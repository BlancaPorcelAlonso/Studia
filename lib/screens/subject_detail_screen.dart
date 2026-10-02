import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../models/models.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';
import '../widgets/empty_botanical_state.dart';
import '../widgets/exam_form_modal.dart';
import '../widgets/note_form_modal.dart';
import '../widgets/priority_badge.dart';
import '../widgets/subject_form_modal.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_modal.dart';

class SubjectDetailScreen extends StatefulWidget {
  const SubjectDetailScreen({
    required this.subject,
    this.initialTabIndex = 0,
    super.key,
  });

  final Subject subject;
  final int initialTabIndex;

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  String _notesSearch = '';
  String _notesCategoryFilter = 'Todas';

  @override
  Widget build(BuildContext context) {
    final repo = AgendaRepository.instance;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final currentSubject =
            repo.getSubjectById(widget.subject.id) ?? widget.subject;
        final tasks =
            repo.tasks.where((t) => t.subjectId == currentSubject.id).toList();
        final pendingTasks =
            tasks.where((t) => t.status != TaskStatus.completed).toList();
        final exams =
            repo.exams.where((e) => e.subjectId == currentSubject.id).toList();
        final notes =
            repo.notes.where((n) => n.subjectId == currentSubject.id).toList();
        final deliverables = repo.deliverables
            .where((item) => item.subjectId == currentSubject.id)
            .toList();
        final absences = repo.absences
            .where((item) => item.subjectId == currentSubject.id)
            .toList();
        final grades = repo.grades
            .where((item) => item.subjectId == currentSubject.id)
            .toList();

        return DefaultTabController(
          length: 7,
          initialIndex: widget.initialTabIndex.clamp(0, 6),
          child: Scaffold(
            appBar: AppBar(
              title: Text('${currentSubject.emoji} ${currentSubject.name}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar asignatura',
                  onPressed: () => _editSubjectDialog(context, currentSubject),
                ),
              ],
            ),
            body: Column(
              children: [
                // Notebook Header
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: currentSubject.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: currentSubject.color.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: currentSubject.color.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(currentSubject.emoji,
                              style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSubject.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: CottagecoreColors.forest,
                                fontFamily: 'serif',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Profesor: ${currentSubject.teacher ?? "Por definir"}',
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF6E6457)),
                            ),
                            if (currentSubject.schedule != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Horario: ${currentSubject.schedule!}',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF7A7064)),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _headerBadge(
                                  '${pendingTasks.length} pendientes',
                                  CottagecoreColors.forest,
                                  currentSubject.color.withValues(alpha: 0.2),
                                ),
                                _headerBadge(
                                  '${exams.length} examen(es)',
                                  CottagecoreColors.terracotta,
                                  CottagecoreColors.warningOrangeBg,
                                ),
                                _headerBadge(
                                  '${notes.length} apuntes',
                                  CottagecoreColors.warmBrown,
                                  CottagecoreColors.creamDarker,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Subject workspace sections
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: CottagecoreColors.creamDarker,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.center,
                    labelPadding: EdgeInsets.symmetric(horizontal: 20),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: CottagecoreColors.forest,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Color(0xFF6B6053),
                    labelStyle:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    tabs: [
                      Tab(text: 'Resumen'),
                      Tab(text: 'Tareas'),
                      Tab(text: 'Entregas'),
                      Tab(text: 'Apuntes'),
                      Tab(text: 'Exámenes'),
                      Tab(text: 'Progreso'),
                      Tab(text: 'Info'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // TabBarView
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildSummaryTab(
                        context,
                        currentSubject,
                        tasks,
                        exams,
                        notes,
                        deliverables,
                      ),
                      _buildTasksTab(context, currentSubject, tasks),
                      _buildDeliverablesTab(
                          context, currentSubject, deliverables),
                      _buildNotesTab(context, currentSubject, notes),
                      _buildExamsTab(context, currentSubject, exams),
                      _buildProgressTab(
                          context, currentSubject, absences, grades),
                      _buildInfoTab(context, currentSubject),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _headerBadge(String text, Color textCol, Color bgCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: textCol),
      ),
    );
  }

  String _weekdayLabel(int weekday) => const [
        '',
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
        'Domingo',
      ][weekday.clamp(1, 7)];

  Widget _buildSummaryTab(
    BuildContext context,
    Subject subject,
    List<Task> tasks,
    List<Exam> exams,
    List<StudyNote> notes,
    List<Deliverable> deliverables,
  ) {
    final recentTasks = List<Task>.from(tasks)
      ..sort((a, b) => (b.completedAt ?? b.startDate ?? b.dueDate)
          .compareTo(a.completedAt ?? a.startDate ?? a.dueDate));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcomingDeliverables = deliverables
        .where((item) =>
            !item.isSubmitted && !DateUtils.dateOnly(item.date).isBefore(today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final recentNotes = List<StudyNote>.from(notes)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final upcomingExams = exams
        .where((exam) => !DateUtils.dateOnly(exam.date).isBefore(today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 2 : 1;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 112,
                child: Card(
                  color: subject.color.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bookmark_added_outlined,
                                color: subject.color, size: 19),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('Dónde me quedé',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                            ),
                            IconButton(
                              tooltip: 'Actualizar último punto de estudio',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _editLastStudy(context, subject),
                              icon: const Icon(Icons.edit_outlined, size: 19),
                            ),
                          ],
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _editLastStudy(context, subject),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                subject.lastStudyNote?.isNotEmpty == true
                                    ? subject.lastStudyNote!
                                    : 'Anota qué hiciste y qué toca retomar.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 12),
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 218,
                children: [
                  _summaryPanel(
                    context,
                    title: 'Tareas',
                    icon: Icons.checklist_rounded,
                    tabIndex: 1,
                    content: _summaryTaskRows(recentTasks.take(3).toList()),
                  ),
                  _summaryPanel(
                    context,
                    title: 'Próximas entregas',
                    icon: Icons.event_available_outlined,
                    tabIndex: 2,
                    content: _summaryDeliverableRows(
                        upcomingDeliverables.take(3).toList()),
                  ),
                  _summaryPanel(
                    context,
                    title: 'Apuntes recientes',
                    icon: Icons.auto_stories_outlined,
                    tabIndex: 3,
                    content: _summaryNoteRows(
                        context, subject.id, recentNotes.take(2).toList()),
                  ),
                  _summaryPanel(
                    context,
                    title: 'Exámenes',
                    icon: Icons.school_outlined,
                    tabIndex: 4,
                    content: _summaryExamRows(upcomingExams.take(3).toList()),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryPanel(
    BuildContext context, {
    required String title,
    required IconData icon,
    required int tabIndex,
    required Widget content,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: CottagecoreColors.forest),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                TextButton.icon(
                  onPressed: () =>
                      DefaultTabController.of(context).animateTo(tabIndex),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                  label: const Text('Ver todas'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            const Divider(height: 14),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _summaryTaskRows(List<Task> tasks) {
    if (tasks.isEmpty) return _summaryEmpty('Sin tareas recientes');
    return Column(
      children: tasks
          .map((task) => SizedBox(
                height: 46,
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Checkbox(
                        value: task.status == TaskStatus.completed,
                        visualDensity: VisualDensity.compact,
                        onChanged: (_) => AgendaRepository.instance
                            .toggleTaskCompletion(task.id),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 6),
                    PriorityBadge(priority: task.priority, compact: true),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _summaryDeliverableRows(List<Deliverable> items) {
    if (items.isEmpty) return _summaryEmpty('Sin próximas entregas');
    return Column(
      children: items
          .map((item) => SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Container(
                      width: 62,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            CottagecoreColors.terracotta.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        DateFormat('d MMM', 'es_ES').format(item.date),
                        maxLines: 1,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: CottagecoreColors.terracotta),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 42,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: CottagecoreColors.creamDarker
                              .withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: CottagecoreColors.border),
                        ),
                        child: Text(item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _summaryNoteRows(
    BuildContext context,
    String subjectId,
    List<StudyNote> notes,
  ) {
    return Row(
      children: [
        for (var index = 0; index < 2; index++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: index < notes.length
                  ? _summaryNoteTile(context, notes[index])
                  : _summaryNotePlaceholder(),
            ),
          ),
        Expanded(
          child: InkWell(
            onTap: () =>
                NoteFormModal.show(context, initialSubjectId: subjectId),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 112,
              decoration: BoxDecoration(
                color: CottagecoreColors.creamDarker.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: CottagecoreColors.border, style: BorderStyle.solid),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded,
                      size: 25, color: CottagecoreColors.warmBrown),
                  SizedBox(height: 5),
                  Text('Añadir apunte',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11, color: CottagecoreColors.warmBrown)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryNotePlaceholder() => Container(
        height: 112,
        decoration: BoxDecoration(
          color: CottagecoreColors.creamDarker.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CottagecoreColors.border),
        ),
      );

  Widget _summaryNoteTile(BuildContext context, StudyNote note) {
    final attachment = note.attachments.isEmpty ? null : note.attachments.first;
    return InkWell(
      onTap: attachment == null
          ? () => NoteFormModal.show(context, initialNote: note)
          : () => _openAttachment(attachment),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: CottagecoreColors.creamDarker.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CottagecoreColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              attachment == null
                  ? Icons.description_outlined
                  : _attachmentIcon(attachment.name),
              size: 30,
              color: CottagecoreColors.warmBrown,
            ),
            const SizedBox(height: 7),
            Text(note.topic,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            Text(
              attachment?.name ?? note.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10, color: CottagecoreColors.warmBrown),
            ),
          ],
        ),
      ),
    );
  }

  IconData _attachmentIcon(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    return switch (extension) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'doc' || 'docx' || 'txt' => Icons.description_outlined,
      'ppt' || 'pptx' => Icons.slideshow_outlined,
      'xls' || 'xlsx' || 'csv' => Icons.table_chart_outlined,
      _ => Icons.attach_file_rounded,
    };
  }

  Widget _summaryExamRows(List<Exam> exams) {
    if (exams.isEmpty) return _summaryEmpty('Sin próximos exámenes');
    return Column(
      children: exams
          .map((exam) => SizedBox(
                height: 50,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 44,
                      decoration: BoxDecoration(
                        color: CottagecoreColors.creamDarker,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_month_outlined,
                          color: CottagecoreColors.warmBrown),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('d MMM', 'es_ES').format(exam.date),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: CottagecoreColors.warmBrown)),
                          Text(exam.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _summaryEmpty(String message) => Align(
        alignment: Alignment.centerLeft,
        child: Text(message,
            style: const TextStyle(fontSize: 12, color: Color(0xFF7A6F62))),
      );

  Future<void> _editLastStudy(BuildContext context, Subject subject) async {
    final isDesktop = MediaQuery.of(context).size.width >= 700;
    final note = isDesktop
        ? await showDialog<String>(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 580,
                  maxHeight: 600,
                ),
                child: _LastStudyForm(initialNote: subject.lastStudyNote ?? ''),
              ),
            ),
          )
        : await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) =>
                _LastStudyForm(initialNote: subject.lastStudyNote ?? ''),
          );
    if (note == null) return;
    await AgendaRepository.instance.updateSubject(
      subject.copyWith(lastStudyNote: note, lastStudyAt: DateTime.now()),
    );
  }

  Widget _buildDeliverablesTab(
    BuildContext context,
    Subject subject,
    List<Deliverable> deliverables,
  ) {
    final sorted = List<Deliverable>.from(deliverables)
      ..sort((a, b) => a.date.compareTo(b.date));
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                  child: Text('Entregas y eventos',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: CottagecoreColors.forest))),
              FilledButton.icon(
                onPressed: () => _showDeliverableDialog(context, subject),
                style: FilledButton.styleFrom(
                  backgroundColor: CottagecoreColors.forest,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nueva entrega'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: sorted.isEmpty
                ? const EmptyBotanicalState(
                    message: 'Sin entregas registradas',
                    subMessage:
                        'Añade fechas de trabajos, presentaciones u otros eventos.',
                    emoji: '📅')
                : ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = sorted[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                              item.isSubmitted
                                  ? Icons.event_available_rounded
                                  : Icons.event_outlined,
                              color: item.isSubmitted
                                  ? CottagecoreColors.calmGreen
                                  : subject.color),
                          title: Text(item.title,
                              style: TextStyle(
                                  decoration: item.isSubmitted
                                      ? TextDecoration.lineThrough
                                      : null)),
                          subtitle: Text(
                              '${DateFormat('EEEE d MMM yyyy', 'es_ES').format(item.date)}${item.description == null ? '' : ' · ${item.description}'}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'toggle') {
                                AgendaRepository.instance.updateDeliverable(item
                                    .copyWith(isSubmitted: !item.isSubmitted));
                              } else if (value == 'edit') {
                                _showDeliverableDialog(context, subject,
                                    initial: item);
                              } else {
                                AgendaRepository.instance
                                    .deleteDeliverable(item.id);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                  value: 'toggle',
                                  child: Text(item.isSubmitted
                                      ? 'Marcar pendiente'
                                      : 'Marcar entregada')),
                              const PopupMenuItem(
                                  value: 'edit', child: Text('Editar')),
                              const PopupMenuItem(
                                  value: 'delete', child: Text('Eliminar')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeliverableDialog(
    BuildContext context,
    Subject subject, {
    Deliverable? initial,
  }) async {
    var title = initial?.title ?? '';
    var notes = initial?.description ?? '';
    final subjects = AgendaRepository.instance.subjects;
    var selectedSubjectId = initial?.subjectId ?? subject.id;
    var date = initial?.date ?? DateTime.now().add(const Duration(days: 7));
    final formKey = GlobalKey<FormState>();
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    Widget buildForm(BuildContext formContext) => StatefulBuilder(
          builder: (formContext, setFormState) {
            final bottomInset = MediaQuery.of(formContext).viewInsets.bottom;
            return Container(
              decoration: const BoxDecoration(
                color: CottagecoreColors.creamCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: CottagecoreColors.border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            initial == null
                                ? '📅 Nueva entrega'
                                : '✏️ Editar entrega',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: CottagecoreColors.forest,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Cerrar',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(formContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Nombre de la entrega',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CottagecoreColors.warmBrown,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: title,
                        autofocus: initial == null,
                        onChanged: (value) => title = value,
                        decoration: const InputDecoration(
                          hintText: 'Ej. Proyecto final',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Escribe el nombre de la entrega'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Asignatura',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CottagecoreColors.warmBrown,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedSubjectId.isNotEmpty
                            ? selectedSubjectId
                            : null,
                        decoration: const InputDecoration(),
                        items: subjects
                            .map((item) => DropdownMenuItem(
                                  value: item.id,
                                  child: Row(
                                    children: [
                                      Text(item.emoji,
                                          style: const TextStyle(fontSize: 16)),
                                      const SizedBox(width: 8),
                                      Text(item.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setFormState(() => selectedSubjectId = value);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Fecha',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CottagecoreColors.warmBrown,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: formContext,
                            initialDate: date,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 730)),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: CottagecoreColors.sage,
                                  onPrimary: Colors.white,
                                  surface: CottagecoreColors.creamCard,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setFormState(() => date = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: CottagecoreColors.creamDarker,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: CottagecoreColors.border, width: 0.8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded,
                                  color: CottagecoreColors.sage),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  DateFormat('EEEE, d MMMM yyyy', 'es_ES')
                                      .format(date),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              const Text('Cambiar',
                                  style: TextStyle(
                                      color: CottagecoreColors.forest,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        initialValue: notes,
                        minLines: 2,
                        maxLines: 3,
                        onChanged: (value) => notes = value,
                        decoration: const InputDecoration(
                          labelText: 'Notas adicionales',
                          hintText: 'Instrucciones, formato o detalles...',
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(formContext, (
                            name: title.trim(),
                            subjectId: selectedSubjectId,
                            date: date,
                            notes: notes.trim(),
                          ));
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: CottagecoreColors.forest,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(
                          initial == null ? 'Crear entrega' : 'Guardar cambios',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );

    final result = isDesktop
        ? await showDialog<
            ({String name, String subjectId, DateTime date, String notes})?>(
            context: context,
            builder: (dialogContext) => Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 580, maxHeight: 800),
                child: buildForm(dialogContext),
              ),
            ),
          )
        : await showModalBottomSheet<
            ({String name, String subjectId, DateTime date, String notes})?>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: buildForm,
          );
    if (result == null) return;
    final item = Deliverable(
      id: initial?.id ?? 'delivery_${DateTime.now().microsecondsSinceEpoch}',
      subjectId: result.subjectId,
      title: result.name,
      description: result.notes.isEmpty ? null : result.notes,
      date: result.date,
      isSubmitted: initial?.isSubmitted ?? false,
    );
    if (initial == null) {
      await AgendaRepository.instance.addDeliverable(item);
    } else {
      await AgendaRepository.instance.updateDeliverable(item);
    }
  }

  Widget _buildProgressTab(
    BuildContext context,
    Subject subject,
    List<SubjectAbsence> absences,
    List<SubjectGrade> grades,
  ) {
    final sortedAbsences = List<SubjectAbsence>.from(absences)
      ..sort((a, b) => b.date.compareTo(a.date));
    final sortedGrades = List<SubjectGrade>.from(grades)
      ..sort((a, b) => b.date.compareTo(a.date));
    final average = grades.isEmpty
        ? null
        : grades
                .map((grade) => grade.score / grade.maxScore * 10)
                .reduce((a, b) => a + b) /
            grades.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Progreso',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: CottagecoreColors.forest)),
            _headerBadge(
                '${absences.length} ausencias',
                CottagecoreColors.terracotta,
                CottagecoreColors.warningOrangeBg),
            _headerBadge('${grades.length} calificaciones',
                CottagecoreColors.forest, CottagecoreColors.creamDarker),
            if (average != null)
              _headerBadge(
                  'Media ${average.toStringAsFixed(1)} / 10',
                  CottagecoreColors.forest,
                  subject.color.withValues(alpha: 0.2)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
                child: Text('Asistencia',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
            OutlinedButton.icon(
                onPressed: () => _showAbsenceDialog(context, subject),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Registrar ausencia')),
          ],
        ),
        if (sortedAbsences.isEmpty)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Todavía no hay ausencias registradas.',
                  style: TextStyle(color: Color(0xFF7A6F62))))
        else
          ...sortedAbsences.map((absence) => Card(
                child: ListTile(
                  leading: const Icon(Icons.event_busy_outlined,
                      color: CottagecoreColors.terracotta),
                  title: Text(DateFormat('EEEE d MMM yyyy', 'es_ES')
                      .format(absence.date)),
                  subtitle: absence.note == null ? null : Text(absence.note!),
                  trailing: SizedBox(
                    width: 154,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: DropdownButton<AbsenceStatus>(
                            isExpanded: true,
                            value: absence.status,
                            underline: const SizedBox.shrink(),
                            items: AbsenceStatus.values
                                .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(_absenceLabel(status),
                                        overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (status) {
                              if (status != null) {
                                AgendaRepository.instance.updateAbsence(
                                    absence.copyWith(status: status));
                              }
                            },
                          ),
                        ),
                        IconButton(
                            tooltip: 'Eliminar ausencia',
                            onPressed: () => AgendaRepository.instance
                                .deleteAbsence(absence.id),
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 19)),
                      ],
                    ),
                  ),
                ),
              )),
        const Divider(height: 28),
        Row(
          children: [
            const Expanded(
                child: Text('Notas de actividades y exámenes',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
            OutlinedButton.icon(
                onPressed: () => _showGradeDialog(context, subject),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Añadir nota')),
          ],
        ),
        if (sortedGrades.isEmpty)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Registra aquí las calificaciones que recibas.',
                  style: TextStyle(color: Color(0xFF7A6F62))))
        else
          ...sortedGrades.map((grade) => Card(
                child: ListTile(
                  leading: Icon(
                      grade.type == GradeType.exam
                          ? Icons.school_outlined
                          : Icons.assignment_outlined,
                      color: subject.color),
                  title: Text(grade.title),
                  subtitle: Text(
                      '${grade.type == GradeType.exam ? 'Examen' : 'Actividad'} · ${DateFormat('d MMM yyyy', 'es_ES').format(grade.date)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${grade.score}/${grade.maxScore}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      IconButton(
                          tooltip: 'Eliminar nota',
                          onPressed: () =>
                              AgendaRepository.instance.deleteGrade(grade.id),
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 19)),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  String _absenceLabel(AbsenceStatus status) => switch (status) {
        AbsenceStatus.pending => 'Pendiente',
        AbsenceStatus.justified => 'Justificada',
        AbsenceStatus.unjustified => 'No justificada',
      };

  Future<void> _showAbsenceDialog(BuildContext context, Subject subject) async {
    final noteController = TextEditingController();
    var date = DateTime.now();
    var status = AbsenceStatus.pending;
    final result = await showDialog<(DateTime, AbsenceStatus, String)?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Registrar ausencia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (picked != null) setDialogState(() => date = picked);
                },
                icon: const Icon(Icons.calendar_today_rounded),
                label: Text(DateFormat('d MMM yyyy', 'es_ES').format(date)),
              ),
              DropdownButtonFormField<AbsenceStatus>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Justificación'),
                items: AbsenceStatus.values
                    .map((value) => DropdownMenuItem(
                        value: value, child: Text(_absenceLabel(value))))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => status = value);
                },
              ),
              TextField(
                  controller: noteController,
                  decoration:
                      const InputDecoration(labelText: 'Nota (opcional)')),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(
                    dialogContext, (date, status, noteController.text.trim())),
                child: const Text('Guardar')),
          ],
        ),
      ),
    );
    noteController.dispose();
    if (result == null) return;
    await AgendaRepository.instance.addAbsence(SubjectAbsence(
      id: 'absence_${DateTime.now().microsecondsSinceEpoch}',
      subjectId: subject.id,
      date: result.$1,
      status: result.$2,
      note: result.$3.isEmpty ? null : result.$3,
    ));
  }

  Future<void> _showGradeDialog(BuildContext context, Subject subject) async {
    final titleController = TextEditingController();
    final scoreController = TextEditingController();
    final maxScoreController = TextEditingController(text: '10');
    var type = GradeType.activity;
    var date = DateTime.now();
    final result =
        await showDialog<(String, double, double, GradeType, DateTime)?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Registrar calificación'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration:
                        const InputDecoration(labelText: 'Actividad o examen')),
                DropdownButtonFormField<GradeType>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(
                        value: GradeType.activity, child: Text('Actividad')),
                    DropdownMenuItem(
                        value: GradeType.exam, child: Text('Examen'))
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => type = value);
                  },
                ),
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                            controller: scoreController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration:
                                const InputDecoration(labelText: 'Nota'))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: TextField(
                            controller: maxScoreController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration:
                                const InputDecoration(labelText: 'Sobre'))),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) setDialogState(() => date = picked);
                  },
                  icon: const Icon(Icons.calendar_today_rounded),
                  label: Text(DateFormat('d MMM yyyy', 'es_ES').format(date)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final score =
                    double.tryParse(scoreController.text.replaceAll(',', '.'));
                final maxScore = double.tryParse(
                    maxScoreController.text.replaceAll(',', '.'));
                if (titleController.text.trim().isNotEmpty &&
                    score != null &&
                    maxScore != null &&
                    maxScore > 0 &&
                    score >= 0 &&
                    score <= maxScore) {
                  Navigator.pop(dialogContext, (
                    titleController.text.trim(),
                    score,
                    maxScore,
                    type,
                    date
                  ));
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    scoreController.dispose();
    maxScoreController.dispose();
    if (result == null) return;
    await AgendaRepository.instance.addGrade(SubjectGrade(
      id: 'grade_${DateTime.now().microsecondsSinceEpoch}',
      subjectId: subject.id,
      title: result.$1,
      score: result.$2,
      maxScore: result.$3,
      type: result.$4,
      date: result.$5,
    ));
  }

  Future<void> _openAttachment(NoteAttachment attachment) async {
    if (attachment.bytesBase64.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Este archivo no está disponible para abrirse directamente.')),
        );
      }
      return;
    }

    final tempDir = await Directory.systemTemp.createTemp('agenda_open_');
    final safeName =
        attachment.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final file = File('${tempDir.path}/$safeName');
    await file.writeAsBytes(base64Decode(attachment.bytesBase64));

    final result = await OpenFilex.open(file.path);
    if (mounted && result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir ${attachment.name}.')),
      );
    }
  }

  Future<void> _downloadAttachment(NoteAttachment attachment) async {
    await FilePicker.saveFile(
      fileName: attachment.name,
      bytes: Uint8List.fromList(base64Decode(attachment.bytesBase64)),
    );
  }

  // --- TAB 1: APUNTES ---

  Widget _buildNotesTab(
      BuildContext context, Subject subject, List<StudyNote> notes) {
    final filtered = notes.where((note) {
      final matchesSearch = _notesSearch.isEmpty ||
          note.title.toLowerCase().contains(_notesSearch.toLowerCase()) ||
          note.topic.toLowerCase().contains(_notesSearch.toLowerCase()) ||
          note.content.toLowerCase().contains(_notesSearch.toLowerCase()) ||
          note.tags
              .any((t) => t.toLowerCase().contains(_notesSearch.toLowerCase()));

      final matchesCat = _notesCategoryFilter == 'Todas' ||
          note.category == _notesCategoryFilter;

      return matchesSearch && matchesCat;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search & Filter Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar apuntes, temas o etiquetas...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _notesSearch = val),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () =>
                    NoteFormModal.show(context, initialSubjectId: subject.id),
                style: FilledButton.styleFrom(
                  backgroundColor: CottagecoreColors.forest,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nuevo apunte'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Todas', 'Resumen', 'Esquema', 'Apuntes', 'Código']
                  .map((cat) {
                final isSel = _notesCategoryFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSel,
                    selectedColor:
                        CottagecoreColors.sage.withValues(alpha: 0.25),
                    onSelected: (_) =>
                        setState(() => _notesCategoryFilter = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Notes List
          Expanded(
            child: filtered.isEmpty
                ? const EmptyBotanicalState(
                    message: 'Sin apuntes que coincidan',
                    subMessage:
                        'Crea tu primer apunte Notion-style con títulos, listas y código.',
                    emoji: '📖',
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final note = filtered[index];
                      final checkDone =
                          note.checklist.where((c) => c.isChecked).length;

                      return Card(
                        child: InkWell(
                          onTap: () =>
                              NoteFormModal.show(context, initialNote: note),
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: CottagecoreColors.sage
                                            .withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        note.category,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: CottagecoreColors.forest,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      note.topic,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF7A6F62)),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => AgendaRepository.instance
                                          .deleteNote(note.id),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  note.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: CottagecoreColors.forest,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  note.content,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13, color: Color(0xFF5A5044)),
                                ),
                                if (note.attachments.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  ...note.attachments.map((attachment) => Row(
                                        children: [
                                          const Icon(Icons.attach_file_rounded,
                                              size: 16,
                                              color:
                                                  CottagecoreColors.warmBrown),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              attachment.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Abrir ${attachment.name}',
                                            visualDensity:
                                                VisualDensity.compact,
                                            onPressed: () =>
                                                _openAttachment(attachment),
                                            icon: const Icon(
                                                Icons.open_in_new_rounded,
                                                size: 18),
                                          ),
                                          IconButton(
                                            tooltip:
                                                'Descargar ${attachment.name}',
                                            visualDensity:
                                                VisualDensity.compact,
                                            onPressed: () =>
                                                _downloadAttachment(attachment),
                                            icon: const Icon(
                                                Icons.download_rounded,
                                                size: 18),
                                          ),
                                        ],
                                      )),
                                ],
                                if (note.checklist.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.checklist_rounded,
                                          size: 16,
                                          color: CottagecoreColors.sage),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Checklist: $checkDone de ${note.checklist.length} completados',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  'Actualizado el ${DateFormat('d MMM yyyy', 'es_ES').format(note.updatedAt)}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.black38),
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
    );
  }

  // --- TAB 2: TAREAS ---

  Widget _buildTasksTab(
      BuildContext context, Subject subject, List<Task> tasks) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Tareas de ${subject.name}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CottagecoreColors.forest),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () =>
                    TaskFormModal.show(context, initialSubjectId: subject.id),
                style: FilledButton.styleFrom(
                  backgroundColor: CottagecoreColors.forest,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nueva tarea'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: tasks.isEmpty
                ? const EmptyBotanicalState(
                    message: 'No hay tareas asignadas',
                    subMessage: 'Crea una tarea rápida para esta asignatura.',
                    emoji: '🌱',
                  )
                : ListView.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskCard(
                        task: task,
                        onEdit: () =>
                            TaskFormModal.show(context, initialTask: task),
                        onDelete: () =>
                            AgendaRepository.instance.deleteTask(task.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: EXÁMENES ---

  Widget _buildExamsTab(
      BuildContext context, Subject subject, List<Exam> exams) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Exámenes de ${subject.name}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CottagecoreColors.forest),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () =>
                    ExamFormModal.show(context, initialSubjectId: subject.id),
                style: FilledButton.styleFrom(
                  backgroundColor: CottagecoreColors.forest,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Registrar examen'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: exams.isEmpty
                ? const EmptyBotanicalState(
                    message: 'Sin exámenes programados',
                    subMessage:
                        'Registra fechas de parciales o finales para preparar el temario.',
                    emoji: '🌾',
                  )
                : ListView.separated(
                    itemCount: exams.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final exam = exams[index];
                      final progress = exam.progressPercent;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      exam.name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: CottagecoreColors.forest,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: exam.stateColor
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      exam.stateLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: exam.stateColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(exam.date)} • ${exam.time} • ${exam.classroom}',
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF6B6053)),
                              ),
                              const SizedBox(height: 12),

                              // Progress bar
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Preparación del temario:',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  Text('$progress%',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: CottagecoreColors.forest)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: progress / 100,
                                minHeight: 9,
                                borderRadius: BorderRadius.circular(20),
                                backgroundColor: CottagecoreColors.creamDarker,
                                valueColor: const AlwaysStoppedAnimation(
                                    CottagecoreColors.sage),
                              ),
                              const SizedBox(height: 12),

                              // Topics checklist
                              const Text('Temario para estudiar:',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              ...List.generate(exam.topics.length, (topicIdx) {
                                final topic = exam.topics[topicIdx];
                                return InkWell(
                                  onTap: () {
                                    AgendaRepository.instance
                                        .toggleExamTopic(exam.id, topicIdx);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          topic.isCompleted
                                              ? Icons.check_box_rounded
                                              : Icons
                                                  .check_box_outline_blank_rounded,
                                          size: 20,
                                          color: topic.isCompleted
                                              ? CottagecoreColors.calmGreen
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            topic.title,
                                            style: TextStyle(
                                              fontSize: 13,
                                              decoration: topic.isCompleted
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: topic.isCompleted
                                                  ? Colors.grey
                                                  : null,
                                            ),
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
    );
  }

  // --- TAB 4: INFO ---

  Widget _buildInfoTab(BuildContext context, Subject subject) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _infoCard('Nombre de la asignatura', subject.name,
              Icons.bookmark_border_rounded),
          _infoCard('Profesor / Docente', subject.teacher ?? 'No especificado',
              Icons.person_outline_rounded),
          _infoCard(
              'Horario de clases',
              subject.schedules.isNotEmpty
                  ? subject.schedules
                      .map((item) =>
                          '${_weekdayLabel(item.weekday)} ${item.timeLabel} · ${item.durationLabel}')
                      .join(' | ')
                  : subject.schedule ?? 'Por definir',
              Icons.access_time_rounded),
          _infoCard('Emoji identificador', subject.emoji,
              Icons.emoji_emotions_outlined),
          if (subject.notes != null)
            _infoCard(
                'Notas de la materia', subject.notes!, Icons.notes_rounded),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _confirmDeleteSubject(context, subject),
            icon: const Icon(Icons.delete_outline_rounded,
                color: CottagecoreColors.urgentRed),
            label: const Text('Eliminar asignatura',
                style: TextStyle(color: CottagecoreColors.urgentRed)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: CottagecoreColors.urgentRed),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CottagecoreColors.creamCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CottagecoreColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: CottagecoreColors.forest),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF7A6F62))),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editSubjectDialog(BuildContext context, Subject subject) =>
      SubjectFormModal.show(context, initialSubject: subject);

  void _confirmDeleteSubject(BuildContext context, Subject subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar asignatura?'),
        content: Text(
            'Se eliminará "${subject.name}" junto con sus tareas, apuntes y exámenes asociados.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: CottagecoreColors.urgentRed),
            onPressed: () {
              AgendaRepository.instance.deleteSubject(subject.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Eliminar definitivamente'),
          ),
        ],
      ),
    );
  }
}

class _LastStudyForm extends StatefulWidget {
  const _LastStudyForm({required this.initialNote});

  final String initialNote;

  @override
  State<_LastStudyForm> createState() => _LastStudyFormState();
}

class _LastStudyFormState extends State<_LastStudyForm> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: CottagecoreColors.creamCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: CottagecoreColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                '🌱 Dónde me quedé',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: CottagecoreColors.forest,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '¿Qué avanzaste y qué toca retomar?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CottagecoreColors.warmBrown,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Escribe el punto donde continuar...',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, _controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: CottagecoreColors.forest,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.check_rounded),
            label: const Text(
              'Guardar avance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
