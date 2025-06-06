class User {
  final String id;
  final String? email; 
  final String? username;
  final String? fullName;
  final DateTime? dateOfBirth;
  final String? timezone;
  final String? privacyLevel;
  final bool? isActive;
  final DateTime? emailVerifiedAt;
  final DateTime? lastActiveAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  User({
    required this.id,
    this.email,
    this.username,
    this.fullName,
    this.dateOfBirth,
    this.timezone,
    this.privacyLevel,
    this.isActive,
    this.emailVerifiedAt,
    this.lastActiveAt,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      fullName: json['full_name'],
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
      timezone: json['timezone'],
      privacyLevel: json['privacy_level'],
      isActive: json['is_active'],
      emailVerifiedAt: json['email_verified_at'] != null ? DateTime.parse(json['email_verified_at']) : null,
      lastActiveAt: json['last_active_at'] != null ? DateTime.parse(json['last_active_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'timezone': timezone,
      'privacy_level': privacyLevel,
      'is_active': isActive,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}