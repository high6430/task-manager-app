enum TimeUnit { days, hours, minutes }

class NotificationTiming {
  final int days;
  final int hours;
  final int minutes;

  NotificationTiming({
    this.days = 0,
    this.hours = 0,
    this.minutes = 0,
  });

  // 総分数に変換（ソート・比較用）
  int get totalMinutes => days * 24 * 60 + hours * 60 + minutes;

  // 表示用テキスト
  String get displayText {
    List<String> parts = [];
    if (days > 0) parts.add('${days}日');
    if (hours > 0) parts.add('${hours}時間');
    if (minutes > 0) parts.add('${minutes}分');
    return parts.isEmpty ? '0分' : parts.join('') + '前';
  }

  // JSON変換
  Map<String, dynamic> toJson() {
    return {
      'days': days,
      'hours': hours,
      'minutes': minutes,
    };
  }

  factory NotificationTiming.fromJson(Map<String, dynamic> json) {
    return NotificationTiming(
      days: json['days'] ?? 0,
      hours: json['hours'] ?? 0,
      minutes: json['minutes'] ?? 0,
    );
  }

  // 等価性チェック（重複検出用）
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationTiming && other.totalMinutes == totalMinutes;
  }

  @override
  int get hashCode => totalMinutes.hashCode;

  // 比較（ソート用：近い順）
  int compareTo(NotificationTiming other) {
    return totalMinutes.compareTo(other.totalMinutes);
  }
}
