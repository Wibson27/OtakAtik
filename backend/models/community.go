package models

import (
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
)

type CommunityCategory struct {
	ID                  uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	CategoryName        string    `gorm:"type:varchar(100);not null;uniqueIndex" json:"categoryName"`
	CategoryDescription *string   `gorm:"type:text" json:"categoryDescription"`
	CategoryColor       string    `gorm:"type:varchar(7);default:'#6B73FF'" json:"categoryColor"`
	DisplayOrder        int       `gorm:"default:0" json:"displayOrder"`
	IsActive            bool      `gorm:"default:true" json:"isActive"`
	ModeratorRequired   bool      `gorm:"default:false" json:"moderatorRequired"`
	PostGuidelines      *string   `gorm:"type:text" json:"postGuidelines"`
	IconName            *string   `gorm:"type:varchar(50)" json:"iconName"`
	CreatedAt           time.Time `json:"createdAt"`
	UpdatedAt           time.Time `json:"updatedAt"`

	// Relationships - Has many posts
	Posts []CommunityPost `gorm:"foreignKey:CategoryID;constraint:OnDelete:CASCADE" json:"posts,omitempty"`
}

type CommunityPost struct {
	ID                   uuid.UUID      `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID               uuid.UUID      `gorm:"type:uuid;not null;index" json:"userId"`
	CategoryID           uuid.UUID      `gorm:"type:uuid;not null;index" json:"categoryId"`
	PostTitle            string         `gorm:"type:varchar(200);not null" json:"postTitle"`
	PostContent          string         `gorm:"type:text;not null" json:"postContent"`
	IsAnonymous          bool           `gorm:"default:false" json:"isAnonymous"`
	AnonymousDisplayName *string        `gorm:"type:varchar(50)" json:"anonymousDisplayName"`
	PostStatus           string         `gorm:"type:varchar(20);default:'published';check:post_status IN ('draft', 'published', 'hidden', 'deleted')" json:"postStatus"`
	SentimentScore       *float64       `gorm:"type:decimal(3,2);check:sentiment_score BETWEEN -1 AND 1" json:"sentimentScore"`
	ContentWarnings      pq.StringArray `gorm:"type:text[]" json:"contentWarnings"`
	ViewCount            int            `gorm:"default:0" json:"viewCount"`
	ReplyCount           int            `gorm:"default:0" json:"replyCount"`
	ReactionCount        int            `gorm:"default:0" json:"reactionCount"`
	LastActivityAt       time.Time      `gorm:"default:CURRENT_TIMESTAMP" json:"lastActivityAt"`
	IsPinned             bool           `gorm:"default:false" json:"isPinned"`
	ModerationNotes      *string        `gorm:"type:text" json:"moderationNotes"`
	CreatedAt            time.Time      `json:"createdAt"`
	UpdatedAt            time.Time      `json:"updatedAt"`

	// Relationships - Using pointers for belongs-to, slices for has-many
	User      *User                `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Category  *CommunityCategory   `gorm:"foreignKey:CategoryID" json:"category,omitempty"`
	Replies   []CommunityPostReply `gorm:"foreignKey:PostID;constraint:OnDelete:CASCADE" json:"replies,omitempty"`
	Reactions []CommunityReaction  `gorm:"polymorphic:Target;polymorphicValue:post" json:"reactions,omitempty"`
}

type CommunityPostReply struct {
	ID                   uuid.UUID  `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	PostID               uuid.UUID  `gorm:"type:uuid;not null;index" json:"postId"`
	ParentReplyID        *uuid.UUID `gorm:"type:uuid;index" json:"parentReplyId"`
	UserID               uuid.UUID  `gorm:"type:uuid;not null;index" json:"userId"`
	ReplyContent         string     `gorm:"type:text;not null" json:"replyContent"`
	IsAnonymous          bool       `gorm:"default:false" json:"isAnonymous"`
	AnonymousDisplayName *string    `gorm:"type:varchar(50)" json:"anonymousDisplayName"`
	ReplyLevel           int        `gorm:"default:1;check:reply_level BETWEEN 1 AND 3" json:"replyLevel"`
	SentimentScore       *float64   `gorm:"type:decimal(3,2);check:sentiment_score BETWEEN -1 AND 1" json:"sentimentScore"`
	ReactionCount        int        `gorm:"default:0" json:"reactionCount"`
	IsDeleted            bool       `gorm:"default:false" json:"isDeleted"`
	CreatedAt            time.Time  `json:"createdAt"`
	UpdatedAt            time.Time  `json:"updatedAt"`

	// Relationships - Using pointers for belongs-to, slices for has-many
	Post         *CommunityPost       `gorm:"foreignKey:PostID" json:"post,omitempty"`
	ParentReply  *CommunityPostReply  `gorm:"foreignKey:ParentReplyID" json:"parentReply,omitempty"`
	ChildReplies []CommunityPostReply `gorm:"foreignKey:ParentReplyID;constraint:OnDelete:CASCADE" json:"childReplies,omitempty"`
	User         *User                `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Reactions    []CommunityReaction  `gorm:"polymorphic:Target;polymorphicValue:reply" json:"reactions,omitempty"`
}

type CommunityReaction struct {
	ID           uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID       uuid.UUID `gorm:"type:uuid;not null;index" json:"userId"`
	TargetType   string    `gorm:"type:varchar(20);not null;check:target_type IN ('post', 'reply')" json:"targetType"`
	TargetID     uuid.UUID `gorm:"type:uuid;not null;index" json:"targetId"`
	ReactionType string    `gorm:"type:varchar(20);not null;check:reaction_type IN ('support', 'relate', 'inspired', 'sending_love')" json:"reactionType"`
	CreatedAt    time.Time `json:"createdAt"`

	// Relationships - Using pointer to break circular dependency
	User *User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}
