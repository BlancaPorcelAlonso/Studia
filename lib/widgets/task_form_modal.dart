import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
  final TextEditingController _newCheckItemController = TextEditingController();

  late String _subjectId;
  late TaskStatus _status;
  late TaskPriority _priority;
  late TaskType _type;
  late String? _linkedExamId;
  late String? _linkedDeliverableId;
  late DateTime _dueDate;
  DateTime? _startDate;
  late List<TaskCheckItem> _checklist;
  final List<PlatformFile> _pendingFiles = [];

  bool _showExtraDetails = false;
  bool _isSaving = false;

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
    _linkedExamId = t?.linkedExamId;
    _linkedDeliverableId = t?.linkedDeliverableId;
    _dueDate = t?.dueDate ??
        widget.initialDueDate ??
        DateTime.now().add(const Duration(days: 2));
    _startDate = t?.startDate;
    _checklist = t != null ? List.from(t.checklist) : [];

    if (t != null &&
        ((t.description?.isNotEmpty ?? false) ||
            (t.notes?.isNotEmpty ?? false) ||
            t.links.isNotEmpty ||
            t.files.isNotEmpty ||
            t.startDate != null ||
            t.linkedExamId != null ||
            t.linkedDeliverableId != null)) {
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
    _newCheckItemController.dispose();
    super.dispose();
  }

  void _addCheckItem() {
    final text = _newCheckItemController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _checklist.add(
        TaskCheckItem(
          id: 'check_${DateTime.now().millisecondsSinceEpoch}_${_checklist.length}',
          text: text,
          isChecked: false,
        ),
      );
      _newCheckItemController.clear();
    });
  }

  void _editCheckItem(int index) {
    final item = _checklist[index];
    final controller = TextEditingController(text: item.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar subtarea'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Texto de la subtarea'),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              setState(() {
                _checklist[index] = item.copyWith(text: val.trim());
              });
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: CottagecoreColors.forest),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _checklist[index] =
                      item.copyWith(text: controller.text.trim());
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    if (!AgendaRepository.instance.isCloudConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicia sesión para adjuntar archivos a una tarea.'),
        ),
      );
      return;
    }
    final files = await FilePicker.pickFiles();
    if (!mounted || files.isEmpty) return;
    setState(() => _pendingFiles.addAll(files));
  }

  String? _fileMimeType(String? extension) => switch (extension?.toLowerCase()) {
        'pdf' => 'application/pdf',
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'txt' => 'text/plain',
        'csv' => 'text/csv',
        _ => null,
      };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = AgendaRepository.instance;
    setState(() => _isSaving = true);
    try {
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
      final taskId = widget.initialTask?.id ??
          'task_${DateTime.now().millisecondsSinceEpoch}';

      if (_pendingFiles.isNotEmpty) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          throw StateError('Inicia sesión para adjuntar archivos.');
        }
        for (var index = 0; index < _pendingFiles.length; index++) {
          final file = _pendingFiles[index];
          final bytes = await file.readAsBytes();
          final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
          final path = '${user.id}/tasks/$taskId/$index-$safeName';
          await Supabase.instance.client.storage
              .from('agenda-attachments')
              .uploadBinary(
                path,
                bytes,
                fileOptions: FileOptions(
                  upsert: true,
                  contentType: _fileMimeType(file.extension),
                ),
              );
          filesList.add(path);
        }
      }

      final task = Task(
        id: taskId,
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
        checklist: _checklist,
        linkedExamId: _linkedExamId,
        linkedDeliverableId: _linkedDeliverableId,
      );

      if (isEditing) {
        await repo.updateTask(task);
      } else {
        await repo.addTask(task);
      }
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la tarea: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
    final completedCount = _checklist.where((c) => c.isChecked).length;
    final totalCount = _checklist.length;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

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
                        Text(sub.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _subjectId = val);
                },
              ),
              const SizedBox(height: 14),

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: CottagecoreColors.creamDarker,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: CottagecoreColors.border, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          color: CottagecoreColors.sage),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy', 'es_ES')
                            .format(_dueDate),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const Text('Cambiar',
                          style: TextStyle(
                              color: CottagecoreColors.forest, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Prioridad
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

              // Estado
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

              // SECCIÓN SUBTAREAS / CHECKLIST
              Row(
                children: [
                  Text(
                    '📋 Subtareas (${_checklist.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CottagecoreColors.warmBrown,
                    ),
                  ),
                  const Spacer(),
                  if (_checklist.isNotEmpty)
                    Text(
                      '$completedCount de $totalCount · ${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CottagecoreColors.forest,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Barra de progreso de subtareas si hay elementos
              if (_checklist.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: CottagecoreColors.creamDarker,
                    valueColor:
                        const AlwaysStoppedAnimation(CottagecoreColors.sage),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Lista reordenable de subtareas
              if (_checklist.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: CottagecoreColors.creamDarker,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.checklist_rtl_rounded,
                          size: 20, color: CottagecoreColors.warmBrown),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sin subtareas todavía. Divide esta tarea en pasos más pequeños.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7A6F62),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _checklist.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _checklist.removeAt(oldIndex);
                      _checklist.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = _checklist[index];
                    return Container(
                      key: ValueKey(item.id),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: item.isChecked
                              ? CottagecoreColors.sage.withValues(alpha: 0.3)
                              : CottagecoreColors.border,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        leading: Checkbox(
                          value: item.isChecked,
                          activeColor: CottagecoreColors.forest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _checklist[index] =
                                  item.copyWith(isChecked: val ?? false);
                            });
                          },
                        ),
                        title: Text(
                          item.text,
                          style: TextStyle(
                            fontSize: 13,
                            decoration: item.isChecked
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.isChecked
                                ? const Color(0xFF8C8276)
                                : const Color(0xFF382F26),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              tooltip: 'Editar subtarea',
                              color: CottagecoreColors.warmBrown,
                              onPressed: () => _editCheckItem(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 16),
                              tooltip: 'Eliminar subtarea',
                              color: CottagecoreColors.urgentRed,
                              onPressed: () {
                                setState(() => _checklist.removeAt(index));
                              },
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle_rounded,
                                  size: 18, color: Color(0xFFB5ABA0)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // Input para añadir subtarea
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newCheckItemController,
                        decoration: InputDecoration(
                          hintText: 'Añadir nueva subtarea...',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          isDense: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: CottagecoreColors.border),
                          ),
                        ),
                        onSubmitted: (_) => _addCheckItem(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: CottagecoreColors.sage,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'Añadir subtarea',
                      onPressed: _addCheckItem,
                    ),
                  ],
                ),
              ),

              // Más detalles
              InkWell(
                onTap: () =>
                    setState(() => _showExtraDetails = !_showExtraDetails),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _showExtraDetails
                            ? Icons.remove_circle_outline_rounded
                            : Icons.add_circle_outline_rounded,
                        size: 20,
                        color: CottagecoreColors.forest,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showExtraDetails
                            ? 'Ocultar detalles'
                            : '+ Añadir detalles',
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
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción / Instrucciones',
                    hintText: 'Ej. Capítulos 3 y 4 del libro...',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _linkedExamId,
                  decoration: const InputDecoration(
                      labelText: 'Vincular a examen (opcional)'),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('Sin examen asociado')),
                    ...repo.exams
                        .where((exam) => exam.subjectId == _subjectId)
                        .map((exam) => DropdownMenuItem<String?>(
                              value: exam.id,
                              child: Text(exam.name),
                            )),
                  ],
                  onChanged: (value) => setState(() => _linkedExamId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _linkedDeliverableId,
                  decoration: const InputDecoration(
                      labelText: 'Vincular a entrega (opcional)'),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('Sin entrega asociada')),
                    ...repo.deliverables
                        .where((deliv) => deliv.subjectId == _subjectId)
                        .map((deliv) => DropdownMenuItem<String?>(
                              value: deliv.id,
                              child: Text(deliv.title),
                            )),
                  ],
                  onChanged: (value) =>
                      setState(() => _linkedDeliverableId = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas adicionales',
                    hintText: 'Consejos del profesor, detalles clave...',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _linksController,
                  decoration: const InputDecoration(
                    labelText: 'Enlaces (separados por coma)',
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _filesController,
                  decoration: const InputDecoration(
                    labelText: 'Archivos o nombres de entrega',
                    hintText: 'actividad_2.pdf, modelo.dart',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _pickFiles,
                  icon: const Icon(Icons.attach_file_rounded),
                  label: Text(_pendingFiles.isEmpty
                      ? 'Adjuntar archivos'
                      : 'Añadir otros archivos (${_pendingFiles.length})'),
                ),
                if (_pendingFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _pendingFiles
                        .map((file) => InputChip(
                              label: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 190),
                                child: Text(file.name,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              onDeleted: _isSaving
                                  ? null
                                  : () => setState(
                                      () => _pendingFiles.remove(file)),
                            ))
                        .toList(),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: CottagecoreColors.forest,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isSaving
                  ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded),
                label: Text(
                  isEditing ? 'Actualizar tarea' : 'Crear tarea',
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

  Widget _priorityOption(TaskPriority priority, String label) {
    final isSelected = _priority == priority;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _priority = priority),
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
              color: isSelected
                  ? CottagecoreColors.sage
                  : CottagecoreColors.border,
              width: isSelected ? 1.8 : 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? CottagecoreColors.forest
                  : const Color(0xFF6B6053),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusOption(TaskStatus status, String label) {
    final isSelected = _status == status;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _status = status),
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
              color: isSelected
                  ? CottagecoreColors.sage
                  : CottagecoreColors.border,
              width: isSelected ? 1.8 : 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? CottagecoreColors.forest
                  : const Color(0xFF6B6053),
            ),
          ),
        ),
      ),
    );
  }
}
