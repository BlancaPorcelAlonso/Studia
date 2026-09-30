import 'package:flutter/material.dart';
import '../models/task.dart';

class DateBadge extends StatelessWidget {
  const DateBadge({
    required this.task,
    this.compact = false,
    super.key,
  });

  final Task task;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final info = task.dueInfo;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: info.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: info.color.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Text(
        info.text,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: info.color,
        ),
      ),
    );
  }
}
