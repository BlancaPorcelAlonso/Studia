import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agenda/main.dart';
import 'package:agenda/services/agenda_repository.dart';
import 'package:agenda/models/models.dart';
import 'package:agenda/widgets/desktop_sidebar.dart';
import 'package:agenda/widgets/task_card.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('es_ES', null);
    await AgendaRepository.instance.initialize();
  });

  testWidgets(
      'App renders desktop shell on wide screen and navigates all tabs without crashing',
      (tester) async {
    // Set desktop screen size (width >= 900)
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const AgendaApp());
    await tester.pumpAndSettle();

    // Verify Desktop Sidebar branding
    expect(find.text('Mi agenda'), findsOneWidget);
    expect(find.text('Buenos días 🌿'), findsOneWidget);
    expect(find.text('🌿 Hoy'), findsOneWidget);
    expect(find.text('🍂 Próximamente'), findsOneWidget);
    expect(find.text('🌷 Esta semana'), findsOneWidget);
    expect(find.text('📌 Próximos exámenes y eventos'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final leftColumnHeight =
        tester.getSize(find.byKey(const ValueKey('home-left-column'))).height;
    final rightColumnHeight =
        tester.getSize(find.byKey(const ValueKey('home-right-column'))).height;
    expect((leftColumnHeight - rightColumnHeight).abs(), lessThan(0.5));
    final leftContentBottom = tester
        .getBottomLeft(find.byKey(const ValueKey('home-left-bottom-section')))
        .dy;
    final rightContentBottom = tester
        .getBottomLeft(
            find.byKey(const ValueKey('home-right-bottom-section-content')))
        .dy;
    expect((leftContentBottom - rightContentBottom).abs(), lessThan(0.5));

    Finder sidebarItem(String label) => find.descendant(
        of: find.byType(DesktopSidebar), matching: find.text(label));

    // Verify navigating to 'Tareas'
    await tester.tap(sidebarItem('Tareas'));
    await tester.pumpAndSettle();
    expect(find.text('🗂️ Tablero de Tareas'), findsOneWidget);
    expect(find.text('Por hacer'), findsOneWidget);
    expect(find.text('En proceso'), findsOneWidget);
    expect(find.text('Completado'), findsOneWidget);

    // Verify navigating to 'Calendario'
    await tester.tap(sidebarItem('Calendario'));
    await tester.pumpAndSettle();
    expect(find.text('📅 Calendario'), findsOneWidget);
    await tester.tap(find.text('Semana'));
    await tester.pumpAndSettle();
    expect(find.text('Próximos eventos'), findsNothing);
    expect(find.byKey(const ValueKey('calendar-week-type-filter')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-week-subject-filter')),
        findsOneWidget);
    expect(find.text('Lun'), findsOneWidget);
    expect(find.text('Dom'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('calendar-week-type-filter')));
    await tester.pumpAndSettle();
    expect(find.text('Clases').last, findsOneWidget);
    await tester.tap(find.text('Clases').last);
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('calendar-week-subject-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Programación').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Verify navigating to 'Asignaturas'
    await tester.tap(sidebarItem('Asignaturas'));
    await tester.pumpAndSettle();
    expect(find.text('📚 Asignaturas'), findsOneWidget);
    expect(find.text('Programación'), findsOneWidget);
    await tester.tap(find.text('Programación'));
    await tester.pumpAndSettle();
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Dónde me quedé'), findsOneWidget);
    expect(find.text('Tareas'), findsWidgets);
    expect(find.text('Próximas entregas'), findsOneWidget);
    expect(find.text('Apuntes recientes'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Entregas').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva entrega'));
    await tester.pumpAndSettle();
    final deliveryNameField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Ej. Proyecto final',
    );
    final deliveryNotesField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Instrucciones, formato o detalles...',
    );
    expect(deliveryNameField, findsOneWidget);
    expect(find.text('Asignatura'), findsOneWidget);
    expect(find.text('Fecha'), findsOneWidget);
    await tester.enterText(deliveryNameField, 'Entrega de integración');
    await tester.enterText(deliveryNotesField, 'Subir también el informe');
    await tester.tap(find.text('Crear entrega').last);
    await tester.pumpAndSettle();
    final createdDelivery = AgendaRepository.instance.deliverables.singleWhere(
      (item) => item.title == 'Entrega de integración',
    );
    expect(createdDelivery.subjectId, 'prog');
    expect(createdDelivery.description, 'Subir también el informe');
    expect(
      AgendaRepository.instance.tasks
          .where((task) => task.title == 'Entrega de integración'),
      isEmpty,
    );
    await AgendaRepository.instance.deleteDeliverable(createdDelivery.id);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Verify navigating to 'Mi semana'
    await tester.tap(sidebarItem('Mi semana'));
    await tester.pumpAndSettle();
    expect(find.text('🍂 Mi semana'), findsOneWidget);

    // Verify navigating to 'Exámenes'
    await tester.tap(sidebarItem('Exámenes'));
    await tester.pumpAndSettle();
    expect(find.text('📖 Exámenes & Evaluaciones'), findsOneWidget);

    // Verify navigating to 'Historial'
    await tester.tap(sidebarItem('Historial'));
    await tester.pumpAndSettle();
    expect(find.text('✓ Historial de Logros'), findsOneWidget);

    // Verify navigating to 'Progreso'
    await tester.tap(sidebarItem('Progreso'));
    await tester.pumpAndSettle();
    expect(find.text('📊 Progreso Académico'), findsOneWidget);
    expect(find.text('🌱 Mi Jardín Botánico'), findsOneWidget);

    // Verify navigating to 'Ajustes'
    await tester.tap(sidebarItem('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('⚙️ Ajustes & Configuración'), findsOneWidget);
  });

  testWidgets('App renders mobile bottom navigation on mobile screen',
      (tester) async {
    // Set mobile screen size (width < 900)
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const AgendaApp());
    await tester.pumpAndSettle();

    expect(find.text('🍂 Próximamente'), findsOneWidget);
    expect(find.text('📌 Próximos exámenes y eventos'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Verify bottom navigation bar destinations exist
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Tareas'), findsOneWidget);
    expect(find.text('Calendario'), findsOneWidget);
    expect(find.text('Asignaturas'), findsOneWidget);
    expect(find.text('Más'), findsOneWidget);

    await tester.tap(find.text('Calendario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semana'));
    await tester.pumpAndSettle();
    expect(find.text('Próximos eventos'), findsNothing);
    expect(tester.takeException(), isNull);

    // Tap on 'Más'
    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    expect(find.text('☰ Más Opciones'), findsOneWidget);

    await tester.tap(find.text('Asignaturas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Programación'));
    await tester.pumpAndSettle();
    expect(find.text('Tareas'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Apuntes recientes'));
    await tester.pumpAndSettle();
    expect(find.text('Apuntes recientes'), findsOneWidget);
    expect(find.text('Añadir apunte'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Task cards show quick links to linked exam and deliverable',
      (tester) async {
    const subjectId = 'linked_task_subject';
    final subject = Subject(
      id: subjectId,
      name: 'Programación',
      emoji: '💻',
      colorValue: 0xFF7EA98B,
    );
    final task = Task(
      id: 'linked_task_card',
      title: 'Tarea con enlaces',
      subjectId: subjectId,
      status: TaskStatus.todo,
      priority: TaskPriority.high,
      type: TaskType.assignment,
      dueDate: DateTime(2026, 10, 10),
      linkedExamId: 'exam_1',
      linkedDeliverableId: 'delivery_1',
    );

    final repo = AgendaRepository.instance;
    if (repo.getSubjectById(subjectId) == null) {
      await repo.addSubject(subject);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: TaskCard(task: task),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ver examen'), findsOneWidget);
    expect(find.text('Ver entrega'), findsOneWidget);

    await tester.tap(find.text('Ver entrega'));
    await tester.pumpAndSettle();
    expect(find.text('Entregas y eventos'), findsOneWidget);
  });

  test('Task and exam relationships persist through JSON serialization', () {
    final task = Task(
      id: 'linked_task',
      title: 'Preparar examen',
      subjectId: 'prog',
      status: TaskStatus.todo,
      priority: TaskPriority.high,
      type: TaskType.assignment,
      dueDate: DateTime(2026, 10, 10),
      linkedExamId: 'exam_1',
      linkedDeliverableId: 'delivery_1',
    );

    final exam = Exam(
      id: 'exam_1',
      name: 'Parcial de programación',
      subjectId: 'prog',
      date: DateTime(2026, 10, 12),
      time: '10:00',
      classroom: 'Aula 2',
      topics: const [ExamTopic(title: 'Modelado', isCompleted: false)],
      state: ExamState.preparing,
      linkedNoteIds: const ['note_1', 'note_2'],
    );

    final restoredTask = Task.fromJson(task.toJson());
    final restoredExam = Exam.fromJson(exam.toJson());

    expect(restoredTask.linkedExamId, 'exam_1');
    expect(restoredTask.linkedDeliverableId, 'delivery_1');
    expect(restoredExam.linkedNoteIds, ['note_1', 'note_2']);
  });

  test('Repository CRUD and single source of truth operates correctly',
      () async {
    final repo = AgendaRepository.instance;
    final initialCount = repo.tasks.length;

    final newTask = Task(
      id: 'test_task_1',
      title: 'Actividad de prueba',
      subjectId: 'prog',
      status: TaskStatus.todo,
      priority: TaskPriority.high,
      type: TaskType.assignment,
      dueDate: DateTime.now().add(const Duration(days: 2)),
    );

    await repo.addTask(newTask);
    expect(repo.tasks.length, initialCount + 1);
    expect(repo.tasks.first.title, 'Actividad de prueba');

    // Move status to in progress
    await repo.moveTaskStatus('test_task_1', TaskStatus.inProgress);
    expect(repo.tasks.firstWhere((t) => t.id == 'test_task_1').status,
        TaskStatus.inProgress);

    // Move status to completed
    await repo.moveTaskStatus('test_task_1', TaskStatus.completed);
    final completedTask = repo.tasks.firstWhere((t) => t.id == 'test_task_1');
    expect(completedTask.status, TaskStatus.completed);
    expect(completedTask.completedAt, isNotNull);

    // Delete task
    await repo.deleteTask('test_task_1');
    expect(repo.tasks.length, initialCount);

    const subjectId = 'test_progress_subject';
    await repo.addSubject(const Subject(
      id: subjectId,
      name: 'Materia de prueba',
      emoji: '📘',
      colorValue: 0xFF7EA98B,
      schedules: [
        ClassSchedule(
            weekday: DateTime.wednesday,
            startMinutes: 17 * 60,
            durationMinutes: 120),
        ClassSchedule(
            weekday: DateTime.friday,
            startMinutes: 9 * 60 + 30,
            durationMinutes: 90),
      ],
    ));
    expect(repo.getSubjectById(subjectId)!.schedules, hasLength(2));
    expect(
        repo.getSubjectById(subjectId)!.schedules.first.durationMinutes, 120);
    await repo.updateSubject(repo.getSubjectById(subjectId)!.copyWith(
          lastStudyNote: 'Repasar el tema 2',
          lastStudyAt: DateTime(2026, 9, 30),
        ));
    expect(repo.getSubjectById(subjectId)!.lastStudyNote, 'Repasar el tema 2');

    await repo.addDeliverable(Deliverable(
      id: 'test_deliverable',
      subjectId: subjectId,
      title: 'Presentación',
      date: DateTime(2026, 10, 5),
    ));
    await repo.addAbsence(SubjectAbsence(
      id: 'test_absence',
      subjectId: subjectId,
      date: DateTime(2026, 9, 30),
    ));
    await repo.addGrade(SubjectGrade(
      id: 'test_grade',
      subjectId: subjectId,
      title: 'Práctica 1',
      type: GradeType.activity,
      score: 8,
      maxScore: 10,
      date: DateTime(2026, 9, 30),
    ));
    expect(
        repo.deliverables
            .firstWhere((item) => item.id == 'test_deliverable')
            .id,
        'test_deliverable');
    expect(repo.absences.firstWhere((item) => item.id == 'test_absence').id,
        'test_absence');
    expect(repo.grades.firstWhere((item) => item.id == 'test_grade').score, 8);

    await repo.deleteSubject(subjectId);
    expect(repo.getSubjectById(subjectId), isNull);
    expect(repo.deliverables, isEmpty);
    expect(repo.absences, isEmpty);
    expect(repo.grades, isEmpty);
  });
}
