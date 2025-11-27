import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_set.dart';
import '../models/notification_timing.dart';

class NotificationSetService {
  static const String _key = 'notification_sets';

  // 通知セットを保存
  static Future<void> saveNotificationSets(List<NotificationSet> sets) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = sets.map((set) => set.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  // 通知セットを読み込み
  static Future<List<NotificationSet>> loadNotificationSets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null) {
      // 初回起動時：初期通知セット「通常」を作成
      final defaultSet = _createDefaultNotificationSet();
      await saveNotificationSets([defaultSet]);
      return [defaultSet];
    }

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => NotificationSet.fromJson(json)).toList();
  }

  // 初期通知セット「通常」を作成
  static NotificationSet _createDefaultNotificationSet() {
    return NotificationSet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '通常',
      timings: [
        NotificationTiming(days: 1), // 1日前
        NotificationTiming(hours: 1), // 1時間前
      ],
      vibration: true,
    );
  }

  // IDで通知セットを取得
  static NotificationSet? getNotificationSetById(
      List<NotificationSet> sets, String id) {
    try {
      return sets.firstWhere((set) => set.id == id);
    } catch (e) {
      return null;
    }
  }

  // 通知セットを追加
  static Future<void> addNotificationSet(NotificationSet newSet) async {
    final sets = await loadNotificationSets();
    sets.add(newSet);
    await saveNotificationSets(sets);
  }

  // 通知セットを更新
  static Future<void> updateNotificationSet(NotificationSet updatedSet) async {
    final sets = await loadNotificationSets();
    final index = sets.indexWhere((set) => set.id == updatedSet.id);
    if (index != -1) {
      sets[index] = updatedSet;
      await saveNotificationSets(sets);
    }
  }

  // 通知セットを削除
  static Future<void> deleteNotificationSet(String id) async {
    final sets = await loadNotificationSets();
    sets.removeWhere((set) => set.id == id);
    await saveNotificationSets(sets);
  }

  // 通知セットが使用されているタスク数を取得
  static int getUsageCount(String setId, List<dynamic> tasks) {
    return tasks.where((task) {
      final notificationSetIds = task.notificationSetIds as List<String>?;
      return notificationSetIds?.contains(setId) ?? false;
    }).length;
  }
}
