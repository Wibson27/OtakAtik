package models

import (
	"time"

	"github.com/google/uuid"
)

type SocialMediaAccount struct {
	ID                   uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID               uuid.UUID `gorm:"type:uuid;not null;index" json:"userId"`
	Platform             string    `gorm:"type:varchar(20);not null;check:platform IN ('instagram', 'twitter', 'facebook', 'tiktok')" json:"platform"`
	PlatformUserID       string    `gorm:"type:varchar(100);not null" json:"platformUserId"`
	PlatformUsername     *string   `gorm:"type:varchar(100)" json:"platformUsername"`
	AccessTokenEncrypted *string   `gorm:"type:text" json:"-"`
	TokenExpiresAt       *time.Time `json:"tokenExpiresAt"`
	MonitoringEnabled    bool      `gorm:"default:false" json:"monitoringEnabled"`
	LastSyncAt           *time.Time `json:"lastSyncAt"`
	WebhookURL           *string   `gorm:"type:varchar(500)" json:"webhookUrl"`
	CreatedAt            time.Time `json:"createdAt"`
	UpdatedAt            time.Time `json:"updatedAt"`

	// Relationships - Using pointer for belongs-to, slice for has-many
	User           *User                        `gorm:"foreignKey:UserID" json:"user,omitempty"`
	MonitoredPosts []SocialMediaPostMonitored   `gorm:"foreignKey:SocialAccountID;constraint:OnDelete:CASCADE" json:"monitoredPosts,omitempty"`
}

type SocialMediaPostMonitored struct {
	ID               uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	SocialAccountID  uuid.UUID `gorm:"type:uuid;not null;index" json:"socialAccountId"`
	PlatformPostID   string    `gorm:"type:varchar(200);not null" json:"platformPostId"`
	PostType         *string   `gorm:"type:varchar(20);check:post_type IN ('text', 'image', 'video', 'story')" json:"postType"`
	PostTimestamp    time.Time `gorm:"not null" json:"postTimestamp"`
	PostMetadata     string    `gorm:"type:jsonb;default:'{}'" json:"postMetadata"`
	ContentHash      *string   `gorm:"type:varchar(64)" json:"contentHash"`
	SentimentProcessed bool    `gorm:"default:false" json:"sentimentProcessed"`
	PrivacyLevel     string    `gorm:"type:varchar(20);default:'private'" json:"privacyLevel"`
	CreatedAt        time.Time `json:"createdAt"`

	// Relationships - Using pointer to break circular dependency
	SocialAccount *SocialMediaAccount `gorm:"foreignKey:SocialAccountID" json:"socialAccount,omitempty"`
}