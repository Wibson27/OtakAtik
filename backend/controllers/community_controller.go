package controllers

import (
	"backend/models"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/gorm"
)

type CommunityController struct {
	DB *gorm.DB
}

// GetCategories returns all community categories
func (co *CommunityController) GetCategories(c *gin.Context) {
	var categories []models.CommunityCategory
	if err := co.DB.Where("is_active = ?", true).Order("display_order ASC, category_name ASC").Find(&categories).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch categories"})
		return
	}

	c.JSON(http.StatusOK, categories)
}

// CreatePost creates a new community post
func (co *CommunityController) CreatePost(c *gin.Context) {
	type CreatePostRequest struct {
		CategoryID           string         `json:"categoryId" binding:"required"`
		PostTitle            string         `json:"postTitle" binding:"required"`
		PostContent          string         `json:"postContent" binding:"required"`
		IsAnonymous          bool           `json:"isAnonymous"`
		AnonymousDisplayName string         `json:"anonymousDisplayName"`
		ContentWarnings      pq.StringArray `json:"contentWarnings"`
	}

	var req CreatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Get user ID from JWT token
	userIDStr := c.Param("userId") // Temporary: get from URL param
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	categoryID, err := uuid.Parse(req.CategoryID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid category ID"})
		return
	}

	// Verify category exists and is active
	var category models.CommunityCategory
	if err := co.DB.Where("id = ? AND is_active = ?", categoryID, true).First(&category).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Category not found or inactive"})
		return
	}

	// Get user preferences for anonymous default
	var preferences models.UserPreferences
	if err := co.DB.Where("user_id = ?", userID).First(&preferences).Error; err == nil {
		if !req.IsAnonymous && preferences.CommunityAnonymousDefault {
			req.IsAnonymous = true
		}
	}

	// Generate anonymous display name if needed and not provided
	if req.IsAnonymous && req.AnonymousDisplayName == "" {
		req.AnonymousDisplayName = generateAnonymousName()
	}

	// TODO: Analyze content for sentiment
	// sentiment := analyzeSentiment(req.PostContent)

	// Create post
	post := models.CommunityPost{
		UserID:      userID,
		CategoryID:  categoryID,
		PostTitle:   req.PostTitle,
		PostContent: req.PostContent,
		IsAnonymous: req.IsAnonymous,
		PostStatus:  "published",
		// SentimentScore: sentiment.Score,
		ContentWarnings: req.ContentWarnings,
	}

	if req.AnonymousDisplayName != "" {
		post.AnonymousDisplayName = &req.AnonymousDisplayName
	}

	if err := co.DB.Create(&post).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create post"})
		return
	}

	// Load the post with category info
	co.DB.Preload("Category").First(&post, post.ID)

	c.JSON(http.StatusCreated, gin.H{
		"message": "Post created successfully",
		"post":    post,
	})
}

// GetPosts returns posts with pagination and filtering
func (co *CommunityController) GetPosts(c *gin.Context) {
	// Pagination parameters
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	offset := (page - 1) * limit

	// Filter parameters
	categoryID := c.Query("categoryId")
	sortBy := c.DefaultQuery("sortBy", "latest") // latest, popular, activity
	search := c.Query("search")

	query := co.DB.Where("post_status = ?", "published")

	// Apply filters
	if categoryID != "" {
		if catID, err := uuid.Parse(categoryID); err == nil {
			query = query.Where("category_id = ?", catID)
		}
	}

	if search != "" {
		searchPattern := "%" + strings.ToLower(search) + "%"
		query = query.Where("LOWER(post_title) LIKE ? OR LOWER(post_content) LIKE ?", searchPattern, searchPattern)
	}

	// Apply sorting
	switch sortBy {
	case "popular":
		query = query.Order("reaction_count DESC, reply_count DESC, created_at DESC")
	case "activity":
		query = query.Order("last_activity_at DESC")
	default: // latest
		query = query.Order("is_pinned DESC, created_at DESC")
	}

	// Execute query with preloading
	var posts []models.CommunityPost
	if err := query.Preload("Category").Preload("User", func(db *gorm.DB) *gorm.DB {
		return db.Select("id, username, full_name") // Don't expose sensitive user data
	}).Limit(limit).Offset(offset).Find(&posts).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch posts"})
		return
	}

	// Get total count for pagination
	var totalCount int64
	countQuery := co.DB.Model(&models.CommunityPost{}).Where("post_status = ?", "published")
	if categoryID != "" {
		if catID, err := uuid.Parse(categoryID); err == nil {
			countQuery = countQuery.Where("category_id = ?", catID)
		}
	}
	if search != "" {
		searchPattern := "%" + strings.ToLower(search) + "%"
		countQuery = countQuery.Where("LOWER(post_title) LIKE ? OR LOWER(post_content) LIKE ?", searchPattern, searchPattern)
	}
	countQuery.Count(&totalCount)

	// Clean up user data for anonymous posts
	for i := range posts {
		if posts[i].IsAnonymous {
			posts[i].User = nil // Don't expose user info for anonymous posts
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"posts": posts,
		"pagination": gin.H{
			"page":       page,
			"limit":      limit,
			"totalCount": totalCount,
			"totalPages": (totalCount + int64(limit) - 1) / int64(limit),
		},
		"filters": gin.H{
			"categoryId": categoryID,
			"sortBy":     sortBy,
			"search":     search,
		},
	})
}

// GetPost returns a specific post with replies
func (co *CommunityController) GetPost(c *gin.Context) {
	postIDStr := c.Param("postId")
	postID, err := uuid.Parse(postIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	var post models.CommunityPost
	if err := co.DB.Preload("Category").
		Preload("User", func(db *gorm.DB) *gorm.DB {
			return db.Select("id, username, full_name")
		}).
		Preload("Replies", func(db *gorm.DB) *gorm.DB {
			return db.Where("is_deleted = ?", false).Order("created_at ASC")
		}).
		Preload("Replies.User", func(db *gorm.DB) *gorm.DB {
			return db.Select("id, username, full_name")
		}).
		Preload("Replies.ChildReplies", func(db *gorm.DB) *gorm.DB {
			return db.Where("is_deleted = ?", false).Order("created_at ASC")
		}).
		Preload("Replies.ChildReplies.User", func(db *gorm.DB) *gorm.DB {
			return db.Select("id, username, full_name")
		}).
		Where("id = ? AND post_status = ?", postID, "published").
		First(&post).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
		return
	}

	// Increment view count
	co.DB.Model(&post).Update("view_count", gorm.Expr("view_count + 1"))

	// Clean up user data for anonymous content
	if post.IsAnonymous {
		post.User = nil
	}

	for i := range post.Replies {
		if post.Replies[i].IsAnonymous {
			post.Replies[i].User = nil
		}
		for j := range post.Replies[i].ChildReplies {
			if post.Replies[i].ChildReplies[j].IsAnonymous {
				post.Replies[i].ChildReplies[j].User = nil
			}
		}
	}

	c.JSON(http.StatusOK, post)
}

// CreateReply creates a reply to a post or another reply
func (co *CommunityController) CreateReply(c *gin.Context) {
	type CreateReplyRequest struct {
		PostID               string `json:"postId" binding:"required"`
		ParentReplyID        string `json:"parentReplyId"` // Optional, for nested replies
		ReplyContent         string `json:"replyContent" binding:"required"`
		IsAnonymous          bool   `json:"isAnonymous"`
		AnonymousDisplayName string `json:"anonymousDisplayName"`
	}

	var req CreateReplyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Get user ID from JWT token
	userIDStr := c.Param("userId") // Temporary: get from URL param
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	postID, err := uuid.Parse(req.PostID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	// Verify post exists and is published
	var post models.CommunityPost
	if err := co.DB.Where("id = ? AND post_status = ?", postID, "published").First(&post).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
		return
	}

	// Handle parent reply if specified
	var parentReplyID *uuid.UUID
	replyLevel := 1
	if req.ParentReplyID != "" {
		if parentID, err := uuid.Parse(req.ParentReplyID); err == nil {
			var parentReply models.CommunityPostReply
			if err := co.DB.Where("id = ? AND post_id = ? AND is_deleted = ?", parentID, postID, false).First(&parentReply).Error; err == nil {
				parentReplyID = &parentID
				replyLevel = parentReply.ReplyLevel + 1
				// Limit nesting to 3 levels
				if replyLevel > 3 {
					replyLevel = 3
				}
			}
		}
	}

	// Get user preferences for anonymous default
	var preferences models.UserPreferences
	if err := co.DB.Where("user_id = ?", userID).First(&preferences).Error; err == nil {
		if !req.IsAnonymous && preferences.CommunityAnonymousDefault {
			req.IsAnonymous = true
		}
	}

	// Generate anonymous display name if needed and not provided
	if req.IsAnonymous && req.AnonymousDisplayName == "" {
		req.AnonymousDisplayName = generateAnonymousName()
	}

	// TODO: Analyze content for sentiment
	// sentiment := analyzeSentiment(req.ReplyContent)

	// Create reply
	reply := models.CommunityPostReply{
		PostID:        postID,
		ParentReplyID: parentReplyID,
		UserID:        userID,
		ReplyContent:  req.ReplyContent,
		IsAnonymous:   req.IsAnonymous,
		ReplyLevel:    replyLevel,
		// SentimentScore: sentiment.Score,
	}

	if req.AnonymousDisplayName != "" {
		reply.AnonymousDisplayName = &req.AnonymousDisplayName
	}

	if err := co.DB.Create(&reply).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create reply"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Reply created successfully",
		"reply":   reply,
	})
}

// AddReaction adds or removes a reaction to a post or reply
func (co *CommunityController) AddReaction(c *gin.Context) {
	type AddReactionRequest struct {
		TargetType   string `json:"targetType" binding:"required"` // post, reply
		TargetID     string `json:"targetId" binding:"required"`
		ReactionType string `json:"reactionType" binding:"required"` // support, relate, inspired, sending_love
	}

	var req AddReactionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Get user ID from JWT token
	userIDStr := c.Param("userId") // Temporary: get from URL param
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	targetID, err := uuid.Parse(req.TargetID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid target ID"})
		return
	}

	// Validate target type and reaction type
	validTargetTypes := []string{"post", "reply"}
	validReactionTypes := []string{"support", "relate", "inspired", "sending_love"}

	if !contains(validTargetTypes, req.TargetType) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid target type"})
		return
	}

	if !contains(validReactionTypes, req.ReactionType) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid reaction type"})
		return
	}

	// Verify target exists
	if req.TargetType == "post" {
		var post models.CommunityPost
		if err := co.DB.Where("id = ? AND post_status = ?", targetID, "published").First(&post).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
			return
		}
	} else {
		var reply models.CommunityPostReply
		if err := co.DB.Where("id = ? AND is_deleted = ?", targetID, false).First(&reply).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Reply not found"})
			return
		}
	}

	// Check if reaction already exists
	var existingReaction models.CommunityReaction
	if err := co.DB.Where("user_id = ? AND target_type = ? AND target_id = ? AND reaction_type = ?",
		userID, req.TargetType, targetID, req.ReactionType).First(&existingReaction).Error; err == nil {
		// Reaction exists, remove it (toggle)
		if err := co.DB.Delete(&existingReaction).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to remove reaction"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Reaction removed", "action": "removed"})
		return
	}

	// Create new reaction
	reaction := models.CommunityReaction{
		UserID:       userID,
		TargetType:   req.TargetType,
		TargetID:     targetID,
		ReactionType: req.ReactionType,
	}

	if err := co.DB.Create(&reaction).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add reaction"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message":  "Reaction added successfully",
		"action":   "added",
		"reaction": reaction,
	})
}

// GetUserPosts returns posts created by a specific user
func (co *CommunityController) GetUserPosts(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Pagination parameters
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	offset := (page - 1) * limit

	var posts []models.CommunityPost
	if err := co.DB.Preload("Category").
		Where("user_id = ? AND post_status = ?", userID, "published").
		Order("created_at DESC").
		Limit(limit).Offset(offset).
		Find(&posts).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch user posts"})
		return
	}

	// Get total count
	var totalCount int64
	co.DB.Model(&models.CommunityPost{}).Where("user_id = ? AND post_status = ?", userID, "published").Count(&totalCount)

	c.JSON(http.StatusOK, gin.H{
		"posts": posts,
		"pagination": gin.H{
			"page":       page,
			"limit":      limit,
			"totalCount": totalCount,
			"totalPages": (totalCount + int64(limit) - 1) / int64(limit),
		},
	})
}

// UpdatePost updates a post (only by the author)
func (co *CommunityController) UpdatePost(c *gin.Context) {
	postIDStr := c.Param("postId")
	postID, err := uuid.Parse(postIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	type UpdatePostRequest struct {
		PostTitle       *string         `json:"postTitle"`
		PostContent     *string         `json:"postContent"`
		ContentWarnings *pq.StringArray `json:"contentWarnings"`
	}

	var req UpdatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Get user ID from JWT token and verify ownership
	userIDStr := c.Param("userId") // Temporary: get from URL param
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Find post and verify ownership
	var post models.CommunityPost
	if err := co.DB.Where("id = ? AND user_id = ? AND post_status = ?", postID, userID, "published").First(&post).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found or not authorized"})
		return
	}

	// Update fields if provided
	if req.PostTitle != nil {
		post.PostTitle = *req.PostTitle
	}

	if req.PostContent != nil {
		post.PostContent = *req.PostContent
		// TODO: Re-analyze sentiment for updated content
	}

	if req.ContentWarnings != nil {
		post.ContentWarnings = *req.ContentWarnings
	}

	if err := co.DB.Save(&post).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update post"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Post updated successfully",
		"post":    post,
	})
}

// DeletePost soft deletes a post (only by the author)
func (co *CommunityController) DeletePost(c *gin.Context) {
	postIDStr := c.Param("postId")
	postID, err := uuid.Parse(postIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	// TODO: Get user ID from JWT token and verify ownership
	userIDStr := c.Param("userId") // Temporary: get from URL param
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Find post and verify ownership
	var post models.CommunityPost
	if err := co.DB.Where("id = ? AND user_id = ? AND post_status = ?", postID, userID, "published").First(&post).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found or not authorized"})
		return
	}

	// Soft delete by changing status
	post.PostStatus = "deleted"
	if err := co.DB.Save(&post).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete post"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Post deleted successfully"})
}

// Helper functions

// generateAnonymousName generates a random anonymous display name
func generateAnonymousName() string {
	adjectives := []string{"Hopeful", "Brave", "Kind", "Peaceful", "Strong", "Gentle", "Wise", "Calm", "Bright", "Caring"}
	nouns := []string{"Soul", "Heart", "Spirit", "Friend", "Helper", "Listener", "Supporter", "Companion", "Warrior", "Angel"}

	adj := adjectives[time.Now().UnixNano()%int64(len(adjectives))]
	noun := nouns[time.Now().UnixNano()%int64(len(nouns))]

	return adj + noun
}

// contains checks if a slice contains a string
func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
