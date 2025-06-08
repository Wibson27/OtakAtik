package middleware

import (
	"net/http"
	"strings"
	"time"

	"backend/config"
	"backend/models"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// TenangJWTClaims represents JWT token claims for Tenang.in platform
type TenangJWTClaims struct {
	UserID       uuid.UUID `json:"user_id"`
	Email        string    `json:"email"`
	IsAdmin      bool      `json:"is_admin"`
	PrivacyLevel string    `json:"privacy_level"`
	TokenType    string    `json:"token_type"` // "access" or "refresh"
	SessionID    string    `json:"session_id"`
	jwt.RegisteredClaims
}

// TenangAuthMiddleware validates JWT tokens for mental health platform
func TenangAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Extract token from Authorization header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			respondWithAuthError(c, "Authorization header required", "missing_token")
			return
		}

		// Check Bearer token format
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			respondWithAuthError(c, "Invalid authorization header format", "invalid_format")
			return
		}

		tokenString := parts[1]

		// Parse and validate token
		claims, err := ValidateTenangJWT(tokenString, "access")
		if err != nil {
			respondWithAuthError(c, "Invalid or expired token", "invalid_token")
			return
		}

		// Check token expiration
		if claims.ExpiresAt.Time.Before(time.Now()) {
			respondWithAuthError(c, "Token has expired", "token_expired")
			return
		}

		// Verify user still exists and is active (important for mental health platform security)
		db := c.MustGet("db").(*gorm.DB)
		var user models.User
		if err := db.Where("id = ? AND is_active = ?", claims.UserID, true).First(&user).Error; err != nil {
			respondWithAuthError(c, "User account not found or inactive", "user_not_found")
			return
		}

		// Update last active timestamp for user engagement tracking
		now := time.Now()
		user.LastActiveAt = &now
		db.Save(&user)

		// Store user information in context for controllers
		c.Set("user_id", claims.UserID)
		c.Set("user_email", claims.Email)
		c.Set("is_admin", claims.IsAdmin)
		c.Set("privacy_level", claims.PrivacyLevel)
		c.Set("session_id", claims.SessionID)
		c.Set("user", user) // Full user object for convenience

		c.Next()
	}
}

// RequireAdmin middleware ensures only admin users can access certain endpoints
func RequireAdmin() gin.HandlerFunc {
	return func(c *gin.Context) {
		isAdmin, exists := c.Get("is_admin")
		if !exists || !isAdmin.(bool) {
			c.JSON(http.StatusForbidden, gin.H{
				"error":   "Admin access required",
				"code":    "admin_required",
				"message": "This endpoint requires administrator privileges",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// OptionalAuth middleware for endpoints that work with or without authentication
func OptionalAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			// No auth provided, continue without user context
			c.Next()
			return
		}

		// Try to parse token
		parts := strings.Split(authHeader, " ")
		if len(parts) == 2 && parts[0] == "Bearer" {
			claims, err := ValidateTenangJWT(parts[1], "access")
			if err == nil && claims.ExpiresAt.Time.After(time.Now()) {
				// Valid token, set user context
				c.Set("user_id", claims.UserID)
				c.Set("user_email", claims.Email)
				c.Set("is_admin", claims.IsAdmin)
				c.Set("privacy_level", claims.PrivacyLevel)
			}
		}

		c.Next()
	}
}

// GenerateTenangJWT generates JWT tokens specifically for Tenang.in platform
func GenerateTenangJWT(user models.User, tokenType string, sessionID string) (string, error) {
	cfg := config.AppConfig

	var secret string
	var expiry time.Duration

	if tokenType == "access" {
		secret = cfg.JWT.AccessSecret
		expiry = cfg.JWT.AccessExpiry
	} else if tokenType == "refresh" {
		secret = cfg.JWT.RefreshSecret
		expiry = cfg.JWT.RefreshExpiry
	} else {
		return "", jwt.ErrInvalidKey
	}

	// Determine if user is admin (check by email pattern for Tenang.in)
	isAdmin := strings.HasSuffix(user.Email, "@tenang.in") || user.Email == "admin@tenang.in"

	// Create claims with mental health platform specific data
	claims := TenangJWTClaims{
		UserID:       user.ID,
		Email:        user.Email,
		IsAdmin:      isAdmin,
		PrivacyLevel: user.PrivacyLevel,
		TokenType:    tokenType,
		SessionID:    sessionID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(expiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    "tenang.in",
			Subject:   user.ID.String(),
			Audience:  []string{"tenang.in-users"},
		},
	}

	// Create token
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	// Sign token with secret
	tokenString, err := token.SignedString([]byte(secret))
	if err != nil {
		return "", err
	}

	return tokenString, nil
}

// ValidateTenangJWT validates and parses Tenang.in JWT tokens
func ValidateTenangJWT(tokenString, expectedType string) (*TenangJWTClaims, error) {
	cfg := config.AppConfig

	// Parse token
	token, err := jwt.ParseWithClaims(tokenString, &TenangJWTClaims{}, func(token *jwt.Token) (interface{}, error) {
		// Validate signing method
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrSignatureInvalid
		}

		// Get claims to determine which secret to use
		claims := token.Claims.(*TenangJWTClaims)
		if claims.TokenType == "access" {
			return []byte(cfg.JWT.AccessSecret), nil
		} else if claims.TokenType == "refresh" {
			return []byte(cfg.JWT.RefreshSecret), nil
		}

		return nil, jwt.ErrInvalidKey
	})

	if err != nil {
		return nil, err
	}

	// Validate token
	if !token.Valid {
		return nil, jwt.ErrTokenInvalid
	}

	// Get claims
	claims, ok := token.Claims.(*TenangJWTClaims)
	if !ok {
		return nil, jwt.ErrInvalidKey
	}

	// Validate token type
	if claims.TokenType != expectedType {
		return nil, jwt.ErrInvalidKey
	}

	// Validate issuer for security
	if claims.Issuer != "tenang.in" {
		return nil, jwt.ErrInvalidKey
	}

	return claims, nil
}

// RefreshTenangTokens generates new access and refresh tokens for Tenang.in
func RefreshTenangTokens(refreshToken string, db *gorm.DB) (string, string, error) {
	// Validate refresh token
	claims, err := ValidateTenangJWT(refreshToken, "refresh")
	if err != nil {
		return "", "", err
	}

	// Get user from database
	var user models.User
	if err := db.Where("id = ? AND is_active = ?", claims.UserID, true).First(&user).Error; err != nil {
		return "", "", err
	}

	// Generate new session ID for security
	newSessionID := uuid.New().String()

	// Generate new tokens
	newAccessToken, err := GenerateTenangJWT(user, "access", newSessionID)
	if err != nil {
		return "", "", err
	}

	newRefreshToken, err := GenerateTenangJWT(user, "refresh", newSessionID)
	if err != nil {
		return "", "", err
	}

	return newAccessToken, newRefreshToken, nil
}

// GetUserFromTenangContext extracts user information from Gin context
func GetUserFromTenangContext(c *gin.Context) (uuid.UUID, string, bool, string, error) {
	userID, exists := c.Get("user_id")
	if !exists {
		return uuid.Nil, "", false, "", jwt.ErrInvalidKey
	}

	email, exists := c.Get("user_email")
	if !exists {
		return uuid.Nil, "", false, "", jwt.ErrInvalidKey
	}

	isAdmin, exists := c.Get("is_admin")
	if !exists {
		return uuid.Nil, "", false, "", jwt.ErrInvalidKey
	}

	privacyLevel, exists := c.Get("privacy_level")
	if !exists {
		return uuid.Nil, "", false, "", jwt.ErrInvalidKey
	}

	return userID.(uuid.UUID), email.(string), isAdmin.(bool), privacyLevel.(string), nil
}

// GetFullUserFromContext gets the complete User object from context
func GetFullUserFromContext(c *gin.Context) (*models.User, error) {
	user, exists := c.Get("user")
	if !exists {
		return nil, jwt.ErrInvalidKey
	}

	userObj, ok := user.(models.User)
	if !ok {
		return nil, jwt.ErrInvalidKey
	}

	return &userObj, nil
}

// ValidateUserOwnership ensures user can only access their own data
func ValidateUserOwnership() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from token
		tokenUserID, _, _, _, err := GetUserFromTenangContext(c)
		if err != nil {
			respondWithAuthError(c, "Authentication required", "auth_required")
			return
		}

		// Get user ID from URL parameter
		paramUserID := c.Param("userId")
		if paramUserID == "" {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":   "User ID required in URL",
				"code":    "user_id_required",
				"message": "This endpoint requires a user ID parameter",
			})
			c.Abort()
			return
		}

		// Parse URL user ID
		urlUserID, err := uuid.Parse(paramUserID)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":   "Invalid user ID format",
				"code":    "invalid_user_id",
				"message": "User ID must be a valid UUID",
			})
			c.Abort()
			return
		}

		// Check if user is admin (admins can access any user's data)
		isAdmin, _ := c.Get("is_admin")
		if isAdmin.(bool) {
			c.Next()
			return
		}

		// Check if token user ID matches URL user ID
		if tokenUserID != urlUserID {
			c.JSON(http.StatusForbidden, gin.H{
				"error":   "Access denied",
				"code":    "access_denied",
				"message": "You can only access your own data",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// respondWithAuthError provides consistent authentication error responses
func respondWithAuthError(c *gin.Context, message string, code string) {
	// Log authentication failure for security monitoring
	clientIP := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	// TODO: Add proper logging to audit system
	// log.Printf("Auth failure: %s | IP: %s | UA: %s", code, clientIP, userAgent)

	c.JSON(http.StatusUnauthorized, gin.H{
		"error":   "Authentication failed",
		"code":    code,
		"message": message,
		"support": "If you're experiencing issues, please reach out to our support team",
	})
	c.Abort()
}