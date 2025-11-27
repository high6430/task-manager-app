import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class AppSettingsService {
  static const String _key = 'app_settings';

  // 設定を保存
  static Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }

  // 設定を読み込み
  static Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null) {
      // 初回起動時：デフォルト設定（通知ON）
      final defaultSettings = AppSettings(notificationEnabled: true);
      await saveSettings(defaultSettings);
      return defaultSettings;
    }

    return AppSettings.fromJson(jsonDecode(jsonString));
  }

  // 通知のON/OFFを切り替え
  static Future<void> toggleNotification(bool enabled) async {
    final settings = await loadSettings();
    await saveSettings(settings.copyWith(notificationEnabled: enabled));
  }
}
