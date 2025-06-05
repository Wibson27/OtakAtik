package controllers

import (
	"net/http"
	"strconv"
	"backend/models"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type NotificationController struct {
	DB *gorm.DB
}

// GetNotifications returns user's notifications with pagination
func (n *NotificationController) GetNotifications(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Pagination parameters
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset := (page - 1) * limit

	// Filter parameters
	isRead := c.Query("isRead")           // true, false, or empty for all
	notificationType := c.Query("type")   // specific notification type
	priority := c.Query("priority")       // low, normal, high, urgent

	query := n.DB.Where("user_id = ?", userID)

	// Apply filters
	if isRead != "" {
		if readBool, err := strconv.ParseBool(isRead); err == nil {
			query = query.Where("is_read = ?", readBool)
		}
	}

	if notificationType != "" {
		query = query.Where("notification_type = ?", notificationType)
	}

	if priority != "" {
		query = query.Where("priority = ?", priority)
	}

	// Exclude expired notifications
	query = query.Where("expires_at IS NULL OR expires_at > ?", time.Now())

	var notifications []models.Notification
	if err := query.Order("created_at DESC").Limit(limit).Offset(offset).Find(&notifications).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch notifications"})
		return
	}

	// Get total count for pagination
	var totalCount int64
	countQuery := n.DB.Model(&models.Notification{}).Where("user_id = ?", userID)
	if isRead != "" {
		if readBool, err := strconv.ParseBool(isRead); err == nil {
			countQuery = countQuery.Where("is_read = ?", readBool)
		}
	}
	if notificationType != "" {
		countQuery = countQuery.Where("notification_type = ?", notificationType)
	}
	if priority != "" {
		countQuery = countQuery.Where("priority = ?", priority)
	}
	countQuery = countQuery.Where("expires_at IS NULL OR expires_at > ?", time.Now())
	countQuery.Count(&totalCount)

	// Get unread count
	var unreadCount int64
	n.DB.Model(&models.Notification{}).Where("user_id = ? AND is_read = ? AND (expires_at IS NULL OR expires_at > ?)",
		userID, false, time.Now()).Count(&unreadCount)

	c.JSON(http.StatusOK, gin.H{
		"notifications": notifications,
		"pagination": gin.H{
			"page":       page,
			"limit":      limit,
			"totalCount": totalCount,
			"totalPages": (totalCount + int64(limit) - 1) / int64(limit),
		},
		"unreadCount": unreadCount,
	})
}

// MarkAsRead marks a notification as read
func (n *NotificationController) MarkAsRead(c *gin.Context) {
	notificationIDStr := c.Param("notificationId")
	notificationID, err := uuid.Parse(notificationIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid notification ID"})
		return
	}

	// TODO: Get user ID from JWT token
	userIDStr := c.Param("userId") // Temporary: get from URL param
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Find notification and verify ownership
	var notification models.Notification
	if err := n.DB.Where("id = ? AND user_id = ?", notificationID, userID).First(&notification).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Notification not found"})
		return
	}

	// Mark as read
	if !notification.IsRead {
		now := time.Now()
		notification.IsRead = true
		notification.ReadAt = &now

		if err := n.DB.Save(&notification).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to mark notification as read"})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"message":      "Notification marked as read",
		"notification": notification,
	})
}

// MarkAllAsRead marks all unread notifications as read for a user
func (n *NotificationController) MarkAllAsRead(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	now := time.Now()
	result := n.DB.Model(&models.Notification{}).
		Where("user_id = ? AND is_read = ?", userID, false).
		Updates(models.Notification{
			IsRead: true,
			ReadAt: &now,
		})

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to mark notifications as read"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":        "All notifications marked as read",
		"updatedCount":   result.RowsAffected,
	})
}

// DeleteNotification deletes a notification
func (n *NotificationController) DeleteNotification(c *gin.Context) {
	notificationIDStr := c.Param("notificationId")
	notificationID, err := uuid.Parse(notificationIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid notification ID"})
		return
	}

	// TODO: Get user ID from JWT token
	userIDStr := c.Param("userId") // Temporary: get from URL param
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Delete notification (verify ownership)
	result := n.DB.Where("id = ? AND user_id = ?", notificationID, userID).Delete(&models.Notification{})
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete notification"})
		return
	}

	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Notification not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Notification deleted successfully"})
}

// CreateNotification creates a new notification (internal use)
func (n *NotificationController) CreateNotification(c *gin.Context) {
	type CreateNotificationRequest struct {
		UserID           string     `json:"userId" binding:"required"`
		NotificationType string     `json:"notificationType" binding:"required"`
		Title            string     `json:"title" binding:"required"`
		Message          string     `json:"message" binding:"required"`
		ActionURL        string     `json:"actionUrl"`
		ActionData       string     `json:"actionData"`
		Priority         string     `json:"priority"`
		DeliveryMethod   string     `json:"deliveryMethod"`
		ScheduledFor     *time.Time `json:"scheduledFor"`
		ExpiresAt        *time.Time `json:"expiresAt"`
	}

	var req CreateNotificationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, err := uuid.Parse(req.UserID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Validate notification type
	validTypes := []string{"chat_checkin", "community_reply", "community_reaction", "social_media_alert", "wellness_reminder"}
	if !contains(validTypes, req.NotificationType) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid notification type"})
		return
	}

	// Validate priority
	if req.Priority == "" {
		req.Priority = "normal"
	}
	validPriorities := []string{"low", "normal", "high", "urgent"}
	if !contains(validPriorities, req.Priority) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid priority"})
		return
	}

	// Validate delivery method
	if req.DeliveryMethod == "" {
		req.DeliveryMethod = "push"
	}
	validMethods := []string{"push", "email", "in_app"}
	if !contains(validMethods, req.DeliveryMethod) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid delivery method"})
		return
	}

	// Create notification
	notification := models.Notification{
		UserID:           userID,
		NotificationType: req.NotificationType,
		Title:            req.Title,
		Message:          req.Message,
		Priority:         req.Priority,
		DeliveryMethod:   req.DeliveryMethod,
		ScheduledFor:     req.ScheduledFor,
		ExpiresAt:        req.ExpiresAt,
	}

	if req.ActionURL != "" {
		notification.ActionURL = &req.ActionURL
	}

	if req.ActionData != "" {
		notification.ActionData = req.ActionData
	}

	if err := n.DB.Create(&notification).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create notification"})
		return
	}

	// If not scheduled, send immediately
	if req.ScheduledFor == nil || req.ScheduledFor.Before(time.Now()) {
		go n.sendNotification(notification.ID)
	}

	c.JSON(http.StatusCreated, gin.H{
		"message":      "Notification created successfully",
		"notification": notification,
	})
}

// sendNotification handles the actual sending of notifications
func (n *NotificationController) sendNotification(notificationID uuid.UUID) {
	var notification models.Notification
	if err := n.DB.First(&notification, notificationID).Error; err != nil {
		return
	}

	// Skip if already sent
	if notification.IsSent {
		return
	}

	// TODO: Implement actual notification sending based on delivery method
	switch notification.DeliveryMethod {
	case "push":
		// Send push notification via FCM, APNs, etc.
		// pushService.Send(notification)
	case "email":
		// Send email notification
		// emailService.Send(notification)
	case "in_app":
		// In-app notifications are handled by the client polling the API
		// No additional action needed
	}

	// Mark as sent
	now := time.Now()
	notification.IsSent = true
	notification.SentAt = &now
	n.DB.Save(&notification)
}

// GetNotificationSettings returns user's notification preferences
func (n *NotificationController) GetNotificationSettings(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	var preferences models.UserPreferences
	if err := n.DB.Where("user_id = ?", userID).First(&preferences).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User preferences not found"})
		return
	}

	// Return only notification-related settings
	settings := gin.H{
		"notificationChat":       preferences.NotificationChat,
		"notificationCommunity":  preferences.NotificationCommunity,
		"notificationSchedule":   preferences.NotificationSchedule,
		"socialMediaMonitoring":  preferences.SocialMediaMonitoring,
	}

	c.JSON(http.StatusOK, settings)
}

// UpdateNotificationSettings updates user's notification preferences
func (n *NotificationController) UpdateNotificationSettings(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	type UpdateSettingsRequest struct {
		NotificationChat      *bool   `json:"notificationChat"`
		NotificationCommunity *bool   `json:"notificationCommunity"`
		NotificationSchedule  *string `json:"notificationSchedule"`
		SocialMediaMonitoring *bool   `json:"socialMediaMonitoring"`
	}

	var req UpdateSettingsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Find preferences
	var preferences models.UserPreferences
	if err := n.DB.Where("user_id = ?", userID).First(&preferences).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User preferences not found"})
		return
	}

	// Update fields if provided
	if req.NotificationChat != nil {
		preferences.NotificationChat = *req.NotificationChat
	}

	if req.NotificationCommunity != nil {
		preferences.NotificationCommunity = *req.NotificationCommunity
	}

	if req.NotificationSchedule != nil {
		preferences.NotificationSchedule = *req.NotificationSchedule
	}

	if req.SocialMediaMonitoring != nil {
		preferences.SocialMediaMonitoring = *req.SocialMediaMonitoring
	}

	// Save updates
	if err := n.DB.Save(&preferences).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update notification settings"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Notification settings updated successfully",
		"settings": gin.H{
			"notificationChat":       preferences.NotificationChat,
			"notificationCommunity":  preferences.NotificationCommunity,
			"notificationSchedule":   preferences.NotificationSchedule,
			"socialMediaMonitoring":  preferences.SocialMediaMonitoring,
		},
	})
}

// GetNotificationStats returns notification statistics for a user
func (n *NotificationController) GetNotificationStats(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Get counts by type and status
	type NotificationStat struct {
		NotificationType string `json:"notificationType"`
		Total            int64  `json:"total"`
		Unread           int64  `json:"unread"`
		Read             int64  `json:"read"`
	}

	var stats []NotificationStat
	query := `
		SELECT
			notification_type,
			COUNT(*) as total,
			COUNT(CASE WHEN is_read = false THEN 1 END) as unread,
			COUNT(CASE WHEN is_read = true THEN 1 END) as read
		FROM notifications
		WHERE user_id = ? AND (expires_at IS NULL OR expires_at > ?)
		GROUP BY notification_type
		ORDER BY notification_type
	`

	if err := n.DB.Raw(query, userID, time.Now()).Scan(&stats).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch notification stats"})
		return
	}

	// Get overall totals
	var totalNotifications, totalUnread int64
	n.DB.Model(&models.Notification{}).Where("user_id = ? AND (expires_at IS NULL OR expires_at > ?)",
		userID, time.Now()).Count(&totalNotifications)
	n.DB.Model(&models.Notification{}).Where("user_id = ? AND is_read = ? AND (expires_at IS NULL OR expires_at > ?)",
		userID, false, time.Now()).Count(&totalUnread)

	c.JSON(http.StatusOK, gin.H{
		"stats": stats,
		"summary": gin.H{
			"totalNotifications": totalNotifications,
			"totalUnread":        totalUnread,
			"totalRead":          totalNotifications - totalUnread,
		},
	})
}

// ProcessScheduledNotifications processes notifications that are scheduled to be sent
// This would typically be called by a background job/cron
func (n *NotificationController) ProcessScheduledNotifications(c *gin.Context) {
	now := time.Now()

	var scheduledNotifications []models.Notification
	if err := n.DB.Where("scheduled_for <= ? AND is_sent = ? AND (expires_at IS NULL OR expires_at > ?)",
		now, false, now).Find(&scheduledNotifications).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch scheduled notifications"})
		return
	}

	processedCount := 0
	for _, notification := range scheduledNotifications {
		go n.sendNotification(notification.ID)
		processedCount++
	}

	c.JSON(http.StatusOK, gin.H{
		"message":        "Scheduled notifications processed",
		"processedCount": processedCount,
	})
}