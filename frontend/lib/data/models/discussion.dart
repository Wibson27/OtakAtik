class Discussion {
  final String id;
  final String title;
  final String content;
  final String authorName;
  final DateTime createdAt;

  Discussion({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    required this.createdAt,
  });

  factory Discussion.fromJson(Map<String, dynamic> json) {
    return Discussion(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      authorName: json['author_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author_name': authorName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}