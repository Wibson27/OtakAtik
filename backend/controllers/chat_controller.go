package controllers

import (
	"backend/models"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ChatController struct {
	DB *gorm.DB
}

// CreateSession creates a new chat session
func (ch *ChatController) CreateSession(c *gin.Context) {
	type CreateSessionRequest struct {
		SessionTitle    string `json:"sessionTitle"`
		TriggerType     string `json:"triggerType" binding:"required"` // user_initiated, social_media_alert, scheduled_checkin, crisis_intervention
		TriggerSourceID string `json:"triggerSourceId"`
	}

	var req CreateSessionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Get user ID from JWT token
	userIDStr := c.Param("userId") // Temporary: get from URL param
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Validate trigger type
	validTriggerTypes := []string{"user_initiated", "social_media_alert", "scheduled_checkin", "crisis_intervention"}
	isValidTrigger := false
	for _, triggerType := range validTriggerTypes {
		if req.TriggerType == triggerType {
			isValidTrigger = true
			break
		}
	}
	if !isValidTrigger {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid trigger type"})
		return
	}

	// Parse trigger source ID if provided
	var triggerSourceID *uuid.UUID
	if req.TriggerSourceID != "" {
		if id, err := uuid.Parse(req.TriggerSourceID); err == nil {
			triggerSourceID = &id
		}
	}

	// Create chat session
	session := models.ChatSession{
		UserID:          userID,
		TriggerType:     req.TriggerType,
		TriggerSourceID: triggerSourceID,
		SessionStatus:   "active",
		MessageCount:    0,
	}

	if req.SessionTitle != "" {
		session.SessionTitle = &req.SessionTitle
	}

	if err := ch.DB.Create(&session).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create chat session"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Chat session created successfully",
		"session": session,
	})
}

// GetSessions returns user's chat sessions
func (ch *ChatController) GetSessions(c *gin.Context) {
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
	status := c.Query("status") // active, completed, abandoned

	query := ch.DB.Where("user_id = ?", userID)
	if status != "" {
		query = query.Where("session_status = ?", status)
	}

	var sessions []models.ChatSession
	if err := query.Order("created_at DESC").Limit(limit).Offset(offset).Find(&sessions).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch sessions"})
		return
	}

	// Get total count for pagination
	var totalCount int64
	countQuery := ch.DB.Model(&models.ChatSession{}).Where("user_id = ?", userID)
	if status != "" {
		countQuery = countQuery.Where("session_status = ?", status)
	}
	countQuery.Count(&totalCount)

	c.JSON(http.StatusOK, gin.H{
		"sessions": sessions,
		"pagination": gin.H{
			"page":       page,
			"limit":      limit,
			"totalCount": totalCount,
			"totalPages": (totalCount + int64(limit) - 1) / int64(limit),
		},
	})
}

// GetSession returns a specific chat session with messages
func (ch *ChatController) GetSession(c *gin.Context) {
	sessionIDStr := c.Param("sessionId")
	sessionID, err := uuid.Parse(sessionIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid session ID"})
		return
	}

	var session models.ChatSession
	if err := ch.DB.Preload("Messages", func(db *gorm.DB) *gorm.DB {
		return db.Order("created_at ASC")
	}).Where("id = ?", sessionID).First(&session).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Session not found"})
		return
	}

	c.JSON(http.StatusOK, session)
}

// SendMessage sends a message in a chat session
func (ch *ChatController) SendMessage(c *gin.Context) {
	type SendMessageRequest struct {
		SessionID       string `json:"sessionId" binding:"required"`
		MessageContent  string `json:"messageContent" binding:"required"`
		SenderType      string `json:"senderType" binding:"required"` // user, ai_bot
		MessageMetadata string `json:"messageMetadata"`
	}

	var req SendMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate sender type
	if req.SenderType != "user" && req.SenderType != "ai_bot" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid sender type. Use 'user' or 'ai_bot'"})
		return
	}

	sessionID, err := uuid.Parse(req.SessionID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid session ID"})
		return
	}

	// Verify session exists and is active
	var session models.ChatSession
	if err := ch.DB.Where("id = ? AND session_status = ?", sessionID, "active").First(&session).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Active session not found"})
		return
	}

	// Create message
	message := models.ChatMessage{
		ChatSessionID:  sessionID,
		SenderType:     req.SenderType,
		MessageContent: req.MessageContent,
	}

	if req.MessageMetadata != "" {
		message.MessageMetadata = req.MessageMetadata
	}

	if err := ch.DB.Create(&message).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send message"})
		return
	}

	// If this is a user message, trigger AI response
	if req.SenderType == "user" {
		go ch.generateAIResponse(sessionID, req.MessageContent)
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Message sent successfully",
		"data":    message,
	})
}

// generateAIResponse generates AI response (placeholder for AI integration)
func (ch *ChatController) generateAIResponse(sessionID uuid.UUID, userMessage string) {
	// TODO: Integrate with AI service (OpenAI, Claude, etc.)
	// This is a placeholder function that would:
	// 1. Send user message to AI service
	// 2. Get AI response
	// 3. Analyze sentiment if needed
	// 4. Store AI response as a new message

	time.Sleep(2 * time.Second) // Simulate processing time

	// Example AI response (in real implementation, this would come from AI service)
	aiResponse := "Thank you for sharing. I understand that you're going through a difficult time. Can you tell me more about what's been causing you stress lately?"

	// TODO: Call sentiment analysis service
	// sentiment := analyzeSentiment(userMessage)

	aiMessage := models.ChatMessage{
		ChatSessionID:  sessionID,
		SenderType:     "ai_bot",
		MessageContent: aiResponse,
		ResponseTimeMs: func() *int { ms := 2000; return &ms }(), // 2 seconds
		// SentimentScore: sentiment.Score,
		// EmotionDetected: sentiment.Emotion,
	}

	ch.DB.Create(&aiMessage)
}

// EndSession ends a chat session
func (ch *ChatController) EndSession(c *gin.Context) {
	sessionIDStr := c.Param("sessionId")
	sessionID, err := uuid.Parse(sessionIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid session ID"})
		return
	}

	type EndSessionRequest struct {
		Status string `json:"status"` // completed, abandoned
	}

	var req EndSessionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate status
	if req.Status != "completed" && req.Status != "abandoned" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid status. Use 'completed' or 'abandoned'"})
		return
	}

	// Find active session
	var session models.ChatSession
	if err := ch.DB.Where("id = ? AND session_status = ?", sessionID, "active").First(&session).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Active session not found"})
		return
	}

	// Calculate session duration
	duration := int(time.Since(session.StartedAt).Seconds())
	now := time.Now()

	// Update session
	session.SessionStatus = req.Status
	session.EndedAt = &now
	session.SessionDurationSeconds = &duration

	if err := ch.DB.Save(&session).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to end session"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Session ended successfully",
		"session": session,
	})
}

// GetScheduledCheckins returns user's scheduled check-ins
func (ch *ChatController) GetScheduledCheckins(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	var checkins []models.ScheduledCheckin
	if err := ch.DB.Where("user_id = ?", userID).Order("next_trigger_at ASC").Find(&checkins).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch scheduled check-ins"})
		return
	}

	c.JSON(http.StatusOK, checkins)
}

// CreateScheduledCheckin creates a new scheduled check-in
func (ch *ChatController) CreateScheduledCheckin(c *gin.Context) {
	type CreateCheckinRequest struct {
		ScheduleName     string  `json:"scheduleName"`
		TimeOfDay        string  `json:"timeOfDay" binding:"required"`  // Format: "15:04"
		DaysOfWeek       []int64 `json:"daysOfWeek" binding:"required"` // 0=Sunday, 1=Monday, etc.
		GreetingTemplate string  `json:"greetingTemplate"`
	}

	var req CreateCheckinRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Parse time
	timeOfDay, err := time.Parse("15:04", req.TimeOfDay)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid time format. Use HH:MM (24-hour format)"})
		return
	}

	// Validate days of week
	for _, day := range req.DaysOfWeek {
		if day < 0 || day > 6 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid day of week. Use 0-6 (0=Sunday)"})
			return
		}
	}

	// Create scheduled check-in
	checkin := models.ScheduledCheckin{
		UserID:     userID,
		TimeOfDay:  timeOfDay,
		DaysOfWeek: req.DaysOfWeek,
		IsActive:   true,
	}

	if req.ScheduleName != "" {
		checkin.ScheduleName = &req.ScheduleName
	}

	if req.GreetingTemplate != "" {
		checkin.GreetingTemplate = &req.GreetingTemplate
	}

	// Calculate next trigger time
	nextTrigger := calculateNextTriggerTime(timeOfDay, req.DaysOfWeek)
	checkin.NextTriggerAt = &nextTrigger

	if err := ch.DB.Create(&checkin).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create scheduled check-in"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Scheduled check-in created successfully",
		"checkin": checkin,
	})
}

// UpdateScheduledCheckin updates a scheduled check-in
func (ch *ChatController) UpdateScheduledCheckin(c *gin.Context) {
	checkinIDStr := c.Param("checkinId")
	checkinID, err := uuid.Parse(checkinIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid check-in ID"})
		return
	}

	type UpdateCheckinRequest struct {
		ScheduleName     *string  `json:"scheduleName"`
		TimeOfDay        *string  `json:"timeOfDay"`  // Format: "15:04"
		DaysOfWeek       *[]int64 `json:"daysOfWeek"` // 0=Sunday, 1=Monday, etc.
		GreetingTemplate *string  `json:"greetingTemplate"`
		IsActive         *bool    `json:"isActive"`
	}

	var req UpdateCheckinRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Find check-in
	var checkin models.ScheduledCheckin
	if err := ch.DB.Where("id = ?", checkinID).First(&checkin).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Scheduled check-in not found"})
		return
	}

	// Update fields if provided
	if req.ScheduleName != nil {
		checkin.ScheduleName = req.ScheduleName
	}

	if req.TimeOfDay != nil {
		if timeOfDay, err := time.Parse("15:04", *req.TimeOfDay); err == nil {
			checkin.TimeOfDay = timeOfDay
		} else {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid time format. Use HH:MM (24-hour format)"})
			return
		}
	}

	if req.DaysOfWeek != nil {
		checkin.DaysOfWeek = *req.DaysOfWeek
	}

	if req.GreetingTemplate != nil {
		checkin.GreetingTemplate = req.GreetingTemplate
	}

	if req.IsActive != nil {
		checkin.IsActive = *req.IsActive
	}

	// Recalculate next trigger time if schedule changed
	if req.TimeOfDay != nil || req.DaysOfWeek != nil {
		nextTrigger := calculateNextTriggerTime(checkin.TimeOfDay, checkin.DaysOfWeek)
		checkin.NextTriggerAt = &nextTrigger
	}

	if err := ch.DB.Save(&checkin).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update scheduled check-in"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Scheduled check-in updated successfully",
		"checkin": checkin,
	})
}

// DeleteScheduledCheckin deletes a scheduled check-in
func (ch *ChatController) DeleteScheduledCheckin(c *gin.Context) {
	checkinIDStr := c.Param("checkinId")
	checkinID, err := uuid.Parse(checkinIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid check-in ID"})
		return
	}

	if err := ch.DB.Delete(&models.ScheduledCheckin{}, checkinID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete scheduled check-in"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Scheduled check-in deleted successfully"})
}

// Helper function to calculate next trigger time
func calculateNextTriggerTime(timeOfDay time.Time, daysOfWeek []int64) time.Time {
	now := time.Now()
	currentWeekday := int64(now.Weekday())

	// Create time for today with the specified time
	today := time.Date(now.Year(), now.Month(), now.Day(),
		timeOfDay.Hour(), timeOfDay.Minute(), 0, 0, now.Location())

	// Find the next occurrence
	for i := 0; i < 7; i++ {
		checkDay := (currentWeekday + int64(i)) % 7
		checkDate := today.AddDate(0, 0, i)

		// Check if this day is in the schedule
		for _, day := range daysOfWeek {
			if day == checkDay {
				// If it's today, make sure the time hasn't passed
				if i == 0 && checkDate.Before(now) {
					continue
				}
				return checkDate
			}
		}
	}

	// If no day found in next 7 days, return next week's first scheduled day
	return today.AddDate(0, 0, 7)
}
