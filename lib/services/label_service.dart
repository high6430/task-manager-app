import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/label.dart';

class LabelService {
  static const String _labelsKey = 'labels';

  // 初期ラベル
  static List<Label> getDefaultLabels() {
    return [
      Label(id: 'work', name: '仕事', color: Colors.blue),
      Label(id: 'personal', name: '私生活', color: Colors.green),
      Label(id: 'urgent', name: '緊急', color: Colors.red),
    ];
  }

  // ラベルを読み込む
  static Future<List<Label>> loadLabels() async {
    final prefs = await SharedPreferences.getInstance();
    final labelsString = prefs.getString(_labelsKey);

    if (labelsString == null) {
      // 初回起動時はデフォルトラベルを保存して返す
      final defaultLabels = getDefaultLabels();
      await saveLabels(defaultLabels);
      return defaultLabels;
    }

    try {
      final List<dynamic> jsonList = json.decode(labelsString);
      return jsonList.map((json) => Label.fromJson(json)).toList();
    } catch (e) {
      // エラー時はデフォルトラベルを返す
      return getDefaultLabels();
    }
  }

  // ラベルを保存する
  static Future<void> saveLabels(List<Label> labels) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(labels.map((l) => l.toJson()).toList());
    await prefs.setString(_labelsKey, jsonString);
  }

  // ラベルを追加
  static Future<void> addLabel(Label label) async {
    final labels = await loadLabels();
    labels.add(label);
    await saveLabels(labels);
  }

  // ラベルを削除
  static Future<void> deleteLabel(String labelId) async {
    final labels = await loadLabels();
    labels.removeWhere((l) => l.id == labelId);
    await saveLabels(labels);
  }

  // ラベルを更新
  static Future<void> updateLabel(Label updatedLabel) async {
    final labels = await loadLabels();
    final index = labels.indexWhere((l) => l.id == updatedLabel.id);
    if (index != -1) {
      labels[index] = updatedLabel;
      await saveLabels(labels);
    }
  }

  // IDからラベルを取得
  static Label? getLabelById(List<Label> labels, String id) {
    try {
      return labels.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }
}