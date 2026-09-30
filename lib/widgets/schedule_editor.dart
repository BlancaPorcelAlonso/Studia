import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Horarios de clase',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: CottagecoreColors.warmBrown,
          ),
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
                  final fields = [
                    DropdownButtonFormField<int>(
                      initialValue: schedule.weekday,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Día'),
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
                    TextFormField(
                      initialValue: schedule.timeLabel,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: 'Hora de inicio',
                        hintText: '17:00',
                      ),
                      onChanged: (value) {
                        final minutes = ClassSchedule.parseTime(value);
                        if (minutes != null) {
                          _update(
                              index, schedule.copyWith(startMinutes: minutes));
                        }
                      },
                    ),
                    TextFormField(
                      initialValue: schedule.durationHoursLabel,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Duración (horas)',
                        hintText: '2',
                      ),
                      onChanged: (value) {
                        final hours =
                            double.tryParse(value.replaceAll(',', '.'));
                        if (hours != null && hours > 0) {
                          _update(
                              index,
                              schedule.copyWith(
                                  durationMinutes: (hours * 60).round()));
                        }
                      },
                    ),
                  ];

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
                        if (constraints.maxWidth < 500)
                          ...fields.map((field) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: field,
                              ))
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: fields[0]),
                              const SizedBox(width: 8),
                              Expanded(flex: 3, child: fields[1]),
                              const SizedBox(width: 8),
                              Expanded(flex: 3, child: fields[2]),
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
