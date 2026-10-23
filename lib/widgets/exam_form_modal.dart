import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';
import 'studia_form_widgets.dart';

class ExamFormModal extends StatefulWidget {
  const ExamFormModal({
    this.initialExam,
    this.initialSubjectId,
    super.key,
  });

  final Exam? initialExam;
  final String? initialSubjectId;

  static Future<void> show(
    BuildContext context, {
    Exam? initialExam,
    String? initialSubjectId,
  }) async {
    await StudiaModalHelper.show(
      context: context,
      maxWidth: 600,
      child: ExamFormModal(
        initialExam: initialExam,
        initialSubjectId: initialSubjectId,
      ),
    );
  }

  @override
  State<ExamFormModal> createState() => _ExamFormModalState();
}

class _ExamFormModalState extends State<ExamFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _classroomController;
  late final TextEditingController _timeController;
  late final TextEditingController _notesController;
  late final TextEditingController _newTopicController;

  late String _subjectId;
  late DateTime _date;
  late ExamState _state;
  late List<ExamTopic> _topics;
  late List<String> _linkedNoteIds;
  bool _isSaving = false;

  bool get isEditing => widget.initialExam != null;

  @override
  void initState() {
    super.initState();
    final repo = AgendaRepository.instance;
    final defaultSubId = repo.subjects.isNotEmpty ? repo.subjects.first.id : '';

    final e = widget.initialExam;
    _nameController = TextEditingController(text: e?.name ?? '');
    _classroomController =
        TextEditingController(text: e?.classroom ?? 'Aula Magna');
    _timeController = TextEditingController(text: e?.time ?? '10:00');
    _notesController = TextEditingController(text: e?.notes ?? '');
    _newTopicController = TextEditingController();

    _subjectId = e?.subjectId ?? widget.initialSubjectId ?? defaultSubId;
    _date = e?.date ?? DateTime.now().add(const Duration(days: 7));
    _state = e?.state ?? ExamState.preparing;
    _topics = e != null
        ? List.from(e.topics)
        : [
            const ExamTopic(title: 'Tema 1: Introducción', isCompleted: false),
            const ExamTopic(title: 'Tema 2: Desarrollo', isCompleted: false),
          ];
    _linkedNoteIds = e != null ? List.from(e.linkedNoteIds) : [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classroomController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    _newTopicController.dispose();
    super.dispose();
  }

  void _addTopic() {
    final text = _newTopicController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _topics.add(ExamTopic(title: text, isCompleted: false));
        _newTopicController.clear();
      });
    }
  }

  void _removeTopic(int index) {
    setState(() {
      _topics.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    final repo = AgendaRepository.instance;
    final exam = Exam(
      id: widget.initialExam?.id ??
          'exam_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      subjectId: _subjectId,
      date: _date,
      time: _timeController.text.trim(),
      classroom: _classroomController.text.trim(),
      topics: _topics,
      state: _state,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      linkedNoteIds: _linkedNoteIds,
    );

    setState(() => _isSaving = true);
    try {
      final synced =
          isEditing ? await repo.updateExam(exam) : await repo.addExam(exam);
      if (!mounted || !synced) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el examen: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _delete() {
    if (widget.initialExam == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar examen?'),
        content:
            const Text('Esta acción eliminará el examen de tu calendario.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: CottagecoreColors.urgentRed),
            onPressed: () {
              Navigator.pop(ctx);
              AgendaRepository.instance.deleteExam(widget.initialExam!.id);
              Navigator.of(context).pop();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = AgendaRepository.instance;
    final notesForSubject =
        repo.notes.where((note) => note.subjectId == _subjectId).toList();

    return StudiaModalContainer(
      title: isEditing ? '📝 Editar examen' : '📖 Registrar examen',
      subtitle: isEditing
          ? 'Actualiza fecha, horario o temario a estudiar'
          : 'Planifica tu examen y los temas que debes repasar',
      actions: Row(
        children: [
          if (isEditing)
            IconButton.outlined(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: CottagecoreColors.urgentRed),
              tooltip: 'Eliminar examen',
              onPressed: _delete,
              style: IconButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2C4B8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          if (isEditing) const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: CottagecoreColors.warmBrown,
                side: const BorderSide(color: CottagecoreColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StudiaPrimaryButton(
              label: _isSaving
                  ? 'Guardando...'
                  : isEditing
                      ? 'Guardar examen'
                      : 'Registrar examen',
              icon: isEditing ? Icons.check_rounded : Icons.add_rounded,
              onPressed: _isSaving ? null : _submit,
            ),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nombre del examen
            StudiaFormField(
              label: 'Nombre del examen',
              isRequired: true,
              child: TextFormField(
                controller: _nameController,
                autofocus: !isEditing,
                decoration: const InputDecoration(
                  hintText: 'Ej. Parcial de Arquitectura del Software',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Indica el nombre' : null,
              ),
            ),

            // Asignatura
            StudiaFormField(
              label: 'Asignatura',
              isRequired: true,
              child: DropdownButtonFormField<String>(
                initialValue: _subjectId.isNotEmpty ? _subjectId : null,
                decoration: const InputDecoration(),
                items: repo.subjects.map((sub) {
                  return DropdownMenuItem(
                    value: sub.id,
                    child: Text('${sub.emoji} ${sub.name}'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _subjectId = val);
                },
                validator: (val) => val == null || val.isEmpty
                    ? 'Selecciona una materia'
                    : null,
              ),
            ),

            // Apuntes relacionados opcionales
            if (notesForSubject.isNotEmpty) ...[
              StudiaFormField(
                label: 'Apuntes relacionados (opcional)',
                child: DropdownButtonFormField<String?>(
                  initialValue: null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Selecciona un apunte para vincular',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Sin añadir nuevo apunte'),
                    ),
                    ...notesForSubject.map((note) {
                      return DropdownMenuItem<String?>(
                        value: note.id,
                        child: Text('📄 ${note.title}'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      if (!_linkedNoteIds.contains(value)) {
                        _linkedNoteIds.add(value);
                      }
                    });
                  },
                ),
              ),
              if (_linkedNoteIds.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: notesForSubject
                        .where((note) => _linkedNoteIds.contains(note.id))
                        .map((note) {
                      return Chip(
                        label: Text(note.title),
                        avatar:
                            const Icon(Icons.description_outlined, size: 16),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        onDeleted: () {
                          setState(() {
                            _linkedNoteIds.remove(note.id);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],

            // Fecha y Hora en 2 columnas
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: StudiaFormField(
                    label: 'Fecha',
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 30)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: CottagecoreColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 18, color: CottagecoreColors.forest),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormat('d MMM yyyy', 'es_ES').format(_date),
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
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StudiaFormField(
                    label: 'Hora',
                    child: TextFormField(
                      controller: _timeController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.access_time_rounded, size: 18),
                        hintText: '10:00',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Indica la hora'
                          : null,
                    ),
                  ),
                ),
              ],
            ),

            // Aula
            StudiaFormField(
              label: 'Aula o sala',
              child: TextFormField(
                controller: _classroomController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.room_outlined, size: 18),
                  hintText: 'Ej. Aula 2.3 / Salón de Actos',
                ),
              ),
            ),

            // Estado de preparación
            StudiaFormField(
              label: 'Estado de preparación',
              child: SegmentedButton<ExamState>(
                segments: const [
                  ButtonSegment(
                    value: ExamState.preparing,
                    label: Text('Estudiando'),
                    icon: Icon(Icons.menu_book_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: ExamState.ready,
                    label: Text('Listo'),
                    icon: Icon(Icons.verified_outlined, size: 16),
                  ),
                ],
                selected: {_state},
                onSelectionChanged: (set) => setState(() => _state = set.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return CottagecoreColors.terracotta
                          .withValues(alpha: 0.2);
                    }
                    return Colors.white;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return CottagecoreColors.terracotta;
                    }
                    return CottagecoreColors.warmBrown;
                  }),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),

            // Temas a estudiar
            StudiaSectionHeader(
              title: '📚 Temario a estudiar (${_topics.length})',
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newTopicController,
                    decoration: InputDecoration(
                      hintText: 'Añadir tema (ej. Tema 3: Normalización)...',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      isDense: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: CottagecoreColors.border),
                      ),
                    ),
                    onSubmitted: (_) => _addTopic(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: CottagecoreColors.terracotta,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Añadir tema',
                  onPressed: _addTopic,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._topics.asMap().entries.map((entry) {
              final index = entry.key;
              final topic = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CottagecoreColors.border),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: topic.isCompleted,
                      activeColor: CottagecoreColors.forest,
                      onChanged: (val) {
                        setState(() {
                          _topics[index] =
                              topic.copyWith(isCompleted: val ?? false);
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        topic.title,
                        style: TextStyle(
                          fontSize: 13,
                          decoration: topic.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: topic.isCompleted
                              ? const Color(0xFF8C8276)
                              : const Color(0xFF382F26),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      tooltip: 'Eliminar tema',
                      color: CottagecoreColors.urgentRed,
                      onPressed: () => _removeTopic(index),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),

            // Notas
            StudiaFormField(
              label: 'Notas / Recordatorios (opcional)',
              bottomSpacing: 8,
              child: TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Material permitido, tipo de examen, etc.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
