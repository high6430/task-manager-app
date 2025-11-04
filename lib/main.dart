import 'package:flutter/material.dart';
import 'screens/task_board_screen.dart';

void main() {
  runApp(TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'タスク管理アプリ',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: TaskBoardScreen(),
    );
  }
}
