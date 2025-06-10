package middleware

import (
	"errors"
	"log"
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

// Custom errors for JWT validation for better error handling
var (
	ErrInvalidToken          = errors.New("token is invalid")
	ErrMismatchedTokenType   = errors.New("token type is mismatched")
	ErrMismatchedIssuer      = errors.New("token issuer is mismatched")
	ErrUserNotFoundOrInactive = errors.New("user account not found or inactive")
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
			// Handle specific token errors with tailored responses
			switch {
			case errors.Is(err, ErrInvalidToken):
				respondWithAuthError(c, "Invalid or expired token", "invalid_token")
			case errors.Is(err, jwt.ErrTokenExpired):
				respondWithAuthError(c, "Token has expired", "token_expired")
			default:
				respondWithAuthError(c, "Authentication failed", "auth_error")
			}
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
		c.Set("privacy_level", user.PrivacyLevel)
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
			if err == nil {
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
		return "", jwt.ErrInvalidKeyType
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
		claims, ok := token.Claims.(*TenangJWTClaims)
		if !ok {
			return nil, jwt.ErrInvalidKey
		}

		if claims.TokenType == "access" {
			return []byte(cfg.JWT.AccessSecret), nil
		} else if claims.TokenType == "refresh" {
			return []byte(cfg.JWT.RefreshSecret), nil
		}

		return nil, jwt.ErrInvalidKeyType
	})

	// Handle parsing errors (e.g., expired, malformed)
	if err != nil {
		return nil, err
	}

	// Get claims
	claims, ok := token.Claims.(*TenangJWTClaims)
	if !ok || !token.Valid {
		return nil, ErrInvalidToken
	}

	// Validate token type
	if claims.TokenType != expectedType {
		return nil, ErrMismatchedTokenType
	}

	// Validate issuer for security
	if claims.Issuer != "tenang.in" {
		return nil, ErrMismatchedIssuer
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
		return "", "", ErrUserNotFoundOrInactive
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
	userIDVal, exists := c.Get("user_id")
	if !exists {
		return uuid.Nil, "", false, "", ErrInvalidToken
	}

	emailVal, exists := c.Get("user_email")
	if !exists {
		return uuid.Nil, "", false, "", ErrInvalidToken
	}

	isAdminVal, exists := c.Get("is_admin")
	if !exists {
		return uuid.Nil, "", false, "", ErrInvalidToken
	}

	privacyLevelVal, exists := c.Get("privacy_level")
	if !exists {
		return uuid.Nil, "", false, "", ErrInvalidToken
	}

	// Type assertions
	userID, ok := userIDVal.(uuid.UUID)
	if !ok {
		return uuid.Nil, "", false, "", ErrInvalidToken
	}
	email, ok := emailVal.(string)
	if !ok {
		return uuid.Nil, "", false, "", ErrInvalidToken
	}
	isAdmin, ok := isAdminVal.(bool)
	if !ok {
		return uuid.Nil, "", false, "", ErrInvalidToken
	}
	privacyLevel, ok := privacyLevelVal.(string)
	if !ok {
		return uuid.Nil, "", false, "", ErrInvalidToken
	}

	return userID, email, isAdmin, privacyLevel, nil
}


// GetFullUserFromContext gets the complete User object from context
func GetFullUserFromContext(c *gin.Context) (*models.User, error) {
	userVal, exists := c.Get("user")
	if !exists {
		return nil, ErrInvalidToken
	}

	userObj, ok := userVal.(models.User)
	if !ok {
		return nil, ErrInvalidToken
	}

	return &userObj, nil
}

// ValidateUserOwnership ensures user can only access their own data
func ValidateUserOwnership() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from token
		tokenUserID, _, isAdminVal, _, err := GetUserFromTenangContext(c)
		if err != nil {
			respondWithAuthError(c, "Authentication required", "auth_required")
			return
		}

		// Admins can access any user's data
		if isAdminVal {
			c.Next()
			return
		}

		// Get user ID from URL parameter, if it exists
		paramUserIDStr := c.Param("userId")
		if paramUserIDStr == "" {
			c.Next()
			return // No ownership to check if userId is not in the URL
		}

		urlUserID, err := uuid.Parse(paramUserIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":   "Invalid user ID format in URL",
				"code":    "invalid_user_id_format",
			})
			c.Abort()
			return
		}

		// Check if token user ID matches URL user ID
		if tokenUserID != urlUserID {
			c.JSON(http.StatusForbidden, gin.H{
				"error":   "Access Denied",
				"code":    "access_denied",
				"message": "You do not have permission to access this resource.",
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

	log.Printf("Auth failure: %s | IP: %s | User-Agent: %s", code, clientIP, userAgent)

	c.JSON(http.StatusUnauthorized, gin.H{
		"error":   "Authentication failed",
		"code":    code,
		"message": message,
		"support": "If you're experiencing issues, please reach out to our support team.",
	})
	c.Abort()
}