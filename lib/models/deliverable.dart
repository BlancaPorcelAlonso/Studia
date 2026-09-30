class Deliverable {
  const Deliverable({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.date,
    this.description,
    this.isSubmitted = false,
  });

  final String id;
  final String subjectId;
  final String title;
  final DateTime date;
  final String? description;
  final bool isSubmitted;

  Deliverable copyWith({
    String? id,
    String? subjectId,
    String? title,
    DateTime? date,
    String? description,
    bool? isSubmitted,
  }) =>
      Deliverable(
        id: id ?? this.id,
        subjectId: subjectId ?? this.subjectId,
        title: title ?? this.title,
        date: date ?? this.date,
        description: description ?? this.description,
        isSubmitted: isSubmitted ?? this.isSubmitted,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'title': title,
        'date': date.toIso8601String(),
        'description': description,
        'isSubmitted': isSubmitted,
      };

  factory Deliverable.fromJson(Map<String, dynamic> json) => Deliverable(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        title: json['title'] as String,
        date: DateTime.parse(json['date'] as String),
        description: json['description'] as String?,
        isSubmitted: json['isSubmitted'] as bool? ?? false,
      );
}
