import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(TaskManagerApp());
}

enum Priority { high, middle, low }

class Task {
  final String title;
  final DateTime deadline;
  final Priority priority;

  Task(this.title, this.deadline, {this.priority = Priority.middle});

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'deadline': deadline.toIso8601String(),
      'priority': priority.index,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      json['title'],
      DateTime.parse(json['deadline']),
      priority: Priority.values[json['priority']],
    );
  }
}

class TaskManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'タスク管理アプリ',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TaskBoardScreen(),
    );
  }
}

class TaskBoardScreen extends StatefulWidget {
  @override
  _TaskBoardScreenState createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen> {
  List<Task> todoTasks = [];
  List<Task> doingTasks = [];
  List<Task> doneTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final todoString = prefs.getString('todoTasks');
    final doingString = prefs.getString('doingTasks');
    final doneString = prefs.getString('doneTasks');

    setState(() {
      todoTasks = todoString != null
          ? List<Task>.from(json.decode(todoString).map((x) => Task.fromJson(x)))
          : [];
      doingTasks = doingString != null
          ? List<Task>.from(json.decode(doingString).map((x) => Task.fromJson(x)))
          : [];
      doneTasks = doneString != null
          ? List<Task>.from(json.decode(doneString).map((x) => Task.fromJson(x)))
          : [];
    });
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('todoTasks', json.encode(todoTasks.map((x) => x.toJson()).toList()));
    prefs.setString('doingTasks', json.encode(doingTasks.map((x) => x.toJson()).toList()));
    prefs.setString('doneTasks', json.encode(doneTasks.map((x) => x.toJson()).toList()));
  }

  void _addTaskDialog() {
    final titleController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    Priority? selectedPriority;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            String getTimeText() {
              if (selectedTime != null) {
                return "${selectedTime!.hour.toString().padLeft(2,'0')}:${selectedTime!.minute.toString().padLeft(2,'0')}";
              } else {
                return "00:00";
              }
            }

            return AlertDialog(
              title: Text("新しいタスクを追加"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: "タイトル"),
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
                                setStateDialog(() {
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
                                setStateDialog(() {
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
                        value: selectedPriority ?? Priority.middle,
                        items: Priority.values
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    p == Priority.high
                                        ? "高"
                                        : p == Priority.middle
                                            ? "中"
                                            : "下",
                                  ),
                                ))
                            .toList(),
                        onChanged: (p) {
                          setStateDialog(() {
                            selectedPriority = p;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text("キャンセル"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: Text("追加"),
                  onPressed: () {
                    if (titleController.text.isNotEmpty && selectedDate != null) {
                      final deadline = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime?.hour ?? 0,
                        selectedTime?.minute ?? 0,
                      );
                      setState(() {
                        todoTasks.add(Task(
                            titleController.text, deadline,
                            priority: selectedPriority ?? Priority.middle));
                        todoTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
                        _saveTasks();
                      });
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
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

  Widget buildTaskCard(Task task, String currentColumn) {
    final cardColor = _getDeadlineColor(task.deadline);
    final textColor = _getTextColor(cardColor);

    List<Widget> moveButtons = [];

    if (currentColumn == "未対応") {
      moveButtons.add(
        ElevatedButton(
          child: Text("進行中へ"),
          onPressed: () {
            setState(() {
              todoTasks.remove(task);
              doingTasks.add(task);
              doingTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
              _saveTasks();
            });
          },
        ),
      );
    } else if (currentColumn == "進行中") {
      moveButtons.addAll([
        ElevatedButton(
          child: Text("未対応へ"),
          onPressed: () {
            setState(() {
              doingTasks.remove(task);
              todoTasks.add(task);
              todoTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
              _saveTasks();
            });
          },
        ),
        ElevatedButton(
          child: Text("完了へ"),
          onPressed: () {
            setState(() {
              doingTasks.remove(task);
              doneTasks.add(task);
              doneTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
              _saveTasks();
            });
          },
        ),
      ]);
    } else if (currentColumn == "完了") {
      moveButtons.add(
        ElevatedButton(
          child: Text("進行中へ"),
          onPressed: () {
            setState(() {
              doneTasks.remove(task);
              doingTasks.add(task);
              doingTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
              _saveTasks();
            });
          },
        ),
      );
    }

    final deleteButton = ElevatedButton(
      child: Text("削除"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.withOpacity(0.5),
        foregroundColor: Colors.white,
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        setState(() {
          if (currentColumn == "未対応") {
            todoTasks.remove(task);
          } else if (currentColumn == "進行中") {
            doingTasks.remove(task);
          } else if (currentColumn == "完了") {
            doneTasks.remove(task);
          }
          _saveTasks();
        });
      },
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

  Widget buildTaskColumn(String title, List<Task> tasks) {
    tasks.sort((a, b) => a.deadline.compareTo(b.deadline));

    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return buildTaskCard(task, title);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("タスク管理")),
      body: Row(
        children: [
          buildTaskColumn("未対応", todoTasks),
          buildTaskColumn("進行中", doingTasks),
          buildTaskColumn("完了", doneTasks),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _addTaskDialog,
      ),
    );
  }
}
