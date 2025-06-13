package controllers

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"backend/config"
	"backend/middleware"
	"backend/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sashabaranov/go-openai"
	"gorm.io/gorm"
)

// ChatController handles all chat-related API requests.
type ChatController struct {
	DB  *gorm.DB
	Cfg *config.Config
}

// NewChatController creates a new instance of ChatController.
func NewChatController(db *gorm.DB, cfg *config.Config) *ChatController {
	return &ChatController{DB: db, Cfg: cfg}
}

// --- DTOs and Request Structs for Chat Controller ---

type ChatSessionResponse struct {
	ID                     uuid.UUID  `json:"id"`
	UserID                 uuid.UUID  `json:"user_id"`
	SessionTitle           *string    `json:"session_title,omitempty"`
	TriggerType            string     `json:"trigger_type"`
	SessionStatus          string     `json:"session_status"`
	MessageCount           int        `json:"message_count"`
	SessionDurationSeconds *int       `json:"session_duration_seconds,omitempty"`
	StartedAt              time.Time  `json:"started_at"`
	EndedAt                *time.Time `json:"ended_at,omitempty"`
}

type ChatMessageResponse struct {
	ID             uuid.UUID `json:"id"`
	ChatSessionID  uuid.UUID `json:"chat_session_id"`
	SenderType     string    `json:"sender_type"`
	MessageContent string    `json:"message_content"`
	CreatedAt      time.Time `json:"created_at"`
}

type ScheduledCheckinResponse struct {
	ID               uuid.UUID  `json:"id"`
	ScheduleName     *string    `json:"schedule_name,omitempty"`
	TimeOfDay        string     `json:"time_of_day"` // Format "15:04"
	DaysOfWeek       []int64    `json:"days_of_week"`
	IsActive         bool       `json:"is_active"`
	GreetingTemplate *string    `json:"greeting_template,omitempty"`
	NextTriggerAt    *time.Time `json:"next_trigger_at,omitempty"`
}

type CreateSessionRequest struct {
	SessionTitle string `json:"session_title"`
	TriggerType  string `json:"trigger_type" binding:"required,oneof=user_initiated social_media_alert scheduled_checkin crisis_intervention"`
}

type SendMessageRequest struct {
	SessionID      uuid.UUID `json:"session_id" binding:"required"`
	MessageContent string    `json:"message_content" binding:"required,min=1"`
}

type EndSessionRequest struct {
	Status string `json:"status" binding:"required,oneof=completed abandoned"`
}

type CreateCheckinRequest struct {
	ScheduleName     *string `json:"schedule_name"`
	TimeOfDay        string  `json:"time_of_day" binding:"required"` // Format: "15:04"
	DaysOfWeek       []int64 `json:"days_of_week" binding:"required,min=1"`
	GreetingTemplate *string `json:"greeting_template"`
}

type UpdateCheckinRequest struct {
	ScheduleName     *string  `json:"schedule_name"`
	TimeOfDay        *string  `json:"time_of_day"`
	DaysOfWeek       *[]int64 `json:"days_of_week"`
	GreetingTemplate *string  `json:"greeting_template"`
	IsActive         *bool    `json:"is_active"`
}

// --- Chat Session Handlers ---

// CreateSession creates a new chat session for the authenticated user.
func (ch *ChatController) CreateSession(c *gin.Context) {
	authedUser, _ := middleware.GetFullUserFromContext(c)
	loc, _ := time.LoadLocation("Asia/Jakarta")
	sessionTitle := fmt.Sprintf("Percakapan pada %s", time.Now().In(loc).Format("2 Jan 15:04"))

	// 1. Buat sesi baru dalam satu transaksi database
	tx := ch.DB.Begin()
	if tx.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to start transaction"})
		return
	}

	session := models.ChatSession{
		UserID:       authedUser.ID,
		TriggerType:  "user_initiated",
		SessionTitle: &sessionTitle,
		StartedAt:    time.Now(),
		SessionStatus: "active",
	}

	if err := tx.Create(&session).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create chat session"})
		return
	}

	// 2. Buat pesan sapaan pertama dari AI secara manual
	welcomeMessage := "Halo! Selamat datang di Tenang.in. Ada yang bisa saya bantu atau ada yang ingin kamu ceritakan hari ini?"
	aiMessage := models.ChatMessage{
		ChatSessionID:  session.ID,
		SenderType:     "ai_bot",
		MessageContent: welcomeMessage,
	}

	if err := tx.Create(&aiMessage).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create welcome message"})
		return
	}

	// Commit transaksi jika semua berhasil
	if err := tx.Commit().Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to commit transaction"})
		return
	}

	// 3. Kembalikan data sesi yang baru dibuat
	response := ChatSessionResponse{
		ID:            session.ID,
		UserID:        session.UserID,
		SessionTitle:  session.SessionTitle,
		TriggerType:   session.TriggerType,
		SessionStatus: session.SessionStatus,
		StartedAt:     session.StartedAt,
	}

	c.JSON(http.StatusCreated, gin.H{"data": response})
}

// GetSessions mengambil riwayat sesi chat pengguna (sudah dilengkapi).
func (ch *ChatController) GetSessions(c *gin.Context) {
	authedUser, _ := middleware.GetFullUserFromContext(c)
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset := (page - 1) * limit

	var sessions []models.ChatSession
	query := ch.DB.Where("user_id = ?", authedUser.ID)

	if status := c.Query("status"); status != "" {
		query = query.Where("session_status = ?", status)
	}

	query.Order("created_at DESC").Limit(limit).Offset(offset).Find(&sessions)

	var response []ChatSessionResponse
	for _, s := range sessions {
		response = append(response, ChatSessionResponse{
			ID:                     s.ID,
			UserID:                 s.UserID,
			SessionTitle:           s.SessionTitle,
			TriggerType:            s.TriggerType,
			SessionStatus:          s.SessionStatus,
			MessageCount:           s.MessageCount,
			SessionDurationSeconds: s.SessionDurationSeconds,
			StartedAt:              s.StartedAt,
			EndedAt:                s.EndedAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{"data": response})
}

// GetSession mengambil pesan untuk sesi spesifik (sudah dilengkapi).
func (ch *ChatController) GetSession(c *gin.Context) {
	sessionID, err := uuid.Parse(c.Param("sessionId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid session ID"})
		return
	}
	authedUser, _ := middleware.GetFullUserFromContext(c)

	var session models.ChatSession
	if err := ch.DB.Where("id = ? AND user_id = ?", sessionID, authedUser.ID).First(&session).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	var messages []models.ChatMessage
	ch.DB.Where("chat_session_id = ?", sessionID).Order("created_at ASC").Find(&messages)

	var response []ChatMessageResponse
	for _, m := range messages {
		response = append(response, ChatMessageResponse{
			ID: m.ID, ChatSessionID: m.ChatSessionID, SenderType: m.SenderType,
			MessageContent: m.MessageContent, CreatedAt: m.CreatedAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{"data": response}) // PERBAIKAN: Dibungkus dengan "data"
}

// SendMessage sends a user message and triggers an AI response.
func (ch *ChatController) SendMessage(c *gin.Context) {
	var req SendMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}
	authedUser, _ := middleware.GetFullUserFromContext(c)

	var session models.ChatSession
	if err := ch.DB.Where("id = ? AND user_id = ? AND session_status = 'active'", req.SessionID, authedUser.ID).First(&session).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": "Active session not found or access denied"})
		return
	}

	userMessage := models.ChatMessage{
		ChatSessionID:  req.SessionID,
		SenderType:     "user",
		MessageContent: req.MessageContent,
	}
	if err := ch.DB.Create(&userMessage).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save user message"})
		return
	}

	// PERBAIKAN: Tidak lagi menggunakan goroutine, panggil langsung dan tunggu hasilnya.
	aiMessage, err := ch.generateAIResponse(session.ID, *authedUser)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get AI response", "details": err.Error()})
		return
	}

	// Kembalikan pesan dari AI
	aiResponse := ChatMessageResponse{
		ID:             aiMessage.ID,
		ChatSessionID:  aiMessage.ChatSessionID,
		SenderType:     aiMessage.SenderType,
		MessageContent: aiMessage.MessageContent,
		CreatedAt:      aiMessage.CreatedAt,
	}
	c.JSON(http.StatusCreated, gin.H{"data": aiResponse})
}

// EndSession ends a chat session.
func (ch *ChatController) EndSession(c *gin.Context) {
	sessionID, _ := uuid.Parse(c.Param("sessionId"))
	authedUser, _ := middleware.GetFullUserFromContext(c)

	var req EndSessionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data", "code": "validation_failed"})
		return
	}

	var session models.ChatSession
	if err := ch.DB.Where("id = ? AND user_id = ? AND session_status = 'active'", sessionID, authedUser.ID).First(&session).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Active session not found", "code": "session_not_found"})
		return
	}

	duration := int(time.Since(session.StartedAt).Seconds())
	now := time.Now()

	session.SessionStatus = req.Status
	session.EndedAt = &now
	session.SessionDurationSeconds = &duration

	if err := ch.DB.Save(&session).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to end session", "code": "db_error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Session ended successfully"})
}

// --- Scheduled Check-in Handlers ---

// GetScheduledCheckins retrieves all scheduled check-ins for the user.
func (ch *ChatController) GetScheduledCheckins(c *gin.Context) {
	authedUser, _ := middleware.GetFullUserFromContext(c)

	var checkins []models.ScheduledCheckin
	ch.DB.Where("user_id = ?", authedUser.ID).Order("created_at DESC").Find(&checkins)

	var response []ScheduledCheckinResponse
	for _, ci := range checkins {
		response = append(response, ScheduledCheckinResponse{
			ID: ci.ID, ScheduleName: ci.ScheduleName, TimeOfDay: ci.TimeOfDay.Format("15:04"),
			DaysOfWeek: ci.DaysOfWeek, IsActive: ci.IsActive, GreetingTemplate: ci.GreetingTemplate,
			NextTriggerAt: ci.NextTriggerAt,
		})
	}
	c.JSON(http.StatusOK, response)
}

// CreateScheduledCheckin creates a new scheduled check-in.
func (ch *ChatController) CreateScheduledCheckin(c *gin.Context) {
	var req CreateCheckinRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data", "code": "validation_failed"})
		return
	}
	authedUser, _ := middleware.GetFullUserFromContext(c)

	timeOfDay, err := time.Parse("15:04", req.TimeOfDay)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid time format. Use HH:MM", "code": "invalid_time_format"})
		return
	}

	nextTrigger := calculateNextTriggerTime(timeOfDay, req.DaysOfWeek)

	checkin := models.ScheduledCheckin{
		UserID:           authedUser.ID,
		ScheduleName:     req.ScheduleName,
		TimeOfDay:        timeOfDay,
		DaysOfWeek:       req.DaysOfWeek,
		GreetingTemplate: req.GreetingTemplate,
		IsActive:         true,
		NextTriggerAt:    &nextTrigger,
	}

	if err := ch.DB.Create(&checkin).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create scheduled check-in", "code": "db_error"})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"message": "Scheduled check-in created", "id": checkin.ID})
}

// UpdateScheduledCheckin updates an existing scheduled check-in.
func (ch *ChatController) UpdateScheduledCheckin(c *gin.Context) {
	checkinID, _ := uuid.Parse(c.Param("checkinId"))
	authedUser, _ := middleware.GetFullUserFromContext(c)

	var req UpdateCheckinRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data", "code": "validation_failed"})
		return
	}

	var checkin models.ScheduledCheckin
	if err := ch.DB.Where("id = ? AND user_id = ?", checkinID, authedUser.ID).First(&checkin).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Scheduled check-in not found", "code": "not_found"})
		return
	}

	scheduleChanged := false
	if req.ScheduleName != nil {
		checkin.ScheduleName = req.ScheduleName
	}
	if req.TimeOfDay != nil {
		if t, err := time.Parse("15:04", *req.TimeOfDay); err == nil {
			checkin.TimeOfDay = t
			scheduleChanged = true
		}
	}
	if req.DaysOfWeek != nil {
		checkin.DaysOfWeek = *req.DaysOfWeek
		scheduleChanged = true
	}
	if req.GreetingTemplate != nil {
		checkin.GreetingTemplate = req.GreetingTemplate
	}
	if req.IsActive != nil {
		checkin.IsActive = *req.IsActive
	}

	if scheduleChanged || (req.IsActive != nil && *req.IsActive) {
		nextTrigger := calculateNextTriggerTime(checkin.TimeOfDay, checkin.DaysOfWeek)
		checkin.NextTriggerAt = &nextTrigger
	} else if req.IsActive != nil && !*req.IsActive {
		checkin.NextTriggerAt = nil
	}

	if err := ch.DB.Save(&checkin).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update check-in", "code": "db_error"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Scheduled check-in updated"})
}

// DeleteScheduledCheckin deletes a scheduled check-in.
func (ch *ChatController) DeleteScheduledCheckin(c *gin.Context) {
	checkinID, _ := uuid.Parse(c.Param("checkinId"))
	authedUser, _ := middleware.GetFullUserFromContext(c)

	result := ch.DB.Where("id = ? AND user_id = ?", checkinID, authedUser.ID).Delete(&models.ScheduledCheckin{})
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Scheduled check-in not found", "code": "not_found"})
		return
	}
	c.Status(http.StatusNoContent)
}

// --- AI Integration ---
func (ch *ChatController) generateAIResponse(sessionID uuid.UUID, user models.User) (*models.ChatMessage, error) {
	log.Printf("🤖 [AI] Starting AI response generation for session: %s", sessionID)

	// Ambil konfigurasi
	apiKey := ch.Cfg.Azure.OpenAIAPIKey
	endpoint := ch.Cfg.Azure.OpenAIEndpoint
	deploymentName := ch.Cfg.Azure.OpenAIDeploymentName
	apiVersion := ch.Cfg.Azure.OpenAIAPIVersion

	// Enhanced logging untuk configuration
	log.Printf("🔧 [AI] Configuration check:")
	log.Printf("   Endpoint: %s", endpoint)
	log.Printf("   Deployment: %s", deploymentName)
	log.Printf("   API Version: %s", apiVersion)
	log.Printf("   API Key length: %d", len(apiKey))

	if apiKey == "" || endpoint == "" || deploymentName == "" {
		msg := fmt.Sprintf("Konfigurasi Azure OpenAI tidak lengkap - KEY:%t, ENDPOINT:%t, DEPLOYMENT:%t",
			apiKey != "", endpoint != "", deploymentName != "")
		log.Printf("❌ [AI] %s", msg)
		return nil, fmt.Errorf(msg)
	}

	// Setup Azure OpenAI client
	log.Printf("🔗 [AI] Creating Azure OpenAI client...")
	config := openai.DefaultAzureConfig(apiKey, endpoint)
	config.APIVersion = apiVersion
	client := openai.NewClientWithConfig(config)

	// Ambil history chat
	log.Printf("📚 [AI] Fetching chat history...")
	var history []models.ChatMessage
	ch.DB.Where("chat_session_id = ?", sessionID).Order("created_at DESC").Limit(10).Find(&history)

	// Reverse history to have correct chronological order
	for i, j := 0, len(history)-1; i < j; i, j = i+1, j-1 {
		history[i], history[j] = history[j], history[i]
	}

	log.Printf("📖 [AI] Found %d messages in history", len(history))

	// Prepare messages for Azure OpenAI
	systemPrompt := "You are Tenang Assistant, an empathetic and supportive AI friend from Indonesia. Your primary goal is to validate the user's feelings first before asking gentle, open-ended questions. Do not give direct advice unless it's about simple, general wellness like breathing exercises. Never diagnose. Keep responses concise and use a warm, supportive tone in Bahasa Indonesia or English, depending on the user's language used in the session. Always end with a question to encourage further sharing."

	messages := []openai.ChatCompletionMessage{
		{Role: openai.ChatMessageRoleSystem, Content: systemPrompt},
	}

	for _, msg := range history {
		role := openai.ChatMessageRoleUser
		if msg.SenderType == "ai_bot" {
			role = openai.ChatMessageRoleAssistant
		}
		messages = append(messages, openai.ChatCompletionMessage{
			Role:    role,
			Content: msg.MessageContent,
		})
		log.Printf("📝 [AI] Added %s message: %.50s...", msg.SenderType, msg.MessageContent)
	}

	// Prepare request
	req := openai.ChatCompletionRequest{
		Model:       deploymentName,
		Messages:    messages,
		MaxTokens:   150,
		Temperature: 0.7,
	}

	log.Printf("🚀 [AI] Sending request to Azure OpenAI...")
	log.Printf("   Model: %s", req.Model)
	log.Printf("   Messages count: %d", len(req.Messages))
	log.Printf("   Max tokens: %d", req.MaxTokens)

	// Make the API call with timing
	start := time.Now()
	resp, err := client.CreateChatCompletion(context.Background(), req)
	duration := time.Since(start)

	if err != nil {
		log.Printf("❌ [AI] Azure OpenAI API error (took %s): %v", duration, err)
		log.Printf("❌ [AI] Error type: %T", err)
		log.Printf("❌ [AI] Full error: %+v", err)
		return nil, fmt.Errorf("Azure OpenAI API error: %v", err)
	}

	log.Printf("✅ [AI] Azure OpenAI API call successful (took %s)", duration)
	log.Printf("📊 [AI] Token usage - Prompt: %d, Completion: %d, Total: %d",
		resp.Usage.PromptTokens, resp.Usage.CompletionTokens, resp.Usage.TotalTokens)

	if len(resp.Choices) == 0 {
		msg := "Azure OpenAI returned no response choices"
		log.Printf("❌ [AI] %s", msg)
		return nil, fmt.Errorf(msg)
	}

	aiResponseContent := resp.Choices[0].Message.Content
	log.Printf("🎯 [AI] Generated response: %.100s...", aiResponseContent)

	// Save to database
	log.Printf("💾 [AI] Saving AI message to database...")
	aiMessage := &models.ChatMessage{
		ChatSessionID:  sessionID,
		SenderType:     "ai_bot",
		MessageContent: aiResponseContent,
	}

	if err := ch.DB.Create(aiMessage).Error; err != nil {
		log.Printf("❌ [AI] Failed to save AI message to database: %v", err)
		return nil, fmt.Errorf("failed to save AI message: %v", err)
	}

	log.Printf("✅ [AI] AI message saved successfully with ID: %s", aiMessage.ID)
	log.Printf("🏁 [AI] AI response generation completed for session: %s", sessionID)

	return aiMessage, nil
}

// --- Helper Function ---

func calculateNextTriggerTime(timeOfDay time.Time, daysOfWeek []int64) time.Time {
	// (Logika ini diambil dari file Anda karena sudah sangat baik)
	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), timeOfDay.Hour(), timeOfDay.Minute(), 0, 0, now.Location())

	for i := 0; i < 7; i++ {
		nextDate := today.AddDate(0, 0, i)
		currentWeekday := int64(nextDate.Weekday()) // Days are 0 (Sun) to 6 (Sat)

		for _, scheduledDay := range daysOfWeek {
			if scheduledDay == currentWeekday {
				if nextDate.After(now) {
					return nextDate
				}
			}
		}
	}
	// If no suitable day found this week, find for next week
	return today.AddDate(0, 0, 7)
}
