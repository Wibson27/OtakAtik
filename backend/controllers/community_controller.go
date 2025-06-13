package controllers

import (
	"net/http"
	"time"

	"backend/middleware"
	"backend/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type CommunityController struct {
	DB *gorm.DB
}

func NewCommunityController(db *gorm.DB) *CommunityController {
	return &CommunityController{DB: db}
}

// --- DTOs (Data Transfer Objects) ---

type CommunityPostSummaryResponse struct {
	ID             uuid.UUID `json:"id"`
	Title          string    `json:"title"`
	ContentSnippet string    `json:"content_snippet"`
	AuthorName     string    `json:"author_name"`
	ReplyCount     int       `json:"reply_count"`
	ReactionCount  int       `json:"reaction_count"`
	LastActivityAt time.Time `json:"last_activity_at"`
}

type CommunityPostReplyResponse struct {
	ID            uuid.UUID `json:"ID"`
	AuthorName    string    `json:"author_name"`
	AuthorID      uuid.UUID `json:"author_id"`
	Content       string    `json:"content"`
	IsAnonymous   bool      `json:"is_anonymous"`
	ReactionCount int       `json:"reaction_count"`
	CreatedAt     time.Time `json:"CreatedAt"`
}

type CommunityPostDetailResponse struct {
	ID            uuid.UUID                    `json:"ID"`
	Title         string                       `json:"title"`
	Content       string                       `json:"content"`
	AuthorName    string                       `json:"author_name"`
	AuthorID      uuid.UUID                    `json:"author_id"`
	IsAnonymous   bool                         `json:"is_anonymous"`
	ReplyCount    int                          `json:"reply_count"`
	ReactionCount int                          `json:"reaction_count"`
	CreatedAt     time.Time                    `json:"CreatedAt"`
	Replies       []CommunityPostReplyResponse `json:"replies"`
}

type CreatePostRequest struct {
	CategoryID  string   `json:"category_id" binding:"required"`
	Title       string   `json:"title" binding:"required,min=5"`
	Content     string   `json:"content" binding:"required,min=10"`
	IsAnonymous bool     `json:"is_anonymous"`
	Tags        []string `json:"tags"`
}

type CreateReplyRequest struct {
	PostID      string `json:"post_id" binding:"required"`
	Content     string `json:"content" binding:"required,min=1"`
	IsAnonymous bool   `json:"is_anonymous"`
}

// --- Implementasi Fungsi Controller ---

func (cc *CommunityController) GetPublicPosts(c *gin.Context) {
	var posts []models.CommunityPost
	err := cc.DB.Preload("User").Order("last_activity_at DESC").Limit(20).Find(&posts, "post_status = ?", "published").Error
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mengambil data postingan"})
		return
	}
	var response []CommunityPostSummaryResponse
	for _, post := range posts {
		authorName := "Pengguna Anonim"
		if !post.IsAnonymous && post.User != nil && post.User.Username != nil {
			authorName = *post.User.Username
		}
		snippet := post.PostContent
		if len(snippet) > 100 {
			snippet = snippet[:100] + "..."
		}
		response = append(response, CommunityPostSummaryResponse{
			ID: post.ID, Title: post.PostTitle, ContentSnippet: snippet, AuthorName: authorName,
			ReplyCount: post.ReplyCount, ReactionCount: post.ReactionCount, LastActivityAt: post.LastActivityAt,
		})
	}
	c.JSON(http.StatusOK, gin.H{"data": response})
}

func (cc *CommunityController) GetPost(c *gin.Context) {
	postID, err := uuid.Parse(c.Param("postId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid Post ID"})
		return
	}

	var post models.CommunityPost
	err = cc.DB.Preload("User").Preload("Replies", func(db *gorm.DB) *gorm.DB {
		return db.Order("community_post_replies.created_at ASC")
	}).Preload("Replies.User").First(&post, "id = ?", postID).Error

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
		return
	}

	var replyResponses []CommunityPostReplyResponse
	for _, reply := range post.Replies {
		replyAuthorName := "Pengguna Anonim"
		if !reply.IsAnonymous && reply.User != nil {
			replyAuthorName = *reply.User.FullName
		}
		replyResponses = append(replyResponses, CommunityPostReplyResponse{
			ID: reply.ID, AuthorName: replyAuthorName, AuthorID: reply.UserID,
			Content: reply.ReplyContent, IsAnonymous: reply.IsAnonymous,
			ReactionCount: reply.ReactionCount, CreatedAt: reply.CreatedAt,
		})
	}

	authorName := "Pengguna Anonim"
	if !post.IsAnonymous && post.User != nil {
		authorName = *post.User.FullName
	}

	response := CommunityPostDetailResponse{
		ID: post.ID, Title: post.PostTitle, Content: post.PostContent, AuthorName: authorName,
		AuthorID: post.UserID, IsAnonymous: post.IsAnonymous, ReplyCount: post.ReplyCount,
		ReactionCount: post.ReactionCount, CreatedAt: post.CreatedAt, Replies: replyResponses,
	}
	c.JSON(http.StatusOK, gin.H{"data": response})
}

func (cc *CommunityController) CreatePost(c *gin.Context) {
	var req CreatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	authedUser, _ := middleware.GetFullUserFromContext(c)
	categoryID, _ := uuid.Parse(req.CategoryID)

	post := models.CommunityPost{
		UserID:      authedUser.ID,
		CategoryID:  categoryID,
		PostTitle:   req.Title,
		PostContent: req.Content,
		IsAnonymous: req.IsAnonymous,
	}
	if err := cc.DB.Create(&post).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create post"})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"data": post})
}

func (cc *CommunityController) CreateReply(c *gin.Context) {
	var req CreateReplyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data"})
		return
	}
	authedUser, _ := middleware.GetFullUserFromContext(c)
	postID, _ := uuid.Parse(req.PostID)

	reply := models.CommunityPostReply{
		PostID: postID, UserID: authedUser.ID, ReplyContent: req.Content, IsAnonymous: req.IsAnonymous,
	}
	if err := cc.DB.Create(&reply).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create reply"})
		return
	}

	cc.DB.Model(&reply).Preload("User").First(&reply)
	authorName := "Pengguna Anonim"
	if !reply.IsAnonymous && reply.User != nil {
		authorName = *reply.User.FullName
	}

	response := CommunityPostReplyResponse{
		ID: reply.ID, AuthorName: authorName, AuthorID: authedUser.ID,
		Content: reply.ReplyContent, CreatedAt: reply.CreatedAt,
	}
	c.JSON(http.StatusCreated, gin.H{"data": response})
}

// --- Placeholder untuk fungsi lainnya ---
func (cc *CommunityController) GetCategories(c *gin.Context) {
	c.JSON(200, gin.H{"message": "not implemented"})
}
func (cc *CommunityController) GetUserPosts(c *gin.Context) {
	c.JSON(200, gin.H{"message": "not implemented"})
}
func (cc *CommunityController) UpdatePost(c *gin.Context) {
	c.JSON(200, gin.H{"message": "not implemented"})
}
func (cc *CommunityController) DeletePost(c *gin.Context) {
	c.JSON(200, gin.H{"message": "not implemented"})
}
func (cc *CommunityController) AddReaction(c *gin.Context) {
	c.JSON(200, gin.H{"message": "not implemented"})
}
func (cc *CommunityController) ReportPost(c *gin.Context) {
	c.JSON(200, gin.H{"message": "not implemented"})
}
func (cc *CommunityController) GetReportedPosts(c *gin.Context) {
	c.JSON(200, gin.H{"message": "not implemented"})
}
func (cc *CommunityController) ModeratePost(c *gin.Context) {
	c.JSON(200, gin.H{"message": "not implemented"})
}
