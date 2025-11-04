import 'package:flutter/material.dart';

class Label {
  final String id;
  final String name;
  final Color color;

  Label({
    required this.id,
    required this.name,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
    };
  }

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      id: json['id'],
      name: json['name'],
      color: Color(json['color']),
    );
  }

  // 文字色を自動計算（背景色に応じて白/黒）
  Color get textColor {
    final brightness = (color.red * 299 + color.green * 587 + color.blue * 114) / 1000;
    return brightness > 128 ? Colors.black : Colors.white;
  }
}