import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as notifications;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/task.dart';
import '../models/notification_timing.dart';
import '../services/notification_set_service.dart';
import '../services/app_settings_service.dart';
import 'dart:async';
import 'package:task_manager_app/utils/logger.dart';


class NotificationService {
  static final notifications.FlutterLocalNotificationsPlugin _notifications =
      notifications.FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  
  // タスク完了イベント用StreamController
  static final StreamController<String> _taskCompleteController = 
      StreamController<String>.broadcast();
  
  // タスク詳細表示イベント用StreamController
  static final StreamController<String> _taskDetailsController = 
      StreamController<String>.broadcast();
  
  // 外部からStreamを購読できるようにする
  static Stream<String> get taskCompleteStream => _taskCompleteController.stream;
  static Stream<String> get taskDetailsStream => _taskDetailsController.stream;

  // 通知サービスの初期化
static Future<void> initialize() async {
  if (_initialized) {
    Logger.warning(' NotificationService は既に初期化済みです');
    return;
  }

  Logger.section(' NotificationService 初期化開始 ');

  // タイムゾーンデータの初期化
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
  Logger.success(' タイムゾーン設定: Asia/Tokyo');

  // Android設定
  const androidSettings = notifications.AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  // iOS設定（通知カテゴリーとアクション追加）
  final iosSettings = notifications.DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    notificationCategories: [
      notifications.DarwinNotificationCategory(
        'task_notification',
        actions: [
          notifications.DarwinNotificationAction.plain(
            'complete',
            '完了',
            options: {
              notifications.DarwinNotificationActionOption.foreground,
            },
          ),
          notifications.DarwinNotificationAction.plain(
            'details',
            '詳細を見る',
            options: {
              notifications.DarwinNotificationActionOption.foreground,
            },
          ),
        ],
        options: {
          notifications.DarwinNotificationCategoryOption.customDismissAction,
        },
      ),
    ],
  );

  final initSettings = notifications.InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  final initialized = await _notifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: _onNotificationTapped,
  );

  if (initialized == true) {
    Logger.success(' FlutterLocalNotifications 初期化成功');
  } else {
    Logger.error(' FlutterLocalNotifications 初期化失敗');
  }

  // 通知チャンネルの作成（Android）
  if (Platform.isAndroid) {
    await _createNotificationChannel();
  }

  _initialized = true;
  Logger.sectionEnd(' NotificationService 初期化完了 ');
}

  // 通知チャンネルの作成（グループ化用）
  static Future<void> _createNotificationChannel() async {
    Logger.log('--- 通知チャンネル作成開始 ---');
    
    const androidChannel = notifications.AndroidNotificationChannel(
      'task_notifications',
      'タスク通知',
      description: 'タスクの締切通知',
      importance: notifications.Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        notifications.AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      Logger.error(' AndroidFlutterLocalNotificationsPlugin が取得できません');
      return;
    }

    await androidPlugin.createNotificationChannel(androidChannel);
    Logger.success(' 通知チャンネル作成完了');
    Logger.log('   ID: ${androidChannel.id}');
    Logger.log('   名前: ${androidChannel.name}');
    Logger.log('   重要度: ${androidChannel.importance}');
    
    // 作成されたチャンネルを確認
    final channels = await androidPlugin.getNotificationChannels();
    if (channels != null) {
      Logger.success(' 登録済み通知チャンネル数: ${channels.length}');
      for (var channel in channels) {
        Logger.log('   - ${channel.id}: ${channel.name} (重要度: ${channel.importance})');
      }
    }
    
    Logger.log('--- 通知チャンネル作成完了 ---\n');
  }

  // 通知権限のリクエスト
// 通知権限のリクエスト
static Future<bool> requestPermission() async {
  if (Platform.isAndroid) {
    // Android 13以上
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  } else if (Platform.isIOS) {
    // iOS - flutter_local_notificationsの権限リクエストを使用
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        notifications.IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      Logger.log('iOS通知権限: $granted');
      return granted ?? false;
    }
    
    // フォールバック: permission_handlerを使用
    final status = await Permission.notification.request();
    return status.isGranted;
  }
  return true;
}

// 通知がタップされた時の処理
static void _onNotificationTapped(notifications.NotificationResponse response) {
  Logger.section(' 通知タップイベント ');
  Logger.log('通知ID: ${response.id}');
  Logger.log('アクション: ${response.actionId}');
  Logger.log('payload: ${response.payload}');
  Logger.log('通知タイプ: ${response.notificationResponseType}');
  
  final actionId = response.actionId;
  final taskId = response.payload;
  
  // 少し遅延させてからイベントを送信（Streamの購読準備を待つ）
  Future.delayed(Duration(milliseconds: 500), () {
    if (actionId == 'complete') {
      Logger.success(' 「完了」ボタンがタップされました');
      Logger.log('タスクID: $taskId');
      
      if (taskId != null) {
        _handleCompleteAction(taskId);
      }
    } else if (actionId == 'details') {
      Logger.log('📋 「詳細を見る」ボタンがタップされました');
      Logger.log('タスクID: $taskId');
      
      if (taskId != null) {
        _handleDetailsAction(taskId);
      }
    } else {
      Logger.log('📱 通知本体がタップされました');
      if (taskId != null) {
        _handleDetailsAction(taskId);
      }
    }
  });
  
  Logger.sectionEnd(' 通知タップイベント');
}

  // 「完了」アクションの処理
  static void _handleCompleteAction(String taskId) {
    Logger.log('--- 完了アクション処理開始 ---');
    Logger.log('タスクID: $taskId');
    
    // StreamControllerを使って、タスク完了イベントを通知
    _taskCompleteController.add(taskId);
    
    Logger.success(' タスク完了イベントを送信しました');
    Logger.log('--- 完了アクション処理終了 ---\n');
  }
  
  // 「詳細を見る」アクションの処理
  static void _handleDetailsAction(String taskId) {
    Logger.log('--- 詳細表示アクション処理開始 ---');
    Logger.log('タスクID: $taskId');
    
    // StreamControllerを使って、タスク詳細表示イベントを通知
    _taskDetailsController.add(taskId);
    
    Logger.success(' タスク詳細表示イベントを送信しました');
    Logger.log('--- 詳細表示アクション処理終了 ---\n');
  }

  // タスクの通知をスケジュール
  static Future<void> scheduleTaskNotifications(
    Task task,
    String taskId,
    String columnName,
  ) async {
    Logger.section(' scheduleTaskNotifications 開始 ');
    Logger.log('タスクID: $taskId');
    Logger.log('カラム: $columnName');
    
    // アプリ全体の通知設定を確認
    final settings = await AppSettingsService.loadSettings();
    Logger.log('アプリ全体の通知: ${settings.notificationEnabled}');
    if (!settings.notificationEnabled) {
      Logger.error(' アプリ全体の通知がOFFのためスキップ');
      return;
    }

    // タスクの通知設定を確認
    Logger.log('タスクの通知: ${task.notificationEnabled}');
    if (!task.notificationEnabled) {
      Logger.error(' タスクの通知がOFFのためスキップ');
      return;
    }

    // 完了タスクには通知しない
    if (columnName == '完了') {
      Logger.error(' 完了タスクのためスキップ');
      return;
    }

    // 既存の通知をキャンセル
    await cancelTaskNotifications(taskId);

    // 全ての通知タイミングを取得
    final allTimings = await _getAllNotificationTimings(task);
    Logger.log('通知タイミング数: ${allTimings.length}');

    // 通知数制限（最大5個）
    if (allTimings.length > 5) {
      Logger.warning(' 通知が5個を超えるため、最初の5個のみスケジュール');
      allTimings.removeRange(5, allTimings.length);
    }

    // 各タイミングで通知をスケジュール
    int notificationId = _generateNotificationId(taskId);
    for (var timing in allTimings) {
      await _scheduleNotification(
        task,
        taskId,
        timing,
        notificationId++,
      );
    }
    
    Logger.sectionEnd(' scheduleTaskNotifications 完了 ');
  }

  // 全ての通知タイミングを取得（統合＆ソート）
  static Future<List<NotificationTiming>> _getAllNotificationTimings(
      Task task) async {
    List<NotificationTiming> allTimings = [];

    // 通知セットのタイミングを追加
    final notificationSets = await NotificationSetService.loadNotificationSets();
    for (var setId in task.notificationSetIds) {
      final set =
          NotificationSetService.getNotificationSetById(notificationSets, setId);
      if (set != null) {
        Logger.log('通知セット「${set.name}」を追加: ${set.timings.length}個');
        allTimings.addAll(set.timings);
      }
    }

    // カスタム通知を追加
    Logger.log('カスタム通知を追加: ${task.customTimings.length}個');
    allTimings.addAll(task.customTimings);

    // 重複を削除してソート（近い順）
    final uniqueTimings = allTimings.toSet().toList()
      ..sort((a, b) => a.compareTo(b));

    Logger.log('統合後の通知数: ${uniqueTimings.length}個');
    for (var timing in uniqueTimings) {
      Logger.log('  - ${timing.displayText}');
    }

    return uniqueTimings;
  }

  // 個別の通知をスケジュール
  static Future<void> _scheduleNotification(
    Task task,
    String taskId,
    NotificationTiming timing,
    int notificationId,
  ) async {
    Logger.log('\n--- 通知スケジュール開始 ---');
    Logger.log('タスクID: $taskId');
    Logger.log('通知ID: $notificationId');
    Logger.log('タイミング: ${timing.displayText}');
    
    // 通知時刻を計算
    final notificationTime = task.deadline.subtract(Duration(
      days: timing.days,
      hours: timing.hours,
      minutes: timing.minutes,
    ));

    Logger.log('締切時刻: ${task.deadline}');
    Logger.log('通知時刻: $notificationTime');
    Logger.log('現在時刻: ${DateTime.now()}');
    
    // 過去の時刻の場合はスケジュールしない
    if (notificationTime.isBefore(DateTime.now())) {
      Logger.error(' 過去の時刻のためスキップ');
      Logger.log('--- 通知スケジュール終了 ---\n');
      return;
    }
    
    Logger.success(' 通知をスケジュールします');

    // 優先度アイコン
    final priorityIcon = _getPriorityIcon(task.priority);

    // 通知内容
    final title = '$priorityIcon ${task.title}';
    final body =
        '${timing.displayText}\n締切: ${_formatDeadline(task.deadline)}';

    Logger.log('通知タイトル: $title');
    Logger.log('通知本文: $body');

    // バイブレーション設定を取得
    final vibration = await _shouldVibrate(task);
    Logger.log('バイブレーション: $vibration');

    // Android通知詳細
final androidDetails = notifications.AndroidNotificationDetails(
  'task_notifications',
  'タスク通知',
  channelDescription: 'タスクの締切通知',
  importance: notifications.Importance.max,
  priority: notifications.Priority.max,
  enableVibration: vibration,
  playSound: true,
  showWhen: true,
  visibility: notifications.NotificationVisibility.public,
  channelShowBadge: true,
  autoCancel: false,
  styleInformation: notifications.BigTextStyleInformation(body),
  actions: <notifications.AndroidNotificationAction>[
    notifications.AndroidNotificationAction(
      'complete',
      '完了',
      showsUserInterface: true,
      cancelNotification: false,
    ),
    notifications.AndroidNotificationAction(
      'details',
      '詳細を見る',
      showsUserInterface: true,
      cancelNotification: false,
    ),
  ],
);

// iOS通知詳細（カテゴリーIDを追加）
const iosDetails = notifications.DarwinNotificationDetails(
  presentAlert: true,
  presentBadge: true,
  presentSound: true,
  categoryIdentifier: 'task_notification', // カテゴリーIDを指定
);

    final notificationDetails = notifications.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // タイムゾーンを明示的に設定
      final scheduledDate = tz.TZDateTime(
        tz.local,
        notificationTime.year,
        notificationTime.month,
        notificationTime.day,
        notificationTime.hour,
        notificationTime.minute,
        notificationTime.second,
      );
      
      final now = tz.TZDateTime.now(tz.local);
      final difference = scheduledDate.difference(now);
      
      Logger.log('スケジュール日時（TZ）: $scheduledDate');
      Logger.log('現在日時（TZ）: $now');
      Logger.log('差分: ${difference.inSeconds}秒後 (${difference.inMinutes}分${difference.inSeconds % 60}秒)');
      
      // 過去の時刻チェック（念のため再確認）
      if (scheduledDate.isBefore(now)) {
        Logger.error(' エラー: スケジュール時刻が過去です');
        Logger.log('--- 通知スケジュール終了（失敗） ---\n');
        return;
      }
      
      // スケジュール
      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: notifications.AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            notifications.UILocalNotificationDateInterpretation.absoluteTime,
        payload: taskId,
        matchDateTimeComponents: null,
      );

      Logger.success(' 通知スケジュール完了');
      Logger.log('通知ID: $notificationId');
    } catch (e) {
      Logger.error(' 通知スケジュールエラー: $e');
      Logger.log('エラー詳細: ${e.toString()}');
    }
    
    Logger.log('--- 通知スケジュール終了 ---\n');
  }

  // 優先度アイコンを取得
  static String _getPriorityIcon(Priority priority) {
    switch (priority) {
      case Priority.high:
        return '🔴';
      case Priority.middle:
        return '🟠';
      case Priority.low:
        return '🟢';
    }
  }

  // 締切日時をフォーマット
  static String _formatDeadline(DateTime deadline) {
    return '${deadline.year}/${deadline.month}/${deadline.day} '
        '${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}';
  }

  // バイブレーション設定を取得
  static Future<bool> _shouldVibrate(Task task) async {
    final notificationSets = await NotificationSetService.loadNotificationSets();
    for (var setId in task.notificationSetIds) {
      final set =
          NotificationSetService.getNotificationSetById(notificationSets, setId);
      if (set != null && set.vibration) {
        return true;
      }
    }
    return false;
  }

  // 通知IDを生成（タスクIDから）
  static int _generateNotificationId(String taskId) {
    return taskId.hashCode.abs() % 1000000;
  }

  // タスクの通知をキャンセル
  static Future<void> cancelTaskNotifications(String taskId) async {
    Logger.log('通知キャンセル: $taskId');
    final notificationId = _generateNotificationId(taskId);
    // 最大5個の通知をキャンセル
    for (int i = 0; i < 5; i++) {
      await _notifications.cancel(notificationId + i);
    }
  }

  // 全ての通知をキャンセル
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // テスト通知を送信（開発用）
  static Future<void> sendTestNotification() async {
    Logger.section(' テスト通知送信 ');
    const androidDetails = notifications.AndroidNotificationDetails(
      'task_notifications',
      'タスク通知',
      channelDescription: 'タスクの締切通知',
      importance: notifications.Importance.max,
      priority: notifications.Priority.max,
    );

    const iosDetails = notifications.DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = notifications.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999999,
      '🔔 テスト通知',
      'これはテスト通知です。通知が正常に動作しています。',
      notificationDetails,
    );
    Logger.success(' テスト通知送信完了');
  }

  // 1分後通知テスト（開発用）
  // 1分後通知テスト（開発用）
  static Future<void> sendTestNotificationIn1Minute() async {
    Logger.section(' 1分後通知テスト ');
    
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(Duration(minutes: 1));
    
    Logger.log('現在時刻（詳細）: ${now.year}/${now.month}/${now.day} ${now.hour}:${now.minute}:${now.second}');
    Logger.log('通知時刻（詳細）: ${scheduledDate.year}/${scheduledDate.month}/${scheduledDate.day} ${scheduledDate.hour}:${scheduledDate.minute}:${scheduledDate.second}');
    
    final difference = scheduledDate.difference(now);
    Logger.log('差分: ${difference.inSeconds}秒後 (${difference.inMinutes}分${difference.inSeconds % 60}秒)');

final androidDetails = notifications.AndroidNotificationDetails(
  'task_notifications',
  'タスク通知',
  channelDescription: 'タスクの締切通知',
  importance: notifications.Importance.max,
  priority: notifications.Priority.max,
  showWhen: true,
  enableVibration: true,
  playSound: true,
  visibility: notifications.NotificationVisibility.public,
  channelShowBadge: true,
  autoCancel: false,
  styleInformation: notifications.BigTextStyleInformation(
    'これは1分後に送信されるテスト通知です\n時刻: ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}',
  ),
  actions: <notifications.AndroidNotificationAction>[
    notifications.AndroidNotificationAction(
      'complete',
      '完了',
      showsUserInterface: true,
      cancelNotification: false,
    ),
    notifications.AndroidNotificationAction(
      'details',
      '詳細を見る',
      showsUserInterface: true,
      cancelNotification: false,
    ),
  ],
);

    const iosDetails = notifications.DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = notifications.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
await _notifications.zonedSchedule(
  999998,
  '🔔 1分後テスト通知',
  'これは1分後に送信されるテスト通知です\n時刻: ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}',
  scheduledDate,
  notificationDetails,
  androidScheduleMode: notifications.AndroidScheduleMode.exactAllowWhileIdle,
  uiLocalNotificationDateInterpretation:
      notifications.UILocalNotificationDateInterpretation.absoluteTime,
  payload: '999998',  // テスト用のダミーID
  matchDateTimeComponents: null,
);

      Logger.success(' 1分後通知をスケジュールしました');
      Logger.log('通知ID: 999998');
      
      // スケジュール済み通知を確認
      await printPendingNotifications();
      
    } catch (e) {
      Logger.error(' エラー: $e');
      Logger.log('エラー詳細: ${e.toString()}');
      Logger.log('スタックトレース: ${StackTrace.current}');
    }
  }

  // アラーム権限の設定画面を開く
  static Future<void> openAlarmSettings() async {
    if (Platform.isAndroid) {
      await openAppSettings();
    }
  }

  // 正確なアラーム権限があるか確認
  static Future<bool> hasExactAlarmPermission() async {
    if (Platform.isAndroid) {
      // Android 12以上
      final status = await Permission.scheduleExactAlarm.status;
      Logger.log('正確なアラーム権限: $status');
      return status.isGranted;
    }
    return true;
  }

  // 正確なアラーム権限を設定画面で有効化するよう促す
  static Future<bool> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.scheduleExactAlarm.status;
      
      if (status.isDenied || status.isPermanentlyDenied) {
        // 設定画面を開く
        Logger.log('設定画面を開きます');
        await openAppSettings();
        return false;
      }
      
      return status.isGranted;
    }
    return true;
  }

  // 通知権限とアラーム権限の両方をチェック
  static Future<Map<String, bool>> checkAllPermissions() async {
    final notificationGranted = Platform.isAndroid
        ? await Permission.notification.isGranted
        : true;
    
    final alarmGranted = await hasExactAlarmPermission();
    
    return {
      'notification': notificationGranted,
      'exactAlarm': alarmGranted,
    };
  }

  // スケジュール済み通知の一覧を取得（デバッグ用）
  static Future<void> printPendingNotifications() async {
    Logger.section(' スケジュール済み通知一覧 ');
    
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        notifications.AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) {
      Logger.error(' AndroidPlugin が取得できません');
      return;
    }
    
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    
    if (pendingNotifications.isEmpty) {
      Logger.log('📭 スケジュール済み通知はありません');
    } else {
      Logger.log('📬 スケジュール済み通知: ${pendingNotifications.length}件');
      for (var notification in pendingNotifications) {
        Logger.log('   ID: ${notification.id}');
        Logger.log('   タイトル: ${notification.title}');
        Logger.log('   本文: ${notification.body}');
        Logger.log('   payload: ${notification.payload}');
        Logger.log('   ---');
      }
    }
    
    Logger.sectionEnd(' 通知一覧');
  }
}
