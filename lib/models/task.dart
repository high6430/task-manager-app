enum Priority { high, middle, low }

class Task {
  final String title;
  final DateTime deadline;
  final Priority priority;
  final String description;
  final List<String> labelIds;

  Task(
    this.title,
    this.deadline, {
    this.priority = Priority.middle,
    this.description = '',
    this.labelIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'deadline': deadline.toIso8601String(),
      'priority': priority.index,
      'description': description,
      'labelIds': labelIds,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      json['title'],
      DateTime.parse(json['deadline']),
      priority: Priority.values[json['priority']],
      description: json['description'] ?? '',
      labelIds: json['labelIds'] != null 
          ? List<String>.from(json['labelIds']) 
          : [],
    );
  }
}