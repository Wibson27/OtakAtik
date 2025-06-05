package models

import (
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
)

type VocalJournalEntry struct {
	ID                  uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID              uuid.UUID `gorm:"type:uuid;not null;index" json:"userId"`
	EntryTitle          *string   `gorm:"type:varchar(200)" json:"entryTitle"`
	DurationSeconds     int       `gorm:"not null" json:"durationSeconds"`
	FileSizeBytes       *int64    `json:"fileSizeBytes"`
	AudioFilePath       string    `gorm:"type:varchar(500);not null" json:"audioFilePath"`
	AudioFormat         string    `gorm:"type:varchar(10);default:'wav';check:audio_format IN ('wav', 'mp3', 'm4a')" json:"audioFormat"`
	RecordingQuality    string    `gorm:"type:varchar(20);default:'good';check:recording_quality IN ('poor', 'fair', 'good', 'excellent')" json:"recordingQuality"`
	AmbientNoiseLevel   string    `gorm:"type:varchar(20);default:'low';check:ambient_noise_level IN ('low', 'medium', 'high')" json:"ambientNoiseLevel"`
	UserTags            pq.StringArray `gorm:"type:text[]" json:"userTags"`
	TranscriptionEnabled bool      `gorm:"default:true" json:"transcriptionEnabled"`
	AnalysisStatus      string    `gorm:"type:varchar(20);default:'pending';check:analysis_status IN ('pending', 'processing', 'completed', 'failed')" json:"analysisStatus"`
	PrivacyLevel        string    `gorm:"type:varchar(20);default:'private';check:privacy_level IN ('private', 'anonymous_research')" json:"privacyLevel"`
	CreatedAt           time.Time `json:"createdAt"`
	UpdatedAt           time.Time `json:"updatedAt"`

	// Relationships - Using pointers for has-one, belongs-to
	User              *User                   `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Transcription     *VocalTranscription     `gorm:"foreignKey:VocalEntryID;constraint:OnDelete:CASCADE" json:"transcription,omitempty"`
	SentimentAnalysis *VocalSentimentAnalysis `gorm:"foreignKey:VocalEntryID;constraint:OnDelete:CASCADE" json:"sentimentAnalysis,omitempty"`
}

type VocalTranscription struct {
	ID                   uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	VocalEntryID         uuid.UUID `gorm:"type:uuid;not null;index" json:"vocalEntryId"`
	TranscriptionText    string    `gorm:"type:text;not null" json:"transcriptionText"`
	ConfidenceScore      *float64  `gorm:"type:decimal(3,2);check:confidence_score BETWEEN 0 AND 1" json:"confidenceScore"`
	LanguageDetected     *string   `gorm:"type:varchar(10)" json:"languageDetected"`
	WordCount            *int      `json:"wordCount"`
	ProcessingService    string    `gorm:"type:varchar(50);default:'azure_speech'" json:"processingService"`
	ProcessingDurationMs *int      `json:"processingDurationMs"`
	IsEncrypted          bool      `gorm:"default:true" json:"isEncrypted"`
	CreatedAt            time.Time `json:"createdAt"`

	// Relationships - Using pointer to break circular dependency
	VocalEntry *VocalJournalEntry `gorm:"foreignKey:VocalEntryID" json:"vocalEntry,omitempty"`
}

type VocalSentimentAnalysis struct {
	ID                      uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	VocalEntryID            uuid.UUID `gorm:"type:uuid;not null;index" json:"vocalEntryId"`
	OverallWellbeingScore   *float64  `gorm:"type:decimal(3,1);check:overall_wellbeing_score BETWEEN 1 AND 10" json:"overallWellbeingScore"`
	WellbeingCategory       *string   `gorm:"type:varchar(50)" json:"wellbeingCategory"`
	EmotionalValence        *float64  `gorm:"type:decimal(3,2);check:emotional_valence BETWEEN -1 AND 1" json:"emotionalValence"`
	EmotionalArousal        *float64  `gorm:"type:decimal(3,2);check:emotional_arousal BETWEEN -1 AND 1" json:"emotionalArousal"`
	EmotionalDominance      *float64  `gorm:"type:decimal(3,2);check:emotional_dominance BETWEEN -1 AND 1" json:"emotionalDominance"`
	DetectedEmotions        string    `gorm:"type:jsonb;default:'{}'" json:"detectedEmotions"`
	DetectedThemes          pq.StringArray `gorm:"type:text[]" json:"detectedThemes"`
	StressIndicators        string    `gorm:"type:jsonb;default:'{}'" json:"stressIndicators"`
	VoiceFeatures           string    `gorm:"type:jsonb;default:'{}'" json:"voiceFeatures"`
	AnalysisModelVersion    *string   `gorm:"type:varchar(50)" json:"analysisModelVersion"`
	ConfidenceScore         *float64  `gorm:"type:decimal(3,2);check:confidence_score BETWEEN 0 AND 1" json:"confidenceScore"`
	ProcessingDurationMs    *int      `json:"processingDurationMs"`
	ReflectionPrompt        *string   `gorm:"type:text" json:"reflectionPrompt"`
	CreatedAt               time.Time `json:"createdAt"`

	// Relationships - Using pointer to break circular dependency
	VocalEntry *VocalJournalEntry `gorm:"foreignKey:VocalEntryID" json:"vocalEntry,omitempty"`
}