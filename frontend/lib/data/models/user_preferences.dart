class UserPreferences {
  final String id;
  final String userId;
  final bool? notificationChat;
  final bool? notificationCommunity;
  final List<dynamic>? notificationSchedule; 
  final bool? communityAnonymousDefault;
  final bool? socialMediaMonitoring;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserPreferences({
    required this.id,
    required this.userId,
    this.notificationChat,
    this.notificationCommunity,
    this.notificationSchedule,
    this.communityAnonymousDefault,
    this.socialMediaMonitoring,
    this.createdAt,
    this.updatedAt,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      id: json['id'],
      userId: json['user_id'],
      notificationChat: json['notification_chat'],
      notificationCommunity: json['notification_community'],
      notificationSchedule: json['notification_schedule'],
      communityAnonymousDefault: json['community_anonymous_default'],
      socialMediaMonitoring: json['social_media_monitoring'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'notification_chat': notificationChat,
      'notification_community': notificationCommunity,
      'notification_schedule': notificationSchedule,
      'community_anonymous_default': communityAnonymousDefault,
      'social_media_monitoring': socialMediaMonitoring,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}