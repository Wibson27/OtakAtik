package middleware

import (
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// TenangClientInfo stores rate limiting information for mental health platform
type TenangClientInfo struct {
	Requests       int
	ResetTime      time.Time
	LastRequest    time.Time
	ConsecutiveTries int       // Track consecutive attempts for mental health considerations
	UserID         *uuid.UUID // Track authenticated users separately
	Mutex          sync.Mutex
}

// TenangRateLimiter stores client information with mental health awareness
type TenangRateLimiter struct {
	Clients sync.Map
	Config  TenangRateLimitConfig
}

// TenangRateLimitConfig holds different rate limits for different endpoint types
type TenangRateLimitConfig struct {
	// Crisis/Support endpoints - more lenient
	CrisisLimit      int
	CrisisWindow     time.Duration

	// Chat endpoints - moderate limits
	ChatLimit        int
	ChatWindow       time.Duration

	// Community endpoints - standard limits
	CommunityLimit   int
	CommunityWindow  time.Duration

	// Auth endpoints - stricter for security
	AuthLimit        int
	AuthWindow       time.Duration

	// Public endpoints - strictest
	PublicLimit      int
	PublicWindow     time.Duration

	// Admin endpoints - lenient for operations
	AdminLimit       int
	AdminWindow      time.Duration
}

// NewTenangRateLimiter creates a rate limiter tailored for mental health platform
func NewTenangRateLimiter() *TenangRateLimiter {
	rl := &TenangRateLimiter{
		Config: TenangRateLimitConfig{
			// Crisis/Support - very lenient (someone in crisis shouldn't be rate limited)
			CrisisLimit:     200,
			CrisisWindow:    time.Minute,

			// Chat - moderate (therapeutic conversations need flexibility)
			ChatLimit:       100,
			ChatWindow:      time.Minute,

			// Community - standard (social interaction)
			CommunityLimit:  60,
			CommunityWindow: time.Minute,

			// Auth - strict (security sensitive)
			AuthLimit:       10,
			AuthWindow:      time.Minute,

			// Public - very strict (unauthenticated users)
			PublicLimit:     20,
			PublicWindow:    time.Minute,

			// Admin - lenient (operations need flexibility)
			AdminLimit:      300,
			AdminWindow:     time.Minute,
		},
	}

	// Clean up expired entries every 5 minutes
	go rl.cleanupExpiredEntries()

	return rl
}

// TenangRateLimitMiddleware creates mental health-aware rate limiting middleware
func TenangRateLimitMiddleware() gin.HandlerFunc {
	limiter := NewTenangRateLimiter()

	return func(c *gin.Context) {
		// Determine endpoint type and get appropriate limits
		endpointType := determineEndpointType(c.Request.URL.Path)
		limit, window := limiter.getLimitsForEndpoint(endpointType)

		// Get client identifier
		clientID := getClientIdentifier(c)

		// Check if user is authenticated (more lenient for authenticated users)
		userID := getUserIDFromContext(c)

		// Apply rate limiting
		allowed, resetTime, remainingRequests := limiter.IsAllowed(clientID, userID, limit, window, endpointType)

		if !allowed {
			// Provide supportive error message for mental health platform
			respondWithRateLimitError(c, endpointType, resetTime, limit)
			return
		}

		// Add rate limit headers
		c.Header("X-RateLimit-Limit", string(rune(limit)))
		c.Header("X-RateLimit-Remaining", string(rune(remainingRequests)))
		c.Header("X-RateLimit-Reset", string(rune(resetTime.Unix())))
		c.Header("X-RateLimit-Window", window.String())

		c.Next()
	}
}

// IsAllowed checks if a client is allowed to make a request with mental health considerations
func (rl *TenangRateLimiter) IsAllowed(clientID string, userID *uuid.UUID, limit int, window time.Duration, endpointType string) (bool, time.Time, int) {
	now := time.Now()

	// Load or create client info
	clientInfo, _ := rl.Clients.LoadOrStore(clientID, &TenangClientInfo{
		Requests:       0,
		ResetTime:      now.Add(window),
		LastRequest:    now,
		ConsecutiveTries: 0,
		UserID:         userID,
	})

	info := clientInfo.(*TenangClientInfo)
	info.Mutex.Lock()
	defer info.Mutex.Unlock()

	// Check if window has expired
	if now.After(info.ResetTime) {
		info.Requests = 0
		info.ResetTime = now.Add(window)
		info.ConsecutiveTries = 0
	}

	// Apply special rules for mental health platform
	adjustedLimit := rl.applyMentalHealthAdjustments(limit, endpointType, userID, info)

	// Check if limit exceeded
	if info.Requests >= adjustedLimit {
		info.ConsecutiveTries++
		return false, info.ResetTime, 0
	}

	// Allow request
	info.Requests++
	info.LastRequest = now
	remainingRequests := adjustedLimit - info.Requests

	return true, info.ResetTime, remainingRequests
}

// applyMentalHealthAdjustments applies special rules for mental health platform
func (rl *TenangRateLimiter) applyMentalHealthAdjustments(baseLimit int, endpointType string, userID *uuid.UUID, info *TenangClientInfo) int {
	adjustedLimit := baseLimit

	// Authenticated users get higher limits (they're verified users)
	if userID != nil {
		adjustedLimit = int(float64(baseLimit) * 1.5)
	}

	// Crisis endpoints get emergency boost
	if endpointType == "crisis" {
		adjustedLimit = baseLimit * 3
	}

	// Users who haven't been abusive get benefit of doubt
	if info.ConsecutiveTries == 0 {
		adjustedLimit = int(float64(adjustedLimit) * 1.2)
	}

	// During peak mental health hours (evening), be more lenient
	hour := time.Now().Hour()
	if hour >= 18 && hour <= 23 { // 6 PM to 11 PM
		adjustedLimit = int(float64(adjustedLimit) * 1.3)
	}

	return adjustedLimit
}

// determineEndpointType categorizes endpoints for appropriate rate limiting
func determineEndpointType(path string) string {
	// Crisis and emergency endpoints
	if strings.Contains(path, "crisis") || strings.Contains(path, "emergency") || strings.Contains(path, "support") {
		return "crisis"
	}

	// Chat and therapeutic endpoints
	if strings.Contains(path, "/chat") || strings.Contains(path, "/vocal") || strings.Contains(path, "/checkin") {
		return "chat"
	}

	// Authentication endpoints
	if strings.Contains(path, "/auth") {
		return "auth"
	}

	// Admin endpoints
	if strings.Contains(path, "/admin") || strings.Contains(path, "/system") {
		return "admin"
	}

	// Community endpoints
	if strings.Contains(path, "/community") || strings.Contains(path, "/social") {
		return "community"
	}

	// Public endpoints (health, categories, etc.)
	return "public"
}

// getLimitsForEndpoint returns appropriate limits for endpoint type
func (rl *TenangRateLimiter) getLimitsForEndpoint(endpointType string) (int, time.Duration) {
	switch endpointType {
	case "crisis":
		return rl.Config.CrisisLimit, rl.Config.CrisisWindow
	case "chat":
		return rl.Config.ChatLimit, rl.Config.ChatWindow
	case "community":
		return rl.Config.CommunityLimit, rl.Config.CommunityWindow
	case "auth":
		return rl.Config.AuthLimit, rl.Config.AuthWindow
	case "admin":
		return rl.Config.AdminLimit, rl.Config.AdminWindow
	default: // public
		return rl.Config.PublicLimit, rl.Config.PublicWindow
	}
}

// getClientIdentifier creates a unique identifier for rate limiting
func getClientIdentifier(c *gin.Context) string {
	// Try to get user ID first (most specific)
	if userID := getUserIDFromContext(c); userID != nil {
		return "user:" + userID.String()
	}

	// Fall back to IP address
	clientIP := c.ClientIP()

	// Include User-Agent to distinguish different apps/browsers from same IP
	userAgent := c.GetHeader("User-Agent")
	if len(userAgent) > 50 {
		userAgent = userAgent[:50] // Truncate long user agents
	}

	return "ip:" + clientIP + ":ua:" + userAgent
}

// getUserIDFromContext safely extracts user ID from context
func getUserIDFromContext(c *gin.Context) *uuid.UUID {
	userID, exists := c.Get("user_id")
	if !exists {
		return nil
	}

	uid, ok := userID.(uuid.UUID)
	if !ok {
		return nil
	}

	return &uid
}

// respondWithRateLimitError provides supportive rate limit error messages
func respondWithRateLimitError(c *gin.Context, endpointType string, resetTime time.Time, limit int) {
	retryAfter := int(time.Until(resetTime).Seconds())

	// Customize message based on endpoint type for mental health sensitivity
	var message string
	var supportMessage string

	switch endpointType {
	case "crisis":
		message = "Kami sedang mengalami permintaan tinggi untuk layanan dukungan krisis. Mohon tunggu sebentar sebelum mencoba lagi."
		supportMessage = "Jika ini adalah keadaan darurat, silakan hubungi hotline krisis: 119 atau WhatsApp ke 081-111-500-711"
	case "chat":
		message = "Sistem chat sedang sibuk melayani banyak pengguna. Mohon tunggu sebentar untuk melanjutkan percakapan."
		supportMessage = "Kami ingin memastikan setiap percakapan mendapat perhatian penuh dari AI kami."
	case "community":
		message = "Terlalu banyak aktivitas komunitas dalam waktu singkat. Mohon tunggu sebentar sebelum berinteraksi lagi."
		supportMessage = "Ini membantu menjaga kualitas diskusi di komunitas untuk semua pengguna."
	case "auth":
		message = "Terlalu banyak percobaan login. Mohon tunggu sebentar untuk keamanan akun Anda."
		supportMessage = "Jika Anda lupa password, gunakan fitur reset password."
	default:
		message = "Terlalu banyak permintaan dalam waktu singkat. Mohon tunggu sebentar sebelum mencoba lagi."
		supportMessage = "Ini membantu menjaga kinerja platform untuk semua pengguna."
	}

	c.Header("Retry-After", string(rune(retryAfter)))
	c.Header("X-RateLimit-Limit", string(rune(limit)))
	c.Header("X-RateLimit-Remaining", "0")
	c.Header("X-RateLimit-Reset", string(rune(resetTime.Unix())))

	c.JSON(http.StatusTooManyRequests, gin.H{
		"error":         "Rate limit exceeded",
		"message":       message,
		"support":       supportMessage,
		"retry_after":   retryAfter,
		"reset_time":    resetTime.UTC().Format(time.RFC3339),
		"endpoint_type": endpointType,
		"wellbeing_tip": "Mengambil jeda sebentar juga baik untuk kesehatan mental. Tarik napas dalam-dalam. 🌸",
	})
	c.Abort()
}

// cleanupExpiredEntries removes expired client entries to prevent memory leaks
func (rl *TenangRateLimiter) cleanupExpiredEntries() {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	for range ticker.C {
		now := time.Now()
		rl.Clients.Range(func(key, value interface{}) bool {
			info := value.(*TenangClientInfo)
			info.Mutex.Lock()

			// Remove entries that haven't been used in the last hour
			expired := now.After(info.ResetTime.Add(time.Hour))

			info.Mutex.Unlock()

			if expired {
				rl.Clients.Delete(key)
			}
			return true
		})
	}
}

// GetCurrentUsage returns current rate limit usage for monitoring
func (rl *TenangRateLimiter) GetCurrentUsage() map[string]interface{} {
	stats := map[string]interface{}{
		"total_clients":    0,
		"active_clients":   0,
		"authenticated":    0,
		"anonymous":        0,
	}

	now := time.Now()
	totalClients := 0
	activeClients := 0
	authenticated := 0
	anonymous := 0

	rl.Clients.Range(func(key, value interface{}) bool {
		totalClients++
		info := value.(*TenangClientInfo)

		// Active in last 5 minutes
		if now.Sub(info.LastRequest) < 5*time.Minute {
			activeClients++
		}

		if info.UserID != nil {
			authenticated++
		} else {
			anonymous++
		}

		return true
	})

	stats["total_clients"] = totalClients
	stats["active_clients"] = activeClients
	stats["authenticated"] = authenticated
	stats["anonymous"] = anonymous

	return stats
}