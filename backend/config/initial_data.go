package config

import (
	"log"
	"time"
	"os"

	"backend/models"

	// "github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// stringPtr adalah helper untuk mendapatkan pointer dari string.
func stringPtr(s string) *string {
	return &s
}

// CreateInitialData mengisi database dengan data awal jika belum ada.
// Termasuk data esensial (kategori, admin) dan data sampel untuk pengembangan.
func CreateInitialData(db *gorm.DB) {
	tx := db.Begin()
	if tx.Error != nil {
		log.Printf("ERROR: Failed to begin transaction for initial data: %v", tx.Error)
		return
	}
	defer tx.Rollback() // Akan diabaikan jika tx.Commit() berhasil

	log.Println("🌱 Seeding essential data...")
	createCommunityCategories(tx)
	createAdminUser(tx)

	// Hanya buat data sampel jika kita tidak di lingkungan produksi
	if GIN_MODE := os.Getenv("GIN_MODE"); GIN_MODE != "release" {
		log.Println("🧪 Seeding sample data for development...")
		createSampleUsers(tx)
		createSamplePosts(tx)
	}

	if err := tx.Commit().Error; err != nil {
		log.Printf("ERROR: Failed to commit initial data transaction: %v", err)
	}
}

// createCommunityCategories menggunakan FirstOrCreate untuk membuat kategori hanya jika belum ada.
func createCommunityCategories(tx *gorm.DB) {
	categories := []models.CommunityCategory{
		{CategoryName: "Mengelola Kecemasan", CategoryDescription: stringPtr("Ruang untuk berbagi pengalaman dan tips mengatasi kecemasan."), IconName: stringPtr("🧘")},
		{CategoryName: "Tips Produktivitas & Stres", CategoryDescription: stringPtr("Diskusi tentang keseimbangan hidup dan manajemen stres."), IconName: stringPtr("⚖️")},
		{CategoryName: "Cerita Inspiratif", CategoryDescription: stringPtr("Bagikan cerita positif dan momen yang memberi harapan."), IconName: stringPtr("✨")},
		{CategoryName: "Support Group", CategoryDescription: stringPtr("Ruang aman untuk saling mendukung dalam perjalanan pemulihan."), IconName: stringPtr("🤗")},
		{CategoryName: "Self Care Tips", CategoryDescription: stringPtr("Tips praktis untuk self-care dan mindfulness."), IconName: stringPtr("💆")},
	}

	for i, category := range categories {
		result := tx.FirstOrCreate(&models.CommunityCategory{}, models.CommunityCategory{
			CategoryName:        category.CategoryName,
			CategoryDescription: category.CategoryDescription,
			IconName:            category.IconName,
			DisplayOrder:        i + 1,
			IsActive:            true,
		})
		if result.Error != nil {
			log.Printf("ERROR: Failed to seed category '%s': %v", category.CategoryName, result.Error)
			return
		}
	}
	log.Println("✅ Community categories checked/seeded.")
}

// createAdminUser menggunakan FirstOrCreate untuk memastikan hanya ada satu admin.
func createAdminUser(tx *gorm.DB) {
	adminEmail := "admin@tenang.in"

	var adminUser models.User
	result := tx.FirstOrCreate(&adminUser, models.User{
		Email:           adminEmail,
		FullName:        stringPtr("Admin Tenang"),
		Username:        stringPtr("admin"),
		IsActive:        true,
		EmailVerifiedAt: func() *time.Time { t := time.Now(); return &t }(),
	})

	if result.Error != nil {
		log.Printf("ERROR: Failed to seed admin user: %v", result.Error)
		return
	}

	if result.RowsAffected > 0 {
		hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("superadmin123!"), bcrypt.DefaultCost)
		tx.Create(&models.UserCredentials{UserID: adminUser.ID, PasswordHash: string(hashedPassword)})
		tx.Create(&models.UserPreferences{UserID: adminUser.ID})
		log.Println("✅ Admin user 'admin@tenang.in' created.")
	} else {
		log.Println("👍 Admin user 'admin@tenang.in' already exists.")
	}
}

// createSampleUsers membuat beberapa pengguna sampel untuk pengembangan.
func createSampleUsers(tx *gorm.DB) {
	sampleUsers := []models.User{
		{Email: "alice@example.com", FullName: stringPtr("Alice Johnson"), Username: stringPtr("alice_j")},
		{Email: "bob@example.com", FullName: stringPtr("Bob Smith"), Username: stringPtr("bob_smith")},
	}

	for _, userData := range sampleUsers {
		var existingUser models.User
		result := tx.FirstOrCreate(&existingUser, models.User{
			Email:           userData.Email,
			FullName:        userData.FullName,
			Username:        userData.Username,
			IsActive:        true,
			EmailVerifiedAt: func() *time.Time { t := time.Now(); return &t }(),
		})

		if result.RowsAffected > 0 {
			hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("password123"), bcrypt.DefaultCost)
			tx.Create(&models.UserCredentials{UserID: existingUser.ID, PasswordHash: string(hashedPassword)})
			log.Printf("✅ Sample user '%s' created.", userData.Email)
		}
	}
}

// createSamplePosts membuat beberapa postingan sampel untuk pengembangan.
func createSamplePosts(tx *gorm.DB) {
	var category models.CommunityCategory
	if err := tx.Where("category_name = ?", "Mengelola Kecemasan").First(&category).Error; err != nil {
		log.Println("WARNING: 'Mengelola Kecemasan' category not found, cannot create sample posts.")
		return
	}

	var user models.User
	if err := tx.Where("email = ?", "alice@example.com").First(&user).Error; err != nil {
		log.Println("WARNING: Sample user 'alice@example.com' not found, cannot create sample posts.")
		return
	}

	samplePosts := []models.CommunityPost{
		{PostTitle: "Tips Mengatasi Cemas di Pagi Hari", PostContent: "Halo semua! Aku mau berbagi tips yang membantu aku mengatasi kecemasan di pagi hari..."},
		{PostTitle: "Apakah ada yang pernah merasa seperti ini?", PostContent: "Akhir-akhir ini aku merasa sulit untuk fokus pada pekerjaan. Rasanya pikiranku melayang ke mana-mana..."},
	}

	for _, postData := range samplePosts {
		var existingPost models.CommunityPost
		result := tx.FirstOrCreate(&existingPost, models.CommunityPost{
			UserID:      user.ID,
			CategoryID:  category.ID,
			PostTitle:   postData.PostTitle,
			PostContent: postData.PostContent,
			PostStatus:  "published",
		})

		if result.RowsAffected > 0 {
			log.Printf("✅ Sample post '%s' created.", postData.PostTitle)
		}
	}
}