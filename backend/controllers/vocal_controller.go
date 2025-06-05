package controllers

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"backend/models"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/gorm"
)

type VocalController struct {
	DB *gorm.DB
}

// CreateEntry uploads and creates a new vocal journal entry
func (v *VocalController) CreateEntry(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Get form data
	entryTitle := c.PostForm("entryTitle")
	userTagsStr := c.PostForm("userTags") // Comma-separated tags
	transcriptionEnabled := c.DefaultPostForm("transcriptionEnabled", "true")
	privacyLevel := c.DefaultPostForm("privacyLevel", "private")

	// Handle file upload
	file, err := c.FormFile("audioFile")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Audio file is required"})
		return
	}

	// Validate file type
	allowedExtensions := []string{".wav", ".mp3", ".m4a"}
	fileExtension := strings.ToLower(filepath.Ext(file.Filename))
	isValidExtension := false
	for _, ext := range allowedExtensions {
		if ext == fileExtension {
			isValidExtension = true
			break
		}
	}

	if !isValidExtension {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file type. Only WAV, MP3, and M4A files are allowed"})
		return
	}

	// Validate file size (max 50MB)
	if file.Size > 50*1024*1024 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "File size exceeds 50MB limit"})
		return
	}

	// Generate unique filename
	fileUUID := uuid.New()
	filename := fmt.Sprintf("%s_%s%s", userID.String(), fileUUID.String(), fileExtension)
	audioFilePath := filepath.Join("audio", filename)

	// Create audio directory if it doesn't exist
	if err := os.MkdirAll("audio", 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create audio directory"})
		return
	}

	// Save file
	if err := c.SaveUploadedFile(file, audioFilePath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save audio file"})
		return
	}

	// TODO: Get audio duration from file metadata
	// For now, we'll set a placeholder value
	durationSeconds := 60 // This should be calculated from actual audio file

	// Parse user tags
	var userTags pq.StringArray
	if userTagsStr != "" {
		tags := strings.Split(userTagsStr, ",")
		for i, tag := range tags {
			tags[i] = strings.TrimSpace(tag)
		}
		userTags = tags
	}

	// Validate privacy level
	if privacyLevel != "private" && privacyLevel != "anonymous_research" {
		privacyLevel = "private"
	}

	// Parse transcription enabled
	transcriptionEnabledBool, _ := strconv.ParseBool(transcriptionEnabled)

	// Create vocal journal entry
	entry := models.VocalJournalEntry{
		UserID:               userID,
		DurationSeconds:      durationSeconds,
		FileSizeBytes:        &file.Size,
		AudioFilePath:        audioFilePath,
		AudioFormat:          strings.TrimPrefix(fileExtension, "."),
		RecordingQuality:     "good", // TODO: Analyze audio quality
		AmbientNoiseLevel:    "low",  // TODO: Analyze ambient noise
		UserTags:             userTags,
		TranscriptionEnabled: transcriptionEnabledBool,
		AnalysisStatus:       "pending",
		PrivacyLevel:         privacyLevel,
	}

	if entryTitle != "" {
		entry.EntryTitle = &entryTitle
	}

	// Save to database
	if err := v.DB.Create(&entry).Error; err != nil {
		// Clean up uploaded file if database save fails
		os.Remove(audioFilePath)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create vocal entry"})
		return
	}

	// Trigger async processing for transcription and analysis
	if transcriptionEnabledBool {
		go v.processVocalEntry(entry.ID)
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Vocal journal entry created successfully",
		"entry":   entry,
	})
}

// processVocalEntry handles async transcription and sentiment analysis
func (v *VocalController) processVocalEntry(entryID uuid.UUID) {
	// Update status to processing
	v.DB.Model(&models.VocalJournalEntry{}).Where("id = ?", entryID).Update("analysis_status", "processing")

	// TODO: Implement actual speech-to-text service integration
	// This is a placeholder for the actual implementation

	// Simulate processing time
	time.Sleep(10 * time.Second)

	// Example transcription (in real implementation, this would come from speech service)
	transcription := models.VocalTranscription{
		VocalEntryID:         entryID,
		TranscriptionText:    "This is a placeholder transcription. In the actual implementation, this would come from a speech-to-text service like Azure Speech, Google Speech-to-Text, or AWS Transcribe.",
		ConfidenceScore:      func() *float64 { score := 0.85; return &score }(),
		LanguageDetected:     func() *string { lang := "id"; return &lang }(),
		WordCount:            func() *int { count := 25; return &count }(),
		ProcessingService:    "azure_speech", // or "google_speech", "aws_transcribe"
		ProcessingDurationMs: func() *int { duration := 8500; return &duration }(),
		IsEncrypted:          true,
	}

	// Save transcription
	if err := v.DB.Create(&transcription).Error; err != nil {
		v.DB.Model(&models.VocalJournalEntry{}).Where("id = ?", entryID).Update("analysis_status", "failed")
		return
	}

	// TODO: Implement sentiment analysis
	// This would typically involve:
	// 1. Analyzing the transcribed text for emotional content
	// 2. Analyzing voice features (tone, pace, etc.) from the audio
	// 3. Combining text and voice analysis for comprehensive sentiment

	// Example sentiment analysis (placeholder)
	sentimentAnalysis := models.VocalSentimentAnalysis{
		VocalEntryID:            entryID,
		OverallWellbeingScore:   func() *float64 { score := 6.5; return &score }(),
		WellbeingCategory:       func() *string { category := "moderate"; return &category }(),
		EmotionalValence:        func() *float64 { valence := 0.2; return &valence }(),
		EmotionalArousal:        func() *float64 { arousal := -0.1; return &arousal }(),
		EmotionalDominance:      func() *float64 { dominance := 0.3; return &dominance }(),
		DetectedEmotions:        `{"calm": 0.6, "hopeful": 0.3, "worried": 0.1}`,
		DetectedThemes:          pq.StringArray{"daily_routine", "work_stress", "self_care"},
		StressIndicators:        `{"voice_tension": 0.2, "speech_rate": "normal", "pauses": "few"}`,
		VoiceFeatures:           `{"pitch_mean": 180.5, "pitch_std": 25.3, "intensity_mean": 65.2}`,
		AnalysisModelVersion:    func() *string { version := "tenang_ai_v1.0"; return &version }(),
		ConfidenceScore:         func() *float64 { score := 0.78; return &score }(),
		ProcessingDurationMs:    func() *int { duration := 5200; return &duration }(),
		ReflectionPrompt:        func() *string { prompt := "It sounds like you're navigating some daily challenges while maintaining a generally positive outlook. What aspects of your self-care routine have been most helpful recently?"; return &prompt }(),
	}

	// Save sentiment analysis
	if err := v.DB.Create(&sentimentAnalysis).Error; err != nil {
		v.DB.Model(&models.VocalJournalEntry{}).Where("id = ?", entryID).Update("analysis_status", "failed")
		return
	}

	// Update status to completed
	v.DB.Model(&models.VocalJournalEntry{}).Where("id = ?", entryID).Update("analysis_status", "completed")
}

// GetEntries returns user's vocal journal entries
func (v *VocalController) GetEntries(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Pagination parameters
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	offset := (page - 1) * limit

	// Status filter
	status := c.Query("status") // pending, processing, completed, failed

	query := v.DB.Where("user_id = ?", userID)
	if status != "" {
		query = query.Where("analysis_status = ?", status)
	}

	var entries []models.VocalJournalEntry
	if err := query.Order("created_at DESC").Limit(limit).Offset(offset).Find(&entries).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch vocal entries"})
		return
	}

	// Get total count for pagination
	var totalCount int64
	countQuery := v.DB.Model(&models.VocalJournalEntry{}).Where("user_id = ?", userID)
	if status != "" {
		countQuery = countQuery.Where("analysis_status = ?", status)
	}
	countQuery.Count(&totalCount)

	c.JSON(http.StatusOK, gin.H{
		"entries": entries,
		"pagination": gin.H{
			"page":       page,
			"limit":      limit,
			"totalCount": totalCount,
			"totalPages": (totalCount + int64(limit) - 1) / int64(limit),
		},
	})
}

// GetEntry returns a specific vocal journal entry with analysis
func (v *VocalController) GetEntry(c *gin.Context) {
	entryIDStr := c.Param("entryId")
	entryID, err := uuid.Parse(entryIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid entry ID"})
		return
	}

	var entry models.VocalJournalEntry
	if err := v.DB.Preload("Transcription").Preload("SentimentAnalysis").Where("id = ?", entryID).First(&entry).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Vocal entry not found"})
		return
	}

	c.JSON(http.StatusOK, entry)
}

// GetTranscription returns transcription for a vocal entry
func (v *VocalController) GetTranscription(c *gin.Context) {
	entryIDStr := c.Param("entryId")
	entryID, err := uuid.Parse(entryIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid entry ID"})
		return
	}

	var transcription models.VocalTranscription
	if err := v.DB.Where("vocal_entry_id = ?", entryID).First(&transcription).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Transcription not found"})
		return
	}

	c.JSON(http.StatusOK, transcription)
}

// GetSentimentAnalysis returns sentiment analysis for a vocal entry
func (v *VocalController) GetSentimentAnalysis(c *gin.Context) {
	entryIDStr := c.Param("entryId")
	entryID, err := uuid.Parse(entryIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid entry ID"})
		return
	}

	var analysis models.VocalSentimentAnalysis
	if err := v.DB.Where("vocal_entry_id = ?", entryID).First(&analysis).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Sentiment analysis not found"})
		return
	}

	c.JSON(http.StatusOK, analysis)
}

// UpdateEntry updates a vocal journal entry
func (v *VocalController) UpdateEntry(c *gin.Context) {
	entryIDStr := c.Param("entryId")
	entryID, err := uuid.Parse(entryIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid entry ID"})
		return
	}

	type UpdateEntryRequest struct {
		EntryTitle   *string           `json:"entryTitle"`
		UserTags     *pq.StringArray   `json:"userTags"`
		PrivacyLevel *string           `json:"privacyLevel"`
	}

	var req UpdateEntryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Find entry
	var entry models.VocalJournalEntry
	if err := v.DB.Where("id = ?", entryID).First(&entry).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Vocal entry not found"})
		return
	}

	// Update fields if provided
	if req.EntryTitle != nil {
		entry.EntryTitle = req.EntryTitle
	}

	if req.UserTags != nil {
		entry.UserTags = *req.UserTags
	}

	if req.PrivacyLevel != nil {
		if *req.PrivacyLevel == "private" || *req.PrivacyLevel == "anonymous_research" {
			entry.PrivacyLevel = *req.PrivacyLevel
		} else {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid privacy level. Use 'private' or 'anonymous_research'"})
			return
		}
	}

	// Save updates
	if err := v.DB.Save(&entry).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update vocal entry"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Vocal entry updated successfully",
		"entry":   entry,
	})
}

// DeleteEntry deletes a vocal journal entry and its associated files
func (v *VocalController) DeleteEntry(c *gin.Context) {
	entryIDStr := c.Param("entryId")
	entryID, err := uuid.Parse(entryIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid entry ID"})
		return
	}

	// Find entry
	var entry models.VocalJournalEntry
	if err := v.DB.Where("id = ?", entryID).First(&entry).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Vocal entry not found"})
		return
	}

	// Delete associated audio file
	if entry.AudioFilePath != "" {
		if err := os.Remove(entry.AudioFilePath); err != nil {
			// Log error but don't fail the request
			fmt.Printf("Warning: Failed to delete audio file %s: %v\n", entry.AudioFilePath, err)
		}
	}

	// Delete from database (this will cascade to transcription and sentiment analysis)
	if err := v.DB.Delete(&entry).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete vocal entry"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Vocal entry deleted successfully"})
}

// GetWellbeingTrends returns user's wellbeing trends from vocal analysis
func (v *VocalController) GetWellbeingTrends(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Get date range from query params (default to last 30 days)
	daysStr := c.DefaultQuery("days", "30")
	days, _ := strconv.Atoi(daysStr)
	if days <= 0 {
		days = 30
	}

	startDate := time.Now().AddDate(0, 0, -days)

	// Get wellbeing scores over time
	type WellbeingTrend struct {
		Date                  time.Time `json:"date"`
		OverallWellbeingScore float64   `json:"overallWellbeingScore"`
		EmotionalValence      float64   `json:"emotionalValence"`
		WellbeingCategory     string    `json:"wellbeingCategory"`
	}

	var trends []WellbeingTrend
	query := `
		SELECT
			DATE(vje.created_at) as date,
			AVG(vsa.overall_wellbeing_score) as overall_wellbeing_score,
			AVG(vsa.emotional_valence) as emotional_valence,
			MODE() WITHIN GROUP (ORDER BY vsa.wellbeing_category) as wellbeing_category
		FROM vocal_journal_entries vje
		JOIN vocal_sentiment_analysis vsa ON vje.id = vsa.vocal_entry_id
		WHERE vje.user_id = ? AND vje.created_at >= ? AND vsa.overall_wellbeing_score IS NOT NULL
		GROUP BY DATE(vje.created_at)
		ORDER BY date DESC
	`

	if err := v.DB.Raw(query, userID, startDate).Scan(&trends).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch wellbeing trends"})
		return
	}

	// Calculate overall statistics
	var avgWellbeing, avgValence float64
	if len(trends) > 0 {
		totalWellbeing, totalValence := 0.0, 0.0
		for _, trend := range trends {
			totalWellbeing += trend.OverallWellbeingScore
			totalValence += trend.EmotionalValence
		}
		avgWellbeing = totalWellbeing / float64(len(trends))
		avgValence = totalValence / float64(len(trends))
	}

	c.JSON(http.StatusOK, gin.H{
		"trends": trends,
		"summary": gin.H{
			"averageWellbeing": avgWellbeing,
			"averageValence":   avgValence,
			"periodDays":       days,
			"entryCount":       len(trends),
		},
		"dateRange": gin.H{
			"startDate": startDate,
			"endDate":   time.Now(),
		},
	})
}

// GetAudioFile serves the audio file for playback
func (v *VocalController) GetAudioFile(c *gin.Context) {
	entryIDStr := c.Param("entryId")
	entryID, err := uuid.Parse(entryIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid entry ID"})
		return
	}

	// Find entry
	var entry models.VocalJournalEntry
	if err := v.DB.Where("id = ?", entryID).First(&entry).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Vocal entry not found"})
		return
	}

	// TODO: Add authorization check to ensure user owns this entry

	// Check if file exists
	if _, err := os.Stat(entry.AudioFilePath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Audio file not found"})
		return
	}

	// Serve the file
	c.File(entry.AudioFilePath)
}