// package main

// import (
// 	// "backend/config"
// 	"backend/controllers"
// 	"backend/models"
// 	"log"
// 	"net/http"

// 	"github.com/gin-gonic/gin"
// )

// func main() {
// 	// Database connection
// 	db := config.DatabaseConnection()

// 	// Auto migrate all models
// 	log.Println("Starting database migration...")
// 	err := db.AutoMigrate(
// 		// User management models
// 		&models.User{},
// 		&models.UserCredentials{},
// 		&models.UserPreferences{},
// 		&models.UserSession{},

// 		// Chat & conversation models
// 		&models.ChatSession{},
// 		&models.ChatMessage{},
// 		&models.ScheduledCheckin{},

// 		// Vocal journal models
// 		&models.VocalJournalEntry{},
// 		&models.VocalTranscription{},
// 		&models.VocalSentimentAnalysis{},

// 		// Community models
// 		&models.CommunityCategory{},
// 		&models.CommunityPost{},
// 		&models.CommunityPostReply{},
// 		&models.CommunityReaction{},

// 		// Social media models
// 		&models.SocialMediaAccount{},
// 		&models.SocialMediaPostMonitored{},

// 		// Support models
// 		&models.Notification{},
// 		&models.UserProgressMetric{},
// 		&models.SystemAnalytics{},
// 		&models.AuditLog{},
// 	)

// 	if err != nil {
// 		log.Fatal("Failed to migrate database:", err)
// 	}

// 	log.Println("Database migration completed successfully")

// 	// Create initial data
// 	config.CreateInitialData(db)

// 	// Initialize Controllers
// 	authController := controllers.AuthController{DB: db}
// 	userController := controllers.UserController{DB: db}
// 	chatController := controllers.ChatController{DB: db}
// 	vocalController := controllers.VocalController{DB: db}
// 	communityController := controllers.CommunityController{DB: db}
// 	notificationController := controllers.NotificationController{DB: db}
// 	socialController := controllers.SocialController{DB: db}
// 	analyticsController := controllers.AnalyticsController{DB: db}

// 	// Initialize Gin router
// 	router := gin.Default()

// 	// Basic health check endpoint
// 	router.GET("/", func(c *gin.Context) {
// 		c.JSON(http.StatusOK, gin.H{
// 			"message": "Welcome to Tenang.in API",
// 			"status":  "healthy",
// 			"version": "1.0.0",
// 		})
// 	})

// 	// Health check endpoint
// 	router.GET("/health", func(c *gin.Context) {
// 		c.JSON(http.StatusOK, gin.H{
// 			"status":   "healthy",
// 			"database": "connected",
// 		})
// 	})

// 	// API route groups
// 	api := router.Group("/api/v1")
// 	{
// 		// Authentication routes
// 		auth := api.Group("/auth")
// 		{
// 			auth.POST("/register", authController.Register)
// 			auth.POST("/login", authController.Login)
// 			auth.POST("/logout", authController.Logout)
// 			auth.POST("/forgot-password", authController.ForgotPassword)
// 			auth.GET("/verify-email", authController.VerifyEmail)
// 			auth.PUT("/change-password/:userId", authController.ChangePassword) // TODO: Use JWT middleware
// 		}

// 		// User profile routes
// 		user := api.Group("/users")
// 		{
// 			user.GET("/:userId/profile", userController.GetProfile)
// 			user.PUT("/:userId/profile", userController.UpdateProfile)
// 			user.GET("/:userId/preferences", userController.GetPreferences)
// 			user.PUT("/:userId/preferences", userController.UpdatePreferences)
// 			user.GET("/:userId/dashboard", userController.GetDashboardStats)
// 			user.GET("/:userId/progress", userController.GetProgressMetrics)
// 			user.DELETE("/:userId/deactivate", userController.DeactivateAccount)
// 		}

// 		// Chat routes
// 		chat := api.Group("/chat")
// 		{
// 			chat.POST("/:userId/sessions", chatController.CreateSession)
// 			chat.GET("/:userId/sessions", chatController.GetSessions)
// 			chat.GET("/sessions/:sessionId", chatController.GetSession)
// 			chat.POST("/messages", chatController.SendMessage)
// 			chat.PUT("/sessions/:sessionId/end", chatController.EndSession)

// 			// Scheduled check-ins
// 			chat.GET("/:userId/checkins", chatController.GetScheduledCheckins)
// 			chat.POST("/:userId/checkins", chatController.CreateScheduledCheckin)
// 			chat.PUT("/checkins/:checkinId", chatController.UpdateScheduledCheckin)
// 			chat.DELETE("/checkins/:checkinId", chatController.DeleteScheduledCheckin)
// 		}

// 		// Vocal journal routes
// 		vocal := api.Group("/vocal")
// 		{
// 			vocal.POST("/:userId/entries", vocalController.CreateEntry)
// 			vocal.GET("/:userId/entries", vocalController.GetEntries)
// 			vocal.GET("/entries/:entryId", vocalController.GetEntry)
// 			vocal.PUT("/entries/:entryId", vocalController.UpdateEntry)
// 			vocal.DELETE("/entries/:entryId", vocalController.DeleteEntry)
// 			vocal.GET("/entries/:entryId/transcription", vocalController.GetTranscription)
// 			vocal.GET("/entries/:entryId/analysis", vocalController.GetSentimentAnalysis)
// 			vocal.GET("/:userId/trends", vocalController.GetWellbeingTrends)
// 			vocal.GET("/entries/:entryId/audio", vocalController.GetAudioFile)
// 		}

// 		// Community routes
// 		community := api.Group("/community")
// 		{
// 			community.GET("/categories", communityController.GetCategories)
// 			community.GET("/posts", communityController.GetPosts)
// 			community.GET("/posts/:postId", communityController.GetPost)
// 			community.POST("/:userId/posts", communityController.CreatePost)
// 			community.PUT("/:userId/posts/:postId", communityController.UpdatePost)
// 			community.DELETE("/:userId/posts/:postId", communityController.DeletePost)
// 			community.GET("/:userId/posts", communityController.GetUserPosts)

// 			// Replies and reactions
// 			community.POST("/:userId/replies", communityController.CreateReply)
// 			community.POST("/:userId/reactions", communityController.AddReaction)
// 		}

// 		// Notification routes
// 		notifications := api.Group("/notifications")
// 		{
// 			notifications.GET("/:userId", notificationController.GetNotifications)
// 			notifications.PUT("/:userId/:notificationId/read", notificationController.MarkAsRead)
// 			notifications.PUT("/:userId/read-all", notificationController.MarkAllAsRead)
// 			notifications.DELETE("/:userId/:notificationId", notificationController.DeleteNotification)
// 			notifications.GET("/:userId/settings", notificationController.GetNotificationSettings)
// 			notifications.PUT("/:userId/settings", notificationController.UpdateNotificationSettings)
// 			notifications.GET("/:userId/stats", notificationController.GetNotificationStats)

// 			// Admin routes for creating notifications
// 			notifications.POST("/create", notificationController.CreateNotification)                       // TODO: Add admin middleware
// 			notifications.POST("/process-scheduled", notificationController.ProcessScheduledNotifications) // TODO: Add admin middleware
// 		}

// 		// Social media routes
// 		social := api.Group("/social")
// 		{
// 			social.POST("/:userId/connect", socialController.ConnectAccount)
// 			social.GET("/:userId/accounts", socialController.GetConnectedAccounts)
// 			social.PUT("/:userId/accounts/:accountId", socialController.UpdateAccountSettings)
// 			social.DELETE("/:userId/accounts/:accountId", socialController.DisconnectAccount)
// 			social.GET("/accounts/:accountId/posts", socialController.GetMonitoredPosts)
// 			social.POST("/:userId/accounts/:accountId/sync", socialController.SyncAccount)
// 			social.GET("/:userId/insights", socialController.GetSocialMediaInsights)

// 			// Webhook endpoints for platform notifications
// 			social.POST("/webhook/:platform", socialController.HandleWebhook)
// 		}

// 		// Analytics routes
// 		analytics := api.Group("/analytics")
// 		{
// 			analytics.POST("/events", analyticsController.RecordEvent)
// 			analytics.GET("/:userId/user", analyticsController.GetUserAnalytics)
// 			analytics.GET("/:userId/wellbeing-report", analyticsController.GetWellbeingReport)

// 			// Admin analytics routes (TODO: Add admin middleware)
// 			analytics.GET("/system/metrics", analyticsController.GetSystemMetrics)
// 			analytics.GET("/system/health", analyticsController.GetPlatformHealth)
// 		}
// 	}

// 	// Static file serving for uploaded content
// 	router.Static("/uploads", "./uploads")
// 	router.Static("/audio", "./audio")

// 	// Start server
// 	log.Println("🚀 Starting Tenang.in API server on port 8080...")
// 	log.Println("📋 Available endpoints:")
// 	log.Println("  GET  /                    - Welcome message")
// 	log.Println("  GET  /health              - Health check")
// 	log.Println("  POST /api/v1/auth/*       - Authentication endpoints")
// 	log.Println("  *    /api/v1/users/*      - User management endpoints")
// 	log.Println("  *    /api/v1/chat/*       - Chat and messaging endpoints")
// 	log.Println("  *    /api/v1/vocal/*      - Vocal journal endpoints")
// 	log.Println("  *    /api/v1/community/*  - Community forum endpoints")
// 	log.Println("  *    /api/v1/notifications/* - Notification endpoints")
// 	log.Println("  *    /api/v1/social/*     - Social media integration endpoints")
// 	log.Println("  *    /api/v1/analytics/*  - Analytics and reporting endpoints")
// 	log.Println("")
// 	log.Println("📁 Static file endpoints:")
// 	log.Println("  GET  /uploads/*           - General uploaded files")
// 	log.Println("  GET  /audio/*             - Audio files for vocal journal")
// 	log.Println("")
// 	log.Println("💡 Next steps:")
// 	log.Println("  1. Implement JWT authentication middleware")
// 	log.Println("  2. Add AI service integration for chat and vocal analysis")
// 	log.Println("  3. Set up social media API integrations")
// 	log.Println("  4. Configure notification services (FCM, email)")
// 	log.Println("  5. Add admin authentication for system endpoints")

//		if err := router.Run(":8080"); err != nil {
//			log.Fatal("Failed to start server:", err)
//		}
//	}
package main
