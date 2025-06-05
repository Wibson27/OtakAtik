package controllers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"backend/models"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AnalyticsController struct {
	DB *gorm.DB
}

// RecordEvent records an analytics event
func (a *AnalyticsController) RecordEvent(c *gin.Context) {
	type RecordEventRequest struct {
		EventType   string                 `json:"eventType" binding:"required"`
		EventData   map[string]interface{} `json:"eventData"`
		UserSegment string                 `json:"userSegment"`
		DeviceType  string                 `json:"deviceType"`
		AppVersion  string                 `json:"appVersion"`
	}

	var req RecordEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Convert event data to JSON string
	eventDataJSON := "{}"
	if req.EventData != nil {
		if jsonBytes, err := json.Marshal(req.EventData); err == nil {
			eventDataJSON = string(jsonBytes)
		}
	}

	// Create analytics event
	event := models.SystemAnalytics{
		EventType:   req.EventType,
		EventData:   eventDataJSON,
		UserSegment: func() *string { if req.UserSegment != "" { return &req.UserSegment } else { return nil } }(),
		DeviceType:  func() *string { if req.DeviceType != "" { return &req.DeviceType } else { return nil } }(),
		AppVersion:  func() *string { if req.AppVersion != "" { return &req.AppVersion } else { return nil } }(),
	}

	if err := a.DB.Create(&event).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to record analytics event"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Analytics event recorded successfully"})
}

// GetSystemMetrics returns system-wide metrics and analytics
func (a *AnalyticsController) GetSystemMetrics(c *gin.Context) {
	// This endpoint would typically require admin authentication
	// TODO: Add admin authentication middleware

	// Get date range from query params (default to last 30 days)
	daysStr := c.DefaultQuery("days", "30")
	days, _ := strconv.Atoi(daysStr)
	if days <= 0 {
		days = 30
	}

	startDate := time.Now().AddDate(0, 0, -days)

	// User metrics
	var totalUsers, activeUsers, newUsers int64
	a.DB.Model(&models.User{}).Where("is_active = ?", true).Count(&totalUsers)
	a.DB.Model(&models.User{}).Where("last_active_at >= ? AND is_active = ?", startDate, true).Count(&activeUsers)
	a.DB.Model(&models.User{}).Where("created_at >= ? AND is_active = ?", startDate, true).Count(&newUsers)

	// Content metrics
	var totalChatSessions, totalVocalEntries, totalCommunityPosts int64
	a.DB.Model(&models.ChatSession{}).Where("created_at >= ?", startDate).Count(&totalChatSessions)
	a.DB.Model(&models.VocalJournalEntry{}).Where("created_at >= ?", startDate).Count(&totalVocalEntries)
	a.DB.Model(&models.CommunityPost{}).Where("created_at >= ? AND post_status = ?", startDate, "published").Count(&totalCommunityPosts)

	// Engagement metrics
	var totalMessages, totalReactions int64
	a.DB.Model(&models.ChatMessage{}).Where("created_at >= ?", startDate).Count(&totalMessages)
	a.DB.Model(&models.CommunityReaction{}).Where("created_at >= ?", startDate).Count(&totalReactions)

	// Most popular event types
	type EventCount struct {
		EventType string `json:"eventType"`
		Count     int64  `json:"count"`
	}

	var popularEvents []EventCount
	a.DB.Model(&models.SystemAnalytics{}).
		Select("event_type, COUNT(*) as count").
		Where("created_at >= ?", startDate).
		Group("event_type").
		Order("count DESC").
		Limit(10).
		Scan(&popularEvents)

	// User segments distribution
	type SegmentCount struct {
		UserSegment string `json:"userSegment"`
		Count       int64  `json:"count"`
	}

	var userSegments []SegmentCount
	a.DB.Model(&models.SystemAnalytics{}).
		Select("user_segment, COUNT(*) as count").
		Where("created_at >= ? AND user_segment IS NOT NULL", startDate).
		Group("user_segment").
		Order("count DESC").
		Scan(&userSegments)

	// Device type distribution
	type DeviceCount struct {
		DeviceType string `json:"deviceType"`
		Count      int64  `json:"count"`
	}

	var deviceTypes []DeviceCount
	a.DB.Model(&models.SystemAnalytics{}).
		Select("device_type, COUNT(*) as count").
		Where("created_at >= ? AND device_type IS NOT NULL", startDate).
		Group("device_type").
		Order("count DESC").
		Scan(&deviceTypes)

	// Daily active users trend
	type DailyMetric struct {
		Date  string `json:"date"`
		Count int64  `json:"count"`
	}

	var dailyActiveUsers []DailyMetric
	dauQuery := `
		SELECT DATE(last_active_at) as date, COUNT(DISTINCT id) as count
		FROM users
		WHERE last_active_at >= ? AND is_active = true
		GROUP BY DATE(last_active_at)
		ORDER BY date DESC
		LIMIT 30
	`
	a.DB.Raw(dauQuery, startDate).Scan(&dailyActiveUsers)

	c.JSON(http.StatusOK, gin.H{
		"metrics": gin.H{
			"users": gin.H{
				"total":  totalUsers,
				"active": activeUsers,
				"new":    newUsers,
			},
			"content": gin.H{
				"chatSessions":   totalChatSessions,
				"vocalEntries":   totalVocalEntries,
				"communityPosts": totalCommunityPosts,
			},
			"engagement": gin.H{
				"messages":  totalMessages,
				"reactions": totalReactions,
			},
		},
		"trends": gin.H{
			"dailyActiveUsers": dailyActiveUsers,
			"popularEvents":    popularEvents,
		},
		"demographics": gin.H{
			"userSegments": userSegments,
			"deviceTypes":  deviceTypes,
		},
		"dateRange": gin.H{
			"startDate": startDate,
			"endDate":   time.Now(),
			"days":      days,
		},
	})
}

// GetUserAnalytics returns analytics for a specific user
func (a *AnalyticsController) GetUserAnalytics(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Get date range from query params (default to last 30 days)
	daysStr := c.DefaultQuery("days", "30")
	days, _ := strconv.Atoi(daysStr)
	if days <= 0 {
		days = 30
	}

	startDate := time.Now().AddDate(0, 0, -days)

	// User activity metrics
	var chatSessionCount, vocalEntryCount, communityPostCount, communityReplyCount int64
	a.DB.Model(&models.ChatSession{}).Where("user_id = ? AND created_at >= ?", userID, startDate).Count(&chatSessionCount)
	a.DB.Model(&models.VocalJournalEntry{}).Where("user_id = ? AND created_at >= ?", userID, startDate).Count(&vocalEntryCount)
	a.DB.Model(&models.CommunityPost{}).Where("user_id = ? AND created_at >= ? AND post_status = ?", userID, startDate, "published").Count(&communityPostCount)
	a.DB.Model(&models.CommunityPostReply{}).Where("user_id = ? AND created_at >= ?", userID, startDate).Count(&communityReplyCount)

	// Message count
	var messageCount int64
	a.DB.Table("chat_messages").
		Joins("JOIN chat_sessions ON chat_messages.chat_session_id = chat_sessions.id").
		Where("chat_sessions.user_id = ? AND chat_messages.created_at >= ? AND chat_messages.sender_type = ?", userID, startDate, "user").
		Count(&messageCount)

	// Wellbeing trend from vocal entries
	type WellbeingPoint struct {
		Date  string  `json:"date"`
		Score float64 `json:"score"`
	}

	var wellbeingTrend []WellbeingPoint
	wellbeingQuery := `
		SELECT DATE(vje.created_at) as date, AVG(vsa.overall_wellbeing_score) as score
		FROM vocal_journal_entries vje
		JOIN vocal_sentiment_analysis vsa ON vje.id = vsa.vocal_entry_id
		WHERE vje.user_id = ? AND vje.created_at >= ? AND vsa.overall_wellbeing_score IS NOT NULL
		GROUP BY DATE(vje.created_at)
		ORDER BY date DESC
	`
	a.DB.Raw(wellbeingQuery, userID, startDate).Scan(&wellbeingTrend)

	// Activity timeline (daily activity)
	type ActivityPoint struct {
		Date     string `json:"date"`
		Activity int64  `json:"activity"`
	}

	var activityTimeline []ActivityPoint
	activityQuery := `
		SELECT date_series.date,
			COALESCE(
				(SELECT COUNT(*) FROM chat_sessions cs WHERE cs.user_id = ? AND DATE(cs.created_at) = date_series.date) +
				(SELECT COUNT(*) FROM vocal_journal_entries vje WHERE vje.user_id = ? AND DATE(vje.created_at) = date_series.date) +
				(SELECT COUNT(*) FROM community_posts cp WHERE cp.user_id = ? AND DATE(cp.created_at) = date_series.date AND cp.post_status = 'published') +
				(SELECT COUNT(*) FROM community_post_replies cpr WHERE cpr.user_id = ? AND DATE(cpr.created_at) = date_series.date),
				0
			) as activity
		FROM (
			SELECT DATE(?) + INTERVAL (seq.seq) DAY as date
			FROM (
				SELECT 0 as seq UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION
				SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION
				SELECT 10 UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION
				SELECT 15 UNION SELECT 16 UNION SELECT 17 UNION SELECT 18 UNION SELECT 19 UNION
				SELECT 20 UNION SELECT 21 UNION SELECT 22 UNION SELECT 23 UNION SELECT 24 UNION
				SELECT 25 UNION SELECT 26 UNION SELECT 27 UNION SELECT 28 UNION SELECT 29
			) seq
		) date_series
		WHERE date_series.date <= DATE(?)
		ORDER BY date_series.date DESC
	`
	a.DB.Raw(activityQuery, userID, userID, userID, userID, startDate, time.Now()).Scan(&activityTimeline)

	// Recent achievements/milestones
	achievements := []string{}
	if chatSessionCount >= 10 {
		achievements = append(achievements, "Active Communicator - 10+ chat sessions")
	}
	if vocalEntryCount >= 5 {
		achievements = append(achievements, "Voice Journal Explorer - 5+ vocal entries")
	}
	if communityPostCount >= 3 {
		achievements = append(achievements, "Community Contributor - 3+ posts")
	}
	if messageCount >= 50 {
		achievements = append(achievements, "Chat Enthusiast - 50+ messages")
	}

	// Calculate average wellbeing score
	var avgWellbeingScore float64
	if len(wellbeingTrend) > 0 {
		total := 0.0
		for _, point := range wellbeingTrend {
			total += point.Score
		}
		avgWellbeingScore = total / float64(len(wellbeingTrend))
	}

	c.JSON(http.StatusOK, gin.H{
		"analytics": gin.H{
			"activity": gin.H{
				"chatSessions":     chatSessionCount,
				"vocalEntries":     vocalEntryCount,
				"communityPosts":   communityPostCount,
				"communityReplies": communityReplyCount,
				"messages":         messageCount,
			},
			"wellbeing": gin.H{
				"averageScore": avgWellbeingScore,
				"trend":        wellbeingTrend,
			},
			"timeline": activityTimeline,
			"achievements": achievements,
		},
		"dateRange": gin.H{
			"startDate": startDate,
			"endDate":   time.Now(),
			"days":      days,
		},
	})
}

// GetWellbeingReport generates a comprehensive wellbeing report for a user
func (a *AnalyticsController) GetWellbeingReport(c *gin.Context) {
	userIDStr := c.Param("userId")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Get date range from query params (default to last 7 days for detailed report)
	daysStr := c.DefaultQuery("days", "7")
	days, _ := strconv.Atoi(daysStr)
	if days <= 0 {
		days = 7
	}

	startDate := time.Now().AddDate(0, 0, -days)

	// Vocal analysis summary
	type WellbeingSummary struct {
		AvgWellbeingScore   float64 `json:"avgWellbeingScore"`
		AvgEmotionalValence float64 `json:"avgEmotionalValence"`
		AvgEmotionalArousal float64 `json:"avgEmotionalArousal"`
		EntryCount          int64   `json:"entryCount"`
	}

	var wellbeingSummary WellbeingSummary
	summaryQuery := `
		SELECT
			COALESCE(AVG(vsa.overall_wellbeing_score), 0) as avg_wellbeing_score,
			COALESCE(AVG(vsa.emotional_valence), 0) as avg_emotional_valence,
			COALESCE(AVG(vsa.emotional_arousal), 0) as avg_emotional_arousal,
			COUNT(vje.id) as entry_count
		FROM vocal_journal_entries vje
		LEFT JOIN vocal_sentiment_analysis vsa ON vje.id = vsa.vocal_entry_id
		WHERE vje.user_id = ? AND vje.created_at >= ?
	`
	a.DB.Raw(summaryQuery, userID, startDate).Scan(&wellbeingSummary)

	// Chat engagement analysis
	type ChatEngagement struct {
		SessionCount    int64   `json:"sessionCount"`
		MessageCount    int64   `json:"messageCount"`
		AvgSessionLength float64 `json:"avgSessionLength"`
	}

	var chatEngagement ChatEngagement
	chatQuery := `
		SELECT
			COUNT(DISTINCT cs.id) as session_count,
			COUNT(cm.id) as message_count,
			COALESCE(AVG(cs.session_duration_seconds), 0) as avg_session_length
		FROM chat_sessions cs
		LEFT JOIN chat_messages cm ON cs.id = cm.chat_session_id AND cm.sender_type = 'user'
		WHERE cs.user_id = ? AND cs.created_at >= ?
	`
	a.DB.Raw(chatQuery, userID, startDate).Scan(&chatEngagement)

	// Community engagement
	type CommunityEngagement struct {
		PostCount     int64 `json:"postCount"`
		ReplyCount    int64 `json:"replyCount"`
		ReactionCount int64 `json:"reactionCount"`
	}

	var communityEngagement CommunityEngagement
	a.DB.Model(&models.CommunityPost{}).Where("user_id = ? AND created_at >= ? AND post_status = ?", userID, startDate, "published").Count(&communityEngagement.PostCount)
	a.DB.Model(&models.CommunityPostReply{}).Where("user_id = ? AND created_at >= ?", userID, startDate).Count(&communityEngagement.ReplyCount)
	a.DB.Model(&models.CommunityReaction{}).Where("user_id = ? AND created_at >= ?", userID, startDate).Count(&communityEngagement.ReactionCount)

	// Mood patterns (from vocal analysis)
	type MoodPattern struct {
		Emotion string  `json:"emotion"`
		Score   float64 `json:"score"`
	}

	// TODO: This would require parsing the detected_emotions JSONB field
	// For now, providing a placeholder structure
	moodPatterns := []MoodPattern{
		{"calm", 0.6},
		{"hopeful", 0.3},
		{"anxious", 0.1},
	}

	// Progress trends
	type ProgressMetric struct {
		MetricType  string    `json:"metricType"`
		Value       float64   `json:"value"`
		Date        time.Time `json:"date"`
		Trend       string    `json:"trend"` // "improving", "stable", "declining"
	}

	var progressMetrics []ProgressMetric
	metricsQuery := `
		SELECT metric_type, metric_value as value, metric_date as date
		FROM user_progress_metrics
		WHERE user_id = ? AND metric_date >= ?
		ORDER BY metric_type, metric_date DESC
	`
	a.DB.Raw(metricsQuery, userID, startDate).Scan(&progressMetrics)

	// Recommendations based on data
	recommendations := []string{}

	if wellbeingSummary.AvgWellbeingScore < 5.0 {
		recommendations = append(recommendations, "Consider scheduling more frequent check-ins or reaching out to a mental health professional")
	}

	if chatEngagement.SessionCount < 2 {
		recommendations = append(recommendations, "Try engaging with the AI chat more regularly for better emotional support")
	}

	if communityEngagement.PostCount == 0 && communityEngagement.ReplyCount == 0 {
		recommendations = append(recommendations, "Consider joining community discussions to connect with others")
	}

	if wellbeingSummary.EntryCount < 3 {
		recommendations = append(recommendations, "Regular voice journaling can help track your emotional patterns better")
	}

	c.JSON(http.StatusOK, gin.H{
		"report": gin.H{
			"period": gin.H{
				"startDate": startDate,
				"endDate":   time.Now(),
				"days":      days,
			},
			"wellbeing": wellbeingSummary,
			"engagement": gin.H{
				"chat":      chatEngagement,
				"community": communityEngagement,
			},
			"patterns": gin.H{
				"mood": moodPatterns,
			},
			"progress":        progressMetrics,
			"recommendations": recommendations,
		},
		"generatedAt": time.Now(),
	})
}

// GetPlatformHealth returns overall platform health metrics (admin only)
func (a *AnalyticsController) GetPlatformHealth(c *gin.Context) {
	// TODO: Add admin authentication middleware

	now := time.Now()
	last24h := now.Add(-24 * time.Hour)
	last7d := now.AddDate(0, 0, -7)

	// System health metrics
	var activeUsers24h, activeUsers7d, totalUsers int64
	a.DB.Model(&models.User{}).Where("last_active_at >= ? AND is_active = ?", last24h, true).Count(&activeUsers24h)
	a.DB.Model(&models.User{}).Where("last_active_at >= ? AND is_active = ?", last7d, true).Count(&activeUsers7d)
	a.DB.Model(&models.User{}).Where("is_active = ?", true).Count(&totalUsers)

	// Error rates (you might want to track these in a separate error log table)
	var failedVocalAnalysis, pendingVocalAnalysis int64
	a.DB.Model(&models.VocalJournalEntry{}).Where("analysis_status = ?", "failed").Count(&failedVocalAnalysis)
	a.DB.Model(&models.VocalJournalEntry{}).Where("analysis_status = ?", "pending").Count(&pendingVocalAnalysis)

	// Performance metrics
	type PerformanceMetric struct {
		AvgResponseTime float64 `json:"avgResponseTime"`
		MessageCount    int64   `json:"messageCount"`
	}

	var performance PerformanceMetric
	perfQuery := `
		SELECT
			COALESCE(AVG(response_time_ms), 0) as avg_response_time,
			COUNT(*) as message_count
		FROM chat_messages
		WHERE created_at >= ? AND sender_type = 'ai_bot' AND response_time_ms IS NOT NULL
	`
	a.DB.Raw(perfQuery, last24h).Scan(&performance)

	// Storage usage (approximate)
	var audioStorageCount int64
	a.DB.Model(&models.VocalJournalEntry{}).Count(&audioStorageCount)

	healthStatus := "healthy"
	issues := []string{}

	if float64(activeUsers24h)/float64(totalUsers) < 0.1 {
		healthStatus = "warning"
		issues = append(issues, "Low daily active user ratio")
	}

	if failedVocalAnalysis > 10 {
		healthStatus = "warning"
		issues = append(issues, "High vocal analysis failure rate")
	}

	if performance.AvgResponseTime > 5000 {
		healthStatus = "warning"
		issues = append(issues, "High AI response times")
	}

	c.JSON(http.StatusOK, gin.H{
		"health": gin.H{
			"status": healthStatus,
			"issues": issues,
		},
		"users": gin.H{
			"active24h": activeUsers24h,
			"active7d":  activeUsers7d,
			"total":     totalUsers,
			"retention": gin.H{
				"daily":  float64(activeUsers24h) / float64(totalUsers),
				"weekly": float64(activeUsers7d) / float64(totalUsers),
			},
		},
		"performance": gin.H{
			"avgResponseTime":      performance.AvgResponseTime,
			"messagesProcessed24h": performance.MessageCount,
		},
		"processing": gin.H{
			"vocalAnalysisFailed":  failedVocalAnalysis,
			"vocalAnalysisPending": pendingVocalAnalysis,
		},
		"storage": gin.H{
			"audioFiles": audioStorageCount,
		},
		"timestamp": now,
	})
}