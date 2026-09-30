class NoteCheckItem {
  const NoteCheckItem({
    required this.text,
    this.isChecked = false,
  });

  final String text;
  final bool isChecked;

  NoteCheckItem copyWith({
    String? text,
    bool? isChecked,
  }) {
    return NoteCheckItem(
      text: text ?? this.text,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'isChecked': isChecked,
      };

  factory NoteCheckItem.fromJson(Map<String, dynamic> json) => NoteCheckItem(
        text: json['text'] as String,
        isChecked: json['isChecked'] as bool? ?? false,
      );
}

class NoteAttachment {
  const NoteAttachment({
    required this.name,
    required this.bytesBase64,
    required this.sizeBytes,
    this.mimeType,
  });

  final String name;
  final String bytesBase64;
  final int sizeBytes;
  final String? mimeType;

  Map<String, dynamic> toJson() => {
        'name': name,
        'bytesBase64': bytesBase64,
        'sizeBytes': sizeBytes,
        'mimeType': mimeType,
      };

  factory NoteAttachment.fromJson(Map<String, dynamic> json) => NoteAttachment(
        name: json['name'] as String,
        bytesBase64: json['bytesBase64'] as String,
        sizeBytes: json['sizeBytes'] as int? ?? 0,
        mimeType: json['mimeType'] as String?,
      );
}

class StudyNote {
  const StudyNote({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.topic,
    required this.category,
    required this.content,
    required this.updatedAt,
    this.tags = const [],
    this.checklist = const [],
    this.attachments = const [],
  });

  final String id;
  final String subjectId;
  final String title;
  final String topic;
  final String category;
  final String content;
  final DateTime updatedAt;
  final List<String> tags;
  final List<NoteCheckItem> checklist;
  final List<NoteAttachment> attachments;

  StudyNote copyWith({
    String? id,
    String? subjectId,
    String? title,
    String? topic,
    String? category,
    String? content,
    DateTime? updatedAt,
    List<String>? tags,
    List<NoteCheckItem>? checklist,
    List<NoteAttachment>? attachments,
  }) {
    return StudyNote(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      category: category ?? this.category,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      checklist: checklist ?? this.checklist,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'title': title,
        'topic': topic,
        'category': category,
        'content': content,
        'updatedAt': updatedAt.toIso8601String(),
        'tags': tags,
        'checklist': checklist.map((item) => item.toJson()).toList(),
        'attachments': attachments.map((item) => item.toJson()).toList(),
      };

  factory StudyNote.fromJson(Map<String, dynamic> json) => StudyNote(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        title: json['title'] as String,
        topic: json['topic'] as String,
        category: json['category'] as String,
        content: json['content'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        checklist: (json['checklist'] as List<dynamic>?)
                ?.map((e) => NoteCheckItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        attachments: (json['attachments'] as List<dynamic>?)
                ?.map((e) => NoteAttachment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
