import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';
import '../widgets/empty_botanical_state.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_modal.dart';

enum CalendarViewMode { month, week, agenda }

enum _WeekFilterType { all, classType, task, event, exam }

extension on _WeekFilterType {
  String get label => switch (this) {
        _WeekFilterType.all => 'Todo',
        _WeekFilterType.classType => 'Clases',
        _WeekFilterType.task => 'Tareas',
        _WeekFilterType.event => 'Eventos',
        _WeekFilterType.exam => 'Exámenes',
      };
}

class _WeekCalendarItem {
  const _WeekCalendarItem({
    required this.date,
    required this.title,
    required this.detail,
    required this.subjectId,
    required this.type,
    required this.icon,
    required this.color,
    this.timeLabel,
    this.onTap,
  });

  final DateTime date;
  final String title;
  final String detail;
  final String subjectId;
  final _WeekFilterType type;
  final IconData icon;
  final Color color;
  final String? timeLabel;
  final VoidCallback? onTap;
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarViewMode _viewMode = CalendarViewMode.month;
  DateTime _currentMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime.now();
  _WeekFilterType? _weekFilterType;
  String? _weekSubjectFilter;

  _WeekFilterType get _selectedWeekFilterType =>
      _weekFilterType ?? _WeekFilterType.all;
  String get _selectedWeekSubjectFilter => _weekSubjectFilter ?? '';

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    setState(() {
      _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
      _selectedDate = DateTime.now();
    });
  }

  List<Subject> _classesOn(AgendaRepository repo, DateTime date) {
    return _scheduledClassesOn(repo, date)
        .map((entry) => entry.subject)
        .fold<List<Subject>>([], (subjects, subject) {
      if (!subjects.any((item) => item.id == subject.id)) {
        subjects.add(subject);
      }
      return subjects;
    });
  }

  List<({Subject subject, ClassSchedule? schedule})> _scheduledClassesOn(
      AgendaRepository repo, DateTime date) {
    final dayNames = switch (date.weekday) {
      DateTime.monday => ['lunes', 'lun'],
      DateTime.tuesday => ['martes', 'mar'],
      DateTime.wednesday => ['miércoles', 'miercoles', 'mié', 'mie'],
      DateTime.thursday => ['jueves', 'jue'],
      DateTime.friday => ['viernes', 'vie'],
      DateTime.saturday => ['sábado', 'sabado', 'sáb', 'sab'],
      DateTime.sunday => ['domingo', 'dom'],
      _ => const <String>[],
    };

    final entries = <({Subject subject, ClassSchedule? schedule})>[];
    for (final subject in repo.subjects) {
      if (subject.schedules.isNotEmpty) {
        entries.addAll(subject.schedules
            .where((schedule) => schedule.weekday == date.weekday)
            .map((schedule) => (subject: subject, schedule: schedule)));
      } else {
        final legacySchedule = subject.schedule?.toLowerCase();
        if (legacySchedule != null && dayNames.any(legacySchedule.contains)) {
          entries.add((subject: subject, schedule: null));
        }
      }
    }
    return entries;
  }

  String _classHours(Subject subject) {
    if (subject.schedules.isNotEmpty) {
      return subject.schedules
          .map(
              (schedule) => '${schedule.timeLabel} · ${schedule.durationLabel}')
          .join('  |  ');
    }
    final schedule = subject.schedule?.trim();
    if (schedule == null || schedule.isEmpty) return 'Hora por confirmar';

    final timeRange = RegExp(
      r'\d{1,2}[:.]\d{2}\s*(?:-|–|a|hasta)\s*\d{1,2}[:.]\d{2}',
      caseSensitive: false,
    ).firstMatch(schedule);
    return timeRange?.group(0)?.replaceAll('.', ':') ?? schedule;
  }

  String _classHoursOnDate(Subject subject, DateTime date) {
    final schedules = subject.schedules
        .where((schedule) => schedule.weekday == date.weekday)
        .toList();
    if (schedules.isEmpty) return _classHours(subject);
    return schedules
        .map((schedule) => '${schedule.timeLabel} · ${schedule.durationLabel}')
        .join('  |  ');
  }

  @override
  Widget build(BuildContext context) {
    final repo = AgendaRepository.instance;
    final isDesktop = MediaQuery.of(context).size.width >= 860;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final title = const Text(
          '📅 Calendario',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: CottagecoreColors.forest,
            fontFamily: 'serif',
          ),
        );
        final viewSwitcher = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: CottagecoreColors.creamDarker,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CottagecoreColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _viewModeButton(CalendarViewMode.month, 'Mes'),
              _viewModeButton(CalendarViewMode.week, 'Semana'),
              _viewModeButton(CalendarViewMode.agenda, 'Agenda'),
            ],
          ),
        );
        final addButton = IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: CottagecoreColors.forest,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Añadir evento para fecha seleccionada',
          onPressed: () => TaskFormModal.show(
            context,
            initialDueDate: _selectedDate,
          ),
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
                  if (isDesktop)
                    Row(
                      children: [
                        title,
                        const Spacer(),
                        viewSwitcher,
                        const SizedBox(width: 8),
                        addButton,
                      ],
                    )
                  else ...[
                    Row(
                      children: [Expanded(child: title), addButton],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: viewSwitcher,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // View content
                  Expanded(
                    child: switch (_viewMode) {
                      CalendarViewMode.month =>
                        _buildMonthView(repo, isDesktop),
                      CalendarViewMode.week => _buildWeekView(repo, isDesktop),
                      CalendarViewMode.agenda => _buildAgendaView(repo),
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _viewModeButton(CalendarViewMode mode, String label) {
    final isSelected = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? CottagecoreColors.forest : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF685D51),
          ),
        ),
      ),
    );
  }

  // --- MONTH VIEW ---

  Widget _buildMonthView(AgendaRepository repo, bool isDesktop) {
    final now = DateTime.now();
    final firstDayOfMonth = _currentMonth;
    final startOffset = (firstDayOfMonth.weekday - 1) % 7;
    final calendarStart = firstDayOfMonth.subtract(Duration(days: startOffset));
    final days = List.generate(42, (i) => calendarStart.add(Duration(days: i)));

    final dayActivities = repo.tasks
        .where((t) => DateUtils.isSameDay(t.dueDate, _selectedDate))
        .toList();
    final dayExams = repo.exams
        .where((e) => DateUtils.isSameDay(e.date, _selectedDate))
        .toList();
    final dayDeliverables = repo.deliverables
        .where((item) => DateUtils.isSameDay(item.date, _selectedDate))
        .toList();
    final dayClasses = _classesOn(repo, _selectedDate);

    return isDesktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _monthGridCard(days, now, repo),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: _selectedDayActivitiesPanel(
                  dayActivities,
                  dayExams,
                  dayClasses,
                  dayDeliverables,
                  scrollable: true,
                ),
              ),
            ],
          )
        : SingleChildScrollView(
            child: Column(
              children: [
                _monthGridCard(days, now, repo),
                const SizedBox(height: 18),
                _selectedDayActivitiesPanel(
                  dayActivities,
                  dayExams,
                  dayClasses,
                  dayDeliverables,
                ),
              ],
            ),
          );
  }

  Widget _monthGridCard(
      List<DateTime> days, DateTime now, AgendaRepository repo) {
    final monthName = DateFormat('MMMM yyyy', 'es_ES').format(_currentMonth);
    final isNarrow = MediaQuery.of(context).size.width < 600;
    const dayHeaders = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Month Header (< Septiembre 2026 > + Hoy)
            if (isNarrow)
              Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: _prevMonth,
                      ),
                      Expanded(
                        child: Text(
                          monthName[0].toUpperCase() + monthName.substring(1),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: CottagecoreColors.forest,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: _goToToday,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: CottagecoreColors.sage),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Hoy',
                          style: TextStyle(color: CottagecoreColors.forest)),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _prevMonth,
                  ),
                  Text(
                    monthName[0].toUpperCase() + monthName.substring(1),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: CottagecoreColors.forest,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _nextMonth,
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: _goToToday,
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: CottagecoreColors.sage),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Hoy',
                        style: TextStyle(color: CottagecoreColors.forest)),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            // Weekday header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: dayHeaders
                  .map((h) => Expanded(
                        child: Text(
                          h,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7A6F62),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            // 6-week Days Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                final date = days[index];
                final isCurrentMonth = date.month == _currentMonth.month;
                final isToday = DateUtils.isSameDay(date, now);
                final isSelected = DateUtils.isSameDay(date, _selectedDate);

                final matchingTasks = repo.tasks
                    .where((t) => DateUtils.isSameDay(t.dueDate, date))
                    .toList();
                final matchingExams = repo.exams
                    .where((e) => DateUtils.isSameDay(e.date, date))
                    .toList();
                final matchingDeliverables = repo.deliverables
                    .where((item) => DateUtils.isSameDay(item.date, date))
                    .toList();
                final matchingClasses = _classesOn(repo, date);
                final hasEvents = matchingTasks.isNotEmpty ||
                    matchingExams.isNotEmpty ||
                    matchingDeliverables.isNotEmpty ||
                    matchingClasses.isNotEmpty;

                return InkWell(
                  onTap: () => setState(() => _selectedDate = date),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CottagecoreColors.forest
                          : isToday
                              ? CottagecoreColors.sage.withValues(alpha: 0.18)
                              : isCurrentMonth
                                  ? CottagecoreColors.creamDarker
                                      .withValues(alpha: 0.45)
                                  : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !isSelected
                          ? Border.all(
                              color: CottagecoreColors.sage, width: 1.5)
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : isCurrentMonth
                                    ? const Color(0xFF382F26)
                                    : const Color(0xFFB5ABA0),
                          ),
                        ),
                        if (hasEvents)
                          Positioned(
                            bottom: 4,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (matchingExams.isNotEmpty)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Colors.white
                                          : CottagecoreColors.urgentRed,
                                    ),
                                  ),
                                if (matchingTasks.isNotEmpty)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Colors.white
                                          : CottagecoreColors.sage,
                                    ),
                                  ),
                                if (matchingClasses.isNotEmpty)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Colors.white
                                          : CottagecoreColors.warmBrown,
                                    ),
                                  ),
                                if (matchingDeliverables.isNotEmpty)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Colors.white
                                          : CottagecoreColors.terracotta,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedDayActivitiesPanel(
    List<Task> tasks,
    List<Exam> exams,
    List<Subject> classes,
    List<Deliverable> deliverables, {
    bool scrollable = false,
  }) {
    final formatted = DateFormat('EEEE, d MMMM', 'es_ES').format(_selectedDate);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Actividades: $formatted',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CottagecoreColors.forest,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () =>
                  TaskFormModal.show(context, initialDueDate: _selectedDate),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Añadir'),
              style: TextButton.styleFrom(
                foregroundColor: CottagecoreColors.forest,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const Divider(height: 16),
        if (tasks.isEmpty &&
            exams.isEmpty &&
            classes.isEmpty &&
            deliverables.isEmpty)
          const EmptyBotanicalState(
            message: 'Día libre de entregas',
            subMessage:
                'Aprovecha para descansar o repasar apuntes tranquilamente.',
            emoji: '🌾',
          )
        else ...[
          if (deliverables.isNotEmpty) ...[
            const Text('📌 Entregas y eventos:',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: CottagecoreColors.terracotta)),
            const SizedBox(height: 6),
            ...deliverables.map((item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                      item.isSubmitted
                          ? Icons.event_available_rounded
                          : Icons.event_outlined,
                      color: CottagecoreColors.terracotta),
                  title: Text(item.title),
                  subtitle:
                      item.description == null ? null : Text(item.description!),
                  trailing: Text(item.isSubmitted ? 'Entregada' : 'Pendiente',
                      style: const TextStyle(fontSize: 11)),
                )),
            const SizedBox(height: 8),
          ],
          if (classes.isNotEmpty) ...[
            const Text(
              '📚 Clases:',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: CottagecoreColors.forest),
            ),
            const SizedBox(height: 6),
            ...classes.map((subject) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: subject.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                        left: BorderSide(color: subject.color, width: 4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 17, color: subject.color),
                      const SizedBox(width: 8),
                      Text(
                        _classHoursOnDate(subject, _selectedDate),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: subject.color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${subject.emoji} ${subject.name}${subject.classroom == null ? '' : ' • ${subject.classroom}'}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
          ],
          if (exams.isNotEmpty) ...[
            const Text(
              '📝 Exámenes:',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: CottagecoreColors.terracotta),
            ),
            const SizedBox(height: 6),
            ...exams.map((exam) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CottagecoreColors.urgentRedBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.school_rounded,
                          color: CottagecoreColors.urgentRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${exam.name} • ${exam.time} (${exam.classroom})',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
          ],
          if (tasks.isNotEmpty) ...[
            const Text(
              '✓ Tareas y Entregas:',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: CottagecoreColors.forest),
            ),
            const SizedBox(height: 6),
            ...tasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TaskCard(
                    task: task,
                    onEdit: () =>
                        TaskFormModal.show(context, initialTask: task),
                    onDelete: () =>
                        AgendaRepository.instance.deleteTask(task.id),
                  ),
                )),
          ],
        ],
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: scrollable ? SingleChildScrollView(child: content) : content,
      ),
    );
  }

  // --- WEEK VIEW ---

  Widget _buildWeekView(AgendaRepository repo, bool isDesktop) {
    final startOfWeek =
        _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () {
                setState(() => _selectedDate =
                    _selectedDate.subtract(const Duration(days: 7)));
              },
            ),
            Expanded(
              child: Text(
                'Semana del ${DateFormat('d MMM', 'es_ES').format(startOfWeek)} al ${DateFormat('d MMM yyyy', 'es_ES').format(days.last)}',
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CottagecoreColors.forest),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () {
                setState(() =>
                    _selectedDate = _selectedDate.add(const Duration(days: 7)));
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildWeekFilters(repo),
        const SizedBox(height: 10),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _buildWeekColumns(
                repo,
                days,
                height: constraints.maxHeight,
                availableWidth: constraints.maxWidth,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekFilters(AgendaRepository repo) {
    final typeItems = _WeekFilterType.values
        .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
        .toList();
    final subjectItems = [
      const DropdownMenuItem(value: '', child: Text('Todas las asignaturas')),
      ...repo.subjects.map((subject) => DropdownMenuItem(
            value: subject.id,
            child: Text('${subject.emoji} ${subject.name}',
                overflow: TextOverflow.ellipsis),
          )),
    ];

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<_WeekFilterType>(
            key: const ValueKey('calendar-week-type-filter'),
            initialValue: _selectedWeekFilterType,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Tipo',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            items: typeItems,
            onChanged: (value) {
              if (value != null) setState(() => _weekFilterType = value);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            key: const ValueKey('calendar-week-subject-filter'),
            initialValue: _selectedWeekSubjectFilter,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Asignatura',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            items: subjectItems,
            onChanged: (value) {
              if (value != null) setState(() => _weekSubjectFilter = value);
            },
          ),
        ),
      ],
    );
  }

  List<_WeekCalendarItem> _itemsForDate(
    AgendaRepository repo,
    DateTime date,
  ) {
    final items = <_WeekCalendarItem>[];
    for (final entry in _scheduledClassesOn(repo, date)) {
      final subject = entry.subject;
      final schedule = entry.schedule;
      items.add(_WeekCalendarItem(
        date: date,
        title: subject.name,
        detail:
            '${schedule == null ? _classHours(subject) : '${schedule.timeLabel} · ${schedule.durationLabel}'}${subject.classroom == null ? '' : ' · ${subject.classroom}'}',
        subjectId: subject.id,
        type: _WeekFilterType.classType,
        icon: Icons.school_outlined,
        color: subject.color,
        timeLabel: schedule?.timeLabel ?? _classHours(subject),
      ));
    }

    for (final task in repo.tasks.where(
      (task) => DateUtils.isSameDay(task.dueDate, date),
    )) {
      final subject = repo.getSubjectById(task.subjectId);
      final type = switch (task.type) {
        TaskType.classType => _WeekFilterType.classType,
        TaskType.exam => _WeekFilterType.exam,
        TaskType.event => _WeekFilterType.event,
        TaskType.assignment || TaskType.project => _WeekFilterType.task,
      };
      items.add(_WeekCalendarItem(
        date: date,
        title: task.title,
        detail:
            '${subject?.emoji ?? '📚'} ${subject?.name ?? 'Materia'} · ${task.statusLabel}',
        subjectId: task.subjectId,
        type: type,
        icon: Icons.checklist_rounded,
        color: subject?.color ?? CottagecoreColors.sage,
        timeLabel: DateFormat('HH:mm').format(task.dueDate),
        onTap: () => TaskFormModal.show(context, initialTask: task),
      ));
    }

    for (final exam in repo.exams.where(
      (exam) => DateUtils.isSameDay(exam.date, date),
    )) {
      final subject = repo.getSubjectById(exam.subjectId);
      items.add(_WeekCalendarItem(
        date: date,
        title: exam.name,
        detail:
            '${subject?.emoji ?? '📚'} ${subject?.name ?? 'Examen'} · ${exam.classroom}',
        subjectId: exam.subjectId,
        type: _WeekFilterType.exam,
        icon: Icons.school_outlined,
        color: CottagecoreColors.urgentRed,
        timeLabel: exam.time,
      ));
    }

    for (final event in repo.deliverables.where(
      (item) => DateUtils.isSameDay(item.date, date),
    )) {
      final subject = repo.getSubjectById(event.subjectId);
      items.add(_WeekCalendarItem(
        date: date,
        title: event.title,
        detail:
            '${subject?.emoji ?? '📚'} ${subject?.name ?? 'Evento'}${event.isSubmitted ? ' · Entregada' : ''}',
        subjectId: event.subjectId,
        type: _WeekFilterType.event,
        icon: Icons.event_outlined,
        color: CottagecoreColors.terracotta,
      ));
    }

    items.sort((a, b) =>
        _minutesOfDay(a.timeLabel).compareTo(_minutesOfDay(b.timeLabel)));
    return items;
  }

  int _minutesOfDay(String? time) {
    if (time == null) return 24 * 60;
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(time);
    if (match == null) return 24 * 60;
    return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  }

  List<_WeekCalendarItem> _filterWeekItems(List<_WeekCalendarItem> items) =>
      items
          .where((item) =>
              (_selectedWeekFilterType == _WeekFilterType.all ||
                  item.type == _selectedWeekFilterType) &&
              (_selectedWeekSubjectFilter.isEmpty ||
                  item.subjectId == _selectedWeekSubjectFilter))
          .toList();

  Widget _buildWeekColumns(
    AgendaRepository repo,
    List<DateTime> days, {
    required double height,
    required double availableWidth,
  }) {
    const minColumnWidth = 102.0;
    final columnWidth = (availableWidth / 7).clamp(minColumnWidth, 132.0);
    final totalWidth = columnWidth * 7;
    const dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(days.length, (index) {
              final day = days[index];
              final isToday = DateUtils.isSameDay(day, DateTime.now());
              final items = _filterWeekItems(_itemsForDate(repo, day));
              return SizedBox(
                width: columnWidth,
                child: Card(
                  color: isToday
                      ? CottagecoreColors.sage.withValues(alpha: 0.08)
                      : CottagecoreColors.creamCard,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _selectedDate = day),
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              children: [
                                Text(dayNames[index],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: CottagecoreColors.warmBrown,
                                    )),
                                const SizedBox(height: 3),
                                Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? CottagecoreColors.forest
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isToday
                                          ? Colors.white
                                          : CottagecoreColors.forest,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 12),
                        Expanded(
                          child: items.isEmpty
                              ? const SizedBox.shrink()
                              : ListView.separated(
                                  padding: EdgeInsets.zero,
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (context, itemIndex) =>
                                      _weekItemCard(items[itemIndex],
                                          compact: true),
                                ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Añadir tarea para ${dayNames[index]}',
                          onPressed: () => TaskFormModal.show(
                            context,
                            initialDueDate: day,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _weekItemCard(_WeekCalendarItem item, {bool compact = false}) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 6 : 8),
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: item.color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(item.icon, size: compact ? 13 : 15, color: item.color),
                const SizedBox(width: 4),
                if (!compact && item.timeLabel != null) ...[
                  Expanded(
                    child: Text(
                      item.timeLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: item.color,
                      ),
                    ),
                  ),
                ] else
                  Expanded(
                    child: Text(
                      DateFormat('EEE d MMM', 'es_ES').format(item.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 9 : 10,
                        color: item.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              item.title,
              maxLines: compact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w700,
                color: CottagecoreColors.forest,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 2),
              Text(
                item.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF7A6F62)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- AGENDA VIEW ---

  Widget _buildAgendaView(AgendaRepository repo) {
    final now = DateTime.now();
    // Gather all upcoming dates with tasks or exams
    final activeTasks = List<Task>.from(repo.tasks)
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final hasClasses =
        List.generate(7, (index) => now.add(Duration(days: index)))
            .any((date) => _classesOn(repo, date).isNotEmpty);

    if (activeTasks.isEmpty &&
        repo.exams.isEmpty &&
        repo.deliverables.isEmpty &&
        !hasClasses) {
      return const EmptyBotanicalState(
        message: 'Agenda despejada',
        subMessage: 'No hay actividades futuras registradas.',
        emoji: '🌿',
      );
    }

    return ListView(
      children: [
        // Today Block
        _agendaSectionHeader('HOY', now),
        ..._activitiesForDate(repo, now),

        const SizedBox(height: 16),
        // Tomorrow Block
        _agendaSectionHeader('MAÑANA', now.add(const Duration(days: 1))),
        ..._activitiesForDate(repo, now.add(const Duration(days: 1))),

        const SizedBox(height: 16),
        // Next days
        ...List.generate(5, (i) {
          final day = now.add(Duration(days: i + 2));
          final items = _activitiesForDate(repo, day);
          if (items.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _agendaSectionHeader(
                DateFormat('EEEE, d MMMM', 'es_ES').format(day).toUpperCase(),
                day,
              ),
              ...items,
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  Widget _agendaSectionHeader(String title, DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: CottagecoreColors.forest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('d MMM', 'es_ES').format(date),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7A6F62)),
          ),
        ],
      ),
    );
  }

  List<Widget> _activitiesForDate(AgendaRepository repo, DateTime date) {
    final tasks =
        repo.tasks.where((t) => DateUtils.isSameDay(t.dueDate, date)).toList();
    final exams =
        repo.exams.where((e) => DateUtils.isSameDay(e.date, date)).toList();
    final deliverables = repo.deliverables
        .where((item) => DateUtils.isSameDay(item.date, date))
        .toList();
    final classes = _classesOn(repo, date);

    if (tasks.isEmpty &&
        exams.isEmpty &&
        classes.isEmpty &&
        deliverables.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6.0),
          child: Text(
            'Sin actividades registradas',
            style: TextStyle(
                fontSize: 13,
                color: Colors.black38,
                fontStyle: FontStyle.italic),
          ),
        ),
      ];
    }

    final widgets = <Widget>[];

    for (final item in deliverables) {
      final subject = repo.getSubjectById(item.subjectId);
      widgets.add(Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CottagecoreColors.warningOrangeBg,
          borderRadius: BorderRadius.circular(14),
          border: Border(
              left: BorderSide(color: CottagecoreColors.terracotta, width: 4)),
        ),
        child: Row(
          children: [
            Icon(
                item.isSubmitted
                    ? Icons.event_available_rounded
                    : Icons.event_outlined,
                color: CottagecoreColors.terracotta,
                size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${item.title}${subject == null ? '' : ' • ${subject.emoji} ${subject.name}'}${item.isSubmitted ? ' · Entregada' : ''}',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
      ));
    }

    for (final subject in classes) {
      widgets.add(Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: subject.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: subject.color, width: 4)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded, size: 18, color: subject.color),
            const SizedBox(width: 8),
            Text(
              _classHoursOnDate(subject, date),
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: subject.color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${subject.emoji} ${subject.name}${subject.classroom == null ? '' : ' • ${subject.classroom}'}',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
      ));
    }

    for (final exam in exams) {
      final sub = repo.getSubjectById(exam.subjectId);
      widgets.add(Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CottagecoreColors.urgentRedBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: CottagecoreColors.urgentRed.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Text('${exam.time} ',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const Text('📝 '),
            Expanded(
              child: Text(
                '${exam.name} • ${sub?.emoji ?? '📚'} ${sub?.name ?? ''} (${exam.classroom})',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
      ));
    }

    for (final task in tasks) {
      final sub = repo.getSubjectById(task.subjectId);
      widgets.add(Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CottagecoreColors.creamCard,
          borderRadius: BorderRadius.circular(14),
          border: Border(
              left: BorderSide(
                  color: sub?.color ?? CottagecoreColors.sage, width: 4)),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () => repo.toggleTaskCompletion(task.id),
              child: Icon(
                task.status == TaskStatus.completed
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: task.status == TaskStatus.completed
                    ? CottagecoreColors.calmGreen
                    : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration: task.status == TaskStatus.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${sub?.emoji ?? '📚'} ${sub?.name ?? 'Materia'} • ${task.typeLabel}',
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF7A6F62)),
                  ),
                ],
              ),
            ),
            Text(
              task.dueInfo.text,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: task.dueInfo.color),
            ),
          ],
        ),
      ));
    }

    return widgets;
  }
}
