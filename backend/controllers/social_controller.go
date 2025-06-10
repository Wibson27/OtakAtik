package controllers

import (
	"backend/models"
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"io"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SocialController struct {
	DB *gorm.DB
}

// ConnectAccount connects a social media account
func (s *SocialController) ConnectAccount(c *gin.Context) {
	type ConnectAccountRequest struct {
		Platform          string `json:"platform" binding:"required"` // instagram, twitter, facebook, tiktok
		PlatformUserID    string `json:"platformUserId" binding:"required"`
		PlatformUsername  string `json:"platformUsername"`
		AccessToken       string `json:"accessToken" binding:"required"`
		TokenExpiresAt    string `json:"tokenExpiresAt"` // ISO 8601 format
		MonitoringEnabled bool   `json:"monitoringEnabled"`
	}

	var req ConnectAccountRequest
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

	// Validate platform
	validPlatforms := []string{"instagram", "twitter", "facebook", "tiktok"}
	if !contains(validPlatforms, req.Platform) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid platform. Supported: instagram, twitter, facebook, tiktok"})
		return
	}

	// Check if account already connected for this platform
	var existingAccount models.SocialMediaAccount
	if err := s.DB.Where("user_id = ? AND platform = ?", userID, req.Platform).First(&existingAccount).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Account already connected for this platform"})
		return
	}

	// Parse token expiration if provided
	var tokenExpiresAt *time.Time
	if req.TokenExpiresAt != "" {
		if expTime, err := time.Parse(time.RFC3339, req.TokenExpiresAt); err == nil {
			tokenExpiresAt = &expTime
		}
	}

	// Encrypt access token
	encryptedToken, err := s.encryptToken(req.AccessToken)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to encrypt access token"})
		return
	}

	// TODO: Validate the access token with the respective platform API
	// This would involve making API calls to verify the token is valid
	// and has the necessary permissions for monitoring

	// Create social media account
	account := models.SocialMediaAccount{
		UserID:               userID,
		Platform:             req.Platform,
		PlatformUserID:       req.PlatformUserID,
		AccessTokenEncrypted: &encryptedToken,
		TokenExpiresAt:       tokenExpiresAt,
		MonitoringEnabled:    req.MonitoringEnabled,
	}

	if req.PlatformUsername != "" {
		account.PlatformUsername = &req.PlatformUsername
	}

	if err := s.DB.Create(&account).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect social media account"})
		return
	}

	// Remove sensitive data from response
	account.AccessTokenEncrypted = nil

	c.JSON(http.StatusCreated, gin.H{
		"message": "Social media account connected successfully",
		"account": account,
	})
}

// GetConnectedAccounts returns user's connected social media accounts
func (s *SocialController) GetConnectedAccounts(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	var accounts []models.SocialMediaAccount
	if err := s.DB.Select("id, user_id, platform, platform_user_id, platform_username, token_expires_at, monitoring_enabled, last_sync_at, created_at, updated_at").
		Where("user_id = ?", userID).Find(&accounts).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch connected accounts"})
		return
	}

	c.JSON(http.StatusOK, accounts)
}

// UpdateAccountSettings updates social media account settings
func (s *SocialController) UpdateAccountSettings(c *gin.Context) {
	accountIDStr := c.Param("accountId")
	accountID, err := uuid.Parse(accountIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid account ID"})
		return
	}

	type UpdateAccountRequest struct {
		MonitoringEnabled *bool   `json:"monitoringEnabled"`
		PlatformUsername  *string `json:"platformUsername"`
	}

	var req UpdateAccountRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Get user ID from JWT token and verify ownership
	userIDStr := c.Param("userId") // Temporary: get from URL param
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Find account and verify ownership
	var account models.SocialMediaAccount
	if err := s.DB.Where("id = ? AND user_id = ?", accountID, userID).First(&account).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Social media account not found"})
		return
	}

	// Update fields if provided
	if req.MonitoringEnabled != nil {
		account.MonitoringEnabled = *req.MonitoringEnabled
	}

	if req.PlatformUsername != nil {
		account.PlatformUsername = req.PlatformUsername
	}

	if err := s.DB.Save(&account).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update account settings"})
		return
	}

	// Remove sensitive data from response
	account.AccessTokenEncrypted = nil

	c.JSON(http.StatusOK, gin.H{
		"message": "Account settings updated successfully",
		"account": account,
	})
}

// DisconnectAccount disconnects a social media account
func (s *SocialController) DisconnectAccount(c *gin.Context) {
	accountIDStr := c.Param("accountId")
	accountID, err := uuid.Parse(accountIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid account ID"})
		return
	}

	// TODO: Get user ID from JWT token and verify ownership
	userIDStr := c.Param("userId") // Temporary: get from URL param
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Find account and verify ownership
	var account models.SocialMediaAccount
	if err := s.DB.Where("id = ? AND user_id = ?", accountID, userID).First(&account).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Social media account not found"})
		return
	}

	// TODO: Revoke access token with the platform API if needed
	// This would involve making API calls to properly disconnect

	// Delete account and associated monitored posts
	if err := s.DB.Delete(&account).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to disconnect account"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Social media account disconnected successfully"})
}

// GetMonitoredPosts returns monitored posts for a social media account
func (s *SocialController) GetMonitoredPosts(c *gin.Context) {
	accountIDStr := c.Param("accountId")
	accountID, err := uuid.Parse(accountIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid account ID"})
		return
	}

	// TODO: Verify user owns this account

	// Pagination parameters
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset := (page - 1) * limit

	// Filter parameters
	sentimentProcessed := c.Query("sentimentProcessed") // true, false, or empty for all
	startDate := c.Query("startDate")                   // ISO 8601 format
	endDate := c.Query("endDate")                       // ISO 8601 format

	query := s.DB.Where("social_account_id = ?", accountID)

	// Apply filters
	if sentimentProcessed != "" {
		if processed, err := strconv.ParseBool(sentimentProcessed); err == nil {
			query = query.Where("sentiment_processed = ?", processed)
		}
	}

	if startDate != "" {
		if start, err := time.Parse(time.RFC3339, startDate); err == nil {
			query = query.Where("post_timestamp >= ?", start)
		}
	}

	if endDate != "" {
		if end, err := time.Parse(time.RFC3339, endDate); err == nil {
			query = query.Where("post_timestamp <= ?", end)
		}
	}

	var posts []models.SocialMediaPostMonitored
	if err := query.Order("post_timestamp DESC").Limit(limit).Offset(offset).Find(&posts).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch monitored posts"})
		return
	}

	// Get total count for pagination
	var totalCount int64
	countQuery := s.DB.Model(&models.SocialMediaPostMonitored{}).Where("social_account_id = ?", accountID)
	if sentimentProcessed != "" {
		if processed, err := strconv.ParseBool(sentimentProcessed); err == nil {
			countQuery = countQuery.Where("sentiment_processed = ?", processed)
		}
	}
	if startDate != "" {
		if start, err := time.Parse(time.RFC3339, startDate); err == nil {
			countQuery = countQuery.Where("post_timestamp >= ?", start)
		}
	}
	if endDate != "" {
		if end, err := time.Parse(time.RFC3339, endDate); err == nil {
			countQuery = countQuery.Where("post_timestamp <= ?", end)
		}
	}
	countQuery.Count(&totalCount)

	c.JSON(http.StatusOK, gin.H{
		"posts": posts,
		"pagination": gin.H{
			"page":       page,
			"limit":      limit,
			"totalCount": totalCount,
			"totalPages": (totalCount + int64(limit) - 1) / int64(limit),
		},
	})
}

// SyncAccount manually triggers synchronization for a social media account
func (s *SocialController) SyncAccount(c *gin.Context) {
	accountIDStr := c.Param("accountId")
	accountID, err := uuid.Parse(accountIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid account ID"})
		return
	}

	// TODO: Get user ID from JWT token and verify ownership
	userIDStr := c.Param("userId") // Temporary: get from URL param
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Find account and verify ownership
	var account models.SocialMediaAccount
	if err := s.DB.Where("id = ? AND user_id = ? AND monitoring_enabled = ?", accountID, userID, true).First(&account).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Social media account not found or monitoring disabled"})
		return
	}

	// Check if token is still valid
	if account.TokenExpiresAt != nil && account.TokenExpiresAt.Before(time.Now()) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Access token has expired. Please reconnect the account"})
		return
	}

	// Trigger async synchronization
	go s.syncAccountPosts(accountID)

	// Update last sync time
	now := time.Now()
	account.LastSyncAt = &now
	s.DB.Save(&account)

	c.JSON(http.StatusOK, gin.H{
		"message":    "Account synchronization started",
		"lastSyncAt": now,
	})
}

// syncAccountPosts performs the actual synchronization of posts
func (s *SocialController) syncAccountPosts(accountID uuid.UUID) {
	var account models.SocialMediaAccount
	if err := s.DB.First(&account, accountID).Error; err != nil {
		return
	}

	// TODO: Decrypt access token
	// accessToken, err := s.decryptToken(*account.AccessTokenEncrypted)
	// if err != nil {
	//     return
	// }

	// TODO: Implement platform-specific API calls to fetch posts
	// This would involve:
	// 1. Making API calls to the respective platform (Instagram, Twitter, etc.)
	// 2. Fetching recent posts from the user's account
	// 3. Storing new posts in the database
	// 4. Triggering sentiment analysis for new posts

	// Example placeholder implementation:
	switch account.Platform {
	case "instagram":
		// s.syncInstagramPosts(account, accessToken)
	case "twitter":
		// s.syncTwitterPosts(account, accessToken)
	case "facebook":
		// s.syncFacebookPosts(account, accessToken)
	case "tiktok":
		// s.syncTikTokPosts(account, accessToken)
	}
}

// GetSocialMediaInsights returns insights from social media monitoring
func (s *SocialController) GetSocialMediaInsights(c *gin.Context) {
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

	// Get social media accounts for this user
	var accounts []models.SocialMediaAccount
	if err := s.DB.Where("user_id = ? AND monitoring_enabled = ?", userID, true).Find(&accounts).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch social media accounts"})
		return
	}

	if len(accounts) == 0 {
		c.JSON(http.StatusOK, gin.H{
			"message": "No social media accounts with monitoring enabled",
			"insights": gin.H{
				"totalPosts":     0,
				"platformCounts": map[string]int{},
				"timelineData":   []interface{}{},
				"summary":        gin.H{},
			},
		})
		return
	}

	// Extract account IDs
	accountIDs := make([]uuid.UUID, len(accounts))
	for i, account := range accounts {
		accountIDs[i] = account.ID
	}

	// Get post counts by platform
	type PlatformCount struct {
		Platform string `json:"platform"`
		Count    int64  `json:"count"`
	}

	var platformCounts []PlatformCount
	query := `
		SELECT sma.platform, COUNT(smpm.id) as count
		FROM social_media_accounts sma
		LEFT JOIN social_media_posts_monitored smpm ON sma.id = smpm.social_account_id
		WHERE sma.user_id = ? AND sma.monitoring_enabled = true
		AND (smpm.post_timestamp IS NULL OR smpm.post_timestamp >= ?)
		GROUP BY sma.platform
		ORDER BY sma.platform
	`

	if err := s.DB.Raw(query, userID, startDate).Scan(&platformCounts).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch platform counts"})
		return
	}

	// Get timeline data (posts per day)
	type TimelineData struct {
		Date  string `json:"date"`
		Count int64  `json:"count"`
	}

	var timelineData []TimelineData
	timelineQuery := `
		SELECT DATE(smpm.post_timestamp) as date, COUNT(*) as count
		FROM social_media_posts_monitored smpm
		JOIN social_media_accounts sma ON smpm.social_account_id = sma.id
		WHERE sma.user_id = ? AND smpm.post_timestamp >= ?
		GROUP BY DATE(smpm.post_timestamp)
		ORDER BY date DESC
	`

	if err := s.DB.Raw(timelineQuery, userID, startDate).Scan(&timelineData).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch timeline data"})
		return
	}

	// Calculate totals
	var totalPosts int64
	for _, count := range platformCounts {
		totalPosts += count.Count
	}

	// TODO: Add sentiment analysis insights
	// This would analyze the sentiment of monitored posts and provide insights
	// about emotional patterns, trending topics, etc.

	c.JSON(http.StatusOK, gin.H{
		"insights": gin.H{
			"totalPosts":     totalPosts,
			"platformCounts": platformCounts,
			"timelineData":   timelineData,
			"dateRange": gin.H{
				"startDate": startDate,
				"endDate":   time.Now(),
				"days":      days,
			},
			"summary": gin.H{
				"connectedAccounts": len(accounts),
				"monitoringActive":  true,
				"averagePostsPerDay": func() float64 {
					if len(timelineData) > 0 {
						return float64(totalPosts) / float64(len(timelineData))
					}
					return 0
				}(),
			},
		},
	})
}

// Webhook endpoint for receiving social media platform notifications
func (s *SocialController) HandleWebhook(c *gin.Context) {
	platform := c.Param("platform")

	// TODO: Implement platform-specific webhook handling
	// This would involve:
	// 1. Verifying the webhook signature
	// 2. Parsing the platform-specific payload
	// 3. Processing new posts or events
	// 4. Triggering sentiment analysis if needed

	switch platform {
	case "instagram":
		// s.handleInstagramWebhook(c)
	case "twitter":
		// s.handleTwitterWebhook(c)
	case "facebook":
		// s.handleFacebookWebhook(c)
	case "tiktok":
		// s.handleTikTokWebhook(c)
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "Unsupported platform"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Webhook processed successfully"})
}

// Helper functions

// encryptToken encrypts an access token for secure storage
func (s *SocialController) encryptToken(token string) (string, error) {
	// TODO: Use a proper encryption key from environment variables
	key := []byte("your-32-byte-encryption-key-here") // Replace with actual key

	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	nonce := make([]byte, gcm.NonceSize())
	if _, err = io.ReadFull(rand.Reader, nonce); err != nil {
		return "", err
	}

	ciphertext := gcm.Seal(nonce, nonce, []byte(token), nil)
	return base64.URLEncoding.EncodeToString(ciphertext), nil
}

// decryptToken decrypts an access token
func (s *SocialController) decryptToken(encryptedToken string) (string, error) {
	// TODO: Use a proper encryption key from environment variables
	key := []byte("your-32-byte-encryption-key-here") // Replace with actual key

	data, err := base64.URLEncoding.DecodeString(encryptedToken)
	if err != nil {
		return "", err
	}

	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	nonceSize := gcm.NonceSize()
	if len(data) < nonceSize {
		return "", err
	}

	nonce, ciphertext := data[:nonceSize], data[nonceSize:]
	plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return "", err
	}

	return string(plaintext), nil
}
