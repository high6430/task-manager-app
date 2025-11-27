import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/label.dart';
import '../models/notification_set.dart';
import '../models/notification_timing.dart';
import '../services/notification_set_service.dart';

class EditTaskDialog extends StatefulWidget {
  final Task task;
  final Function(Task) onTaskUpdated;
  final List<Label> availableLabels; // 外部から受け取る

  const EditTaskDialog({
    Key? key,
    required this.task,
    required this.onTaskUpdated,
    required this.availableLabels, // 追加
  }) : super(key: key);

  @override
  _EditTaskDialogState createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  late Priority selectedPriority;
  Set<String> selectedLabelIds = {};
  
  // 通知関連
  List<NotificationSet> availableNotificationSets = [];
  Set<String> selectedNotificationSetIds = {};
  List<NotificationTiming> customTimings = [];
  bool notificationEnabled = true;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task.title);
    descriptionController = TextEditingController(text: widget.task.description);
    selectedDate = DateTime(
      widget.task.deadline.year,
      widget.task.deadline.month,
      widget.task.deadline.day,
    );
    selectedTime = TimeOfDay(
      hour: widget.task.deadline.hour,
      minute: widget.task.deadline.minute,
    );
    selectedPriority = widget.task.priority;
    selectedLabelIds = Set.from(widget.task.labelIds);
    selectedNotificationSetIds = Set.from(widget.task.notificationSetIds);
    customTimings = List.from(widget.task.customTimings);
    notificationEnabled = widget.task.notificationEnabled;
    _loadNotificationSets();
  }

  Future<void> _loadNotificationSets() async {
    final sets = await NotificationSetService.loadNotificationSets();
    if (mounted) {
      setState(() {
        availableNotificationSets = sets;
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  String getTimeText() {
    return '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
  }

  void _addCustomTiming() {
    showDialog(
      context: context,
      builder: (context) => _CustomTimingDialog(
        onAdd: (timing) {
          setState(() {
            customTimings.add(timing);
          });
        },
      ),
    );
  }

  void _updateTask() {
    print('🔧 _updateTask が呼ばれました');
    
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルを入力してください')),
      );
      return;
    }

    final deadline = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final updatedTask = Task(
      titleController.text,
      deadline,
      id: widget.task.id,
      priority: selectedPriority,
      description: descriptionController.text,
      labelIds: selectedLabelIds.toList(),
      notificationSetIds: selectedNotificationSetIds.toList(),
      customTimings: customTimings,
      notificationEnabled: notificationEnabled,
    );

    print('更新タスク作成完了: ${updatedTask.title}');
    print('widget.onTaskUpdated を呼び出します');
    
    widget.onTaskUpdated(updatedTask);
    
    print('✅ widget.onTaskUpdated 呼び出し完了');
    // Navigator.pop(context)はTaskDetailScreenで呼ぶ
  }

  @override
  Widget build(BuildContext context) {
    // カスタム通知を近い順にソート
    final sortedCustomTimings = List<NotificationTiming>.from(customTimings)
      ..sort((a, b) => a.compareTo(b));

    return AlertDialog(
      title: const Text('タスクを編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'タイトル'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '詳細（任意）',
                hintText: 'タスクの詳細を入力',
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '締め切り日: ${selectedDate.year}/${selectedDate.month}/${selectedDate.day} ${getTimeText()}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Column(
                  children: [
                    ElevatedButton(
                      child: const Text('日付選択'),
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    ElevatedButton(
                      child: const Text('時間選択'),
                      onPressed: () async {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (pickedTime != null) {
                          setState(() {
                            selectedTime = pickedTime;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                const Text('優先度: ', style: TextStyle(fontSize: 16)),
                DropdownButton<Priority>(
                  value: selectedPriority,
                  items: Priority.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              p == Priority.high
                                  ? '高'
                                  : p == Priority.middle
                                      ? '中'
                                      : '低',
                            ),
                          ))
                      .toList(),
                  onChanged: (p) {
                    if (p != null) {
                      setState(() {
                        selectedPriority = p;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.availableLabels.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ラベル:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              ...widget.availableLabels.map((label) {
                final isSelected = selectedLabelIds.contains(label.id);
                return CheckboxListTile(
                  title: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: label.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(label.name),
                    ],
                  ),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedLabelIds.add(label.id);
                      } else {
                        selectedLabelIds.remove(label.id);
                      }
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ],
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            // 通知設定
            CheckboxListTile(
              title: const Text(
                '通知設定',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              value: notificationEnabled,
              onChanged: (bool? value) {
                setState(() {
                  notificationEnabled = value ?? true;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (notificationEnabled) ...[
              const SizedBox(height: 8),
              if (availableNotificationSets.isNotEmpty) ...[
                const Text(
                  '通知セット:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...availableNotificationSets.map((set) {
                  final isSelected = selectedNotificationSetIds.contains(set.id);
                  return CheckboxListTile(
                    title: Text(set.name),
                    subtitle: Text(
                      set.timings.map((t) => t.displayText).join(', '),
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedNotificationSetIds.add(set.id);
                        } else {
                          selectedNotificationSetIds.remove(set.id);
                        }
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'カスタム通知:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('追加'),
                    onPressed: _addCustomTiming,
                  ),
                ],
              ),
              if (sortedCustomTimings.isEmpty)
                const Text(
                  'カスタム通知なし',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ...sortedCustomTimings.map((timing) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(timing.displayText, style: const TextStyle(fontSize: 14)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        customTimings.remove(timing);
                      });
                    },
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('キャンセル'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('保存'),
          onPressed: _updateTask,
        ),
      ],
    );
  }
}

// カスタム通知タイミング入力ダイアログ
class _CustomTimingDialog extends StatefulWidget {
  final Function(NotificationTiming) onAdd;

  const _CustomTimingDialog({required this.onAdd});

  @override
  _CustomTimingDialogState createState() => _CustomTimingDialogState();
}

class _CustomTimingDialogState extends State<_CustomTimingDialog> {
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
        const SnackBar(content: Text('1以上の値を入力してください')),
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
        const SnackBar(content: Text('最大180日までです')),
      );
      return;
    }

    if (totalMinutes < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最小1分です')),
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
      title: const Text('カスタム通知を追加'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<TimeUnit>(
            value: selectedUnit,
            isExpanded: true,
            items: const [
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
          const SizedBox(height: 16),
          if (selectedUnit == TimeUnit.hours) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: valueController,
                    decoration: const InputDecoration(labelText: '時間'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: minutesController,
                    decoration: const InputDecoration(labelText: '分'),
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
          child: const Text('キャンセル'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('追加'),
          onPressed: _add,
        ),
      ],
    );
  }
}
