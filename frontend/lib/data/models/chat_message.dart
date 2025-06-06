import 'package:frontend/common/enums.dart';
import 'package:frontend/data/models/attachment_file.dart'; 

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

  // untuk kebutuhan UI di forum_discussion_post.dart
  final String senderId; 
  final String senderName;
  final DateTime timestamp; 
  final MessageType type; 
  final bool isOwner; 
  final List<AttachmentFile> attachments; 

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

    // Properti tambahan (wajib diisi dari UI)
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    this.type = MessageType.text, 
    required this.isOwner,
    this.attachments = const [],
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      chatSessionId: json['chat_session_id'] as String,
      senderType: json['sender_type'] as String,
      messageContent: json['message_content'] as String,
      messageMetadata: json['message_metadata'] as Map<String, dynamic>?,
      sentimentScore: (json['sentiment_score'] as num?)?.toDouble(),
      emotionDetected: json['emotion_detected'] as String?,
      responseTimeMs: json['response_time_ms'] as int?,
      isEncrypted: json['is_encrypted'] as bool?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,

      senderId: json['sender_id'] as String? ?? json['sender_type'], 
      senderName: json['sender_name'] as String? ?? (json['sender_type'] == 'user' ? 'Anda' : 'Bot'), 
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
      type: MessageType.values.firstWhere(
          (e) => e.toString().split('.').last == json['type'],
          orElse: () => MessageType.text),
      isOwner: json['is_owner'] as bool? ?? (json['sender_type'] == 'user' ? true : false), 
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => AttachmentFile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
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

      'sender_id': senderId,
      'sender_name': senderName,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'is_owner': isOwner,
      'attachments': attachments.map((e) => e.toJson()).toList(),
    };
  }
}