import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    final dynamic result;
    try {
      result = await client.from(table).select().eq('user_id', userId);
    } catch (error, stackTrace) {
      _logLoadFailure('SELECT public.$table', error, stackTrace);
      rethrow;
    }
    try {
      return List<Map<String, dynamic>>.from(result);
    } catch (error, stackTrace) {
      _logLoadFailure(
          'decode SELECT public.$table response', error, stackTrace);
      rethrow;
    }
  }

  List<T> _convertRows<T>(
    String table,
    List<Map<String, dynamic>> rows,
    T Function(Map<String, dynamic>) convert,
  ) {
    final converted = <T>[];
    for (var index = 0; index < rows.length; index++) {
      try {
        converted.add(convert(rows[index]));
      } catch (error, stackTrace) {
        _logLoadFailure('convert public.$table row $index', error, stackTrace);
        rethrow;
      }
    }
    return converted;
  }

  void _logLoadFailure(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!kDebugMode) return;
    debugPrint('[SupabaseAgendaSync] Failed to $operation: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  Future<AgendaSnapshot> load() async {
    final subjectRows = await _rows('subjects');
    final scheduleRows = await _rows('class_schedules');
    final schedules = <String, List<ClassSchedule>>{};
    final parsedSchedules = _convertRows<ClassSchedule>(
      'class_schedules',
      scheduleRows,
      (row) => ClassSchedule(
        weekday: (row['weekday'] as num).toInt(),
        startMinutes: (row['start_minutes'] as num).toInt(),
        durationMinutes: (row['duration_minutes'] as num).toInt(),
      ),
    );
    for (var index = 0; index < scheduleRows.length; index++) {
      try {
        schedules
            .putIfAbsent(scheduleRows[index]['subject_id'] as String, () => [])
            .add(parsedSchedules[index]);
      } catch (error, stackTrace) {
        _logLoadFailure(
          'group public.class_schedules by subject',
          error,
          stackTrace,
        );
        rethrow;
      }
    }
    final subjects = _convertRows(
      'subjects',
      subjectRows,
      (row) => Subject(
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
      ),
    );

    final taskRows = await _rows('tasks');
    final taskLinks = await _rows('task_links');
    final taskAttachments = await _rows('task_attachments');
    final taskCheckRows = await _rows('task_check_items');
    final checksByTask = <String, List<Map<String, dynamic>>>{};
    for (final row in taskCheckRows) {
      try {
        checksByTask.putIfAbsent(row['task_id'] as String, () => []).add(row);
      } catch (error, stackTrace) {
        _logLoadFailure(
          'group public.task_check_items by task',
          error,
          stackTrace,
        );
        rethrow;
      }
    }
    try {
      for (final list in checksByTask.values) {
        list.sort(
            (a, b) => (a['position'] as num).compareTo(b['position'] as num));
      }
    } catch (error, stackTrace) {
      _logLoadFailure(
        'sort public.task_check_items by position',
        error,
        stackTrace,
      );
      rethrow;
    }
    final linksByTask = _group(
      taskLinks,
      table: 'task_links',
      parentKey: 'task_id',
      valueKey: 'url',
    );
    final filesByTask = _group(
      taskAttachments,
      table: 'task_attachments',
      parentKey: 'task_id',
      valueKey: 'storage_path',
    );
    final tasks = _convertRows(
      'tasks',
      taskRows,
      (row) => Task(
        id: row['id'] as String,
        title: row['title'] as String,
        subjectId: row['subject_id'] as String,
        status: _enumValue(TaskStatus.values, row['status'], TaskStatus.todo),
        priority: _enumValue(
            TaskPriority.values, row['priority'], TaskPriority.medium),
        type: _enumValue(TaskType.values, row['type'], TaskType.assignment),
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
      ),
    );

    final examRows = await _rows('exams');
    final topicRows = await _rows('exam_topics');
    final topics = <String, List<Map<String, dynamic>>>{};
    for (final row in topicRows) {
      try {
        topics.putIfAbsent(row['exam_id'] as String, () => []).add(row);
      } catch (error, stackTrace) {
        _logLoadFailure(
          'group public.exam_topics by exam',
          error,
          stackTrace,
        );
        rethrow;
      }
    }
    try {
      for (final list in topics.values) {
        list.sort(
            (a, b) => (a['position'] as num).compareTo(b['position'] as num));
      }
    } catch (error, stackTrace) {
      _logLoadFailure(
        'sort public.exam_topics by position',
        error,
        stackTrace,
      );
      rethrow;
    }
    final exams = _convertRows(
      'exams',
      examRows,
      (row) => Exam(
        id: row['id'] as String,
        name: row['name'] as String,
        subjectId: row['subject_id'] as String,
        date: _date(row['exam_date']),
        time: row['exam_time'] as String,
        classroom: row['classroom'] as String,
        state: _enumValue(ExamState.values, row['state'], ExamState.notStarted),
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
      ),
    );

    final noteRows = await _rows('study_notes');
    final checkRows = await _rows('note_check_items');
    final tagRows = await _rows('note_tags');
    final attachmentRows = await _rows('note_attachments');
    final checks = <String, List<Map<String, dynamic>>>{};
    for (final row in checkRows) {
      try {
        checks.putIfAbsent(row['note_id'] as String, () => []).add(row);
      } catch (error, stackTrace) {
        _logLoadFailure(
          'group public.note_check_items by note',
          error,
          stackTrace,
        );
        rethrow;
      }
    }
    try {
      for (final list in checks.values) {
        list.sort(
            (a, b) => (a['position'] as num).compareTo(b['position'] as num));
      }
    } catch (error, stackTrace) {
      _logLoadFailure(
        'sort public.note_check_items by position',
        error,
        stackTrace,
      );
      rethrow;
    }
    final tags = _group(
      tagRows,
      table: 'note_tags',
      parentKey: 'note_id',
      valueKey: 'tag',
    );
    final attachments = <String, List<NoteAttachment>>{};
    for (final row in attachmentRows) {
      try {
        attachments.putIfAbsent(row['note_id'] as String, () => []).add(
              NoteAttachment(
                name: row['name'] as String,
                bytesBase64: '',
                sizeBytes: (row['size_bytes'] as num?)?.toInt() ?? 0,
                mimeType: row['mime_type'] as String?,
                storagePath: row['storage_path'] as String,
              ),
            );
      } catch (error, stackTrace) {
        _logLoadFailure(
          'convert/group public.note_attachments',
          error,
          stackTrace,
        );
        rethrow;
      }
    }
    final notes = _convertRows(
      'study_notes',
      noteRows,
      (row) => StudyNote(
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
      ),
    );

    final deliverableAttachmentRows = await _rows('deliverable_attachments');
    final deliverableAttachments = <String, List<Map<String, dynamic>>>{};
    for (final row in deliverableAttachmentRows) {
      try {
        deliverableAttachments
            .putIfAbsent(row['deliverable_id'] as String, () => [])
            .add(row);
      } catch (error, stackTrace) {
        _logLoadFailure(
          'group public.deliverable_attachments by deliverable',
          error,
          stackTrace,
        );
        rethrow;
      }
    }

    final deliverablesRows = await _rows('deliverables');
    final deliverables = _convertRows(
      'deliverables',
      deliverablesRows,
      (row) => Deliverable(
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
                  sizeBytes: (attachment['size_bytes'] as num?)?.toInt() ?? 0,
                  mimeType: attachment['mime_type'] as String?,
                  storagePath: attachment['storage_path'] as String,
                ))
            .toList(),
      ),
    );
    final absencesRows = await _rows('subject_absences');
    final absences = _convertRows(
      'subject_absences',
      absencesRows,
      (row) => SubjectAbsence(
        id: row['id'] as String,
        subjectId: row['subject_id'] as String,
        date: _date(row['absence_date']),
        status: _enumValue(
          AbsenceStatus.values,
          row['status'],
          AbsenceStatus.pending,
        ),
        note: row['note'] as String?,
      ),
    );
    final gradesRows = await _rows('subject_grades');
    final grades = _convertRows(
      'subject_grades',
      gradesRows,
      (row) => SubjectGrade(
        id: row['id'] as String,
        subjectId: row['subject_id'] as String,
        title: row['title'] as String,
        type: _enumValue(GradeType.values, row['type'], GradeType.activity),
        score: (row['score'] as num).toDouble(),
        maxScore: (row['max_score'] as num).toDouble(),
        date: _date(row['grade_date']),
      ),
    );

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

    // Migration must be non-destructive: never update an existing cloud note.
    // Postgres timestamps may have a different precision than local timestamps,
    // so comparing them with exact equality can cause repeated false conflicts.
    final rows = await _rows('study_notes');
    final rowsById = {for (final row in rows) row['id'] as String: row};
    for (final sourceNote in localNotes) {
      final localNote = sourceNote.copyWith(
        subjectId: subjectIdMap[sourceNote.subjectId] ?? sourceNote.subjectId,
      );
      final existing = rowsById[localNote.id];
      if (existing != null &&
          _sameNoteContent(existing, localNote) &&
          await _matchesNote(localNote)) {
        continue;
      }

      // Reuse an existing migration copy when it already matches, so a
      // repeated login does not create another duplicate each time.
      final prefix = '${localNote.id}_local_migration_${userId}_';
      var alreadyMigrated = false;
      for (final row in rows) {
        final rowId = row['id'] as String;
        if (rowId.startsWith(prefix) &&
            _sameNoteContent(row, localNote) &&
            await _matchesNote(localNote.copyWith(id: rowId))) {
          alreadyMigrated = true;
          break;
        }
      }
      if (alreadyMigrated) continue;

      var suffix = 1;
      while (true) {
        final candidateId = existing == null && suffix == 1
            ? localNote.id
            : '${prefix}$suffix';
        if (rowsById.containsKey(candidateId)) {
          suffix++;
          continue;
        }
        final candidate = localNote.copyWith(id: candidateId);
        try {
          await saveNote(candidate, insertOnly: true);
          rowsById[candidateId] = {
            'id': candidateId,
            'subject_id': candidate.subjectId,
            'title': candidate.title,
            'topic': candidate.topic,
            'category': candidate.category,
            'content': candidate.content,
            'updated_at': candidate.updatedAt.toIso8601String(),
          };
          break;
        } catch (error) {
          if (!_isDuplicateKey(error)) rethrow;
          suffix++;
        }
      }
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
    late final List<Map<String, dynamic>> savedRows;
    if (expectedUpdatedAt != null) {
      savedRows = List<Map<String, dynamic>>.from(await client
          .from('study_notes')
          .update(values)
          .eq('user_id', userId)
          .eq('id', note.id)
          .eq('updated_at', expectedUpdatedAt.toIso8601String())
          .select('id, user_id, subject_id, title, topic, category, content'));
      if (savedRows.isEmpty) {
        throw StateError(
          'El apunte "${note.title}" cambió en otro dispositivo. '
          'Vuelve a cargarlo antes de guardar para no sobrescribir cambios.',
        );
      }
    } else if (insertOnly) {
      savedRows = List<Map<String, dynamic>>.from(await client
          .from('study_notes')
          .insert({'id': note.id, ...values}).select(
              'id, user_id, subject_id, title, topic, category, content'));
    } else {
      savedRows = List<Map<String, dynamic>>.from(await client
          .from('study_notes')
          .upsert({'id': note.id, ...values}).select(
              'id, user_id, subject_id, title, topic, category, content'));
    }
    if (savedRows.length != 1) {
      throw StateError(
        'Supabase devolvió ${savedRows.length} filas al guardar '
        'el apunte "${note.title}" (se esperaba una).',
      );
    }
    final saved = savedRows.single;
    if (saved['id'] != note.id ||
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
    final rows = await client
        .from('study_notes')
        .select(
          'id, user_id, subject_id, title, topic, category, content, updated_at',
        )
        .eq('user_id', userId)
        .eq('id', note.id);
    if (rows.isEmpty) {
      throw StateError('No se encontró el apunte "${note.title}" en Supabase.');
    }
    if (rows.length != 1) {
      throw StateError(
        'Supabase devolvió ${rows.length} filas al verificar '
        'el apunte "${note.title}" (se esperaba una).',
      );
    }
    final row = rows.single;
    // Name mismatched fields without logging personal note content.
    final mismatchedFields = <String>[
      if (row['user_id'] != userId) 'user_id',
      if (row['subject_id'] != note.subjectId) 'subject_id',
      if (row['title'] != note.title) 'title',
      if (row['topic'] != note.topic) 'topic',
      if (row['category'] != note.category) 'category',
      if (row['content'] != note.content) 'content',
    ];
    if (mismatchedFields.isNotEmpty) {
      throw StateError(
        'No se pudo verificar el apunte "${note.title}". '
        'Campos distintos en Supabase: ${mismatchedFields.join(', ')}. '
        'No se ha eliminado el contenido local.',
      );
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
    try {
      final result = await client.rpc(
        'get_or_create_practice_hours',
        params: {'p_initial_minutes': initialMinutes},
      );
      if (result is! num) {
        throw FormatException(
          'Respuesta inválida al cargar horas de prácticas: $result',
        );
      }
      return result.toInt();
    } catch (error, stackTrace) {
      _logLoadFailure(
        'RPC public.get_or_create_practice_hours',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<int> addPracticeMinutes(int minutes) async {
    try {
      final result = await client.rpc(
        'add_practice_minutes',
        params: {'p_minutes': minutes},
      );
      if (result is! num) {
        throw FormatException(
          'Respuesta inválida al guardar horas de prácticas: $result',
        );
      }
      return result.toInt();
    } catch (error, stackTrace) {
      _logLoadFailure(
        'RPC public.add_practice_minutes',
        error,
        stackTrace,
      );
      rethrow;
    }
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
    List<Map<String, dynamic>> rows, {
    required String table,
    required String parentKey,
    required String valueKey,
  }) {
    final result = <String, List<String>>{};
    try {
      for (final row in rows) {
        result
            .putIfAbsent(row[parentKey] as String, () => [])
            .add(row[valueKey] as String? ?? row['name'] as String);
      }
    } catch (error, stackTrace) {
      _logLoadFailure('group public.$table rows', error, stackTrace);
      rethrow;
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
