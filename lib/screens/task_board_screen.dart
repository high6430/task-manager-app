import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/label.dart';
import '../services/task_service.dart';
import '../services/label_service.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/edit_task_dialog.dart';
import 'label_settings_screen.dart';

class TaskBoardScreen extends StatefulWidget {
  @override
  _TaskBoardScreenState createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen> with SingleTickerProviderStateMixin {
  List<Task> todoTasks = [];
  List<Task> doingTasks = [];
  List<Task> doneTasks = [];
  List<Label> availableLabels = [];
  String? selectedLabelId; // null = すべて表示
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadTasks();
    await _loadLabels();
  }

  Future<void> _loadTasks() async {
    final tasks = await TaskService.loadTasks();
    setState(() {
      todoTasks = tasks['todo']!;
      doingTasks = tasks['doing']!;
      doneTasks = tasks['done']!;
    });
  }

  Future<void> _loadLabels() async {
    final labels = await LabelService.loadLabels();
    setState(() {
      availableLabels = labels;
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
        title: Text('確認'),
        content: Text('このタスクを削除しますか？\n\n「${task.title}」'),
        actions: [
          TextButton(
            child: Text('キャンセル'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('削除'),
            onPressed: () {
              setState(() {
                if (columnName == '未対応') {
                  todoTasks.remove(task);
                } else if (columnName == '進行中') {
                  doingTasks.remove(task);
                } else if (columnName == '完了') {
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

  void _editTask(Task oldTask, String columnName) {
    showDialog(
      context: context,
      builder: (context) => EditTaskDialog(
        task: oldTask,
        onTaskUpdated: (newTask) {
          setState(() {
            List<Task> targetList;
            if (columnName == '未対応') {
              targetList = todoTasks;
            } else if (columnName == '進行中') {
              targetList = doingTasks;
            } else {
              targetList = doneTasks;
            }
            
            final index = targetList.indexOf(oldTask);
            if (index != -1) {
              targetList[index] = newTask;
              targetList.sort((a, b) => a.deadline.compareTo(b.deadline));
            }
            _saveTasks();
          });
        },
      ),
    );
  }

  List<Task> _filterTasks(List<Task> tasks) {
    if (selectedLabelId == null) {
      return tasks; // すべて表示
    }
    return tasks.where((task) => task.labelIds.contains(selectedLabelId)).toList();
  }

  Widget _buildTaskList(List<Task> tasks, String columnName) {
    final filteredTasks = _filterTasks(tasks);
    filteredTasks.sort((a, b) => a.deadline.compareTo(b.deadline));

    if (filteredTasks.isEmpty) {
      return Center(
        child: Text(
          'タスクがありません',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return TaskCard(
          task: task,
          currentColumn: columnName,
          onDelete: () {
            _showDeleteConfirmDialog(task, columnName);
          },
          onEdit: () {
            _editTask(task, columnName);
          },
          onMoveToTodo: columnName == '進行中'
              ? () {
                  setState(() {
                    doingTasks.remove(task);
                    todoTasks.add(task);
                    todoTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
                    _saveTasks();
                  });
                }
              : null,
          onMoveToDoing: (columnName == '未対応' || columnName == '完了')
              ? () {
                  setState(() {
                    if (columnName == '未対応') {
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
          onMoveToDone: columnName == '進行中'
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

  int _getFilteredTaskCount(List<Task> tasks) {
    return _filterTasks(tasks).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('タスク管理'),
        actions: [
          IconButton(
            icon: Icon(Icons.label),
            tooltip: 'ラベル管理',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LabelSettingsScreen()),
              );
              // ラベル管理画面から戻ってきたらラベルを再読み込み
              _loadLabels();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(96),
          child: Column(
            children: [
              // フィルタドロップダウン
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'フィルタ: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String?>(
                        value: selectedLabelId,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('すべて'),
                          ),
                          ...availableLabels.map((label) {
                            return DropdownMenuItem<String?>(
                              value: label.id,
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: label.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(label.name),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedLabelId = newValue;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // タブバー
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: '未対応 (${_getFilteredTaskCount(todoTasks)})'),
                  Tab(text: '進行中 (${_getFilteredTaskCount(doingTasks)})'),
                  Tab(text: '完了 (${_getFilteredTaskCount(doneTasks)})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(todoTasks, '未対応'),
          _buildTaskList(doingTasks, '進行中'),
          _buildTaskList(doneTasks, '完了'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _addTaskDialog,
      ),
    );
  }
}
