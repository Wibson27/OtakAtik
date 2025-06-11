package controllers

import (
	"context"
	"errors"
	"net/http"
	"time"

	"backend/config"
	"backend/middleware"
	"backend/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"google.golang.org/api/idtoken"
	"gorm.io/gorm"
)

// AuthController handles all authentication-related API requests.
type AuthController struct {
	DB  *gorm.DB
	Cfg *config.Config
}

// NewAuthController creates a new instance of AuthController with dependencies.
func NewAuthController(db *gorm.DB, cfg *config.Config) *AuthController {
	return &AuthController{DB: db, Cfg: cfg}
}

// --- DTOs and Request Structs ---

type RegisterRequest struct {
	Email       string `json:"email" binding:"required,email"`
	Password    string `json:"password" binding:"required,min=8"`
	FullName    string `json:"full_name" binding:"required,min=2"`
	Username    string `json:"username" binding:"omitempty,min=3"`
	DateOfBirth string `json:"date_of_birth" binding:"omitempty,datetime=2006-01-02"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type GoogleAuthRequest struct {
	IDToken string `json:"id_token" binding:"required"`
}

type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

type ChangePasswordRequest struct {
	CurrentPassword string `json:"current_password" binding:"required"`
	NewPassword     string `json:"new_password" binding:"required,min=8"`
}

type AuthResponse struct {
	Message string `json:"message"`
	User    struct {
		ID       uuid.UUID `json:"id"`
		Email    string    `json:"email"`
		FullName *string   `json:"full_name"`
		Username *string   `json:"username"`
	} `json:"user"`
	Tokens struct {
		AccessToken  string `json:"access_token"`
		RefreshToken string `json:"refresh_token"`
		TokenType    string `json:"token_type"`
		ExpiresIn    int64  `json:"expires_in"`
	} `json:"tokens"`
}

// --- Controller Handlers ---

// Register handles new user registration.
func (a *AuthController) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data", "details": err.Error()})
		return
	}

	var existingUser models.User
	if err := a.DB.Where("email = ?", req.Email).First(&existingUser).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Email already registered"})
		return
	}

	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)

	user := models.User{
		ID:       uuid.New(),
		Email:    req.Email,
		FullName: &req.FullName,
		IsActive: true,
	}
	if req.Username != "" { user.Username = &req.Username }
	if dob, err := time.Parse("2006-01-02", req.DateOfBirth); err == nil { user.DateOfBirth = &dob }

	err := a.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&user).Error; err != nil { return err }
		if err := tx.Create(&models.UserCredentials{UserID: user.ID, PasswordHash: string(hashedPassword)}).Error; err != nil { return err }
		if err := tx.Create(&models.UserPreferences{UserID: user.ID}).Error; err != nil { return err }
		return nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user account", "code": "db_transaction_failed"})
		return
	}

	a.generateTokensAndRespond(c, user, http.StatusCreated, "Registrasi berhasil! Selamat datang di Tenang.in 🌸")
}

// Login handles user authentication.
func (a *AuthController) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data"})
		return
	}

	var user models.User
	if err := a.DB.Where("email = ? AND is_active = ?", req.Email, true).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	var credentials models.UserCredentials
	a.DB.Where("user_id = ?", user.ID).First(&credentials)
	if err := bcrypt.CompareHashAndPassword([]byte(credentials.PasswordHash), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	a.DB.Model(&user).Update("last_active_at", time.Now())
	a.generateTokensAndRespond(c, user, http.StatusOK, "Login berhasil! Selamat datang kembali 🌸")
}

// RefreshToken provides new access and refresh tokens.
func (a *AuthController) RefreshToken(c *gin.Context) {
	var req RefreshTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid refresh token request"})
		return
	}

	claims, err := middleware.ValidateTenangJWT(req.RefreshToken, "refresh")
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired refresh token"})
		return
	}

	var user models.User
	if err := a.DB.First(&user, claims.UserID).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found for this token"})
		return
	}

	a.generateTokensAndRespond(c, user, http.StatusOK, "Tokens refreshed successfully")
}

// GoogleAuth handles authentication via Google ID token.
func (a *AuthController) GoogleAuth(c *gin.Context) {
	var req GoogleAuthRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID token request"})
		return
	}

	// Verifikasi token ID dengan Google secara aman di backend
	idTokenPayload, err := idtoken.Validate(context.Background(), req.IDToken, a.Cfg.Google.ClientID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid Google ID token", "details": err.Error()})
		return
	}

	email := idTokenPayload.Claims["email"].(string)
	name := idTokenPayload.Claims["name"].(string)

	var user models.User
	err = a.DB.Where(models.User{Email: email}).First(&user).Error

	if errors.Is(err, gorm.ErrRecordNotFound) { // User baru
		newUser := models.User{
			ID:              uuid.New(),
			Email:           email,
			FullName:        &name,
			IsActive:        true,
			EmailVerifiedAt: func() *time.Time { t := time.Now(); return &t }(),
		}
		err = a.DB.Transaction(func(tx *gorm.DB) error {
			if err := tx.Create(&newUser).Error; err != nil { return err }
			if err := tx.Create(&models.UserCredentials{UserID: newUser.ID, PasswordHash: "google_sso"}).Error; err != nil { return err }
			if err := tx.Create(&models.UserPreferences{UserID: newUser.ID}).Error; err != nil { return err }
			return nil
		})
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user from Google account"})
			return
		}
		a.generateTokensAndRespond(c, newUser, http.StatusCreated, "Akun berhasil dibuat dengan Google! Selamat datang 🌸")
	} else if err == nil { // User sudah ada
		a.DB.Model(&user).Update("last_active_at", time.Now())
		a.generateTokensAndRespond(c, user, http.StatusOK, "Login dengan Google berhasil! Selamat datang kembali 🌸")
	} else {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error during Google auth"})
	}
}

// Logout is a placeholder for client-side token deletion.
func (a *AuthController) Logout(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Logout successful. Please clear tokens on the client."})
}

// ChangePassword allows an authenticated user to change their password.
func (a *AuthController) ChangePassword(c *gin.Context) {
	var req ChangePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil { c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data"}); return }
	authedUser, _ := middleware.GetFullUserFromContext(c)

	var credentials models.UserCredentials
	if err := a.DB.Where("user_id = ?", authedUser.ID).First(&credentials).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User credentials not found"}); return
	}
	if err := bcrypt.CompareHashAndPassword([]byte(credentials.PasswordHash), []byte(req.CurrentPassword)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid current password"}); return
	}

	newHashedPassword, _ := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	credentials.PasswordHash = string(newHashedPassword)
	credentials.PasswordChangedAt = time.Now()
	a.DB.Save(&credentials)

	c.JSON(http.StatusOK, gin.H{"message": "Password changed successfully"})
}

// (Placeholders for features requiring email service)
func (a *AuthController) ForgotPassword(c *gin.Context) { c.JSON(http.StatusOK, gin.H{"message": "If your email is registered, a password reset link has been sent."}) }
func (a *AuthController) ResetPassword(c *gin.Context) { c.JSON(http.StatusOK, gin.H{"message": "Password has been reset successfully."}) }
func (a *AuthController) VerifyEmail(c *gin.Context) { c.JSON(http.StatusOK, gin.H{"message": "Email verified successfully."}) }

// --- Helper Functions ---

func (a *AuthController) generateTokensAndRespond(c *gin.Context, user models.User, statusCode int, message string) {
	sessionID := uuid.New().String()
	accessToken, errAccess := middleware.GenerateTenangJWT(user, "access", sessionID)
	refreshToken, errRefresh := middleware.GenerateTenangJWT(user, "refresh", sessionID)

	if errAccess != nil || errRefresh != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate tokens"})
		return
	}

	accessExpiry := a.Cfg.JWT.AccessExpiry

	response := AuthResponse{ Message: message }
	response.User.ID = user.ID
	response.User.Email = user.Email
	response.User.FullName = user.FullName
	response.User.Username = user.Username
	response.Tokens.AccessToken = accessToken
	response.Tokens.RefreshToken = refreshToken
	response.Tokens.TokenType = "Bearer"
	response.Tokens.ExpiresIn = int64(accessExpiry.Seconds())

	c.JSON(statusCode, response)
}