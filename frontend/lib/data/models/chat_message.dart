class ChatMessage {
  final String id;
  final String chatSessionId;
  final String senderType;
  final String messageContent;
  final Map<String, dynamic>? messageMetadata;
  final double? sentimentScore;
  final String? emotionDetected;
  final int? responseTimeMs;
  final bool? isEncrypted;
  final DateTime? createdAt;

  ChatMessage({
    required this.id,
    required this.chatSessionId,
    required this.senderType,
    required this.messageContent,
    this.messageMetadata,
    this.sentimentScore,
    this.emotionDetected,
    this.responseTimeMs,
    this.isEncrypted,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      chatSessionId: json['chat_session_id'],
      senderType: json['sender_type'],
      messageContent: json['message_content'],
      messageMetadata: json['message_metadata'],
      sentimentScore: (json['sentiment_score'] as num?)?.toDouble(), 
      emotionDetected: json['emotion_detected'],
      responseTimeMs: json['response_time_ms'],
      isEncrypted: json['is_encrypted'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_session_id': chatSessionId,
      'sender_type': senderType,
      'message_content': messageContent,
      'message_metadata': messageMetadata,
      'sentiment_score': sentimentScore,
      'emotion_detected': emotionDetected,
      'response_time_ms': responseTimeMs,
      'is_encrypted': isEncrypted,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}