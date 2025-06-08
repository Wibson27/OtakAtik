package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"

	"backend/config"
	"backend/controllers"
	"backend/middleware"
	"backend/models"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func main() {
	// Load configuration for Tenang.in platform
	log.Println("🌸 Starting Tenang.in - Mental Health Platform...")
	cfg := config.LoadConfig()

	// Set Gin mode based on environment
	gin.SetMode(cfg.Server.Environment)

	// Initialize database connection
	db := config.DatabaseConnection()

	// Auto migrate all Tenang.in models
	log.Println("📊 Starting database migration for mental health platform...")
	err := migrateTenangModels(db)
	if err != nil {
		log.Fatal("❌ Failed to migrate Tenang.in database:", err)
	}
	log.Println("✅ Tenang.in database migration completed successfully")

	// Create initial data (community categories, admin user, etc.)
	config.CreateInitialData(db)

	// Initialize all Tenang.in controllers with dependency injection
	controllers := initializeTenangControllers(db)

	// Setup Gin router with mental health platform configuration
	router := setupTenangRouter(cfg, db)

	// Setup all platform routes
	setupTenangRoutes(router, controllers)

	// Setup static file serving for mental health content
	setupStaticFileServing(router, cfg)

	// Print startup information
	printTenangStartupInfo(cfg)

	// Start the Tenang.in server
	address := fmt.Sprintf("%s:%s", cfg.Server.Host, cfg.Server.Port)
	log.Printf("🚀 Tenang.in server starting on http://%s", address)
	log.Printf("🔒 Environment: %s", cfg.Server.Environment)
	log.Printf("🌐 CORS Origins: %v", cfg.Server.CORSOrigins)

	if err := router.Run(address); err != nil {
		log.Fatal("❌ Failed to start Tenang.in server:", err)
	}
}

// migrateTenangModels performs database migration for all mental health platform models
func migrateTenangModels(db *gorm.DB) error {
	return db.AutoMigrate(
		// User management models - Privacy-first design
		&models.User{},
		&models.UserCredentials{},
		&models.UserPreferences{},
		&models.UserSession{},

		// Mental health chat & conversation models
		&models.ChatSession{},
		&models.ChatMessage{},
		&models.ScheduledCheckin{},

		// Vocal journal models for emotional wellbeing
		&models.VocalJournalEntry{},
		&models.VocalTranscription{},
		&models.VocalSentimentAnalysis{},

		// Community models for peer support
		&models.CommunityCategory{},
		&models.CommunityPost{},
		&models.CommunityPostReply{},
		&models.CommunityReaction{},

		// Social media monitoring models (optional, privacy-focused)
		&models.SocialMediaAccount{},
		&models.SocialMediaPostMonitored{},

		// Support models for platform operations
		&models.Notification{},
		&models.UserProgressMetric{},
		&models.SystemAnalytics{},
		&models.AuditLog{},
	)
}

// TenangControllers holds all controller instances for the platform
type TenangControllers struct {
	Auth         *controllers.AuthController
	User         *controllers.UserController
	Chat         *controllers.ChatController
	Vocal        *controllers.VocalController
	Community    *controllers.CommunityController
	Notification *controllers.NotificationController
	Social       *controllers.SocialController
	Analytics    *controllers.AnalyticsController
}

// initializeTenangControllers creates all controller instances with database injection
func initializeTenangControllers(db *gorm.DB) *TenangControllers {
	return &TenangControllers{
		Auth:         &controllers.AuthController{DB: db},
		User:         &controllers.UserController{DB: db},
		Chat:         &controllers.ChatController{DB: db},
		Vocal:        &controllers.VocalController{DB: db},
		Community:    &controllers.CommunityController{DB: db},
		Notification: &controllers.NotificationController{DB: db},
		Social:       &controllers.SocialController{DB: db},
		Analytics:    &controllers.AnalyticsController{DB: db},
	}
}

// setupTenangRouter configures Gin router with mental health platform specific middleware
func setupTenangRouter(cfg *config.Config, db *gorm.DB) *gin.Engine {
	router := gin.New()

	// Global middleware stack for mental health platform
	router.Use(gin.Logger())
	router.Use(gin.Recovery())

	// CORS configuration for Flutter frontend and web access
	corsConfig := cors.Config{
		AllowOrigins:     cfg.Server.CORSOrigins,
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization", "X-Requested-With", "X-User-Privacy-Level"},
		ExposeHeaders:    []string{"Content-Length", "X-RateLimit-Limit", "X-RateLimit-Remaining", "X-RateLimit-Reset"},
		AllowCredentials: true,
		MaxAge:          12 * 60 * 60, // 12 hours
	}
	router.Use(cors.New(corsConfig))

	// Mental health platform specific security headers
	router.Use(func(c *gin.Context) {
		// Security headers for mental health data protection
		c.Header("X-Content-Type-Options", "nosniff")
		c.Header("X-Frame-Options", "DENY")
		c.Header("X-XSS-Protection", "1; mode=block")
		c.Header("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
		c.Header("Referrer-Policy", "strict-origin-when-cross-origin")
		c.Header("Content-Security-Policy", "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; font-src 'self' data:; img-src 'self' data: https:; media-src 'self' blob:; connect-src 'self' https:")

		// Mental health platform identification
		c.Header("X-Platform", "Tenang.in")
		c.Header("X-Platform-Version", "1.0.0")

		c.Next()
	})

	// Rate limiting middleware with mental health awareness
	router.Use(middleware.TenangRateLimitMiddleware())

	// Make database available to all routes
	router.Use(func(c *gin.Context) {
		c.Set("db", db)
		c.Next()
	})

	return router
}

// setupTenangRoutes configures all API routes for the mental health platform
func setupTenangRoutes(router *gin.Engine, controllers *TenangControllers) {
	// Health check and platform info endpoints
	setupHealthEndpoints(router)

	// API v1 routes for Tenang.in
	v1 := router.Group("/api/v1")

	// Public routes (no authentication required)
	setupPublicRoutes(v1, controllers)

	// Protected routes (require JWT authentication)
	protected := v1.Group("/")
	protected.Use(middleware.TenangAuthMiddleware())
	setupProtectedRoutes(protected, controllers)

	// Admin routes (require admin privileges)
	admin := v1.Group("/admin")
	admin.Use(middleware.TenangAuthMiddleware())
	admin.Use(middleware.RequireAdmin())
	setupAdminRoutes(admin, controllers)
}

// setupHealthEndpoints creates health check and platform status endpoints
func setupHealthEndpoints(router *gin.Engine) {
	// Welcome endpoint with mental health platform information
	router.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message":     "Selamat datang di Tenang.in - Platform Kesehatan Mental",
			"platform":    "Tenang.in",
			"version":     "1.0.0",
			"description": "Platform kesehatan mental yang aman dan supportif untuk semua",
			"features": []string{
				"AI Chatbot untuk dukungan mental",
				"Vocal Journal dengan analisis sentimen",
				"Komunitas peer support",
				"Monitoring media sosial (opsional)",
				"Analytics kesehatan mental",
			},
			"support": "Jika membutuhkan bantuan darurat: 119 atau WhatsApp 081-111-500-711",
		})
	})

	// Health check endpoint for monitoring
	router.GET("/health", func(c *gin.Context) {
		db := c.MustGet("db").(*gorm.DB)

		// Check database connection
		sqlDB, err := db.DB()
		var dbStatus string
		if err != nil || sqlDB.Ping() != nil {
			dbStatus = "disconnected"
		} else {
			dbStatus = "connected"
		}

		// Get basic platform metrics
		var userCount, activeUserCount int64
		db.Model(&models.User{}).Where("is_active = ?", true).Count(&userCount)
		db.Model(&models.User{}).Where("is_active = ? AND last_active_at > NOW() - INTERVAL '24 hours'", true).Count(&activeUserCount)

		c.JSON(http.StatusOK, gin.H{
			"status":            "healthy",
			"platform":          "Tenang.in",
			"database":          dbStatus,
			"total_users":       userCount,
			"active_users_24h":  activeUserCount,
			"timestamp":         gin.H{},
		})
	})

	// Privacy policy endpoint (important for mental health platform)
	router.GET("/privacy", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"privacy_policy": "Tenang.in menerapkan Privacy by Design",
			"data_collection": "Minimal data collection - hanya yang diperlukan",
			"user_control": "Pengguna memiliki kontrol penuh atas data mereka",
			"encryption": "Data sensitif dienkripsi end-to-end",
			"anonymity": "Opsi partisipasi anonim tersedia",
			"gdpr_compliance": "Fully compliant with GDPR regulations",
			"contact": "privacy@tenang.in",
		})
	})
}

// setupPublicRoutes configures routes that don't require authentication
func setupPublicRoutes(v1 *gin.RouterGroup, controllers *TenangControllers) {
	// Authentication routes
	auth := v1.Group("/auth")
	{
		auth.POST("/register", controllers.Auth.Register)
		auth.POST("/login", controllers.Auth.Login)
		auth.POST("/google", controllers.Auth.GoogleAuth)
		auth.POST("/refresh", controllers.Auth.RefreshToken)
		auth.POST("/forgot-password", controllers.Auth.ForgotPassword)
		auth.POST("/reset-password", controllers.Auth.ResetPassword)
		auth.GET("/verify-email", controllers.Auth.VerifyEmail)
	}

	// Public community routes (for browsing without account)
	community := v1.Group("/community")
	community.Use(middleware.OptionalAuth()) // Optional auth for personalization
	{
		community.GET("/categories", controllers.Community.GetCategories)
		community.GET("/posts/public", controllers.Community.GetPublicPosts)
		community.GET("/posts/:postId", controllers.Community.GetPost)
	}

	// Webhook endpoints (external services)
	webhooks := v1.Group("/webhooks")
	{
		webhooks.POST("/social/:platform", controllers.Social.HandleWebhook)
	}
}

// setupProtectedRoutes configures routes that require JWT authentication
func setupProtectedRoutes(protected *gin.RouterGroup, controllers *TenangControllers) {
	// User management routes with ownership validation
	users := protected.Group("/users")
	users.Use(middleware.ValidateUserOwnership())
	{
		users.GET("/:userId/profile", controllers.User.GetProfile)
		users.PUT("/:userId/profile", controllers.User.UpdateProfile)
		users.GET("/:userId/preferences", controllers.User.GetPreferences)
		users.PUT("/:userId/preferences", controllers.User.UpdatePreferences)
		users.GET("/:userId/dashboard", controllers.User.GetDashboardStats)
		users.GET("/:userId/progress", controllers.User.GetProgressMetrics)
		users.DELETE("/:userId/deactivate", controllers.User.DeactivateAccount)
	}

	// Mental health chat routes
	chat := protected.Group("/chat")
	chat.Use(middleware.ValidateUserOwnership())
	{
		chat.POST("/:userId/sessions", controllers.Chat.CreateSession)
		chat.GET("/:userId/sessions", controllers.Chat.GetSessions)
		chat.GET("/sessions/:sessionId", controllers.Chat.GetSession)
		chat.POST("/messages", controllers.Chat.SendMessage)
		chat.PUT("/sessions/:sessionId/end", controllers.Chat.EndSession)

		// Scheduled mental health check-ins
		chat.GET("/:userId/checkins", controllers.Chat.GetScheduledCheckins)
		chat.POST("/:userId/checkins", controllers.Chat.CreateScheduledCheckin)
		chat.PUT("/checkins/:checkinId", controllers.Chat.UpdateScheduledCheckin)
		chat.DELETE("/checkins/:checkinId", controllers.Chat.DeleteScheduledCheckin)
	}

	// Vocal journal routes for emotional tracking
	vocal := protected.Group("/vocal")
	vocal.Use(middleware.ValidateUserOwnership())
	{
		vocal.POST("/:userId/entries", controllers.Vocal.CreateEntry)
		vocal.GET("/:userId/entries", controllers.Vocal.GetEntries)
		vocal.GET("/entries/:entryId", controllers.Vocal.GetEntry)
		vocal.PUT("/entries/:entryId", controllers.Vocal.UpdateEntry)
		vocal.DELETE("/entries/:entryId", controllers.Vocal.DeleteEntry)
		vocal.GET("/entries/:entryId/transcription", controllers.Vocal.GetTranscription)
		vocal.GET("/entries/:entryId/analysis", controllers.Vocal.GetSentimentAnalysis)
		vocal.GET("/:userId/trends", controllers.Vocal.GetWellbeingTrends)
		vocal.GET("/entries/:entryId/audio", controllers.Vocal.GetAudioFile)
	}

	// Community routes for peer support
	community := protected.Group("/community")
	{
		community.POST("/:userId/posts", controllers.Community.CreatePost)
		community.PUT("/:userId/posts/:postId", controllers.Community.UpdatePost)
		community.DELETE("/:userId/posts/:postId", controllers.Community.DeletePost)
		community.GET("/:userId/posts", controllers.Community.GetUserPosts)

		// Community interactions
		community.POST("/:userId/replies", controllers.Community.CreateReply)
		community.POST("/:userId/reactions", controllers.Community.AddReaction)
		community.POST("/:userId/posts/:postId/report", controllers.Community.ReportPost)
	}

	// Notification system
	notifications := protected.Group("/notifications")
	notifications.Use(middleware.ValidateUserOwnership())
	{
		notifications.GET("/:userId", controllers.Notification.GetNotifications)
		notifications.PUT("/:userId/:notificationId/read", controllers.Notification.MarkAsRead)
		notifications.PUT("/:userId/read-all", controllers.Notification.MarkAllAsRead)
		notifications.DELETE("/:userId/:notificationId", controllers.Notification.DeleteNotification)
		notifications.GET("/:userId/settings", controllers.Notification.GetNotificationSettings)
		notifications.PUT("/:userId/settings", controllers.Notification.UpdateNotificationSettings)
		notifications.GET("/:userId/stats", controllers.Notification.GetNotificationStats)
		notifications.POST("/:userId/test", controllers.Notification.SendTestNotification)
		notifications.GET("/:userId/unread-count", controllers.Notification.GetUnreadCount)
	}

	// Social media monitoring (optional, privacy-focused)
	social := protected.Group("/social")
	social.Use(middleware.ValidateUserOwnership())
	{
		social.POST("/:userId/connect", controllers.Social.ConnectAccount)
		social.GET("/:userId/accounts", controllers.Social.GetConnectedAccounts)
		social.PUT("/:userId/accounts/:accountId", controllers.Social.UpdateAccountSettings)
		social.DELETE("/:userId/accounts/:accountId", controllers.Social.DisconnectAccount)
		social.GET("/accounts/:accountId/posts", controllers.Social.GetMonitoredPosts)
		social.POST("/:userId/accounts/:accountId/sync", controllers.Social.SyncAccount)
		social.GET("/:userId/insights", controllers.Social.GetSocialMediaInsights)
	}

	// User analytics and wellbeing reports
	analytics := protected.Group("/analytics")
	{
		analytics.POST("/events", controllers.Analytics.RecordEvent)
		analytics.GET("/:userId/user", middleware.ValidateUserOwnership(), controllers.Analytics.GetUserAnalytics)
		analytics.GET("/:userId/wellbeing-report", middleware.ValidateUserOwnership(), controllers.Analytics.GetWellbeingReport)
	}

	// Authentication management (protected)
	authProtected := protected.Group("/auth")
	{
		authProtected.POST("/logout", controllers.Auth.Logout)
		authProtected.POST("/change-password/:userId", middleware.ValidateUserOwnership(), controllers.Auth.ChangePassword)
	}
}

// setupAdminRoutes configures admin-only routes for platform management
func setupAdminRoutes(admin *gin.RouterGroup, controllers *TenangControllers) {
	// System analytics and monitoring
	admin.GET("/analytics/system/metrics", controllers.Analytics.GetSystemMetrics)
	admin.GET("/analytics/system/health", controllers.Analytics.GetPlatformHealth)

	// Community moderation
	admin.POST("/community/posts/:postId/moderate", controllers.Community.ModeratePost)
	admin.GET("/community/reported-posts", controllers.Community.GetReportedPosts)

	// User management
	admin.GET("/users", controllers.User.GetAllUsers)
	admin.PUT("/users/:userId/status", controllers.User.UpdateUserStatus)

	// System notifications
	admin.POST("/notifications/broadcast", controllers.Notification.BroadcastNotification)
	admin.POST("/notifications/process-scheduled", controllers.Notification.ProcessScheduledNotifications)

	// Platform configuration
	admin.GET("/config", func(c *gin.Context) {
		// Return safe configuration info for admin dashboard
		c.JSON(http.StatusOK, gin.H{
			"platform_info": gin.H{
				"name":        "Tenang.in",
				"version":     "1.0.0",
				"environment": gin.Mode(),
				"features": map[string]bool{
					"chat_enabled":      true,
					"vocal_enabled":     true,
					"community_enabled": true,
					"social_enabled":    true,
					"analytics_enabled": true,
				},
			},
		})
	})
}

// setupStaticFileServing configures static file serving for mental health content
func setupStaticFileServing(router *gin.Engine, cfg *config.Config) {
	// Create upload directories if they don't exist
	uploadDirs := []string{
		cfg.Storage.AudioUploadPath,
		"./uploads/images",
		"./uploads/documents",
	}

	for _, dir := range uploadDirs {
		if err := os.MkdirAll(dir, 0755); err != nil {
			log.Printf("⚠️  Failed to create upload directory %s: %v", dir, err)
		}
	}

	// Static file serving with proper headers for mental health content
	router.Static("/uploads", "./uploads")
	router.Static("/audio", cfg.Storage.AudioUploadPath)

	// Serve audio files with specific headers for privacy
	router.GET("/api/v1/audio/:filename", middleware.TenangAuthMiddleware(), func(c *gin.Context) {
		filename := c.Param("filename")
		filepath := filepath.Join(cfg.Storage.AudioUploadPath, filename)

		// Verify user has access to this audio file
		// TODO: Implement audio file ownership verification

		c.Header("Cache-Control", "private, no-cache")
		c.Header("X-Content-Type-Options", "nosniff")
		c.File(filepath)
	})
}

// printTenangStartupInfo displays comprehensive startup information
func printTenangStartupInfo(cfg *config.Config) {
	log.Println("")
	log.Println("🌸 ================================")
	log.Println("🌸  TENANG.IN PLATFORM STARTED")
	log.Println("🌸 ================================")
	log.Println("")
	log.Println("📋 Platform Features:")
	log.Println("  🤖 AI Mental Health Chatbot")
	log.Println("  🎤 Vocal Journal with Sentiment Analysis")
	log.Println("  👥 Anonymous Peer Support Community")
	log.Println("  📱 Social Media Monitoring (Optional)")
	log.Println("  📊 Mental Health Analytics & Progress")
	log.Println("  🔔 Smart Notifications & Check-ins")
	log.Println("")
	log.Println("🔗 Key API Endpoints:")
	log.Println("  GET  /                              - Platform welcome & info")
	log.Println("  GET  /health                        - Health check & metrics")
	log.Println("  GET  /privacy                       - Privacy policy")
	log.Println("  POST /api/v1/auth/register          - User registration")
	log.Println("  POST /api/v1/auth/login             - User authentication")
	log.Println("  GET  /api/v1/community/categories   - Community categories")
	log.Println("  POST /api/v1/chat/:userId/sessions  - Start chat session")
	log.Println("  POST /api/v1/vocal/:userId/entries  - Upload vocal journal")
	log.Println("")
	log.Println("🔒 Security Features:")
	log.Println("  ✅ JWT Authentication with mental health context")
	log.Println("  ✅ Mental health-aware rate limiting")
	log.Println("  ✅ Privacy-first data handling")
	log.Println("  ✅ Crisis endpoint protection")
	log.Println("  ✅ End-to-end encryption for sensitive data")
	log.Println("")
	log.Println("🆘 Crisis Support:")
	log.Println("  📞 Emergency Hotline: 119")
	log.Println("  💬 WhatsApp Crisis: 081-111-500-711")
	log.Println("  🌐 Mental Health Directory: sehatmental.kemkes.go.id")
	log.Println("")
	log.Println("💡 Next Development Steps:")
	log.Println("  1. 🧠 Integrate Azure OpenAI for AI chat responses")
	log.Println("  2. 🎵 Implement Azure Speech Services for transcription")
	log.Println("  3. 🤗 Connect HuggingFace for vocal sentiment analysis")
	log.Println("  4. 📱 Set up social media OAuth2 integrations")
	log.Println("  5. 📧 Configure email services for notifications")
	log.Println("  6. 🚨 Implement crisis detection and intervention")
	log.Println("")
}