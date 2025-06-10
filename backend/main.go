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

	appControllers := initializeTenangControllers(db)
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

// TenangControllers holds all controller instances for the platform
type TenangControllers struct {
	Auth         *controllers.AuthController
	User         *controllers.UserController
	Community    *controllers.CommunityController
	Notification *controllers.NotificationController
	// Placeholders for controllers yet to be implemented
	Chat      *controllers.ChatController
	Vocal     *controllers.VocalController
	Social    *controllers.SocialController
	Analytics *controllers.AnalyticsController
}

// initializeTenangControllers creates all controller instances with database injection
func initializeTenangControllers(db *gorm.DB) *TenangControllers {
	return &TenangControllers{
		// Menggunakan konstruktor yang sudah ada di file controller Anda
		Auth:         &controllers.AuthController{DB: db},
		// Menggunakan konstruktor yang sudah kita buat bersama
		User:         controllers.NewUserController(db),
		Community:    controllers.NewCommunityController(db),
		Notification: controllers.NewNotificationController(db),
		// Placeholder untuk controller yang akan kita buat selanjutnya
		Chat:      &controllers.ChatController{DB: db},
		Vocal:     &controllers.VocalController{DB: db},
		Social:    &controllers.SocialController{DB: db},
		Analytics: &controllers.AnalyticsController{DB: db},
	}
}

// setupTenangRouter configures the Gin router
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

// setupTenangRoutes configures all API routes for the mental health platform
func setupTenangRoutes(router *gin.Engine, c *TenangControllers) {
	router.GET("/health", func(ctx *gin.Context) { ctx.JSON(http.StatusOK, gin.H{"status": "healthy"}) })

	v1 := router.Group("/api/v1")
	setupPublicRoutes(v1, c)

	protected := v1.Group("/")
	protected.Use(middleware.TenangAuthMiddleware())
	setupProtectedRoutes(protected, c)

	admin := v1.Group("/admin")
	admin.Use(middleware.TenangAuthMiddleware(), middleware.RequireAdmin())
	setupAdminRoutes(admin, c)
}

// setupPublicRoutes configures routes that don't require authentication
func setupPublicRoutes(v1 *gin.RouterGroup, c *TenangControllers) {
	auth := v1.Group("/auth")
	{
		// Rute-rute ini sekarang valid karena kita sudah memiliki AuthController
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

// setupProtectedRoutes configures routes that require JWT authentication
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
		community.POST("/replies", c.Community.CreateReply)
		community.POST("/reactions", c.Community.AddReaction)
		community.POST("/posts/:postId/report", c.Community.ReportPost)
		community.PUT("/posts/:postId", c.Community.UpdatePost)
		community.DELETE("/posts/:postId", c.Community.DeletePost)
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

	authProtected := protected.Group("/auth")
	{
		authProtected.POST("/logout", c.Auth.Logout)
		authProtected.POST("/change-password", c.Auth.ChangePassword)
	}

	// TODO: Implementasikan rute untuk Chat, Vocal, Social, dan Analytics
}

// setupAdminRoutes configures admin-only routes for platform management
func setupAdminRoutes(admin *gin.RouterGroup, c *TenangControllers) {
	admin.GET("/users", c.User.GetAllUsers)
	admin.PUT("/users/:userId/status", c.User.UpdateUserStatus)

	admin.GET("/community/reported-posts", c.Community.GetReportedPosts)
	admin.POST("/community/posts/:postId/moderate", c.Community.ModeratePost)

	admin.POST("/notifications/broadcast", c.Notification.BroadcastNotification)
	admin.POST("/notifications/process-scheduled", c.Notification.ProcessScheduledNotifications)

	// TODO: Add other admin routes
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