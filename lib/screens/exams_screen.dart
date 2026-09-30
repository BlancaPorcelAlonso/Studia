import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';
import '../widgets/empty_botanical_state.dart';
import '../widgets/exam_form_modal.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AgendaRepository.instance;
    final isDesktop = MediaQuery.of(context).size.width >= 860;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final exams = repo.exams;

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
                        '📖 Exámenes & Evaluaciones',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: CottagecoreColors.forest,
                          fontFamily: 'serif',
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => ExamFormModal.show(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: CottagecoreColors.forest,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Nuevo examen'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Planifica el temario y mide tu porcentaje real de preparación',
                    style: TextStyle(fontSize: 14, color: Color(0xFF7A6F62)),
                  ),
                  const SizedBox(height: 18),

                  Expanded(
                    child: exams.isEmpty
                        ? const EmptyBotanicalState(
                            message: 'No tienes exámenes registrados',
                            subMessage: 'Registra un examen para dividir su temario en temas y controlar tu progreso.',
                            emoji: '📖',
                          )
                        : ListView.separated(
                            itemCount: exams.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final exam = exams[index];
                              final sub = repo.getSubjectById(exam.subjectId);
                              final progress = exam.progressPercent;

                              return Card(
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border(
                                      left: BorderSide(
                                        color: sub?.color ?? CottagecoreColors.terracotta,
                                        width: 6,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header: Exam Name + Subject + State Badge + Actions
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  exam.name,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    color: CottagecoreColors.forest,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Text(sub?.emoji ?? '📚', style: const TextStyle(fontSize: 14)),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      sub?.name ?? 'General',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: sub?.color ?? CottagecoreColors.forest,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: exam.stateColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              exam.stateLabel,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: exam.stateColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18),
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => ExamFormModal.show(context, initialExam: exam),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => repo.deleteExam(exam.id),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Date, Time & Classroom
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, size: 15, color: CottagecoreColors.sage),
                                          const SizedBox(width: 6),
                                          Text(
                                            DateFormat('d \'de\' MMMM yyyy', 'es_ES').format(exam.date),
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(width: 14),
                                          const Icon(Icons.access_time_rounded, size: 15, color: CottagecoreColors.sage),
                                          const SizedBox(width: 6),
                                          Text(exam.time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                          const SizedBox(width: 14),
                                          const Icon(Icons.room_outlined, size: 15, color: CottagecoreColors.sage),
                                          const SizedBox(width: 6),
                                          Text(exam.classroom, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      const SizedBox(height: 14),

                                      // Preparation Progress
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Preparación: ${exam.completedTopicsCount} de ${exam.topics.length} temas',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B6053)),
                                          ),
                                          Text(
                                            '$progress%',
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CottagecoreColors.forest),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: progress / 100,
                                        minHeight: 10,
                                        borderRadius: BorderRadius.circular(20),
                                        backgroundColor: CottagecoreColors.creamDarker,
                                        valueColor: const AlwaysStoppedAnimation(CottagecoreColors.sage),
                                      ),
                                      const SizedBox(height: 14),

                                      // Temario Checkable List
                                      const Text(
                                        'Temario (Marca los temas según los vayas estudiando):',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CottagecoreColors.forest),
                                      ),
                                      const SizedBox(height: 8),
                                      if (exam.topics.isEmpty)
                                        const Text('No se ha desglosado el temario todavía.', style: TextStyle(fontSize: 12, color: Colors.grey))
                                      else
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: List.generate(exam.topics.length, (tIdx) {
                                            final topic = exam.topics[tIdx];
                                            return InkWell(
                                              onTap: () => repo.toggleExamTopic(exam.id, tIdx),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: topic.isCompleted
                                                      ? CottagecoreColors.calmGreenBg
                                                      : CottagecoreColors.creamDarker,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: topic.isCompleted
                                                        ? CottagecoreColors.calmGreen.withValues(alpha: 0.5)
                                                        : CottagecoreColors.border,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      topic.isCompleted
                                                          ? Icons.check_circle_rounded
                                                          : Icons.radio_button_unchecked_rounded,
                                                      size: 16,
                                                      color: topic.isCompleted
                                                          ? CottagecoreColors.calmGreen
                                                          : const Color(0xFF8A7E72),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      topic.title,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: topic.isCompleted
                                                            ? CottagecoreColors.forest
                                                            : const Color(0xFF4C4237),
                                                        decoration: topic.isCompleted ? TextDecoration.lineThrough : null,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                        ),

                                      if (exam.notes != null && exam.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: CottagecoreColors.creamDarker,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '💡 ${exam.notes}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B6053)),
                                          ),
                                        ),
                                      ],
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
