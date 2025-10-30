import 'package:flutter/material.dart';
import '../models/task.dart';

class AddTaskDialog extends StatefulWidget {
  final Function(Task) onTaskAdded;

  const AddTaskDialog({Key? key, required this.onTaskAdded}) : super(key: key);

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  Priority selectedPriority = Priority.middle;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  String getTimeText() {
    if (selectedTime != null) {
      return "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";
    } else {
      return "00:00";
    }
  }

  void _addTask() {
    if (titleController.text.isNotEmpty && selectedDate != null) {
      final deadline = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime?.hour ?? 0,
        selectedTime?.minute ?? 0,
      );
      final task = Task(
        titleController.text,
        deadline,
        priority: selectedPriority,
        description: descriptionController.text,
      );
      widget.onTaskAdded(task);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("新しいタスクを追加"),
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
                    selectedDate == null
                        ? "締め切り日: 未選択"
                        : "締め切り日: ${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day} ${getTimeText()}",
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
                          initialDate: DateTime.now(),
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
                          initialTime: TimeOfDay.now(),
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
          child: Text("追加"),
          onPressed: _addTask,
        ),
      ],
    );
  }
}