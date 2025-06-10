package controllers

import (
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
	ScheduleName     *string `json:"schedule_name"`
	TimeOfDay        *string `json:"time_of_day"`
	DaysOfWeek       *[]int64 `json:"days_of_week"`
	GreetingTemplate *string `json:"greeting_template"`
	IsActive         *bool   `json:"is_active"`
}


// --- Chat Session Handlers ---

// CreateSession creates a new chat session for the authenticated user.
func (ch *ChatController) CreateSession(c *gin.Context) {
	var req CreateSessionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data", "code": "validation_failed"})
		return
	}

	authedUser, _ := middleware.GetFullUserFromContext(c)
	session := models.ChatSession{
		UserID:        authedUser.ID,
		TriggerType:   req.TriggerType,
		StartedAt:     time.Now(),
		SessionStatus: "active",
	}
	if req.SessionTitle != "" {
		session.SessionTitle = &req.SessionTitle
	}

	if err := ch.DB.Create(&session).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create chat session", "code": "db_error"})
		return
	}

	// Mengirim kembali respons dalam bentuk DTO
	c.JSON(http.StatusCreated, ChatSessionResponse{
		ID:            session.ID,
		UserID:        session.UserID,
		SessionTitle:  session.SessionTitle,
		TriggerType:   session.TriggerType,
		SessionStatus: session.SessionStatus,
		StartedAt:     session.StartedAt,
	})
}

// GetSessions retrieves paginated chat sessions for the authenticated user.
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

	query.Order("started_at DESC").Limit(limit).Offset(offset).Find(&sessions)

	var response []ChatSessionResponse
	for _, s := range sessions {
		response = append(response, ChatSessionResponse{
			ID: s.ID, UserID: s.UserID, SessionTitle: s.SessionTitle, TriggerType: s.TriggerType,
			SessionStatus: s.SessionStatus, MessageCount: s.MessageCount, SessionDurationSeconds: s.SessionDurationSeconds,
			StartedAt: s.StartedAt, EndedAt: s.EndedAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{"data": response})
}

// GetSession retrieves messages for a specific chat session.
func (ch *ChatController) GetSession(c *gin.Context) {
	sessionID, _ := uuid.Parse(c.Param("sessionId"))
	authedUser, _ := middleware.GetFullUserFromContext(c)

	var session models.ChatSession
	if err := ch.DB.Where("id = ? AND user_id = ?", sessionID, authedUser.ID).First(&session).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied to this session", "code": "forbidden"})
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

	c.JSON(http.StatusOK, response)
}

// SendMessage sends a user message and triggers an AI response.
func (ch *ChatController) SendMessage(c *gin.Context) {
	var req SendMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data", "code": "validation_failed"})
		return
	}

	authedUser, _ := middleware.GetFullUserFromContext(c)

	var session models.ChatSession
	if err := ch.DB.Where("id = ? AND user_id = ? AND session_status = 'active'", req.SessionID, authedUser.ID).First(&session).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": "Active session not found or access denied", "code": "session_inactive_or_forbidden"})
		return
	}

	userMessage := models.ChatMessage{
		ChatSessionID:  req.SessionID,
		SenderType:     "user",
		MessageContent: req.MessageContent,
	}
	if err := ch.DB.Create(&userMessage).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save message", "code": "db_error"})
		return
	}

	go ch.generateAIResponse(session.ID, req.MessageContent)

	c.JSON(http.StatusCreated, ChatMessageResponse{
		ID: userMessage.ID, ChatSessionID: userMessage.ChatSessionID, SenderType: userMessage.SenderType,
		MessageContent: userMessage.MessageContent, CreatedAt: userMessage.CreatedAt,
	})
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
	if req.ScheduleName != nil { checkin.ScheduleName = req.ScheduleName }
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
	if req.GreetingTemplate != nil { checkin.GreetingTemplate = req.GreetingTemplate }
	if req.IsActive != nil { checkin.IsActive = *req.IsActive }

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

func (ch *ChatController) generateAIResponse(sessionID uuid.UUID, userMessage string) {
	log.Printf("Starting AI response generation for session: %s", sessionID)

	// ---- Ini adalah bagian di mana Anda akan berintegrasi dengan Azure OpenAI ----
	// 1. Ambil API Key & Endpoint dari konfigurasi yang sudah di-load dari .env
	apiKey := ch.Cfg.Azure.OpenAIAPIKey
	endpoint := ch.Cfg.Azure.OpenAIEndpoint
	if apiKey == "" || endpoint == "" {
		log.Println("WARNING: AZURE_OPENAI_API_KEY or AZURE_OPENAI_ENDPOINT is not set. Skipping AI response.")
		return
	}

	// 2. Siapkan OpenAI client configuration untuk Azure
	// config := openai.DefaultAzureConfig(apiKey, endpoint)
	// client := openai.NewClientWithConfig(config)

	// 3. Ambil beberapa pesan terakhir sebagai konteks percakapan
	var history []models.ChatMessage
	ch.DB.Where("chat_session_id = ?", sessionID).Order("created_at DESC").Limit(5).Find(&history)

	// 4. Buat prompt untuk AI sesuai dengan persona "Tenang Assistant"
	// Referensi: Dokumentasi Fitur 2.1.2 AI Response System
	systemPrompt := "You are Tenang Assistant, an empathetic and supportive AI friend from Indonesia. Your primary goal is to validate the user's feelings first before asking gentle, open-ended questions. Do not give direct advice unless it's about simple, general wellness like breathing exercises. Never diagnose. Keep responses concise and use a warm, supportive tone in Bahasa Indonesia."

	messages := []openai.ChatCompletionMessage{
		{Role: openai.ChatMessageRoleSystem, Content: systemPrompt},
	}
	// Tambahkan history ke messages...
	for i := len(history) - 1; i >= 0; i-- {
		role := openai.ChatMessageRoleUser
		if history[i].SenderType == "ai_bot" {
			role = openai.ChatMessageRoleAssistant
		}
		messages = append(messages, openai.ChatCompletionMessage{Role: role, Content: history[i].MessageContent})
	}
	messages = append(messages, openai.ChatCompletionMessage{Role: openai.ChatMessageRoleUser, Content: userMessage})

	// 5. Buat request ke Azure OpenAI
	// req := openai.ChatCompletionRequest{
	// 	Model:    openai.GPT3Dot5Turbo, // Atau model lain yang Anda deploy di Azure
	// 	Messages: messages,
	// 	MaxTokens: 150,
	// }

	// 6. Panggil API (bagian ini di-comment-out, ganti dengan panggilan nyata saat Anda punya API Key)
	// resp, err := client.CreateChatCompletion(context.Background(), req)
	// if err != nil {
	// 	log.Printf("ERROR: Azure OpenAI completion error for session %s: %v", sessionID, err)
	// 	return
	// }
	// aiResponseContent := resp.Choices[0].Message.Content

	// --- Gunakan response palsu untuk pengembangan ---
	time.Sleep(2 * time.Second) // Simulasi waktu respons AI
	aiResponseContent := fmt.Sprintf("Terima kasih sudah berbagi, saya mengerti perasaan '%s' itu tidak mudah. Ada hal spesifik yang memicu perasaan ini?", userMessage)


	// 7. Simpan respons AI ke database
	aiMessage := models.ChatMessage{
		ChatSessionID:  sessionID,
		SenderType:     "ai_bot",
		MessageContent: aiResponseContent,
	}
	if err := ch.DB.Create(&aiMessage).Error; err != nil {
		log.Printf("ERROR: Failed to save AI message for session %s: %v", sessionID, err)
	} else {
		log.Printf("AI response saved successfully for session %s", sessionID)
	}
	// TODO: Kirim notifikasi ke user via WebSocket bahwa ada balasan baru.
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
	return today.AddDate(0,0,7)
}