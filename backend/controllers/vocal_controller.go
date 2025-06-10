package controllers

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"backend/config"
	"backend/middleware"
	"backend/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/gorm"
)

type VocalController struct {
	DB  *gorm.DB
	Cfg *config.Config
}

func NewVocalController(db *gorm.DB, cfg *config.Config) *VocalController {
	return &VocalController{DB: db, Cfg: cfg}
}

// --- DTOs and Request Structs ---

type VocalEntryResponse struct {
	ID                 uuid.UUID      `json:"id"`
	UserID             uuid.UUID      `json:"user_id"`
	EntryTitle         *string        `json:"entry_title,omitempty"`
	DurationSeconds    int            `json:"duration_seconds"`
	AudioFormat        string         `json:"audio_format"`
	UserTags           pq.StringArray `json:"user_tags,omitempty"`
	AnalysisStatus     string         `json:"analysis_status"`
	TranscriptionReady bool           `json:"transcription_ready"`
	AnalysisReady      bool           `json:"analysis_ready"`
	CreatedAt          time.Time      `json:"created_at"`
}

type VocalEntryDetailResponse struct {
	ID            uuid.UUID                      `json:"id"`
	EntryTitle    *string                        `json:"entry_title,omitempty"`
	CreatedAt     time.Time                      `json:"created_at"`
	AudioURL      string                         `json:"audio_url"`
	Transcription *models.VocalTranscription     `json:"transcription,omitempty"`
	Analysis      *models.VocalSentimentAnalysis `json:"analysis,omitempty"`
}

type UpdateVocalEntryRequest struct {
	EntryTitle *string        `json:"entryTitle"`
	UserTags   pq.StringArray `json:"userTags" gorm:"type:text[]"`
}

type WellbeingTrend struct {
	Date                string  `json:"date"`
	OverallWellbeingScore float64 `json:"overall_wellbeing_score"`
}


// --- Controller Handlers ---

// CreateEntry handles the upload of a new vocal journal entry.
func (v *VocalController) CreateEntry(c *gin.Context) {
	authedUser, _ := middleware.GetFullUserFromContext(c)

	if err := c.Request.ParseMultipartForm(v.Cfg.Storage.MaxFileSize); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Request size exceeds limit", "code": "size_limit_exceeded"})
		return
	}

	file, header, err := c.Request.FormFile("audioFile")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Audio file is required in 'audioFile' field", "code": "file_required"})
		return
	}
	defer file.Close()

	fileExt := strings.ToLower(filepath.Ext(header.Filename))
	if fileExt != ".wav" && fileExt != ".mp3" && fileExt != ".m4a" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file type. Use .wav, .mp3, or .m4a", "code": "invalid_file_type"})
		return
	}

	uploadPath := v.Cfg.Storage.AudioUploadPath
	if err := os.MkdirAll(uploadPath, 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not prepare storage", "code": "storage_error"})
		return
	}

	uniqueFilename := fmt.Sprintf("%s_%s%s", authedUser.ID.String(), uuid.New().String(), fileExt)
	filePath := filepath.Join(uploadPath, uniqueFilename)

	out, err := os.Create(filePath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not save file", "code": "file_save_error"})
		return
	}
	defer out.Close()
	_, err = io.Copy(out, file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error while saving file", "code": "file_copy_error"})
		return
	}

	entryTitle := c.Request.FormValue("entryTitle")
	userTagsStr := c.Request.FormValue("userTags")
	transcriptionEnabled, _ := strconv.ParseBool(c.DefaultPostForm("transcriptionEnabled", "true"))

	// TODO: Get audio duration from file metadata.
	durationSeconds := 120 // Placeholder

	entry := models.VocalJournalEntry{
		UserID:               authedUser.ID,
		EntryTitle:           &entryTitle,
		DurationSeconds:      durationSeconds,
		FileSizeBytes:        &header.Size,
		AudioFilePath:        filePath,
		AudioFormat:          strings.TrimPrefix(fileExt, "."),
		UserTags:             strings.Split(userTagsStr, ","),
		TranscriptionEnabled: transcriptionEnabled,
		AnalysisStatus:       "pending",
		PrivacyLevel:         "private",
	}

	if err := v.DB.Create(&entry).Error; err != nil {
		os.Remove(filePath)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create vocal entry record", "code": "db_error"})
		return
	}

	if transcriptionEnabled {
		go v.processVocalEntry(entry.ID)
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Vocal entry uploaded successfully", "entry_id": entry.ID})
}

// GetEntries retrieves a paginated list of vocal entries for the user.
func (v *VocalController) GetEntries(c *gin.Context) {
	authedUser, _ := middleware.GetFullUserFromContext(c)
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "15"))
	offset := (page - 1) * limit

	var entries []models.VocalJournalEntry
	query := v.DB.Where("user_id = ?", authedUser.ID)
	query.Order("created_at DESC").Limit(limit).Offset(offset).Find(&entries)

	var response []VocalEntryResponse
	for _, e := range entries {
		var transcriptionCount, analysisCount int64
		v.DB.Model(&models.VocalTranscription{}).Where("vocal_entry_id = ?", e.ID).Count(&transcriptionCount)
		v.DB.Model(&models.VocalSentimentAnalysis{}).Where("vocal_entry_id = ?", e.ID).Count(&analysisCount)

		response = append(response, VocalEntryResponse{
			ID: e.ID, UserID: e.UserID, EntryTitle: e.EntryTitle, DurationSeconds: e.DurationSeconds,
			AudioFormat: e.AudioFormat, UserTags: e.UserTags, AnalysisStatus: e.AnalysisStatus,
			TranscriptionReady: transcriptionCount > 0, AnalysisReady: analysisCount > 0, CreatedAt: e.CreatedAt,
		})
	}
	c.JSON(http.StatusOK, gin.H{"data": response})
}

// GetEntry retrieves a single detailed vocal entry with its analysis.
func (v *VocalController) GetEntry(c *gin.Context) {
	entryID, _ := uuid.Parse(c.Param("entryId"))
	authedUser, _ := middleware.GetFullUserFromContext(c)

	var entry models.VocalJournalEntry
	if err := v.DB.Preload("Transcription").Preload("Analysis").Where("id = ? AND user_id = ?", entryID, authedUser.ID).First(&entry).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Vocal entry not found or access denied", "code": "not_found_or_forbidden"})
		return
	}

	c.JSON(http.StatusOK, VocalEntryDetailResponse{
		ID:            entry.ID,
		EntryTitle:    entry.EntryTitle,
		CreatedAt:     entry.CreatedAt,
		AudioURL:      fmt.Sprintf("/api/v1/vocal/entries/%s/audio", entry.ID.String()),
		Transcription: entry.Transcription,
		Analysis:      entry.SentimentAnalysis,
	})
}

// DeleteEntry deletes a vocal entry and its associated data and file.
func (v *VocalController) DeleteEntry(c *gin.Context) {
	entryID, _ := uuid.Parse(c.Param("entryId"))
	authedUser, _ := middleware.GetFullUserFromContext(c)

	var entry models.VocalJournalEntry
	if err := v.DB.Where("id = ? AND user_id = ?", entryID, authedUser.ID).First(&entry).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Vocal entry not found", "code": "not_found"})
		return
	}

	// Hapus file dari disk
	if err := os.Remove(entry.AudioFilePath); err != nil {
		log.Printf("WARNING: Failed to delete audio file %s: %v", entry.AudioFilePath, err)
	}

	// Hapus record dari DB (akan ter-cascade ke transkripsi dan analisis)
	if err := v.DB.Select("Transcription", "Analysis").Delete(&entry).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete vocal entry record", "code": "db_error"})
		return
	}

	c.Status(http.StatusNoContent)
}

// GetAudioFile serves the requested audio file after ownership verification.
func (v *VocalController) GetAudioFile(c *gin.Context) {
    entryID, _ := uuid.Parse(c.Param("entryId"))
    authedUser, _ := middleware.GetFullUserFromContext(c)

    var entry models.VocalJournalEntry
    if err := v.DB.Where("id = ? AND user_id = ?", entryID, authedUser.ID).First(&entry).Error; err != nil {
        c.JSON(http.StatusForbidden, gin.H{"error": "Access to this audio file is denied", "code": "forbidden"})
        return
    }

    c.File(entry.AudioFilePath)
}

// GetWellbeingTrends returns aggregated wellbeing data for visualizations.
func (v *VocalController) GetWellbeingTrends(c *gin.Context) {
	authedUser, _ := middleware.GetFullUserFromContext(c)
	days, _ := strconv.Atoi(c.DefaultQuery("days", "30"))

	var trends []WellbeingTrend
	v.DB.Model(&models.VocalSentimentAnalysis{}).
		Select("DATE(vocal_journal_entries.created_at) as date, AVG(overall_wellbeing_score) as overall_wellbeing_score").
		Joins("JOIN vocal_journal_entries ON vocal_journal_entries.id = vocal_sentiment_analysis.vocal_entry_id").
		Where("vocal_journal_entries.user_id = ? AND vocal_journal_entries.created_at >= ?", authedUser.ID, time.Now().AddDate(0, 0, -days)).
		Group("DATE(vocal_journal_entries.created_at)").
		Order("date ASC").
		Scan(&trends)

	c.JSON(http.StatusOK, gin.H{"trends": trends})
}


// --- AI Processing Pipeline & Helpers ---

func (v *VocalController) processVocalEntry(entryID uuid.UUID) {
	log.Printf("Starting vocal analysis pipeline for entry: %s", entryID)
	v.DB.Model(&models.VocalJournalEntry{}).Where("id = ?", entryID).Update("analysis_status", "processing")

	var entry models.VocalJournalEntry
	if err := v.DB.First(&entry, entryID).Error; err != nil {
		log.Printf("ERROR: Could not find entry %s to process: %v", entryID, err)
		return
	}

	// ---- Tahap 1: Speech-to-Text (Azure Speech Services) ----
	transcriptionText, err := v.transcribeAudioWithAzure(entry.AudioFilePath)
	if err != nil {
		log.Printf("ERROR: Azure transcription failed for entry %s: %v", entryID, err)
		v.DB.Model(&entry).Update("analysis_status", "failed")
		return
	}
	confidenceScore := 0.95
	transcription := models.VocalTranscription{
		VocalEntryID: entryID, TranscriptionText: transcriptionText, ConfidenceScore: &confidenceScore, // Placeholder score
	}
	v.DB.Create(&transcription)


	// ---- Tahap 2: Content Analysis (Azure Text Analytics) ----
	themes, err := v.analyzeTextWithAzure(transcriptionText)
	if err != nil { log.Printf("WARNING: Text analysis failed for entry %s: %v", entryID, err) }


	// ---- Tahap 3: Vocal Sentiment Analysis (HuggingFace) ----
	// valence, arousal, dominance, err := v.analyzeVocalTonesWithHuggingFace(entry.AudioFilePath)
	// if err != nil { log.Printf("WARNING: Vocal analysis failed for entry %s: %v", entryID, err) }


	// ---- Tahap 4: Gabungkan Hasil & Simpan ----
	overallScore := 7.5
	wellbeingCategory := "Menghadapi beberapa tantangan 💪"
	analysis := models.VocalSentimentAnalysis{
		VocalEntryID:         entryID,
		OverallWellbeingScore: &overallScore, // Placeholder
		WellbeingCategory:    &wellbeingCategory, // Placeholder
		DetectedThemes:       themes,
	}
	v.DB.Create(&analysis)

	v.DB.Model(&entry).Update("analysis_status", "completed")
	log.Printf("Finished vocal analysis pipeline for entry: %s", entryID)
}

func (v *VocalController) transcribeAudioWithAzure(filePath string) (string, error) {
	// apiKey := v.Cfg.Azure.SpeechApiKey
	// region := v.Cfg.Azure.SpeechRegion
	// if apiKey == "" || region == "" { return "", errors.New("Azure Speech config not set") }
	//
	// config, err := speech.NewSpeechConfigFromSubscription(apiKey, region)
	// if err != nil { return "", err }
	// defer config.Close()
	//
	// audioConfig, err := audio.NewAudioConfigFromWavFileInput(filePath)
	// if err != nil { return "", err }
	// defer audioConfig.Close()
	//
	// recognizer, err := speech.NewSpeechRecognizerFromConfig(config, audioConfig)
	// if err != nil { return "", err }
	// defer recognizer.Close()
	//
	// result := <-recognizer.RecognizeOnceAsync()
	// if result.Error != nil { return "", result.Error }

	// Placeholder untuk pengembangan
	log.Printf("TRANSCRIBING (placeholder): %s", filePath)
	time.Sleep(3 * time.Second)
	return "Ini adalah hasil transkripsi dari file audio. Terdengar ada sedikit kekhawatiran mengenai pekerjaan, namun secara umum nada suara terdengar stabil dan tenang.", nil
}

func (v *VocalController) analyzeTextWithAzure(text string) (pq.StringArray, error) {
	// endpoint := v.Cfg.Azure.TextAnalyticsEndpoint
	// key := v.Cfg.Azure.TextAnalyticsKey
	// ... (Setup Azure Text Analytics client) ...
	//
	// resp, err := client.ExtractKeyPhrases(context.Background(), []string{text}, nil)
	// ... (proses response untuk mendapatkan tema/keyword)

	// Placeholder untuk pengembangan
	log.Printf("ANALYZING TEXT (placeholder): %s", text)
	time.Sleep(1 * time.Second)
	return pq.StringArray{"pekerjaan", "tantangan", "rutinitas"}, nil
}

func (v *VocalController) analyzeVocalTonesWithHuggingFace(filePath string) (float64, float64, float64, error) {
	// endpoint := v.Cfg.HuggingFace.Endpoint
	// apiKey := v.Cfg.HuggingFace.ApiKey
	// ... (baca file audio, buat HTTP request ke HuggingFace Inference API) ...
	//
	// resp, err := http.DefaultClient.Do(req)
	// ... (proses JSON response dari HuggingFace)

	// Placeholder untuk pengembangan
	log.Printf("ANALYZING VOCAL TONES (placeholder): %s", filePath)
	time.Sleep(2 * time.Second)
	return 0.6, 0.3, 0.5, nil // valence, arousal, dominance
}