import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';
import 'task_card.dart';

class KanbanColumn extends StatelessWidget {
  const KanbanColumn({
    required this.status,
    required this.title,
    required this.emoji,
    required this.accentColor,
    required this.tasks,
    required this.onEditTask,
    required this.onAddTask,
    super.key,
  });

  final TaskStatus status;
  final String title;
  final String emoji;
  final Color accentColor;
  final List<Task> tasks;
  final ValueChanged<Task> onEditTask;
  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    final repo = AgendaRepository.instance;

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) {
        repo.moveTaskStatus(details.data.id, status);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: isHovered
                ? accentColor.withValues(alpha: 0.12)
                : CottagecoreColors.creamDarker.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isHovered ? accentColor : CottagecoreColors.border,
              width: isHovered ? 2.0 : 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Column Header
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CottagecoreColors.forest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.add_rounded, size: 20),
                    tooltip: 'Añadir a esta columna',
                    visualDensity: VisualDensity.compact,
                    onPressed: onAddTask,
                    color: CottagecoreColors.forest,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tasks List or Empty Placeholder
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                emoji,
                                style: TextStyle(
                                  fontSize: 26,
                                  color: Colors.grey.withValues(alpha: 0.4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Arrastra una tarea aquí',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF918576),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final task = tasks[index];

                          return LongPressDraggable<Task>(
                            data: task,
                            delay: const Duration(milliseconds: 150),
                            feedback: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(18),
                              child: SizedBox(
                                width: 280,
                                child: TaskCard(task: task),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.35,
                              child: TaskCard(task: task),
                            ),
                            child: TaskCard(
                              task: task,
                              onEdit: () => onEditTask(task),
                              onDelete: () => repo.deleteTask(task.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
