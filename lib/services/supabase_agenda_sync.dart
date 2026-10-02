import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class AgendaSnapshot {
  const AgendaSnapshot({
    required this.subjects,
    required this.tasks,
    required this.exams,
    required this.notes,
    required this.deliverables,
    required this.absences,
    required this.grades,
  });

  final List<Subject> subjects;
  final List<Task> tasks;
  final List<Exam> exams;
  final List<StudyNote> notes;
  final List<Deliverable> deliverables;
  final List<SubjectAbsence> absences;
  final List<SubjectGrade> grades;
}

class SupabaseAgendaSync {
  SupabaseAgendaSync(this.client, this.userId);

  final SupabaseClient client;
  final String userId;

  Future<List<Map<String, dynamic>>> _rows(String table) async {
    final result = await client.from(table).select().eq('user_id', userId);
    return List<Map<String, dynamic>>.from(result);
  }

  Future<AgendaSnapshot> load() async {
    final subjectRows = await _rows('subjects');
    final scheduleRows = await _rows('class_schedules');
    final schedules = <String, List<ClassSchedule>>{};
    for (final row in scheduleRows) {
      schedules.putIfAbsent(row['subject_id'] as String, () => []).add(
            ClassSchedule(
              weekday: row['weekday'] as int,
              startMinutes: row['start_minutes'] as int,
              durationMinutes: row['duration_minutes'] as int,
            ),
          );
    }
    final subjects = subjectRows
        .map((row) => Subject(
              id: row['id'] as String,
              name: row['name'] as String,
              emoji: row['emoji'] as String? ?? '🌿',
              colorValue: (row['color_value'] as num?)?.toInt() ?? 0xFF7EA98B,
              teacher: row['teacher'] as String?,
              classroom: row['classroom'] as String?,
              schedule: row['schedule'] as String?,
              schedules: schedules[row['id']] ?? const [],
              notes: row['notes'] as String?,
              lastStudyNote: row['last_study_note'] as String?,
              lastStudyAt: _optionalDate(row['last_study_at']),
            ))
        .toList();

    final taskRows = await _rows('tasks');
    final taskLinks = await _rows('task_links');
    final taskAttachments = await _rows('task_attachments');
    final linksByTask = _group(taskLinks, 'task_id', 'url');
    final filesByTask = _group(taskAttachments, 'task_id', 'name');
    final tasks = taskRows
        .map((row) => Task(
              id: row['id'] as String,
              title: row['title'] as String,
              subjectId: row['subject_id'] as String,
              status:
                  _enumValue(TaskStatus.values, row['status'], TaskStatus.todo),
              priority: _enumValue(
                  TaskPriority.values, row['priority'], TaskPriority.medium),
              type:
                  _enumValue(TaskType.values, row['type'], TaskType.assignment),
              dueDate: _date(row['due_date']),
              startDate: _optionalDate(row['start_date']),
              completedAt: _optionalDate(row['completed_at']),
              description: row['description'] as String?,
              notes: row['notes'] as String?,
              links: linksByTask[row['id']] ?? const [],
              files: filesByTask[row['id']] ?? const [],
              linkedExamId: row['linked_exam_id'] as String?,
              linkedDeliverableId: row['linked_deliverable_id'] as String?,
            ))
        .toList();

    final examRows = await _rows('exams');
    final topicRows = await _rows('exam_topics');
    final topics = <String, List<Map<String, dynamic>>>{};
    for (final row in topicRows) {
      topics.putIfAbsent(row['exam_id'] as String, () => []).add(row);
    }
    for (final list in topics.values) {
      list.sort(
          (a, b) => (a['position'] as int).compareTo(b['position'] as int));
    }
    final exams = examRows
        .map((row) => Exam(
              id: row['id'] as String,
              name: row['name'] as String,
              subjectId: row['subject_id'] as String,
              date: _date(row['exam_date']),
              time: row['exam_time'] as String,
              classroom: row['classroom'] as String,
              state: _enumValue(
                  ExamState.values, row['state'], ExamState.notStarted),
              notes: row['notes'] as String?,
              topics: (topics[row['id']] ?? const [])
                  .map((topic) => ExamTopic(
                        title: topic['title'] as String,
                        isCompleted: topic['is_completed'] as bool,
                      ))
                  .toList(),
              linkedNoteIds: (row['linked_note_ids'] as List<dynamic>?)
                      ?.map((e) => e as String)
                      .toList() ??
                  const [],
            ))
        .toList();

    final noteRows = await _rows('study_notes');
    final checkRows = await _rows('note_check_items');
    final tagRows = await _rows('note_tags');
    final attachmentRows = await _rows('note_attachments');
    final checks = <String, List<Map<String, dynamic>>>{};
    for (final row in checkRows) {
      checks.putIfAbsent(row['note_id'] as String, () => []).add(row);
    }
    for (final list in checks.values) {
      list.sort(
          (a, b) => (a['position'] as int).compareTo(b['position'] as int));
    }
    final tags = _group(tagRows, 'note_id', 'tag');
    final attachments = <String, List<NoteAttachment>>{};
    for (final row in attachmentRows) {
      var bytesBase64 = '';
      try {
        final bytes = await client.storage
            .from('agenda-attachments')
            .download(row['storage_path'] as String);
        bytesBase64 = base64Encode(bytes);
      } catch (_) {
        // Keep the note available if an attachment is missing from Storage.
      }
      attachments.putIfAbsent(row['note_id'] as String, () => []).add(
            NoteAttachment(
              name: row['name'] as String,
              bytesBase64: bytesBase64,
              sizeBytes: (row['size_bytes'] as num?)?.toInt() ?? 0,
              mimeType: row['mime_type'] as String?,
            ),
          );
    }
    final notes = noteRows
        .map((row) => StudyNote(
              id: row['id'] as String,
              subjectId: row['subject_id'] as String,
              title: row['title'] as String,
              topic: row['topic'] as String,
              category: row['category'] as String,
              content: row['content'] as String,
              updatedAt: _date(row['updated_at']),
              tags: tags[row['id']] ?? const [],
              checklist: (checks[row['id']] ?? const [])
                  .map((item) => NoteCheckItem(
                        text: item['text'] as String,
                        isChecked: item['is_checked'] as bool,
                      ))
                  .toList(),
              attachments: attachments[row['id']] ?? const [],
            ))
        .toList();

    final deliverables = (await _rows('deliverables'))
        .map((row) => Deliverable(
              id: row['id'] as String,
              subjectId: row['subject_id'] as String,
              title: row['title'] as String,
              date: _date(row['due_date']),
              description: row['description'] as String?,
              isSubmitted: row['is_submitted'] as bool,
            ))
        .toList();
    final absences = (await _rows('subject_absences'))
        .map((row) => SubjectAbsence(
              id: row['id'] as String,
              subjectId: row['subject_id'] as String,
              date: _date(row['absence_date']),
              status: _enumValue(
                  AbsenceStatus.values, row['status'], AbsenceStatus.pending),
              note: row['note'] as String?,
            ))
        .toList();
    final grades = (await _rows('subject_grades'))
        .map((row) => SubjectGrade(
              id: row['id'] as String,
              subjectId: row['subject_id'] as String,
              title: row['title'] as String,
              type:
                  _enumValue(GradeType.values, row['type'], GradeType.activity),
              score: (row['score'] as num).toDouble(),
              maxScore: (row['max_score'] as num).toDouble(),
              date: _date(row['grade_date']),
            ))
        .toList();

    return AgendaSnapshot(
      subjects: subjects,
      tasks: tasks,
      exams: exams,
      notes: notes,
      deliverables: deliverables,
      absences: absences,
      grades: grades,
    );
  }

  Future<void> saveSubjects(List<Subject> subjects) async {
    for (final subject in subjects) {
      await client.from('subjects').upsert({
        'id': subject.id,
        'user_id': userId,
        'name': subject.name,
        'emoji': subject.emoji,
        'color_value': subject.colorValue,
        'teacher': subject.teacher,
        'classroom': subject.classroom,
        'schedule': subject.schedule,
        'notes': subject.notes,
        'last_study_note': subject.lastStudyNote,
        'last_study_at': subject.lastStudyAt?.toIso8601String(),
      });
      await _replaceChildren(
        'class_schedules',
        'subject_id',
        subject.id,
        subject.schedules
            .asMap()
            .entries
            .map((entry) => {
                  'id': '${subject.id}-schedule-${entry.key}',
                  'user_id': userId,
                  'subject_id': subject.id,
                  'weekday': entry.value.weekday,
                  'start_minutes': entry.value.startMinutes,
                  'duration_minutes': entry.value.durationMinutes,
                })
            .toList(),
      );
    }
  }

  Future<void> saveTasks(List<Task> tasks) async {
    for (final task in tasks) {
      await client.from('tasks').upsert({
        'id': task.id,
        'user_id': userId,
        'subject_id': task.subjectId,
        'title': task.title,
        'status': task.status.name,
        'priority': task.priority.name,
        'type': task.type.name,
        'due_date': task.dueDate.toIso8601String(),
        'start_date': task.startDate?.toIso8601String(),
        'completed_at': task.completedAt?.toIso8601String(),
        'description': task.description,
        'notes': task.notes,
        'linked_exam_id': task.linkedExamId,
        'linked_deliverable_id': task.linkedDeliverableId,
      });
      await _replaceChildren(
        'task_links',
        'task_id',
        task.id,
        task.links
            .asMap()
            .entries
            .map((entry) => {
                  'id': '${task.id}-link-${entry.key}',
                  'user_id': userId,
                  'task_id': task.id,
                  'url': entry.value,
                  'position': entry.key,
                })
            .toList(),
      );
      await _replaceChildren(
        'task_attachments',
        'task_id',
        task.id,
        task.files
            .asMap()
            .entries
            .map((entry) => {
                  'id': '${task.id}-file-${entry.key}',
                  'user_id': userId,
                  'task_id': task.id,
                  'name': entry.value.split(RegExp(r'[/\\]')).last,
                  'storage_path': entry.value,
                })
            .toList(),
      );
    }
  }

  Future<void> saveExams(List<Exam> exams) async {
    for (final exam in exams) {
      await client.from('exams').upsert({
        'id': exam.id,
        'user_id': userId,
        'subject_id': exam.subjectId,
        'name': exam.name,
        'exam_date': _dateString(exam.date),
        'exam_time': exam.time,
        'classroom': exam.classroom,
        'state': exam.state.name,
        'notes': exam.notes,
        'linked_note_ids': exam.linkedNoteIds,
      });
      await _replaceChildren(
        'exam_topics',
        'exam_id',
        exam.id,
        exam.topics
            .asMap()
            .entries
            .map((entry) => {
                  'id': '${exam.id}-topic-${entry.key}',
                  'user_id': userId,
                  'exam_id': exam.id,
                  'title': entry.value.title,
                  'is_completed': entry.value.isCompleted,
                  'position': entry.key,
                })
            .toList(),
      );
    }
  }

  Future<void> saveNotes(List<StudyNote> notes) async {
    for (final note in notes) {
      await client.from('study_notes').upsert({
        'id': note.id,
        'user_id': userId,
        'subject_id': note.subjectId,
        'title': note.title,
        'topic': note.topic,
        'category': note.category,
        'content': note.content,
        'updated_at': note.updatedAt.toIso8601String(),
      });
      await _replaceChildren(
        'note_check_items',
        'note_id',
        note.id,
        note.checklist
            .asMap()
            .entries
            .map((entry) => {
                  'id': '${note.id}-check-${entry.key}',
                  'user_id': userId,
                  'note_id': note.id,
                  'text': entry.value.text,
                  'is_checked': entry.value.isChecked,
                  'position': entry.key,
                })
            .toList(),
      );
      await _replaceTags(note);
      final attachmentRows = <Map<String, dynamic>>[];
      for (var index = 0; index < note.attachments.length; index++) {
        final attachment = note.attachments[index];
        if (attachment.bytesBase64.isEmpty) continue;
        final safeName =
            attachment.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final path = '$userId/notes/${note.id}/$index-$safeName';
        await client.storage.from('agenda-attachments').uploadBinary(
              path,
              base64Decode(attachment.bytesBase64),
              fileOptions: FileOptions(
                upsert: true,
                contentType: attachment.mimeType,
              ),
            );
        attachmentRows.add({
          'id': '${note.id}-attachment-$index',
          'user_id': userId,
          'note_id': note.id,
          'name': attachment.name,
          'storage_path': path,
          'size_bytes': attachment.sizeBytes,
          'mime_type': attachment.mimeType,
        });
      }
      await _replaceChildren(
          'note_attachments', 'note_id', note.id, attachmentRows);
    }
  }

  Future<void> saveDeliverables(List<Deliverable> items) async {
    for (final item in items) {
      await client.from('deliverables').upsert({
        'id': item.id,
        'user_id': userId,
        'subject_id': item.subjectId,
        'title': item.title,
        'due_date': item.date.toIso8601String(),
        'description': item.description,
        'is_submitted': item.isSubmitted,
      });
    }
  }

  Future<void> saveAbsences(List<SubjectAbsence> items) async {
    for (final item in items) {
      await client.from('subject_absences').upsert({
        'id': item.id,
        'user_id': userId,
        'subject_id': item.subjectId,
        'absence_date': _dateString(item.date),
        'status': item.status.name,
        'note': item.note,
      });
    }
  }

  Future<void> saveGrades(List<SubjectGrade> items) async {
    for (final item in items) {
      await client.from('subject_grades').upsert({
        'id': item.id,
        'user_id': userId,
        'subject_id': item.subjectId,
        'title': item.title,
        'type': item.type.name,
        'score': item.score,
        'max_score': item.maxScore,
        'grade_date': _dateString(item.date),
      });
    }
  }

  Future<void> delete(String table, String id) async {
    await client.from(table).delete().eq('user_id', userId).eq('id', id);
  }

  Future<void> resetAll() async {
    for (final table in [
      'subjects',
      'tasks',
      'exams',
      'study_notes',
      'deliverables',
      'subject_absences',
      'subject_grades',
    ]) {
      await client.from(table).delete().eq('user_id', userId);
    }
  }

  Future<void> _replaceChildren(
    String table,
    String parentColumn,
    String parentId,
    List<Map<String, dynamic>> rows,
  ) async {
    final existing = await client
        .from(table)
        .select('id')
        .eq('user_id', userId)
        .eq(parentColumn, parentId);
    final wantedIds = rows.map((row) => row['id']).toSet();
    final staleIds = List<String>.from(existing
        .map((row) => row['id'] as String)
        .where((id) => !wantedIds.contains(id)));
    if (staleIds.isNotEmpty) {
      await client
          .from(table)
          .delete()
          .eq('user_id', userId)
          .inFilter('id', staleIds);
    }
    if (rows.isNotEmpty) await client.from(table).upsert(rows);
  }

  Future<void> _replaceTags(StudyNote note) async {
    await client
        .from('note_tags')
        .delete()
        .eq('user_id', userId)
        .eq('note_id', note.id);
    if (note.tags.isNotEmpty) {
      await client.from('note_tags').insert(note.tags
          .map((tag) => {
                'user_id': userId,
                'note_id': note.id,
                'tag': tag,
              })
          .toList());
    }
  }

  Map<String, List<String>> _group(
    List<Map<String, dynamic>> rows,
    String parentKey,
    String valueKey,
  ) {
    final result = <String, List<String>>{};
    for (final row in rows) {
      result
          .putIfAbsent(row[parentKey] as String, () => [])
          .add(row[valueKey] as String);
    }
    return result;
  }

  static T _enumValue<T extends Enum>(
      List<T> values, Object? value, T fallback) {
    for (final option in values) {
      if (option.name == value) return option;
    }
    return fallback;
  }

  static DateTime _date(Object? value) =>
      DateTime.parse(value.toString()).toLocal();

  static DateTime? _optionalDate(Object? value) =>
      value == null ? null : _date(value);

  static String _dateString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
