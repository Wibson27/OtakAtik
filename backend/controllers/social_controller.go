package controllers

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"

	"backend/config"
	"backend/middleware"
	"backend/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SocialController struct {
	DB  *gorm.DB
	Cfg *config.Config
}

func NewSocialController(db *gorm.DB, cfg *config.Config) *SocialController {
	return &SocialController{DB: db, Cfg: cfg}
}

// --- DTOs and Request Structs ---

type SocialAccountResponse struct {
	ID                uuid.UUID  `json:"id"`
	Platform          string     `json:"platform"`
	PlatformUsername  *string    `json:"platform_username,omitempty"`
	MonitoringEnabled bool       `json:"monitoring_enabled"`
	LastSyncAt        *time.Time `json:"last_sync_at,omitempty"`
	CreatedAt         time.Time  `json:"created_at"`
}

type MonitoredPostResponse struct {
	ID                 uuid.UUID `json:"id"`
	PlatformPostID     string    `json:"platform_post_id"`
	PostType           *string   `json:"post_type,omitempty"`
	PostTimestamp      time.Time `json:"post_timestamp"`
	SentimentProcessed bool      `json:"sentiment_processed"`
}

type ConnectAccountRequest struct {
	Platform    string `json:"platform" binding:"required,oneof=instagram twitter facebook tiktok"`
	AccessToken string `json:"access_token" binding:"required"`
}

type UpdateAccountSettingsRequest struct {
	MonitoringEnabled *bool `json:"monitoring_enabled" binding:"required"`
}


// --- Controller Handlers ---

// ConnectAccount securely connects a new social media account.
func (s *SocialController) ConnectAccount(c *gin.Context) {
	var req ConnectAccountRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data", "code": "validation_failed"})
		return
	}

	authedUser, _ := middleware.GetFullUserFromContext(c)

	// TODO: Implement a real OAuth2 flow. This would involve exchanging the access token
	// for user details from the platform API to get the real PlatformUserID and PlatformUsername.
	platformUserID := fmt.Sprintf("placeholder_%s_%s", req.Platform, authedUser.ID.String())
	platformUsername := fmt.Sprintf("%s_user", req.Platform)

	var existingAccount models.SocialMediaAccount
	if s.DB.Where("user_id = ? AND platform = ?", authedUser.ID, req.Platform).First(&existingAccount).Error == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "This social media platform is already connected", "code": "platform_conflict"})
		return
	}

	encryptedToken, err := s.encryptToken(req.AccessToken)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to secure account token", "code": "encryption_error"})
		return
	}

	account := models.SocialMediaAccount{
		UserID:               authedUser.ID,
		Platform:             req.Platform,
		PlatformUserID:       platformUserID,
		PlatformUsername:     &platformUsername,
		AccessTokenEncrypted: &encryptedToken,
		MonitoringEnabled:    true, // Default to enabled
	}

	if err := s.DB.Create(&account).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect social media account", "code": "db_error"})
		return
	}

	c.JSON(http.StatusCreated, SocialAccountResponse{
		ID: account.ID, Platform: account.Platform, PlatformUsername: account.PlatformUsername,
		MonitoringEnabled: account.MonitoringEnabled, CreatedAt: account.CreatedAt,
	})
}

// GetConnectedAccounts retrieves all social media accounts for the user.
func (s *SocialController) GetConnectedAccounts(c *gin.Context) {
	authedUser, _ := middleware.GetFullUserFromContext(c)

	var accounts []models.SocialMediaAccount
	s.DB.Where("user_id = ?", authedUser.ID).Find(&accounts)

	response := make([]SocialAccountResponse, len(accounts))
	for i, acc := range accounts {
		response[i] = SocialAccountResponse{
			ID: acc.ID, Platform: acc.Platform, PlatformUsername: acc.PlatformUsername,
			MonitoringEnabled: acc.MonitoringEnabled, LastSyncAt: acc.LastSyncAt, CreatedAt: acc.CreatedAt,
		}
	}
	c.JSON(http.StatusOK, response)
}

// UpdateAccountSettings updates the monitoring status for a social account.
func (s *SocialController) UpdateAccountSettings(c *gin.Context) {
	accountID, _ := uuid.Parse(c.Param("accountId"))
	authedUser, _ := middleware.GetFullUserFromContext(c)

	var req UpdateAccountSettingsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request, 'monitoring_enabled' field is required", "code": "validation_failed"})
		return
	}

	var account models.SocialMediaAccount
	if err := s.DB.Where("id = ? AND user_id = ?", accountID, authedUser.ID).First(&account).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Social media account not found", "code": "not_found"})
		return
	}

	account.MonitoringEnabled = *req.MonitoringEnabled
	if err := s.DB.Save(&account).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update account settings", "code": "db_error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Account settings updated successfully"})
}

// DisconnectAccount removes a social media connection.
func (s *SocialController) DisconnectAccount(c *gin.Context) {
	accountID, _ := uuid.Parse(c.Param("accountId"))
	authedUser, _ := middleware.GetFullUserFromContext(c)

	result := s.DB.Where("id = ? AND user_id = ?", accountID, authedUser.ID).Delete(&models.SocialMediaAccount{})
	if result.Error != nil || result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Account not found or could not be deleted", "code": "not_found_or_failed"})
		return
	}

	c.Status(http.StatusNoContent)
}

// GetMonitoredPosts retrieves monitored posts for a specific account.
func (s *SocialController) GetMonitoredPosts(c *gin.Context) {
	accountID, _ := uuid.Parse(c.Param("accountId"))
	authedUser, _ := middleware.GetFullUserFromContext(c)

	// Verify ownership: check if the social account belongs to the authenticated user.
	var account models.SocialMediaAccount
	if err := s.DB.Where("id = ? AND user_id = ?", accountID, authedUser.ID).First(&account).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access to this social account is denied", "code": "forbidden"})
		return
	}

	var posts []models.SocialMediaPostMonitored
	s.DB.Where("social_account_id = ?", accountID).Order("post_timestamp DESC").Find(&posts)

	var response []MonitoredPostResponse
	for _, p := range posts {
		response = append(response, MonitoredPostResponse{
			ID: p.ID, PlatformPostID: p.PlatformPostID, PostType: p.PostType,
			PostTimestamp: p.PostTimestamp, SentimentProcessed: p.SentimentProcessed,
		})
	}
	c.JSON(http.StatusOK, response)
}

// SyncAccount manually triggers post synchronization for an account.
func (s *SocialController) SyncAccount(c *gin.Context) {
	accountID, _ := uuid.Parse(c.Param("accountId"))
	authedUser, _ := middleware.GetFullUserFromContext(c)

	var account models.SocialMediaAccount
	if err := s.DB.Where("id = ? AND user_id = ? AND monitoring_enabled = ?", accountID, authedUser.ID, true).First(&account).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": "Account not found or monitoring is disabled", "code": "forbidden_or_not_found"})
		return
	}

	go s.syncAccountPosts(account)

	s.DB.Model(&account).Update("last_sync_at", time.Now())

	c.JSON(http.StatusAccepted, gin.H{"message": "Account synchronization has been started."})
}

// GetSocialMediaInsights returns aggregated insights from all connected accounts.
func (s *SocialController) GetSocialMediaInsights(c *gin.Context) {
	authedUser, _ := middleware.GetFullUserFromContext(c)

	type PlatformCount struct {
		Platform string `json:"platform"`
		Count    int64  `json:"count"`
	}

	var platformCounts []PlatformCount
	s.DB.Model(&models.SocialMediaAccount{}).
		Select("social_media_accounts.platform, COUNT(social_media_posts_monitored.id) as count").
		Joins("LEFT JOIN social_media_posts_monitored ON social_media_posts_monitored.social_account_id = social_media_accounts.id").
		Where("social_media_accounts.user_id = ?", authedUser.ID).
		Group("social_media_accounts.platform").
		Scan(&platformCounts)

	// ... (Sisa logika dari kode Anda untuk timeline data dan summary, yang sudah baik)

	c.JSON(http.StatusOK, gin.H{
		"insights": gin.H{
			"platform_counts": platformCounts,
			// ... data lain
		},
	})
}

// HandleWebhook processes incoming webhooks from social media platforms.
func (s *SocialController) HandleWebhook(c *gin.Context) {
	platform := c.Param("platform")

	// TODO: Implement platform-specific signature verification using webhook secrets from .env
	// e.g., verifyFacebookSignature(c.Request, s.Cfg.Webhook.FacebookSecret)

	log.Printf("Received webhook from platform: %s", platform)
	c.JSON(http.StatusOK, gin.H{"status": "received"})
}


// --- Helper and Background Functions ---

func (s *SocialController) syncAccountPosts(account models.SocialMediaAccount) {
	log.Printf("Syncing posts for account %s on platform %s", account.ID, account.Platform)
	// Placeholder for background job
}

// encryptToken securely encrypts a token using AES-GCM and the key from config.
func (s *SocialController) encryptToken(token string) (string, error) {
	key, err := base64.StdEncoding.DecodeString(s.Cfg.Security.EncryptionKey)
	if err != nil || len(key) != 32 {
		return "", errors.New("invalid encryption key: must be a 32-byte base64 encoded string")
	}

	block, err := aes.NewCipher(key)
	if err != nil { return "", err }

	gcm, err := cipher.NewGCM(block)
	if err != nil { return "", err }

	nonce := make([]byte, gcm.NonceSize())
	if _, err = io.ReadFull(rand.Reader, nonce); err != nil { return "", err }

	ciphertext := gcm.Seal(nonce, nonce, []byte(token), nil)
	return base64.URLEncoding.EncodeToString(ciphertext), nil
}

// decryptToken securely decrypts a token using the key from config.
func (s *SocialController) decryptToken(encryptedToken string) (string, error) {
	key, err := base64.StdEncoding.DecodeString(s.Cfg.Security.EncryptionKey)
	if err != nil || len(key) != 32 {
		return "", errors.New("invalid encryption key: must be a 32-byte base64 encoded string")
	}

	data, err := base64.URLEncoding.DecodeString(encryptedToken)
	if err != nil { return "", err }

	block, err := aes.NewCipher(key)
	if err != nil { return "", err }

	gcm, err := cipher.NewGCM(block)
	if err != nil { return "", err }

	nonceSize := gcm.NonceSize()
	if len(data) < nonceSize { return "", errors.New("ciphertext too short") }

	nonce, ciphertext := data[:nonceSize], data[nonceSize:]
	plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
	if err != nil { return "", err }

	return string(plaintext), nil
}