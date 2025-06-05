package controllers

import (
	"net/http"
	"strings"
	"backend/models"
	"time"

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

// Register creates a new user account with credentials and preferences
func (a *AuthController) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Check if email already exists
	var existingUser models.User
	if err := a.DB.Where("email = ?", req.Email).First(&existingUser).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Email already registered"})
		return
	}

	// Check if username already exists (if provided)
	if req.Username != "" {
		if err := a.DB.Where("username = ?", req.Username).First(&existingUser).Error; err == nil {
			c.JSON(http.StatusConflict, gin.H{"error": "Username already taken"})
			return
		}
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	// Parse date of birth if provided
	var dateOfBirth *time.Time
	if req.DateOfBirth != "" {
		if dob, err := time.Parse("2006-01-02", req.DateOfBirth); err == nil {
			dateOfBirth = &dob
		}
	}

	// Start transaction
	tx := a.DB.Begin()

	// Create user
	user := models.User{
		Email:       req.Email,
		FullName:    &req.FullName,
		DateOfBirth: dateOfBirth,
		IsActive:    true,
	}

	if req.Username != "" {
		user.Username = &req.Username
	}

	if err := tx.Create(&user).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
		return
	}

	// Create user credentials
	credentials := models.UserCredentials{
		UserID:       user.ID,
		PasswordHash: string(hashedPassword),
	}

	if err := tx.Create(&credentials).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create credentials"})
		return
	}

	// Create default user preferences
	preferences := models.UserPreferences{
		UserID:                    user.ID,
		NotificationChat:          true,
		NotificationCommunity:     true,
		CommunityAnonymousDefault: false,
		SocialMediaMonitoring:     false,
	}

	if err := tx.Create(&preferences).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create preferences"})
		return
	}

	// Commit transaction
	tx.Commit()

	// Return user without sensitive data
	c.JSON(http.StatusCreated, gin.H{
		"message": "Account created successfully",
		"user": gin.H{
			"id":       user.ID,
			"email":    user.Email,
			"fullName": user.FullName,
			"username": user.Username,
		},
	})
}

// Login authenticates user and returns user data
func (a *AuthController) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Find user by email
	var user models.User
	if err := a.DB.Where("email = ? AND is_active = ?", req.Email, true).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
		return
	}

	// Get user credentials
	var credentials models.UserCredentials
	if err := a.DB.Where("user_id = ?", user.ID).First(&credentials).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
		return
	}

	// Check if account is locked
	if credentials.LockedUntil != nil && credentials.LockedUntil.After(time.Now()) {
		c.JSON(http.StatusLocked, gin.H{"error": "Account is temporarily locked"})
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

		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
		return
	}

	// Reset failed login attempts on successful login
	credentials.FailedLoginAttempts = 0
	credentials.LockedUntil = nil
	a.DB.Save(&credentials)

	// Update last active
	now := time.Now()
	user.LastActiveAt = &now
	a.DB.Save(&user)

	// TODO: Generate JWT token here
	// Example: token, err := generateJWT(user.ID)
	// if err != nil { ... }

	// Return user data (without sensitive information)
	c.JSON(http.StatusOK, gin.H{
		"message": "Login successful",
		"user": gin.H{
			"id":           user.ID,
			"email":        user.Email,
			"fullName":     user.FullName,
			"username":     user.Username,
			"lastActiveAt": user.LastActiveAt,
		},
		// "token": token, // TODO: Include JWT token
	})
}

// Logout handles user logout (when JWT is implemented)
func (a *AuthController) Logout(c *gin.Context) {
	// TODO: Implement JWT token invalidation
	// For now, return success (client should remove token)
	c.JSON(http.StatusOK, gin.H{"message": "Logged out successfully"})
}

// ChangePassword allows users to change their password
func (a *AuthController) ChangePassword(c *gin.Context) {
	type ChangePasswordRequest struct {
		CurrentPassword string `json:"currentPassword" binding:"required"`
		NewPassword     string `json:"newPassword" binding:"required,min=6"`
	}

	var req ChangePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Get user ID from JWT token
	// userID := getUserIDFromToken(c)
	userIDStr := c.Param("userId") // Temporary: get from URL param
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Get user credentials
	var credentials models.UserCredentials
	if err := a.DB.Where("user_id = ?", userID).First(&credentials).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Verify current password
	if err := bcrypt.CompareHashAndPassword([]byte(credentials.PasswordHash), []byte(req.CurrentPassword)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Current password is incorrect"})
		return
	}

	// Hash new password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	// Update password
	credentials.PasswordHash = string(hashedPassword)
	credentials.PasswordChangedAt = time.Now()
	if err := a.DB.Save(&credentials).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update password"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Password changed successfully"})
}

// ForgotPassword initiates password reset process
func (a *AuthController) ForgotPassword(c *gin.Context) {
	type ForgotPasswordRequest struct {
		Email string `json:"email" binding:"required,email"`
	}

	var req ForgotPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Check if user exists
	var user models.User
	if err := a.DB.Where("email = ?", req.Email).First(&user).Error; err != nil {
		// Don't reveal if email exists or not for security
		c.JSON(http.StatusOK, gin.H{"message": "If the email exists, a reset link has been sent"})
		return
	}

	// TODO: Generate password reset token and send email
	// resetToken := generateResetToken()
	// sendPasswordResetEmail(user.Email, resetToken)

	c.JSON(http.StatusOK, gin.H{"message": "If the email exists, a reset link has been sent"})
}

// VerifyEmail verifies user email address
func (a *AuthController) VerifyEmail(c *gin.Context) {
	// TODO: Implement email verification
	// token := c.Query("token")
	// userID := validateEmailVerificationToken(token)

	c.JSON(http.StatusNotImplemented, gin.H{"message": "Email verification not implemented yet"})
}

// Helper function to validate email format (additional validation)
func isValidEmail(email string) bool {
	return strings.Contains(email, "@") && strings.Contains(email, ".")
}