package models

import (
	"time"

	"github.com/google/uuid"
)

type User struct {
	ID                uuid.UUID  `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	Email             string     `gorm:"type:varchar(255);uniqueIndex;not null" json:"email"`
	Username          *string    `gorm:"type:varchar(50);uniqueIndex" json:"username"`
	FullName          *string    `gorm:"type:varchar(100)" json:"fullName"`
	DateOfBirth       *time.Time `gorm:"type:date" json:"dateOfBirth"`
	Timezone          string     `gorm:"type:varchar(50);default:'Asia/Jakarta'" json:"timezone"`
	PrivacyLevel      string     `gorm:"type:varchar(20);default:'standard';check:privacy_level IN ('minimal', 'standard', 'full')" json:"privacyLevel"`
	IsActive          bool       `gorm:"default:true" json:"isActive"`
	EmailVerifiedAt   *time.Time `json:"emailVerifiedAt"`
	LastActiveAt      *time.Time `json:"lastActiveAt"`
	CreatedAt         time.Time  `json:"createdAt"`
	UpdatedAt         time.Time  `json:"updatedAt"`
	DeletedAt         *time.Time `gorm:"index" json:"deletedAt"`

	// Relationships - Using pointers for Has One, slices for Has Many
	Credentials       *UserCredentials     `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"credentials,omitempty"`
	Preferences       *UserPreferences     `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"preferences,omitempty"`
	Sessions          []UserSession        `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"sessions,omitempty"`
	// ChatSessions      []ChatSession        `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"chatSessions,omitempty"`
	// VocalEntries      []VocalJournalEntry  `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"vocalEntries,omitempty"`
	// CommunityPosts    []CommunityPost      `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"communityPosts,omitempty"`
	// PostReplies       []CommunityPostReply `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"postReplies,omitempty"`
	// Reactions         []CommunityReaction  `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"reactions,omitempty"`
	// SocialAccounts    []SocialMediaAccount `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"socialAccounts,omitempty"`
	// Notifications     []Notification       `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"notifications,omitempty"`
	// ProgressMetrics   []UserProgressMetric `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"progressMetrics,omitempty"`
	// ScheduledCheckins []ScheduledCheckin   `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"scheduledCheckins,omitempty"`
}

type UserCredentials struct {
	ID                    uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID                uuid.UUID `gorm:"type:uuid;not null;index" json:"userId"`
	PasswordHash          string    `gorm:"type:varchar(255);not null" json:"-"`
	PasswordChangedAt     time.Time `gorm:"default:CURRENT_TIMESTAMP" json:"passwordChangedAt"`
	FailedLoginAttempts   int       `gorm:"default:0" json:"failedLoginAttempts"`
	LockedUntil           *time.Time `json:"lockedUntil"`
	CreatedAt             time.Time `json:"createdAt"`
	UpdatedAt             time.Time `json:"updatedAt"`

	// Relationships - Using pointer to break circular dependency
	User *User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

type UserPreferences struct {
	ID                          uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID                      uuid.UUID `gorm:"type:uuid;not null;index" json:"userId"`
	NotificationChat            bool      `gorm:"default:true" json:"notificationChat"`
	NotificationCommunity       bool      `gorm:"default:true" json:"notificationCommunity"`
	NotificationSchedule        string    `gorm:"type:jsonb;default:'[]'" json:"notificationSchedule"`
	CommunityAnonymousDefault   bool      `gorm:"default:false" json:"communityAnonymousDefault"`
	SocialMediaMonitoring       bool      `gorm:"default:false" json:"socialMediaMonitoring"`
	CreatedAt                   time.Time `json:"createdAt"`
	UpdatedAt                   time.Time `json:"updatedAt"`

	// Relationships - Using pointer to break circular dependency
	User *User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

type UserSession struct {
	ID             uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID         uuid.UUID `gorm:"type:uuid;not null;index" json:"userId"`
	SessionToken   string    `gorm:"type:varchar(255);not null;uniqueIndex" json:"sessionToken"`
	DeviceInfo     string    `gorm:"type:jsonb;default:'{}'" json:"deviceInfo"`
	IPAddress      string    `gorm:"type:inet" json:"ipAddress"`
	LastActivityAt time.Time `gorm:"default:CURRENT_TIMESTAMP" json:"lastActivityAt"`
	ExpiresAt      time.Time `gorm:"not null" json:"expiresAt"`
	IsActive       bool      `gorm:"default:true" json:"isActive"`
	CreatedAt      time.Time `json:"createdAt"`

	// Relationships - Using pointer to break circular dependency
	User *User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}