package models

import (
	"time"

	"github.com/google/uuid"
)

type Notification struct {
	ID               uuid.UUID  `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID           uuid.UUID  `gorm:"type:uuid;not null;index" json:"userId"`
	NotificationType string     `gorm:"type:varchar(30);not null;check:notification_type IN ('chat_checkin', 'community_reply', 'community_reaction', 'social_media_alert', 'wellness_reminder')" json:"notificationType"`
	Title            string     `gorm:"type:varchar(200);not null" json:"title"`
	Message          string     `gorm:"type:text;not null" json:"message"`
	ActionURL        *string    `gorm:"type:varchar(500)" json:"actionUrl"`
	ActionData       string     `gorm:"type:jsonb;default:'{}'" json:"actionData"`
	Priority         string     `gorm:"type:varchar(10);default:'normal';check:priority IN ('low', 'normal', 'high', 'urgent')" json:"priority"`
	DeliveryMethod   string     `gorm:"type:varchar(20);default:'push';check:delivery_method IN ('push', 'email', 'in_app')" json:"deliveryMethod"`
	IsRead           bool       `gorm:"default:false" json:"isRead"`
	IsSent           bool       `gorm:"default:false" json:"isSent"`
	ScheduledFor     *time.Time `json:"scheduledFor"`
	SentAt           *time.Time `json:"sentAt"`
	ReadAt           *time.Time `json:"readAt"`
	ExpiresAt        *time.Time `json:"expiresAt"`
	CreatedAt        time.Time  `json:"createdAt"`

	// Relationships - Using pointer to break circular dependency
	User *User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

type UserProgressMetric struct {
	ID              uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID          uuid.UUID `gorm:"type:uuid;not null;index" json:"userId"`
	MetricType      string    `gorm:"type:varchar(30);not null;check:metric_type IN ('wellbeing_trend_vocal', 'chat_engagement', 'community_participation', 'overall_wellness')" json:"metricType"`
	MetricValue     float64   `gorm:"type:decimal(10,2);not null" json:"metricValue"`
	MetricDate      time.Time `gorm:"type:date;not null" json:"metricDate"`
	CalculationData string    `gorm:"type:jsonb;default:'{}'" json:"calculationData"`
	CreatedAt       time.Time `json:"createdAt"`

	// Relationships - Using pointer to break circular dependency
	User *User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

type SystemAnalytics struct {
	ID          uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	EventType   string    `gorm:"type:varchar(50);not null" json:"eventType"`
	EventData   string    `gorm:"type:jsonb;not null;default:'{}'" json:"eventData"`
	UserSegment *string   `gorm:"type:varchar(30)" json:"userSegment"`
	DeviceType  *string   `gorm:"type:varchar(20)" json:"deviceType"`
	AppVersion  *string   `gorm:"type:varchar(20)" json:"appVersion"`
	CreatedAt   time.Time `json:"createdAt"`
}

type AuditLog struct {
	ID        uuid.UUID  `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID    *uuid.UUID `gorm:"type:uuid;index" json:"userId"`
	Action    string     `gorm:"type:varchar(50);not null" json:"action"`
	TableName *string    `gorm:"type:varchar(50)" json:"tableName"`
	RecordID  *uuid.UUID `gorm:"type:uuid" json:"recordId"`
	OldValues *string    `gorm:"type:jsonb" json:"oldValues"`
	NewValues *string    `gorm:"type:jsonb" json:"newValues"`
	IPAddress *string    `gorm:"type:inet" json:"ipAddress"`
	UserAgent *string    `gorm:"type:text" json:"userAgent"`
	CreatedAt time.Time  `json:"createdAt"`

	// Relationships - Using pointer to break circular dependency
	User *User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}
