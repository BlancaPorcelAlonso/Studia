import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';
import '../widgets/task_form_modal.dart';

class MyWeekScreen extends StatefulWidget {
  const MyWeekScreen({super.key});

  @override
  State<MyWeekScreen> createState() => _MyWeekScreenState();
}

class _MyWeekScreenState extends State<MyWeekScreen> {
  DateTime _currentWeekStart = () {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  }();

  void _prevWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }

  void _currentWeek() {
    final now = DateTime.now();
    setState(() {
      _currentWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = AgendaRepository.instance;
    final isDesktop = MediaQuery.of(context).size.width >= 860;
    final days = List.generate(7, (i) => _currentWeekStart.add(Duration(days: i)));
    final endOfWeek = days.last;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final startFormatted = DateFormat('d MMM', 'es_ES').format(_currentWeekStart).toUpperCase();
        final endFormatted = DateFormat('d MMM yyyy', 'es_ES').format(endOfWeek).toUpperCase();

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
                  // Title + Week Range + Controls
                  Row(
                    children: [
                      const Text(
                        '🍂 Mi semana',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: CottagecoreColors.forest,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: CottagecoreColors.sage.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$startFormatted — $endFormatted',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: CottagecoreColors.forest,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: _prevWeek,
                      ),
                      OutlinedButton(
                        onPressed: _currentWeek,
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          side: const BorderSide(color: CottagecoreColors.sage),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Esta semana', style: TextStyle(color: CottagecoreColors.forest)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: _nextWeek,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Vista estilo diario semanal. Marca tus tareas completadas directamente aquí.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF7A6F62)),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: ListView.separated(
                      itemCount: 7,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final day = days[index];
                        final isToday = DateUtils.isSameDay(day, DateTime.now());
                        final dayName = DateFormat('EEEE', 'es_ES').format(day).toUpperCase();
                        final dateStr = DateFormat('d \'de\' MMMM', 'es_ES').format(day);

                        final dayTasks = repo.tasks.where((t) => DateUtils.isSameDay(t.dueDate, day)).toList();
                        final dayExams = repo.exams.where((e) => DateUtils.isSameDay(e.date, day)).toList();

                        // Subjects that might have class on this day name
                        final dayShort = DateFormat('E', 'es_ES').format(day).toLowerCase();
                        final scheduledClasses = repo.subjects.where((s) {
                          if (s.schedule == null) return false;
                          return s.schedule!.toLowerCase().contains(dayShort.substring(0, 3));
                        }).toList();

                        return Card(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: isToday
                                  ? CottagecoreColors.sage.withValues(alpha: 0.08)
                                  : null,
                              border: isToday
                                  ? Border.all(color: CottagecoreColors.sage, width: 1.5)
                                  : null,
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Day Header
                                Row(
                                  children: [
                                    Text(
                                      dayName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: isToday ? CottagecoreColors.forest : const Color(0xFF5A4D3F),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF8A7F73)),
                                    ),
                                    if (isToday) ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: CottagecoreColors.forest,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text('HOY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.add_rounded, size: 20),
                                      tooltip: 'Añadir tarea para este día',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => TaskFormModal.show(context, initialDueDate: day),
                                    ),
                                  ],
                                ),
                                const Divider(height: 14),

                                // Scheduled Classes
                                if (scheduledClasses.isNotEmpty) ...[
                                  ...scheduledClasses.map((s) => Padding(
                                        padding: const EdgeInsets.only(bottom: 6.0),
                                        child: Row(
                                          children: [
                                            Text(s.emoji, style: const TextStyle(fontSize: 14)),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${s.name} • ${s.schedule}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: s.color.withValues(alpha: 0.9),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                  const SizedBox(height: 4),
                                ],

                                // Exams
                                if (dayExams.isNotEmpty) ...[
                                  ...dayExams.map((e) => Padding(
                                        padding: const EdgeInsets.only(bottom: 6.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: CottagecoreColors.urgentRedBg,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Text('🔴 ', style: TextStyle(fontSize: 12)),
                                              Text(
                                                'Examen: ${e.name} (${e.time})',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: CottagecoreColors.urgentRed,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )),
                                ],

                                // Tasks with Interactive Checkboxes
                                if (dayTasks.isEmpty && dayExams.isEmpty && scheduledClasses.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4.0),
                                    child: Text(
                                      'Sin actividades planificadas para este día.',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  )
                                else
                                  ...dayTasks.map((t) {
                                    final sub = repo.getSubjectById(t.subjectId);
                                    final isDone = t.status == TaskStatus.completed;

                                    return InkWell(
                                      onTap: () => repo.toggleTaskCompletion(t.id),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isDone
                                                  ? Icons.check_box_rounded
                                                  : Icons.check_box_outline_blank_rounded,
                                              size: 20,
                                              color: isDone ? CottagecoreColors.calmGreen : const Color(0xFF8A7F73),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${t.title} • ${sub?.emoji ?? '📚'} ${sub?.name ?? ''}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                                  color: isDone ? const Color(0xFF9E958A) : CottagecoreColors.forest,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              t.dueInfo.text,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: t.dueInfo.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
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
