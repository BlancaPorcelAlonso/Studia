import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';

class PracticeTimeFormModal extends StatefulWidget {
  const PracticeTimeFormModal({super.key});

  static Future<void> show(BuildContext context) async {
    final isDesktop = MediaQuery.of(context).size.width >= 700;
    if (isDesktop) {
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 580, maxHeight: 800),
            child: PracticeTimeFormModal(),
          ),
        ),
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const PracticeTimeFormModal(),
      );
    }
  }

  @override
  State<PracticeTimeFormModal> createState() => _PracticeTimeFormModalState();
}

class _PracticeTimeFormModalState extends State<PracticeTimeFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    setState(() => _isSaving = true);
    try {
      await AgendaRepository.instance.addPracticeMinutes(hours * 60 + minutes);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudieron guardar las horas: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    return Container(
      decoration: BoxDecoration(
        color: CottagecoreColors.creamCard,
        borderRadius: isDesktop
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isDesktop) ...[
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
              ],
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '🌱 Añadir horas de prácticas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: CottagecoreColors.forest,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: const Icon(Icons.close_rounded),
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('practice-hours-input'),
                      controller: _hoursController,
                      decoration: const InputDecoration(labelText: 'Horas'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        final hours = int.tryParse(value ?? '');
                        final minutes = int.tryParse(_minutesController.text);
                        if ((value?.isNotEmpty ?? false) && hours == null) {
                          return 'Horas inválidas';
                        }
                        if (_minutesController.text.isNotEmpty &&
                            minutes == null) {
                          return 'Minutos inválidos';
                        }
                        if ((hours ?? 0) == 0 && (minutes ?? 0) == 0) {
                          return 'Añade al menos un minuto';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('practice-minutes-input'),
                      controller: _minutesController,
                      decoration: const InputDecoration(labelText: 'Minutos'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        final minutes = int.tryParse(value ?? '');
                        if ((value?.isNotEmpty ?? false) && minutes == null) {
                          return 'Minutos inválidos';
                        }
                        if (minutes != null && minutes > 59) {
                          return 'Máx. 59';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const ValueKey('practice-save-button'),
                onPressed: _isSaving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: CottagecoreColors.forest,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text(
                  'Guardar horas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
