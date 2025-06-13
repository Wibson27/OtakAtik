import 'package:frontend/data/models/community_post_reply.dart';

class CommunityPostDetail {
  final String id;
  final String title;
  final String content;
  final String authorName;
  final String authorId;
  final DateTime createdAt;
  final List<CommunityPostReply> replies;

  CommunityPostDetail({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    required this.authorId,
    required this.createdAt,
    required this.replies,
  });

  factory CommunityPostDetail.fromJson(Map<String, dynamic> json) {
    var repliesList = (json['replies'] as List<dynamic>?) ?? [];
    List<CommunityPostReply> parsedReplies = repliesList
        .map((replyJson) => CommunityPostReply.fromJson(replyJson))
        .toList();

    return CommunityPostDetail(
      id: json['ID'] as String? ?? '',
      title: json['title'] as String? ?? 'Tanpa Judul',
      content: json['content'] as String? ?? '',
      authorName: json['author_name'] as String? ?? 'Anonim',
      authorId: json['author_id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['CreatedAt'] as String? ?? '') ?? DateTime.now(),
      replies: parsedReplies,
    );
  }
}