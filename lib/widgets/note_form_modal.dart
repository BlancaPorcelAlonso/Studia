import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';

class NoteFormModal extends StatefulWidget {
  const NoteFormModal({
    this.initialNote,
    this.initialSubjectId,
    super.key,
  });

  final StudyNote? initialNote;
  final String? initialSubjectId;

  static Future<void> show(
    BuildContext context, {
    StudyNote? initialNote,
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
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 820),
            child: NoteFormModal(
              initialNote: initialNote,
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
        builder: (ctx) => NoteFormModal(
          initialNote: initialNote,
          initialSubjectId: initialSubjectId,
        ),
      );
    }
  }

  @override
  State<NoteFormModal> createState() => _NoteFormModalState();
}

class _NoteFormModalState extends State<NoteFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _topicController;
  late final TextEditingController _categoryController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;
  late final TextEditingController _newCheckItemController;

  late String _subjectId;
  late List<NoteCheckItem> _checklist;
  late List<NoteAttachment> _attachments;

  bool get isEditing => widget.initialNote != null;

  @override
  void initState() {
    super.initState();
    final repo = AgendaRepository.instance;
    final defaultSubId = repo.subjects.isNotEmpty ? repo.subjects.first.id : '';

    final n = widget.initialNote;
    _titleController = TextEditingController(text: n?.title ?? '');
    _topicController = TextEditingController(text: n?.topic ?? 'Tema 1');
    _categoryController = TextEditingController(text: n?.category ?? 'Resumen');
    _contentController = TextEditingController(text: n?.content ?? '');
    _tagsController = TextEditingController(text: n?.tags.join(', ') ?? '');
    _newCheckItemController = TextEditingController();

    _subjectId = n?.subjectId ?? widget.initialSubjectId ?? defaultSubId;
    _checklist = n != null ? List.from(n.checklist) : [];
    _attachments = n != null ? List.from(n.attachments) : [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _topicController.dispose();
    _categoryController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _newCheckItemController.dispose();
    super.dispose();
  }

  void _addCheckItem() {
    final text = _newCheckItemController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _checklist.add(NoteCheckItem(text: text, isChecked: false));
        _newCheckItemController.clear();
      });
    }
  }

  Future<void> _attachFile() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Adjuntar documento al apunte',
      type: FileType.any,
    );
    if (file == null) return;

    final fileSize = await file.length();
    if (fileSize != null && fileSize > 2 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El archivo supera el límite de 2 MB.')),
        );
      }
      return;
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) return;

    setState(() {
      _attachments.add(NoteAttachment(
        name: file.name,
        bytesBase64: base64Encode(bytes),
        sizeBytes: bytes.length,
      ));
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final repo = AgendaRepository.instance;
    final tags = _tagsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final note = StudyNote(
      id: widget.initialNote?.id ??
          'note_${DateTime.now().millisecondsSinceEpoch}',
      subjectId: _subjectId,
      title: _titleController.text.trim(),
      topic: _topicController.text.trim(),
      category: _categoryController.text.trim(),
      content: _contentController.text.trim(),
      updatedAt: DateTime.now(),
      tags: tags,
      checklist: _checklist,
      attachments: _attachments,
    );

    if (isEditing) {
      repo.updateNote(note);
    } else {
      repo.addNote(note);
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
                        ? '📖 Editar apunte'
                        : '📖 Nuevo apunte de estudio',
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

              const _FieldLabel('Título del apunte'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Ej. Resumen de Concurrencia y Bloqueos',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Indica el título' : null,
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _FieldLabel('Asignatura'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue:
                              _subjectId.isNotEmpty ? _subjectId : null,
                          decoration: const InputDecoration(),
                          items: repo.subjects.map((sub) {
                            return DropdownMenuItem(
                              value: sub.id,
                              child: Text('${sub.emoji} ${sub.name}'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _subjectId = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _FieldLabel('Tema / Unidad'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _topicController,
                          decoration: const InputDecoration(
                            hintText: 'Tema 2',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _FieldLabel('Categoría'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: [
                            'Resumen',
                            'Cuestionario',
                            'Esquema',
                            'Apuntes',
                            'Código'
                          ].contains(_categoryController.text)
                              ? _categoryController.text
                              : 'Resumen',
                          decoration: const InputDecoration(),
                          items: const [
                            DropdownMenuItem(
                                value: 'Resumen', child: Text('Resumen')),
                            DropdownMenuItem(
                                value: 'Cuestionario',
                                child: Text('Cuestionario')),
                            DropdownMenuItem(
                                value: 'Esquema', child: Text('Esquema')),
                            DropdownMenuItem(
                                value: 'Apuntes', child: Text('Apuntes')),
                            DropdownMenuItem(
                                value: 'Código', child: Text('Código')),
                          ],
                          onChanged: (val) {
                            if (val != null) _categoryController.text = val;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _FieldLabel('Etiquetas'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _tagsController,
                          decoration: const InputDecoration(
                            hintText: 'Flutter, UI, Examen',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Content editor
              const _FieldLabel('Contenido del apunte'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contentController,
                maxLines: 7,
                decoration: const InputDecoration(
                  hintText:
                      'Escribe tus notas, fórmulas, ideas clave, definiciones...',
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  const Expanded(
                    child: _FieldLabel('Documentos adjuntos'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _attachFile,
                    icon: const Icon(Icons.attach_file_rounded, size: 18),
                    label: const Text('Añadir archivo'),
                  ),
                ],
              ),
              if (_attachments.isNotEmpty) ...[
                const SizedBox(height: 6),
                ...List.generate(_attachments.length, (index) {
                  final attachment = _attachments[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(attachment.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle:
                        Text('${(attachment.sizeBytes / 1024).ceil()} KB'),
                    trailing: IconButton(
                      tooltip: 'Quitar archivo',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () =>
                          setState(() => _attachments.removeAt(index)),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 14),

              // Checklist section
              const _FieldLabel('Puntos clave / Checklist de repaso'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newCheckItemController,
                      decoration: const InputDecoration(
                        hintText: 'Añadir concepto a repasar...',
                      ),
                      onSubmitted: (_) => _addCheckItem(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: CottagecoreColors.sage,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    onPressed: _addCheckItem,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...List.generate(_checklist.length, (index) {
                final item = _checklist[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: item.isChecked,
                        activeColor: CottagecoreColors.calmGreen,
                        onChanged: (val) {
                          setState(() {
                            _checklist[index] =
                                item.copyWith(isChecked: val ?? false);
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          item.text,
                          style: TextStyle(
                            decoration: item.isChecked
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () {
                          setState(() => _checklist.removeAt(index));
                        },
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: CottagecoreColors.forest,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.save_rounded),
                label: Text(
                  isEditing ? 'Actualizar apunte' : 'Guardar apunte',
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
