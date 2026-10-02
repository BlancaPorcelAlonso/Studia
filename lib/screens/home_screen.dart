import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';
import '../widgets/empty_botanical_state.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({this.onNavigateTab, super.key});

  final ValueChanged<int>? onNavigateTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final repo = AgendaRepository.instance;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final now = DateTime.now();
        final tasks = repo.tasks;
        final subjects = repo.subjects;
        final exams = repo.exams;
        final deliverables = repo.deliverables;

        // Calculations for sections
        final todayTasks =
            tasks.where((t) => DateUtils.isSameDay(t.dueDate, now)).toList();
        final selectedDayTasks = tasks
            .where((t) => DateUtils.isSameDay(t.dueDate, _selectedDate))
            .toList();
        final todayDate = DateUtils.dateOnly(now);

        final upcomingTasks = tasks
            .where((t) =>
                t.status != TaskStatus.completed &&
                t.dueDate.isAfter(now) &&
                t.dueDate.difference(now).inDays <= 7)
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

        final upcomingExams = exams
            .where((exam) => !DateUtils.dateOnly(exam.date).isBefore(todayDate))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        final upcomingDeliverables = deliverables
            .where((item) =>
                !item.isSubmitted &&
                !DateUtils.dateOnly(item.date).isBefore(todayDate))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        final urgentOrLate = tasks.where((t) {
          if (t.status == TaskStatus.completed) return false;
          return t.isLate ||
              t.priority == TaskPriority.urgent ||
              (t.dueDate.difference(now).inDays <= 1 && t.dueDate.isAfter(now));
        }).toList();

        final pendingCount =
            tasks.where((t) => t.status != TaskStatus.completed).length;
        final inProgressCount =
            tasks.where((t) => t.status == TaskStatus.inProgress).length;
        final upcomingExamsCount = exams
            .where((e) => e.date.isAfter(now.subtract(const Duration(days: 1))))
            .length;
        final thisWeekCount = tasks.where((t) {
          final diff = t.dueDate.difference(now).inDays;
          return diff >= 0 && diff <= 7 && t.status != TaskStatus.completed;
        }).length;

        // Schedule of today from subjects
        final currentWeekdayName =
            DateFormat('EEEE', 'es_ES').format(now).toLowerCase();
        final todaySubjects = subjects.where((s) {
          if (s.schedule == null) return false;
          final sched = s.schedule!.toLowerCase();
          return sched.contains(currentWeekdayName.substring(0, 3));
        }).toList();

        final isWide = MediaQuery.of(context).size.width >= 900;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 32 : 18,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & Date Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Buenos días 🌿',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: CottagecoreColors.forest,
                                fontFamily: 'serif',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, d \'de\' MMMM', 'es_ES')
                                  .format(now),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7A6F62),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: CottagecoreColors.forest,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add_rounded),
                        tooltip: 'Crear nueva tarea',
                        onPressed: () => TaskFormModal.show(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Compact Summary Cards
                  _buildCompactSummary(
                    pendingCount: pendingCount,
                    inProgressCount: inProgressCount,
                    upcomingExamsCount: upcomingExamsCount,
                    thisWeekCount: thisWeekCount,
                  ),
                  const SizedBox(height: 24),

                  // Needs Attention Alert (Only if active items)
                  if (urgentOrLate.isNotEmpty) ...[
                    _buildNeedsAttentionBanner(urgentOrLate),
                    const SizedBox(height: 24),
                  ],

                  // Desktop 2-column or Mobile stacked
                  if (isWide)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              key: const ValueKey('home-left-column'),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _dashboardSection(
                                    _buildTodaySection(
                                      todayTasks.take(3).toList(),
                                      todaySubjects,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  KeyedSubtree(
                                    key: const ValueKey(
                                        'home-left-bottom-section'),
                                    child: _dashboardSection(
                                      _buildUpcomingSection(
                                        upcomingTasks.take(2).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              key: const ValueKey('home-right-column'),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildWeekStripSection(
                                      tasks, exams, deliverables),
                                    const SizedBox(height: 5),
                                  _dashboardSection(
                                    _buildUpcomingAssessments(
                                      upcomingExams.take(3).toList(),
                                      upcomingDeliverables.take(3).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  KeyedSubtree(
                                    key: const ValueKey(
                                        'home-right-bottom-section'),
                                    child: _buildSelectedDayActivities(
                                        selectedDayTasks.take(3).toList()),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _dashboardSection(
                      _buildTodaySection(todayTasks, todaySubjects),
                    ),
                    const SizedBox(height: 24),
                    _dashboardSection(
                      _buildUpcomingSection(upcomingTasks.take(2).toList()),
                    ),
                    const SizedBox(height: 24),
                    _buildWeekStripSection(tasks, exams, deliverables),
                    const SizedBox(height: 20),
                    _dashboardSection(
                      _buildUpcomingAssessments(
                          upcomingExams, upcomingDeliverables),
                    ),
                    const SizedBox(height: 20),
                    _buildSelectedDayActivities(selectedDayTasks),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactSummary({
    required int pendingCount,
    required int inProgressCount,
    required int upcomingExamsCount,
    required int thisWeekCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CottagecoreColors.creamCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CottagecoreColors.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceAround,
        children: [
          _summaryPill('3 tareas pendientes', '$pendingCount pendientes',
              const Color(0xFF7EA98B), Icons.checklist_rounded),
          _summaryPill('2 en proceso', '$inProgressCount en proceso',
              const Color(0xFFCE9657), Icons.timelapse_rounded),
          _summaryPill('1 examen próximo', '$upcomingExamsCount examen(es)',
              const Color(0xFFC77A5C), Icons.menu_book_rounded),
          _summaryPill('1 entrega semana', '$thisWeekCount esta semana',
              const Color(0xFF88A38F), Icons.calendar_today_rounded),
        ],
      ),
    );
  }

  Widget _summaryPill(String tooltip, String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardSection(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CottagecoreColors.creamCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CottagecoreColors.border),
        ),
        child: child,
      );

  Widget _buildNeedsAttentionBanner(List<Task> urgentOrLate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CottagecoreColors.urgentRedBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: CottagecoreColors.urgentRed.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Necesita atención',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CottagecoreColors.urgentRed,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: CottagecoreColors.urgentRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${urgentOrLate.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tienes ${urgentOrLate.length} asunto(s) prioritario(s) o con fecha próxima:',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B3A35)),
          ),
          const SizedBox(height: 8),
          ...urgentOrLate.take(3).map((task) {
            final repo = AgendaRepository.instance;
            final sub = repo.getSubjectById(task.subjectId);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.arrow_right_rounded,
                      size: 18, color: CottagecoreColors.urgentRed),
                  Expanded(
                    child: Text(
                      '${task.title} (${sub?.emoji ?? '📚'} ${sub?.name ?? ''}) - ${task.dueInfo.text}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTodaySection(
      List<Task> todayTasks, List<Subject> todaySubjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '🌿 Hoy',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: CottagecoreColors.forest,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () =>
                  TaskFormModal.show(context, initialDueDate: DateTime.now()),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Para hoy'),
              style: TextButton.styleFrom(
                  foregroundColor: CottagecoreColors.forest),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Classes scheduled for today
        if (todaySubjects.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CottagecoreColors.sage.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_outlined,
                    size: 20, color: CottagecoreColors.forest),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Clases de hoy: ${todaySubjects.map((s) => '${s.emoji} ${s.name}').join(', ')}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CottagecoreColors.forest,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (todayTasks.isEmpty)
          const EmptyBotanicalState(
            message: 'Todo al día por hoy',
            subMessage:
                'No tienes entregas programadas para hoy. Tómate un té 🍵',
            emoji: '🌱',
          )
        else
          Column(
            children: todayTasks
                .map((task) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TaskCard(
                        task: task,
                        onEdit: () =>
                            TaskFormModal.show(context, initialTask: task),
                        onDelete: () =>
                            AgendaRepository.instance.deleteTask(task.id),
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildUpcomingSection(List<Task> upcomingTasks) {
    final compactTasks = upcomingTasks.take(6).toList();
    final visibleSlotCount = compactTasks.length < 2 ? 2 : 2;
    final fixedHeight = visibleSlotCount * 86.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🍂 Próximamente',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: CottagecoreColors.forest,
          ),
        ),
        const SizedBox(height: 12),
        if (upcomingTasks.isEmpty)
          const EmptyBotanicalState(
            message: 'Sin entregas pendientes próximas',
            subMessage: 'Excelente ritmo de estudio.',
            emoji: '🌾',
          )
        else
          SizedBox(
            height: fixedHeight,
            child: Scrollbar(
              thumbVisibility: compactTasks.length > 2,
              child: ListView.separated(
                itemCount: compactTasks.length,
                padding: EdgeInsets.zero,
                physics: compactTasks.length > 2
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final task = compactTasks[index];
                  final sub = AgendaRepository.instance.getSubjectById(task.subjectId);
                  final subColor = sub?.color ?? CottagecoreColors.sage;

                  return SizedBox(
                    height: 78,
                    child: Card(
                      child: InkWell(
                        onTap: () => TaskFormModal.show(context, initialTask: task),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 68),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border(
                              left: BorderSide(color: subColor, width: 5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 66,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: CottagecoreColors.creamDarker,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  DateFormat('d MMM', 'es_ES').format(task.dueDate),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: CottagecoreColors.warmBrown,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: CottagecoreColors.forest,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${sub?.emoji ?? '📚'} ${sub?.name ?? 'Materia'} · ${task.dueInfo.text}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: task.dueInfo.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded,
                                  color: CottagecoreColors.warmBrown),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUpcomingAssessments(
    List<Exam> exams,
    List<Deliverable> deliverables,
  ) {
    final repo = AgendaRepository.instance;
    final items = <({
      DateTime date,
      String title,
      String detail,
      IconData icon,
      Color color,
    })>[
      ...exams.map((exam) {
        final subject = repo.getSubjectById(exam.subjectId);
        return (
          date: exam.date,
          title: exam.name,
          detail:
              '${subject?.emoji ?? '📚'} ${subject?.name ?? 'Examen'} · ${exam.time}',
          icon: Icons.school_outlined,
          color: CottagecoreColors.terracotta,
        );
      }),
      ...deliverables.map((item) {
        final subject = repo.getSubjectById(item.subjectId);
        return (
          date: item.date,
          title: item.title,
          detail:
              '${subject?.emoji ?? '📚'} ${subject?.name ?? 'Evento'}${item.description == null ? '' : ' · ${item.description}'}',
          icon: Icons.event_outlined,
          color: CottagecoreColors.sage,
        );
      }),
    ]..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📌 Próximos exámenes y eventos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: CottagecoreColors.forest,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const EmptyBotanicalState(
            message: 'Sin exámenes ni eventos próximos',
            subMessage: 'Aquí aparecerán las próximas fechas importantes.',
            emoji: '🌾',
          )
        else
          Column(
            children: items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 68),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border(
                                left: BorderSide(color: item.color, width: 5)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: item.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(item.icon, color: item.color),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: CottagecoreColors.forest,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.detail,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF7A6F62),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('d MMM', 'es_ES').format(item.date),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: item.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildWeekStripSection(
    List<Task> tasks,
    List<Exam> exams,
    List<Deliverable> deliverables,
  ) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    final dayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CottagecoreColors.creamCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CottagecoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '🌷 Esta semana',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CottagecoreColors.forest,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  '${DateFormat('d MMM').format(startOfWeek)} - ${DateFormat('d MMM').format(days.last)}',
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF7A6F62)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final day = days[index];
              final isToday = DateUtils.isSameDay(day, now);
              final isSelected = DateUtils.isSameDay(day, _selectedDate);
              final hasActivities =
                  tasks.any((t) => DateUtils.isSameDay(t.dueDate, day)) ||
                      exams.any((e) => DateUtils.isSameDay(e.date, day)) ||
                      deliverables
                          .any((item) => DateUtils.isSameDay(item.date, day));

              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedDate = day),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CottagecoreColors.forest
                          : isToday
                              ? CottagecoreColors.sage.withValues(alpha: 0.18)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !isSelected
                          ? Border.all(
                              color: CottagecoreColors.sage, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          dayLetters[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6B6053),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : CottagecoreColors.forest,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasActivities
                                ? (isSelected
                                    ? Colors.white
                                    : CottagecoreColors.terracotta)
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayActivities(List<Task> selectedDayTasks) {
    final formattedDate =
        DateFormat('EEEE, d MMMM', 'es_ES').format(_selectedDate);

    return Container(
      key: const ValueKey('home-right-bottom-section-content'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CottagecoreColors.creamCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CottagecoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Actividades para el $formattedDate',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CottagecoreColors.warmBrown,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                tooltip: 'Añadir tarea para esta fecha',
                onPressed: () =>
                    TaskFormModal.show(context, initialDueDate: _selectedDate),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (selectedDayTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'Sin tareas programadas para este día.',
                style: TextStyle(fontSize: 13, color: Color(0xFF8A7E72)),
              ),
            )
          else
            ...selectedDayTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TaskCard(
                  task: task,
                  onEdit: () => TaskFormModal.show(context, initialTask: task),
                  onDelete: () => AgendaRepository.instance.deleteTask(task.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
