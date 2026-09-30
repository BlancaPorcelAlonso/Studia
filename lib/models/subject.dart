import 'package:flutter/material.dart';

class ClassSchedule {
  const ClassSchedule({
    required this.weekday,
    required this.startMinutes,
    required this.durationMinutes,
  });

  final int weekday;
  final int startMinutes;
  final int durationMinutes;

  String get timeLabel =>
      '${(startMinutes ~/ 60).toString().padLeft(2, '0')}:${(startMinutes % 60).toString().padLeft(2, '0')}';

  String get durationHoursLabel =>
      (durationMinutes / 60).toStringAsFixed(durationMinutes % 60 == 0 ? 0 : 1);

  String get durationLabel => '$durationHoursLabel h';

  ClassSchedule copyWith({
    int? weekday,
    int? startMinutes,
    int? durationMinutes,
  }) =>
      ClassSchedule(
        weekday: weekday ?? this.weekday,
        startMinutes: startMinutes ?? this.startMinutes,
        durationMinutes: durationMinutes ?? this.durationMinutes,
      );

  static int? parseTime(String value) {
    final match = RegExp(r'^(\d{1,2})[:.](\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return hour * 60 + minute;
  }

  Map<String, dynamic> toJson() => {
        'weekday': weekday,
        'startMinutes': startMinutes,
        'durationMinutes': durationMinutes,
      };

  factory ClassSchedule.fromJson(Map<String, dynamic> json) => ClassSchedule(
        weekday: json['weekday'] as int,
        startMinutes: json['startMinutes'] as int,
        durationMinutes: json['durationMinutes'] as int? ?? 60,
      );
}

class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    this.teacher,
    this.classroom,
    this.schedule,
    this.schedules = const [],
    this.notes,
    this.lastStudyNote,
    this.lastStudyAt,
  });

  final String id;
  final String name;
  final String emoji;
  final int colorValue;
  final String? teacher;
  final String? classroom;
  final String? schedule;
  final List<ClassSchedule> schedules;
  final String? notes;
  final String? lastStudyNote;
  final DateTime? lastStudyAt;

  Color get color => Color(colorValue);

  Subject copyWith({
    String? id,
    String? name,
    String? emoji,
    int? colorValue,
    String? teacher,
    String? classroom,
    String? schedule,
    List<ClassSchedule>? schedules,
    String? notes,
    String? lastStudyNote,
    DateTime? lastStudyAt,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      teacher: teacher ?? this.teacher,
      classroom: classroom ?? this.classroom,
      schedule: schedule ?? this.schedule,
      schedules: schedules ?? this.schedules,
      notes: notes ?? this.notes,
      lastStudyNote: lastStudyNote ?? this.lastStudyNote,
      lastStudyAt: lastStudyAt ?? this.lastStudyAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'colorValue': colorValue,
        'teacher': teacher,
        'classroom': classroom,
        'schedule': schedule,
        'schedules': schedules.map((item) => item.toJson()).toList(),
        'notes': notes,
        'lastStudyNote': lastStudyNote,
        'lastStudyAt': lastStudyAt?.toIso8601String(),
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String? ?? '🌿',
        colorValue: json['colorValue'] as int? ?? 0xFF7EA98B,
        teacher: json['teacher'] as String?,
        classroom: json['classroom'] as String?,
        schedule: json['schedule'] as String?,
        schedules: (json['schedules'] as List<dynamic>?)
                ?.map((item) =>
                    ClassSchedule.fromJson(item as Map<String, dynamic>))
                .toList() ??
            const [],
        notes: json['notes'] as String?,
        lastStudyNote: json['lastStudyNote'] as String?,
        lastStudyAt: json['lastStudyAt'] != null
            ? DateTime.tryParse(json['lastStudyAt'] as String)
            : null,
      );
}
