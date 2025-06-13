package models

import (
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/datatypes"
)

type VocalJournalEntry struct {
	ID                   uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"ID"`
	UserID               uuid.UUID `gorm:"type:uuid;not null;index" json:"UserID"`
	EntryTitle           *string   `gorm:"type:varchar(200)" json:"EntryTitle"`
	DurationSeconds      int       `gorm:"not null" json:"DurationSeconds"`
	FileSizeBytes        *int64    `json:"FileSizeBytes"`
	AudioFilePath        string    `gorm:"type:varchar(500);not null" json:"AudioFilePath"`
	AudioFormat          string    `gorm:"type:varchar(10);default:'wav'" json:"AudioFormat"`
	RecordingQuality     string    `gorm:"type:varchar(20);default:'good'" json:"RecordingQuality"`
	AmbientNoiseLevel    string    `gorm:"type:varchar(20);default:'low'" json:"AmbientNoiseLevel"`
	UserTags             pq.StringArray `gorm:"type:text[]" json:"UserTags"`
	TranscriptionEnabled bool      `gorm:"default:true" json:"TranscriptionEnabled"`
	AnalysisStatus       string    `gorm:"type:varchar(20);default:'pending'" json:"AnalysisStatus"`
	PrivacyLevel         string    `gorm:"type:varchar(20);default:'private'" json:"PrivacyLevel"`
	CreatedAt            time.Time `json:"CreatedAt"`
	UpdatedAt            time.Time `json:"UpdatedAt"`
	User                 *User                 `gorm:"foreignKey:UserID" json:"User,omitempty"`
	Transcription        *VocalTranscription   `gorm:"foreignKey:VocalEntryID;constraint:OnDelete:CASCADE" json:"Transcription,omitempty"`
	SentimentAnalysis    *VocalSentimentAnalysis `gorm:"foreignKey:VocalEntryID;constraint:OnDelete:CASCADE" json:"Analysis,omitempty"`
}

type VocalTranscription struct {
	ID                   uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"ID"`
	VocalEntryID         uuid.UUID `gorm:"type:uuid;not null;index" json:"VocalEntryID"`
	TranscriptionText    string    `gorm:"type:text;not null" json:"TranscriptionText"`
	ConfidenceScore      *float64  `gorm:"type:decimal(3,2)" json:"ConfidenceScore"`
	LanguageDetected     *string   `gorm:"type:varchar(10)" json:"LanguageDetected"`
	WordCount            *int      `json:"WordCount"`
	ProcessingService    string    `gorm:"type:varchar(50);default:'azure_speech'" json:"ProcessingService"`
	ProcessingDurationMs *int      `json:"ProcessingDurationMs"`
	IsEncrypted          bool      `gorm:"default:true" json:"IsEncrypted"`
	CreatedAt            time.Time `json:"CreatedAt"`

	// Relationships - Using pointer to break circular dependency
	VocalEntry *VocalJournalEntry `gorm:"foreignKey:VocalEntryID" json:"vocalEntry,omitempty"`
}

type VocalSentimentAnalysis struct {
	ID                    uuid.UUID      `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"ID"`
	VocalEntryID          uuid.UUID      `gorm:"type:uuid;not null" json:"VocalEntryID"`
	OverallWellbeingScore *float64       `gorm:"type:decimal(3,1)" json:"OverallWellbeingScore"`
	WellbeingCategory     *string        `gorm:"type:varchar(100)" json:"WellbeingCategory"`
	EmotionalValence      *float64       `gorm:"type:decimal(3,2)" json:"EmotionalValence,omitempty"`
	EmotionalArousal      *float64       `gorm:"type:decimal(3,2)" json:"EmotionalArousal,omitempty"`
	EmotionalDominance    *float64       `gorm:"type:decimal(3,2)" json:"EmotionalDominance,omitempty"`
	DetectedEmotions      datatypes.JSON `gorm:"type:jsonb" json:"DetectedEmotions,omitempty"`
	DetectedThemes        pq.StringArray `gorm:"type:text[]" json:"DetectedThemes,omitempty"`
	StressIndicators      datatypes.JSON `gorm:"type:jsonb" json:"StressIndicators,omitempty"`
	VoiceFeatures         datatypes.JSON `gorm:"type:jsonb" json:"VoiceFeatures,omitempty"`
	AnalysisModelVersion  *string        `gorm:"type:varchar(50)" json:"AnalysisModelVersion"`
	ConfidenceScore       *float64       `gorm:"type:decimal(3,2)" json:"ConfidenceScore,omitempty"`
	ProcessingDurationMs  *int           `json:"ProcessingDurationMs,omitempty"`
	ReflectionPrompt      *string        `gorm:"type:text" json:"ReflectionPrompt"`
	CreatedAt             time.Time      `json:"CreatedAt"`
	UpdatedAt             time.Time      `json:"UpdatedAt"`

	// Relationships - Using pointer to break circular dependency
	VocalEntry *VocalJournalEntry `gorm:"foreignKey:VocalEntryID" json:"VocalEntry,omitempty"`
}