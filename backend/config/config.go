package config

import (
	"encoding/base64"
	"log"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

// Config holds all application configuration
type Config struct {
	Server      ServerConfig
	Database    DatabaseConfig
	JWT         JWTConfig
	Azure       AzureConfig
	HuggingFace HuggingFaceConfig
	OAuth       OAuthConfig
	Google      GoogleOAuthConfig
	Email       EmailConfig
	Storage     StorageConfig
	Security    SecurityConfig
}

type ServerConfig struct {
	Port        string
	Host        string
	Environment string
	CORSOrigins []string
}

type JWTConfig struct {
	AccessSecret  string
	RefreshSecret string
	AccessExpiry  time.Duration
	RefreshExpiry time.Duration
	EncryptionKey []byte
}

type AzureConfig struct {
	OpenAIAPIKey        string
	OpenAIEndpoint      string
	SpeechAPIKey        string
	SpeechRegion        string
	TextAnalyticsKey    string
	TextAnalyticsEndpoint string
	BlobStorageAccount  string
	BlobStorageKey      string
	BlobContainerName   string
	BlobContainerAudio  string // Nama diubah agar sesuai .env
	OpenAIDeploymentName string // Ditambahkan
	OpenAIAPIVersion     string // Ditambahkan
	OpenAIModelName      string // Ditambahkan
	OpenAIModelVersion   string // Ditambahkan
}

type HuggingFaceConfig struct {
	APIKey    string
	ModelName string
	Endpoint  string
}

type GoogleOAuthConfig struct {
	ClientID     string
	ClientSecret string
	RedirectURI  string
}

type OAuthConfig struct {
	InstagramClientID     string
	InstagramClientSecret string
	InstagramRedirectURI  string
	TwitterClientID       string
	TwitterClientSecret   string
	TwitterRedirectURI    string
	FacebookAppID         string
	FacebookAppSecret     string
	FacebookRedirectURI   string
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
	MaxFileSize       int64 // in bytes
	AllowedExtensions []string
}

type SecurityConfig struct {
	EncryptionKey    []byte
	RateLimitPerMin  int
	MaxLoginAttempts int
	LockoutDuration  time.Duration
}

var AppConfig *Config

// LoadConfig loads all configuration from environment variables
func LoadConfig() *Config {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	// --- Membaca dan Mem-validasi Kunci Enkripsi dengan Benar ---
	jwtKey := decodeKey("JWT_ENCRYPTION_KEY")
	securityKey := decodeKey("ENCRYPTION_KEY")

	// --- Mem-parsing nilai-nilai lain ---
	accessExpiry, _ := time.ParseDuration(getEnv("JWT_ACCESS_EXPIRY", "15m"))
	refreshExpiry, _ := time.ParseDuration(getEnv("JWT_REFRESH_EXPIRY", "168h"))
	lockoutDuration, _ := time.ParseDuration(getEnv("LOCKOUT_DURATION", "15m"))
	smtpPort, _ := strconv.Atoi(getEnv("SMTP_PORT", "587"))
	maxFileSize, _ := strconv.ParseInt(getEnv("MAX_FILE_SIZE", "10485760"), 10, 64)
	rateLimitPerMin, _ := strconv.Atoi(getEnv("RATE_LIMIT_PER_MIN", "60"))
	maxLoginAttempts, _ := strconv.Atoi(getEnv("MAX_LOGIN_ATTEMPTS", "5"))

	config := &Config{
		Server: ServerConfig{
			Port:        getEnv("PORT", "8080"),
			Host:        getEnv("HOST", "localhost"),
			Environment: getEnv("GIN_MODE", "debug"),
			CORSOrigins: strings.Split(getEnv("CORS_ORIGINS", "http://localhost:3000,http://localhost:8081"), ","),
		},

		Database: *LoadDatabaseConfig(), // Memanggil fungsi dari database.go

		JWT: JWTConfig{
			AccessSecret:  getEnvRequired("JWT_ACCESS_SECRET"),
			RefreshSecret: getEnvRequired("JWT_REFRESH_SECRET"),
			AccessExpiry:  accessExpiry,
			RefreshExpiry: refreshExpiry,
			EncryptionKey: jwtKey, // Menyimpan hasil decode
		},

		Azure: AzureConfig{
			OpenAIAPIKey:         getEnv("AZURE_OPENAI_API_KEY", ""),
			OpenAIEndpoint:       getEnv("AZURE_OPENAI_ENDPOINT", ""),
			OpenAIDeploymentName: getEnv("AZURE_OPENAI_DEPLOYMENT_NAME", ""),
			OpenAIAPIVersion:     getEnv("AZURE_OPENAI_API_VERSION", "2024-02-15-preview"),

			SpeechAPIKey: getEnv("AZURE_SPEECH_API_KEY", ""),
			SpeechRegion: getEnv("AZURE_SPEECH_REGION", ""),

			TextAnalyticsKey:      getEnv("AZURE_TEXT_ANALYTICS_KEY", ""),
			TextAnalyticsEndpoint: getEnv("AZURE_TEXT_ANALYTICS_ENDPOINT", ""),

			BlobStorageAccount:  getEnv("AZURE_BLOB_STORAGE_ACCOUNT", ""),
			BlobStorageKey:      getEnv("AZURE_BLOB_STORAGE_KEY", ""),
			BlobContainerAudio:  getEnv("AZURE_BLOB_CONTAINER_AUDIO", "audio-files"),
		},

		HuggingFace: HuggingFaceConfig{
			APIKey:    getEnv("HUGGINGFACE_API_KEY", ""),
			ModelName: getEnv("HUGGINGFACE_MODEL", "facebook/wav2vec2-base-960h"),
			Endpoint:  getEnv("HUGGINGFACE_ENDPOINT", "https://api-inference.huggingface.co"),
		},

		Google: GoogleOAuthConfig{
			ClientID:     getEnv("GOOGLE_CLIENT_ID", ""),
			ClientSecret: getEnv("GOOGLE_CLIENT_SECRET", ""),
			RedirectURI:  getEnv("GOOGLE_REDIRECT_URI", ""),
		},

		OAuth: OAuthConfig{
			InstagramClientID:     getEnv("INSTAGRAM_CLIENT_ID", ""),
			InstagramClientSecret: getEnv("INSTAGRAM_CLIENT_SECRET", ""),
			InstagramRedirectURI:  getEnv("INSTAGRAM_REDIRECT_URI", ""),
			TwitterClientID:       getEnv("TWITTER_CLIENT_ID", ""),
			TwitterClientSecret:   getEnv("TWITTER_CLIENT_SECRET", ""),
			TwitterRedirectURI:    getEnv("TWITTER_REDIRECT_URI", ""),
			FacebookAppID:         getEnv("FACEBOOK_APP_ID", ""),
			FacebookAppSecret:     getEnv("FACEBOOK_APP_SECRET", ""),
			FacebookRedirectURI:   getEnv("FACEBOOK_REDIRECT_URI", ""),
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
			AllowedExtensions: []string{".wav", ".mp3", ".m4a"},
		},

		Security: SecurityConfig{
			EncryptionKey:    securityKey, // Menyimpan hasil decode
			RateLimitPerMin:  rateLimitPerMin,
			MaxLoginAttempts: maxLoginAttempts,
			LockoutDuration:  lockoutDuration,
		},
	}

	validateConfig(config) // Tetap memanggil fungsi validasi utama

	AppConfig = config
	return config
}

// getEnvRequired mengambil environment variable dan panic jika tidak ada.
func getEnvRequired(key string) string {
	value := os.Getenv(key)
	if value == "" {
		log.Fatalf("FATAL: Required environment variable %s is not set", key)
	}
	return value
}

// getEnv mengambil environment variable dengan nilai default.
func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

// decodeKey adalah helper untuk men-decode dan memvalidasi kunci Base64.
func decodeKey(envKey string) []byte {
	keyStr := getEnvRequired(envKey)

	decodedKey, err := base64.StdEncoding.DecodeString(keyStr)
	if err != nil {
		log.Fatalf("FATAL: '%s' is not a valid base64 string: %v", envKey, err)
	}

	// Validasi panjang dilakukan di sini, di satu tempat.
	if len(decodedKey) != 32 {
		log.Fatalf("FATAL: Decoded '%s' must be exactly 32 bytes, but got %d bytes", envKey, len(decodedKey))
	}

	return decodedKey
}

// validateConfig memvalidasi nilai-nilai konfigurasi penting lainnya.
func validateConfig(config *Config) {
	if len(config.JWT.AccessSecret) < 32 {
		log.Println("WARNING: JWT_ACCESS_SECRET should be at least 32 characters for security.")
	}
	if len(config.JWT.RefreshSecret) < 32 {
		log.Println("WARNING: JWT_REFRESH_SECRET should be at least 32 characters for security.")
	}

	// Validasi untuk kunci enkripsi sudah dilakukan di dalam decodeKey,
	// sehingga tidak perlu diulang di sini.

	log.Println("✅ Configuration values loaded and validated.")
}