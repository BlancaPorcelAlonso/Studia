import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';
import '../widgets/kanban_column.dart';
import '../widgets/task_form_modal.dart';

class TasksKanbanScreen extends StatefulWidget {
  const TasksKanbanScreen({this.selectedSubjectId, super.key});

  final String? selectedSubjectId;

  @override
  State<TasksKanbanScreen> createState() => _TasksKanbanScreenState();
}

class _TasksKanbanScreenState extends State<TasksKanbanScreen>
    with SingleTickerProviderStateMixin {
  String _timeFilter = 'Todas';
  String _subjectFilter = 'Todas';
  late TabController _tabController;

  final List<String> _timeFilters = [
    'Todas',
    'Hoy',
    'Esta semana',
    'Atrasadas',
    'Urgentes',
    'Completadas',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.selectedSubjectId != null) {
      _subjectFilter = widget.selectedSubjectId!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Task> _applyFilters(List<Task> allTasks) {
    final now = DateTime.now();

    return allTasks.where((task) {
      // Subject filter
      if (_subjectFilter != 'Todas' && task.subjectId != _subjectFilter) {
        return false;
      }

      // Time & Status filter
      switch (_timeFilter) {
        case 'Hoy':
          return DateUtils.isSameDay(task.dueDate, now);
        case 'Esta semana':
          final diff = task.dueDate.difference(now).inDays;
          return diff >= 0 && diff <= 7;
        case 'Atrasadas':
          return task.isLate;
        case 'Urgentes':
          return task.priority == TaskPriority.urgent;
        case 'Completadas':
          return task.status == TaskStatus.completed;
        case 'Todas':
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final repo = AgendaRepository.instance;
    final isDesktop = MediaQuery.of(context).size.width >= 860;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final filteredTasks = _applyFilters(repo.tasks);
        final todoTasks =
            filteredTasks.where((t) => t.status == TaskStatus.todo).toList();
        final inProgressTasks = filteredTasks
            .where((t) => t.status == TaskStatus.inProgress)
            .toList();
        final completedTasks = filteredTasks
            .where((t) => t.status == TaskStatus.completed)
            .toList();

        final columns = [
          KanbanColumn(
            status: TaskStatus.todo,
            title: 'Por hacer',
            emoji: '📥',
            accentColor: CottagecoreColors.warmBrown,
            tasks: todoTasks,
            onEditTask: (t) => TaskFormModal.show(context, initialTask: t),
            onAddTask: () => TaskFormModal.show(
              context,
              initialStatus: TaskStatus.todo,
              initialSubjectId: _subjectFilter != 'Todas' ? _subjectFilter : null,
            ),
          ),
          KanbanColumn(
            status: TaskStatus.inProgress,
            title: 'En proceso',
            emoji: '🌱',
            accentColor: CottagecoreColors.sage,
            tasks: inProgressTasks,
            onEditTask: (t) => TaskFormModal.show(context, initialTask: t),
            onAddTask: () => TaskFormModal.show(
              context,
              initialStatus: TaskStatus.inProgress,
              initialSubjectId: _subjectFilter != 'Todas' ? _subjectFilter : null,
            ),
          ),
          KanbanColumn(
            status: TaskStatus.completed,
            title: 'Completado',
            emoji: '✓',
            accentColor: CottagecoreColors.forest,
            tasks: completedTasks,
            onEditTask: (t) => TaskFormModal.show(context, initialTask: t),
            onAddTask: () => TaskFormModal.show(
              context,
              initialStatus: TaskStatus.completed,
              initialSubjectId: _subjectFilter != 'Todas' ? _subjectFilter : null,
            ),
          ),
        ];

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
                  // Title + Action button
                  Row(
                    children: [
                      const Text(
                        '🗂️ Tablero de Tareas',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: CottagecoreColors.forest,
                          fontFamily: 'serif',
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => TaskFormModal.show(
                          context,
                          initialSubjectId:
                              _subjectFilter != 'Todas' ? _subjectFilter : null,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: CottagecoreColors.forest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Nueva tarea'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Horizontal Filters Bar (Time + Subject)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Subject selector
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: CottagecoreColors.creamDarker,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: CottagecoreColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _subjectFilter,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                              items: [
                                const DropdownMenuItem(
                                  value: 'Todas',
                                  child: Text('📚 Todas las materias'),
                                ),
                                ...repo.subjects.map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text('${s.emoji} ${s.name}'),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _subjectFilter = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Time filters chips
                        ..._timeFilters.map((filter) {
                          final isSelected = _timeFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(filter),
                              selected: isSelected,
                              selectedColor: CottagecoreColors.sage.withValues(alpha: 0.25),
                              labelStyle: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? CottagecoreColors.forest
                                    : const Color(0xFF6B6053),
                              ),
                              onSelected: (_) => setState(() => _timeFilter = filter),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Layout: Desktop 3 columns side-by-side | Mobile TabBar + TabBarView
                  Expanded(
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: columns
                                .map((col) => Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 14),
                                        child: col,
                                      ),
                                    ))
                                .toList(),
                          )
                        : Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: CottagecoreColors.creamDarker,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: TabBar(
                                  controller: _tabController,
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  indicator: BoxDecoration(
                                    color: CottagecoreColors.forest,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  labelColor: Colors.white,
                                  unselectedLabelColor: const Color(0xFF6B6053),
                                  labelStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  tabs: [
                                    Tab(text: '📥 Por hacer (${todoTasks.length})'),
                                    Tab(text: '🌱 En curso (${inProgressTasks.length})'),
                                    Tab(text: '✓ Hecho (${completedTasks.length})'),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: columns,
                                ),
                              ),
                            ],
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
