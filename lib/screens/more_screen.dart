import 'package:flutter/material.dart';
import '../theme/cottagecore_theme.dart';
import 'exams_screen.dart';
import 'history_screen.dart';
import 'my_week_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '☰ Más Opciones',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: CottagecoreColors.forest,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Accesos rápidos a tus herramientas complementarias.',
                style: TextStyle(fontSize: 14, color: Color(0xFF7A6F62)),
              ),
              const SizedBox(height: 24),

              _moreOptionTile(
                context,
                icon: '📖',
                title: 'Exámenes',
                subtitle: 'Evaluaciones y preparación de temario',
                destination: const ExamsScreen(),
              ),
              _moreOptionTile(
                context,
                icon: '🍂',
                title: 'Mi semana',
                subtitle: 'Vista de agenda semanal día a día',
                destination: const MyWeekScreen(),
              ),
              _moreOptionTile(
                context,
                icon: '✓',
                title: 'Historial',
                subtitle: 'Tareas terminadas y trabajos entregados',
                destination: const HistoryScreen(),
              ),
              _moreOptionTile(
                context,
                icon: '📊',
                title: 'Progreso & Mi Jardín',
                subtitle: 'Métricas de ritmo de estudio y jardín botánico',
                destination: const ProgressScreen(),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(),
              ),

              _moreOptionTile(
                context,
                icon: '⚙️',
                title: 'Ajustes',
                subtitle: 'Personalización, notificaciones y materias',
                destination: const SettingsScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moreOptionTile(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required Widget destination,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => destination),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: CottagecoreColors.sage.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: CottagecoreColors.forest,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF7A6F62)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF9E958A)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
