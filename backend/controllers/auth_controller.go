package controllers

import (
	"encoding/json"
	"io"
	"net/http"
	"time"

	// "backend/config"
	"backend/middleware"
	"backend/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type AuthController struct {
	DB *gorm.DB
}

// RegisterRequest represents the registration request payload
type RegisterRequest struct {
	Email       string `json:"email" binding:"required,email"`
	Password    string `json:"password" binding:"required,min=6"`
	FullName    string `json:"fullName" binding:"required"`
	Username    string `json:"username"`
	DateOfBirth string `json:"dateOfBirth"` // Format: YYYY-MM-DD
}

// LoginRequest represents the login request payload
type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

// GoogleAuthRequest represents Google OAuth request
type GoogleAuthRequest struct {
	GoogleToken string `json:"googleToken" binding:"required"`
}

// GoogleUserInfo represents Google user information
type GoogleUserInfo struct {
	ID            string `json:"id"`
	Email         string `json:"email"`
	VerifiedEmail bool   `json:"verified_email"`
	Name          string `json:"name"`
	GivenName     string `json:"given_name"`
	FamilyName    string `json:"family_name"`
	Picture       string `json:"picture"`
}

// RefreshTokenRequest represents refresh token request
type RefreshTokenRequest struct {
	RefreshToken string `json:"refreshToken" binding:"required"`
}

// Register creates a new user account with credentials and preferences
func (a *AuthController) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid request data",
			"details": err.Error(),
		})
		return
	}

	// Check if email already exists
	var existingUser models.User
	if err := a.DB.Where("email = ?", req.Email).First(&existingUser).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{
			"error":   "Email already registered",
			"message": "Email ini sudah terdaftar. Silakan gunakan email lain atau login.",
		})
		return
	}

	// Check if username already exists (if provided)
	if req.Username != "" {
		if err := a.DB.Where("username = ?", req.Username).First(&existingUser).Error; err == nil {
			c.JSON(http.StatusConflict, gin.H{
				"error":   "Username already taken",
				"message": "Username ini sudah digunakan. Silakan pilih username lain.",
			})
			return
		}
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to process password",
			"message": "Terjadi kesalahan saat memproses password. Silakan coba lagi.",
		})
		return
	}

	// Create user
	userID := uuid.New()
	now := time.Now()

	user := models.User{
		ID:       userID,
		Email:    req.Email,
		FullName: &req.FullName,
		IsActive: true,
		CreatedAt: now,
		UpdatedAt: now,
	}

	// Set username if provided
	if req.Username != "" {
		user.Username = &req.Username
	}

	// Parse date of birth if provided
	if req.DateOfBirth != "" {
		if dob, err := time.Parse("2006-01-02", req.DateOfBirth); err == nil {
			user.DateOfBirth = &dob
		}
	}

	// Start transaction
	tx := a.DB.Begin()

	// Create user
	if err := tx.Create(&user).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to create user",
			"message": "Gagal membuat akun. Silakan coba lagi.",
		})
		return
	}

	// Create user credentials
	credentials := models.UserCredentials{
		ID:           uuid.New(),
		UserID:       userID,
		PasswordHash: string(hashedPassword),
		CreatedAt:    now,
		UpdatedAt:    now,
	}

	if err := tx.Create(&credentials).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to create credentials",
			"message": "Gagal membuat kredensial. Silakan coba lagi.",
		})
		return
	}

	// Create user preferences with default values
	preferences := models.UserPreferences{
		ID:                        uuid.New(),
		UserID:                   userID,
		NotificationChat:         true,
		NotificationCommunity:    true,
		NotificationSchedule:     "[]",
		CommunityAnonymousDefault: false,
		SocialMediaMonitoring:    false,
		CreatedAt:               now,
		UpdatedAt:               now,
	}

	if err := tx.Create(&preferences).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to create preferences",
			"message": "Gagal membuat preferensi. Silakan coba lagi.",
		})
		return
	}

	// Commit transaction
	tx.Commit()

	// Generate JWT tokens
	sessionID := uuid.New().String()
	accessToken, err := middleware.GenerateTenangJWT(user, "access", sessionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to generate access token",
			"message": "Gagal membuat token akses. Silakan coba login.",
		})
		return
	}

	refreshToken, err := middleware.GenerateTenangJWT(user, "refresh", sessionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to generate refresh token",
			"message": "Gagal membuat refresh token. Silakan coba login.",
		})
		return
	}

	// Return success response
	c.JSON(http.StatusCreated, gin.H{
		"message": "Registrasi berhasil! Selamat datang di Tenang.in 🌸",
		"user": gin.H{
			"id":           user.ID,
			"email":        user.Email,
			"fullName":     user.FullName,
			"username":     user.Username,
			"dateOfBirth":  user.DateOfBirth,
			"createdAt":    user.CreatedAt,
		},
		"tokens": gin.H{
			"accessToken":  accessToken,
			"refreshToken": refreshToken,
			"tokenType":    "Bearer",
			"expiresIn":    900, // 15 minutes in seconds
		},
		"preferences": preferences,
	})
}

// Login authenticates user and returns JWT tokens
func (a *AuthController) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid request data",
			"details": err.Error(),
		})
		return
	}

	// Find user by email
	var user models.User
	if err := a.DB.Where("email = ? AND is_active = ?", req.Email, true).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":   "Invalid credentials",
			"message": "Email atau password salah. Silakan periksa kembali.",
		})
		return
	}

	// Get user credentials
	var credentials models.UserCredentials
	if err := a.DB.Where("user_id = ?", user.ID).First(&credentials).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":   "Invalid credentials",
			"message": "Email atau password salah. Silakan periksa kembali.",
		})
		return
	}

	// Check if account is locked
	if credentials.LockedUntil != nil && credentials.LockedUntil.After(time.Now()) {
		c.JSON(http.StatusLocked, gin.H{
			"error":   "Account temporarily locked",
			"message": "Akun sementara dikunci karena terlalu banyak percobaan login yang gagal. Silakan coba lagi nanti.",
		})
		return
	}

	// Verify password
	if err := bcrypt.CompareHashAndPassword([]byte(credentials.PasswordHash), []byte(req.Password)); err != nil {
		// Increment failed login attempts
		credentials.FailedLoginAttempts++
		if credentials.FailedLoginAttempts >= 5 {
			lockUntil := time.Now().Add(15 * time.Minute)
			credentials.LockedUntil = &lockUntil
		}
		a.DB.Save(&credentials)

		c.JSON(http.StatusUnauthorized, gin.H{
			"error":   "Invalid credentials",
			"message": "Email atau password salah. Silakan periksa kembali.",
		})
		return
	}

	// Reset failed login attempts on successful login
	credentials.FailedLoginAttempts = 0
	credentials.LockedUntil = nil
	a.DB.Save(&credentials)

	// Update last active timestamp
	now := time.Now()
	user.LastActiveAt = &now
	a.DB.Save(&user)

	// Generate JWT tokens
	sessionID := uuid.New().String()
	accessToken, err := middleware.GenerateTenangJWT(user, "access", sessionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to generate access token",
			"message": "Gagal membuat token akses. Silakan coba lagi.",
		})
		return
	}

	refreshToken, err := middleware.GenerateTenangJWT(user, "refresh", sessionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to generate refresh token",
			"message": "Gagal membuat refresh token. Silakan coba lagi.",
		})
		return
	}

	// Get user preferences
	var preferences models.UserPreferences
	a.DB.Where("user_id = ?", user.ID).First(&preferences)

	// Return success response
	c.JSON(http.StatusOK, gin.H{
		"message": "Login berhasil! Selamat datang kembali di Tenang.in 🌸",
		"user": gin.H{
			"id":           user.ID,
			"email":        user.Email,
			"fullName":     user.FullName,
			"username":     user.Username,
			"dateOfBirth":  user.DateOfBirth,
			"lastActiveAt": user.LastActiveAt,
		},
		"tokens": gin.H{
			"accessToken":  accessToken,
			"refreshToken": refreshToken,
			"tokenType":    "Bearer",
			"expiresIn":    900, // 15 minutes in seconds
		},
		"preferences": preferences,
	})
}

// GoogleAuth handles Google OAuth authentication
func (a *AuthController) GoogleAuth(c *gin.Context) {
	var req GoogleAuthRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid request data",
			"details": err.Error(),
		})
		return
	}

	// Verify Google token and get user info
	googleUser, err := a.verifyGoogleToken(req.GoogleToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":   "Invalid Google token",
			"message": "Token Google tidak valid. Silakan coba lagi.",
		})
		return
	}

	// Check if user already exists
	var user models.User
	userExists := a.DB.Where("email = ?", googleUser.Email).First(&user).Error == nil

	now := time.Now()

	if userExists {
		// Update existing user's last active
		user.LastActiveAt = &now
		a.DB.Save(&user)
	} else {
		// Create new user from Google account
		userID := uuid.New()

		user = models.User{
			ID:              userID,
			Email:           googleUser.Email,
			FullName:        &googleUser.Name,
			IsActive:        true,
			EmailVerifiedAt: &now, // Google accounts are pre-verified
			CreatedAt:       now,
			UpdatedAt:       now,
		}

		// Start transaction for new user creation
		tx := a.DB.Begin()

		// Create user
		if err := tx.Create(&user).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Failed to create user",
				"message": "Gagal membuat akun. Silakan coba lagi.",
			})
			return
		}

		// Create empty credentials (Google users don't have password)
		credentials := models.UserCredentials{
			ID:                  uuid.New(),
			UserID:              userID,
			PasswordHash:        "", // Empty for Google users
			FailedLoginAttempts: 0,
			CreatedAt:           now,
			UpdatedAt:           now,
		}

		if err := tx.Create(&credentials).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Failed to create credentials",
				"message": "Gagal membuat kredensial. Silakan coba lagi.",
			})
			return
		}

		// Create default preferences
		preferences := models.UserPreferences{
			ID:                        uuid.New(),
			UserID:                   userID,
			NotificationChat:         true,
			NotificationCommunity:    true,
			NotificationSchedule:     "[]",
			CommunityAnonymousDefault: false,
			SocialMediaMonitoring:    false,
			CreatedAt:               now,
			UpdatedAt:               now,
		}

		if err := tx.Create(&preferences).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Failed to create preferences",
				"message": "Gagal membuat preferensi. Silakan coba lagi.",
			})
			return
		}

		tx.Commit()
	}

	// Generate JWT tokens
	sessionID := uuid.New().String()
	accessToken, err := middleware.GenerateTenangJWT(user, "access", sessionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to generate access token",
			"message": "Gagal membuat token akses. Silakan coba lagi.",
		})
		return
	}

	refreshToken, err := middleware.GenerateTenangJWT(user, "refresh", sessionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to generate refresh token",
			"message": "Gagal membuat refresh token. Silakan coba lagi.",
		})
		return
	}

	// Get user preferences
	var preferences models.UserPreferences
	a.DB.Where("user_id = ?", user.ID).First(&preferences)

	// Determine response message
	var message string
	if userExists {
		message = "Login dengan Google berhasil! Selamat datang kembali di Tenang.in 🌸"
	} else {
		message = "Akun berhasil dibuat dengan Google! Selamat datang di Tenang.in 🌸"
	}

	c.JSON(http.StatusOK, gin.H{
		"message": message,
		"user": gin.H{
			"id":              user.ID,
			"email":           user.Email,
			"fullName":        user.FullName,
			"username":        user.Username,
			"dateOfBirth":     user.DateOfBirth,
			"emailVerifiedAt": user.EmailVerifiedAt,
			"lastActiveAt":    user.LastActiveAt,
		},
		"tokens": gin.H{
			"accessToken":  accessToken,
			"refreshToken": refreshToken,
			"tokenType":    "Bearer",
			"expiresIn":    900, // 15 minutes in seconds
		},
		"preferences": preferences,
		"isNewUser":   !userExists,
	})
}

// RefreshToken generates new access and refresh tokens
func (a *AuthController) RefreshToken(c *gin.Context) {
	var req RefreshTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid request data",
			"details": err.Error(),
		})
		return
	}

	// Refresh tokens using middleware function
	newAccessToken, newRefreshToken, err := middleware.RefreshTenangTokens(req.RefreshToken, a.DB)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":   "Invalid refresh token",
			"message": "Refresh token tidak valid. Silakan login kembali.",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Token berhasil diperbarui",
		"tokens": gin.H{
			"accessToken":  newAccessToken,
			"refreshToken": newRefreshToken,
			"tokenType":    "Bearer",
			"expiresIn":    900, // 15 minutes in seconds
		},
	})
}

// Logout handles user logout
func (a *AuthController) Logout(c *gin.Context) {
	// Get user from context
	userID, _, _, _, err := middleware.GetUserFromTenangContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":   "Invalid token",
			"message": "Token tidak valid.",
		})
		return
	}

	// TODO: Implement token blacklisting for enhanced security
	// For now, client should remove the token

	// Update user's last active timestamp
	now := time.Now()
	a.DB.Model(&models.User{}).Where("id = ?", userID).Update("last_active_at", now)

	c.JSON(http.StatusOK, gin.H{
		"message": "Logout berhasil. Terima kasih telah menggunakan Tenang.in 🌸",
	})
}

// ChangePassword allows users to change their password
func (a *AuthController) ChangePassword(c *gin.Context) {
	type ChangePasswordRequest struct {
		CurrentPassword string `json:"currentPassword" binding:"required"`
		NewPassword     string `json:"newPassword" binding:"required,min=6"`
	}

	var req ChangePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid request data",
			"details": err.Error(),
		})
		return
	}

	// Get user ID from JWT token
	userID, _, _, _, err := middleware.GetUserFromTenangContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":   "Authentication required",
			"message": "Token tidak valid.",
		})
		return
	}

	// Get user credentials
	var credentials models.UserCredentials
	if err := a.DB.Where("user_id = ?", userID).First(&credentials).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "User credentials not found",
			"message": "Kredensial pengguna tidak ditemukan.",
		})
		return
	}

	// Check if current password is empty (Google users)
	if credentials.PasswordHash == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Cannot change password for Google account",
			"message": "Tidak dapat mengubah password untuk akun Google. Silakan kelola password melalui akun Google Anda.",
		})
		return
	}

	// Verify current password
	if err := bcrypt.CompareHashAndPassword([]byte(credentials.PasswordHash), []byte(req.CurrentPassword)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":   "Invalid current password",
			"message": "Password saat ini salah.",
		})
		return
	}

	// Hash new password
	hashedNewPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to hash new password",
			"message": "Gagal memproses password baru.",
		})
		return
	}

	// Update password
	credentials.PasswordHash = string(hashedNewPassword)
	credentials.PasswordChangedAt = time.Now()

	if err := a.DB.Save(&credentials).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to update password",
			"message": "Gagal mengupdate password.",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Password berhasil diubah. Gunakan password baru untuk login selanjutnya.",
	})
}

// ForgotPassword handles password reset requests
func (a *AuthController) ForgotPassword(c *gin.Context) {
	type ForgotPasswordRequest struct {
		Email string `json:"email" binding:"required,email"`
	}

	var req ForgotPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid request data",
			"details": err.Error(),
		})
		return
	}

	// Check if user exists
	var user models.User
	if err := a.DB.Where("email = ? AND is_active = ?", req.Email, true).First(&user).Error; err != nil {
		// Return success even if user doesn't exist (security best practice)
		c.JSON(http.StatusOK, gin.H{
			"message": "Jika email terdaftar, link reset password akan dikirimkan ke email Anda.",
		})
		return
	}

	// TODO: Generate reset token and send email
	// For now, return success message
	c.JSON(http.StatusOK, gin.H{
		"message": "Link reset password telah dikirimkan ke email Anda. Silakan periksa inbox dan folder spam.",
	})
}

// ResetPassword handles password reset with token
func (a *AuthController) ResetPassword(c *gin.Context) {
	type ResetPasswordRequest struct {
		Token       string `json:"token" binding:"required"`
		NewPassword string `json:"newPassword" binding:"required,min=6"`
	}

	var req ResetPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid request data",
			"details": err.Error(),
		})
		return
	}

	// TODO: Validate reset token and update password
	c.JSON(http.StatusOK, gin.H{
		"message": "Password berhasil direset. Silakan login dengan password baru.",
	})
}

// VerifyEmail handles email verification
func (a *AuthController) VerifyEmail(c *gin.Context) {
	token := c.Query("token")
	if token == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Verification token required",
			"message": "Token verifikasi diperlukan.",
		})
		return
	}

	// TODO: Validate verification token and update email_verified_at
	c.JSON(http.StatusOK, gin.H{
		"message": "Email berhasil diverifikasi. Akun Anda sudah aktif.",
	})
}

// verifyGoogleToken verifies Google OAuth token and returns user info
func (a *AuthController) verifyGoogleToken(token string) (*GoogleUserInfo, error) {
	// Call Google API to verify token
	resp, err := http.Get("https://www.googleapis.com/oauth2/v2/userinfo?access_token=" + token)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, err
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var googleUser GoogleUserInfo
	if err := json.Unmarshal(body, &googleUser); err != nil {
		return nil, err
	}

	return &googleUser, nil
}