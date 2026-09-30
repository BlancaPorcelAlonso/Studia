enum AbsenceStatus { pending, justified, unjustified }

class SubjectAbsence {
  const SubjectAbsence({
    required this.id,
    required this.subjectId,
    required this.date,
    this.status = AbsenceStatus.pending,
    this.note,
  });

  final String id;
  final String subjectId;
  final DateTime date;
  final AbsenceStatus status;
  final String? note;

  SubjectAbsence copyWith({
    String? id,
    String? subjectId,
    DateTime? date,
    AbsenceStatus? status,
    String? note,
  }) =>
      SubjectAbsence(
        id: id ?? this.id,
        subjectId: subjectId ?? this.subjectId,
        date: date ?? this.date,
        status: status ?? this.status,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'date': date.toIso8601String(),
        'status': status.name,
        'note': note,
      };

  factory SubjectAbsence.fromJson(Map<String, dynamic> json) => SubjectAbsence(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        date: DateTime.parse(json['date'] as String),
        status: AbsenceStatus.values.firstWhere(
          (status) => status.name == json['status'],
          orElse: () => AbsenceStatus.pending,
        ),
        note: json['note'] as String?,
      );
}

enum GradeType { activity, exam }

class SubjectGrade {
  const SubjectGrade({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.type,
    required this.score,
    required this.maxScore,
    required this.date,
  });

  final String id;
  final String subjectId;
  final String title;
  final GradeType type;
  final double score;
  final double maxScore;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'title': title,
        'type': type.name,
        'score': score,
        'maxScore': maxScore,
        'date': date.toIso8601String(),
      };

  factory SubjectGrade.fromJson(Map<String, dynamic> json) => SubjectGrade(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        title: json['title'] as String,
        type: GradeType.values.firstWhere(
          (type) => type.name == json['type'],
          orElse: () => GradeType.activity,
        ),
        score: (json['score'] as num).toDouble(),
        maxScore: (json['maxScore'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
      );
}
