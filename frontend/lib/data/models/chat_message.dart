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
    // Sesuaikan dengan response dari backend ChatMessageResponse DTO
    return ChatMessage(
      id: json['id'],
      chatSessionId: json['chat_session_id'],
      senderType: json['sender_type'],
      messageContent: json['message_content'],
      createdAt: DateTime.parse(json['created_at']),
      // Properti UI diisi dengan logika default
      senderId: json['sender_type'] == 'user' ? 'user_main' : 'ai_bot_001',
      senderName: json['sender_type'] == 'user' ? 'Saya' : 'Tenang Assistant',
      timestamp: DateTime.parse(json['created_at']),
      isOwner: json['sender_type'] == 'user',
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