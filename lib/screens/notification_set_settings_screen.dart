import 'package:flutter/material.dart';
import '../models/notification_set.dart';
import '../models/notification_timing.dart';
import '../models/task.dart';
import '../services/notification_set_service.dart';
import '../services/task_service.dart';

class NotificationSetSettingsScreen extends StatefulWidget {
  @override
  _NotificationSetSettingsScreenState createState() =>
      _NotificationSetSettingsScreenState();
}

class _NotificationSetSettingsScreenState
    extends State<NotificationSetSettingsScreen> {
  List<NotificationSet> notificationSets = [];

  @override
  void initState() {
    super.initState();
    _loadNotificationSets();
  }

  Future<void> _loadNotificationSets() async {
    final sets = await NotificationSetService.loadNotificationSets();
    setState(() {
      notificationSets = sets;
    });
  }

  void _addNotificationSet() {
    showDialog(
      context: context,
      builder: (context) => _NotificationSetDialog(
        onSave: (newSet) async {
          await NotificationSetService.addNotificationSet(newSet);
          _loadNotificationSets();
        },
      ),
    );
  }

  void _editNotificationSet(NotificationSet set) {
    showDialog(
      context: context,
      builder: (context) => _NotificationSetDialog(
        existingSet: set,
        onSave: (updatedSet) async {
          await NotificationSetService.updateNotificationSet(updatedSet);
          _loadNotificationSets();
        },
      ),
    );
  }

  void _deleteNotificationSet(NotificationSet set) async {
    // 使用中のタスク数を確認
    final tasks = await TaskService.loadTasks();
    final allTasks = [
      ...tasks['todo']!,
      ...tasks['doing']!,
      ...tasks['done']!,
    ];
    final usageCount = NotificationSetService.getUsageCount(set.id, allTasks);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('確認'),
        content: usageCount > 0
            ? Text(
                'この通知セットは${usageCount}個のタスクで使用中です。\n削除すると、それらのタスクから自動的に除外されます。')
            : Text('「${set.name}」を削除しますか？'),
        actions: [
          TextButton(
            child: Text('キャンセル'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('削除'),
            onPressed: () async {
              // 通知セットを削除
              await NotificationSetService.deleteNotificationSet(set.id);

              // 使用中のタスクから除外
              if (usageCount > 0) {
                final updatedTodoTasks = tasks['todo']!.map((task) {
                  if (task.notificationSetIds.contains(set.id)) {
                    final updatedIds = List<String>.from(task.notificationSetIds)
                      ..remove(set.id);
                    return Task(
                      task.title,
                      task.deadline,
                      id: task.id,  // 追加
                      priority: task.priority,
                      description: task.description,
                      labelIds: task.labelIds,
                      notificationSetIds: updatedIds,
                      customTimings: task.customTimings,
                      notificationEnabled: task.notificationEnabled,
                    );
                  }
                  return task;
                }).toList();

                final updatedDoingTasks = tasks['doing']!.map((task) {
                  if (task.notificationSetIds.contains(set.id)) {
                    final updatedIds = List<String>.from(task.notificationSetIds)
                      ..remove(set.id);
                    return Task(
                      task.title,
                      task.deadline,
                      id: task.id,  // 追加
                      priority: task.priority,
                      description: task.description,
                      labelIds: task.labelIds,
                      notificationSetIds: updatedIds,
                      customTimings: task.customTimings,
                      notificationEnabled: task.notificationEnabled,
                    );
                  }
                  return task;
                }).toList();

                final updatedDoneTasks = tasks['done']!.map((task) {
                  if (task.notificationSetIds.contains(set.id)) {
                    final updatedIds = List<String>.from(task.notificationSetIds)
                      ..remove(set.id);
                    return Task(
                      task.title,
                      task.deadline,
                      id: task.id,  // 追加
                      priority: task.priority,
                      description: task.description,
                      labelIds: task.labelIds,
                      notificationSetIds: updatedIds,
                      customTimings: task.customTimings,
                      notificationEnabled: task.notificationEnabled,
                    );
                  }
                  return task;
                }).toList();

                await TaskService.saveTasks(
                  todoTasks: updatedTodoTasks,
                  doingTasks: updatedDoingTasks,
                  doneTasks: updatedDoneTasks,
                );
              }

              Navigator.pop(context);
              _loadNotificationSets();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('通知セット管理'),
      ),
      body: notificationSets.isEmpty
          ? Center(
              child: Text(
                '通知セットがありません',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: notificationSets.length,
              itemBuilder: (context, index) {
                final set = notificationSets[index];
                // タイミングを近い順にソート
                final sortedTimings = List<NotificationTiming>.from(set.timings)
                  ..sort((a, b) => a.compareTo(b));

                return Card(
                  child: ListTile(
                    title: Text(
                      set.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        ...sortedTimings.map((timing) => Text('・${timing.displayText}')),
                        SizedBox(height: 4),
                        Text(
                          'バイブレーション: ${set.vibration ? "ON" : "OFF"}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editNotificationSet(set),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNotificationSet(set),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _addNotificationSet,
      ),
    );
  }
}

// 通知セット追加・編集ダイアログ
class _NotificationSetDialog extends StatefulWidget {
  final NotificationSet? existingSet;
  final Function(NotificationSet) onSave;

  const _NotificationSetDialog({
    this.existingSet,
    required this.onSave,
  });

  @override
  _NotificationSetDialogState createState() => _NotificationSetDialogState();
}

class _NotificationSetDialogState extends State<_NotificationSetDialog> {
  late TextEditingController nameController;
  List<NotificationTiming> timings = [];
  bool vibration = true;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.existingSet?.name ?? '',
    );
    timings = widget.existingSet != null
        ? List.from(widget.existingSet!.timings)
        : [];
    vibration = widget.existingSet?.vibration ?? true;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _addTiming() {
    showDialog(
      context: context,
      builder: (context) => _TimingInputDialog(
        onAdd: (timing) {
          setState(() {
            timings.add(timing);
          });
        },
      ),
    );
  }

  void _save() {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('名前を入力してください')),
      );
      return;
    }

    if (timings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('通知タイミングを追加してください')),
      );
      return;
    }

    final set = NotificationSet(
      id: widget.existingSet?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text,
      timings: timings,
      vibration: vibration,
    );

    widget.onSave(set);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // タイミングを近い順にソート
    final sortedTimings = List<NotificationTiming>.from(timings)
      ..sort((a, b) => a.compareTo(b));

    return AlertDialog(
      title: Text(widget.existingSet == null ? '通知セットを追加' : '通知セットを編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: '名前'),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text('通知タイミング:', style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                TextButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('追加'),
                  onPressed: _addTiming,
                ),
              ],
            ),
            SizedBox(height: 8),
            if (sortedTimings.isEmpty)
              Text('通知タイミングが設定されていません', style: TextStyle(color: Colors.grey)),
            ...sortedTimings.map((timing) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(timing.displayText),
                trailing: IconButton(
                  icon: Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      timings.remove(timing);
                    });
                  },
                ),
              );
            }).toList(),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('バイブレーション'),
              value: vibration,
              onChanged: (value) {
                setState(() {
                  vibration = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('キャンセル'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text('保存'),
          onPressed: _save,
        ),
      ],
    );
  }
}

// 通知タイミング入力ダイアログ
class _TimingInputDialog extends StatefulWidget {
  final Function(NotificationTiming) onAdd;

  const _TimingInputDialog({required this.onAdd});

  @override
  _TimingInputDialogState createState() => _TimingInputDialogState();
}

class _TimingInputDialogState extends State<_TimingInputDialog> {
  TimeUnit selectedUnit = TimeUnit.days;
  late TextEditingController valueController;
  late TextEditingController minutesController;

  @override
  void initState() {
    super.initState();
    valueController = TextEditingController(text: '1');
    minutesController = TextEditingController(text: '00');
  }

  @override
  void dispose() {
    valueController.dispose();
    minutesController.dispose();
    super.dispose();
  }

  void _add() {
    final value = int.tryParse(valueController.text) ?? 0;
    final minutes = selectedUnit == TimeUnit.hours
        ? (int.tryParse(minutesController.text) ?? 0)
        : 0;

    if (value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('1以上の値を入力してください')),
      );
      return;
    }

    // 最大180日（259200分）のチェック
    int totalMinutes = 0;
    if (selectedUnit == TimeUnit.days) {
      totalMinutes = value * 24 * 60;
    } else if (selectedUnit == TimeUnit.hours) {
      totalMinutes = value * 60 + minutes;
    } else {
      totalMinutes = value;
    }

    if (totalMinutes > 180 * 24 * 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('最大180日までです')),
      );
      return;
    }

    if (totalMinutes < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('最小1分です')),
      );
      return;
    }

    final timing = NotificationTiming(
      days: selectedUnit == TimeUnit.days ? value : 0,
      hours: selectedUnit == TimeUnit.hours ? value : 0,
      minutes: selectedUnit == TimeUnit.minutes
          ? value
          : (selectedUnit == TimeUnit.hours ? minutes : 0),
    );

    widget.onAdd(timing);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('通知タイミングを追加'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<TimeUnit>(
            value: selectedUnit,
            isExpanded: true,
            items: [
              DropdownMenuItem(value: TimeUnit.days, child: Text('日前')),
              DropdownMenuItem(value: TimeUnit.hours, child: Text('時間前')),
              DropdownMenuItem(value: TimeUnit.minutes, child: Text('分前')),
            ],
            onChanged: (value) {
              setState(() {
                selectedUnit = value!;
                if (selectedUnit != TimeUnit.hours) {
                  minutesController.text = '00';
                }
              });
            },
          ),
          SizedBox(height: 16),
          if (selectedUnit == TimeUnit.hours) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: valueController,
                    decoration: InputDecoration(labelText: '時間'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: minutesController,
                    decoration: InputDecoration(labelText: '分'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ] else ...[
            TextField(
              controller: valueController,
              decoration: InputDecoration(
                labelText: selectedUnit == TimeUnit.days ? '日数' : '分数',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          child: Text('キャンセル'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text('追加'),
          onPressed: _add,
        ),
      ],
    );
  }
}
