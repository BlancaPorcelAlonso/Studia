import 'package:flutter/material.dart';

enum TaskStatus { todo, inProgress, completed }

enum TaskPriority { low, medium, high, urgent }

enum TaskType { assignment, exam, classType, project, event }

class DueInfo {
  final String text;
  final Color color;
  final Color backgroundColor;

  const DueInfo({
    required this.text,
    required this.color,
    required this.backgroundColor,
  });
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.status,
    required this.priority,
    required this.type,
    required this.dueDate,
    this.startDate,
    this.completedAt,
    this.description,
    this.notes,
    this.links = const [],
    this.files = const [],
  });

  final String id;
  final String title;
  final String subjectId;
  final TaskStatus status;
  final TaskPriority priority;
  final TaskType type;
  final DateTime dueDate;
  final DateTime? startDate;
  final DateTime? completedAt;
  final String? description;
  final String? notes;
  final List<String> links;
  final List<String> files;

  String get statusLabel {
    switch (status) {
      case TaskStatus.todo:
        return 'Por hacer';
      case TaskStatus.inProgress:
        return 'En proceso';
      case TaskStatus.completed:
        return 'Completado';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case TaskPriority.low:
        return 'Baja';
      case TaskPriority.medium:
        return 'Media';
      case TaskPriority.high:
        return 'Alta';
      case TaskPriority.urgent:
        return 'Urgente';
    }
  }

  String get typeLabel {
    switch (type) {
      case TaskType.assignment:
        return 'Entrega';
      case TaskType.exam:
        return 'Examen';
      case TaskType.classType:
        return 'Clase';
      case TaskType.project:
        return 'Proyecto';
      case TaskType.event:
        return 'Evento';
    }
  }

  bool get isLate {
    if (status == TaskStatus.completed) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today);
  }

  DueInfo get dueInfo {
    if (status == TaskStatus.completed) {
      return const DueInfo(
        text: '✓ Completada',
        color: Color(0xFF496B4B),
        backgroundColor: Color(0xFFE4EFE3),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diffDays = due.difference(today).inDays;

    if (diffDays < 0) {
      final lateDays = diffDays.abs();
      if (lateDays == 1) {
        return const DueInfo(
          text: '🔴 Atrasada ayer',
          color: Color(0xFFC04E3D),
          backgroundColor: Color(0xFFFDE8E5),
        );
      }
      return DueInfo(
        text: '🔴 Atrasada $lateDays días',
        color: const Color(0xFFC04E3D),
        backgroundColor: const Color(0xFFFDE8E5),
      );
    } else if (diffDays == 0) {
      return const DueInfo(
        text: '🟠 Hoy',
        color: Color(0xFFD47C35),
        backgroundColor: Color(0xFFFDF0E2),
      );
    } else if (diffDays == 1) {
      return const DueInfo(
        text: '🟠 Mañana',
        color: Color(0xFFD47C35),
        backgroundColor: Color(0xFFFDF0E2),
      );
    } else if (diffDays <= 3) {
      return DueInfo(
        text: '🟡 Quedan $diffDays días',
        color: const Color(0xFFB58E29),
        backgroundColor: const Color(0xFFFDF7E2),
      );
    } else {
      return DueInfo(
        text: '🌿 Quedan $diffDays días',
        color: const Color(0xFF517D5B),
        backgroundColor: const Color(0xFFEAF4E8),
      );
    }
  }

  Task copyWith({
    String? id,
    String? title,
    String? subjectId,
    TaskStatus? status,
    TaskPriority? priority,
    TaskType? type,
    DateTime? dueDate,
    DateTime? startDate,
    DateTime? completedAt,
    String? description,
    String? notes,
    List<String>? links,
    List<String>? files,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      subjectId: subjectId ?? this.subjectId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      completedAt: completedAt ?? this.completedAt,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      links: links ?? this.links,
      files: files ?? this.files,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subjectId': subjectId,
        'status': status.name,
        'priority': priority.name,
        'type': type.name,
        'dueDate': dueDate.toIso8601String(),
        'startDate': startDate?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'description': description,
        'notes': notes,
        'links': links,
        'files': files,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        subjectId: json['subjectId'] as String,
        status: TaskStatus.values.firstWhere(
          (s) => s.name == (json['status'] as String),
          orElse: () => TaskStatus.todo,
        ),
        priority: TaskPriority.values.firstWhere(
          (p) => p.name == (json['priority'] as String),
          orElse: () => TaskPriority.medium,
        ),
        type: TaskType.values.firstWhere(
          (t) => t.name == (json['type'] as String),
          orElse: () => TaskType.assignment,
        ),
        dueDate: DateTime.parse(json['dueDate'] as String),
        startDate: json['startDate'] != null
            ? DateTime.tryParse(json['startDate'] as String)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
        description: json['description'] as String?,
        notes: json['notes'] as String?,
        links: (json['links'] as List<dynamic>?)?.map((e) => e as String).toList() ??
            const [],
        files: (json['files'] as List<dynamic>?)?.map((e) => e as String).toList() ??
            const [],
      );
}
