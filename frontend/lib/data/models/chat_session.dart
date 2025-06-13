// frontend/lib/data/models/chat_session.dart

class ChatSession {
  final String id;
  final String userId;
  final String? sessionTitle;
  final String triggerType;
  final String? triggerSourceId;
  final String? sessionStatus;
  final int? messageCount;
  final int? sessionDurationSeconds;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChatSession({
    required this.id,
    required this.userId,
    this.sessionTitle,
    required this.triggerType,
    this.triggerSourceId,
    this.sessionStatus,
    this.messageCount,
    this.sessionDurationSeconds,
    this.startedAt,
    this.endedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      // PERBAIKAN: Menambahkan fallback untuk semua field non-nullable
      id: json['id'] as String? ?? 'invalid_session_id',
      userId: json['user_id'] as String? ?? 'unknown_user',
      sessionTitle: json['session_title'] as String?,
      triggerType: json['trigger_type'] as String? ?? 'unknown',
      triggerSourceId: json['trigger_source_id'] as String?,
      sessionStatus: json['session_status'] as String?,
      messageCount: json['message_count'] as int?,
      sessionDurationSeconds: json['session_duration_seconds'] as int?,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'session_title': sessionTitle,
      'trigger_type': triggerType,
      'trigger_source_id': triggerSourceId,
      'session_status': sessionStatus,
      'message_count': messageCount,
      'session_duration_seconds': sessionDurationSeconds,
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}