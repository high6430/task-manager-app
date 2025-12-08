import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/app_settings_service.dart';
import '../services/notification_service.dart';
import 'label_settings_screen.dart';
import 'notification_set_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings settings = AppSettings();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final loadedSettings = await AppSettingsService.loadSettings();
    setState(() {
      settings = loadedSettings;
    });
  }

  Future<void> _toggleNotification(bool value) async {
    await AppSettingsService.toggleNotification(value);
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          // 通知設定セクション
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '通知',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          SwitchListTile(
            title: const Text('通知を有効にする'),
            subtitle: const Text('アプリ全体の通知のON/OFF'),
            value: settings.notificationEnabled,
            onChanged: _toggleNotification,
          ),
          const Divider(),
          
          // 管理画面へのリンク
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '管理',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.label, color: Colors.green),
            title: const Text('ラベル管理'),
            subtitle: const Text('ラベルの追加・編集・削除'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LabelSettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.orange),
            title: const Text('通知セット管理'),
            subtitle: const Text('通知セットの追加・編集・削除'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationSetSettingsScreen()),
              );
            },
          ),
          const Divider(),
          
          // ヘルプ
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'ヘルプ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.alarm, color: Colors.purple),
            title: const Text('アラーム権限の設定'),
            subtitle: const Text('通知が届かない場合、ここから設定してください'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('アラーム権限の設定'),
                  content: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Android 12以降では、正確な時刻に通知を送るために「アラームとリマインダー」の権限が必要です。',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '設定手順:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('1. 「設定を開く」ボタンをタップ'),
                        Text('2. 「アラームとリマインダー」を探す'),
                        Text('3. スイッチをONにする'),
                        SizedBox(height: 16),
                        Text(
                          '※この権限がOFFの場合、通知が届きません',
                          style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('キャンセル'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton(
                      child: const Text('設定を開く'),
                      onPressed: () async {
                        Navigator.pop(context);
                        await NotificationService.openAlarmSettings();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.battery_charging_full, color: Colors.red),
            title: const Text('バッテリー最適化について'),
            subtitle: const Text('通知が届かない場合の対処法'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showBatteryOptimizationDialog();
            },
          ),
          
          // アプリ情報
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'タスク管理アプリ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'バージョン 1.0.1',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 4),
                Text(
                  '学生向けタスク管理アプリ',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBatteryOptimizationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('バッテリー最適化について'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '通知が届かない場合、以下を確認してください：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('1. 通知権限の確認'),
              Text(
                '設定 > アプリ > タスク管理アプリ > 通知\n通知が「オン」になっているか確認',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              const Text('2. バッテリー最適化の除外'),
              Text(
                '設定 > バッテリー > バッテリー最適化\nこのアプリを「最適化しない」に設定',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              const Text('3. バックグラウンド実行の許可'),
              Text(
                '設定 > アプリ > タスク管理アプリ > バッテリー\n「バックグラウンドでの実行」を許可',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              const Text('4. 省電力モードの確認'),
              Text(
                '省電力モードがオンの場合、通知が遅延する可能性があります',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('閉じる'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}