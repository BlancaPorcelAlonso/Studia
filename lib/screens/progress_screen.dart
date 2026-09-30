import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AgendaRepository.instance;
    final isDesktop = MediaQuery.of(context).size.width >= 860;
    final now = DateTime.now();

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final totalTasks = repo.tasks.length;
        final completedTasks = repo.tasks.where((t) => t.status == TaskStatus.completed).length;
        final pendingTasks = repo.tasks.where((t) => t.status != TaskStatus.completed).length;
        final lateTasks = repo.tasks.where((t) => t.isLate).length;
        final upcomingExams = repo.exams.where((e) => e.date.isAfter(now.subtract(const Duration(days: 1)))).length;

        // Completed this week
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final completedThisWeek = repo.tasks.where((t) {
          if (t.status != TaskStatus.completed) return false;
          final date = t.completedAt ?? t.dueDate;
          return date.isAfter(startOfWeek);
        }).length;

        final percentage = totalTasks == 0 ? 0 : ((completedTasks / totalTasks) * 100).round();

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 28 : 16,
                vertical: 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Progreso Académico',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: CottagecoreColors.forest,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Una mirada tranquila y motivadora a tu ritmo de estudio.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF7A6F62)),
                  ),
                  const SizedBox(height: 20),

                  // Overall Balance Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22.0),
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  value: totalTasks == 0 ? 0 : (completedTasks / totalTasks),
                                  strokeWidth: 10,
                                  backgroundColor: CottagecoreColors.creamDarker,
                                  valueColor: const AlwaysStoppedAnimation(CottagecoreColors.sage),
                                ),
                              ),
                              Text(
                                '$percentage%',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: CottagecoreColors.forest,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 22),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ritmo de estudio',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CottagecoreColors.forest),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$completedTasks de $totalTasks tareas completadas.',
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B6053)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '🌾 Has finalizado $completedThisWeek tarea(s) esta semana.',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CottagecoreColors.sage),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4 Compact metric boxes
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _metricBox('Completadas', '$completedTasks', CottagecoreColors.calmGreen, CottagecoreColors.calmGreenBg, Icons.check_circle_rounded),
                      _metricBox('Pendientes', '$pendingTasks', CottagecoreColors.warmBrown, CottagecoreColors.creamDarker, Icons.pending_actions_rounded),
                      _metricBox('Atrasadas', '$lateTasks', lateTasks > 0 ? CottagecoreColors.urgentRed : CottagecoreColors.sage, lateTasks > 0 ? CottagecoreColors.urgentRedBg : CottagecoreColors.calmGreenBg, Icons.warning_amber_rounded),
                      _metricBox('Exámenes', '$upcomingExams', CottagecoreColors.terracotta, CottagecoreColors.warningOrangeBg, Icons.school_rounded),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 🌱 JARDÍN DE PROGRESO BOTÁNICO
                  Row(
                    children: [
                      const Text(
                        '🌱 Mi Jardín Botánico',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: CottagecoreColors.forest,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: CottagecoreColors.calmGreenBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Crecimiento continuo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CottagecoreColors.calmGreen)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cada materia tiene su propia planta. Cada tarea completada alimenta su crecimiento con flores y nuevos brotes.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF7A6F62)),
                  ),
                  const SizedBox(height: 16),

                  // Garden grid of subjects
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: repo.subjects.map((sub) {
                      final subjectTasks = repo.tasks.where((t) => t.subjectId == sub.id).toList();
                      final completedSubTasks = subjectTasks.where((t) => t.status == TaskStatus.completed).length;

                      // Plant stage: 0=Semilla, 1=Brote, 2=Planta joven, 3+=Floración
                      final (plantEmoji, stageName, stageDesc) = switch (completedSubTasks) {
                        0 => ('🌰', 'Semilla en tierra', 'Comienza una tarea para germinar'),
                        1 => ('🌱', 'Brote tierno', '1 tarea completada con éxito'),
                        2 => ('🌿', 'Planta joven', '2 tareas completadas con constancia'),
                        _ => ('🌷', 'En plena floración', '¡$completedSubTasks tareas superadas!'),
                      };

                      return Container(
                        width: isDesktop ? 260 : double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: CottagecoreColors.creamCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: CottagecoreColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: sub.color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(plantEmoji, style: const TextStyle(fontSize: 34)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${sub.emoji} ${sub.name}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CottagecoreColors.forest),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stageName,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sub.color),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stageDesc,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF7A6F62)),
                            ),
                            const SizedBox(height: 10),
                            // Mini progress indicator
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: (completedSubTasks / (subjectTasks.isEmpty ? 1 : subjectTasks.length)).clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: CottagecoreColors.creamDarker,
                                valueColor: AlwaysStoppedAnimation(sub.color),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _metricBox(String label, String value, Color color, Color bg, IconData icon) {
    return Container(
      width: 165,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
