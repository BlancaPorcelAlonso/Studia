import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';
import 'studia_form_widgets.dart';

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
    await StudiaModalHelper.show(
      context: context,
      maxWidth: 620,
      child: NoteFormModal(
        initialNote: initialNote,
        initialSubjectId: initialSubjectId,
      ),
    );
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

  Future<void> _attachFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.any,
    );
    if (files.isEmpty) return;
    final file = files.first;
    final bytes = await file.readAsBytes();
    final encoded = base64Encode(bytes);
    setState(() {
      _attachments.add(
        NoteAttachment(
          name: file.name,
          bytesBase64: encoded,
          sizeBytes: bytes.length,
          mimeType: _attachmentMimeType(file.extension),
        ),
      );
    });
  }

  String? _attachmentMimeType(String? extension) =>
      switch (extension?.toLowerCase()) {
        'pdf' => 'application/pdf',
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'txt' => 'text/plain',
        'csv' => 'text/csv',
        _ => null,
      };

  void _addCheckItem() {
    final text = _newCheckItemController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _checklist.add(NoteCheckItem(text: text, isChecked: false));
      _newCheckItemController.clear();
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
      topic: _topicController.text.trim().isEmpty
          ? 'Tema 1'
          : _topicController.text.trim(),
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

  void _delete() {
    if (widget.initialNote == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar apunte?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: CottagecoreColors.urgentRed,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              AgendaRepository.instance.deleteNote(widget.initialNote!.id);
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

    return StudiaModalContainer(
      title: isEditing ? '📖 Editar apunte' : '📖 Nuevo apunte de estudio',
      subtitle: isEditing
          ? 'Modifica el contenido, adjuntos o checklist de repaso'
          : 'Organiza apuntes, resúmenes y conceptos clave',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título
            StudiaFormField(
              label: 'Título del apunte',
              isRequired: true,
              child: TextFormField(
                controller: _titleController,
                autofocus: !isEditing,
                decoration: const InputDecoration(
                  hintText: 'Ej. Resumen de Concurrencia y Bloqueos',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Indica el título' : null,
              ),
            ),

            // Asignatura y Tema
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: StudiaFormField(
                    label: 'Asignatura',
                    isRequired: true,
                    child: DropdownButtonFormField<String>(
                      initialValue: _subjectId.isNotEmpty ? _subjectId : null,
                      isExpanded: true,
                      decoration: const InputDecoration(),
                      items: repo.subjects.map((sub) {
                        return DropdownMenuItem(
                          value: sub.id,
                          child: Text(
                            '${sub.emoji} ${sub.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _subjectId = val);
                      },
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StudiaFormField(
                    label: 'Tema / Unidad',
                    child: TextFormField(
                      controller: _topicController,
                      decoration: const InputDecoration(
                        hintText: 'Ej. Tema 2',
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Categoría y Etiquetas
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: StudiaFormField(
                    label: 'Categoría',
                    child: DropdownButtonFormField<String>(
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
                        DropdownMenuItem(value: 'Resumen', child: Text('Resumen')),
                        DropdownMenuItem(
                            value: 'Cuestionario', child: Text('Cuestionario')),
                        DropdownMenuItem(value: 'Esquema', child: Text('Esquema')),
                        DropdownMenuItem(value: 'Apuntes', child: Text('Apuntes')),
                        DropdownMenuItem(value: 'Código', child: Text('Código')),
                      ],
                      onChanged: (val) {
                        if (val != null) _categoryController.text = val;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StudiaFormField(
                    label: 'Etiquetas',
                    child: TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        hintText: 'Flutter, UI, Examen',
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Contenido del apunte
            StudiaFormField(
              label: 'Contenido del apunte',
              child: TextFormField(
                controller: _contentController,
                maxLines: 7,
                decoration: const InputDecoration(
                  hintText:
                      'Escribe tus notas, fórmulas, ideas clave, definiciones...',
                ),
              ),
            ),

            // Documentos adjuntos
            StudiaSectionHeader(
              title: '📎 Documentos adjuntos (${_attachments.length})',
              action: TextButton.icon(
                onPressed: _attachFile,
                icon: const Icon(Icons.attach_file_rounded, size: 16),
                label: const Text('Adjuntar'),
                style: TextButton.styleFrom(
                  foregroundColor: CottagecoreColors.forest,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            if (_attachments.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: CottagecoreColors.creamDarker,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.file_present_outlined,
                        size: 20, color: CottagecoreColors.warmBrown),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sin archivos adjuntos. Puedes subir PDFs, imágenes o apuntes.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF7A6F62)),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              ...List.generate(_attachments.length, (index) {
                final attachment = _attachments[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CottagecoreColors.border),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    leading: const Icon(Icons.insert_drive_file_outlined,
                        color: CottagecoreColors.forest),
                    title: Text(attachment.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle:
                        Text('${(attachment.sizeBytes / 1024).ceil()} KB'),
                    trailing: IconButton(
                      tooltip: 'Quitar archivo',
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () =>
                          setState(() => _attachments.removeAt(index)),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],

            // Checklist de repaso
            StudiaSectionHeader(
              title: '✓ Puntos clave / Repaso (${_checklist.length})',
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newCheckItemController,
                    decoration: InputDecoration(
                      hintText: 'Añadir concepto o pregunta a repasar...',
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
                  onPressed: _addCheckItem,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...List.generate(_checklist.length, (index) {
              final item = _checklist[index];
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
                      value: item.isChecked,
                      activeColor: CottagecoreColors.forest,
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
                          color: item.isChecked
                              ? const Color(0xFF8C8276)
                              : const Color(0xFF382F26),
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
            const SizedBox(height: 10),
          ],
        ),
      ),
      actions: Row(
        children: [
          if (isEditing)
            IconButton.outlined(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: CottagecoreColors.urgentRed),
              tooltip: 'Eliminar apunte',
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
              label: isEditing ? 'Guardar cambios' : 'Crear apunte',
              icon: isEditing ? Icons.check_rounded : Icons.add_rounded,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}
