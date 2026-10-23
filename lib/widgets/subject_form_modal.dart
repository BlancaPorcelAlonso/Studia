import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';
import 'schedule_editor.dart';
import 'studia_form_widgets.dart';

class SubjectFormModal extends StatefulWidget {
  const SubjectFormModal({this.initialSubject, super.key});

  final Subject? initialSubject;

  static Future<void> show(
    BuildContext context, {
    Subject? initialSubject,
  }) async {
    await StudiaModalHelper.show(
      context: context,
      maxWidth: 600,
      child: SubjectFormModal(initialSubject: initialSubject),
    );
  }

  @override
  State<SubjectFormModal> createState() => _SubjectFormModalState();
}

class _SubjectFormModalState extends State<SubjectFormModal> {
  static const _emojiOptions = [
    '🌿',
    '🌱',
    '📚',
    '🧪',
    '🎨',
    '💻',
    '🧮',
    '📖',
    '🌷',
    '🍄',
    '🕯️',
    '🪶',
  ];
  static const _colorOptions = [
    (0xFF7EA98B, 'Verde salvia'),
    (0xFFC77A5C, 'Terracota'),
    (0xFFD49A9C, 'Rosa empolvado'),
    (0xFFB69A7A, 'Marrón cálido'),
    (0xFF8FA392, 'Verde suave'),
    (0xFFD8B25A, 'Mostaza cálido'),
    (0xFF5A7F92, 'Azul pizarra'),
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _teacherController;
  late String _emoji;
  late int _colorValue;
  late List<ClassSchedule> _schedules;
  bool _isSaving = false;

  bool get isEditing => widget.initialSubject != null;

  @override
  void initState() {
    super.initState();
    final subject = widget.initialSubject;
    _nameController = TextEditingController(text: subject?.name ?? '');
    _teacherController = TextEditingController(text: subject?.teacher ?? '');
    _emoji = subject?.emoji ?? _emojiOptions.first;
    _colorValue = subject?.colorValue ?? _colorOptions.first.$1;
    _schedules = List<ClassSchedule>.from(subject?.schedules ?? const []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    final subject = widget.initialSubject;
    final name = _nameController.text.trim();
    final teacher = _teacherController.text.trim();
    // Sort schedules chronologically by startMinutes
    final sortedSchedules = List<ClassSchedule>.from(_schedules)
      ..sort((a, b) {
        final dayCmp = a.weekday.compareTo(b.weekday);
        if (dayCmp != 0) return dayCmp;
        return a.startMinutes.compareTo(b.startMinutes);
      });

    final updated = subject == null
        ? Subject(
            id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            emoji: _emoji,
            colorValue: _colorValue,
            teacher: teacher.isEmpty ? null : teacher,
            schedules: sortedSchedules,
          )
        : subject.copyWith(
            name: name,
            emoji: _emoji,
            colorValue: _colorValue,
            teacher: teacher.isEmpty ? null : teacher,
            schedules: sortedSchedules,
          );
    final repo = AgendaRepository.instance;
    setState(() => _isSaving = true);
    try {
      final synced = subject == null
          ? await repo.addSubject(updated)
          : await repo.updateSubject(updated);
      if (!synced) return;
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la asignatura: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudiaModalContainer(
      title: isEditing ? '✏️ Editar asignatura' : '📚 Nueva asignatura',
      subtitle: isEditing
          ? 'Modifica los datos, colores u horarios de la materia'
          : 'Añade una asignatura a tu plan de estudio',
      actions: Row(
        children: [
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
                      ? 'Guardar cambios'
                      : 'Crear asignatura',
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
            // Nombre
            StudiaFormField(
              label: 'Nombre de la materia',
              isRequired: true,
              child: TextFormField(
                controller: _nameController,
                autofocus: !isEditing,
                decoration: const InputDecoration(
                  hintText: 'Ej. Arquitectura del Software',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Escribe el nombre de la materia'
                    : null,
              ),
            ),

            // Profesor/a
            StudiaFormField(
              label: 'Profesor/a (opcional)',
              child: TextFormField(
                controller: _teacherController,
                decoration: const InputDecoration(
                  hintText: 'Ej. Dra. Carmen Silva',
                ),
              ),
            ),

            // Icono
            StudiaFormField(
              label: 'Icono de la asignatura',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _emojiOptions.map((emoji) {
                  final selected = emoji == _emoji;
                  return InkWell(
                    onTap: () => setState(() => _emoji = emoji),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? CottagecoreColors.sage.withValues(alpha: 0.25)
                            : CottagecoreColors.creamDarker,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? CottagecoreColors.forest
                              : CottagecoreColors.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Color identificador
            StudiaFormField(
              label: 'Color identificador',
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                children: _colorOptions.map((option) {
                  final selected = _colorValue == option.$1;
                  return Tooltip(
                    message: option.$2,
                    child: InkWell(
                      onTap: () => setState(() => _colorValue = option.$1),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(option.$1),
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(
                                  color: CottagecoreColors.forest, width: 2.8)
                              : Border.all(color: Colors.white, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded,
                                size: 18, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Editor de horarios
            StudiaSectionHeader(
              title: '🕒 Horario de clases',
            ),
            ScheduleEditor(
              initialSchedules: _schedules,
              onChanged: (value) => _schedules = value,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
