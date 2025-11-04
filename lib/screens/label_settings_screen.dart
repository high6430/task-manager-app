import 'package:flutter/material.dart';
import '../models/label.dart';
import '../services/label_service.dart';

class LabelSettingsScreen extends StatefulWidget {
  @override
  _LabelSettingsScreenState createState() => _LabelSettingsScreenState();
}

class _LabelSettingsScreenState extends State<LabelSettingsScreen> {
  List<Label> labels = [];

  @override
  void initState() {
    super.initState();
    _loadLabels();
  }

  Future<void> _loadLabels() async {
    final loadedLabels = await LabelService.loadLabels();
    setState(() {
      labels = loadedLabels;
    });
  }

  void _showAddLabelDialog() {
    final nameController = TextEditingController();
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("新しいラベルを追加"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: "ラベル名"),
                    ),
                    SizedBox(height: 16),
                    Text("色を選択:", style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Colors.red,
                        Colors.pink,
                        Colors.purple,
                        Colors.deepPurple,
                        Colors.indigo,
                        Colors.blue,
                        Colors.lightBlue,
                        Colors.cyan,
                        Colors.teal,
                        Colors.green,
                        Colors.lightGreen,
                        Colors.lime,
                        Colors.yellow,
                        Colors.amber,
                        Colors.orange,
                        Colors.deepOrange,
                        Colors.brown,
                        Colors.grey,
                        Colors.blueGrey,
                      ].map((color) {
                        return GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColor == color ? Colors.black : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      final newLabel = Label(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        color: selectedColor,
                      );
                      await LabelService.addLabel(newLabel);
                      _loadLabels();
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

  void _showDeleteConfirmDialog(Label label) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("確認"),
        content: Text("ラベル「${label.name}」を削除しますか？"),
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
            onPressed: () async {
              await LabelService.deleteLabel(label.id);
              _loadLabels();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ラベル管理"),
      ),
      body: labels.isEmpty
          ? Center(
              child: Text(
                "ラベルがありません",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: labels.length,
              itemBuilder: (context, index) {
                final label = labels[index];
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: label.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      label.name,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmDialog(label),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _showAddLabelDialog,
      ),
    );
  }
}