package controllers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"backend/config"
	"backend/middleware"
	"backend/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type AnalyticsController struct {
	DB  *gorm.DB
	Cfg *config.Config
}

func NewAnalyticsController(db *gorm.DB, cfg *config.Config) *AnalyticsController {
	return &AnalyticsController{DB: db, Cfg: cfg}
}

// --- DTOs and Request Structs ---

type RecordEventRequest struct {
	EventType   string                 `json:"event_type" binding:"required"`
	EventData   map[string]interface{} `json:"event_data"`
	UserSegment string                 `json:"user_segment"`
	DeviceType  string                 `json:"device_type"`
	AppVersion  string                 `json:"app_version"`
}

type SystemMetricsResponse struct {
	Metrics struct {
		Users struct {
			Total  int64 `json:"total"`
			Active int64 `json:"active"`
			New    int64 `json:"new"`
		} `json:"users"`
		Content struct {
			ChatSessions   int64 `json:"chat_sessions"`
			VocalEntries   int64 `json:"vocal_entries"`
			CommunityPosts int64 `json:"community_posts"`
		} `json:"content"`
	} `json:"metrics"`
	DateRange struct {
		StartDate time.Time `json:"start_date"`
		EndDate   time.Time `json:"end_date"`
	} `json:"date_range"`
}

type UserAnalyticsResponse struct {
	Activity struct {
		ChatSessions     int64 `json:"chat_sessions"`
		VocalEntries     int64 `json:"vocal_entries"`
		CommunityPosts   int64 `json:"community_posts"`
		CommunityReplies int64 `json:"community_replies"`
	} `json:"activity"`
	Wellbeing struct {
		AverageScore float64          `json:"average_score"`
		Trend        []WellbeingPoint `json:"trend"`
	} `json:"wellbeing"`
	Achievements []string `json:"achievements"`
}

type WellbeingPoint struct {
	Date  string  `json:"date"`
	Score float64 `json:"score"`
}


// --- Controller Handlers ---

// RecordEvent records a generic analytics event from the client.
func (a *AnalyticsController) RecordEvent(c *gin.Context) {
	var req RecordEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data", "code": "validation_failed"})
		return
	}
	eventDataJSON, _ := json.Marshal(req.EventData)

	event := models.SystemAnalytics{
		EventType:   req.EventType,
		EventData:   string(eventDataJSON),
		UserSegment: &req.UserSegment,
		DeviceType:  &req.DeviceType,
		AppVersion:  &req.AppVersion,
	}
	if err := a.DB.Create(&event).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to record event", "code": "db_error"})
		return
	}
	c.JSON(http.StatusAccepted, gin.H{"message": "Event recorded"})
}

// GetSystemMetrics returns system-wide metrics for the admin dashboard.
func (a *AnalyticsController) GetSystemMetrics(c *gin.Context) {
	days, _ := strconv.Atoi(c.DefaultQuery("days", "30"))
	startDate := time.Now().AddDate(0, 0, -days)

	var resp SystemMetricsResponse
	a.DB.Model(&models.User{}).Where("is_active = ?", true).Count(&resp.Metrics.Users.Total)
	a.DB.Model(&models.User{}).Where("last_active_at >= ? AND is_active = ?", startDate, true).Count(&resp.Metrics.Users.Active)
	a.DB.Model(&models.User{}).Where("created_at >= ?", startDate).Count(&resp.Metrics.Users.New)

	a.DB.Model(&models.ChatSession{}).Where("created_at >= ?", startDate).Count(&resp.Metrics.Content.ChatSessions)
	a.DB.Model(&models.VocalJournalEntry{}).Where("created_at >= ?", startDate).Count(&resp.Metrics.Content.VocalEntries)
	a.DB.Model(&models.CommunityPost{}).Where("created_at >= ? AND post_status = 'published'", startDate).Count(&resp.Metrics.Content.CommunityPosts)

	resp.DateRange.StartDate = startDate
	resp.DateRange.EndDate = time.Now()

	c.JSON(http.StatusOK, resp)
}

// GetUserAnalytics returns key activity metrics for a specific user.
func (a *AnalyticsController) GetUserAnalytics(c *gin.Context) {
	authedUser, _ := middleware.GetFullUserFromContext(c)
	days, _ := strconv.Atoi(c.DefaultQuery("days", "30"))
	startDate := time.Now().AddDate(0, 0, -days)

	var resp UserAnalyticsResponse
	a.DB.Model(&models.ChatSession{}).Where("user_id = ? AND created_at >= ?", authedUser.ID, startDate).Count(&resp.Activity.ChatSessions)
	a.DB.Model(&models.VocalJournalEntry{}).Where("user_id = ? AND created_at >= ?", authedUser.ID, startDate).Count(&resp.Activity.VocalEntries)
	a.DB.Model(&models.CommunityPost{}).Where("user_id = ? AND created_at >= ?", authedUser.ID, startDate).Count(&resp.Activity.CommunityPosts)
	a.DB.Model(&models.CommunityPostReply{}).Where("user_id = ? AND created_at >= ?", authedUser.ID, startDate).Count(&resp.Activity.CommunityReplies)

	// Get Wellbeing Trend
	wellbeingQuery := `
		SELECT DATE(vje.created_at) as date, AVG(vsa.overall_wellbeing_score) as score
		FROM vocal_journal_entries vje
		JOIN vocal_sentiment_analysis vsa ON vje.id = vsa.vocal_entry_id
		WHERE vje.user_id = ? AND vje.created_at >= ? AND vsa.overall_wellbeing_score IS NOT NULL
		GROUP BY DATE(vje.created_at) ORDER BY date ASC`
	a.DB.Raw(wellbeingQuery, authedUser.ID, startDate).Scan(&resp.Wellbeing.Trend)

	// Calculate average score from trend data
	if len(resp.Wellbeing.Trend) > 0 {
		var totalScore float64
		for _, point := range resp.Wellbeing.Trend {
			totalScore += point.Score
		}
		resp.Wellbeing.AverageScore = totalScore / float64(len(resp.Wellbeing.Trend))
	}

	// Calculate Achievements
	if resp.Activity.ChatSessions >= 10 {
		resp.Achievements = append(resp.Achievements, "Active Communicator")
	}
	if resp.Activity.VocalEntries >= 5 {
		resp.Achievements = append(resp.Achievements, "Voice Journal Explorer")
	}

	c.JSON(http.StatusOK, resp)
}


// GetWellbeingReport generates a comprehensive wellbeing report for the user.
func (a *AnalyticsController) GetWellbeingReport(c *gin.Context) {
	authedUser, _ := middleware.GetFullUserFromContext(c)

	// Logika dari file Anda dipertahankan sepenuhnya, karena sudah sangat baik.
	// Outputnya kini dimasukkan ke dalam DTO yang terstruktur.

	type WellbeingSummary struct {
		AvgWellbeingScore   float64 `json:"avg_wellbeing_score"`
		AvgEmotionalValence float64 `json:"avg_emotional_valence"`
		EntryCount          int64   `json:"entry_count"`
	}
	type ChatEngagement struct {
		SessionCount   int64   `json:"session_count"`
		MessageCount   int64   `json:"message_count"`
	}
	type CommunityEngagement struct {
		PostCount     int64 `json:"post_count"`
		ReplyCount    int64 `json:"reply_count"`
		ReactionCount int64 `json:"reaction_count"`
	}
	type WellbeingReportResponse struct {
		UserName        *string             `json:"user_name"`
		Wellbeing       WellbeingSummary    `json:"wellbeing"`
		Engagement      struct {
			Chat      ChatEngagement      `json:"chat"`
			Community CommunityEngagement `json:"community"`
		} `json:"engagement"`
		Recommendations []string `json:"recommendations"`
		GeneratedAt   time.Time `json:"generated_at"`
	}

	var reportResponse WellbeingReportResponse
	reportResponse.UserName = authedUser.FullName

	// Query-query dari file Anda digunakan di sini
	a.DB.Raw(`SELECT COALESCE(AVG(vsa.overall_wellbeing_score), 0) as avg_wellbeing_score, COALESCE(AVG(vsa.emotional_valence), 0) as avg_emotional_valence, COUNT(vje.id) as entry_count FROM vocal_journal_entries vje LEFT JOIN vocal_sentiment_analysis vsa ON vje.id = vsa.vocal_entry_id WHERE vje.user_id = ?`, authedUser.ID).Scan(&reportResponse.Wellbeing)
	a.DB.Raw(`SELECT COUNT(DISTINCT cs.id) as session_count, COUNT(cm.id) as message_count FROM chat_sessions cs LEFT JOIN chat_messages cm ON cs.id = cm.chat_session_id WHERE cs.user_id = ?`, authedUser.ID).Scan(&reportResponse.Engagement.Chat)
	a.DB.Model(&models.CommunityPost{}).Where("user_id = ?", authedUser.ID).Count(&reportResponse.Engagement.Community.PostCount)
	a.DB.Model(&models.CommunityPostReply{}).Where("user_id = ?", authedUser.ID).Count(&reportResponse.Engagement.Community.ReplyCount)

	// Logika rekomendasi dari file Anda
	if reportResponse.Wellbeing.AvgWellbeingScore > 0 && reportResponse.Wellbeing.AvgWellbeingScore < 5.0 {
		reportResponse.Recommendations = append(reportResponse.Recommendations, "Skor wellbeing Anda menunjukkan kebutuhan perhatian ekstra. Pertimbangkan untuk lebih sering check-in atau berbicara dengan profesional.")
	}
	if reportResponse.Engagement.Chat.SessionCount < 2 {
		reportResponse.Recommendations = append(reportResponse.Recommendations, "Berinteraksi dengan Tenang Assistant dapat membantu memberikan dukungan emosional secara rutin.")
	}

	reportResponse.GeneratedAt = time.Now()
	c.JSON(http.StatusOK, reportResponse)
}

// GetPlatformHealth provides a snapshot of platform health for admins.
func (a *AnalyticsController) GetPlatformHealth(c *gin.Context) {
	// (Logika dari file Anda dipertahankan, hanya outputnya diubah ke DTO)
	type PlatformHealthResponse struct {
		OverallStatus string `json:"overall_status"`
		Metrics       gin.H  `json:"metrics"`
		CheckedAt     time.Time `json:"checked_at"`
	}

	var activeUsers24h, totalUsers, failedJobs int64
	a.DB.Model(&models.User{}).Where("last_active_at >= ?", time.Now().Add(-24 * time.Hour)).Count(&activeUsers24h)
	a.DB.Model(&models.User{}).Count(&totalUsers)
	a.DB.Model(&models.VocalJournalEntry{}).Where("analysis_status = ?", "failed").Count(&failedJobs)

	healthStatus := "healthy"
	if failedJobs > 10 { healthStatus = "warning" }

	c.JSON(http.StatusOK, PlatformHealthResponse{
		OverallStatus: healthStatus,
		Metrics: gin.H{
			"active_users_24h": activeUsers24h,
			"total_users": totalUsers,
			"failed_analysis_jobs": failedJobs,
		},
		CheckedAt: time.Now(),
	})
}