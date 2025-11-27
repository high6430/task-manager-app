import 'notification_timing.dart';

class NotificationSet {
  final String id;
  final String name;
  final List<NotificationTiming> timings;
  final bool vibration;

  NotificationSet({
    required this.id,
    required this.name,
    required this.timings,
    this.vibration = true,
  });

  // JSON変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'timings': timings.map((t) => t.toJson()).toList(),
      'vibration': vibration,
    };
  }

  factory NotificationSet.fromJson(Map<String, dynamic> json) {
    return NotificationSet(
      id: json['id'],
      name: json['name'],
      timings: (json['timings'] as List)
          .map((t) => NotificationTiming.fromJson(t))
          .toList(),
      vibration: json['vibration'] ?? true,
    );
  }

  // コピー（編集用）
  NotificationSet copyWith({
    String? id,
    String? name,
    List<NotificationTiming>? timings,
    bool? vibration,
  }) {
    return NotificationSet(
      id: id ?? this.id,
      name: name ?? this.name,
      timings: timings ?? this.timings,
      vibration: vibration ?? this.vibration,
    );
  }
}
