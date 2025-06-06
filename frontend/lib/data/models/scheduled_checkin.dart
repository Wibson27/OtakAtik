class ScheduledCheckin {
  final String id;
  final String userId;
  final String? scheduleName;
  final String timeOfDay; // Menyimpan sebagai String HH:MM:SS
  final List<int> daysOfWeek;
  final bool? isActive;
  final String? greetingTemplate;
  final DateTime? lastTriggeredAt;
  final DateTime? nextTriggerAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ScheduledCheckin({
    required this.id,
    required this.userId,
    this.scheduleName,
    required this.timeOfDay,
    required this.daysOfWeek,
    this.isActive,
    this.greetingTemplate,
    this.lastTriggeredAt,
    this.nextTriggerAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ScheduledCheckin.fromJson(Map<String, dynamic> json) {
    return ScheduledCheckin(
      id: json['id'],
      userId: json['user_id'],
      scheduleName: json['schedule_name'],
      timeOfDay: json['time_of_day'], // Baca langsung sebagai String
      daysOfWeek: List<int>.from(json['days_of_week']),
      isActive: json['is_active'],
      greetingTemplate: json['greeting_template'],
      lastTriggeredAt: json['last_triggered_at'] != null ? DateTime.parse(json['last_triggered_at']) : null,
      nextTriggerAt: json['next_trigger_at'] != null ? DateTime.parse(json['next_trigger_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'schedule_name': scheduleName,
      'time_of_day': timeOfDay, // Kirim langsung sebagai String
      'days_of_week': daysOfWeek,
      'is_active': isActive,
      'greeting_template': greetingTemplate,
      'last_triggered_at': lastTriggeredAt?.toIso8601String(),
      'next_trigger_at': nextTriggerAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}