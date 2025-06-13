class CommunityPost {
  final String id;
  final String title;
  final String contentSnippet;
  final String categoryName;
  final String authorName;
  final int replyCount;
  final int reactionCount;
  final DateTime createdAt;
  final DateTime lastActivityAt;

  CommunityPost({
    required this.id,
    required this.title,
    required this.contentSnippet,
    required this.categoryName,
    required this.authorName,
    required this.replyCount,
    required this.reactionCount,
    required this.createdAt,
    required this.lastActivityAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Tanpa Judul',
      contentSnippet: json['content_snippet'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? 'Umum',
      authorName: json['author_name'] as String? ?? 'Anonim',
      replyCount: json['reply_count'] as int? ?? 0,
      reactionCount: json['reaction_count'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      lastActivityAt: DateTime.tryParse(json['last_activity_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

// class CommunityPost {
//   final String id;
//   final String userId;
//   final String categoryId;
//   final String postTitle;
//   final String postContent;
//   final bool? isAnonymous;
//   final String? anonymousDisplayName;
//   final String? postStatus;
//   final double? sentimentScore;
//   final List<String>? contentWarnings;
//   final int? viewCount;
//   final int? replyCount;
//   final int? reactionCount;
//   final DateTime? lastActivityAt;
//   final bool? isPinned;
//   final String? moderationNotes;
//   final DateTime? createdAt;
//   final DateTime? updatedAt;

//   CommunityPost({
//     required this.id,
//     required this.userId,
//     required this.categoryId,
//     required this.postTitle,
//     required this.postContent,
//     this.isAnonymous,
//     this.anonymousDisplayName,
//     this.postStatus,
//     this.sentimentScore,
//     this.contentWarnings,
//     this.viewCount,
//     this.replyCount,
//     this.reactionCount,
//     this.lastActivityAt,
//     this.isPinned,
//     this.moderationNotes,
//     this.createdAt,
//     this.updatedAt,
//   });

//   factory CommunityPost.fromJson(Map<String, dynamic> json) {
//     return CommunityPost(
//       id: json['id'],
//       userId: json['user_id'],
//       categoryId: json['category_id'],
//       postTitle: json['post_title'],
//       postContent: json['post_content'],
//       isAnonymous: json['is_anonymous'],
//       anonymousDisplayName: json['anonymous_display_name'],
//       postStatus: json['post_status'],
//       sentimentScore: (json['sentiment_score'] as num?)?.toDouble(),
//       contentWarnings: (json['content_warnings'] as List?)?.map((e) => e.toString()).toList(),
//       viewCount: json['view_count'],
//       replyCount: json['reply_count'],
//       reactionCount: json['reaction_count'],
//       lastActivityAt: json['last_activity_at'] != null ? DateTime.parse(json['last_activity_at']) : null,
//       isPinned: json['is_pinned'],
//       moderationNotes: json['moderation_notes'],
//       createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
//       updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'user_id': userId,
//       'category_id': categoryId,
//       'post_title': postTitle,
//       'post_content': postContent,
//       'is_anonymous': isAnonymous,
//       'anonymous_display_name': anonymousDisplayName,
//       'post_status': postStatus,
//       'sentiment_score': sentimentScore,
//       'content_warnings': contentWarnings,
//       'view_count': viewCount,
//       'reply_count': replyCount,
//       'reaction_count': reactionCount,
//       'last_activity_at': lastActivityAt?.toIso8601String(),
//       'is_pinned': isPinned,
//       'moderation_notes': moderationNotes,
//       'created_at': createdAt?.toIso8601String(),
//       'updated_at': updatedAt?.toIso8601String(),
//     };
//   }
// }