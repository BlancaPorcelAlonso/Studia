import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';

class TaskFormModal extends StatefulWidget {
  const TaskFormModal({
    this.initialTask,
    this.initialSubjectId,
    this.initialStatus,
    this.initialDueDate,
    super.key,
  });

  final Task? initialTask;
  final String? initialSubjectId;
  final TaskStatus? initialStatus;
  final DateTime? initialDueDate;

  static Future<void> show(
    BuildContext context, {
    Task? initialTask,
    String? initialSubjectId,
    TaskStatus? initialStatus,
    DateTime? initialDueDate,
  }) async {
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    if (isDesktop) {
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 800),
            child: TaskFormModal(
              initialTask: initialTask,
              initialSubjectId: initialSubjectId,
              initialStatus: initialStatus,
              initialDueDate: initialDueDate,
            ),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => TaskFormModal(
          initialTask: initialTask,
          initialSubjectId: initialSubjectId,
          initialStatus: initialStatus,
          initialDueDate: initialDueDate,
        ),
      );
    }
  }

  @override
  State<TaskFormModal> createState() => _TaskFormModalState();
}

class _TaskFormModalState extends State<TaskFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  late final TextEditingController _linksController;
  late final TextEditingController _filesController;

  late String _subjectId;
  late TaskStatus _status;
  late TaskPriority _priority;
  late TaskType _type;
  late DateTime _dueDate;
  DateTime? _startDate;

  bool _showExtraDetails = false;

  bool get isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final repo = AgendaRepository.instance;
    final defaultSubId = repo.subjects.isNotEmpty ? repo.subjects.first.id : '';

    final t = widget.initialTask;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descriptionController = TextEditingController(text: t?.description ?? '');
    _notesController = TextEditingController(text: t?.notes ?? '');
    _linksController = TextEditingController(text: t?.links.join(', ') ?? '');
    _filesController = TextEditingController(text: t?.files.join(', ') ?? '');

    _subjectId = t?.subjectId ?? widget.initialSubjectId ?? defaultSubId;
    _status = t?.status ?? widget.initialStatus ?? TaskStatus.todo;
    _priority = t?.priority ?? TaskPriority.medium;
    _type = t?.type ?? TaskType.assignment;
    _dueDate = t?.dueDate ?? widget.initialDueDate ?? DateTime.now().add(const Duration(days: 2));
    _startDate = t?.startDate;

    if (t != null &&
        ((t.description?.isNotEmpty ?? false) ||
            (t.notes?.isNotEmpty ?? false) ||
            t.links.isNotEmpty ||
            t.files.isNotEmpty ||
            t.startDate != null)) {
      _showExtraDetails = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _linksController.dispose();
    _filesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final repo = AgendaRepository.instance;
    final linksList = _linksController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final filesList = _filesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final task = Task(
      id: widget.initialTask?.id ?? 'task_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      subjectId: _subjectId,
      status: _status,
      priority: _priority,
      type: _type,
      dueDate: _dueDate,
      startDate: _startDate,
      completedAt: _status == TaskStatus.completed
          ? (widget.initialTask?.completedAt ?? DateTime.now())
          : null,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      links: linksList,
      files: filesList,
    );

    if (isEditing) {
      repo.updateTask(task);
    } else {
      repo.addTask(task);
    }

    Navigator.of(context).pop();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: CottagecoreColors.sage,
              onPrimary: Colors.white,
              surface: CottagecoreColors.creamCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
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
              // Header Drag Handle & Title
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
                    isEditing ? '✏️ Editar tarea' : '🌱 Nueva tarea',
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

              // Title input
              const Text(
                '¿Qué tienes que hacer?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CottagecoreColors.warmBrown,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                autofocus: !isEditing,
                decoration: const InputDecoration(
                  hintText: 'Ej. Actividad 2 de Dart',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Por favor escribe el título de la tarea';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Subject Dropdown
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
                initialValue: _subjectId.isNotEmpty ? _subjectId : null,
                decoration: const InputDecoration(),
                items: repo.subjects.map((sub) {
                  return DropdownMenuItem<String>(
                    value: sub.id,
                    child: Row(
                      children: [
                        Text(sub.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _subjectId = val);
                },
              ),
              const SizedBox(height: 14),

              // Due Date Picker
              const Text(
                'Fecha límite',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CottagecoreColors.warmBrown,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDueDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: CottagecoreColors.creamDarker,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: CottagecoreColors.border, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: CottagecoreColors.sage),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(_dueDate),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const Text('Cambiar', style: TextStyle(color: CottagecoreColors.forest, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Priority Buttons
              const Text(
                'Prioridad',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CottagecoreColors.warmBrown,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _priorityOption(TaskPriority.low, '🌿 Baja'),
                  const SizedBox(width: 8),
                  _priorityOption(TaskPriority.medium, '🟡 Media'),
                  const SizedBox(width: 8),
                  _priorityOption(TaskPriority.high, '🟠 Alta'),
                  const SizedBox(width: 8),
                  _priorityOption(TaskPriority.urgent, '🔴 Urgente'),
                ],
              ),
              const SizedBox(height: 16),

              // Status Buttons
              const Text(
                'Estado inicial',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CottagecoreColors.warmBrown,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statusOption(TaskStatus.todo, '📥 Por hacer'),
                  const SizedBox(width: 8),
                  _statusOption(TaskStatus.inProgress, '🌱 En proceso'),
                  if (isEditing) ...[
                    const SizedBox(width: 8),
                    _statusOption(TaskStatus.completed, '✓ Completado'),
                  ],
                ],
              ),
              const SizedBox(height: 18),

              // "+ Añadir detalles" Toggle
              InkWell(
                onTap: () => setState(() => _showExtraDetails = !_showExtraDetails),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        _showExtraDetails
                            ? Icons.remove_circle_outline_rounded
                            : Icons.add_circle_outline_rounded,
                        color: CottagecoreColors.forest,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showExtraDetails ? 'Ocultar detalles' : '+ Añadir detalles',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: CottagecoreColors.forest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_showExtraDetails) ...[
                const SizedBox(height: 10),
                // Type selector
                DropdownButtonFormField<TaskType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Tipo de tarea'),
                  items: TaskType.values.map((type) {
                    final label = switch (type) {
                      TaskType.assignment => 'Entrega',
                      TaskType.exam => 'Examen',
                      TaskType.classType => 'Clase',
                      TaskType.project => 'Proyecto',
                      TaskType.event => 'Evento',
                    };
                    return DropdownMenuItem(value: type, child: Text(label));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _type = val);
                  },
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción / Instrucciones',
                    hintText: 'Ej. Capítulos 3 y 4 del libro...',
                  ),
                ),
                const SizedBox(height: 12),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas adicionales',
                    hintText: 'Consejos del profesor, detalles clave...',
                  ),
                ),
                const SizedBox(height: 12),

                // Links
                TextFormField(
                  controller: _linksController,
                  decoration: const InputDecoration(
                    labelText: 'Enlaces (separados por coma)',
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: 12),

                // Files
                TextFormField(
                  controller: _filesController,
                  decoration: const InputDecoration(
                    labelText: 'Archivos o nombres de entrega',
                    hintText: 'actividad_2.pdf, modelo.dart',
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Submit Button
              FilledButton.icon(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: CottagecoreColors.forest,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  isEditing ? 'Actualizar tarea' : 'Crear tarea',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityOption(TaskPriority p, String label) {
    final isSelected = _priority == p;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _priority = p),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? CottagecoreColors.sage.withValues(alpha: 0.22)
                : CottagecoreColors.creamDarker,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? CottagecoreColors.sage : CottagecoreColors.border,
              width: isSelected ? 1.8 : 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? CottagecoreColors.forest : const Color(0xFF6B6053),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusOption(TaskStatus s, String label) {
    final isSelected = _status == s;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _status = s),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? CottagecoreColors.sage.withValues(alpha: 0.22)
                : CottagecoreColors.creamDarker,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? CottagecoreColors.sage : CottagecoreColors.border,
              width: isSelected ? 1.8 : 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? CottagecoreColors.forest : const Color(0xFF6B6053),
            ),
          ),
        ),
      ),
    );
  }
}
