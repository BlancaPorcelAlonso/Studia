import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/app_shell.dart';
import 'screens/supabase_gate.dart';
import 'services/agenda_repository.dart';
import 'services/supabase_config.dart';
import 'theme/cottagecore_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    runApp(const AgendaCloudApp());
  } else {
    await AgendaRepository.instance.initialize();
    runApp(const AgendaApp());
  }
}

class AgendaCloudApp extends StatelessWidget {
  const AgendaCloudApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Agenda Académica Cottagecore',
        debugShowCheckedModeBanner: false,
        theme: CottagecoreTheme.lightTheme,
        home: const SupabaseGate(),
      );
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
