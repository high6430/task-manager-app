import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/task.dart';
import 'services/task_service.dart';
import 'widgets/task_card.dart';
import 'widgets/add_task_dialog.dart';
void main() {
  runApp(TaskManagerApp());
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
  final tasks = await TaskService.loadTasks();
  setState(() {
    todoTasks = tasks['todo']!;
    doingTasks = tasks['doing']!;
    doneTasks = tasks['done']!;
  });
}

Future<void> _saveTasks() async {
  await TaskService.saveTasks(
    todoTasks: todoTasks,
    doingTasks: doingTasks,
    doneTasks: doneTasks,
  );
}
  void _addTaskDialog() {
  showDialog(
    context: context,
    builder: (context) => AddTaskDialog(
      onTaskAdded: (task) {
        setState(() {
          todoTasks.add(task);
          todoTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
          _saveTasks();
        });
      },
    ),
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
              return TaskCard(
                task: task,
                currentColumn: title,
                onDelete: () {
                  setState(() {
                    if (title == "未対応") {
                      todoTasks.remove(task);
                    } else if (title == "進行中") {
                      doingTasks.remove(task);
                    } else if (title == "完了") {
                      doneTasks.remove(task);
                    }
                    _saveTasks();
                  });
                },
                onMoveToTodo: title == "進行中"
                    ? () {
                        setState(() {
                          doingTasks.remove(task);
                          todoTasks.add(task);
                          todoTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
                          _saveTasks();
                        });
                      }
                    : null,
                onMoveToDoing: (title == "未対応" || title == "完了")
                    ? () {
                        setState(() {
                          if (title == "未対応") {
                            todoTasks.remove(task);
                          } else {
                            doneTasks.remove(task);
                          }
                          doingTasks.add(task);
                          doingTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
                          _saveTasks();
                        });
                      }
                    : null,
                onMoveToDone: title == "進行中"
                    ? () {
                        setState(() {
                          doingTasks.remove(task);
                          doneTasks.add(task);
                          doneTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
                          _saveTasks();
                        });
                      }
                    : null,
              );
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
