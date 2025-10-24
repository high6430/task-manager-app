import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';

class TaskService {
  // タスクを読み込む
  static Future<Map<String, List<Task>>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final todoString = prefs.getString('todoTasks');
    final doingString = prefs.getString('doingTasks');
    final doneString = prefs.getString('doneTasks');

    return {
      'todo': todoString != null
          ? List<Task>.from(json.decode(todoString).map((x) => Task.fromJson(x)))
          : [],
      'doing': doingString != null
          ? List<Task>.from(json.decode(doingString).map((x) => Task.fromJson(x)))
          : [],
      'done': doneString != null
          ? List<Task>.from(json.decode(doneString).map((x) => Task.fromJson(x)))
          : [],
    };
  }

  // タスクを保存する
  static Future<void> saveTasks({
    required List<Task> todoTasks,
    required List<Task> doingTasks,
    required List<Task> doneTasks,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('todoTasks', json.encode(todoTasks.map((x) => x.toJson()).toList()));
    await prefs.setString('doingTasks', json.encode(doingTasks.map((x) => x.toJson()).toList()));
    await prefs.setString('doneTasks', json.encode(doneTasks.map((x) => x.toJson()).toList()));
  }
}