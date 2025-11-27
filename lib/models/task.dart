import 'notification_timing.dart';

enum Priority { high, middle, low }

class Task {
  final String id;  // 追加
  final String title;
  final DateTime deadline;
  final Priority priority;
  final String description;
  final List<String> labelIds;
  final List<String> notificationSetIds;
  final List<NotificationTiming> customTimings;
  final bool notificationEnabled;

  Task(
    this.title,
    this.deadline, {
    String? id,  // 追加：nullableにして自動生成可能に
    this.priority = Priority.middle,
    this.description = '',
    this.labelIds = const [],
    this.notificationSetIds = const [],
    this.customTimings = const [],
    this.notificationEnabled = true,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();  // 追加：自動生成

  Map<String, dynamic> toJson() {
    return {
      'id': id,  // 追加
      'title': title,
      'deadline': deadline.toIso8601String(),
      'priority': priority.index,
      'description': description,
      'labelIds': labelIds,
      'notificationSetIds': notificationSetIds,
      'customTimings': customTimings.map((t) => t.toJson()).toList(),
      'notificationEnabled': notificationEnabled,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      json['title'],
      DateTime.parse(json['deadline']),
      id: json['id'],  // 追加
      priority: Priority.values[json['priority'] ?? 1],
      description: json['description'] ?? '',
      labelIds: List<String>.from(json['labelIds'] ?? []),
      notificationSetIds: List<String>.from(json['notificationSetIds'] ?? []),
      customTimings: (json['customTimings'] as List?)
              ?.map((t) => NotificationTiming.fromJson(t))
              .toList() ??
          [],
      notificationEnabled: json['notificationEnabled'] ?? true,
    );
  }
}
