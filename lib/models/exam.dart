import 'package:flutter/material.dart';

enum ExamState { notStarted, started, preparing, revising, ready }

class ExamTopic {
  const ExamTopic({
    required this.title,
    this.isCompleted = false,
  });

  final String title;
  final bool isCompleted;

  ExamTopic copyWith({
    String? title,
    bool? isCompleted,
  }) {
    return ExamTopic(
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'isCompleted': isCompleted,
      };

  factory ExamTopic.fromJson(Map<String, dynamic> json) => ExamTopic(
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}

class Exam {
  const Exam({
    required this.id,
    required this.name,
    required this.subjectId,
    required this.date,
    required this.time,
    required this.classroom,
    required this.topics,
    required this.state,
    this.notes,
    this.linkedNoteIds = const [],
  });

  final String id;
  final String name;
  final String subjectId;
  final DateTime date;
  final String time;
  final String classroom;
  final List<ExamTopic> topics;
  final ExamState state;
  final String? notes;
  final List<String> linkedNoteIds;

  String get stateLabel {
    switch (state) {
      case ExamState.notStarted:
        return '🔴 No empezado';
      case ExamState.started:
        return '🟠 Empezado';
      case ExamState.preparing:
        return '🟡 Preparando';
      case ExamState.revising:
        return '🔵 Repasando';
      case ExamState.ready:
        return '🟢 Preparado';
    }
  }

  Color get stateColor {
    switch (state) {
      case ExamState.notStarted:
        return const Color(0xFFC04E3D);
      case ExamState.started:
        return const Color(0xFFD47C35);
      case ExamState.preparing:
        return const Color(0xFFB58E29);
      case ExamState.revising:
        return const Color(0xFF4A7C9B);
      case ExamState.ready:
        return const Color(0xFF496B4B);
    }
  }

  int get completedTopicsCount =>
      topics.where((topic) => topic.isCompleted).length;

  int get progressPercent {
    if (topics.isEmpty) return 0;
    return ((completedTopicsCount / topics.length) * 100).round();
  }

  Exam copyWith({
    String? id,
    String? name,
    String? subjectId,
    DateTime? date,
    String? time,
    String? classroom,
    List<ExamTopic>? topics,
    ExamState? state,
    String? notes,
    List<String>? linkedNoteIds,
  }) {
    return Exam(
      id: id ?? this.id,
      name: name ?? this.name,
      subjectId: subjectId ?? this.subjectId,
      date: date ?? this.date,
      time: time ?? this.time,
      classroom: classroom ?? this.classroom,
      topics: topics ?? this.topics,
      state: state ?? this.state,
      notes: notes ?? this.notes,
      linkedNoteIds: linkedNoteIds ?? this.linkedNoteIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subjectId': subjectId,
        'date': date.toIso8601String(),
        'time': time,
        'classroom': classroom,
        'topics': topics.map((t) => t.toJson()).toList(),
        'state': state.name,
        'notes': notes,
        'linkedNoteIds': linkedNoteIds,
      };

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
        id: json['id'] as String,
        name: json['name'] as String,
        subjectId: json['subjectId'] as String,
        date: DateTime.parse(json['date'] as String),
        time: json['time'] as String,
        classroom: json['classroom'] as String? ?? 'Aula común',
        topics: (json['topics'] as List<dynamic>?)
                ?.map((e) => ExamTopic.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        state: ExamState.values.firstWhere(
          (s) => s.name == (json['state'] as String),
          orElse: () => ExamState.notStarted,
        ),
        notes: json['notes'] as String?,
        linkedNoteIds: (json['linkedNoteIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );
}
