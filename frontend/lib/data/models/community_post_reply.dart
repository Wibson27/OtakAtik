class CommunityPostReply {
  final String id;
  final String postId;
  final String? parentReplyId;
  final String userId;
  final String replyContent;
  final bool? isAnonymous;
  final String? anonymousDisplayName;
  final int? replyLevel;
  final double? sentimentScore;
  final int? reactionCount;
  final bool? isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CommunityPostReply({
    required this.id,
    required this.postId,
    this.parentReplyId,
    required this.userId,
    required this.replyContent,
    this.isAnonymous,
    this.anonymousDisplayName,
    this.replyLevel,
    this.sentimentScore,
    this.reactionCount,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  factory CommunityPostReply.fromJson(Map<String, dynamic> json) {
    return CommunityPostReply(
      id: json['id'],
      postId: json['post_id'],
      parentReplyId: json['parent_reply_id'],
      userId: json['user_id'],
      replyContent: json['reply_content'],
      isAnonymous: json['is_anonymous'],
      anonymousDisplayName: json['anonymous_display_name'],
      replyLevel: json['reply_level'],
      sentimentScore: (json['sentiment_score'] as num?)?.toDouble(),
      reactionCount: json['reaction_count'],
      isDeleted: json['is_deleted'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'parent_reply_id': parentReplyId,
      'user_id': userId,
      'reply_content': replyContent,
      'is_anonymous': isAnonymous,
      'anonymous_display_name': anonymousDisplayName,
      'reply_level': replyLevel,
      'sentiment_score': sentimentScore,
      'reaction_count': reactionCount,
      'is_deleted': isDeleted,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}