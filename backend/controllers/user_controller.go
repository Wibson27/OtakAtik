package controllers

import (
	"backend/models"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type UserController struct {
	DB *gorm.DB
}

// GetProfile returns user profile with preferences
func (u *UserController) GetProfile(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	var user models.User
	if err := u.DB.Preload("Preferences").Where("id = ? AND is_active = ?", userID, true).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Return user profile without sensitive data
	profile := gin.H{
		"id":              user.ID,
		"email":           user.Email,
		"username":        user.Username,
		"fullName":        user.FullName,
		"dateOfBirth":     user.DateOfBirth,
		"timezone":        user.Timezone,
		"privacyLevel":    user.PrivacyLevel,
		"emailVerifiedAt": user.EmailVerifiedAt,
		"lastActiveAt":    user.LastActiveAt,
		"createdAt":       user.CreatedAt,
		"preferences":     user.Preferences,
	}

	c.JSON(http.StatusOK, profile)
}

// UpdateProfile updates user profile information
func (u *UserController) UpdateProfile(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	type UpdateProfileRequest struct {
		FullName     *string `json:"fullName"`
		Username     *string `json:"username"`
		DateOfBirth  *string `json:"dateOfBirth"` // Format: YYYY-MM-DD
		Timezone     *string `json:"timezone"`
		PrivacyLevel *string `json:"privacyLevel"`
	}

	var req UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Find user
	var user models.User
	if err := u.DB.Where("id = ? AND is_active = ?", userID, true).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Check if username is taken (if being updated)
	if req.Username != nil && *req.Username != "" {
		var existingUser models.User
		if err := u.DB.Where("username = ? AND id != ?", *req.Username, userID).First(&existingUser).Error; err == nil {
			c.JSON(http.StatusConflict, gin.H{"error": "Username already taken"})
			return
		}
		user.Username = req.Username
	}

	// Update fields if provided
	if req.FullName != nil {
		user.FullName = req.FullName
	}

	if req.DateOfBirth != nil && *req.DateOfBirth != "" {
		if dob, err := time.Parse("2006-01-02", *req.DateOfBirth); err == nil {
			user.DateOfBirth = &dob
		} else {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid date format. Use YYYY-MM-DD"})
			return
		}
	}

	if req.Timezone != nil {
		user.Timezone = *req.Timezone
	}

	if req.PrivacyLevel != nil {
		if *req.PrivacyLevel == "minimal" || *req.PrivacyLevel == "standard" || *req.PrivacyLevel == "full" {
			user.PrivacyLevel = *req.PrivacyLevel
		} else {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid privacy level. Use: minimal, standard, or full"})
			return
		}
	}

	// Save updates
	if err := u.DB.Save(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update profile"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Profile updated successfully",
		"user": gin.H{
			"id":           user.ID,
			"email":        user.Email,
			"username":     user.Username,
			"fullName":     user.FullName,
			"dateOfBirth":  user.DateOfBirth,
			"timezone":     user.Timezone,
			"privacyLevel": user.PrivacyLevel,
		},
	})
}

// GetPreferences returns user preferences
func (u *UserController) GetPreferences(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	var preferences models.UserPreferences
	if err := u.DB.Where("user_id = ?", userID).First(&preferences).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Preferences not found"})
		return
	}

	c.JSON(http.StatusOK, preferences)
}

// UpdatePreferences updates user preferences
func (u *UserController) UpdatePreferences(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	type UpdatePreferencesRequest struct {
		NotificationChat          *bool   `json:"notificationChat"`
		NotificationCommunity     *bool   `json:"notificationCommunity"`
		NotificationSchedule      *string `json:"notificationSchedule"`
		CommunityAnonymousDefault *bool   `json:"communityAnonymousDefault"`
		SocialMediaMonitoring     *bool   `json:"socialMediaMonitoring"`
	}

	var req UpdatePreferencesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Find preferences
	var preferences models.UserPreferences
	if err := u.DB.Where("user_id = ?", userID).First(&preferences).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Preferences not found"})
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

	if req.CommunityAnonymousDefault != nil {
		preferences.CommunityAnonymousDefault = *req.CommunityAnonymousDefault
	}

	if req.SocialMediaMonitoring != nil {
		preferences.SocialMediaMonitoring = *req.SocialMediaMonitoring
	}

	// Save updates
	if err := u.DB.Save(&preferences).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update preferences"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":     "Preferences updated successfully",
		"preferences": preferences,
	})
}

// GetDashboardStats returns user dashboard statistics
func (u *UserController) GetDashboardStats(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Get various counts
	var chatSessionCount int64
	u.DB.Model(&models.ChatSession{}).Where("user_id = ?", userID).Count(&chatSessionCount)

	var vocalEntryCount int64
	u.DB.Model(&models.VocalJournalEntry{}).Where("user_id = ?", userID).Count(&vocalEntryCount)

	var communityPostCount int64
	u.DB.Model(&models.CommunityPost{}).Where("user_id = ? AND post_status = ?", userID, "published").Count(&communityPostCount)

	// Get recent activity
	var recentChatSessions []models.ChatSession
	u.DB.Where("user_id = ?", userID).Order("created_at DESC").Limit(3).Find(&recentChatSessions)

	var recentVocalEntries []models.VocalJournalEntry
	u.DB.Where("user_id = ?", userID).Order("created_at DESC").Limit(3).Find(&recentVocalEntries)

	// TODO: Calculate average wellbeing score from vocal analysis
	// SELECT AVG(overall_wellbeing_score) FROM vocal_sentiment_analysis
	// JOIN vocal_journal_entries ON vocal_sentiment_analysis.vocal_entry_id = vocal_journal_entries.id
	// WHERE vocal_journal_entries.user_id = ? AND vocal_sentiment_analysis.created_at >= ?

	var avgWellbeingScore float64
	subQuery := u.DB.Table("vocal_journal_entries").Select("id").Where("user_id = ?", userID)
	u.DB.Table("vocal_sentiment_analysis").
		Where("vocal_entry_id IN (?) AND created_at >= ?", subQuery, time.Now().AddDate(0, 0, -30)).
		Select("COALESCE(AVG(overall_wellbeing_score), 0)").
		Scan(&avgWellbeingScore)

	stats := gin.H{
		"chatSessions":      chatSessionCount,
		"vocalEntries":      vocalEntryCount,
		"communityPosts":    communityPostCount,
		"avgWellbeingScore": avgWellbeingScore,
		"recentActivity": gin.H{
			"chatSessions": recentChatSessions,
			"vocalEntries": recentVocalEntries,
		},
	}

	c.JSON(http.StatusOK, stats)
}

// GetProgressMetrics returns user progress metrics
func (u *UserController) GetProgressMetrics(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Get date range from query params (default to last 30 days)
	daysStr := c.DefaultQuery("days", "30")
	var days int
	if d, err := uuid.Parse(daysStr); err == nil {
		days = int(d.ID())
	} else {
		days = 30
	}

	startDate := time.Now().AddDate(0, 0, -days)

	var metrics []models.UserProgressMetric
	if err := u.DB.Where("user_id = ? AND metric_date >= ?", userID, startDate).
		Order("metric_date DESC").Find(&metrics).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch metrics"})
		return
	}

	// Group metrics by type
	groupedMetrics := make(map[string][]models.UserProgressMetric)
	for _, metric := range metrics {
		groupedMetrics[metric.MetricType] = append(groupedMetrics[metric.MetricType], metric)
	}

	c.JSON(http.StatusOK, gin.H{
		"metrics": groupedMetrics,
		"dateRange": gin.H{
			"startDate": startDate,
			"endDate":   time.Now(),
			"days":      days,
		},
	})
}

// DeactivateAccount deactivates user account (soft delete)
func (u *UserController) DeactivateAccount(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	type DeactivateRequest struct {
		Reason string `json:"reason"`
	}

	var req DeactivateRequest
	c.ShouldBindJSON(&req) // Optional reason

	// Find user
	var user models.User
	if err := u.DB.Where("id = ? AND is_active = ?", userID, true).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Deactivate user
	user.IsActive = false
	now := time.Now()
	user.DeletedAt = &now

	if err := u.DB.Save(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to deactivate account"})
		return
	}

	// TODO: Add audit log entry for account deactivation
	// auditLog := models.AuditLog{
	//     UserID: &userID,
	//     Action: "ACCOUNT_DEACTIVATED",
	//     NewValues: req.Reason,
	// }
	// u.DB.Create(&auditLog)

	c.JSON(http.StatusOK, gin.H{"message": "Account deactivated successfully"})
}
