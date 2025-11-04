import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/label.dart';
import '../services/label_service.dart';
import 'label_chip.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final String currentColumn;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onMoveToTodo;
  final VoidCallback? onMoveToDoing;
  final VoidCallback? onMoveToDone;

  const TaskCard({
    Key? key,
    required this.task,
    required this.currentColumn,
    required this.onDelete,
    this.onEdit,
    this.onMoveToTodo,
    this.onMoveToDoing,
    this.onMoveToDone,
  }) : super(key: key);

  @override
  _TaskCardState createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  List<Label> availableLabels = [];

  @override
  void initState() {
    super.initState();
    _loadLabels();
  }

  Future<void> _loadLabels() async {
    final labels = await LabelService.loadLabels();
    setState(() {
      availableLabels = labels;
    });
  }

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

  List<Label> _getTaskLabels() {
    return widget.task.labelIds
        .map((id) => LabelService.getLabelById(availableLabels, id))
        .where((label) => label != null)
        .cast<Label>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _getDeadlineColor(widget.task.deadline);
    final textColor = _getTextColor(cardColor);
    final taskLabels = _getTaskLabels();

    List<Widget> actionButtons = [];

    // 移動ボタン
    if (widget.currentColumn == '未対応') {
      if (widget.onMoveToDoing != null) {
        actionButtons.add(
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size(100, 40),
            ),
            child: Text('進行中へ', style: TextStyle(fontSize: 14)),
            onPressed: widget.onMoveToDoing,
          ),
        );
      }
    } else if (widget.currentColumn == '進行中') {
      if (widget.onMoveToTodo != null) {
        actionButtons.add(
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size(100, 40),
            ),
            child: Text('未対応へ', style: TextStyle(fontSize: 14)),
            onPressed: widget.onMoveToTodo,
          ),
        );
      }
      if (widget.onMoveToDone != null) {
        actionButtons.add(
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size(100, 40),
            ),
            child: Text('完了へ', style: TextStyle(fontSize: 14)),
            onPressed: widget.onMoveToDone,
          ),
        );
      }
    } else if (widget.currentColumn == '完了') {
      if (widget.onMoveToDoing != null) {
        actionButtons.add(
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size(100, 40),
            ),
            child: Text('進行中へ', style: TextStyle(fontSize: 14)),
            onPressed: widget.onMoveToDoing,
          ),
        );
      }
    }

    // 編集ボタン
    if (widget.onEdit != null) {
      actionButtons.add(
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size(100, 40),
          ),
          child: Text('編集', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          onPressed: widget.onEdit,
        ),
      );
    }

    // 削除ボタン（小さいまま）
    actionButtons.add(
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.withOpacity(0.5),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size(0, 40),
        ),
        child: Text('削除', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        onPressed: widget.onDelete,
      ),
    );

    return Card(
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
                    widget.task.title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.circle, color: _priorityColor(widget.task.priority), size: 14),
              ],
            ),
            if (taskLabels.isNotEmpty) ...[
              SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: taskLabels.map((label) => LabelChip(label: label, small: true)).toList(),
              ),
            ],
            if (widget.task.description.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                '詳細:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
              ),
              SizedBox(height: 2),
              Text(
                widget.task.description,
                style: TextStyle(fontSize: 12, color: textColor),
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ],
            SizedBox(height: 4),
            Text(
              '締め切り: ${widget.task.deadline.year}/${widget.task.deadline.month}/${widget.task.deadline.day} '
              '${widget.task.deadline.hour.toString().padLeft(2, '0')}:${widget.task.deadline.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 4.0,
              runSpacing: 4.0,
              children: actionButtons,
            ),
          ],
        ),
      ),
    );
  }
}
