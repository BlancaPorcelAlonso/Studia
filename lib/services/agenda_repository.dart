import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'supabase_agenda_sync.dart';

class AgendaRepository extends ChangeNotifier {
  static AgendaRepository? _instance;
  static AgendaRepository get instance => _instance ??= AgendaRepository._();

  AgendaRepository._();

  List<Subject> _subjects = [];
  List<Task> _tasks = [];
  List<Exam> _exams = [];
  List<StudyNote> _notes = [];
  List<Deliverable> _deliverables = [];
  List<SubjectAbsence> _absences = [];
  List<SubjectGrade> _grades = [];
  int _practiceMinutes = 0;
  bool _initialized = false;
  SupabaseAgendaSync? _cloudSync;
  String? _cloudUserId;
  String? _syncError;
  Future<void> _syncTail = Future<void>.value();

  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Exam> get exams => List.unmodifiable(_exams);
  List<StudyNote> get notes => List.unmodifiable(_notes);
  List<Deliverable> get deliverables => List.unmodifiable(_deliverables);
  List<SubjectAbsence> get absences => List.unmodifiable(_absences);
  List<SubjectGrade> get grades => List.unmodifiable(_grades);
  int get practiceMinutes => _practiceMinutes;
  bool get isInitialized => _initialized;
  bool get isCloudConnected => _cloudSync != null;
  String? get syncError => _syncError;

  Future<void> initialize({bool useCloud = false}) async {
    if (useCloud) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw StateError('Se requiere una sesión activa.');
      if (_initialized && _cloudUserId == user.id) return;
      _cloudSync = SupabaseAgendaSync(Supabase.instance.client, user.id);
      _initialized = false;
      final prefs = await SharedPreferences.getInstance();
      final practiceMinutesKey = 'agenda_practice_minutes_${user.id}_v1';
      final initialPracticeMinutes = prefs.getInt(practiceMinutesKey) ??
          prefs.getInt('agenda_practice_minutes_v1') ??
          0;
      _practiceMinutes = initialPracticeMinutes;
      final storedNotes = prefs.getStringList('agenda_notes_v1');
      final localNotes = storedNotes
              ?.map((item) =>
                  StudyNote.fromJson(jsonDecode(item) as Map<String, dynamic>))
              .toList() ??
          const <StudyNote>[];
      final storedSubjects = prefs.getStringList('agenda_subjects_v1');
      final localSubjects = storedSubjects
              ?.map((item) =>
                  Subject.fromJson(jsonDecode(item) as Map<String, dynamic>))
              .toList() ??
          const <Subject>[];
      Object? migrationError;
      try {
        await _cloudSync!.migrateLocalNotes(localNotes, localSubjects);
        if (!kDebugMode && storedNotes != null) {
          await prefs.remove('agenda_notes_v1');
        }
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            '[AgendaRepository] initialize: migrating local study notes '
            'failed; local notes were retained: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
        }
        migrationError = error;
      }
      late final AgendaSnapshot snapshot;
      try {
        snapshot = await _cloudSync!.load();
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            '[AgendaRepository] initialize: loading Supabase snapshot failed: '
            '$error',
          );
          debugPrintStack(stackTrace: stackTrace);
        }
        rethrow;
      }
      _subjects = snapshot.subjects;
      _tasks = snapshot.tasks;
      _exams = snapshot.exams;
      _notes = [
        ...snapshot.notes,
        ...localNotes.where(
          (localNote) =>
              !snapshot.notes.any((cloudNote) => cloudNote.id == localNote.id),
        ),
      ];
      _deliverables = snapshot.deliverables;
      _absences = snapshot.absences;
      _grades = snapshot.grades;
      Object? practiceHoursError;
      try {
        _practiceMinutes =
            await _cloudSync!.loadPracticeMinutes(initialPracticeMinutes);
        await prefs.setInt(practiceMinutesKey, _practiceMinutes);
        if (prefs.containsKey('agenda_practice_minutes_v1')) {
          await prefs.remove('agenda_practice_minutes_v1');
        }
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            '[AgendaRepository] initialize: could not load practice hours; '
            'the local total was retained: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
        }
        practiceHoursError = error;
      }
      _initialized = true;
      _cloudUserId = user.id;
      final syncErrors = [
        if (migrationError != null)
          'No se pudieron migrar los apuntes locales. Se conservaron en este dispositivo. $migrationError',
        if (practiceHoursError != null)
          'No se pudieron cargar las horas de prácticas desde Supabase. Se conservó el total de este dispositivo. $practiceHoursError',
      ];
      _syncError = syncErrors.isEmpty ? null : syncErrors.join(' ');
      notifyListeners();
      return;
    }
    if (_initialized && _cloudSync == null) return;
    _cloudSync = null;
    _cloudUserId = null;
    final prefs = await SharedPreferences.getInstance();
    _practiceMinutes = prefs.getInt('agenda_practice_minutes_v1') ?? 0;

    final storedSubjects = prefs.getStringList('agenda_subjects_v1');
    if (storedSubjects != null && storedSubjects.isNotEmpty) {
      _subjects = storedSubjects
          .map((item) =>
              Subject.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    } else {
      _subjects = _defaultSubjects();
    }

    final storedTasks = prefs.getStringList('agenda_tasks_v1');
    if (storedTasks != null && storedTasks.isNotEmpty) {
      _tasks = storedTasks
          .map(
              (item) => Task.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    } else {
      _tasks = _defaultTasks();
    }

    final storedExams = prefs.getStringList('agenda_exams_v1');
    if (storedExams != null && storedExams.isNotEmpty) {
      _exams = storedExams
          .map(
              (item) => Exam.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    } else {
      _exams = _defaultExams();
    }

    final storedNotes = prefs.getStringList('agenda_notes_v1');
    if (storedNotes != null && storedNotes.isNotEmpty) {
      _notes = storedNotes
          .map((item) =>
              StudyNote.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    } else {
      _notes = _defaultNotes();
    }

    _deliverables = (prefs.getStringList('agenda_deliverables_v1') ?? [])
        .map((item) =>
            Deliverable.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
    _absences = (prefs.getStringList('agenda_absences_v1') ?? [])
        .map((item) =>
            SubjectAbsence.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
    _grades = (prefs.getStringList('agenda_grades_v1') ?? [])
        .map((item) =>
            SubjectGrade.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();

    _initialized = true;
    notifyListeners();
  }

  Future<void> resetForSignedOut() async {
    await flushPendingSync();
    _subjects = [];
    _tasks = [];
    _exams = [];
    _notes = [];
    _deliverables = [];
    _absences = [];
    _grades = [];
    _practiceMinutes = 0;
    _cloudSync = null;
    _cloudUserId = null;
    _initialized = false;
    _syncError = null;
    notifyListeners();
  }

  Future<void> addPracticeMinutes(int minutes) async {
    if (minutes <= 0) {
      throw ArgumentError.value(minutes, 'minutes', 'Debe ser mayor que cero.');
    }

    final prefs = await SharedPreferences.getInstance();
    final cloud = _cloudSync;
    late final int totalMinutes;
    if (cloud == null) {
      totalMinutes = _practiceMinutes + minutes;
      await prefs.setInt('agenda_practice_minutes_v1', totalMinutes);
    } else {
      final userId = _cloudUserId;
      if (userId == null) {
        throw StateError('No se pudo identificar la cuenta de Supabase.');
      }
      totalMinutes = await cloud.addPracticeMinutes(minutes);
      await prefs.setInt('agenda_practice_minutes_${userId}_v1', totalMinutes);
    }
    _practiceMinutes = totalMinutes;
    notifyListeners();
  }

  Future<void> flushPendingSync() async {
    while (true) {
      final pendingSync = _syncTail;
      await pendingSync;
      if (identical(pendingSync, _syncTail)) return;
    }
  }

  Subject? getSubjectById(String id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // --- Task Methods ---

  Future<void> addTask(Task task) async {
    _tasks.insert(0, task);
    await _persistTasks();
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      await _persistTasks();
      notifyListeners();
    }
  }

  Future<void> moveTaskStatus(String taskId, TaskStatus newStatus) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final old = _tasks[index];
      if (old.status != newStatus) {
        _tasks[index] = old.copyWith(
          status: newStatus,
          completedAt:
              newStatus == TaskStatus.completed ? DateTime.now() : null,
        );
        await _persistTasks();
        notifyListeners();
      }
    }
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final old = _tasks[index];
      final newStatus = old.status == TaskStatus.completed
          ? TaskStatus.todo
          : TaskStatus.completed;
      _tasks[index] = old.copyWith(
        status: newStatus,
        completedAt: newStatus == TaskStatus.completed ? DateTime.now() : null,
      );
      await _persistTasks();
      notifyListeners();
    }
  }

  Future<void> toggleTaskCheckItem(String taskId, String checkItemId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final updatedChecklist = task.checklist.map((item) {
        if (item.id == checkItemId) {
          return item.copyWith(isChecked: !item.isChecked);
        }
        return item;
      }).toList();
      _tasks[index] = task.copyWith(checklist: updatedChecklist);
      await _persistTasks();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    await _persistTasks();
    await _syncRemote((cloud) => cloud.delete('tasks', taskId));
    notifyListeners();
  }

  // --- Subject Methods ---

  Future<bool> addSubject(Subject subject) async {
    _subjects.add(subject);
    final synced = await _persistSubjects();
    notifyListeners();
    return synced;
  }

  Future<bool> updateSubject(Subject subject) async {
    final index = _subjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      _subjects[index] = subject;
      final synced = await _persistSubjects();
      notifyListeners();
      return synced;
    }
    return false;
  }

  Future<void> deleteSubject(String subjectId) async {
    _subjects.removeWhere((s) => s.id == subjectId);
    _tasks.removeWhere((t) => t.subjectId == subjectId);
    _exams.removeWhere((e) => e.subjectId == subjectId);
    _notes.removeWhere((n) => n.subjectId == subjectId);
    _deliverables.removeWhere((item) => item.subjectId == subjectId);
    _absences.removeWhere((item) => item.subjectId == subjectId);
    _grades.removeWhere((item) => item.subjectId == subjectId);
    await _persistSubjects();
    await _persistTasks();
    await _persistExams();
    await _persistDeliverables();
    await _persistAbsences();
    await _persistGrades();
    await _syncRemote((cloud) => cloud.delete('subjects', subjectId));
    notifyListeners();
  }

  // --- Exam Methods ---

  Future<bool> addExam(Exam exam) async {
    _exams.add(exam);
    final synced = await _persistExams();
    notifyListeners();
    return synced;
  }

  Future<bool> updateExam(Exam exam) async {
    final index = _exams.indexWhere((e) => e.id == exam.id);
    if (index != -1) {
      _exams[index] = exam;
      final synced = await _persistExams();
      notifyListeners();
      return synced;
    }
    return false;
  }

  Future<void> toggleExamTopic(String examId, int topicIndex) async {
    final examIndex = _exams.indexWhere((e) => e.id == examId);
    if (examIndex != -1) {
      final exam = _exams[examIndex];
      if (topicIndex >= 0 && topicIndex < exam.topics.length) {
        final currentTopics = List<ExamTopic>.from(exam.topics);
        final oldTopic = currentTopics[topicIndex];
        currentTopics[topicIndex] =
            oldTopic.copyWith(isCompleted: !oldTopic.isCompleted);

        // Update state automatically if all completed
        final allCompleted = currentTopics.every((t) => t.isCompleted);
        final anyCompleted = currentTopics.any((t) => t.isCompleted);
        ExamState newState = exam.state;
        if (allCompleted) {
          newState = ExamState.ready;
        } else if (anyCompleted && exam.state == ExamState.notStarted) {
          newState = ExamState.preparing;
        }

        _exams[examIndex] = exam.copyWith(
          topics: currentTopics,
          state: newState,
        );
        await _persistExams();
        notifyListeners();
      }
    }
  }

  Future<void> deleteExam(String examId) async {
    _exams.removeWhere((e) => e.id == examId);
    await _persistExams();
    await _syncRemote((cloud) => cloud.delete('exams', examId));
    notifyListeners();
  }

  // --- Note Methods ---

  Future<bool> addNote(StudyNote note) async {
    final synced = await _saveNoteToCloud(note);
    if (synced) _notes.insert(0, note);
    notifyListeners();
    return synced;
  }

  Future<bool> updateNote(StudyNote note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      final previous = _notes[index];
      final synced = await _saveNoteToCloud(
        note,
        expectedUpdatedAt: previous.updatedAt,
      );
      if (synced) _notes[index] = note;
      notifyListeners();
      return synced;
    }
    return false;
  }

  Future<bool> deleteNote(String noteId) async {
    if (_cloudSync == null) {
      _syncError = 'Inicia sesión para eliminar apuntes de forma segura.';
      notifyListeners();
      return false;
    }
    final deleted = await _syncRemote((cloud) => cloud.deleteNote(noteId));
    if (!deleted) return false;
    _notes.removeWhere((n) => n.id == noteId);
    notifyListeners();
    return true;
  }

  // --- Deliverable Methods ---

  Future<bool> addDeliverable(Deliverable deliverable) async {
    _deliverables.add(deliverable);
    final synced = await _persistDeliverables();
    notifyListeners();
    return synced;
  }

  Future<bool> updateDeliverable(Deliverable deliverable) async {
    final index = _deliverables.indexWhere((item) => item.id == deliverable.id);
    if (index != -1) {
      _deliverables[index] = deliverable;
      final synced = await _persistDeliverables();
      notifyListeners();
      return synced;
    }
    return false;
  }

  Future<void> toggleDeliverableSubmitted(String deliverableId) async {
    final index = _deliverables.indexWhere((item) => item.id == deliverableId);
    if (index != -1) {
      final old = _deliverables[index];
      _deliverables[index] = old.copyWith(isSubmitted: !old.isSubmitted);
      await _persistDeliverables();
      notifyListeners();
    }
  }

  Future<void> deleteDeliverable(String deliverableId) async {
    _deliverables.removeWhere((item) => item.id == deliverableId);
    await _persistDeliverables();
    await _syncRemote((cloud) => cloud.delete('deliverables', deliverableId));
    notifyListeners();
  }

  // --- Subject Progress Methods ---

  Future<void> addAbsence(SubjectAbsence absence) async {
    _absences.add(absence);
    await _persistAbsences();
    notifyListeners();
  }

  Future<void> updateAbsence(SubjectAbsence absence) async {
    final index = _absences.indexWhere((item) => item.id == absence.id);
    if (index != -1) {
      _absences[index] = absence;
      await _persistAbsences();
      notifyListeners();
    }
  }

  Future<void> deleteAbsence(String absenceId) async {
    _absences.removeWhere((item) => item.id == absenceId);
    await _persistAbsences();
    await _syncRemote((cloud) => cloud.delete('subject_absences', absenceId));
    notifyListeners();
  }

  Future<void> addGrade(SubjectGrade grade) async {
    _grades.add(grade);
    await _persistGrades();
    notifyListeners();
  }

  Future<void> deleteGrade(String gradeId) async {
    _grades.removeWhere((item) => item.id == gradeId);
    await _persistGrades();
    await _syncRemote((cloud) => cloud.delete('subject_grades', gradeId));
    notifyListeners();
  }

  // --- Reset to sample data ---

  Future<void> resetToSampleData() async {
    _subjects = _defaultSubjects();
    _tasks = _defaultTasks();
    _exams = _defaultExams();
    _notes = _defaultNotes();
    _deliverables = [];
    _absences = [];
    _grades = [];
    await _syncRemote((cloud) => cloud.resetAll());
    await _persistSubjects();
    await _persistTasks();
    await _persistExams();
    await _persistNotes();
    await _persistDeliverables();
    await _persistAbsences();
    await _persistGrades();
    notifyListeners();
  }

  // --- Internal Persistence ---

  Future<void> _persistTasks() async {
    final tasks = List<Task>.of(_tasks);
    final prefs = await SharedPreferences.getInstance();
    final encoded = tasks.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList('agenda_tasks_v1', encoded);
    await _syncRemote((cloud) => cloud.saveTasks(tasks));
  }

  Future<bool> _persistSubjects() async {
    final subjects = List<Subject>.of(_subjects);
    final sync = _syncRemote((cloud) => cloud.saveSubjects(subjects));
    final prefs = await SharedPreferences.getInstance();
    final encoded = subjects.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList('agenda_subjects_v1', encoded);
    return sync;
  }

  Future<bool> _persistExams() async {
    final exams = List<Exam>.of(_exams);
    final sync = _syncRemote((cloud) => cloud.saveExams(exams));
    final prefs = await SharedPreferences.getInstance();
    final encoded = exams.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('agenda_exams_v1', encoded);
    return sync;
  }

  Future<bool> _persistNotes() async {
    final notes = List<StudyNote>.of(_notes);
    if (_cloudSync == null) return false;
    return _syncRemote((cloud) => cloud.saveNotes(notes));
  }

  Future<bool> _saveNoteToCloud(
    StudyNote note, {
    DateTime? expectedUpdatedAt,
  }) async {
    if (_cloudSync == null) {
      _syncError = 'Inicia sesión para guardar apuntes de forma segura.';
      notifyListeners();
      return false;
    }
    return _syncRemote(
      (cloud) => cloud.saveNote(
        note,
        expectedUpdatedAt: expectedUpdatedAt,
        insertOnly: expectedUpdatedAt == null,
      ),
    );
  }

  Future<bool> _persistDeliverables() async {
    final deliverables = List<Deliverable>.of(_deliverables);
    final sync = _syncRemote((cloud) => cloud.saveDeliverables(deliverables));
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        deliverables.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('agenda_deliverables_v1', encoded);
    return sync;
  }

  Future<bool> _persistAbsences() async {
    final absences = List<SubjectAbsence>.of(_absences);
    final sync = _syncRemote((cloud) => cloud.saveAbsences(absences));
    final prefs = await SharedPreferences.getInstance();
    final encoded = absences.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('agenda_absences_v1', encoded);
    return sync;
  }

  Future<bool> _persistGrades() async {
    final grades = List<SubjectGrade>.of(_grades);
    final sync = _syncRemote((cloud) => cloud.saveGrades(grades));
    final prefs = await SharedPreferences.getInstance();
    final encoded = grades.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('agenda_grades_v1', encoded);
    return sync;
  }

  Future<bool> _syncRemote(
    Future<void> Function(SupabaseAgendaSync cloud) operation,
  ) async {
    final cloud = _cloudSync;
    if (cloud == null) return true;
    final previousSync = _syncTail;
    final completer = Completer<void>();
    _syncTail = completer.future;
    await previousSync;
    try {
      if (_syncError != null) {
        _syncError = null;
        notifyListeners();
      }
      await operation(cloud);
      return true;
    } catch (error) {
      _syncError = error.toString();
      notifyListeners();
      return false;
    } finally {
      completer.complete();
    }
  }

  // --- Seed Data ---

  List<Subject> _defaultSubjects() {
    return [
      const Subject(
        id: 'prog',
        name: 'Programación',
        emoji: '🌿',
        colorValue: 0xFF7EA98B, // Verde salvia
        teacher: 'Marta Ruiz',
        classroom: 'Aula Magna 3',
        schedule: 'Lunes y Miércoles 10:00 - 12:00',
        notes: 'Enfoque en desarrollo móvil con Dart y Flutter.',
      ),
      const Subject(
        id: 'db',
        name: 'Bases de Datos',
        emoji: '🍄',
        colorValue: 0xFFC77A5C, // Terracota
        teacher: 'Javier Soler',
        classroom: 'Laboratorio B-12',
        schedule: 'Martes 12:00 - 14:00',
        notes: 'Modelado relacional, PostgreSQL y optimización SQL.',
      ),
      const Subject(
        id: 'ui',
        name: 'Diseño de Interfaces',
        emoji: '🌷',
        colorValue: 0xFFD49A9C, // Rosa empolvado cálido
        teacher: 'Sara Lobo',
        classroom: 'Taller Multimedia',
        schedule: 'Miércoles y Jueves 15:00 - 17:00',
        notes: 'UX Research, Figma y sistemas de diseño armónicos.',
      ),
      const Subject(
        id: 'sys',
        name: 'Sistemas Operativos',
        emoji: '🕯️',
        colorValue: 0xFFB69A7A, // Beige / marrón cálido
        teacher: 'Pablo León',
        classroom: 'Aula 204',
        schedule: 'Jueves 09:00 - 11:00',
        notes: 'Administración Linux, scripts Bash y concurrencia.',
      ),
      const Subject(
        id: 'ing',
        name: 'Inglés Técnico',
        emoji: '🪶',
        colorValue: 0xFF8FA392,
        teacher: 'Elena Woods',
        classroom: 'Seminario 4',
        schedule: 'Viernes 11:30 - 13:30',
        notes: 'Lectura de documentación y comunicación profesional.',
      ),
    ];
  }

  List<Task> _defaultTasks() {
    final now = DateTime.now();
    return [
      Task(
        id: 'task_dart_activity',
        title: 'Actividad 2 de Dart',
        subjectId: 'prog',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        type: TaskType.assignment,
        dueDate: now.add(const Duration(days: 2)),
        description:
            'Implementar la estructura de clases, constructores y métodos abstractos para la agenda.',
        notes: 'Revisar la guía de buenas prácticas de Flutter/Dart.',
        links: const ['https://dart.dev/guides'],
      ),
      Task(
        id: 'task_erp_project',
        title: 'Entrega Proyecto ERP',
        subjectId: 'db',
        status: TaskStatus.todo,
        priority: TaskPriority.urgent,
        type: TaskType.project,
        dueDate: now.add(const Duration(days: 1)),
        description: 'Terminar esquema relacional y queries de inventario.',
      ),
      Task(
        id: 'task_ui_review',
        title: 'Boceto de paleta Cottagecore',
        subjectId: 'ui',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        type: TaskType.assignment,
        dueDate: now.add(const Duration(days: 3)),
        description: 'Elegir tonos crema, salvia y madera para la interfaz.',
      ),
      Task(
        id: 'task_sys_linux',
        title: 'Práctica de Shell scripting',
        subjectId: 'sys',
        status: TaskStatus.completed,
        priority: TaskPriority.low,
        type: TaskType.assignment,
        dueDate: now.subtract(const Duration(days: 2)),
        completedAt: now.subtract(const Duration(days: 2)),
        description: 'Script para respaldos periódicos con cron.',
      ),
      Task(
        id: 'task_sql_views',
        title: 'Vistas e índices en PostgreSQL',
        subjectId: 'db',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        type: TaskType.assignment,
        dueDate: now.add(const Duration(days: 5)),
      ),
    ];
  }

  List<Exam> _defaultExams() {
    final now = DateTime.now();
    return [
      Exam(
        id: 'exam_db_midterm',
        name: 'Examen Bases de Datos',
        subjectId: 'db',
        date: now.add(const Duration(days: 6)),
        time: '10:30',
        classroom: 'Aula Magna A-204',
        state: ExamState.preparing,
        notes: 'Permitido llevar formulario resumen manuscrito.',
        topics: const [
          ExamTopic(
              title: 'Tema 1: Modelo Entidad-Relación', isCompleted: true),
          ExamTopic(
              title: 'Tema 2: Normalización (1FN, 2FN, 3FN)',
              isCompleted: true),
          ExamTopic(
              title: 'Tema 3: Consultas avanzadas SQL y JOINs',
              isCompleted: true),
          ExamTopic(
              title: 'Tema 4: Transacciones ACID e Índices',
              isCompleted: false),
        ],
      ),
      Exam(
        id: 'exam_sys_final',
        name: 'Parcial de Sistemas Operativos',
        subjectId: 'sys',
        date: now.add(const Duration(days: 12)),
        time: '09:00',
        classroom: 'Laboratorio 1',
        state: ExamState.started,
        notes: 'Entra teoría de procesos y permisos POSIX.',
        topics: const [
          ExamTopic(
              title: 'Tema 1: Arquitectura del Kernel', isCompleted: true),
          ExamTopic(
              title: 'Tema 2: Gestión de Procesos e Hilos', isCompleted: false),
          ExamTopic(
              title: 'Tema 3: Memoria virtual y Paginación',
              isCompleted: false),
          ExamTopic(
              title: 'Tema 4: Sistema de Ficheros y Redes', isCompleted: false),
        ],
      ),
    ];
  }

  List<StudyNote> _defaultNotes() {
    final now = DateTime.now();
    return [
      StudyNote(
        id: 'note_prog_1',
        subjectId: 'prog',
        title: 'Fundamentos de Programación Reactiva',
        topic: 'Tema 1: Arquitectura Flutter',
        category: 'Resumen',
        content:
            'Los widgets son descripciones inmutables de la interfaz de usuario.\n\n'
            '• StatelessWidget: cuando el widget no depende de nada más que de su configuración inicial.\n'
            '• StatefulWidget: cuando la interfaz cambia dinámicamente con interacción del usuario o datos asíncronos.\n'
            '• ChangeNotifier + ListenableBuilder: mecanismo ligero y elegante para sincronizar vistas sin dependencias pesadas.',
        updatedAt: now.subtract(const Duration(days: 1)),
        tags: const ['Flutter', 'Widgets', 'Arquitectura'],
        checklist: const [
          NoteCheckItem(
              text: 'Revisar ciclo de vida de State', isChecked: true),
          NoteCheckItem(
              text: 'Probar CustomPainter para gráficos botánicos',
              isChecked: false),
        ],
      ),
      StudyNote(
        id: 'note_db_1',
        subjectId: 'db',
        title: 'Guía Rápida de Índices B-Tree',
        topic: 'Tema 4: Optimización',
        category: 'Esquema',
        content:
            'Un índice B-Tree mantiene los datos ordenados y permite búsquedas, inserciones y eliminaciones en tiempo logarítmico O(log n).\n\n'
            'Regla de oro: No indexar columnas con baja cardinalidad (ej: booleanos).',
        updatedAt: now.subtract(const Duration(days: 3)),
        tags: const ['SQL', 'Índices', 'B-Tree'],
      ),
      StudyNote(
        id: 'note_ui_1',
        subjectId: 'ui',
        title: 'Psicología del Color Cottagecore & Ergonomía',
        topic: 'Tema 2: Color y Tipografía',
        category: 'Apuntes',
        content:
            'Evitar fondos blancos puros (#FFFFFF) por fatiga visual. Usar cremas cálidos (#FBF7F0).\n'
            'El color verde salvia (#7EA98B) transmite calma, concentración y naturaleza.\n'
            'El rojo puro debe evitarse salvo en urgencias críticas para reducir el estrés del estudiante.',
        updatedAt: now.subtract(const Duration(days: 4)),
        tags: const ['Cottagecore', 'UX', 'Accesibilidad'],
      ),
    ];
  }
}
