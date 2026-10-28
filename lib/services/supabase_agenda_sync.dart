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
    List<Map<String, dynamic>> taskCheckRows = const [];
    try {
      taskCheckRows = await _rows('task_check_items');
    } catch (_) {}
    final checksByTask = <String, List<Map<String, dynamic>>>{};
    for (final row in taskCheckRows) {
      checksByTask.putIfAbsent(row['task_id'] as String, () => []).add(row);
    }
    for (final list in checksByTask.values) {
      list.sort(
          (a, b) => (a['position'] as int).compareTo(b['position'] as int));
    }
    final linksByTask = _group(taskLinks, 'task_id', 'url');
    final filesByTask = _group(taskAttachments, 'task_id', 'storage_path');
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
              checklist: (checksByTask[row['id']] ?? const [])
                  .map((c) => TaskCheckItem(
                        id: c['id'] as String,
                        text: c['text'] as String,
                        isChecked: c['is_checked'] as bool? ?? false,
                      ))
                  .toList(),
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
      attachments.putIfAbsent(row['note_id'] as String, () => []).add(
            NoteAttachment(
              name: row['name'] as String,
              bytesBase64: '',
              sizeBytes: (row['size_bytes'] as num?)?.toInt() ?? 0,
              mimeType: row['mime_type'] as String?,
              storagePath: row['storage_path'] as String,
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

    List<Map<String, dynamic>> deliverableAttachmentRows = const [];
    try {
      deliverableAttachmentRows = await _rows('deliverable_attachments');
    } catch (_) {}
    final deliverableAttachments = <String, List<Map<String, dynamic>>>{};
    for (final row in deliverableAttachmentRows) {
      deliverableAttachments
          .putIfAbsent(row['deliverable_id'] as String, () => [])
          .add(row);
    }

    final deliverables = (await _rows('deliverables'))
        .map((row) => Deliverable(
              id: row['id'] as String,
              subjectId: row['subject_id'] as String,
              title: row['title'] as String,
              date: _date(row['due_date']),
              description: row['description'] as String?,
              isSubmitted: row['is_submitted'] as bool,
              attachments: (deliverableAttachments[row['id'] as String] ??
                      const <Map<String, dynamic>>[])
                  .map((attachment) => NoteAttachment(
                        name: attachment['name'] as String,
                        bytesBase64: '',
                        sizeBytes:
                            (attachment['size_bytes'] as num?)?.toInt() ?? 0,
                        mimeType: attachment['mime_type'] as String?,
                        storagePath: attachment['storage_path'] as String,
                      ))
                  .toList(),
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

  Future<void> migrateLocalNotes(
    List<StudyNote> localNotes,
    List<Subject> localSubjects,
  ) async {
    if (localNotes.isEmpty) return;

    final subjectRows = await _rows('subjects');
    final subjectIds = subjectRows.map((row) => row['id'] as String).toSet();
    final localSubjectsById = {
      for (final subject in localSubjects) subject.id: subject,
    };
    final subjectIdMap = <String, String>{};
    final missingSubjectIds = localNotes
        .map((note) => note.subjectId)
        .where((id) => !subjectIds.contains(id))
        .toSet();
    for (final subjectId in missingSubjectIds) {
      final localSubject = localSubjectsById[subjectId];
      if (localSubject == null) {
        throw StateError(
          'No se encontró una asignatura local necesaria para migrar un apunte.',
        );
      }
      try {
        await saveSubjects([localSubject]);
        subjectIds.add(subjectId);
      } catch (error) {
        if (!_isDuplicateKey(error)) rethrow;
        var suffix = 0;
        while (true) {
          final candidateId =
              '${subjectId}_local_migration_$userId${suffix == 0 ? '' : '_$suffix'}';
          if (subjectIds.contains(candidateId)) {
            subjectIdMap[subjectId] = candidateId;
            break;
          }
          try {
            await saveSubjects([localSubject.copyWith(id: candidateId)]);
            subjectIds.add(candidateId);
            subjectIdMap[subjectId] = candidateId;
            break;
          } catch (candidateError) {
            if (!_isDuplicateKey(candidateError)) rethrow;
            suffix++;
          }
        }
      }
    }

    final rows = await _rows('study_notes');
    final rowsById = {for (final row in rows) row['id'] as String: row};
    noteLoop:
    for (final sourceNote in localNotes) {
      final localNote = sourceNote.copyWith(
        subjectId: subjectIdMap[sourceNote.subjectId] ?? sourceNote.subjectId,
      );
      var destination = localNote;
      final existing = rowsById[localNote.id];
      DateTime? expectedUpdatedAt;
      var insertOnly = existing == null;
      if (existing != null) {
        final cloudUpdatedAt = _date(existing['updated_at']);
        if (_sameNoteContent(existing, localNote)) {
          if (localNote.updatedAt.isAfter(cloudUpdatedAt)) {
            expectedUpdatedAt = cloudUpdatedAt;
            insertOnly = false;
          } else if (localNote.updatedAt.isBefore(cloudUpdatedAt) ||
              await _matchesNote(localNote)) {
            continue noteLoop;
          } else {
            expectedUpdatedAt = cloudUpdatedAt;
            insertOnly = false;
          }
        } else if (localNote.updatedAt.isAfter(cloudUpdatedAt)) {
          expectedUpdatedAt = cloudUpdatedAt;
          insertOnly = false;
        } else {
          var suffix = 1;
          while (true) {
            final candidateId =
                '${localNote.id}_local_migration_${userId}_$suffix';
            final candidate = rowsById[candidateId];
            if (candidate == null) {
              destination = localNote.copyWith(id: candidateId);
              insertOnly = true;
              break;
            }
            if (_sameNoteContent(candidate, localNote)) {
              final candidateUpdatedAt = _date(candidate['updated_at']);
              if (candidateUpdatedAt.isAfter(localNote.updatedAt) ||
                  (candidateUpdatedAt == localNote.updatedAt &&
                      await _matchesNote(
                        localNote.copyWith(id: candidateId),
                      ))) {
                continue noteLoop;
              }
              destination = localNote.copyWith(
                id: candidateId,
                updatedAt: candidateUpdatedAt,
              );
              expectedUpdatedAt = candidateUpdatedAt;
              insertOnly = false;
              break;
            }
            suffix++;
          }
        }
      }

      try {
        await saveNote(
          destination,
          expectedUpdatedAt: expectedUpdatedAt,
          insertOnly: insertOnly,
        );
      } catch (error) {
        if (!_isDuplicateKey(error) || expectedUpdatedAt != null) rethrow;
        var suffix = 0;
        while (true) {
          final candidateId =
              '${localNote.id}_local_migration_$userId${suffix == 0 ? '' : '_$suffix'}';
          final candidate = rowsById[candidateId];
          if (candidate != null && _sameNoteContent(candidate, localNote)) {
            destination = localNote.copyWith(
              id: candidateId,
              updatedAt: _date(candidate['updated_at']),
            );
            expectedUpdatedAt = _date(candidate['updated_at']);
            await saveNote(
              destination,
              expectedUpdatedAt: expectedUpdatedAt,
            );
            break;
          }
          if (candidate == null) {
            destination = localNote.copyWith(id: candidateId);
            try {
              await saveNote(destination, insertOnly: true);
              break;
            } catch (candidateError) {
              if (!_isDuplicateKey(candidateError)) rethrow;
            }
          }
          suffix++;
        }
      }
      rowsById[destination.id] = {
        'id': destination.id,
        'subject_id': destination.subjectId,
        'title': destination.title,
        'topic': destination.topic,
        'category': destination.category,
        'content': destination.content,
        'updated_at': destination.updatedAt.toIso8601String(),
      };
    }
  }

  bool _isDuplicateKey(Object error) =>
      error is PostgrestException && error.code == '23505';

  Future<bool> _matchesNote(StudyNote note) async {
    try {
      await _verifyNote(note);
      return true;
    } on StateError {
      return false;
    }
  }

  bool _sameNoteContent(Map<String, dynamic> row, StudyNote note) =>
      row['subject_id'] == note.subjectId &&
      row['title'] == note.title &&
      row['topic'] == note.topic &&
      row['category'] == note.category &&
      row['content'] == note.content;

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
                  'id': '$userId-${subject.id}-schedule-${entry.key}',
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
      final taskRow = {
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
      };
      try {
        await client.from('tasks').upsert(taskRow);
      } on PostgrestException catch (error) {
        final missingDeliverableColumn = error.code == 'PGRST204' &&
            error.message.contains(
              "Could not find the 'linked_deliverable_id' column of 'tasks'",
            );
        if (!missingDeliverableColumn || task.linkedDeliverableId != null) {
          rethrow;
        }
        taskRow.remove('linked_deliverable_id');
        await client.from('tasks').upsert(taskRow);
      }
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
      try {
        await _replaceChildren(
          'task_check_items',
          'task_id',
          task.id,
          task.checklist
              .asMap()
              .entries
              .map((entry) => {
                    'id': entry.value.id.isNotEmpty
                        ? entry.value.id
                        : '${task.id}-check-${entry.key}',
                    'user_id': userId,
                    'task_id': task.id,
                    'text': entry.value.text,
                    'is_checked': entry.value.isChecked,
                    'position': entry.key,
                  })
              .toList(),
        );
      } catch (_) {
        // Ignored if table hasn't been migrated yet
      }
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
      await saveNote(note);
    }
  }

  Future<void> saveNote(
    StudyNote note, {
    DateTime? expectedUpdatedAt,
    bool insertOnly = false,
  }) async {
    final values = {
      'user_id': userId,
      'subject_id': note.subjectId,
      'title': note.title,
      'topic': note.topic,
      'category': note.category,
      'content': note.content,
      'updated_at': note.updatedAt.toIso8601String(),
    };
    final Map<String, dynamic>? saved;
    if (expectedUpdatedAt != null) {
      saved = await client
          .from('study_notes')
          .update(values)
          .eq('user_id', userId)
          .eq('id', note.id)
          .eq('updated_at', expectedUpdatedAt.toIso8601String())
          .select('id, user_id, subject_id, title, topic, category, content')
          .maybeSingle();
      if (saved == null) {
        throw StateError(
          'El apunte "${note.title}" cambió en otro dispositivo. '
          'Vuelve a cargarlo antes de guardar para no sobrescribir cambios.',
        );
      }
    } else if (insertOnly) {
      saved = await client
          .from('study_notes')
          .insert({'id': note.id, ...values})
          .select('id, user_id, subject_id, title, topic, category, content')
          .maybeSingle();
    } else {
      saved = await client
          .from('study_notes')
          .upsert({'id': note.id, ...values})
          .select('id, user_id, subject_id, title, topic, category, content')
          .maybeSingle();
    }
    if (saved == null ||
        saved['id'] != note.id ||
        saved['user_id'] != userId ||
        saved['subject_id'] != note.subjectId ||
        saved['title'] != note.title ||
        saved['topic'] != note.topic ||
        saved['category'] != note.category ||
        saved['content'] != note.content) {
      throw StateError(
        'Supabase no confirmó los cambios del apunte "${note.title}".',
      );
    }

    await _replaceChildren(
      'note_check_items',
      'note_id',
      note.id,
      note.checklist
          .asMap()
          .entries
          .map((entry) => {
                'id': '$userId-${note.id}-check-${entry.key}',
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
      var path = attachment.storagePath;
      if (attachment.bytesBase64.isNotEmpty) {
        path = _noteAttachmentPath(note, attachment, index);
        await client.storage.from('agenda-attachments').uploadBinary(
              path,
              base64Decode(attachment.bytesBase64),
              fileOptions: FileOptions(
                upsert: true,
                contentType: attachment.mimeType,
              ),
            );
      }
      if (path == null) {
        throw StateError('No se pudo subir el adjunto "${attachment.name}".');
      }
      if (!path.startsWith('$userId/')) {
        throw StateError(
          'El adjunto "${attachment.name}" no pertenece a esta cuenta.',
        );
      }
      attachmentRows.add({
        'id': '$userId-${note.id}-attachment-$index',
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
    await _verifyNote(note);
  }

  String _noteAttachmentPath(
    StudyNote note,
    NoteAttachment attachment,
    int index,
  ) {
    final safeName =
        attachment.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return '$userId/notes/${note.id}/$index-$safeName';
  }

  Future<void> _verifyNote(StudyNote note) async {
    final row = await client
        .from('study_notes')
        .select(
          'id, user_id, subject_id, title, topic, category, content, updated_at',
        )
        .eq('user_id', userId)
        .eq('id', note.id)
        .maybeSingle();
    if (row == null) {
      throw StateError('No se encontró el apunte "${note.title}" en Supabase.');
    }
    if (row['user_id'] != userId ||
        !_sameNoteContent(row, note) ||
        row['title'] != note.title ||
        row['topic'] != note.topic ||
        _date(row['updated_at']) != note.updatedAt) {
      throw StateError('No se pudo verificar el apunte "${note.title}".');
    }

    final checkRows = await client
        .from('note_check_items')
        .select('text, is_checked, position')
        .eq('user_id', userId)
        .eq('note_id', note.id)
        .order('position');
    if (checkRows.length != note.checklist.length) {
      throw StateError('No se pudo verificar el checklist de "${note.title}".');
    }
    for (var index = 0; index < note.checklist.length; index++) {
      final item = note.checklist[index];
      final saved = checkRows[index];
      if (saved['text'] != item.text ||
          saved['is_checked'] != item.isChecked ||
          saved['position'] != index) {
        throw StateError(
          'No se pudo verificar el checklist de "${note.title}".',
        );
      }
    }

    final tagRows = await client
        .from('note_tags')
        .select('tag')
        .eq('user_id', userId)
        .eq('note_id', note.id);
    final savedTags = tagRows.map((row) => row['tag'] as String).toSet();
    if (savedTags.length != note.tags.toSet().length ||
        !savedTags.containsAll(note.tags)) {
      throw StateError('No se pudieron verificar las etiquetas del apunte.');
    }

    final attachmentRows = await client
        .from('note_attachments')
        .select('id, name, storage_path, size_bytes, mime_type')
        .eq('user_id', userId)
        .eq('note_id', note.id)
        .order('id');
    if (attachmentRows.length != note.attachments.length) {
      throw StateError('No se pudieron verificar los adjuntos del apunte.');
    }
    final attachmentsById = {
      for (final row in attachmentRows) row['id'] as String: row,
    };
    for (var index = 0; index < note.attachments.length; index++) {
      final attachment = note.attachments[index];
      final saved = attachmentsById['$userId-${note.id}-attachment-$index'];
      final expectedPath = attachment.bytesBase64.isNotEmpty
          ? _noteAttachmentPath(note, attachment, index)
          : attachment.storagePath;
      if (saved == null ||
          saved['name'] != attachment.name ||
          saved['storage_path'] != expectedPath ||
          (saved['size_bytes'] as num?)?.toInt() != attachment.sizeBytes ||
          saved['mime_type'] != attachment.mimeType) {
        throw StateError('No se pudieron verificar los adjuntos del apunte.');
      }
    }
  }

  Future<void> deleteNote(String noteId) async {
    final rows = await client
        .from('study_notes')
        .delete()
        .eq('user_id', userId)
        .eq('id', noteId)
        .select('id');
    if (rows.isEmpty) {
      throw StateError('Supabase no confirmó la eliminación del apunte.');
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
      final attachmentRows = <Map<String, dynamic>>[];
      for (var index = 0; index < item.attachments.length; index++) {
        final attachment = item.attachments[index];
        var path = attachment.storagePath;
        if (attachment.bytesBase64.isNotEmpty) {
          final safeName =
              attachment.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
          path = '$userId/deliverables/${item.id}/$index-$safeName';
          await client.storage.from('agenda-attachments').uploadBinary(
                path,
                base64Decode(attachment.bytesBase64),
                fileOptions: FileOptions(
                  upsert: true,
                  contentType: attachment.mimeType,
                ),
              );
        }
        if (path == null) continue;
        attachmentRows.add({
          'id': '${item.id}-attachment-$index',
          'user_id': userId,
          'deliverable_id': item.id,
          'name': attachment.name,
          'storage_path': path,
          'size_bytes': attachment.sizeBytes,
          'mime_type': attachment.mimeType,
        });
      }
      await _replaceChildren(
          'deliverable_attachments', 'deliverable_id', item.id, attachmentRows);
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

  Future<int> loadPracticeMinutes(int initialMinutes) async {
    final result = await client.rpc(
      'get_or_create_practice_hours',
      params: {'p_initial_minutes': initialMinutes},
    );
    if (result is! num) {
      throw FormatException('Respuesta inválida al cargar horas de prácticas.');
    }
    return result.toInt();
  }

  Future<int> addPracticeMinutes(int minutes) async {
    final result = await client.rpc(
      'add_practice_minutes',
      params: {'p_minutes': minutes},
    );
    if (result is! num) {
      throw FormatException(
          'Respuesta inválida al guardar horas de prácticas.');
    }
    return result.toInt();
  }

  Future<void> delete(String table, String id) async {
    await client.from(table).delete().eq('user_id', userId).eq('id', id);
  }

  Future<void> resetAll() async {
    for (final table in [
      'subjects',
      'tasks',
      'task_check_items',
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
          .add(row[valueKey] as String? ?? row['name'] as String);
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
