package controllers

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"backend/config"
	"backend/middleware"
	"backend/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sashabaranov/go-openai"
	"gorm.io/gorm"
)

type VocalController struct {
	DB         *gorm.DB
	Cfg        *config.Config
	HTTPClient *http.Client
}

// NewVocalController membuat instance baru dari VocalController
func NewVocalController(db *gorm.DB, cfg *config.Config) *VocalController {
	return &VocalController{
		DB:         db,
		Cfg:        cfg,
		HTTPClient: &http.Client{Timeout: 90 * time.Second}, // Timeout lebih lama untuk proses AI
	}
}

// Struct untuk mem-parsing respons JSON dari OpenAI
type OpenAIAnalysisResponse struct {
	WellbeingScore    float64 `json:"wellbeing_score"`
	WellbeingCategory string  `json:"wellbeing_category"`
	Reflection        string  `json:"reflection"`
}

// CreateEntry: Alur kerja lengkap untuk upload dan analisis
func (vc *VocalController) CreateEntry(c *gin.Context) {
	authedUser, _ := middleware.GetFullUserFromContext(c)
	file, header, err := c.Request.FormFile("audio")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "File audio dengan key 'audio' dibutuhkan."})
		return
	}
	defer file.Close()

	audioBytes, err := io.ReadAll(file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membaca file audio."})
		return
	}

	// 1. Transkripsi Suara -> Teks (Azure STT)
	transcriptionText, err := vc.transcribeAudioWithAzure(audioBytes)
	if err != nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Gagal melakukan transkripsi suara", "details": err.Error()})
		return
	}
	log.Printf("[VOCAL DEBUG] Hasil Transkripsi: %s", transcriptionText)
	if strings.TrimSpace(transcriptionText) == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Tidak ada suara yang terdeteksi dalam rekaman."})
		return
	}

	// 2. Analisis Teks -> Skor, Kategori, Refleksi (Azure OpenAI)
	analysis, err := vc.analyzeTextWithOpenAI(transcriptionText)
	if err != nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Gagal menganalisis teks", "details": err.Error()})
		return
	}

	// 3. Simpan semua hasil ke database
	tx := vc.DB.Begin()

	uploadPath := vc.Cfg.Storage.AudioUploadPath
	if err := os.MkdirAll(uploadPath, 0755); err != nil {
		log.Printf("Gagal membuat direktori upload: %v", err)
	}
	uniqueFilename := fmt.Sprintf("%s_%s%s", authedUser.ID.String(), uuid.New().String(), filepath.Ext(header.Filename))
	filePath := filepath.Join(uploadPath, uniqueFilename)
	if err := os.WriteFile(filePath, audioBytes, 0644); err != nil {
		log.Printf("Gagal menyimpan file audio ke disk: %v", err)
		filePath = "cloud/storage_failed" // fallback path
	}

	title := fmt.Sprintf("Jurnal Suara - %s", time.Now().Format("2 Jan 2006"))
	vocalEntry := models.VocalJournalEntry{
		UserID:          authedUser.ID,
		EntryTitle:      &title,
		DurationSeconds: 0, // Placeholder
		FileSizeBytes:   &header.Size,
		AudioFilePath:   filePath,
		AudioFormat:     strings.TrimPrefix(filepath.Ext(header.Filename), "."),
		AnalysisStatus:  "completed",
	}
	if err := tx.Create(&vocalEntry).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "DB Error: Gagal membuat entri."})
		return
	}

	transcription := models.VocalTranscription{VocalEntryID: vocalEntry.ID, TranscriptionText: transcriptionText}
	if err := tx.Create(&transcription).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "DB Error: Gagal menyimpan transkripsi."})
		return
	}

	modelNameFromConfig := vc.Cfg.Azure.OpenAIDeploymentName
	analysisResult := models.VocalSentimentAnalysis{
		VocalEntryID:          vocalEntry.ID,
		OverallWellbeingScore: &analysis.WellbeingScore,
		WellbeingCategory:     &analysis.WellbeingCategory,
		ReflectionPrompt:      &analysis.Reflection,
		AnalysisModelVersion:  &modelNameFromConfig,
	}
	if err := tx.Create(&analysisResult).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "DB Error: Gagal menyimpan analisis."})
		return
	}

	tx.Commit()

	// 4. Kembalikan hasil analisis ke frontend
	c.JSON(http.StatusCreated, gin.H{"data": analysisResult})
}

// transcribeAudioWithAzure: Menggunakan Azure Speech to Text
func (vc *VocalController) transcribeAudioWithAzure(audioBytes []byte) (string, error) {
	endpoint := fmt.Sprintf("https://%s.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=id-ID", vc.Cfg.Azure.SpeechRegion)
	req, err := http.NewRequest("POST", endpoint, bytes.NewReader(audioBytes))
	if err != nil {
		return "", err
	}
	req.Header.Set("Ocp-Apim-Subscription-Key", vc.Cfg.Azure.SpeechAPIKey)
	req.Header.Set("Content-Type", "audio/wav; codecs=audio/pcm; samplerate=16000")

	resp, err := vc.HTTPClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("Azure STT API error: status %d, body: %s", resp.StatusCode, string(body))
	}

	var result struct {
		DisplayText string `json:"DisplayText"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", err
	}

	return result.DisplayText, nil
}

// analyzeTextWithOpenAI: Menganalisis teks menggunakan GPT
func (vc *VocalController) analyzeTextWithOpenAI(transcription string) (*OpenAIAnalysisResponse, error) {
	config := openai.DefaultAzureConfig(vc.Cfg.Azure.OpenAIAPIKey, vc.Cfg.Azure.OpenAIEndpoint)
	config.APIVersion = vc.Cfg.Azure.OpenAIAPIVersion
	client := openai.NewClientWithConfig(config)

	systemPrompt := `Anda adalah API yang mengembalikan format JSON. Jangan menulis teks atau penjelasan apapun di luar blok JSON. Anda menerima transkrip dari jurnal suara pengguna. Analisis teksnya dan kembalikan objek JSON dengan struktur: {"wellbeing_score": float, "wellbeing_category": "string", "reflection": "string"}. 'wellbeing_score' adalah angka 1.0-10.0. 'wellbeing_category' adalah judul singkat 3-5 kata. 'reflection' adalah paragraf refleksi 2-4 kalimat dalam Bahasa Indonesia.`

	req := openai.ChatCompletionRequest{
		Model:            vc.Cfg.Azure.OpenAIDeploymentName,
		ResponseFormat:   &openai.ChatCompletionResponseFormat{Type: openai.ChatCompletionResponseFormatTypeJSONObject},
		Messages: []openai.ChatCompletionMessage{
			{Role: openai.ChatMessageRoleSystem, Content: systemPrompt},
			{Role: openai.ChatMessageRoleUser, Content: transcription},
		},
		MaxTokens:   350,
		Temperature: 0.6,
	}

	resp, err := client.CreateChatCompletion(context.Background(), req)
	if err != nil {
		return nil, fmt.Errorf("OpenAI completion error: %w", err)
	}
	if len(resp.Choices) == 0 {
		return nil, fmt.Errorf("OpenAI tidak memberikan respons")
	}

	rawResponse := resp.Choices[0].Message.Content
	log.Printf("[VOCAL DEBUG] Raw OpenAI Response: %s", rawResponse)

	var analysisResp OpenAIAnalysisResponse
	err = json.Unmarshal([]byte(rawResponse), &analysisResp)
	if err != nil {
		log.Printf("Gagal mem-parsing JSON dari OpenAI: %v. Raw content: %s", err, rawResponse)
		return nil, fmt.Errorf("respons AI tidak dalam format JSON yang valid")
	}

	if analysisResp.WellbeingCategory == "" || analysisResp.Reflection == "" {
		return nil, fmt.Errorf("AI mengembalikan objek JSON kosong atau tidak lengkap. Respons mentah: %s", rawResponse)
	}

	return &analysisResp, nil
}

// ... (Fungsi-fungsi lain seperti GetEntries, DeleteEntry, dll. bisa Anda tambahkan kembali di sini sesuai kebutuhan)



// // GetEntries retrieves a paginated list of vocal entries for the user.
// func (v *VocalController) GetEntries(c *gin.Context) {
// 	authedUser, _ := middleware.GetFullUserFromContext(c)
// 	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
// 	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "15"))
// 	offset := (page - 1) * limit

// 	var entries []models.VocalJournalEntry
// 	query := v.DB.Where("user_id = ?", authedUser.ID)
// 	query.Order("created_at DESC").Limit(limit).Offset(offset).Find(&entries)

// 	var response []VocalEntryResponse
// 	for _, e := range entries {
// 		var transcriptionCount, analysisCount int64
// 		v.DB.Model(&models.VocalTranscription{}).Where("vocal_entry_id = ?", e.ID).Count(&transcriptionCount)
// 		v.DB.Model(&models.VocalSentimentAnalysis{}).Where("vocal_entry_id = ?", e.ID).Count(&analysisCount)

// 		response = append(response, VocalEntryResponse{
// 			ID: e.ID, UserID: e.UserID, EntryTitle: e.EntryTitle, DurationSeconds: e.DurationSeconds,
// 			AudioFormat: e.AudioFormat, UserTags: e.UserTags, AnalysisStatus: e.AnalysisStatus,
// 			TranscriptionReady: transcriptionCount > 0, AnalysisReady: analysisCount > 0, CreatedAt: e.CreatedAt,
// 		})
// 	}
// 	c.JSON(http.StatusOK, gin.H{"data": response})
// }

// // GetEntry retrieves a single detailed vocal entry with its analysis.
// func (v *VocalController) GetEntry(c *gin.Context) {
// 	entryID, _ := uuid.Parse(c.Param("entryId"))
// 	authedUser, _ := middleware.GetFullUserFromContext(c)

// 	var entry models.VocalJournalEntry
// 	if err := v.DB.Preload("Transcription").Preload("Analysis").Where("id = ? AND user_id = ?", entryID, authedUser.ID).First(&entry).Error; err != nil {
// 		c.JSON(http.StatusNotFound, gin.H{"error": "Vocal entry not found or access denied", "code": "not_found_or_forbidden"})
// 		return
// 	}

// 	c.JSON(http.StatusOK, VocalEntryDetailResponse{
// 		ID:            entry.ID,
// 		EntryTitle:    entry.EntryTitle,
// 		CreatedAt:     entry.CreatedAt,
// 		AudioURL:      fmt.Sprintf("/api/v1/vocal/entries/%s/audio", entry.ID.String()),
// 		Transcription: entry.Transcription,
// 		Analysis:      entry.SentimentAnalysis,
// 	})
// }

// // DeleteEntry deletes a vocal entry and its associated data and file.
// func (v *VocalController) DeleteEntry(c *gin.Context) {
// 	entryID, _ := uuid.Parse(c.Param("entryId"))
// 	authedUser, _ := middleware.GetFullUserFromContext(c)

// 	var entry models.VocalJournalEntry
// 	if err := v.DB.Where("id = ? AND user_id = ?", entryID, authedUser.ID).First(&entry).Error; err != nil {
// 		c.JSON(http.StatusNotFound, gin.H{"error": "Vocal entry not found", "code": "not_found"})
// 		return
// 	}

// 	// Hapus file dari disk
// 	if err := os.Remove(entry.AudioFilePath); err != nil {
// 		log.Printf("WARNING: Failed to delete audio file %s: %v", entry.AudioFilePath, err)
// 	}

// 	// Hapus record dari DB (akan ter-cascade ke transkripsi dan analisis)
// 	if err := v.DB.Select("Transcription", "Analysis").Delete(&entry).Error; err != nil {
// 		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete vocal entry record", "code": "db_error"})
// 		return
// 	}

// 	c.Status(http.StatusNoContent)
// }

// // GetAudioFile serves the requested audio file after ownership verification.
// func (v *VocalController) GetAudioFile(c *gin.Context) {
//     entryID, _ := uuid.Parse(c.Param("entryId"))
//     authedUser, _ := middleware.GetFullUserFromContext(c)

//     var entry models.VocalJournalEntry
//     if err := v.DB.Where("id = ? AND user_id = ?", entryID, authedUser.ID).First(&entry).Error; err != nil {
//         c.JSON(http.StatusForbidden, gin.H{"error": "Access to this audio file is denied", "code": "forbidden"})
//         return
//     }

//     c.File(entry.AudioFilePath)
// }

// // GetWellbeingTrends returns aggregated wellbeing data for visualizations.
// func (v *VocalController) GetWellbeingTrends(c *gin.Context) {
// 	authedUser, _ := middleware.GetFullUserFromContext(c)
// 	days, _ := strconv.Atoi(c.DefaultQuery("days", "30"))

// 	var trends []WellbeingTrend
// 	v.DB.Model(&models.VocalSentimentAnalysis{}).
// 		Select("DATE(vocal_journal_entries.created_at) as date, AVG(overall_wellbeing_score) as overall_wellbeing_score").
// 		Joins("JOIN vocal_journal_entries ON vocal_journal_entries.id = vocal_sentiment_analysis.vocal_entry_id").
// 		Where("vocal_journal_entries.user_id = ? AND vocal_journal_entries.created_at >= ?", authedUser.ID, time.Now().AddDate(0, 0, -days)).
// 		Group("DATE(vocal_journal_entries.created_at)").
// 		Order("date ASC").
// 		Scan(&trends)

// 	c.JSON(http.StatusOK, gin.H{"trends": trends})
// }


// // --- AI Processing Pipeline & Helpers ---

// func (v *VocalController) processVocalEntry(entryID uuid.UUID) {
// 	log.Printf("Starting vocal analysis pipeline for entry: %s", entryID)
// 	v.DB.Model(&models.VocalJournalEntry{}).Where("id = ?", entryID).Update("analysis_status", "processing")

// 	var entry models.VocalJournalEntry
// 	if err := v.DB.First(&entry, entryID).Error; err != nil {
// 		log.Printf("ERROR: Could not find entry %s to process: %v", entryID, err)
// 		return
// 	}

// 	// ---- Tahap 1: Speech-to-Text (Azure Speech Services) ----
// 	transcriptionText, err := v.transcribeAudioWithAzure(entry.AudioFilePath)
// 	if err != nil {
// 		log.Printf("ERROR: Azure transcription failed for entry %s: %v", entryID, err)
// 		v.DB.Model(&entry).Update("analysis_status", "failed")
// 		return
// 	}
// 	confidenceScore := 0.95
// 	transcription := models.VocalTranscription{
// 		VocalEntryID: entryID, TranscriptionText: transcriptionText, ConfidenceScore: &confidenceScore, // Placeholder score
// 	}
// 	v.DB.Create(&transcription)


// 	// ---- Tahap 2: Content Analysis (Azure Text Analytics) ----
// 	themes, err := v.analyzeTextWithAzure(transcriptionText)
// 	if err != nil { log.Printf("WARNING: Text analysis failed for entry %s: %v", entryID, err) }


// 	// ---- Tahap 3: Vocal Sentiment Analysis (HuggingFace) ----
// 	// valence, arousal, dominance, err := v.analyzeVocalTonesWithHuggingFace(entry.AudioFilePath)
// 	// if err != nil { log.Printf("WARNING: Vocal analysis failed for entry %s: %v", entryID, err) }


// 	// ---- Tahap 4: Gabungkan Hasil & Simpan ----
// 	overallScore := 7.5
// 	wellbeingCategory := "Menghadapi beberapa tantangan 💪"
// 	analysis := models.VocalSentimentAnalysis{
// 		VocalEntryID:         entryID,
// 		OverallWellbeingScore: &overallScore, // Placeholder
// 		WellbeingCategory:    &wellbeingCategory, // Placeholder
// 		DetectedThemes:       themes,
// 	}
// 	v.DB.Create(&analysis)

// 	v.DB.Model(&entry).Update("analysis_status", "completed")
// 	log.Printf("Finished vocal analysis pipeline for entry: %s", entryID)
// }

// func (v *VocalController) analyzeTextWithAzure(text string) (pq.StringArray, error) {
// 	// endpoint := v.Cfg.Azure.TextAnalyticsEndpoint
// 	// key := v.Cfg.Azure.TextAnalyticsKey
// 	// ... (Setup Azure Text Analytics client) ...
// 	//
// 	// resp, err := client.ExtractKeyPhrases(context.Background(), []string{text}, nil)
// 	// ... (proses response untuk mendapatkan tema/keyword)

// 	// Placeholder untuk pengembangan
// 	log.Printf("ANALYZING TEXT (placeholder): %s", text)
// 	time.Sleep(1 * time.Second)
// 	return pq.StringArray{"pekerjaan", "tantangan", "rutinitas"}, nil
// }

// func (vc *VocalController) analyzeSentimentWithHuggingFace(audioBytes []byte) (HuggingFaceEmotionResponse, error) {
// 	modelURL := "https://api-inference.huggingface.co/models/superb/wav2vec2-base-superb-er"
// 	req, err := http.NewRequest("POST", modelURL, bytes.NewReader(audioBytes))
// 	if err != nil {
// 		return nil, err
// 	}
// 	req.Header.Set("Authorization", "Bearer "+vc.Cfg.HuggingFace.APIKey) // Asumsi Anda punya config HuggingFace
// 	req.Header.Set("Content-Type", "audio/wav")

// 	resp, err := vc.HTTPClient.Do(req)
// 	if err != nil {
// 		return nil, err
// 	}
// 	defer resp.Body.Close()

// 	if resp.StatusCode != http.StatusOK {
// 		body, _ := io.ReadAll(resp.Body)
// 		return nil, fmt.Errorf("Hugging Face API error: status %d, body: %s", resp.StatusCode, string(body))
// 	}

// 	var hfResponse HuggingFaceEmotionResponse
// 	if err := json.NewDecoder(resp.Body).Decode(&hfResponse); err != nil {
// 		return nil, err
// 	}

// 	return hfResponse, nil
// }