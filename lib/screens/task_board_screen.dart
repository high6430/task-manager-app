import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_dialog.dart';

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