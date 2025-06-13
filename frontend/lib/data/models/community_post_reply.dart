class CommunityPostReply {
  final String id;
  final String authorName;
  final String authorId;
  final String content;
  final bool isAnonymous;
  final int reactionCount;
  final DateTime createdAt;

  CommunityPostReply({
    required this.id,
    required this.authorName,
    required this.authorId,
    required this.content,
    required this.isAnonymous,
    required this.reactionCount,
    required this.createdAt,
  });

  factory CommunityPostReply.fromJson(Map<String, dynamic> json) {
    return CommunityPostReply(
      id: json['ID'] as String? ?? '',
      authorName: json['author_name'] as String? ?? 'Anonim',
      authorId: json['author_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      reactionCount: json['reaction_count'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['CreatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}