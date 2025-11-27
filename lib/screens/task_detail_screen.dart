import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/label.dart';
import '../models/notification_set.dart';
import '../models/notification_timing.dart';
import '../services/notification_set_service.dart';
import '../widgets/label_chip.dart';
import '../widgets/edit_task_dialog.dart';
import 'package:pikado/utils/logger.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final String currentColumn;
  final List<Label> availableLabels; // 外部から受け取る
  final Function(Task) onTaskUpdated;
  final VoidCallback? onComplete;

  const TaskDetailScreen({
    Key? key,
    required this.task,
    required this.currentColumn,
    required this.availableLabels, // 追加
    required this.onTaskUpdated,
    this.onComplete,
  }) : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  List<NotificationSet> availableNotificationSets = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final sets = await NotificationSetService.loadNotificationSets();
    if (mounted) {
      setState(() {
        availableNotificationSets = sets;
      });
    }
  }

  List<Label> _getTaskLabels() {
    return widget.task.labelIds
        .map((id) => widget.availableLabels.firstWhere(
              (label) => label.id == id,
              orElse: () => Label(id: '', name: '', color: Colors.grey),
            ))
        .where((label) => label.id.isNotEmpty)
        .toList();
  }

  List<NotificationSet> _getTaskNotificationSets() {
    return widget.task.notificationSetIds
        .map(
          (id) => NotificationSetService.getNotificationSetById(
            availableNotificationSets,
            id,
          ),
        )
        .where((set) => set != null)
        .cast<NotificationSet>()
        .toList();
  }

  String _getPriorityText(Priority priority) {
    switch (priority) {
      case Priority.high:
        return '🔴 高';
      case Priority.middle:
        return '🟠 中';
      case Priority.low:
        return '🟢 低';
    }
  }

  String _getStatusText(String column) {
    switch (column) {
      case '未対応':
        return '未対応';
      case '進行中':
        return '進行中';
      case '完了':
        return '完了';
      default:
        return column;
    }
  }

  void _showCompleteConfirmDialog() {
    Logger.log('🟢🟢🟢 完了確認ダイアログを表示します 🟢🟢🟢');
    Logger.log('widget.onComplete: ${widget.onComplete}');
    Logger.log('widget.onComplete is null: ${widget.onComplete == null}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認'),
        content: Text('「${widget.task.title}」を完了にしますか？'),
        actions: [
          TextButton(
            child: const Text('キャンセル'),
            onPressed: () {
              Logger.warning(' ユーザーがキャンセルしました');
              Navigator.pop(context);
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('完了にする'),
            onPressed: () {
              Logger.success(' ユーザーが「完了にする」を選択しました');
              Navigator.pop(context); // ダイアログを閉じる
              
              if (widget.onComplete != null) {
                Logger.log('widget.onComplete を呼び出します');
                widget.onComplete!();
                Logger.success(' widget.onComplete 呼び出し完了');
              } else {
                Logger.error(' エラー: widget.onComplete が null です');
              }
              
              Navigator.pop(context); // タスク確認画面を閉じる
              Logger.success(' タスク確認画面を閉じました');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskLabels = _getTaskLabels();
    final taskNotificationSets = _getTaskNotificationSets();

    // 全ての通知タイミングを統合してソート
    List<NotificationTiming> allTimings = [];

    // 通知セットのタイミングを追加
    for (var set in taskNotificationSets) {
      allTimings.addAll(set.timings);
    }

    // カスタム通知を追加
    allTimings.addAll(widget.task.customTimings);

    // 重複を削除してソート（近い順）
    final uniqueTimings = allTimings.toSet().toList()
      ..sort((a, b) => a.compareTo(b));

    return Scaffold(
      appBar: AppBar(title: const Text('タスク確認')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Text(
              widget.task.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ラベル
            if (taskLabels.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: taskLabels
                    .map((label) => LabelChip(label: label))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 詳細
            if (widget.task.description.isNotEmpty) ...[
              const Text(
                '詳細:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.task.description,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 締切
            _buildInfoRow(
              '締切:',
              '${widget.task.deadline.year}/${widget.task.deadline.month}/${widget.task.deadline.day} '
                  '${widget.task.deadline.hour.toString().padLeft(2, '0')}:${widget.task.deadline.minute.toString().padLeft(2, '0')}',
            ),
            const SizedBox(height: 12),

            // 優先度
            _buildInfoRow('優先度:', _getPriorityText(widget.task.priority)),
            const SizedBox(height: 12),

            // ステータス
            _buildInfoRow('ステータス:', _getStatusText(widget.currentColumn)),
            const SizedBox(height: 16),

            const Divider(),
            const SizedBox(height: 16),

            // 通知設定
            const Text(
              '通知設定:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (!widget.task.notificationEnabled) ...[
              const Text(
                '通知は無効です',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ] else ...[
              if (taskNotificationSets.isEmpty &&
                  widget.task.customTimings.isEmpty) ...[
                const Text(
                  '通知タイミングが設定されていません',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ] else ...[
                if (taskNotificationSets.isNotEmpty) ...[
                  const Text(
                    '通知セット:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...taskNotificationSets.map((set) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Text(
                        '・${set.name}（${set.timings.map((t) => t.displayText).join(', ')}）',
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                ],
                if (widget.task.customTimings.isNotEmpty) ...[
                  const Text(
                    'カスタム通知:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...widget.task.customTimings.map((timing) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Text(
                        '・${timing.displayText}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                ],
                const Text(
                  '実際の通知（統合後）:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...uniqueTimings.map((timing) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Text(
                      '・${timing.displayText}',
                      style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                    ),
                  );
                }).toList(),
                // デバッグ情報追加
                if (uniqueTimings.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    'デバッグ情報（通知予定時刻）:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...uniqueTimings.map((timing) {
                    final notificationTime = widget.task.deadline.subtract(
                      Duration(
                        days: timing.days,
                        hours: timing.hours,
                        minutes: timing.minutes,
                      ),
                    );
                    final isPast = notificationTime.isBefore(DateTime.now());
                    final now = DateTime.now();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isPast ? Colors.red[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isPast ? Colors.red : Colors.green,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '・${timing.displayText}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '通知時刻: ${notificationTime.year}/${notificationTime.month}/${notificationTime.day} '
                            '${notificationTime.hour.toString().padLeft(2, '0')}:${notificationTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '現在時刻: ${now.year}/${now.month}/${now.day} '
                            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                isPast ? Icons.cancel : Icons.check_circle,
                                size: 16,
                                color: isPast ? Colors.red : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isPast ? '過去（通知されない）' : '未来（スケジュール済み）',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isPast ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                child: const Text('閉じる'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                child: const Text('編集'),
                onPressed: () async {
                  Logger.log('🔧🔧🔧 編集ボタンがタップされました 🔧🔧🔧');
                  Logger.log('タスクID: ${widget.task.id}');
                  Logger.log('タスク名: ${widget.task.title}');
                  
                  // 編集ダイアログを開く
                  final result = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) => EditTaskDialog(
                      task: widget.task,
                      availableLabels: widget.availableLabels, // ラベルを渡す
                      onTaskUpdated: (updatedTask) async {
                        Logger.log('📝 EditTaskDialog から onTaskUpdated が呼ばれました');
                        Logger.log('更新後タスクID: ${updatedTask.id}');
                        Logger.log('更新後タスク名: ${updatedTask.title}');
                        
                        Logger.log('widget.onTaskUpdated を呼び出します（await）');
                        // タスク更新コールバックを呼び、完了を待つ
                        await widget.onTaskUpdated(updatedTask);
                        Logger.success(' widget.onTaskUpdated 呼び出し完了');
                        
                        // 更新処理が完了してからダイアログを閉じる
                        Navigator.of(dialogContext).pop(true);
                        Logger.success(' ダイアログを閉じました');
                      },
                    ),
                  );
                  
                  Logger.log('showDialog が完了しました');
                  Logger.log('result: $result');
                  
                  // ダイアログが正常に閉じられた場合、詳細画面も閉じる
                  if (result == true && mounted) {
                    Logger.log('詳細画面を閉じます');
                    Navigator.of(context).pop();
                    Logger.success(' 詳細画面を閉じました');
                  } else {
                    Logger.warning(' ダイアログがキャンセルされたか、mountedがfalseです');
                  }
                },
              ),
            ),
            if (widget.currentColumn != '完了') ...[
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('完了へ'),
                  onPressed: () {
                    Logger.log('🟢 「完了へ」ボタンがタップされました');
                    Logger.log('currentColumn: ${widget.currentColumn}');
                    Logger.log('onComplete is null: ${widget.onComplete == null}');
                    _showCompleteConfirmDialog();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
