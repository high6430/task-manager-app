import 'package:flutter/material.dart';
import '../models/task.dart';

class EditTaskDialog extends StatefulWidget {
  final Task task;
  final Function(Task) onTaskUpdated;

  const EditTaskDialog({
    Key? key,
    required this.task,
    required this.onTaskUpdated,
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
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  String getTimeText() {
    return "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";
  }

  void _updateTask() {
    if (titleController.text.isNotEmpty) {
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
        priority: selectedPriority,
        description: descriptionController.text,
      );
      widget.onTaskUpdated(updatedTask);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("タスクを編集"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "タイトル"),
            ),
            SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: "詳細（任意）",
                hintText: "タスクの詳細を入力",
              ),
              maxLines: 3,
              minLines: 1,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "締め切り日: ${selectedDate.year}/${selectedDate.month}/${selectedDate.day} ${getTimeText()}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Column(
                  children: [
                    ElevatedButton(
                      child: Text("日付選択"),
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
                      child: Text("時間選択"),
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
                Text("優先度: ", style: TextStyle(fontSize: 16)),
                DropdownButton<Priority>(
                  value: selectedPriority,
                  items: Priority.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              p == Priority.high
                                  ? "高"
                                  : p == Priority.middle
                                      ? "中"
                                      : "低",
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
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text("キャンセル"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text("保存"),
          onPressed: _updateTask,
        ),
      ],
    );
  }
}