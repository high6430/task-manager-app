class AppSettings {
  final bool notificationEnabled;

  AppSettings({
    this.notificationEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'notificationEnabled': notificationEnabled,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationEnabled: json['notificationEnabled'] ?? true,
    );
  }

  AppSettings copyWith({
    bool? notificationEnabled,
  }) {
    return AppSettings(
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }
}

