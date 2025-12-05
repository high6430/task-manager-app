import 'package:flutter/material.dart';
import 'screens/task_board_screen.dart';
import 'services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:pikado/utils/logger.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 通知サービスの初期化
  await NotificationService.initialize();
  
  Logger.section(' アプリ起動 ');
  
  // 通知権限のリクエスト
  if (Platform.isAndroid) {
    Logger.section(' Android 権限チェック ');
    
    // ★ 修正1: POST_NOTIFICATIONS 権限（Android 13以上）
    Logger.log('--- POST_NOTIFICATIONS 権限 ---');
    final notificationStatus = await Permission.notification.status;
    Logger.log('現在の状態: $notificationStatus');
    
    if (notificationStatus.isDenied) {
      Logger.log('通知権限をリクエストします');
      final result = await Permission.notification.request();
      Logger.log('リクエスト結果: $result');
      
      if (result.isGranted) {
        Logger.success('✅ 通知権限が許可されました');
      } else if (result.isDenied) {
        Logger.error('❌ 通知権限が拒否されました');
      } else if (result.isPermanentlyDenied) {
        Logger.error('❌ 通知権限が永続的に拒否されました（設定画面から有効化してください）');
      }
    } else if (notificationStatus.isGranted) {
      Logger.success('✅ 通知権限は既に許可済みです');
    } else if (notificationStatus.isPermanentlyDenied) {
      Logger.error('❌ 通知権限が永続的に拒否されています（設定画面から有効化してください）');
    }
    
    // ★ 修正2: SCHEDULE_EXACT_ALARM 権限（Android 12以上）- 新規追加
    Logger.log('--- SCHEDULE_EXACT_ALARM 権限 ---');
    final alarmStatus = await Permission.scheduleExactAlarm.status;
    Logger.log('現在の状態: $alarmStatus');
    
    if (alarmStatus.isDenied) {
      Logger.log('アラーム権限をリクエストします');
      final result = await Permission.scheduleExactAlarm.request();
      Logger.log('リクエスト結果: $result');
      
      if (result.isGranted) {
        Logger.success('✅ アラーム権限が許可されました');
      } else if (result.isDenied) {
        Logger.warning('⚠️ アラーム権限が拒否されました（通知が正確な時刻に届かない可能性があります）');
      } else if (result.isPermanentlyDenied) {
        Logger.warning('⚠️ アラーム権限が永続的に拒否されました（設定画面から有効化してください）');
      }
    } else if (alarmStatus.isGranted) {
      Logger.success('✅ アラーム権限は既に許可済みです');
    } else if (alarmStatus.isPermanentlyDenied) {
      Logger.warning('⚠️ アラーム権限が永続的に拒否されています（設定画面から有効化してください）');
    }
    
    Logger.sectionEnd(' Android 権限チェック ');
    
  } else if (Platform.isIOS) {
    Logger.section(' iOS 権限チェック ');
    
    // iOS
    final notificationStatus = await Permission.notification.status;
    Logger.log('iOS通知権限: $notificationStatus');
    
    if (notificationStatus.isDenied) {
      final result = await Permission.notification.request();
      Logger.log('iOS通知権限リクエスト結果: $result');
      
      if (result.isGranted) {
        Logger.success('✅ iOS通知権限が許可されました');
      } else {
        Logger.error('❌ iOS通知権限が拒否されました');
      }
    } else if (notificationStatus.isGranted) {
      Logger.success('✅ iOS通知権限は既に許可済みです');
    }
    
    Logger.sectionEnd(' iOS 権限チェック ');
  }
  
  Logger.sectionEnd(' 初期化完了 ');
  
  runApp(pikado());
}

class pikado extends StatelessWidget {
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
