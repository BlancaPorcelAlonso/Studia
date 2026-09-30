import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';
import '../widgets/empty_botanical_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AgendaRepository.instance;
    final isDesktop = MediaQuery.of(context).size.width >= 860;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final completed = repo.tasks
            .where((t) => t.status == TaskStatus.completed)
            .toList()
          ..sort((a, b) {
            final dateA = a.completedAt ?? a.dueDate;
            final dateB = b.completedAt ?? b.dueDate;
            return dateB.compareTo(dateA); // Most recent first
          });

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 28 : 16,
                vertical: 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '✓ Historial de Logros',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: CottagecoreColors.forest,
                          fontFamily: 'serif',
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: CottagecoreColors.calmGreenBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${completed.length} completadas',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: CottagecoreColors.calmGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Registro de tus tareas terminadas y trabajos académicos entregados con éxito.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF7A6F62)),
                  ),
                  const SizedBox(height: 18),

                  Expanded(
                    child: completed.isEmpty
                        ? const EmptyBotanicalState(
                            message: 'Aún no hay tareas en el historial',
                            subMessage: 'A medida que completes tareas en el tablero, aparecerán aquí registradas con su fecha de finalización.',
                            emoji: '🌱',
                          )
                        : ListView.separated(
                            itemCount: completed.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final task = completed[index];
                              final sub = repo.getSubjectById(task.subjectId);
                              final finishedDate = task.completedAt ?? task.dueDate;

                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: CottagecoreColors.calmGreenBg,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.check_circle_rounded,
                                          color: CottagecoreColors.calmGreen,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task.title,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: CottagecoreColors.forest,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${sub?.emoji ?? '📚'} ${sub?.name ?? 'Materia'} • ${task.typeLabel} • Entregada el ${DateFormat('d MMMM yyyy', 'es_ES').format(finishedDate)}',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF7A6F62)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.undo_rounded, size: 20),
                                        tooltip: 'Mover de vuelta a pendientes',
                                        onPressed: () {
                                          repo.moveTaskStatus(task.id, TaskStatus.todo);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                        tooltip: 'Eliminar definitivamente',
                                        onPressed: () {
                                          repo.deleteTask(task.id);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
