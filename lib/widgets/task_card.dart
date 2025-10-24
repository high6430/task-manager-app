import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final String currentColumn;
  final VoidCallback onDelete;
  final VoidCallback? onMoveToTodo;
  final VoidCallback? onMoveToDoing;
  final VoidCallback? onMoveToDone;

  const TaskCard({
    Key? key,
    required this.task,
    required this.currentColumn,
    required this.onDelete,
    this.onMoveToTodo,
    this.onMoveToDoing,
    this.onMoveToDone,
  }) : super(key: key);

  Color _getDeadlineColor(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (deadline.isBefore(today)) {
      return Colors.red.shade200;
    } else if (deadline.year == today.year &&
        deadline.month == today.month &&
        deadline.day == today.day) {
      return Colors.orange.shade200;
    } else {
      return Colors.green.shade200;
    }
  }

  Color _getTextColor(Color background) {
    double brightness =
        (background.red * 299 + background.green * 587 + background.blue * 114) / 1000;
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

  @override
  Widget build(BuildContext context) {
    final cardColor = _getDeadlineColor(task.deadline);
    final textColor = _getTextColor(cardColor);

    List<Widget> moveButtons = [];

    if (currentColumn == "未対応") {
      if (onMoveToDoing != null) {
        moveButtons.add(
          ElevatedButton(
            child: Text("進行中へ"),
            onPressed: onMoveToDoing,
          ),
        );
      }
    } else if (currentColumn == "進行中") {
      if (onMoveToTodo != null) {
        moveButtons.add(
          ElevatedButton(
            child: Text("未対応へ"),
            onPressed: onMoveToTodo,
          ),
        );
      }
      if (onMoveToDone != null) {
        moveButtons.add(
          ElevatedButton(
            child: Text("完了へ"),
            onPressed: onMoveToDone,
          ),
        );
      }
    } else if (currentColumn == "完了") {
      if (onMoveToDoing != null) {
        moveButtons.add(
          ElevatedButton(
            child: Text("進行中へ"),
            onPressed: onMoveToDoing,
          ),
        );
      }
    }

    final deleteButton = ElevatedButton(
      child: Text("削除"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.withOpacity(0.5),
        foregroundColor: Colors.white,
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      onPressed: onDelete,
    );

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  task.title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
                SizedBox(width: 8),
                Icon(Icons.circle, color: _priorityColor(task.priority), size: 16),
              ],
            ),
            SizedBox(height: 4),
            Text(
              "締め切り: ${task.deadline.year}/${task.deadline.month}/${task.deadline.day} "
              "${task.deadline.hour.toString().padLeft(2, '0')}:${task.deadline.minute.toString().padLeft(2, '0')}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Row(
                  children: moveButtons
                      .map((b) => Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: b,
                          ))
                      .toList(),
                ),
                Spacer(),
                deleteButton,
              ],
            ),
          ],
        ),
      ),
    );
  }
}