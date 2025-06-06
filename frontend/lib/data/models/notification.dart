class Notification {
  final String id;
  final String userId;
  final String notificationType;
  final String title;
  final String message;
  final String? actionUrl;
  final Map<String, dynamic>? actionData;
  final String? priority;
  final String? deliveryMethod;
  final bool? isRead;
  final bool? isSent;
  final DateTime? scheduledFor;
  final DateTime? sentAt;
  final DateTime? readAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  Notification({
    required this.id,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.message,
    this.actionUrl,
    this.actionData,
    this.priority,
    this.deliveryMethod,
    this.isRead,
    this.isSent,
    this.scheduledFor,
    this.sentAt,
    this.readAt,
    this.expiresAt,
    this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      userId: json['user_id'],
      notificationType: json['notification_type'],
      title: json['title'],
      message: json['message'],
      actionUrl: json['action_url'],
      actionData: json['action_data'],
      priority: json['priority'],
      deliveryMethod: json['delivery_method'],
      isRead: json['is_read'],
      isSent: json['is_sent'],
      scheduledFor: json['scheduled_for'] != null ? DateTime.parse(json['scheduled_for']) : null,
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'notification_type': notificationType,
      'title': title,
      'message': message,
      'action_url': actionUrl,
      'action_data': actionData,
      'priority': priority,
      'delivery_method': deliveryMethod,
      'is_read': isRead,
      'is_sent': isSent,
      'scheduled_for': scheduledFor?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}