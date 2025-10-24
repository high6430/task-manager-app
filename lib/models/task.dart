enum Priority { high, middle, low }

class Task {
  final String title;
  final DateTime deadline;
  final Priority priority;

  Task(this.title, this.deadline, {this.priority = Priority.middle});

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'deadline': deadline.toIso8601String(),
      'priority': priority.index,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      json['title'],
      DateTime.parse(json['deadline']),
      priority: Priority.values[json['priority']],
    );
  }
}