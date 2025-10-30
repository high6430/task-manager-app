import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_dialog.dart';

class TaskBoardScreen extends StatefulWidget {
  @override
  _TaskBoardScreenState createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen> with SingleTickerProviderStateMixin {
  List<Task> todoTasks = [];
  List<Task> doingTasks = [];
  List<Task> doneTasks = [];
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  void _showDeleteConfirmDialog(Task task, String columnName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("確認"),
        content: Text("このタスクを削除しますか？\n\n「${task.title}」"),
        actions: [
          TextButton(
            child: Text("キャンセル"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text("削除"),
            onPressed: () {
              setState(() {
                if (columnName == "未対応") {
                  todoTasks.remove(task);
                } else if (columnName == "進行中") {
                  doingTasks.remove(task);
                } else if (columnName == "完了") {
                  doneTasks.remove(task);
                }
                _saveTasks();
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, String columnName) {
    tasks.sort((a, b) => a.deadline.compareTo(b.deadline));

    if (tasks.isEmpty) {
      return Center(
        child: Text(
          'タスクがありません',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          currentColumn: columnName,
          onDelete: () {
            _showDeleteConfirmDialog(task, columnName);
          },
          onMoveToTodo: columnName == "進行中"
              ? () {
                  setState(() {
                    doingTasks.remove(task);
                    todoTasks.add(task);
                    todoTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
                    _saveTasks();
                  });
                }
              : null,
          onMoveToDoing: (columnName == "未対応" || columnName == "完了")
              ? () {
                  setState(() {
                    if (columnName == "未対応") {
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
          onMoveToDone: columnName == "進行中"
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("タスク管理"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "未対応 (${todoTasks.length})"),
            Tab(text: "進行中 (${doingTasks.length})"),
            Tab(text: "完了 (${doneTasks.length})"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(todoTasks, "未対応"),
          _buildTaskList(doingTasks, "進行中"),
          _buildTaskList(doneTasks, "完了"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _addTaskDialog,
      ),
    );
  }
}