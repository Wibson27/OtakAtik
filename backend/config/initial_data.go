package config

import (
	"backend/models"
	"log"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// CreateInitialData creates essential seed data for the application
func CreateInitialData(db *gorm.DB) {
	log.Println("🌱 Creating initial seed data...")

	// Create community categories
	createCommunityCategories(db)

	// Create admin user (optional, for development)
	createAdminUser(db)

	// Create notification templates
	createNotificationTemplates(db)

	log.Println("✅ Initial seed data created successfully")
}

// stringPtr is a helper function to get a pointer to a string
func stringPtr(s string) *string {
	return &s
}

// createCommunityCategories creates the community forum categories
func createCommunityCategories(db *gorm.DB) {
	categories := []models.CommunityCategory{
		{
			ID:                  uuid.New(),
			CategoryName:        "Mengelola Kecemasan",
			CategoryDescription: stringPtr("Space khusus untuk berbagi pengalaman dan tips mengatasi kecemasan sehari-hari"),
			CategoryColor:       "#6366F1", // Indigo
			IconName:            stringPtr("🧘"),
			IsActive:            true,
			DisplayOrder:        1,
			CreatedAt:           time.Now(),
			UpdatedAt:           time.Now(),
		},
		{
			ID:                  uuid.New(),
			CategoryName:        "Tips Produktivitas & Stress",
			CategoryDescription: stringPtr("Diskusi tentang keseimbangan hidup, manajemen stress, dan tips produktivitas yang sehat"),
			CategoryColor:       "#10B981", // Emerald
			IconName:            stringPtr("⚖️"),
			IsActive:            true,
			DisplayOrder:        2,
			CreatedAt:           time.Now(),
			UpdatedAt:           time.Now(),
		},
		{
			ID:                  uuid.New(),
			CategoryName:        "Cerita Inspiratif",
			CategoryDescription: stringPtr("Berbagi cerita positif, pencapaian, dan momen-momen yang memberikan harapan"),
			CategoryColor:       "#F59E0B", // Amber
			IconName:            stringPtr("✨"),
			IsActive:            true,
			DisplayOrder:        3,
			CreatedAt:           time.Now(),
			UpdatedAt:           time.Now(),
		},
		{
			ID:                  uuid.New(),
			CategoryName:        "Support Group",
			CategoryDescription: stringPtr("Ruang aman untuk saling mendukung dan berbagi pengalaman dalam perjalanan pemulihan"),
			CategoryColor:       "#EF4444", // Red
			IconName:            stringPtr("🤗"),
			IsActive:            true,
			DisplayOrder:        4,
			CreatedAt:           time.Now(),
			UpdatedAt:           time.Now(),
		},
		{
			ID:                  uuid.New(),
			CategoryName:        "Self Care Tips",
			CategoryDescription: stringPtr("Tips praktis untuk self-care, mindfulness, dan aktivitas yang membantu kesehatan mental"),
			CategoryColor:       "#8B5CF6", // Violet
			IconName:            stringPtr("💆"),
			IsActive:            true,
			DisplayOrder:        5,
			CreatedAt:           time.Now(),
			UpdatedAt:           time.Now(),
		},
		{
			ID:                  uuid.New(),
			CategoryName:        "Professional Help Experience",
			CategoryDescription: stringPtr("Berbagi pengalaman dengan terapis, psikolog, atau bantuan profesional lainnya"),
			CategoryColor:       "#06B6D4", // Cyan
			IconName:            stringPtr("👩‍⚕️"),
			IsActive:            true,
			DisplayOrder:        6,
			CreatedAt:           time.Now(),
			UpdatedAt:           time.Now(),
		},
	}

	for _, category := range categories {
		var existingCategory models.CommunityCategory
		result := db.Where("category_name = ?", category.CategoryName).First(&existingCategory)

		if result.Error == gorm.ErrRecordNotFound {
			if err := db.Create(&category).Error; err != nil {
				log.Printf("❌ Failed to create category '%s': %v", category.CategoryName, err)
			} else {
				log.Printf("✅ Created community category: %s", category.CategoryName)
			}
		} else {
			log.Printf("⚠️  Category '%s' already exists, skipping", category.CategoryName)
		}
	}
}

// createAdminUser creates a default admin user for development
func createAdminUser(db *gorm.DB) {
	// Check if admin user already exists
	var existingUser models.User
	result := db.Where("email = ?", "admin@tenang.in").First(&existingUser)

	if result.Error == gorm.ErrRecordNotFound {
		// Create admin user
		adminID := uuid.New()
		now := time.Now()

		// Hash password
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
		if err != nil {
			log.Printf("❌ Failed to hash admin password: %v", err)
			return
		}

		// Create user
		adminUser := models.User{
			ID:              adminID,
			Email:           "admin@tenang.in",
			FullName:        stringPtr("Admin Tenang"),
			Username:        stringPtr("admin"),
			IsActive:        true,
			EmailVerifiedAt: &now,
			CreatedAt:       time.Now(),
			UpdatedAt:       time.Now(),
		}

		if err := db.Create(&adminUser).Error; err != nil {
			log.Printf("❌ Failed to create admin user: %v", err)
			return
		}

		// Create user credentials
		adminCredentials := models.UserCredentials{
			ID:           uuid.New(),
			UserID:       adminID,
			PasswordHash: string(hashedPassword),
			CreatedAt:    time.Now(),
			UpdatedAt:    time.Now(),
		}

		if err := db.Create(&adminCredentials).Error; err != nil {
			log.Printf("❌ Failed to create admin credentials: %v", err)
			return
		}

		// Create user preferences
		adminPreferences := models.UserPreferences{
			ID:                        uuid.New(),
			UserID:                    adminID,
			NotificationChat:          true,
			NotificationCommunity:     true,
			NotificationSchedule:      "[]", // Empty JSON array
			CommunityAnonymousDefault: false,
			SocialMediaMonitoring:     false,
			CreatedAt:                 time.Now(),
			UpdatedAt:                 time.Now(),
		}

		if err := db.Create(&adminPreferences).Error; err != nil {
			log.Printf("❌ Failed to create admin preferences: %v", err)
			return
		}

		log.Println("✅ Created admin user (admin@tenang.in / admin123)")
	} else {
		log.Println("⚠️  Admin user already exists, skipping")
	}
}

// createNotificationTemplates creates default notification templates
func createNotificationTemplates(db *gorm.DB) {
	// Note: This would require a NotificationTemplate model
	// For now, we'll skip this and implement later when needed
	log.Println("📝 Notification templates will be created when NotificationTemplate model is implemented")
}

// CreateSampleData creates sample data for development/testing (optional)
func CreateSampleData(db *gorm.DB) {
	log.Println("🧪 Creating sample data for development...")

	// Create sample users for testing
	createSampleUsers(db)

	// Create sample posts
	createSamplePosts(db)

	log.Println("✅ Sample data created successfully")
}

// createSampleUsers creates sample users for development
func createSampleUsers(db *gorm.DB) {
	sampleUsers := []struct {
		Email    string
		FullName string
		Username string
	}{
		{"alice@example.com", "Alice Johnson", "alice_j"},
		{"bob@example.com", "Bob Smith", "bob_smith"},
		{"clara@example.com", "Clara Rodriguez", "clara_r"},
	}

	for _, userData := range sampleUsers {
		var existingUser models.User
		result := db.Where("email = ?", userData.Email).First(&existingUser)

		if result.Error == gorm.ErrRecordNotFound {
			userID := uuid.New()
			now := time.Now()

			// Hash password
			hashedPassword, err := bcrypt.GenerateFromPassword([]byte("password123"), bcrypt.DefaultCost)
			if err != nil {
				log.Printf("❌ Failed to hash password for %s: %v", userData.Email, err)
				continue
			}

			// Create user
			user := models.User{
				ID:              userID,
				Email:           userData.Email,
				FullName:        stringPtr(userData.FullName),
				Username:        stringPtr(userData.Username),
				IsActive:        true,
				EmailVerifiedAt: &now,
				CreatedAt:       time.Now(),
				UpdatedAt:       time.Now(),
			}

			if err := db.Create(&user).Error; err != nil {
				log.Printf("❌ Failed to create user %s: %v", userData.Email, err)
				continue
			}

			// Create credentials
			credentials := models.UserCredentials{
				ID:           uuid.New(),
				UserID:       userID,
				PasswordHash: string(hashedPassword),
				CreatedAt:    time.Now(),
				UpdatedAt:    time.Now(),
			}

			if err := db.Create(&credentials).Error; err != nil {
				log.Printf("❌ Failed to create credentials for %s: %v", userData.Email, err)
				continue
			}

			log.Printf("✅ Created sample user: %s", userData.Email)
		}
	}
}

// createSamplePosts creates sample community posts
func createSamplePosts(db *gorm.DB) {
	// Get first category
	var category models.CommunityCategory
	if err := db.First(&category).Error; err != nil {
		log.Printf("❌ No categories found for sample posts: %v", err)
		return
	}

	// Get sample user
	var user models.User
	if err := db.Where("email = ?", "alice@example.com").First(&user).Error; err != nil {
		log.Printf("❌ No sample user found for posts: %v", err)
		return
	}

	samplePosts := []models.CommunityPost{
		{
			ID:                   uuid.New(),
			UserID:               user.ID,
			CategoryID:           category.ID,
			PostTitle:            "Tips Mengatasi Kecemasan di Pagi Hari",
			PostContent:          "Halo semua! Aku mau berbagi tips yang membantu aku mengatasi kecemasan di pagi hari. Pertama, aku selalu mulai dengan breathing exercise selama 5 menit...",
			IsAnonymous:          false,
			AnonymousDisplayName: nil,
			PostStatus:           "published",
			ViewCount:            0,
			CreatedAt:            time.Now(),
			UpdatedAt:            time.Now(),
		},
		{
			ID:                   uuid.New(),
			UserID:               user.ID,
			CategoryID:           category.ID,
			PostTitle:            "Cara Aku Belajar Menerima Diri Sendiri",
			PostContent:          "Journey self-acceptance aku dimulai ketika aku sadar bahwa aku terlalu keras sama diri sendiri. Aku ingin berbagi beberapa hal yang membantu...",
			IsAnonymous:          true,
			AnonymousDisplayName: stringPtr("WiseCat123"),
			PostStatus:           "published",
			ViewCount:            0,
			CreatedAt:            time.Now().Add(-24 * time.Hour),
			UpdatedAt:            time.Now().Add(-24 * time.Hour),
		},
	}

	for _, post := range samplePosts {
		if err := db.Create(&post).Error; err != nil {
			log.Printf("❌ Failed to create sample post: %v", err)
		} else {
			log.Printf("✅ Created sample post: %s", post.PostTitle)
		}
	}
}
