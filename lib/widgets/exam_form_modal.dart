import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';

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
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    if (isDesktop) {
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 800),
            child: ExamFormModal(
              initialExam: initialExam,
              initialSubjectId: initialSubjectId,
            ),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ExamFormModal(
          initialExam: initialExam,
          initialSubjectId: initialSubjectId,
        ),
      );
    }
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

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
    );

    if (isEditing) {
      repo.updateExam(exam);
    } else {
      repo.addExam(exam);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final repo = AgendaRepository.instance;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: CottagecoreColors.creamCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      child: Form(
        key: _formKey,
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
                    isEditing
                        ? '📝 Editar examen'
                        : '📖 Registrar nuevo examen',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: CottagecoreColors.forest,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Name
              const _FieldLabel('Nombre del examen'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Indica el nombre' : null,
              ),
              const SizedBox(height: 12),

              // Subject
              const _FieldLabel('Asignatura'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
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
              ),
              const SizedBox(height: 12),

              // Date & Time
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _FieldLabel('Fecha'),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _date,
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 30)),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setState(() => _date = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: CottagecoreColors.creamDarker,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: CottagecoreColors.border, width: 0.8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 18, color: CottagecoreColors.sage),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat('dd MMM yyyy', 'es_ES')
                                        .format(_date),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _FieldLabel('Hora'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _timeController,
                          decoration: const InputDecoration(hintText: '10:30'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const _FieldLabel('Aula / Ubicación'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _classroomController,
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 12),

              // State
              const _FieldLabel('Estado de preparación'),
              const SizedBox(height: 6),
              DropdownButtonFormField<ExamState>(
                initialValue: _state,
                decoration: const InputDecoration(),
                items: ExamState.values.map((s) {
                  final label = switch (s) {
                    ExamState.notStarted => '🔴 No empezado',
                    ExamState.started => '🟠 Empezado',
                    ExamState.preparing => '🟡 Preparando',
                    ExamState.revising => '🔵 Repasando',
                    ExamState.ready => '🟢 Preparado',
                  };
                  return DropdownMenuItem(value: s, child: Text(label));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _state = v);
                },
              ),
              const SizedBox(height: 16),

              // Temario Section
              const _FieldLabel('Temario del examen'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newTopicController,
                      decoration: const InputDecoration(
                        hintText: 'Añadir tema (ej: Tema 3: Consultas)',
                      ),
                      onSubmitted: (_) => _addTopic(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: CottagecoreColors.sage,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    onPressed: _addTopic,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Topics list
              if (_topics.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'No hay temas añadidos aún.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                )
              else
                ...List.generate(_topics.length, (index) {
                  final topic = _topics[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: CottagecoreColors.creamDarker,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: topic.isCompleted,
                          activeColor: CottagecoreColors.calmGreen,
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
                              decoration: topic.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _removeTopic(index),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 12),

              // Notes
              const _FieldLabel('Notas / Recordatorios'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Material permitido, tipo de examen, etc.',
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              FilledButton.icon(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: CottagecoreColors.forest,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  isEditing ? 'Actualizar examen' : 'Guardar examen',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CottagecoreColors.warmBrown,
        ),
      );
}
