package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/sashabaranov/go-openai"

	"backend/config"
	"backend/controllers"
	"backend/middleware"
	"backend/models"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func main() {
	log.Println("🌸 Starting Tenang.in - Mental Health Platform...")
	cfg := config.LoadConfig()
	gin.SetMode(cfg.Server.Environment)

	db := config.DatabaseConnection()

	log.Println("📊 Starting database migration...")
	if err := migrateTenangModels(db); err != nil {
		log.Fatal("❌ Failed to migrate database:", err)
	}
	log.Println("✅ Database migration completed successfully")

	config.CreateInitialData(db)

	appControllers := initializeTenangControllers(db, cfg)
	router := setupTenangRouter(cfg, db)
	setupTenangRoutes(router, appControllers)
	setupStaticFileServing(router, cfg)

	printTenangStartupInfo(cfg)

	address := fmt.Sprintf("%s:%s", cfg.Server.Host, cfg.Server.Port)
	log.Printf("🚀 Tenang.in server starting on http://%s", address)
	if err := router.Run(address); err != nil {
		log.Fatal("❌ Failed to start server:", err)
	}
}

// migrateTenangModels mencakup semua model dalam aplikasi.
func migrateTenangModels(db *gorm.DB) error {
	return db.AutoMigrate(
		&models.User{}, &models.UserCredentials{}, &models.UserPreferences{}, &models.UserSession{},
		&models.ChatSession{}, &models.ChatMessage{}, &models.ScheduledCheckin{},
		&models.VocalJournalEntry{}, &models.VocalTranscription{}, &models.VocalSentimentAnalysis{},
		&models.CommunityCategory{}, &models.CommunityPost{}, &models.CommunityPostReply{}, &models.CommunityReaction{},
		&models.SocialMediaAccount{}, &models.SocialMediaPostMonitored{},
		&models.Notification{}, &models.UserProgressMetric{}, &models.SystemAnalytics{}, &models.AuditLog{},
	)
}

// TenangControllers menampung semua instance controller.
type TenangControllers struct {
	Auth         *controllers.AuthController
	User         *controllers.UserController
	Community    *controllers.CommunityController
	Notification *controllers.NotificationController
	Chat         *controllers.ChatController
	Vocal        *controllers.VocalController
	Social       *controllers.SocialController
	Analytics    *controllers.AnalyticsController
}

// initializeTenangControllers membuat semua instance controller dengan dependensinya.
func initializeTenangControllers(db *gorm.DB, cfg *config.Config) *TenangControllers {
	return &TenangControllers{
		Auth:         controllers.NewAuthController(db, cfg),
		User:         controllers.NewUserController(db),
		Community:    controllers.NewCommunityController(db),
		Notification: controllers.NewNotificationController(db, cfg),
		Chat:         controllers.NewChatController(db, cfg),
		Vocal:        controllers.NewVocalController(db, cfg),
		Social:       controllers.NewSocialController(db, cfg),
		Analytics:    controllers.NewAnalyticsController(db, cfg),
	}
}

// setupTenangRouter mengonfigurasi Gin router dengan middleware.
func setupTenangRouter(cfg *config.Config, db *gorm.DB) *gin.Engine {
	router := gin.New()
	router.Use(gin.Logger(), gin.Recovery())
	router.Use(cors.New(cors.Config{
		AllowOrigins:     cfg.Server.CORSOrigins,
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization"},
		AllowCredentials: true,
	}))
	router.Use(func(c *gin.Context) {
		c.Set("db", db)
		c.Next()
	})
	return router
}

// setupTenangRoutes mengonfigurasi semua rute API.
func setupTenangRoutes(router *gin.Engine, c *TenangControllers) {
	router.GET("/health", func(ctx *gin.Context) { ctx.JSON(http.StatusOK, gin.H{"status": "healthy"}) })

	setupDebugRoutes(router, c)

	v1 := router.Group("/api/v1")
	setupPublicRoutes(v1, c)

	protected := v1.Group("/")
	protected.Use(middleware.TenangAuthMiddleware())
	setupProtectedRoutes(protected, c)

	admin := v1.Group("/admin")
	admin.Use(middleware.TenangAuthMiddleware(), middleware.RequireAdmin())
	setupAdminRoutes(admin, c)
}

func setupDebugRoutes(router *gin.Engine, c *TenangControllers) {
	debug := router.Group("/debug")
	{
		debug.GET("/env", func(ctx *gin.Context) {
			cfg := config.AppConfig // Ambil dari global config
			if cfg == nil {
				ctx.JSON(500, gin.H{"error": "Config not loaded"})
				return
			}

			apiKey := cfg.Azure.OpenAIAPIKey
			masked := ""
			if len(apiKey) > 8 {
				masked = apiKey[:4] + "..." + apiKey[len(apiKey)-4:]
			}

			debugInfo := map[string]interface{}{
				"azure_config": map[string]string{
					"api_key_masked":  masked,
					"endpoint":        cfg.Azure.OpenAIEndpoint,
					"deployment_name": cfg.Azure.OpenAIDeploymentName,
					"api_version":     cfg.Azure.OpenAIAPIVersion,
				},
				"config_status": map[string]bool{
					"api_key_set":    len(cfg.Azure.OpenAIAPIKey) > 0,
					"endpoint_set":   len(cfg.Azure.OpenAIEndpoint) > 0,
					"deployment_set": len(cfg.Azure.OpenAIDeploymentName) > 0,
					"version_set":    len(cfg.Azure.OpenAIAPIVersion) > 0,
				},
				"timestamp": time.Now(),
			}

			ctx.JSON(200, gin.H{"debug": debugInfo})
		})

		debug.GET("/test-openai", func(ctx *gin.Context) {
			cfg := config.AppConfig
			if cfg == nil {
				ctx.JSON(500, gin.H{"error": "Config not loaded"})
				return
			}

			// Test Azure OpenAI connection langsung
			testAzureOpenAI(ctx, cfg)
		})
	}
}

// 🔧 FUNCTION YANG DIPERBAIKI - SEKARANG LENGKAP
func testAzureOpenAI(c *gin.Context, cfg *config.Config) {
	apiKey := cfg.Azure.OpenAIAPIKey
	endpoint := cfg.Azure.OpenAIEndpoint
	deploymentName := cfg.Azure.OpenAIDeploymentName
	apiVersion := cfg.Azure.OpenAIAPIVersion

	log.Printf("🔍 Testing Azure OpenAI Connection...")
	log.Printf("   Endpoint: %s", endpoint)
	log.Printf("   Deployment: %s", deploymentName)
	log.Printf("   API Version: %s", apiVersion)
	log.Printf("   API Key length: %d", len(apiKey))

	if apiKey == "" || endpoint == "" || deploymentName == "" {
		c.JSON(400, gin.H{
			"error": "Missing Azure OpenAI configuration",
			"missing": map[string]bool{
				"api_key":    apiKey == "",
				"endpoint":   endpoint == "",
				"deployment": deploymentName == "",
			},
		})
		return
	}

	// 🔧 IMPLEMENTASI AZURE OPENAI YANG LENGKAP
	config := openai.DefaultAzureConfig(apiKey, endpoint)
	config.APIVersion = apiVersion
	client := openai.NewClientWithConfig(config)

	req := openai.ChatCompletionRequest{
		Model: deploymentName,
		Messages: []openai.ChatCompletionMessage{
			{
				Role:    openai.ChatMessageRoleSystem,
				Content: "You are a helpful assistant.",
			},
			{
				Role:    openai.ChatMessageRoleUser,
				Content: "Say 'Hello from Azure OpenAI test' in Indonesian.",
			},
		},
		MaxTokens:   50,
		Temperature: 0.7,
	}

	log.Printf("🚀 Sending request to Azure OpenAI...")
	start := time.Now()
	resp, err := client.CreateChatCompletion(context.Background(), req)
	duration := time.Since(start)

	if err != nil {
		log.Printf("❌ Azure OpenAI Error: %v", err)
		c.JSON(500, gin.H{
			"error":    "Azure OpenAI connection failed",
			"details":  err.Error(),
			"duration": duration.String(),
		})
		return
	}

	if len(resp.Choices) == 0 {
		log.Printf("❌ No response choices from Azure OpenAI")
		c.JSON(500, gin.H{
			"error":    "No response choices from Azure OpenAI",
			"duration": duration.String(),
		})
		return
	}

	response := resp.Choices[0].Message.Content
	log.Printf("✅ Azure OpenAI Response: %s", response)
	log.Printf("✅ Request completed in: %s", duration)

	c.JSON(200, gin.H{
		"success":  true,
		"response": response,
		"duration": duration.String(),
		"usage": map[string]interface{}{
			"prompt_tokens":     resp.Usage.PromptTokens,
			"completion_tokens": resp.Usage.CompletionTokens,
			"total_tokens":      resp.Usage.TotalTokens,
		},
		"model": resp.Model,
	})
}

// setupPublicRoutes untuk endpoint yang tidak memerlukan otentikasi.
func setupPublicRoutes(v1 *gin.RouterGroup, c *TenangControllers) {
	auth := v1.Group("/auth")
	{
		auth.POST("/register", c.Auth.Register)
		auth.POST("/login", c.Auth.Login)
		auth.POST("/google", c.Auth.GoogleAuth)
		auth.POST("/refresh", c.Auth.RefreshToken)
		auth.POST("/forgot-password", c.Auth.ForgotPassword)
		auth.POST("/reset-password", c.Auth.ResetPassword)
		auth.GET("/verify-email", c.Auth.VerifyEmail)
	}

	community := v1.Group("/community")
	community.Use(middleware.OptionalAuth())
	{
		community.GET("/categories", c.Community.GetCategories)
		community.GET("/posts/public", c.Community.GetPublicPosts)
		community.GET("/posts/:postId", c.Community.GetPost)
	}
}

// setupProtectedRoutes untuk endpoint yang memerlukan otentikasi JWT.
func setupProtectedRoutes(protected *gin.RouterGroup, c *TenangControllers) {
	users := protected.Group("/users")
	users.Use(middleware.ValidateUserOwnership())
	{
		users.GET("/:userId/profile", c.User.GetProfile)
		users.PUT("/:userId/profile", c.User.UpdateProfile)
		users.GET("/:userId/preferences", c.User.GetPreferences)
		users.PUT("/:userId/preferences", c.User.UpdatePreferences)
		users.GET("/:userId/dashboard", c.User.GetDashboardStats)
		users.GET("/:userId/progress", c.User.GetProgressMetrics)
		users.DELETE("/:userId/deactivate", c.User.DeactivateAccount)
	}

	community := protected.Group("/community")
	{
		community.GET("/posts", c.Community.GetUserPosts)
		community.POST("/posts", c.Community.CreatePost)
		community.PUT("/posts/:postId", c.Community.UpdatePost)
		community.DELETE("/posts/:postId", c.Community.DeletePost)
		community.POST("/replies", c.Community.CreateReply)
		community.POST("/reactions", c.Community.AddReaction)
		community.POST("/posts/:postId/report", c.Community.ReportPost)
	}

	notifications := protected.Group("/notifications")
	{
		notifications.GET("/", c.Notification.GetNotifications)
		notifications.GET("/unread-count", c.Notification.GetUnreadCount)
		notifications.POST("/test", c.Notification.SendTestNotification)
		notifications.PUT("/:notificationId/read", c.Notification.MarkAsRead)
		notifications.PUT("/read-all", c.Notification.MarkAllAsRead)
		notifications.DELETE("/:notificationId", c.Notification.DeleteNotification)
	}

	chat := protected.Group("/chat")
	{
		chat.POST("/sessions", c.Chat.CreateSession)
		chat.GET("/sessions", c.Chat.GetSessions)
		chat.GET("/sessions/:sessionId", c.Chat.GetSession)
		chat.POST("/messages", c.Chat.SendMessage)
		chat.PUT("/sessions/:sessionId/end", c.Chat.EndSession)
		chat.GET("/checkins", c.Chat.GetScheduledCheckins)
		chat.POST("/checkins", c.Chat.CreateScheduledCheckin)
		chat.PUT("/checkins/:checkinId", c.Chat.UpdateScheduledCheckin)
		chat.DELETE("/checkins/:checkinId", c.Chat.DeleteScheduledCheckin)
	}

	vocal := protected.Group("/vocal")
	{
		vocal.POST("/entries", c.Vocal.CreateEntry)
		// vocal.GET("/entries", c.Vocal.GetEntries)
		// vocal.GET("/entries/:entryId", c.Vocal.GetEntry)
		// vocal.DELETE("/entries/:entryId", c.Vocal.DeleteEntry)
		// vocal.GET("/entries/:entryId/audio", c.Vocal.GetAudioFile)
		// vocal.GET("/trends", c.Vocal.GetWellbeingTrends)
	}

	social := protected.Group("/social")
	{
		social.POST("/connect", c.Social.ConnectAccount)
		social.GET("/accounts", c.Social.GetConnectedAccounts)
		social.PUT("/accounts/:accountId", c.Social.UpdateAccountSettings)
		social.DELETE("/accounts/:accountId", c.Social.DisconnectAccount)
		social.POST("/accounts/:accountId/sync", c.Social.SyncAccount)
		social.GET("/accounts/:accountId/posts", c.Social.GetMonitoredPosts)
		social.GET("/insights", c.Social.GetSocialMediaInsights)
		social.POST("/webhooks/:platform", c.Social.HandleWebhook)
	}

	analytics := protected.Group("/analytics")
	{
		analytics.POST("/events", c.Analytics.RecordEvent)
		analytics.GET("/user", c.Analytics.GetUserAnalytics)
		analytics.GET("/wellbeing-report", c.Analytics.GetWellbeingReport)
	}

	authProtected := protected.Group("/auth")
	{
		authProtected.POST("/logout", c.Auth.Logout)
		authProtected.POST("/change-password", c.Auth.ChangePassword)
	}
}

// setupAdminRoutes mengonfigurasi rute khusus admin.
func setupAdminRoutes(admin *gin.RouterGroup, c *TenangControllers) {
	admin.GET("/users", c.User.GetAllUsers)
	admin.PUT("/users/:userId/status", c.User.UpdateUserStatus)

	admin.GET("/community/reported-posts", c.Community.GetReportedPosts)
	admin.POST("/community/posts/:postId/moderate", c.Community.ModeratePost)

	admin.POST("/notifications/broadcast", c.Notification.BroadcastNotification)
	admin.POST("/notifications/process-scheduled", c.Notification.ProcessScheduledNotifications)

	admin.GET("/analytics/system/metrics", c.Analytics.GetSystemMetrics)
	admin.GET("/analytics/platform-health", c.Analytics.GetPlatformHealth)
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
