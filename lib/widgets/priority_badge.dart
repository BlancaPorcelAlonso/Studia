import 'package:flutter/material.dart';
import '../models/task.dart';
import '../theme/cottagecore_theme.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({
    required this.priority,
    this.compact = false,
    super.key,
  });

  final TaskPriority priority;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color, bg) = switch (priority) {
      TaskPriority.low => (
          'Baja',
          '🌿',
          CottagecoreColors.calmGreen,
          CottagecoreColors.calmGreenBg
        ),
      TaskPriority.medium => (
          'Media',
          '🟡',
          const Color(0xFF9E7C1B),
          const Color(0xFFFDF8E2)
        ),
      TaskPriority.high => (
          'Alta',
          '🟠',
          CottagecoreColors.warningOrange,
          CottagecoreColors.warningOrangeBg
        ),
      TaskPriority.urgent => (
          'Urgente',
          '🔴',
          CottagecoreColors.urgentRed,
          CottagecoreColors.urgentRedBg
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: compact ? 10 : 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
