import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/label.dart';
import '../services/task_service.dart';
import '../services/label_service.dart';
import '../services/notification_service.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/edit_task_dialog.dart';
import 'label_settings_screen.dart';
import 'notification_set_settings_screen.dart';
import 'settings_screen.dart';
import 'dart:io';
import 'dart:async';
import 'task_detail_screen.dart';
import 'package:pikado/utils/logger.dart';

class TaskBoardScreen extends StatefulWidget {
  @override
  _TaskBoardScreenState createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen>
    with SingleTickerProviderStateMixin {
  List<Task> todoTasks = [];
  List<Task> doingTasks = [];
  List<Task> doneTasks = [];
  List<Label> availableLabels = [];
  String? selectedLabelId;

  late TabController _tabController;

  // 通知イベント購読用
  StreamSubscription<String>? _taskCompleteSubscription;
  StreamSubscription<String>? _taskDetailsSubscription;

  // フィルタリング済みタスクをキャッシュ
  List<Task> _filteredTodoTasks = [];
  List<Task> _filteredDoingTasks = [];
  List<Task> _filteredDoneTasks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 通知イベントの購読を最初に設定
    Logger.section(' Stream購読開始 ');

    // 通知からのタスク完了イベントを購読
    _taskCompleteSubscription = NotificationService.taskCompleteStream.listen(
      (taskId) {
        Logger.log('📬 タスク完了イベント受信: $taskId');
        _completeTaskFromNotification(taskId);
      },
      onError: (error) {
        Logger.error(' タスク完了イベントエラー: $error');
      },
    );

    // 通知からのタスク詳細表示イベントを購読
    _taskDetailsSubscription = NotificationService.taskDetailsStream.listen(
      (taskId) {
        Logger.log('📬 タスク詳細表示イベント受信: $taskId');
        _showTaskDetailsFromNotification(taskId);
      },
      onError: (error) {
        Logger.error(' タスク詳細表示イベントエラー: $error');
      },
    );

    Logger.success(' Stream購読完了');
    Logger.sectionEnd(' Stream購読');

    // データ読み込み
    _loadData();

    // 権限チェック（少し遅延させて表示）
    Future.delayed(Duration(milliseconds: 800), () {
      _checkPermissions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskCompleteSubscription?.cancel();
    _taskDetailsSubscription?.cancel();
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
      _updateFilteredTasks();
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

  // フィルタリング済みタスクを更新（キャッシュ）
  void _updateFilteredTasks() {
    _filteredTodoTasks = _filterAndSortTasks(todoTasks);
    _filteredDoingTasks = _filterAndSortTasks(doingTasks);
    _filteredDoneTasks = _filterAndSortTasks(doneTasks);
  }

  // タスクをフィルタリング＆ソート
  List<Task> _filterAndSortTasks(List<Task> tasks) {
    List<Task> filtered;
    if (selectedLabelId == null) {
      filtered = List.from(tasks);
    } else {
      filtered = tasks
          .where((task) => task.labelIds.contains(selectedLabelId))
          .toList();
    }
    filtered.sort((a, b) => a.deadline.compareTo(b.deadline));
    return filtered;
  }

  void _addTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        availableLabels: availableLabels,
        onTaskAdded: (task) async {
          setState(() {
            todoTasks.add(task);
            _updateFilteredTasks();
          });
          await _saveTasks();

          // 通知をスケジュール
          final taskId = task.id;
          await NotificationService.scheduleTaskNotifications(
            task,
            taskId,
            '未対応',
          );
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
            onPressed: () async {
              setState(() {
                if (columnName == '未対応') {
                  todoTasks.remove(task);
                } else if (columnName == '進行中') {
                  doingTasks.remove(task);
                } else if (columnName == '完了') {
                  doneTasks.remove(task);
                }
                _updateFilteredTasks();
              });
              await _saveTasks();

              // 通知をキャンセル
              final taskId = task.id;
              await NotificationService.cancelTaskNotifications(taskId);

              if (mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

void _editTask(Task oldTask, String columnName) {
  showDialog(
    context: context,
    builder: (dialogContext) => EditTaskDialog(  // ★ 修正: context → dialogContext
      task: oldTask,
      availableLabels: availableLabels,
      onTaskUpdated: (newTask) async {
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
          }
          _updateFilteredTasks();
        });
        await _saveTasks();

        final taskId = newTask.id;
        await NotificationService.scheduleTaskNotifications(
          newTask,
          taskId,
          columnName,
        );
        
        // ★ 追加: ダイアログを閉じる
        Navigator.of(dialogContext).pop(true);
        Logger.success(' 編集ダイアログを閉じました');
      },
    ),
  );
}

  Widget _buildTaskList(List<Task> filteredTasks, String columnName) {
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
          key: ValueKey(task.id),
          task: task,
          currentColumn: columnName,
          availableLabels: availableLabels,
          onDelete: () {
            _showDeleteConfirmDialog(task, columnName);
          },
          onEdit: () {
            _editTask(task, columnName);
          },
          onTaskUpdated: (updatedTask) async {
            Logger.log('🔄 TaskBoardScreen: onTaskUpdated が呼ばれました');
            Logger.log('更新タスクID: ${updatedTask.id}');
            Logger.log('カラム: $columnName');

            setState(() {
              List<Task> targetList;
              if (columnName == '未対応') {
                targetList = todoTasks;
              } else if (columnName == '進行中') {
                targetList = doingTasks;
              } else {
                targetList = doneTasks;
              }

              final index = targetList.indexWhere(
                (t) => t.id == updatedTask.id,
              );
              if (index != -1) {
                targetList[index] = updatedTask;
                Logger.success(' タスクを更新しました');
              } else {
                Logger.error(' エラー: タスクが見つかりませんでした（index: $index）');
              }
              _updateFilteredTasks();
            });

            Logger.log('タスクを保存します');
            await _saveTasks();
            Logger.success(' タスク保存完了');

            // 通知を再スケジュール
            Logger.log('通知を再スケジュールします');
            await NotificationService.scheduleTaskNotifications(
              updatedTask,
              updatedTask.id,
              columnName,
            );
            Logger.success(' 通知再スケジュール完了');

            Logger.success(' TaskBoardScreen: onTaskUpdated 完了\n');
          },
          onMoveToTodo: columnName == '進行中'
              ? () async {
                  setState(() {
                    doingTasks.remove(task);
                    todoTasks.add(task);
                    _updateFilteredTasks();
                  });
                  await _saveTasks();

                  // 通知を再スケジュール
                  final taskId = task.id;
                  await NotificationService.scheduleTaskNotifications(
                    task,
                    taskId,
                    '未対応',
                  );
                }
              : null,
          onMoveToDoing: (columnName == '未対応' || columnName == '完了')
              ? () async {
                  setState(() {
                    if (columnName == '未対応') {
                      todoTasks.remove(task);
                    } else {
                      doneTasks.remove(task);
                    }
                    doingTasks.add(task);
                    _updateFilteredTasks();
                  });
                  await _saveTasks();

                  // 通知を再スケジュール
                  final taskId = task.id;
                  await NotificationService.scheduleTaskNotifications(
                    task,
                    taskId,
                    '進行中',
                  );
                }
              : null,
          onMoveToDone: (columnName == '進行中' || columnName == '未対応')
              ? () async {
                  Logger.log('🟢 onMoveToDone が呼ばれました');
                  Logger.log('カラム: $columnName');
                  Logger.log('タスクID: ${task.id}');

                  setState(() {
                    if (columnName == '未対応') {
                      todoTasks.remove(task);
                      Logger.log('未対応リストから削除');
                    } else if (columnName == '進行中') {
                      doingTasks.remove(task);
                      Logger.log('進行中リストから削除');
                    }
                    doneTasks.add(task);
                    _updateFilteredTasks();
                    Logger.log('完了リストに追加');
                  });

                  await _saveTasks();
                  Logger.success(' タスク保存完了');

                  // 完了時は通知をキャンセル
                  final taskId = task.id;
                  await NotificationService.cancelTaskNotifications(taskId);
                  Logger.success(' 通知キャンセル完了');

                  // 完了タブに切り替え
                  _tabController.animateTo(2);
                  Logger.log('完了タブに切り替え');

                  Logger.log('🟢 onMoveToDone 完了\n');
                }
              : null,
        );
      },
    );
  }

  int _getFilteredTaskCount(List<Task> filteredTasks) {
    return filteredTasks.length;
  }

  // 権限チェック
  Future<void> _checkPermissions() async {
    if (!Platform.isAndroid) return;

    final permissions = await NotificationService.checkAllPermissions();

    final notificationGranted = permissions['notification'] ?? false;
    final alarmGranted = permissions['exactAlarm'] ?? false;

    Logger.log('通知権限: $notificationGranted');
    Logger.log('アラーム権限: $alarmGranted');

    // どちらかが許可されていない場合、ダイアログ表示
    if (!notificationGranted || !alarmGranted) {
      _showPermissionDialog(notificationGranted, alarmGranted);
    }
  }

  // 権限ダイアログを表示
  void _showPermissionDialog(bool notificationGranted, bool alarmGranted) {
    String message = '';

    if (!notificationGranted && !alarmGranted) {
      message =
          '通知を受け取るには、以下の2つの権限が必要です：\n\n'
          '1. 通知の許可\n'
          '2. アラームとリマインダーの許可\n\n'
          '設定画面で両方をONにしてください。';
    } else if (!notificationGranted) {
      message =
          '通知を受け取るには「通知の許可」が必要です。\n\n'
          '設定画面でONにしてください。';
    } else if (!alarmGranted) {
      message =
          '通知を正確な時刻に届けるには\n'
          '「アラームとリマインダー」の権限が必要です。\n\n'
          '設定画面でONにしてください。';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('重要な設定'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('後で'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await NotificationService.requestExactAlarmPermission();

              // 再チェック（設定画面から戻ってきた後）
              Future.delayed(Duration(seconds: 1), () {
                _checkPermissions();
              });
            },
            child: Text('設定画面を開く'),
          ),
        ],
      ),
    );
  }

  // 通知からタスクを完了にする
  Future<void> _completeTaskFromNotification(String taskId) async {
    Logger.log('--- 通知からタスク完了処理開始 ---');
    Logger.log('タスクID: $taskId');

    Task? targetTask;
    String? columnName;

    // 全てのリストからタスクを検索
    for (var task in todoTasks) {
      if (task.id == taskId) {
        targetTask = task;
        columnName = '未対応';
        break;
      }
    }

    if (targetTask == null) {
      for (var task in doingTasks) {
        if (task.id == taskId) {
          targetTask = task;
          columnName = '進行中';
          break;
        }
      }
    }

    if (targetTask == null) {
      for (var task in doneTasks) {
        if (task.id == taskId) {
          Logger.warning(' タスクは既に完了済みです');
          Logger.log('--- 通知からタスク完了処理終了 ---\n');
          return;
        }
      }
    }

    if (targetTask == null) {
      Logger.error(' タスクが見つかりませんでした');
      Logger.log('--- 通知からタスク完了処理終了 ---\n');
      return;
    }

    Logger.success(' タスクを発見: ${targetTask.title}');
    Logger.log('現在のカラム: $columnName');
    
    // 確認ダイアログを表示
    if (mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('タスク完了確認'),
          content: Text('「${targetTask!.title}」\n\nこのタスクを完了にしますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('キャンセル'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text('完了にする'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        Logger.warning(' ユーザーがキャンセルしました');
        Logger.log('--- 通知からタスク完了処理終了 ---\n');
        return;
      }
    }

    // タスクを完了リストに移動
    setState(() {
      if (columnName == '未対応') {
        todoTasks.remove(targetTask);
      } else if (columnName == '進行中') {
        doingTasks.remove(targetTask);
      }
      doneTasks.add(targetTask!);
      _updateFilteredTasks();
    });

    await _saveTasks();

    // 通知をキャンセル
    await NotificationService.cancelTaskNotifications(taskId);
    
    // 完了タブに切り替え
    _tabController.animateTo(2);

    Logger.success(' タスクを完了にしました');
    Logger.log('--- 通知からタスク完了処理終了 ---\n');

    // スナックバーで通知
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('「${targetTask.title}」を完了にしました'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // 通知からタスク詳細を表示
  Future<void> _showTaskDetailsFromNotification(String taskId) async {
    Logger.log('--- 通知からタスク詳細表示処理開始 ---');
    Logger.log('タスクID: $taskId');

    Task? targetTask;
    String? columnName;

    // 全てのリストからタスクを検索
    for (var task in todoTasks) {
      if (task.id == taskId) {
        targetTask = task;
        columnName = '未対応';
        break;
      }
    }

    if (targetTask == null) {
      for (var task in doingTasks) {
        if (task.id == taskId) {
          targetTask = task;
          columnName = '進行中';
          break;
        }
      }
    }

    if (targetTask == null) {
      for (var task in doneTasks) {
        if (task.id == taskId) {
          targetTask = task;
          columnName = '完了';
          break;
        }
      }
    }

    if (targetTask == null) {
      Logger.error(' タスクが見つかりませんでした');
      Logger.log('--- 通知からタスク詳細表示処理終了 ---\n');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('タスクが見つかりませんでした')),
        );
      }
      return;
    }

    Logger.success(' タスクを発見: ${targetTask.title}');
    Logger.log('現在のカラム: $columnName');

    // 適切なタブに切り替え
    if (columnName == '未対応') {
      _tabController.animateTo(0);
    } else if (columnName == '進行中') {
      _tabController.animateTo(1);
    } else if (columnName == '完了') {
      _tabController.animateTo(2);
    }

    Logger.log('--- 通知からタスク詳細表示処理終了 ---\n');

    // タスク詳細画面に遷移
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskDetailScreen(
            task: targetTask!,
            currentColumn: columnName!,
            availableLabels: availableLabels,
            onTaskUpdated: (updatedTask) async {
              Logger.log('🔄🔄🔄 タスク更新処理開始（通知から） 🔄🔄🔄');
              Logger.log('更新タスクID: ${updatedTask.id}');
              Logger.log('更新タスク名: ${updatedTask.title}');
              Logger.log('現在のカラム: $columnName');

              // タスク更新処理
              setState(() {
                List<Task> targetList;
                if (columnName == '未対応') {
                  targetList = todoTasks;
                } else if (columnName == '進行中') {
                  targetList = doingTasks;
                } else {
                  targetList = doneTasks;
                }

                Logger.log('対象リストのタスク数: ${targetList.length}');

                final index = targetList.indexWhere(
                  (t) => t.id == updatedTask.id,
                );
                Logger.log('タスクのインデックス: $index');

                if (index != -1) {
                  Logger.log('タスクを更新します');
                  targetList[index] = updatedTask;
                  Logger.success(' タスクを更新しました: ${updatedTask.title}');
                } else {
                  Logger.error(' エラー: タスクが見つかりませんでした');
                  Logger.log('検索対象リスト:');
                  for (var t in targetList) {
                    Logger.log('  - ID: ${t.id}, タイトル: ${t.title}');
                  }
                }
                _updateFilteredTasks();
              });

              Logger.log('タスクを保存します');
              await _saveTasks();
              Logger.success(' タスク保存完了');

              // 通知を再スケジュール
              Logger.log('通知を再スケジュールします');
              await NotificationService.scheduleTaskNotifications(
                updatedTask,
                updatedTask.id,
                columnName!,
              );
              Logger.success(' 通知再スケジュール完了');
              Logger.log('🔄🔄🔄 タスク更新処理完了（通知から） 🔄🔄🔄\n');
            },
            onComplete: columnName != '完了'
                ? () async {
                    Logger.log('--- 完了処理開始（詳細画面から・通知経由） ---');
                    Logger.log('タスクID: $taskId');

                    // タスクを完了にする処理
                    setState(() {
                      if (columnName == '未対応') {
                        todoTasks.remove(targetTask);
                        Logger.log('未対応リストから削除');
                      } else if (columnName == '進行中') {
                        doingTasks.remove(targetTask);
                        Logger.log('進行中リストから削除');
                      }
                      doneTasks.add(targetTask!);
                      _updateFilteredTasks();
                      Logger.log('完了リストに追加');
                    });

                    await _saveTasks();
                    Logger.success(' タスク保存完了');

                    // 通知をキャンセル
                    await NotificationService.cancelTaskNotifications(taskId);
                    Logger.success(' 通知キャンセル完了');

                    // 完了タブに切り替え
                    _tabController.animateTo(2);
                    Logger.log('完了タブに切り替え');

                    Logger.success(' タスクを完了にしました');
                    Logger.log('--- 完了処理終了（詳細画面から・通知経由） ---\n');

                    // スナックバーで通知
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('「${targetTask!.title}」を完了にしました'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                : null,
          ),
        ),
      );
    }
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
              _loadLabels();
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications),
            tooltip: '通知セット管理',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationSetSettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            tooltip: '設定',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(96),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'フィルタ: ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                          }),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedLabelId = newValue;
                            _updateFilteredTasks();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: '未対応 (${_getFilteredTaskCount(_filteredTodoTasks)})'),
                  Tab(text: '進行中 (${_getFilteredTaskCount(_filteredDoingTasks)})'),
                  Tab(text: '完了 (${_getFilteredTaskCount(_filteredDoneTasks)})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(_filteredTodoTasks, '未対応'),
          _buildTaskList(_filteredDoingTasks, '進行中'),
          _buildTaskList(_filteredDoneTasks, '完了'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _addTaskDialog,
      ),
    );
  }
}
