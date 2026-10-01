import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';
import '../widgets/subject_form_modal.dart';
import 'subject_detail_screen.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  void _showAddSubjectDialog(BuildContext context) =>
      SubjectFormModal.show(context);

  @override
  Widget build(BuildContext context) {
    final repo = AgendaRepository.instance;
    final isDesktop = MediaQuery.of(context).size.width >= 860;
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1100 ? 3 : (width >= 650 ? 2 : 1);

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final subjects = repo.subjects;
        final addSubjectButton = FilledButton.icon(
          onPressed: () => _showAddSubjectDialog(context),
          style: FilledButton.styleFrom(
            backgroundColor: CottagecoreColors.forest,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Nueva materia'),
        );

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
                  // Title + Add button
                  if (width < 650)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '📚 Asignaturas',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: CottagecoreColors.forest,
                            fontFamily: 'serif',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: addSubjectButton,
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        const Text(
                          '📚 Asignaturas',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: CottagecoreColors.forest,
                            fontFamily: 'serif',
                          ),
                        ),
                        const Spacer(),
                        addSubjectButton,
                      ],
                    ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tus cuadernos de estudio y apuntes académicos',
                    style: TextStyle(fontSize: 14, color: Color(0xFF7A6F62)),
                  ),
                  const SizedBox(height: 18),

                  Expanded(
                    child: GridView.builder(
                      itemCount: subjects.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: width >= 650 ? 1.7 : 2.1,
                      ),
                      itemBuilder: (context, index) {
                        final subject = subjects[index];
                        final subjectTasks = repo.tasks
                            .where((t) => t.subjectId == subject.id)
                            .toList();
                        final pendingTasks = subjectTasks
                            .where((t) => t.status != TaskStatus.completed)
                            .toList();
                        final nextTask = pendingTasks.isNotEmpty
                            ? (pendingTasks
                                  ..sort(
                                      (a, b) => a.dueDate.compareTo(b.dueDate)))
                                .first
                            : null;
                        final examCount = repo.exams
                            .where((e) => e.subjectId == subject.id)
                            .length;

                        return Card(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SubjectDetailScreen(subject: subject),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border(
                                  left: BorderSide(
                                      color: subject.color, width: 6),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: subject.color
                                              .withValues(alpha: 0.16),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Center(
                                          child: Text(subject.emoji,
                                              style: const TextStyle(
                                                  fontSize: 22)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              subject.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: CottagecoreColors.forest,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              subject.teacher ??
                                                  'Sin profesor asignado',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF7A6F62)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 12),
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                              Icons
                                                  .check_circle_outline_rounded,
                                              size: 14,
                                              color: CottagecoreColors.sage),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${pendingTasks.length} pendientes',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      if (examCount > 0)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.menu_book_rounded,
                                                size: 14,
                                                color: CottagecoreColors
                                                    .terracotta),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$examCount exam.',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: CottagecoreColors
                                                      .terracotta),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  Text(
                                    nextTask != null
                                        ? 'Próx. ${DateFormat('d MMM', 'es_ES').format(nextTask.dueDate)} (${nextTask.dueInfo.text})'
                                        : 'Todo entregado al día 🌱',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: nextTask != null
                                          ? nextTask.dueInfo.color
                                          : CottagecoreColors.calmGreen,
                                    ),
                                  ),
                                ],
                              ),
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
