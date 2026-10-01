import 'dart:convert';
import 'package:flutter/material.dart';
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
  bool _initialized = false;
  SupabaseAgendaSync? _cloudSync;
  String? _cloudUserId;
  String? _syncError;

  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Exam> get exams => List.unmodifiable(_exams);
  List<StudyNote> get notes => List.unmodifiable(_notes);
  List<Deliverable> get deliverables => List.unmodifiable(_deliverables);
  List<SubjectAbsence> get absences => List.unmodifiable(_absences);
  List<SubjectGrade> get grades => List.unmodifiable(_grades);
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
      final snapshot = await _cloudSync!.load();
      _subjects = snapshot.subjects;
      _tasks = snapshot.tasks;
      _exams = snapshot.exams;
      _notes = snapshot.notes;
      _deliverables = snapshot.deliverables;
      _absences = snapshot.absences;
      _grades = snapshot.grades;
      _initialized = true;
      _cloudUserId = user.id;
      _syncError = null;
      await _cacheAll();
      notifyListeners();
      return;
    }
    if (_initialized && _cloudSync == null) return;
    _cloudSync = null;
    _cloudUserId = null;
    final prefs = await SharedPreferences.getInstance();

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
    _subjects = [];
    _tasks = [];
    _exams = [];
    _notes = [];
    _deliverables = [];
    _absences = [];
    _grades = [];
    _cloudSync = null;
    _cloudUserId = null;
    _initialized = false;
    _syncError = null;
    notifyListeners();
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

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    await _persistTasks();
    await _syncRemote(() => _cloudSync?.delete('tasks', taskId));
    notifyListeners();
  }

  // --- Subject Methods ---

  Future<void> addSubject(Subject subject) async {
    _subjects.add(subject);
    await _persistSubjects();
    notifyListeners();
  }

  Future<void> updateSubject(Subject subject) async {
    final index = _subjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      _subjects[index] = subject;
      await _persistSubjects();
      notifyListeners();
    }
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
    await _persistNotes();
    await _persistDeliverables();
    await _persistAbsences();
    await _persistGrades();
    await _syncRemote(() => _cloudSync?.delete('subjects', subjectId));
    notifyListeners();
  }

  // --- Exam Methods ---

  Future<void> addExam(Exam exam) async {
    _exams.add(exam);
    await _persistExams();
    notifyListeners();
  }

  Future<void> updateExam(Exam exam) async {
    final index = _exams.indexWhere((e) => e.id == exam.id);
    if (index != -1) {
      _exams[index] = exam;
      await _persistExams();
      notifyListeners();
    }
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
    await _syncRemote(() => _cloudSync?.delete('exams', examId));
    notifyListeners();
  }

  // --- Note Methods ---

  Future<void> addNote(StudyNote note) async {
    _notes.insert(0, note);
    await _persistNotes();
    notifyListeners();
  }

  Future<void> updateNote(StudyNote note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
      await _persistNotes();
      notifyListeners();
    }
  }

  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((n) => n.id == noteId);
    await _persistNotes();
    await _syncRemote(() => _cloudSync?.delete('study_notes', noteId));
    notifyListeners();
  }

  // --- Deliverable Methods ---

  Future<void> addDeliverable(Deliverable deliverable) async {
    _deliverables.add(deliverable);
    await _persistDeliverables();
    notifyListeners();
  }

  Future<void> updateDeliverable(Deliverable deliverable) async {
    final index = _deliverables.indexWhere((item) => item.id == deliverable.id);
    if (index != -1) {
      _deliverables[index] = deliverable;
      await _persistDeliverables();
      notifyListeners();
    }
  }

  Future<void> deleteDeliverable(String deliverableId) async {
    _deliverables.removeWhere((item) => item.id == deliverableId);
    await _persistDeliverables();
    await _syncRemote(() => _cloudSync?.delete('deliverables', deliverableId));
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
    await _syncRemote(() => _cloudSync?.delete('subject_absences', absenceId));
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
    await _syncRemote(() => _cloudSync?.delete('subject_grades', gradeId));
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
    await _syncRemote(() => _cloudSync?.resetAll());
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
    final prefs = await SharedPreferences.getInstance();
    final encoded = _tasks.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList('agenda_tasks_v1', encoded);
    await _syncRemote(() => _cloudSync?.saveTasks(_tasks));
  }

  Future<void> _persistSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _subjects.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList('agenda_subjects_v1', encoded);
    await _syncRemote(() => _cloudSync?.saveSubjects(_subjects));
  }

  Future<void> _persistExams() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _exams.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('agenda_exams_v1', encoded);
    await _syncRemote(() => _cloudSync?.saveExams(_exams));
  }

  Future<void> _persistNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _notes.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList('agenda_notes_v1', encoded);
    await _syncRemote(() => _cloudSync?.saveNotes(_notes));
  }

  Future<void> _persistDeliverables() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        _deliverables.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('agenda_deliverables_v1', encoded);
    await _syncRemote(() => _cloudSync?.saveDeliverables(_deliverables));
  }

  Future<void> _persistAbsences() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _absences.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('agenda_absences_v1', encoded);
    await _syncRemote(() => _cloudSync?.saveAbsences(_absences));
  }

  Future<void> _persistGrades() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _grades.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('agenda_grades_v1', encoded);
    await _syncRemote(() => _cloudSync?.saveGrades(_grades));
  }

  Future<void> _syncRemote(Future<void>? Function() operation) async {
    if (_cloudSync == null) return;
    try {
      await operation();
      _syncError = null;
    } catch (error) {
      _syncError = error.toString();
    }
  }

  Future<void> _cacheAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'agenda_subjects_v1',
      _subjects.map((item) => jsonEncode(item.toJson())).toList(),
    );
    await prefs.setStringList(
      'agenda_tasks_v1',
      _tasks.map((item) => jsonEncode(item.toJson())).toList(),
    );
    await prefs.setStringList(
      'agenda_exams_v1',
      _exams.map((item) => jsonEncode(item.toJson())).toList(),
    );
    await prefs.setStringList(
      'agenda_notes_v1',
      _notes.map((item) => jsonEncode(item.toJson())).toList(),
    );
    await prefs.setStringList(
      'agenda_deliverables_v1',
      _deliverables.map((item) => jsonEncode(item.toJson())).toList(),
    );
    await prefs.setStringList(
      'agenda_absences_v1',
      _absences.map((item) => jsonEncode(item.toJson())).toList(),
    );
    await prefs.setStringList(
      'agenda_grades_v1',
      _grades.map((item) => jsonEncode(item.toJson())).toList(),
    );
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
