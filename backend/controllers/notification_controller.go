package controllers

import (
	"net/http"
	"strconv"
	"time"
	"math"

	"backend/config"
	"backend/middleware"
	"backend/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type NotificationController struct {
	DB *gorm.DB
	Cfg *config.Config
}

func NewNotificationController(db *gorm.DB, cfg *config.Config) *NotificationController {
	return &NotificationController{DB: db, Cfg: cfg}
}

// --- DTOs and Request Structs ---

type NotificationResponse struct {
	ID               uuid.UUID  `json:"id"`
	UserID           uuid.UUID  `json:"user_id"`
	NotificationType string     `json:"notification_type"`
	Title            string     `json:"title"`
	Message          string     `json:"message"`
	ActionURL        *string    `json:"action_url,omitempty"`
	ActionData       string     `json:"action_data,omitempty"`
	Priority         string     `json:"priority"`
	IsRead           bool       `json:"is_read"`
	ReadAt           *time.Time `json:"read_at,omitempty"`
	CreatedAt        time.Time  `json:"created_at"`
}

type BroadcastRequest struct {
	NotificationType string `json:"notification_type" binding:"required"`
	Title            string `json:"title" binding:"required"`
	Message          string `json:"message" binding:"required"`
	ActionURL        string `json:"action_url"`
}


// --- Controller Handlers ---

// GetNotifications retrieves a user's notifications with filtering and pagination.
// ROUTE: GET /api/v1/notifications
func (n *NotificationController) GetNotifications(c *gin.Context) {
	authedUser, _ := middleware.GetFullUserFromContext(c)
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset := (page - 1) * limit

	// Build and apply filters
	query := n.DB.Where("user_id = ?", authedUser.ID)
	query = applyNotificationFilters(c, query)

	countQuery := n.DB.Model(&models.Notification{}).Where("user_id = ?", authedUser.ID)
	countQuery = applyNotificationFilters(c, countQuery)

	var notifications []models.Notification
	if err := query.Order("created_at DESC").Limit(limit).Offset(offset).Find(&notifications).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch notifications", "code": "db_error"})
		return
	}

	var totalCount int64
	countQuery.Count(&totalCount)

	// Map to DTOs
	responseItems := []NotificationResponse{}
	for _, notif := range notifications {
		responseItems = append(responseItems, mapNotificationToResponse(notif))
	}

	c.JSON(http.StatusOK, gin.H{
		"data": responseItems,
		"pagination": gin.H{
			"total_records": totalCount, "current_page": page, "page_size": limit,
			"total_pages": int(math.Ceil(float64(totalCount) / float64(limit))),
		},
	})
}

// GetUnreadCount retrieves the count of unread notifications for the user.
// ROUTE: GET /api/v1/notifications/unread-count
func (n *NotificationController) GetUnreadCount(c *gin.Context) {
    authedUser, _ := middleware.GetFullUserFromContext(c)

    var unreadCount int64
    n.DB.Model(&models.Notification{}).
        Where("user_id = ? AND is_read = ? AND (expires_at IS NULL OR expires_at > ?)", authedUser.ID, false, time.Now()).
        Count(&unreadCount)

    c.JSON(http.StatusOK, gin.H{"unread_count": unreadCount})
}

// MarkAsRead marks a single notification as read.
// ROUTE: PUT /api/v1/notifications/:notificationId/read
func (n *NotificationController) MarkAsRead(c *gin.Context) {
	notificationID, _ := uuid.Parse(c.Param("notificationId"))
	authedUser, _ := middleware.GetFullUserFromContext(c)

	var notification models.Notification
	if err := n.DB.Where("id = ? AND user_id = ?", notificationID, authedUser.ID).First(&notification).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Notification not found", "code": "not_found"})
		return
	}

	if !notification.IsRead {
		now := time.Now()
		notification.IsRead = true
		notification.ReadAt = &now
		n.DB.Save(&notification)
	}

	c.JSON(http.StatusOK, mapNotificationToResponse(notification))
}

// MarkAllAsRead marks all of a user's unread notifications as read.
// ROUTE: PUT /api/v1/notifications/read-all
func (n *NotificationController) MarkAllAsRead(c *gin.Context) {
	authedUser, _ := middleware.GetFullUserFromContext(c)
	now := time.Now()

	result := n.DB.Model(&models.Notification{}).
		Where("user_id = ? AND is_read = ?", authedUser.ID, false).
		Updates(map[string]interface{}{"is_read": true, "read_at": &now})

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to mark notifications as read", "code": "db_error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "All notifications marked as read", "updated_count": result.RowsAffected})
}

// DeleteNotification deletes a single notification.
// ROUTE: DELETE /api/v1/notifications/:notificationId
func (n *NotificationController) DeleteNotification(c *gin.Context) {
	notificationID, _ := uuid.Parse(c.Param("notificationId"))
	authedUser, _ := middleware.GetFullUserFromContext(c)

	result := n.DB.Where("id = ? AND user_id = ?", notificationID, authedUser.ID).Delete(&models.Notification{})
	if result.Error != nil || result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Notification not found or could not be deleted", "code": "not_found_or_failed"})
		return
	}

	c.Status(http.StatusNoContent)
}

// SendTestNotification creates a test notification for the authenticated user.
// ROUTE: POST /api/v1/notifications/test
func (n *NotificationController) SendTestNotification(c *gin.Context) {
    authedUser, _ := middleware.GetFullUserFromContext(c)

    testNotif := models.Notification{
        UserID:           authedUser.ID,
        NotificationType: "wellness_reminder",
        Title:            "Notification Test Successful",
        Message:          "This is a test notification to confirm your settings are working correctly.",
        Priority:         "normal",
        DeliveryMethod:   "push",
    }

    if err := n.DB.Create(&testNotif).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create test notification", "code": "db_error"})
        return
    }

    c.JSON(http.StatusCreated, gin.H{"message": "Test notification created successfully", "notification": mapNotificationToResponse(testNotif)})
}

// --- Admin Handlers ---

// BroadcastNotification sends a notification to all active users.
// ROUTE: POST /api/v1/admin/notifications/broadcast
func (n *NotificationController) BroadcastNotification(c *gin.Context) {
    var req BroadcastRequest
    if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data", "code": "validation_failed"})
		return
	}

    var userIDs []uuid.UUID
    n.DB.Model(&models.User{}).Where("is_active = ?", true).Pluck("id", &userIDs)

    if len(userIDs) == 0 {
        c.JSON(http.StatusOK, gin.H{"message": "No active users to broadcast to.", "users_targeted": 0})
        return
    }

    var newNotifications []models.Notification
    for _, userID := range userIDs {
        newNotifications = append(newNotifications, models.Notification{
            UserID:           userID,
            NotificationType: req.NotificationType,
            Title:            req.Title,
            Message:          req.Message,
            ActionURL:        &req.ActionURL,
            Priority:         "high",
            DeliveryMethod:   "push",
        })
    }

    if err := n.DB.Create(&newNotifications).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create broadcast notifications", "code": "db_batch_error"})
        return
    }

    c.JSON(http.StatusCreated, gin.H{"message": "Broadcast notification created for all active users.", "users_targeted": len(userIDs)})
}

// ProcessScheduledNotifications handles sending of scheduled notifications.
// ROUTE: POST /api/v1/admin/notifications/process-scheduled
func (n *NotificationController) ProcessScheduledNotifications(c *gin.Context) {
	// This function is kept from your original code, it's a good pattern.
	// In a real production environment, this endpoint would be protected and called by a trusted cron job service.
	now := time.Now()

	var scheduledNotifications []models.Notification
	if err := n.DB.Where("scheduled_for <= ? AND is_sent = ?", now, false).Find(&scheduledNotifications).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch scheduled notifications"})
		return
	}

	processedCount := 0
	for _, notification := range scheduledNotifications {
		go sendNotification(n.DB, notification.ID)
		processedCount++
	}

	c.JSON(http.StatusOK, gin.H{"message": "Scheduled notifications processed", "processedCount": processedCount})
}

// --- Helper Functions ---

// applyNotificationFilters is a helper to keep filter logic DRY.
func applyNotificationFilters(c *gin.Context, query *gorm.DB) *gorm.DB {
	if isRead := c.Query("isRead"); isRead != "" {
		if readBool, err := strconv.ParseBool(isRead); err == nil {
			query = query.Where("is_read = ?", readBool)
		}
	}
	if notificationType := c.Query("type"); notificationType != "" {
		query = query.Where("notification_type = ?", notificationType)
	}
	if priority := c.Query("priority"); priority != "" {
		query = query.Where("priority = ?", priority)
	}
	// Always exclude expired notifications
	query = query.Where("expires_at IS NULL OR expires_at > ?", time.Now())
	return query
}

// mapNotificationToResponse safely maps a notification model to its DTO.
func mapNotificationToResponse(notif models.Notification) NotificationResponse {
    return NotificationResponse{
        ID:               notif.ID,
        UserID:           notif.UserID,
        NotificationType: notif.NotificationType,
        Title:            notif.Title,
        Message:          notif.Message,
        ActionURL:        notif.ActionURL,
        ActionData:       notif.ActionData,
        Priority:         notif.Priority,
        IsRead:           notif.IsRead,
        ReadAt:           notif.ReadAt,
        CreatedAt:        notif.CreatedAt,
    }
}

// sendNotification simulates the sending of a notification.
func sendNotification(db *gorm.DB, notificationID uuid.UUID) {
	var notification models.Notification
	if err := db.First(&notification, notificationID).Error; err != nil {
		return // Notification not found
	}
	if notification.IsSent {
		return // Already sent
	}

	// TODO: Implement actual sending logic based on DeliveryMethod
	// switch notification.DeliveryMethod {
	// case "push": // pushService.Send(notification)
	// case "email": // emailService.Send(notification)
	// }

	// Mark as sent
	now := time.Now()
	notification.IsSent = true
	notification.SentAt = &now
	db.Save(&notification)
}