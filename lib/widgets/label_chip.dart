import 'package:flutter/material.dart';
import '../models/label.dart';

class LabelChip extends StatelessWidget {
  final Label label;
  final bool small;

  const LabelChip({
    Key? key,
    required this.label,
    this.small = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: label.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.name,
        style: TextStyle(
          color: label.textColor,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
