import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../theme/cottagecore_theme.dart';

class ScheduleEditor extends StatefulWidget {
  const ScheduleEditor({
    required this.initialSchedules,
    required this.onChanged,
    super.key,
  });

  final List<ClassSchedule> initialSchedules;
  final ValueChanged<List<ClassSchedule>> onChanged;

  @override
  State<ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<ScheduleEditor> {
  late List<ClassSchedule> _schedules;

  @override
  void initState() {
    super.initState();
    _schedules = List<ClassSchedule>.from(widget.initialSchedules);
  }

  void _update(int index, ClassSchedule value) {
    setState(() => _schedules[index] = value);
    widget.onChanged(List<ClassSchedule>.from(_schedules));
  }

  void _add() {
    final next = ClassSchedule(
      weekday: _schedules.isEmpty ? DateTime.monday : _schedules.last.weekday,
      startMinutes: _schedules.isEmpty ? 8 * 60 : _schedules.last.startMinutes,
      durationMinutes: 60,
    );
    setState(() => _schedules.add(next));
    widget.onChanged(List<ClassSchedule>.from(_schedules));
  }

  void _remove(int index) {
    setState(() => _schedules.removeAt(index));
    widget.onChanged(List<ClassSchedule>.from(_schedules));
  }

  void _updateStartTime(
    int index,
    ClassSchedule schedule, {
    int? hour,
    int? minute,
  }) {
    final nextHour = hour ?? schedule.startMinutes ~/ 60;
    final nextMinute = minute ?? schedule.startMinutes % 60;
    if (nextHour > 23 || nextMinute > 59) return;
    _update(
      index,
      schedule.copyWith(
        startMinutes: nextHour * 60 + nextMinute,
      ),
    );
  }

  void _updateDuration(
    int index,
    ClassSchedule schedule, {
    int? hours,
    int? minutes,
  }) {
    final currentHours = schedule.durationMinutes ~/ 60;
    final currentMinutes = schedule.durationMinutes % 60;
    final totalMinutes =
        ((hours ?? currentHours) * 60 + (minutes ?? currentMinutes))
            .clamp(1, 1440);
    _update(index, schedule.copyWith(durationMinutes: totalMinutes));
  }

  Widget _buildStartTimeEditor(int index, ClassSchedule schedule) {
    return _fieldSection(
      'Hora de inicio',
      Row(
        children: [
          Expanded(
            child: TextFormField(
              key: ValueKey('schedule-hour-$index'),
              initialValue:
                  (schedule.startMinutes ~/ 60).toString().padLeft(2, '0'),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: const InputDecoration(hintText: 'HH'),
              onChanged: (value) {
                final hour = int.tryParse(value);
                if (hour != null && hour <= 23) {
                  _updateStartTime(index, schedule, hour: hour);
                }
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Text(':', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: TextFormField(
              key: ValueKey('schedule-minute-$index'),
              initialValue:
                  (schedule.startMinutes % 60).toString().padLeft(2, '0'),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: const InputDecoration(hintText: 'MM'),
              onChanged: (value) {
                final minute = int.tryParse(value);
                if (minute != null && minute <= 59) {
                  _updateStartTime(index, schedule, minute: minute);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldSection(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 6),
          field,
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel(
          'Horarios de clase',
        ),
        const SizedBox(height: 6),
        if (_schedules.isEmpty)
          const Text(
            'Añade una franja por cada día y hora de clase.',
            style: TextStyle(fontSize: 12, color: Color(0xFF7A6F62)),
          )
        else
          ...List.generate(_schedules.length, (index) {
            final schedule = _schedules[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final dayField = _fieldSection(
                    'Día',
                    DropdownButtonFormField<int>(
                      initialValue: schedule.weekday,
                      isExpanded: true,
                      decoration: const InputDecoration(),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Lunes')),
                        DropdownMenuItem(value: 2, child: Text('Martes')),
                        DropdownMenuItem(value: 3, child: Text('Miércoles')),
                        DropdownMenuItem(value: 4, child: Text('Jueves')),
                        DropdownMenuItem(value: 5, child: Text('Viernes')),
                        DropdownMenuItem(value: 6, child: Text('Sábado')),
                        DropdownMenuItem(value: 7, child: Text('Domingo')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _update(index, schedule.copyWith(weekday: value));
                        }
                      },
                    ),
                  );

                  // 2. Hora de Inicio
                  final startTimeField = _buildStartTimeEditor(index, schedule);

                  // 3. Horas de Duración
                  final durationHoursField = _fieldSection(
                    'Duración (h)',
                    DropdownButtonFormField<int>(
                      initialValue: schedule.durationMinutes ~/ 60,
                      isExpanded: true,
                      decoration: const InputDecoration(),
                      items: List.generate(
                        25,
                        (hour) => DropdownMenuItem(
                          value: hour,
                          child: Text('$hour h'),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          _updateDuration(index, schedule, hours: value);
                        }
                      },
                    ),
                  );

                  // 4. Minutos de Duración
                  final durationMinutesField = _fieldSection(
                    'Duración (m)',
                    DropdownButtonFormField<int>(
                      initialValue: schedule.durationMinutes % 60,
                      isExpanded: true,
                      decoration: const InputDecoration(),
                      items: List.generate(
                        60,
                        (minute) => DropdownMenuItem(
                          value: minute,
                          child: Text('$minute min'),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          _updateDuration(index, schedule, minutes: value);
                        }
                      },
                    ),
                  );

                  return Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    decoration: BoxDecoration(
                      color:
                          CottagecoreColors.creamDarker.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: CottagecoreColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Franja ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: CottagecoreColors.forest,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Quitar horario',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _remove(index),
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Día arriba en su propio espacio
                        dayField,
                        const SizedBox(height: 10),
                        // Fila única para Hora Inicio, Horas Duración y Minutos Duración
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: startTimeField),
                            const SizedBox(width: 8),
                            Expanded(flex: 2, child: durationHoursField),
                            const SizedBox(width: 8),
                            Expanded(flex: 2, child: durationMinutesField),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Añadir día y hora'),
            style: TextButton.styleFrom(
              foregroundColor: CottagecoreColors.forest,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
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
