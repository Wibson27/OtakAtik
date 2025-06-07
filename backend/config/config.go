package config

import (
	"log"
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
)

// Config holds all application configuration
type Config struct {
	// Server Configuration
	Server ServerConfig

	// Database Configuration
	Database DatabaseConfig

	// JWT Configuration
	JWT JWTConfig

	// Azure AI Services
	Azure AzureConfig

	// HuggingFace Configuration
	HuggingFace HuggingFaceConfig

	// Social Media OAuth
	OAuth OAuthConfig

	// Email Configuration
	Email EmailConfig

	// File Storage
	Storage StorageConfig

	// Security
	Security SecurityConfig
}

type ServerConfig struct {
	Port        string
	Host        string
	Environment string
	CORSOrigins []string
}

type JWTConfig struct {
	AccessSecret     string
	RefreshSecret    string
	AccessExpiry     time.Duration
	RefreshExpiry    time.Duration
	EncryptionKey    string // 32-byte key for token encryption
}

type AzureConfig struct {
	OpenAIAPIKey      string
	OpenAIEndpoint    string
	SpeechAPIKey      string
	SpeechRegion      string
	TextAnalyticsKey  string
	TextAnalyticsEndpoint string
	BlobStorageAccount    string
	BlobStorageKey        string
	BlobContainerName     string
}

type HuggingFaceConfig struct {
	APIKey     string
	ModelName  string // e.g., "facebook/wav2vec2-base-960h"
	Endpoint   string
}

type OAuthConfig struct {
	// Instagram
	InstagramClientID     string
	InstagramClientSecret string
	InstagramRedirectURI  string

	// Twitter/X
	TwitterClientID       string
	TwitterClientSecret   string
	TwitterRedirectURI    string

	// Facebook
	FacebookAppID         string
	FacebookAppSecret     string
	FacebookRedirectURI   string

	// TikTok
	TikTokClientKey       string
	TikTokClientSecret    string
	TikTokRedirectURI     string
}

type EmailConfig struct {
	SMTPHost     string
	SMTPPort     int
	SMTPUsername string
	SMTPPassword string
	FromEmail    string
	FromName     string
}

type StorageConfig struct {
	AudioUploadPath   string
	MaxFileSize       int64  // in bytes
	AllowedExtensions []string
}

type SecurityConfig struct {
	EncryptionKey    string // 32-byte key for general encryption
	RateLimitPerMin  int
	MaxLoginAttempts int
	LockoutDuration  time.Duration
}

var AppConfig *Config

// LoadConfig loads all configuration from environment variables
func LoadConfig() *Config {
	// Load .env file if it exists (for development)
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	// Parse durations
	accessExpiry, _ := time.ParseDuration(getEnv("JWT_ACCESS_EXPIRY", "15m"))
	refreshExpiry, _ := time.ParseDuration(getEnv("JWT_REFRESH_EXPIRY", "168h")) // 7 days
	lockoutDuration, _ := time.ParseDuration(getEnv("LOCKOUT_DURATION", "15m"))

	// Parse integers
	smtpPort, _ := strconv.Atoi(getEnv("SMTP_PORT", "587"))
	maxFileSize, _ := strconv.ParseInt(getEnv("MAX_FILE_SIZE", "10485760"), 10, 64) // 10MB
	rateLimitPerMin, _ := strconv.Atoi(getEnv("RATE_LIMIT_PER_MIN", "60"))
	maxLoginAttempts, _ := strconv.Atoi(getEnv("MAX_LOGIN_ATTEMPTS", "5"))

	config := &Config{
		Server: ServerConfig{
			Port:        getEnv("PORT", "8080"),
			Host:        getEnv("HOST", "localhost"),
			Environment: getEnv("GIN_MODE", "debug"),
			CORSOrigins: []string{
				getEnv("FRONTEND_URL", "http://localhost:3000"),
				getEnv("MOBILE_APP_URL", "http://localhost:8081"),
			},
		},

		Database: *LoadDatabaseConfig(),

		JWT: JWTConfig{
			AccessSecret:  getEnvRequired("JWT_ACCESS_SECRET"),
			RefreshSecret: getEnvRequired("JWT_REFRESH_SECRET"),
			AccessExpiry:  accessExpiry,
			RefreshExpiry: refreshExpiry,
			EncryptionKey: getEnvRequired("JWT_ENCRYPTION_KEY"), // Must be 32 bytes
		},

		Azure: AzureConfig{
			OpenAIAPIKey:          getEnvRequired("AZURE_OPENAI_API_KEY"),
			OpenAIEndpoint:        getEnvRequired("AZURE_OPENAI_ENDPOINT"),
			SpeechAPIKey:          getEnvRequired("AZURE_SPEECH_API_KEY"),
			SpeechRegion:          getEnvRequired("AZURE_SPEECH_REGION"),
			TextAnalyticsKey:      getEnvRequired("AZURE_TEXT_ANALYTICS_KEY"),
			TextAnalyticsEndpoint: getEnvRequired("AZURE_TEXT_ANALYTICS_ENDPOINT"),
			BlobStorageAccount:    getEnvRequired("AZURE_BLOB_STORAGE_ACCOUNT"),
			BlobStorageKey:        getEnvRequired("AZURE_BLOB_STORAGE_KEY"),
			BlobContainerName:     getEnv("AZURE_BLOB_CONTAINER", "audio-files"),
		},

		HuggingFace: HuggingFaceConfig{
			APIKey:    getEnvRequired("HUGGINGFACE_API_KEY"),
			ModelName: getEnv("HUGGINGFACE_MODEL", "facebook/wav2vec2-base-960h"),
			Endpoint:  getEnv("HUGGINGFACE_ENDPOINT", "https://api-inference.huggingface.co"),
		},

		OAuth: OAuthConfig{
			// Instagram
			InstagramClientID:     getEnv("INSTAGRAM_CLIENT_ID", ""),
			InstagramClientSecret: getEnv("INSTAGRAM_CLIENT_SECRET", ""),
			InstagramRedirectURI:  getEnv("INSTAGRAM_REDIRECT_URI", ""),

			// Twitter/X
			TwitterClientID:       getEnv("TWITTER_CLIENT_ID", ""),
			TwitterClientSecret:   getEnv("TWITTER_CLIENT_SECRET", ""),
			TwitterRedirectURI:    getEnv("TWITTER_REDIRECT_URI", ""),

			// Facebook
			FacebookAppID:         getEnv("FACEBOOK_APP_ID", ""),
			FacebookAppSecret:     getEnv("FACEBOOK_APP_SECRET", ""),
			FacebookRedirectURI:   getEnv("FACEBOOK_REDIRECT_URI", ""),

			// TikTok
			TikTokClientKey:       getEnv("TIKTOK_CLIENT_KEY", ""),
			TikTokClientSecret:    getEnv("TIKTOK_CLIENT_SECRET", ""),
			TikTokRedirectURI:     getEnv("TIKTOK_REDIRECT_URI", ""),
		},

		Email: EmailConfig{
			SMTPHost:     getEnv("SMTP_HOST", "smtp.gmail.com"),
			SMTPPort:     smtpPort,
			SMTPUsername: getEnv("SMTP_USERNAME", ""),
			SMTPPassword: getEnv("SMTP_PASSWORD", ""),
			FromEmail:    getEnv("FROM_EMAIL", "noreply@tenang.in"),
			FromName:     getEnv("FROM_NAME", "Tenang.in"),
		},

		Storage: StorageConfig{
			AudioUploadPath:   getEnv("AUDIO_UPLOAD_PATH", "./uploads/audio"),
			MaxFileSize:       maxFileSize,
			AllowedExtensions: []string{".wav", ".mp3", ".m4a", ".flac"},
		},

		Security: SecurityConfig{
			EncryptionKey:    getEnvRequired("ENCRYPTION_KEY"), // Must be 32 bytes
			RateLimitPerMin:  rateLimitPerMin,
			MaxLoginAttempts: maxLoginAttempts,
			LockoutDuration:  lockoutDuration,
		},
	}

	// Validate critical configuration
	validateConfig(config)

	AppConfig = config
	return config
}

// getEnvRequired gets environment variable and panics if not found
func getEnvRequired(key string) string {
	value := os.Getenv(key)
	if value == "" {
		log.Fatalf("Required environment variable %s is not set", key)
	}
	return value
}

// getEnv gets environment variable with fallback
func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

// validateConfig validates critical configuration values
func validateConfig(config *Config) {
	// Validate JWT secrets
	if len(config.JWT.AccessSecret) < 32 {
		log.Fatal("JWT_ACCESS_SECRET must be at least 32 characters")
	}
	if len(config.JWT.RefreshSecret) < 32 {
		log.Fatal("JWT_REFRESH_SECRET must be at least 32 characters")
	}

	// Validate encryption keys (must be exactly 32 bytes for AES-256)
	if len(config.JWT.EncryptionKey) != 32 {
		log.Fatal("JWT_ENCRYPTION_KEY must be exactly 32 bytes")
	}
	if len(config.Security.EncryptionKey) != 32 {
		log.Fatal("ENCRYPTION_KEY must be exactly 32 bytes")
	}

	log.Println("✅ Configuration validation passed")
}