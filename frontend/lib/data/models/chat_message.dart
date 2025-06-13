// PERBAIKAN UTAMA untuk ChatMessage Model
// File: data/models/chat_message.dart

import 'package:frontend/data/models/attachment_file.dart';

class ChatMessage {
  final String id;
  final String chatSessionId;
  final String senderType;
  final String messageContent;
  final DateTime timestamp;
  final String senderName;
  final bool isOwner;
  final List<AttachmentFile>? attachments;

  ChatMessage({
    required this.id,
    required this.chatSessionId,
    required this.senderType,
    required this.messageContent,
    required this.timestamp,
    required this.senderName,
    required this.isOwner,
    this.attachments,
  });

  // 🔧 PERBAIKAN: fromJson yang lebih robust
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    try {
      // Validasi field wajib
      if (json['id'] == null) {
        throw Exception('ChatMessage: id field is required');
      }

      if (json['message_content'] == null) {
        throw Exception('ChatMessage: message_content field is required');
      }

      // Parse timestamp dengan fallback
      DateTime parsedTimestamp;
      try {
        if (json['created_at'] != null) {
          parsedTimestamp = DateTime.parse(json['created_at']);
        } else if (json['timestamp'] != null) {
          parsedTimestamp = DateTime.parse(json['timestamp']);
        } else {
          parsedTimestamp = DateTime.now();
        }
      } catch (e) {
        print("⚠️ Error parsing timestamp, using current time: $e");
        parsedTimestamp = DateTime.now();
      }

      // Determine sender info dengan fallback
      final senderType = json['sender_type']?.toString() ?? 'user';
      final isOwner = senderType.toLowerCase() == 'user';

      String senderName;
      if (isOwner) {
        senderName = json['sender_name']?.toString() ?? 'You';
      } else {
        senderName = json['sender_name']?.toString() ?? 'Tenang Assistant';
      }

      // Parse attachments jika ada
      List<AttachmentFile>? attachments;
      if (json['attachments'] != null && json['attachments'] is List) {
        try {
          attachments = (json['attachments'] as List)
              .map((attachment) => AttachmentFile.fromJson(attachment))
              .toList();
        } catch (e) {
          print("⚠️ Error parsing attachments: $e");
          attachments = null;
        }
      }

      return ChatMessage(
        id: json['id'].toString(),
        chatSessionId: json['chat_session_id']?.toString() ??
                      json['session_id']?.toString() ??
                      '',
        senderType: senderType,
        messageContent: json['message_content'].toString().trim(),
        timestamp: parsedTimestamp,
        senderName: senderName,
        isOwner: isOwner,
        attachments: attachments,
      );

    } catch (e) {
      print("❌ Error in ChatMessage.fromJson: $e");
      print("❌ JSON data: $json");
      rethrow;
    }
  }

  // 🔧 PERBAIKAN: Factory untuk membuat pesan user dengan data valid
  factory ChatMessage.fromUser({
    required String content,
    required String sessionId,
    List<AttachmentFile>? attachments,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
      chatSessionId: sessionId,
      senderType: 'user',
      messageContent: content.trim(),
      timestamp: DateTime.now(),
      senderName: 'You',
      isOwner: true,
      attachments: attachments,
    );
  }

  // 🔧 PERBAIKAN: Factory untuk membuat pesan AI dengan data valid
  factory ChatMessage.fromAI({
    required String content,
    required String sessionId,
    String? messageId,
  }) {
    return ChatMessage(
      id: messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      chatSessionId: sessionId,
      senderType: 'ai_bot',
      messageContent: content.trim(),
      timestamp: DateTime.now(),
      senderName: 'Tenang Assistant',
      isOwner: false,
      attachments: null,
    );
  }

  // Utility methods
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_session_id': chatSessionId,
      'sender_type': senderType,
      'message_content': messageContent,
      'created_at': timestamp.toIso8601String(),
      'sender_name': senderName,
      'attachments': attachments?.map((a) => a.toJson()).toList(),
    };
  }

  // 🔧 PERBAIKAN: Method untuk validasi pesan
  bool get isValid {
    return id.isNotEmpty &&
           chatSessionId.isNotEmpty &&
           messageContent.trim().isNotEmpty;
  }

  // 🔧 PERBAIKAN: Method untuk copy dengan perubahan
  ChatMessage copyWith({
    String? id,
    String? chatSessionId,
    String? senderType,
    String? messageContent,
    DateTime? timestamp,
    String? senderName,
    bool? isOwner,
    List<AttachmentFile>? attachments,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatSessionId: chatSessionId ?? this.chatSessionId,
      senderType: senderType ?? this.senderType,
      messageContent: messageContent ?? this.messageContent,
      timestamp: timestamp ?? this.timestamp,
      senderName: senderName ?? this.senderName,
      isOwner: isOwner ?? this.isOwner,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, sender: $senderName, content: "${messageContent.length > 50 ? messageContent.substring(0, 50) + "..." : messageContent}")';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}