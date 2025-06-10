package controllers

import (
	"math"
	"net/http"
	"strconv"
	"time"

	"backend/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// UserController handles all user-centric API requests
type UserController struct {
	DB *gorm.DB
}

// NewUserController creates a new instance of UserController with DB dependency
func NewUserController(db *gorm.DB) *UserController {
	return &UserController{DB: db}
}


// --- DTOs (Data Transfer Objects) ---

type UserProfileResponse struct {
	ID           uuid.UUID  `json:"id"`
	Email        string     `json:"email"`
	Username     *string    `json:"username"`
	FullName     *string    `json:"full_name"`
	DateOfBirth  *time.Time `json:"date_of_birth,omitempty"`
	Timezone     string     `json:"timezone"`
	PrivacyLevel string     `json:"privacy_level"`
	CreatedAt    time.Time  `json:"created_at"`
	LastActiveAt *time.Time `json:"last_active_at,omitempty"`
}

type UserUpdateRequest struct {
	Username     *string `json:"username" binding:"omitempty,min=3,max=50"`
	FullName     *string `json:"full_name" binding:"omitempty,min=2,max=100"`
	DateOfBirth  *string `json:"date_of_birth" binding:"omitempty,datetime=2006-01-02"` // Terima sebagai string untuk validasi
	Timezone     *string `json:"timezone" binding:"omitempty,min=2,max=50"`
	PrivacyLevel *string `json:"privacy_level" binding:"omitempty,oneof=minimal standard full"`
}

// AdminUserView DTO
type AdminUserView struct {
	UserProfileResponse
	IsActive        bool       `json:"is_active"`
	EmailVerifiedAt *time.Time `json:"email_verified_at,omitempty"`
	// Tipe data disesuaikan dengan model `models.User`
	DeletedAt       *time.Time `json:"deleted_at,omitempty"`
}

type UserStatusUpdateRequest struct {
	IsActive bool `json:"is_active"`
}

type UserPreferencesResponse struct {
	UserID                      uuid.UUID `json:"user_id"`
	NotificationChat            bool      `json:"notification_chat"`
	NotificationCommunity       bool      `json:"notification_community"`
	NotificationSchedule        string    `json:"notification_schedule"`
	CommunityAnonymousDefault   bool      `json:"community_anonymous_default"`
	SocialMediaMonitoring       bool      `json:"social_media_monitoring"`
	UpdatedAt                   time.Time `json:"updated_at"`
}

type UserPreferencesUpdateRequest struct {
	NotificationChat          *bool  `json:"notification_chat"`
	NotificationCommunity     *bool  `json:"notification_community"`
	NotificationSchedule      *string `json:"notification_schedule"`
	CommunityAnonymousDefault *bool  `json:"community_anonymous_default"`
	SocialMediaMonitoring     *bool  `json:"social_media_monitoring"`
}

type DashboardStatsResponse struct {
	ChatSessionsCount   int64   `json:"chat_sessions_count"`
	VocalEntriesCount   int64   `json:"vocal_entries_count"`
	CommunityPostsCount int64   `json:"community_posts_count"`
	AvgWellbeingScore   float64 `json:"avg_wellbeing_score"`
}


// --- Controller Handlers ---

// GetProfile retrieves a single user's profile.
// ROUTE: GET /api/v1/users/:userId/profile
func (uc *UserController) GetProfile(c *gin.Context) {
	userID, err := uuid.Parse(c.Param("userId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID format", "code": "invalid_user_id"})
		return
	}

	var user models.User
	if err := uc.DB.Where("id = ?", userID).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found", "code": "user_not_found"})
		return
	}

	c.JSON(http.StatusOK, UserProfileResponse{
		ID: user.ID, Email: user.Email, Username: user.Username, FullName: user.FullName,
		DateOfBirth: user.DateOfBirth, Timezone: user.Timezone, PrivacyLevel: user.PrivacyLevel,
		CreatedAt: user.CreatedAt, LastActiveAt: user.LastActiveAt,
	})
}

// UpdateProfile allows a user to update their own profile information.
// ROUTE: PUT /api/v1/users/:userId/profile
func (uc *UserController) UpdateProfile(c *gin.Context) {
	userID, _ := uuid.Parse(c.Param("userId"))

	var req UserUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data", "details": err.Error(), "code": "validation_failed"})
		return
	}

	var user models.User
	if err := uc.DB.Where("id = ?", userID).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found", "code": "user_not_found"})
		return
	}

	if req.Username != nil {
		var existingUser models.User
		if err := uc.DB.Where("username = ? AND id != ?", *req.Username, userID).First(&existingUser).Error; err == nil {
			c.JSON(http.StatusConflict, gin.H{"error": "Username is already taken", "code": "username_conflict"})
			return
		}
		user.Username = req.Username
	}

	if req.FullName != nil { user.FullName = req.FullName }
	if req.Timezone != nil { user.Timezone = *req.Timezone }
	if req.PrivacyLevel != nil { user.PrivacyLevel = *req.PrivacyLevel }

	if req.DateOfBirth != nil {
		dob, err := time.Parse("2006-01-02", *req.DateOfBirth)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid date format, use YYYY-MM-DD", "code": "invalid_date_format"})
			return
		}
		user.DateOfBirth = &dob
	}

	if err := uc.DB.Save(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update profile", "code": "db_update_failed"})
		return
	}
	uc.GetProfile(c)
}

// GetPreferences retrieves user-specific application preferences.
// ROUTE: GET /api/v1/users/:userId/preferences
func (uc *UserController) GetPreferences(c *gin.Context) {
	userID, _ := uuid.Parse(c.Param("userId"))
	var prefs models.UserPreferences

	if err := uc.DB.Where(models.UserPreferences{UserID: userID}).FirstOrCreate(&prefs).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not retrieve preferences", "code": "db_query_failed"})
		return
	}

	c.JSON(http.StatusOK, UserPreferencesResponse{
		UserID: prefs.UserID, NotificationChat: prefs.NotificationChat, NotificationCommunity: prefs.NotificationCommunity,
		NotificationSchedule: prefs.NotificationSchedule, CommunityAnonymousDefault: prefs.CommunityAnonymousDefault,
		SocialMediaMonitoring: prefs.SocialMediaMonitoring, UpdatedAt: prefs.UpdatedAt,
	})
}

// UpdatePreferences allows a user to update their own preferences.
// ROUTE: PUT /api/v1/users/:userId/preferences
func (uc *UserController) UpdatePreferences(c *gin.Context) {
	userID, _ := uuid.Parse(c.Param("userId"))

	var req UserPreferencesUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data", "code": "validation_failed"})
		return
	}

	var prefs models.UserPreferences
	uc.DB.Where(models.UserPreferences{UserID: userID}).FirstOrCreate(&prefs)

	if req.NotificationChat != nil { prefs.NotificationChat = *req.NotificationChat }
	if req.NotificationCommunity != nil { prefs.NotificationCommunity = *req.NotificationCommunity }
	if req.CommunityAnonymousDefault != nil { prefs.CommunityAnonymousDefault = *req.CommunityAnonymousDefault }
	if req.SocialMediaMonitoring != nil { prefs.SocialMediaMonitoring = *req.SocialMediaMonitoring }
	if req.NotificationSchedule != nil { prefs.NotificationSchedule = *req.NotificationSchedule }

	if err := uc.DB.Save(&prefs).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update preferences", "code": "db_update_failed"})
		return
	}
	uc.GetPreferences(c)
}

// GetDashboardStats calculates and retrieves key engagement stats for a user's dashboard.
// ROUTE: GET /api/v1/users/:userId/dashboard
func (uc *UserController) GetDashboardStats(c *gin.Context) {
	userID, _ := uuid.Parse(c.Param("userId"))

	var stats DashboardStatsResponse
	var avgScore struct { Avg float64 }

	uc.DB.Model(&models.ChatSession{}).Where("user_id = ?", userID).Count(&stats.ChatSessionsCount)
	uc.DB.Model(&models.VocalJournalEntry{}).Where("user_id = ?", userID).Count(&stats.VocalEntriesCount)
	uc.DB.Model(&models.CommunityPost{}).Where("user_id = ?", userID).Count(&stats.CommunityPostsCount)

	subQuery := uc.DB.Table("vocal_journal_entries").Select("id").Where("user_id = ?", userID)
	uc.DB.Model(&models.VocalSentimentAnalysis{}).Where("vocal_entry_id IN (?)", subQuery).Select("COALESCE(AVG(overall_wellbeing_score), 0)").Scan(&avgScore)

	stats.AvgWellbeingScore = avgScore.Avg
	c.JSON(http.StatusOK, stats)
}

// GetProgressMetrics retrieves time-series data for user progress visualization.
// ROUTE: GET /api/v1/users/:userId/progress
func (uc *UserController) GetProgressMetrics(c *gin.Context) {
	userID, _ := uuid.Parse(c.Param("userId"))

	var metrics []models.UserProgressMetric
	if err := uc.DB.Where("user_id = ?", userID).Order("metric_date DESC").Find(&metrics).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not retrieve progress metrics", "code": "db_query_failed"})
		return
	}
	c.JSON(http.StatusOK, metrics)
}

// DeactivateAccount performs a soft delete on a user account.
// ROUTE: DELETE /api/v1/users/:userId/deactivate
func (uc *UserController) DeactivateAccount(c *gin.Context) {
	userID, _ := uuid.Parse(c.Param("userId"))

	var user models.User
	if tx := uc.DB.Where("id = ?", userID).First(&user); tx.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found", "code": "user_not_found"})
		return
	}

	err := uc.DB.Transaction(func(tx *gorm.DB) error {
		user.IsActive = false
		if err := tx.Save(&user).Error; err != nil {
			return err
		}
		if err := tx.Delete(&user).Error; err != nil {
			return err
		}
		return nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to deactivate account", "code": "db_transaction_failed"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "User account deactivated successfully", "code": "user_deactivated"})
}


// --- Admin-Only Handlers ---

// GetAllUsers retrieves a paginated list of all users.
// ROUTE: GET /api/v1/admin/users
func (uc *UserController) GetAllUsers(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "10"))
	offset := (page - 1) * pageSize

	var users []models.User
	var totalRecords int64

	uc.DB.Model(&models.User{}).Unscoped().Count(&totalRecords)
	uc.DB.Model(&models.User{}).Unscoped().Offset(offset).Limit(pageSize).Order("created_at DESC").Find(&users)

	var response []AdminUserView
	for _, user := range users {
		response = append(response, AdminUserView{
			UserProfileResponse: UserProfileResponse{
				ID: user.ID, Email: user.Email, Username: user.Username, FullName: user.FullName,
				DateOfBirth: user.DateOfBirth, Timezone: user.Timezone, PrivacyLevel: user.PrivacyLevel,
				CreatedAt: user.CreatedAt, LastActiveAt: user.LastActiveAt,
			},
			IsActive:        user.IsActive,
			EmailVerifiedAt: user.EmailVerifiedAt,
			DeletedAt:       user.DeletedAt, // Ini sekarang valid karena tipe datanya sama (*time.Time)
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"data": response,
		"pagination": gin.H{
			"total_records": totalRecords, "current_page": page, "page_size": pageSize,
			"total_pages": int(math.Ceil(float64(totalRecords) / float64(pageSize))),
		},
	})
}

// UpdateUserStatus allows an admin to activate or deactivate a user account.
// ROUTE: PUT /api/v1/admin/users/:userId/status
func (uc *UserController) UpdateUserStatus(c *gin.Context) {
	userID, err := uuid.Parse(c.Param("userId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID format", "code": "invalid_user_id"})
		return
	}
	var req UserStatusUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data", "code": "validation_failed"})
		return
	}

	var user models.User
	if err := uc.DB.Unscoped().Where("id = ?", userID).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found", "code": "user_not_found"})
		return
	}

	user.IsActive = req.IsActive

	// Jika mengaktifkan kembali, hapus timestamp soft delete
	if user.IsActive {
		user.DeletedAt = nil // Cara yang benar untuk menghapus soft delete
	} else if user.DeletedAt == nil {
		// Jika menonaktifkan dan belum soft-deleted, tambahkan timestamp
		now := time.Now()
		user.DeletedAt = &now
	}

	if err := uc.DB.Save(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update user status", "code": "db_update_failed"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "User status updated successfully", "user_id": user.ID, "new_status": user.IsActive})
}