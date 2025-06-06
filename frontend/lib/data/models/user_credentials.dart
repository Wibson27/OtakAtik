class UserCredentials {
  final String id;
  final String userId;
  final String passwordHash;
  final DateTime? passwordChangedAt;
  final int? failedLoginAttempts;
  final DateTime? lockedUntil;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserCredentials({
    required this.id,
    required this.userId,
    required this.passwordHash,
    this.passwordChangedAt,
    this.failedLoginAttempts,
    this.lockedUntil,
    this.createdAt,
    this.updatedAt,
  });

  factory UserCredentials.fromJson(Map<String, dynamic> json) {
    return UserCredentials(
      id: json['id'],
      userId: json['user_id'],
      passwordHash: json['password_hash'],
      passwordChangedAt: json['password_changed_at'] != null ? DateTime.parse(json['password_changed_at']) : null,
      failedLoginAttempts: json['failed_login_attempts'],
      lockedUntil: json['locked_until'] != null ? DateTime.parse(json['locked_until']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'password_hash': passwordHash,
      'password_changed_at': passwordChangedAt?.toIso8601String(),
      'failed_login_attempts': failedLoginAttempts,
      'locked_until': lockedUntil?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}