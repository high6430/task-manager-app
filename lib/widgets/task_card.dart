import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/label.dart';
import '../services/label_service.dart';
import '../screens/task_detail_screen.dart';
import 'label_chip.dart';
import 'package:pikado/utils/logger.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final String currentColumn;
  final List<Label> availableLabels; // 外部から受け取る
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onMoveToTodo;
  final VoidCallback? onMoveToDoing;
  final VoidCallback? onMoveToDone;
  final Function(Task)? onTaskUpdated;

  const TaskCard({
    Key? key,
    required this.task,
    required this.currentColumn,
    required this.availableLabels, // 追加
    required this.onDelete,
    this.onEdit,
    this.onMoveToTodo,
    this.onMoveToDoing,
    this.onMoveToDone,
    this.onTaskUpdated,
  }) : super(key: key);

  Color _getDeadlineColor(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);

    // 過去の日付（前日以前）
    if (deadlineDate.isBefore(today)) {
      return Colors.red.shade200;
    }

    // 当日
    if (deadlineDate.isAtSameMomentAs(today)) {
      // 締切時刻を過ぎているかチェック
      if (now.isAfter(deadline)) {
        return Colors.red.shade200; // 時刻を過ぎた
      } else {
        return Colors.orange.shade200; // まだ時刻前
      }
    }

    // 未来の日付（翌日以降）
    return Colors.green.shade200;
  }

  Color _getTextColor(Color background) {
    double brightness =
        (background.red * 299 +
            background.green * 587 +
            background.blue * 114) /
        1000;
    return brightness > 128 ? Colors.black : Colors.white;
  }

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.high:
        return Colors.red;
      case Priority.middle:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  List<Label> _getTaskLabels() {
    return task.labelIds
        .map((id) => LabelService.getLabelById(availableLabels, id))
        .where((label) => label != null)
        .cast<Label>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _getDeadlineColor(task.deadline);
    final textColor = _getTextColor(cardColor);
    final taskLabels = _getTaskLabels();

    List<Widget> actionButtons = [];

    // 移動ボタン
    if (currentColumn == '未対応') {
      if (onMoveToDoing != null) {
        actionButtons.add(
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size(100, 40),
            ),
            child: Text('進行中へ', style: TextStyle(fontSize: 14)),
            onPressed: onMoveToDoing,
          ),
        );
      }
    } else if (currentColumn == '進行中') {
      if (onMoveToTodo != null) {
        actionButtons.add(
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size(100, 40),
            ),
            child: Text('未対応へ', style: TextStyle(fontSize: 14)),
            onPressed: onMoveToTodo,
          ),
        );
      }
      if (onMoveToDone != null) {
        actionButtons.add(
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size(100, 40),
            ),
            child: Text('完了へ', style: TextStyle(fontSize: 14)),
            onPressed: onMoveToDone,
          ),
        );
      }
    } else if (currentColumn == '完了') {
      if (onMoveToDoing != null) {
        actionButtons.add(
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size(100, 40),
            ),
            child: Text('進行中へ', style: TextStyle(fontSize: 14)),
            onPressed: onMoveToDoing,
          ),
        );
      }
    }

    // 編集ボタン
    if (onEdit != null) {
      actionButtons.add(
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size(100, 40),
          ),
          child: Text(
            '編集',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          onPressed: onEdit,
        ),
      );
    }

    // 削除ボタン
    actionButtons.add(
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.withOpacity(0.5),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size(0, 40),
        ),
        child: Text(
          '削除',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        onPressed: onDelete,
      ),
    );

    return GestureDetector(
      onLongPress: () async {
        Logger.log('🔵🔵🔵 タスクカード長押し 🔵🔵🔵');
        Logger.log('タスクID: ${task.id}');
        Logger.log('タスク名: ${task.title}');
        Logger.log('currentColumn: $currentColumn');
        Logger.log('onMoveToDone is null: ${onMoveToDone == null}');
        Logger.log('onTaskUpdated is null: ${onTaskUpdated == null}');

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(
              task: task,
              currentColumn: currentColumn,
              availableLabels: availableLabels, // ラベルを渡す
              onTaskUpdated: (updatedTask) {
                Logger.log('🔄 TaskCard: onTaskUpdated が呼ばれました');
                Logger.log('更新後タスクID: ${updatedTask.id}');
                Logger.log('更新後タスク名: ${updatedTask.title}');

                if (onTaskUpdated != null) {
                  Logger.log('widget.onTaskUpdated を呼び出します');
                  onTaskUpdated!(updatedTask);
                  Logger.success(' widget.onTaskUpdated 呼び出し完了');
                } else {
                  Logger.error(' エラー: widget.onTaskUpdated が null です');
                }
              },
              onComplete: currentColumn != '完了'
                  ? () {
                      Logger.success(' TaskCard: onComplete が呼ばれました');
                      Logger.log('currentColumn: $currentColumn');

                      if (onMoveToDone != null) {
                        Logger.log('widget.onMoveToDone を呼び出します');
                        onMoveToDone!();
                        Logger.success(' widget.onMoveToDone 呼び出し完了');
                      } else {
                        Logger.error(' エラー: widget.onMoveToDone が null です');
                      }
                    }
                  : null,
            ),
          ),
        );

        Logger.log('🔵🔵🔵 タスクカード長押し終了 🔵🔵🔵\n');
      },
      child: Card(
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      overflow: TextOverflow.visible,
                      softWrap: true,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.circle,
                    color: _priorityColor(task.priority),
                    size: 14,
                  ),
                ],
              ),
              if (taskLabels.isNotEmpty) ...[
                SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: taskLabels
                      .map((label) => LabelChip(label: label, small: true))
                      .toList(),
                ),
              ],
              if (task.description.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  '詳細:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  task.description,
                  style: TextStyle(fontSize: 12, color: textColor),
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ],
              SizedBox(height: 4),
              Text(
                '締め切り: ${task.deadline.year}/${task.deadline.month}/${task.deadline.day} '
                '${task.deadline.hour.toString().padLeft(2, '0')}:${task.deadline.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 8),
              Wrap(spacing: 4.0, runSpacing: 4.0, children: actionButtons),
            ],
          ),
        ),
      ),
    );
  }
}
