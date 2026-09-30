import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';
import 'date_badge.dart';
import 'priority_badge.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showDragHandle = false,
    super.key,
  });

  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final repo = AgendaRepository.instance;
    final subject = repo.getSubjectById(task.subjectId);
    final subjectColor = subject?.color ?? CottagecoreColors.sage;
    final isDone = task.status == TaskStatus.completed;

    return Card(
      child: InkWell(
        onTap: onTap ?? onEdit,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border(
              left: BorderSide(color: subjectColor, width: 6),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Subject Tag + Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: subjectColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(subject?.emoji ?? '📚', style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              subject?.name ?? 'General',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: subjectColor.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Editar tarea',
                      color: const Color(0xFF7A6F62),
                      onPressed: onEdit,
                    ),
                  ],
                  if (onDelete != null) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Eliminar tarea',
                      color: const Color(0xFFB8786F),
                      onPressed: onDelete,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                task.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDone ? const Color(0xFF8B948A) : CottagecoreColors.forest,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),

              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF776F64),
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Badges row: Priority + Type
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  PriorityBadge(priority: task.priority, compact: true),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: CottagecoreColors.creamDarker,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      task.typeLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CottagecoreColors.warmBrown,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              const Divider(height: 16, thickness: 0.7),

              // Bottom row: Due Date Info + Checkbox / Status Toggle
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 14,
                        color: subjectColor.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('d MMM', 'es_ES').format(task.dueDate),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B6053),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DateBadge(task: task, compact: true),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          repo.toggleTaskCompletion(task.id);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Icon(
                            isDone
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isDone
                                ? CottagecoreColors.calmGreen
                                : const Color(0xFFB5A99B),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
