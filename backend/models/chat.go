package models

import (
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
)

type ChatSession struct {
	ID                    uuid.UUID  `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID                uuid.UUID  `gorm:"type:uuid;not null;index" json:"userId"`
	SessionTitle          *string    `gorm:"type:varchar(200)" json:"sessionTitle"`
	TriggerType           string     `gorm:"type:varchar(30);not null;check:trigger_type IN ('user_initiated', 'social_media_alert', 'scheduled_checkin', 'crisis_intervention')" json:"triggerType"`
	TriggerSourceID       *uuid.UUID `gorm:"type:uuid" json:"triggerSourceId"`
	SessionStatus         string     `gorm:"type:varchar(20);default:'active';check:session_status IN ('active', 'completed', 'abandoned')" json:"sessionStatus"`
	MessageCount          int        `gorm:"default:0" json:"messageCount"`
	SessionDurationSeconds *int      `json:"sessionDurationSeconds"`
	StartedAt             time.Time  `gorm:"default:CURRENT_TIMESTAMP" json:"startedAt"`
	EndedAt               *time.Time `json:"endedAt"`
	CreatedAt             time.Time  `json:"createdAt"`
	UpdatedAt             time.Time  `json:"updatedAt"`

	// Relationships - Using pointer for belongs-to, slice for has-many
	User     *User         `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Messages []ChatMessage `gorm:"foreignKey:ChatSessionID;constraint:OnDelete:CASCADE" json:"messages,omitempty"`
}

type ChatMessage struct {
	ID              uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	ChatSessionID   uuid.UUID `gorm:"type:uuid;not null;index" json:"chatSessionId"`
	SenderType      string    `gorm:"type:varchar(10);not null;check:sender_type IN ('user', 'ai_bot')" json:"senderType"`
	MessageContent  string    `gorm:"type:text;not null" json:"messageContent"`
	MessageMetadata string    `gorm:"type:jsonb;default:'{}'" json:"messageMetadata"`
	SentimentScore  *float64  `gorm:"type:decimal(3,2);check:sentiment_score BETWEEN -1 AND 1" json:"sentimentScore"`
	EmotionDetected *string   `gorm:"type:varchar(20)" json:"emotionDetected"`
	ResponseTimeMs  *int      `json:"responseTimeMs"`
	IsEncrypted     bool      `gorm:"default:false" json:"isEncrypted"`
	CreatedAt       time.Time `json:"createdAt"`

	// Relationships - Using pointer to break circular dependency
	ChatSession *ChatSession `gorm:"foreignKey:ChatSessionID" json:"chatSession,omitempty"`
}

type ScheduledCheckin struct {
	ID               uuid.UUID     `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID           uuid.UUID     `gorm:"type:uuid;not null;index" json:"userId"`
	ScheduleName     *string       `gorm:"type:varchar(100)" json:"scheduleName"`
	TimeOfDay        time.Time     `gorm:"type:time;not null" json:"timeOfDay"`
	DaysOfWeek       pq.Int64Array `gorm:"type:integer[];not null" json:"daysOfWeek"`
	IsActive         bool          `gorm:"default:true" json:"isActive"`
	GreetingTemplate *string       `gorm:"type:varchar(500)" json:"greetingTemplate"`
	LastTriggeredAt  *time.Time    `json:"lastTriggeredAt"`
	NextTriggerAt    *time.Time    `json:"nextTriggerAt"`
	CreatedAt        time.Time     `json:"createdAt"`
	UpdatedAt        time.Time     `json:"updatedAt"`

	// Relationships - Using pointer to break circular dependency
	User *User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}