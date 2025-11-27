import 'package:flutter/material.dart';
import 'screens/task_board_screen.dart';
import 'services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 通知サービスの初期化
  await NotificationService.initialize();
  
  print('=== アプリ起動 ===');
  
  // 通知権限のリクエスト
  if (Platform.isAndroid) {
    // Android 13以上
    final notificationStatus = await Permission.notification.status;
    print('通知権限: $notificationStatus');
    
    if (notificationStatus.isDenied) {
      final result = await Permission.notification.request();
      print('通知権限リクエスト結果: $result');
    }
    
    // アラーム権限は画面内で案内するので、ここではチェックのみ
    final hasAlarm = await NotificationService.hasExactAlarmPermission();
    print('アラーム権限: $hasAlarm');
  } else if (Platform.isIOS) {
    // iOS
    final notificationStatus = await Permission.notification.status;
    print('iOS通知権限: $notificationStatus');
    
    if (notificationStatus.isDenied) {
      final result = await Permission.notification.request();
      print('iOS通知権限リクエスト結果: $result');
    }
  }
  
  print('=== 初期化完了 ===\n');
  
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
