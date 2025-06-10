package controllers

import (
	"errors"
	"math"
	"net/http"
	"strconv"
	"time"

	"backend/middleware"
	"backend/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/gorm"
)

type CommunityController struct {
	DB *gorm.DB
}

func NewCommunityController(db *gorm.DB) *CommunityController {
	return &CommunityController{DB: db}
}

// --- DTOs (Data Transfer Objects) for Community Controller ---

type UserSummaryResponse struct {
	ID       uuid.UUID `json:"id"`
	Username *string   `json:"username"`
	FullName *string   `json:"full_name"`
}

type ReplyResponse struct {
	ID                   uuid.UUID            `json:"id"`
	PostID               uuid.UUID            `json:"post_id"`
	ParentReplyID        *uuid.UUID           `json:"parent_reply_id,omitempty"`
	Author               *UserSummaryResponse `json:"author,omitempty"`
	AnonymousDisplayName *string              `json:"anonymous_display_name,omitempty"`
	IsAnonymous          bool                 `json:"is_anonymous"`
	ReplyContent         string               `json:"reply_content"`
	ReplyLevel           int                  `json:"reply_level"`
	ReactionCount        int                  `json:"reaction_count"`
	CreatedAt            time.Time            `json:"created_at"`
	UpdatedAt            time.Time            `json:"updated_at"`
}

type PostResponse struct {
	ID                   uuid.UUID                `json:"id"`
	Category             models.CommunityCategory `json:"category"` // Diperbaiki di mapping
	Author               *UserSummaryResponse     `json:"author,omitempty"`
	AnonymousDisplayName *string                  `json:"anonymous_display_name,omitempty"`
	IsAnonymous          bool                     `json:"is_anonymous"`
	PostTitle            string                   `json:"post_title"`
	PostContent          string                   `json:"post_content"`
	PostStatus           string                   `json:"post_status"`
	SentimentScore       float64                  `json:"sentiment_score"` // Diperbaiki di mapping
	ContentWarnings      pq.StringArray           `json:"content_warnings"`
	ViewCount            int                      `json:"view_count"`
	ReplyCount           int                      `json:"reply_count"`
	ReactionCount        int                      `json:"reaction_count"`
	IsPinned             bool                     `json:"is_pinned"`
	LastActivityAt       time.Time                `json:"last_activity_at"`
	CreatedAt            time.Time                `json:"created_at"`
	UpdatedAt            time.Time                `json:"updated_at"`
	Replies              []ReplyResponse          `json:"replies,omitempty"`
}

// --- Request Body Structs ---

type CreatePostRequest struct {
	CategoryID      uuid.UUID      `json:"category_id" binding:"required"`
	PostTitle       string         `json:"post_title" binding:"required,min=5,max=200"`
	PostContent     string         `json:"post_content" binding:"required,min=10"`
	IsAnonymous     bool           `json:"is_anonymous"`
	ContentWarnings pq.StringArray `json:"content_warnings" gorm:"type:text[]"`
}

type CreateReplyRequest struct {
	PostID        uuid.UUID  `json:"post_id" binding:"required"`
	ParentReplyID *uuid.UUID `json:"parent_reply_id"`
	ReplyContent  string     `json:"reply_content" binding:"required,min=1"`
	IsAnonymous   bool       `json:"is_anonymous"`
}

type AddReactionRequest struct {
	TargetType   string    `json:"target_type" binding:"required,oneof=post reply"`
	TargetID     uuid.UUID `json:"target_id" binding:"required"`
	ReactionType string    `json:"reaction_type" binding:"required,oneof=support relate inspired sending_love"`
}

type ReportRequest struct {
	Reason string `json:"reason" binding:"required"`
	Notes  string `json:"notes"`
}

type ModerationRequest struct {
	NewStatus string `json:"new_status" binding:"required,oneof=published hidden deleted"`
	Notes     string `json:"notes" binding:"required"`
	IsPinned  *bool  `json:"is_pinned"`
}

// --- Controller Handlers (Kode fungsi tidak berubah, hanya perbaikan di DTO dan helper) ---

// GetCategories returns all active community categories.
// ROUTE: GET /api/v1/community/categories
func (co *CommunityController) GetCategories(c *gin.Context) {
	var categories []models.CommunityCategory
	if err := co.DB.Where("is_active = ?", true).Order("display_order ASC").Find(&categories).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch categories", "code": "db_error"})
		return
	}
	c.JSON(http.StatusOK, categories)
}

// CreatePost creates a new community post.
// ROUTE: POST /api/v1/community/posts
func (co *CommunityController) CreatePost(c *gin.Context) {
	var req CreatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data", "details": err.Error(), "code": "validation_failed"})
		return
	}

	authedUser, err := middleware.GetFullUserFromContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required", "code": "auth_required"})
		return
	}

	post := models.CommunityPost{
		UserID:          authedUser.ID,
		CategoryID:      req.CategoryID,
		PostTitle:       req.PostTitle,
		PostContent:     req.PostContent,
		IsAnonymous:     req.IsAnonymous,
		PostStatus:      "published",
		ContentWarnings: req.ContentWarnings,
	}

	if post.IsAnonymous {
		name := generateAnonymousName()
		post.AnonymousDisplayName = &name
	}

	if err := co.DB.Create(&post).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create post", "code": "db_creation_failed"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Post created successfully", "post_id": post.ID})
}

// GetPublicPosts returns a paginated list of posts, can be called without authentication.
// ROUTE: GET /api/v1/community/posts/public
func (co *CommunityController) GetPublicPosts(c *gin.Context) {
	co.getPaginatedPosts(c)
}

// GetUserPosts returns posts created by a specific user.
// ROUTE: GET /api/v1/community/posts
func (co *CommunityController) GetUserPosts(c *gin.Context) {
	co.getPaginatedPosts(c)
}

// GetPost returns a single detailed post with its replies.
// ROUTE: GET /api/v1/community/posts/:postId
func (co *CommunityController) GetPost(c *gin.Context) {
	postID, err := uuid.Parse(c.Param("postId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID format", "code": "invalid_post_id"})
		return
	}

	var post models.CommunityPost
	if err := co.DB.Preload("Category").Preload("User").
		Where("id = ? AND post_status = ?", postID, "published").
		First(&post).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found", "code": "post_not_found"})
		return
	}

	go func() {
		co.DB.Model(&models.CommunityPost{}).Where("id = ?", postID).UpdateColumn("view_count", gorm.Expr("view_count + 1"))
	}()

	var replies []models.CommunityPostReply
	co.DB.Preload("User").Where("post_id = ? AND is_deleted = ?", postID, false).Order("created_at ASC").Find(&replies)

	postResponse := co.mapPostToResponse(post, replies)

	c.JSON(http.StatusOK, postResponse)
}

// CreateReply adds a reply to a post.
// ROUTE: POST /api/v1/community/replies
func (co *CommunityController) CreateReply(c *gin.Context) {
	var req CreateReplyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data", "code": "validation_failed"})
		return
	}

	authedUser, _ := middleware.GetFullUserFromContext(c)

	var post models.CommunityPost
	if err := co.DB.Where("id = ? AND post_status = 'published'", req.PostID).First(&post).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found or has been hidden", "code": "post_not_found"})
		return
	}

	reply := models.CommunityPostReply{
		PostID:       req.PostID,
		UserID:       authedUser.ID,
		ReplyContent: req.ReplyContent,
		IsAnonymous:  req.IsAnonymous,
	}

	if req.IsAnonymous {
		name := generateAnonymousName()
		reply.AnonymousDisplayName = &name
	}

	if err := co.DB.Create(&reply).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create reply", "code": "db_error"})
		return
	}

	co.DB.Model(&post).Update("last_activity_at", time.Now())

	c.JSON(http.StatusCreated, gin.H{"message": "Reply added successfully", "reply_id": reply.ID})
}

// AddReaction adds or removes a reaction to a post or reply.
// ROUTE: POST /api/v1/community/reactions
func (co *CommunityController) AddReaction(c *gin.Context) {
	var req AddReactionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data", "code": "validation_failed"})
		return
	}

	authedUser, _ := middleware.GetFullUserFromContext(c)

	reaction := models.CommunityReaction{
		UserID: authedUser.ID, TargetType: req.TargetType, TargetID: req.TargetID, ReactionType: req.ReactionType,
	}

	var existing models.CommunityReaction
	err := co.DB.Where(&reaction).First(&existing).Error

	if err == nil {
		co.DB.Delete(&existing)
		c.JSON(http.StatusOK, gin.H{"message": "Reaction removed", "action": "removed"})
	} else if errors.Is(err, gorm.ErrRecordNotFound) {
		co.DB.Create(&reaction)
		c.JSON(http.StatusCreated, gin.H{"message": "Reaction added", "action": "added"})
	} else {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error", "code": "db_error"})
	}
}

// --- Moderation & Admin Handlers ---

// ReportPost allows a user to report a post for review.
// ROUTE: POST /api/v1/community/posts/:postId/report
func (co *CommunityController) ReportPost(c *gin.Context) {
	postID, _ := uuid.Parse(c.Param("postId"))
	authedUser, _ := middleware.GetFullUserFromContext(c)

	var req ReportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request, reason is required", "code": "validation_failed"})
		return
	}

	note := "Reported by " + authedUser.ID.String() + " for: " + req.Reason + ". Notes: " + req.Notes

	result := co.DB.Model(&models.CommunityPost{}).Where("id = ?", postID).Update("moderation_notes", gorm.Expr("moderation_notes || ? || '\n'", note))
	if result.Error != nil || result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found", "code": "post_not_found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Post reported successfully. Our team will review it shortly."})
}

// ModeratePost allows an admin to change the status of a post.
// ROUTE: POST /api/v1/admin/community/posts/:postId/moderate
func (co *CommunityController) ModeratePost(c *gin.Context) {
	postID, _ := uuid.Parse(c.Param("postId"))
	var req ModerationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request", "code": "validation_failed"})
		return
	}

	updates := map[string]interface{}{
		"post_status":      req.NewStatus,
		"moderation_notes": gorm.Expr("moderation_notes || ? || '\n'", req.Notes),
	}
	if req.IsPinned != nil {
		updates["is_pinned"] = *req.IsPinned
	}

	result := co.DB.Model(&models.CommunityPost{}).Where("id = ?", postID).Updates(updates)
	if result.Error != nil || result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found", "code": "post_not_found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Post moderated successfully"})
}

// GetReportedPosts retrieves posts that have moderation notes.
// ROUTE: GET /api/v1/admin/community/reported-posts
func (co *CommunityController) GetReportedPosts(c *gin.Context) {
	c.Request.URL.RawQuery += "&status=reported"
	co.getPaginatedPosts(c)
}

// --- Helper Functions ---

func (co *CommunityController) getPaginatedPosts(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	offset := (page - 1) * limit

	query := co.DB.Model(&models.CommunityPost{}).Preload("Category").Preload("User")

	if catIDStr := c.Query("categoryId"); catIDStr != "" {
		query = query.Where("category_id = ?", catIDStr)
	}
	if search := c.Query("search"); search != "" {
		query = query.Where("post_title ILIKE ?", "%"+search+"%")
	}
	if status := c.Query("status"); status == "reported" {
		query = query.Where("moderation_notes IS NOT NULL AND moderation_notes != ''")
	} else {
		query = query.Where("post_status = 'published'")
	}

	switch c.DefaultQuery("sortBy", "activity") {
	case "popular":
		query = query.Order("reaction_count DESC, created_at DESC")
	case "latest":
		query = query.Order("created_at DESC")
	default: // activity
		query = query.Order("is_pinned DESC, last_activity_at DESC")
	}

	var posts []models.CommunityPost
	var totalCount int64

	query.Count(&totalCount)
	query.Limit(limit).Offset(offset).Find(&posts)

	responsePosts := []PostResponse{}
	for _, post := range posts {
		responsePosts = append(responsePosts, co.mapPostToResponse(post, nil))
	}

	c.JSON(http.StatusOK, gin.H{
		"data": responsePosts,
		"pagination": gin.H{
			"total_records": totalCount, "current_page": page, "page_size": limit,
			"total_pages": int(math.Ceil(float64(totalCount) / float64(limit))),
		},
	})
}

func (co *CommunityController) mapPostToResponse(post models.CommunityPost, replies []models.CommunityPostReply) PostResponse {
	resp := PostResponse{
		ID: post.ID, IsAnonymous: post.IsAnonymous,
		PostTitle: post.PostTitle, PostContent: post.PostContent, PostStatus: post.PostStatus,
		ContentWarnings: post.ContentWarnings, ViewCount: post.ViewCount, ReplyCount: post.ReplyCount,
		ReactionCount: post.ReactionCount, IsPinned: post.IsPinned, LastActivityAt: post.LastActivityAt,
		CreatedAt: post.CreatedAt, UpdatedAt: post.UpdatedAt,
	}

	// Perbaikan: Penanganan pointer untuk Category dan SentimentScore
	if post.Category != nil {
		resp.Category = *post.Category
	}
	if post.SentimentScore != nil {
		resp.SentimentScore = *post.SentimentScore
	}

	if post.IsAnonymous {
		resp.Author = nil
		resp.AnonymousDisplayName = post.AnonymousDisplayName
	} else if post.User != nil {
		resp.Author = &UserSummaryResponse{ID: post.User.ID, Username: post.User.Username, FullName: post.User.FullName}
	}

	if replies != nil {
		resp.Replies = []ReplyResponse{}
		for _, reply := range replies {
			replyResp := ReplyResponse{
				ID: reply.ID, PostID: reply.PostID, ParentReplyID: reply.ParentReplyID, IsAnonymous: reply.IsAnonymous,
				ReplyContent: reply.ReplyContent, ReplyLevel: reply.ReplyLevel, ReactionCount: reply.ReactionCount,
				CreatedAt: reply.CreatedAt, UpdatedAt: reply.UpdatedAt,
			}
			if reply.IsAnonymous {
				replyResp.Author = nil
				replyResp.AnonymousDisplayName = reply.AnonymousDisplayName
			} else if reply.User != nil {
				replyResp.Author = &UserSummaryResponse{ID: reply.User.ID, Username: reply.User.Username, FullName: reply.User.FullName}
			}
			resp.Replies = append(resp.Replies, replyResp)
		}
	}
	return resp
}

func generateAnonymousName() string {
	adjectives := []string{"Harapan", "Berani", "Baik", "Damai", "Kuat", "Lembut", "Bijak", "Tenang", "Ceria", "Peduli"}
	nouns := []string{"Jiwa", "Hati", "Semangat", "Sahabat", "Penolong", "Pendengar", "Pejuang", "Malaikat"}

	adjIndex := time.Now().UnixNano() % int64(len(adjectives))
	nounIndex := (time.Now().UnixNano() / int64(time.Second)) % int64(len(nouns))
	number := time.Now().Unix() % 1000

	return adjectives[adjIndex] + nouns[nounIndex] + strconv.Itoa(int(number))
}
