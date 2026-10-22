import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';
import 'attachment_preview_dialog.dart';
import 'studia_form_widgets.dart';

/// Modal unificado para crear, editar y consultar entregas o eventos académicos
class DeliverableFormModal extends StatefulWidget {
  const DeliverableFormModal({
    this.initialDeliverable,
    this.initialSubjectId,
    this.initialDate,
    super.key,
  });

  final Deliverable? initialDeliverable;
  final String? initialSubjectId;
  final DateTime? initialDate;

  static Future<void> show(
    BuildContext context, {
    Deliverable? initialDeliverable,
    String? initialSubjectId,
    DateTime? initialDate,
  }) async {
    await StudiaModalHelper.show(
      context: context,
      child: DeliverableFormModal(
        initialDeliverable: initialDeliverable,
        initialSubjectId: initialSubjectId,
        initialDate: initialDate,
      ),
    );
  }

  @override
  State<DeliverableFormModal> createState() => _DeliverableFormModalState();
}

class _DeliverableFormModalState extends State<DeliverableFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late List<NoteAttachment> _attachments;

  late String _subjectId;
  late DateTime _date;
  late bool _isSubmitted;

  bool get isEditing => widget.initialDeliverable != null;

  @override
  void initState() {
    super.initState();
    final repo = AgendaRepository.instance;
    final defaultSubId = repo.subjects.isNotEmpty ? repo.subjects.first.id : '';

    final d = widget.initialDeliverable;
    _titleController = TextEditingController(text: d?.title ?? '');
    _descriptionController = TextEditingController(text: d?.description ?? '');
    _attachments = d == null ? [] : List.from(d.attachments);

    _subjectId = d?.subjectId ?? widget.initialSubjectId ?? defaultSubId;
    _date = d?.date ??
        widget.initialDate ??
        DateTime.now().add(const Duration(days: 7));
    _isSubmitted = d?.isSubmitted ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final repo = AgendaRepository.instance;
    final deliverable = Deliverable(
      id: widget.initialDeliverable?.id ??
          'deliv_${DateTime.now().millisecondsSinceEpoch}',
      subjectId: _subjectId,
      title: _titleController.text.trim(),
      date: _date,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isSubmitted: _isSubmitted,
      attachments: _attachments,
    );

    if (isEditing) {
      repo.updateDeliverable(deliverable);
    } else {
      repo.addDeliverable(deliverable);
    }

    Navigator.of(context).pop();
  }

  Future<void> _pickAttachment() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return;
    final file = files.first;
    final bytes = await file.readAsBytes();
    setState(() {
      _attachments.add(NoteAttachment(
        name: file.name,
        bytesBase64: base64Encode(bytes),
        sizeBytes: bytes.length,
        mimeType: _mimeType(file.extension),
      ));
    });
  }

  String? _mimeType(String? extension) => switch (extension?.toLowerCase()) {
        'pdf' => 'application/pdf',
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'txt' => 'text/plain',
        'csv' => 'text/csv',
        _ => null,
      };

  Future<void> _previewAttachment(NoteAttachment attachment) async {
    await AttachmentPreviewDialog.show(
      context,
      fileName: attachment.name,
      loadBytes: () async {
        if (attachment.bytesBase64.isNotEmpty) {
          return Uint8List.fromList(base64Decode(attachment.bytesBase64));
        }
        final path = attachment.storagePath;
        if (path == null) throw StateError('El archivo no está disponible.');
        return Supabase.instance.client.storage
            .from('agenda-attachments')
            .download(path);
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: CottagecoreColors.forest,
              onPrimary: Colors.white,
              surface: CottagecoreColors.creamCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _delete() {
    if (widget.initialDeliverable == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar entrega?'),
        content: const Text(
          'Esta acción no se puede deshacer.',
        ),
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
              AgendaRepository.instance
                  .deleteDeliverable(widget.initialDeliverable!.id);
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
      title: isEditing ? '✏️ Editar entrega' : '📦 Nueva entrega',
      subtitle: isEditing
          ? 'Actualiza los detalles o el estado de entrega'
          : 'Añade una fecha de trabajo, práctica o proyecto',
      actions: Row(
        children: [
          if (isEditing)
            IconButton.outlined(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: CottagecoreColors.urgentRed),
              tooltip: 'Eliminar entrega',
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
              label: isEditing ? 'Guardar cambios' : 'Crear entrega',
              icon: isEditing ? Icons.check_rounded : Icons.add_rounded,
              onPressed: _submit,
            ),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Estado de entrega destacado
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isSubmitted
                    ? CottagecoreColors.sage.withValues(alpha: 0.15)
                    : CottagecoreColors.creamDarker,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isSubmitted
                      ? CottagecoreColors.sage
                      : CottagecoreColors.border,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSubmitted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: _isSubmitted
                        ? CottagecoreColors.forest
                        : CottagecoreColors.warmBrown,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSubmitted
                              ? 'Entrega completada ✓'
                              : 'Pendiente de entrega',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _isSubmitted
                                ? CottagecoreColors.forest
                                : CottagecoreColors.warmBrown,
                          ),
                        ),
                        Text(
                          _isSubmitted
                              ? 'Marcada como entregada'
                              : 'Pulsa para marcar como entregada',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7A6F62),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isSubmitted,
                    activeColor: CottagecoreColors.forest,
                    onChanged: (val) {
                      setState(() => _isSubmitted = val);
                    },
                  ),
                ],
              ),
            ),

            // Título de la entrega
            StudiaFormField(
              label: 'Título de la entrega',
              isRequired: true,
              child: TextFormField(
                controller: _titleController,
                autofocus: !isEditing,
                decoration: const InputDecoration(
                  hintText: 'Ej. Trabajo fin de trimestre / Práctica 3',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Indica el nombre de la entrega';
                  }
                  return null;
                },
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
                  return DropdownMenuItem<String>(
                    value: sub.id,
                    child: Row(
                      children: [
                        Text(sub.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          sub.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _subjectId = val);
                },
                validator: (val) =>
                    val == null || val.isEmpty ? 'Selecciona una materia' : null,
              ),
            ),

            // Fecha
            StudiaFormField(
              label: 'Fecha de entrega',
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CottagecoreColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 18, color: CottagecoreColors.forest),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEEE, d \'de\' MMMM yyyy', 'es_ES')
                            .format(_date),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CottagecoreColors.forest,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_calendar_rounded,
                          size: 18, color: CottagecoreColors.warmBrown),
                    ],
                  ),
                ),
              ),
            ),

            // Descripción o notas
            StudiaFormField(
              label: 'Detalles o requisitos (opcional)',
              bottomSpacing: 8,
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Añade pautas de entrega, enlace al campus, etc.',
                ),
              ),
            ),
            StudiaFormField(
              label: 'Archivos adjuntos',
              bottomSpacing: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickAttachment,
                    icon: const Icon(Icons.attach_file_rounded),
                    label: const Text('Adjuntar archivo'),
                  ),
                  if (_attachments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _attachments.map((attachment) {
                        return InputChip(
                          avatar: const Icon(Icons.attach_file_rounded,
                              size: 17),
                          label: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 190),
                            child: Text(attachment.name,
                                overflow: TextOverflow.ellipsis),
                          ),
                          onPressed: () => _previewAttachment(attachment),
                          onDeleted: () => setState(
                              () => _attachments.remove(attachment)),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
