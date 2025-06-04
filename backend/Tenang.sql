-- ======================================================================================
-- TENANG.IN DATABASE SCHEMA
-- Platform Kesehatan Mental - Database Schema Lengkap
-- PostgreSQL Version 14+
-- ======================================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ======================================================================================
-- USER MANAGEMENT TABLES
-- ======================================================================================

-- Tabel users - Informasi dasar pengguna
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE,
    full_name VARCHAR(100),
    date_of_birth DATE,
    timezone VARCHAR(50) DEFAULT 'Asia/Jakarta',
    privacy_level VARCHAR(20) DEFAULT 'standard' CHECK (privacy_level IN ('minimal', 'standard', 'full')),
    is_active BOOLEAN DEFAULT true,
    email_verified_at TIMESTAMP,
    last_active_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    CONSTRAINT check_user_age CHECK (date_of_birth IS NULL OR date_of_birth <= CURRENT_DATE - INTERVAL '13 years')
);

-- Tabel user_credentials - Kredensial terpisah untuk keamanan
CREATE TABLE user_credentials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    password_hash VARCHAR(255) NOT NULL,
    password_changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel user_preferences - Preferensi yang dapat dikustomisasi
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_chat BOOLEAN DEFAULT true,
    notification_community BOOLEAN DEFAULT true,
    notification_schedule JSONB DEFAULT '[]',
    community_anonymous_default BOOLEAN DEFAULT false,
    social_media_monitoring BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel user_sessions - Tracking sesi aktif
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) NOT NULL UNIQUE,
    device_info JSONB DEFAULT '{}',
    ip_address INET,
    last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ======================================================================================
-- CHATBOT & CONVERSATION TABLES
-- ======================================================================================

-- Tabel chat_sessions - Metadata untuk setiap sesi obrolan
CREATE TABLE chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_title VARCHAR(200),
    trigger_type VARCHAR(30) NOT NULL CHECK (trigger_type IN ('user_initiated', 'social_media_alert', 'scheduled_checkin', 'crisis_intervention')),
    trigger_source_id UUID,
    session_status VARCHAR(20) DEFAULT 'active' CHECK (session_status IN ('active', 'completed', 'abandoned')),
    message_count INTEGER DEFAULT 0,
    session_duration_seconds INTEGER,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel chat_messages - Pesan individual dalam sesi
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_session_id UUID NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
    sender_type VARCHAR(10) NOT NULL CHECK (sender_type IN ('user', 'ai_bot')),
    message_content TEXT NOT NULL,
    message_metadata JSONB DEFAULT '{}',
    sentiment_score DECIMAL(3,2) CHECK (sentiment_score BETWEEN -1 AND 1),
    emotion_detected VARCHAR(20),
    response_time_ms INTEGER,
    is_encrypted BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel scheduled_checkins - Jadwal check-in otomatis
CREATE TABLE scheduled_checkins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    schedule_name VARCHAR(100),
    time_of_day TIME NOT NULL,
    days_of_week INTEGER[] NOT NULL CHECK (array_length(days_of_week, 1) > 0),
    is_active BOOLEAN DEFAULT true,
    greeting_template VARCHAR(500),
    last_triggered_at TIMESTAMP,
    next_trigger_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ======================================================================================
-- VOCAL JOURNAL TABLES
-- ======================================================================================

-- Tabel vocal_journal_entries - Metadata rekaman suara
CREATE TABLE vocal_journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entry_title VARCHAR(200),
    duration_seconds INTEGER NOT NULL,
    file_size_bytes BIGINT,
    audio_file_path VARCHAR(500) NOT NULL,
    audio_format VARCHAR(10) DEFAULT 'wav' CHECK (audio_format IN ('wav', 'mp3', 'm4a')),
    recording_quality VARCHAR(20) DEFAULT 'good' CHECK (recording_quality IN ('poor', 'fair', 'good', 'excellent')),
    ambient_noise_level VARCHAR(20) DEFAULT 'low' CHECK (ambient_noise_level IN ('low', 'medium', 'high')),
    user_tags TEXT[],
    transcription_enabled BOOLEAN DEFAULT true,
    analysis_status VARCHAR(20) DEFAULT 'pending' CHECK (analysis_status IN ('pending', 'processing', 'completed', 'failed')),
    privacy_level VARCHAR(20) DEFAULT 'private' CHECK (privacy_level IN ('private', 'anonymous_research')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel vocal_transcriptions - Hasil speech-to-text
CREATE TABLE vocal_transcriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vocal_entry_id UUID NOT NULL REFERENCES vocal_journal_entries(id) ON DELETE CASCADE,
    transcription_text TEXT NOT NULL,
    confidence_score DECIMAL(3,2) CHECK (confidence_score BETWEEN 0 AND 1),
    language_detected VARCHAR(10),
    word_count INTEGER,
    processing_service VARCHAR(50) DEFAULT 'azure_speech',
    processing_duration_ms INTEGER,
    is_encrypted BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel vocal_sentiment_analysis - Hasil analisis AI
CREATE TABLE vocal_sentiment_analysis (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vocal_entry_id UUID NOT NULL REFERENCES vocal_journal_entries(id) ON DELETE CASCADE,
    overall_wellbeing_score DECIMAL(3,1) CHECK (overall_wellbeing_score BETWEEN 1 AND 10),
    wellbeing_category VARCHAR(50),
    emotional_valence DECIMAL(3,2) CHECK (emotional_valence BETWEEN -1 AND 1),
    emotional_arousal DECIMAL(3,2) CHECK (emotional_arousal BETWEEN -1 AND 1),
    emotional_dominance DECIMAL(3,2) CHECK (emotional_dominance BETWEEN -1 AND 1),
    detected_emotions JSONB DEFAULT '{}',
    detected_themes TEXT[],
    stress_indicators JSONB DEFAULT '{}',
    voice_features JSONB DEFAULT '{}',
    analysis_model_version VARCHAR(50),
    confidence_score DECIMAL(3,2) CHECK (confidence_score BETWEEN 0 AND 1),
    processing_duration_ms INTEGER,
    reflection_prompt TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ======================================================================================
-- COMMUNITY FEATURES TABLES
-- ======================================================================================

-- Tabel community_categories - Kategori forum
CREATE TABLE community_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_name VARCHAR(100) NOT NULL UNIQUE,
    category_description TEXT,
    category_color VARCHAR(7) DEFAULT '#6B73FF',
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    moderator_required BOOLEAN DEFAULT false,
    post_guidelines TEXT,
    icon_name VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel community_posts - Postingan pengguna di forum
CREATE TABLE community_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES community_categories(id),
    post_title VARCHAR(200) NOT NULL,
    post_content TEXT NOT NULL,
    is_anonymous BOOLEAN DEFAULT false,
    anonymous_display_name VARCHAR(50),
    post_status VARCHAR(20) DEFAULT 'published' CHECK (post_status IN ('draft', 'published', 'hidden', 'deleted')),
    sentiment_score DECIMAL(3,2) CHECK (sentiment_score BETWEEN -1 AND 1),
    content_warnings TEXT[],
    view_count INTEGER DEFAULT 0,
    reply_count INTEGER DEFAULT 0,
    reaction_count INTEGER DEFAULT 0,
    last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_pinned BOOLEAN DEFAULT false,
    moderation_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel community_post_replies - Balasan bersarang untuk postingan
CREATE TABLE community_post_replies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
    parent_reply_id UUID REFERENCES community_post_replies(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reply_content TEXT NOT NULL,
    is_anonymous BOOLEAN DEFAULT false,
    anonymous_display_name VARCHAR(50),
    reply_level INTEGER DEFAULT 1 CHECK (reply_level BETWEEN 1 AND 3),
    sentiment_score DECIMAL(3,2) CHECK (sentiment_score BETWEEN -1 AND 1),
    reaction_count INTEGER DEFAULT 0,
    is_deleted BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel community_reactions - Reaksi pada postingan dan balasan
CREATE TABLE community_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type VARCHAR(20) NOT NULL CHECK (target_type IN ('post', 'reply')),
    target_id UUID NOT NULL,
    reaction_type VARCHAR(20) NOT NULL CHECK (reaction_type IN ('support', 'relate', 'inspired', 'sending_love')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, target_type, target_id, reaction_type)
);

-- ======================================================================================
-- SOCIAL MEDIA INTEGRATION TABLES
-- ======================================================================================

-- Tabel social_media_accounts - Akun media sosial yang terhubung
CREATE TABLE social_media_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    platform VARCHAR(20) NOT NULL CHECK (platform IN ('instagram', 'twitter', 'facebook', 'tiktok')),
    platform_user_id VARCHAR(100) NOT NULL,
    platform_username VARCHAR(100),
    access_token_encrypted TEXT,
    token_expires_at TIMESTAMP,
    monitoring_enabled BOOLEAN DEFAULT false,
    last_sync_at TIMESTAMP,
    webhook_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, platform)
);

-- Tabel social_media_posts_monitored - Metadata dari postingan yang dipantau
CREATE TABLE social_media_posts_monitored (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    social_account_id UUID NOT NULL REFERENCES social_media_accounts(id) ON DELETE CASCADE,
    platform_post_id VARCHAR(200) NOT NULL,
    post_type VARCHAR(20) CHECK (post_type IN ('text', 'image', 'video', 'story')),
    post_timestamp TIMESTAMP NOT NULL,
    post_metadata JSONB DEFAULT '{}',
    content_hash VARCHAR(64),
    sentiment_processed BOOLEAN DEFAULT false,
    privacy_level VARCHAR(20) DEFAULT 'private',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(social_account_id, platform_post_id)
);

-- ======================================================================================
-- SUPPORT TABLES
-- ======================================================================================

-- Tabel notifications - Sistem notifikasi terpusat
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(30) NOT NULL CHECK (notification_type IN ('chat_checkin', 'community_reply', 'community_reaction', 'social_media_alert', 'wellness_reminder')),
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    action_url VARCHAR(500),
    action_data JSONB DEFAULT '{}',
    priority VARCHAR(10) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    delivery_method VARCHAR(20) DEFAULT 'push' CHECK (delivery_method IN ('push', 'email', 'in_app')),
    is_read BOOLEAN DEFAULT false,
    is_sent BOOLEAN DEFAULT false,
    scheduled_for TIMESTAMP,
    sent_at TIMESTAMP,
    read_at TIMESTAMP,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel user_progress_metrics - Tracking progress teragregasi
CREATE TABLE user_progress_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    metric_type VARCHAR(30) NOT NULL CHECK (metric_type IN ('wellbeing_trend_vocal', 'chat_engagement', 'community_participation', 'overall_wellness')),
    metric_value DECIMAL(10,2) NOT NULL,
    metric_date DATE NOT NULL,
    calculation_data JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, metric_type, metric_date)
);

-- Tabel system_analytics - Analytics penggunaan anonim
CREATE TABLE system_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB NOT NULL DEFAULT '{}',
    user_segment VARCHAR(30),
    device_type VARCHAR(20),
    app_version VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel audit_logs - Trail audit komprehensif
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(50) NOT NULL,
    table_name VARCHAR(50),
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ======================================================================================
-- INDEXES UNTUK PERFORMANCE
-- ======================================================================================

-- User management indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(is_active, deleted_at);
CREATE INDEX idx_users_last_active ON users(last_active_at);
CREATE UNIQUE INDEX idx_users_username ON users(username) WHERE username IS NOT NULL;

-- Chat system indexes
CREATE INDEX idx_chat_sessions_user_created ON chat_sessions(user_id, created_at DESC);
CREATE INDEX idx_chat_messages_session_created ON chat_messages(chat_session_id, created_at);
CREATE INDEX idx_scheduled_checkins_user_active ON scheduled_checkins(user_id, is_active);

-- Vocal journal indexes
CREATE INDEX idx_vocal_entries_user_created ON vocal_journal_entries(user_id, created_at DESC);
CREATE INDEX idx_vocal_entries_analysis_status ON vocal_journal_entries(analysis_status);
CREATE INDEX idx_vocal_transcriptions_entry ON vocal_transcriptions(vocal_entry_id);
CREATE INDEX idx_vocal_analysis_entry ON vocal_sentiment_analysis(vocal_entry_id);

-- Community indexes
CREATE INDEX idx_community_posts_category_activity ON community_posts(category_id, last_activity_at DESC);
CREATE INDEX idx_community_posts_status_created ON community_posts(post_status, created_at DESC);
CREATE INDEX idx_community_replies_post_created ON community_post_replies(post_id, created_at);
CREATE INDEX idx_community_reactions_target ON community_reactions(target_type, target_id);

-- Social media indexes
CREATE UNIQUE INDEX idx_social_accounts_user_platform ON social_media_accounts(user_id, platform);
CREATE INDEX idx_social_posts_account_timestamp ON social_media_posts_monitored(social_account_id, post_timestamp DESC);

-- Notification indexes
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read, created_at DESC);
CREATE INDEX idx_notifications_scheduled ON notifications(scheduled_for) WHERE scheduled_for IS NOT NULL;

-- Analytics indexes
CREATE INDEX idx_analytics_type_created ON system_analytics(event_type, created_at);
CREATE INDEX idx_progress_metrics_user_type ON user_progress_metrics(user_id, metric_type, metric_date DESC);

-- Audit indexes
CREATE INDEX idx_audit_logs_user_created ON audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_logs_table_created ON audit_logs(table_name, created_at DESC);

-- ======================================================================================
-- PARTIAL INDEXES UNTUK EFISIENSI
-- ======================================================================================

-- Pengguna aktif saja
CREATE INDEX idx_users_active_last_activity ON users(last_active_at DESC)
WHERE is_active = true AND deleted_at IS NULL;

-- Postingan yang dipublikasi saja
CREATE INDEX idx_posts_published_activity ON community_posts(last_activity_at DESC)
WHERE post_status = 'published';

-- Analisis yang pending saja
CREATE INDEX idx_vocal_pending_analysis ON vocal_journal_entries(created_at)
WHERE analysis_status = 'pending';

-- Notifikasi yang belum dibaca saja
CREATE INDEX idx_notifications_unread ON notifications(user_id, created_at DESC)
WHERE is_read = false;

-- ======================================================================================
-- TRIGGERS UNTUK UPDATE OTOMATIS
-- ======================================================================================

-- Fungsi untuk update timestamp updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Terapkan trigger updated_at ke semua tabel yang relevan
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_credentials_updated_at BEFORE UPDATE ON user_credentials
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_sessions_updated_at BEFORE UPDATE ON chat_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_scheduled_checkins_updated_at BEFORE UPDATE ON scheduled_checkins
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vocal_entries_updated_at BEFORE UPDATE ON vocal_journal_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_community_categories_updated_at BEFORE UPDATE ON community_categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_community_posts_updated_at BEFORE UPDATE ON community_posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_community_replies_updated_at BEFORE UPDATE ON community_post_replies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_social_accounts_updated_at BEFORE UPDATE ON social_media_accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Fungsi untuk update jumlah pesan dalam chat sessions
CREATE OR REPLACE FUNCTION update_chat_session_message_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE chat_sessions SET
            message_count = message_count + 1,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.chat_session_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE chat_sessions SET
            message_count = message_count - 1,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = OLD.chat_session_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

CREATE TRIGGER update_message_count_trigger
    AFTER INSERT OR DELETE ON chat_messages
    FOR EACH ROW EXECUTE FUNCTION update_chat_session_message_count();

-- Fungsi untuk update jumlah balasan dalam community posts
CREATE OR REPLACE FUNCTION update_post_reply_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE community_posts SET
            reply_count = reply_count + 1,
            last_activity_at = CURRENT_TIMESTAMP,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE community_posts SET
            reply_count = reply_count - 1,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = OLD.post_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

CREATE TRIGGER update_reply_count_trigger
    AFTER INSERT OR DELETE ON community_post_replies
    FOR EACH ROW EXECUTE FUNCTION update_post_reply_count();

-- Fungsi untuk update jumlah reaksi
CREATE OR REPLACE FUNCTION update_reaction_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.target_type = 'post' THEN
            UPDATE community_posts SET reaction_count = reaction_count + 1 WHERE id = NEW.target_id;
        ELSIF NEW.target_type = 'reply' THEN
            UPDATE community_post_replies SET reaction_count = reaction_count + 1 WHERE id = NEW.target_id;
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.target_type = 'post' THEN
            UPDATE community_posts SET reaction_count = reaction_count - 1 WHERE id = OLD.target_id;
        ELSIF OLD.target_type = 'reply' THEN
            UPDATE community_post_replies SET reaction_count = reaction_count - 1 WHERE id = OLD.target_id;
        END IF;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

CREATE TRIGGER update_reaction_counts_trigger
    AFTER INSERT OR DELETE ON community_reactions
    FOR EACH ROW EXECUTE FUNCTION update_reaction_counts();

-- ======================================================================================
-- FUNGSI AUDIT TRIGGER
-- ======================================================================================

-- Fungsi untuk audit logging
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    current_user_id_val UUID;
BEGIN
    -- Ambil current user ID dari session (akan di-set oleh aplikasi)
    current_user_id_val := current_setting('app.current_user_id', true)::UUID;

    INSERT INTO audit_logs (
        user_id, action, table_name, record_id,
        old_values, new_values, created_at
    ) VALUES (
        current_user_id_val,
        TG_OP,
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        CASE WHEN TG_OP = 'DELETE' THEN row_to_json(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN row_to_json(NEW) ELSE NULL END,
        CURRENT_TIMESTAMP
    );
    RETURN COALESCE(NEW, OLD);
EXCEPTION WHEN OTHERS THEN
    -- Lanjutkan operasi meski audit gagal
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Terapkan audit trigger ke tabel sensitif
CREATE TRIGGER audit_users AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_user_credentials AFTER INSERT OR UPDATE OR DELETE ON user_credentials
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_vocal_entries AFTER INSERT OR UPDATE OR DELETE ON vocal_journal_entries
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- ======================================================================================
-- DATA AWAL
-- ======================================================================================

-- Insert kategori komunitas default
INSERT INTO community_categories (category_name, category_description, category_color, display_order, icon_name) VALUES
('Mengelola Kecemasan', 'Diskusi tentang cara mengatasi dan mengelola kecemasan sehari-hari', '#FF6B6B', 1, 'heart'),
('Tips Produktivitas & Stress', 'Berbagi tips untuk tetap produktif sambil mengelola stress', '#4ECDC4', 2, 'target'),
('Cerita Inspiratif', 'Bagikan cerita inspiratif dan motivasi untuk sesama', '#45B7D1', 3, 'star'),
('Support Group', 'Ruang untuk saling mendukung dan menguatkan', '#96CEB4', 4, 'users'),
('Self Care Tips', 'Tips dan trik untuk merawat diri sendiri', '#FFEAA7', 5, 'heart-handshake'),
('Professional Help Experience', 'Diskusi tentang pengalaman dengan bantuan profesional', '#DDA0DD', 6, 'user-doctor');

-- ======================================================================================
-- ROW LEVEL SECURITY (RLS)
-- ======================================================================================

-- Enable RLS pada tabel sensitif
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE vocal_journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE vocal_transcriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE vocal_sentiment_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_post_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Contoh policy: Users hanya bisa akses data mereka sendiri
CREATE POLICY user_data_isolation_chat ON chat_messages
    FOR ALL TO authenticated_users
    USING (chat_session_id IN (SELECT id FROM chat_sessions WHERE user_id = current_setting('app.current_user_id')::UUID));

CREATE POLICY user_data_isolation_vocal ON vocal_journal_entries
    FOR ALL TO authenticated_users
    USING (user_id = current_setting('app.current_user_id')::UUID);

-- ======================================================================================
-- FUNGSI MAINTENANCE DATABASE
-- ======================================================================================

-- Fungsi untuk cleanup data lama
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS void AS $$
BEGIN
    -- Hapus notifikasi lama (30 hari)
    DELETE FROM notifications
    WHERE created_at < NOW() - INTERVAL '30 days'
    AND is_read = true;

    -- Hapus analytics lama (90 hari)
    DELETE FROM system_analytics
    WHERE created_at < NOW() - INTERVAL '90 days';

    -- Hapus audit logs lama (1 tahun)
    DELETE FROM audit_logs
    WHERE created_at < NOW() - INTERVAL '1 year';

    RAISE NOTICE 'Cleanup data lama selesai';
END;
$$ LANGUAGE plpgsql;

-- ======================================================================================
-- VIEWS UNTUK QUERY UMUM
-- ======================================================================================

-- View untuk statistik dashboard pengguna
CREATE VIEW user_dashboard_stats AS
SELECT
    u.id as user_id,
    u.full_name,
    COUNT(DISTINCT cs.id) as total_chat_sessions,
    COUNT(DISTINCT vje.id) as total_vocal_entries,
    COUNT(DISTINCT cp.id) as total_community_posts,
    AVG(vsa.overall_wellbeing_score) as avg_wellbeing_score,
    MAX(u.last_active_at) as last_active
FROM users u
LEFT JOIN chat_sessions cs ON u.id = cs.user_id
LEFT JOIN vocal_journal_entries vje ON u.id = vje.user_id
LEFT JOIN community_posts cp ON u.id = cp.user_id
LEFT JOIN vocal_sentiment_analysis vsa ON vje.id = vsa.vocal_entry_id
WHERE u.is_active = true AND u.deleted_at IS NULL
GROUP BY u.id, u.full_name;

-- View untuk aktivitas komunitas terbaru
CREATE VIEW recent_community_activity AS
SELECT
    cp.id,
    cp.post_title,
    cp.created_at,
    cp.last_activity_at,
    cp.reply_count,
    cp.reaction_count,
    cc.category_name,
    CASE
        WHEN cp.is_anonymous THEN cp.anonymous_display_name
        ELSE u.username
    END as author_name
FROM community_posts cp
JOIN community_categories cc ON cp.category_id = cc.id
LEFT JOIN users u ON cp.user_id = u.id
WHERE cp.post_status = 'published'
ORDER BY cp.last_activity_at DESC;

-- ======================================================================================
-- OPTIMISASI PERFORMANCE
-- ======================================================================================

-- Analyze tabel untuk optimal query planning
ANALYZE users;
ANALYZE chat_sessions;
ANALYZE chat_messages;
ANALYZE vocal_journal_entries;
ANALYZE community_posts;
ANALYZE community_post_replies;

-- ======================================================================================
-- SCHEMA SELESAI
-- ======================================================================================

COMMENT ON DATABASE tenang_in IS 'Database Platform Kesehatan Mental Tenang.in - Schema komprehensif untuk aplikasi dukungan kesehatan mental';

-- Akhir schema


