import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';
import 'schedule_editor.dart';

class SubjectFormModal extends StatefulWidget {
  const SubjectFormModal({this.initialSubject, super.key});

  final Subject? initialSubject;

  static Future<void> show(
    BuildContext context, {
    Subject? initialSubject,
  }) async {
    final isDesktop = MediaQuery.of(context).size.width >= 700;
    if (isDesktop) {
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 800),
            child: SubjectFormModal(initialSubject: initialSubject),
          ),
        ),
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SubjectFormModal(initialSubject: initialSubject),
      );
    }
  }

  @override
  State<SubjectFormModal> createState() => _SubjectFormModalState();
}

class _SubjectFormModalState extends State<SubjectFormModal> {
  static const _emojiOptions = [
    '🌿', '🌱', '📚', '🧪', '🎨', '💻', '🧮', '📖', '🌷', '🍄', '🕯️', '🪶',
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
    if (!_formKey.currentState!.validate()) return;
    final subject = widget.initialSubject;
    final name = _nameController.text.trim();
    final teacher = _teacherController.text.trim();
    final updated = subject == null
        ? Subject(
            id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            emoji: _emoji,
            colorValue: _colorValue,
            teacher: teacher.isEmpty ? null : teacher,
            schedules: _schedules,
          )
        : subject.copyWith(
            name: name,
            emoji: _emoji,
            colorValue: _colorValue,
            teacher: teacher.isEmpty ? null : teacher,
            schedules: _schedules,
          );
    if (subject == null) {
      await AgendaRepository.instance.addSubject(updated);
    } else {
      await AgendaRepository.instance.updateSubject(updated);
    }
    if (mounted) Navigator.of(context).pop();
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
                    isEditing ? '✏️ Editar asignatura' : '📚 Nueva asignatura',
                    style: const TextStyle(
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
              const _FieldLabel('Nombre de la materia'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                autofocus: !isEditing,
                decoration: const InputDecoration(
                  hintText: 'Ej. Arquitectura del Software',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Escribe el nombre de la materia'
                    : null,
              ),
              const SizedBox(height: 14),
              const _FieldLabel('Profesor/a'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _teacherController,
                decoration: const InputDecoration(
                  hintText: 'Ej. Dra. Carmen Silva',
                ),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Icono de la asignatura'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _emojiOptions.map((emoji) {
                  final selected = emoji == _emoji;
                  return InkWell(
                    onTap: () => setState(() => _emoji = emoji),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? CottagecoreColors.sage.withValues(alpha: 0.2)
                            : CottagecoreColors.creamDarker,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? CottagecoreColors.sage
                              : CottagecoreColors.border,
                          width: selected ? 1.8 : 0.8,
                        ),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ScheduleEditor(
                initialSchedules: _schedules,
                onChanged: (value) => _schedules = value,
              ),
              const SizedBox(height: 14),
              const _FieldLabel('Color identificador'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
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
                              ? Border.all(color: CottagecoreColors.forest, width: 2.5)
                              : null,
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
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: CottagecoreColors.forest,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  isEditing ? 'Guardar asignatura' : 'Crear asignatura',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
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
