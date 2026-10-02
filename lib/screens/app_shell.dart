import 'package:flutter/material.dart';
import '../widgets/desktop_sidebar.dart';
import '../widgets/task_form_modal.dart';
import 'calendar_screen.dart';
import 'exams_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'more_screen.dart';
import 'my_week_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';
import 'subjects_screen.dart';
import 'tasks_kanban_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _desktopIndex = 0;
  int _mobileIndex = 0;

  // Pages for Desktop sidebar (9 options)
  final List<Widget> _desktopPages = const [
    HomeScreen(),
    TasksKanbanScreen(),
    CalendarScreen(),
    SubjectsScreen(),
    MyWeekScreen(),
    ExamsScreen(),
    HistoryScreen(),
    ProgressScreen(),
    SettingsScreen(),
  ];

  // Pages for Mobile bottom nav (5 options)
  final List<Widget> _mobilePages = const [
    HomeScreen(),
    TasksKanbanScreen(),
    CalendarScreen(),
    SubjectsScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      final showTaskAction = _desktopIndex != 3;
      return Scaffold(
        body: Row(
          children: [
            DesktopSidebar(
              selectedIndex: _desktopIndex,
              onSelect: (index) {
                setState(() => _desktopIndex = index);
              },
            ),
            Expanded(
              child: IndexedStack(
                index: _desktopIndex,
                children: _desktopPages,
              ),
            ),
          ],
        ),
        floatingActionButton: showTaskAction
            ? FloatingActionButton.extended(
                onPressed: () => TaskFormModal.show(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nueva tarea',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              )
            : null,
      );
    }

    // Mobile layout
    final showTaskAction = _mobileIndex != 3;
    return Scaffold(
      body: IndexedStack(
        index: _mobileIndex,
        children: _mobilePages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _mobileIndex,
        onDestinationSelected: (index) {
          setState(() => _mobileIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_rounded),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: 'Tareas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book_rounded),
            label: 'Asignaturas',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            selectedIcon: Icon(Icons.more_horiz_rounded),
            label: 'Más',
          ),
        ],
      ),
      floatingActionButton: showTaskAction
          ? FloatingActionButton(
              onPressed: () => TaskFormModal.show(context),
              tooltip: 'Crear nueva tarea',
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
    );
  }
}
