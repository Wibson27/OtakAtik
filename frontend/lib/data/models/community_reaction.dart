class CommunityReaction {
  final String id;
  final String userId;
  final String targetType;
  final String targetId;
  final String reactionType;
  final DateTime? createdAt;

  CommunityReaction({
    required this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.reactionType,
    this.createdAt,
  });

  factory CommunityReaction.fromJson(Map<String, dynamic> json) {
    return CommunityReaction(
      id: json['id'],
      userId: json['user_id'],
      targetType: json['target_type'],
      targetId: json['target_id'],
      reactionType: json['reaction_type'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'target_type': targetType,
      'target_id': targetId,
      'reaction_type': reactionType,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}