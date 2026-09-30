import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/app_shell.dart';
import 'services/agenda_repository.dart';
import 'theme/cottagecore_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  await AgendaRepository.instance.initialize();
  runApp(const AgendaApp());
}

class AgendaApp extends StatelessWidget {
  const AgendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda Académica Cottagecore',
      debugShowCheckedModeBanner: false,
      theme: CottagecoreTheme.lightTheme,
      home: const AppShell(),
    );
  }
}
