class UserSession {
  final String id;
  final String userId;
  final String sessionToken;
  final Map<String, dynamic>? deviceInfo;
  final String? ipAddress;
  final DateTime? lastActivityAt;
  final DateTime expiresAt;
  final bool? isActive;
  final DateTime? createdAt;

  UserSession({
    required this.id,
    required this.userId,
    required this.sessionToken,
    this.deviceInfo,
    this.ipAddress,
    this.lastActivityAt,
    required this.expiresAt,
    this.isActive,
    this.createdAt,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'],
      userId: json['user_id'],
      sessionToken: json['session_token'],
      deviceInfo: json['device_info'],
      ipAddress: json['ip_address'],
      lastActivityAt: json['last_activity_at'] != null ? DateTime.parse(json['last_activity_at']) : null,
      expiresAt: DateTime.parse(json['expires_at']),
      isActive: json['is_active'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'session_token': sessionToken,
      'device_info': deviceInfo,
      'ip_address': ipAddress,
      'last_activity_at': lastActivityAt?.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}