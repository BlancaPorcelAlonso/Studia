import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';
import 'subjects_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _enableNotifications = true;
  bool _notify1DayBefore = true;
  bool _notify3DaysBefore = true;
  bool _notifyExams5DaysBefore = true;

  @override
  Widget build(BuildContext context) {
    final repo = AgendaRepository.instance;
    final isDesktop = MediaQuery.of(context).size.width >= 860;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 28 : 16,
            vertical: 18,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚙️ Ajustes & Configuración',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: CottagecoreColors.forest,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Personaliza la estética, recordatorios y gestión académica.',
                style: TextStyle(fontSize: 14, color: Color(0xFF7A6F62)),
              ),
              const SizedBox(height: 20),

              // 🎨 APARIENCIA
              _sectionHeader('🎨 Apariencia & Identidad Visual'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _settingRow(
                        title: 'Tema Visual',
                        subtitle: 'Cottagecore cálido (Fondo crema, verde salvia, terracota)',
                        trailing: const Icon(Icons.check_circle_rounded, color: CottagecoreColors.sage),
                      ),
                      const Divider(height: 20),
                      _settingRow(
                        title: 'Tipografía de lectura',
                        subtitle: 'Serifa para títulos botánicos y palo seco para legibilidad de tareas',
                        trailing: const Text('Óptima', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🔔 NOTIFICACIONES
              _sectionHeader('🔔 Notificaciones & Recordatorios'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Recordatorios automáticos', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text('Alertas preventivas de entregas y exámenes'),
                        activeThumbColor: CottagecoreColors.forest,
                        value: _enableNotifications,
                        onChanged: (v) => setState(() => _enableNotifications = v),
                      ),
                      if (_enableNotifications) ...[
                        const Divider(height: 16),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Avisar el día previo (Mañana entregas...)'),
                          activeColor: CottagecoreColors.calmGreen,
                          value: _notify1DayBefore,
                          onChanged: (v) => setState(() => _notify1DayBefore = v ?? true),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Avisar con 3 días de antelación (Te quedan 3 días...)'),
                          activeColor: CottagecoreColors.calmGreen,
                          value: _notify3DaysBefore,
                          onChanged: (v) => setState(() => _notify3DaysBefore = v ?? true),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Avisar exámenes con 5 días de margen (Examen en 5 días...)'),
                          activeColor: CottagecoreColors.calmGreen,
                          value: _notifyExams5DaysBefore,
                          onChanged: (v) => setState(() => _notifyExams5DaysBefore = v ?? true),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CottagecoreColors.creamDarker,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            children: [
                              Text('💬 ', style: TextStyle(fontSize: 16)),
                              Expanded(
                                child: Text(
                                  'Ejemplo: "🌿 Mañana entregas Actividad 2 de Dart (Programación)."',
                                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF6B6053)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 📚 GESTIONAR ASIGNATURAS
              _sectionHeader('📚 Asignaturas & Colores'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: CottagecoreColors.sage.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(child: Text('📚', style: TextStyle(fontSize: 20))),
                        ),
                        title: const Text('Administrar asignaturas', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${repo.subjects.length} materias configuradas con colores e iconos'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SubjectsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ☁️ SINCRONIZACIÓN Y DATOS
              _sectionHeader('☁️ Persistencia & Datos'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _settingRow(
                        title: 'Modo de almacenamiento',
                        subtitle: repo.isCloudConnected
                            ? 'Supabase · ${Supabase.instance.client.auth.currentUser?.email ?? 'Cuenta activa'}'
                            : 'Solo este dispositivo · SharedPreferences',
                        trailing: Icon(
                          repo.isCloudConnected
                              ? Icons.cloud_done_outlined
                              : Icons.cloud_off_outlined,
                          color: repo.isCloudConnected
                              ? CottagecoreColors.calmGreen
                              : CottagecoreColors.warmBrown,
                        ),
                      ),
                      if (repo.syncError != null) ...[
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: CottagecoreColors.terracotta),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No se pudo sincronizar. Los cambios siguen guardados en este dispositivo. ${repo.syncError}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (repo.isCloudConnected) ...[
                        const Divider(height: 20),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.logout_rounded),
                          title: const Text('Cerrar sesión'),
                          onTap: () => Supabase.instance.client.auth.signOut(),
                        ),
                      ],
                      const Divider(height: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 👤 CUENTA & VERSION
              _sectionHeader('👤 Agenda Académica'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _settingRow(
                        title: 'Versión del Sistema',
                        subtitle: 'Agenda Cottagecore v1.0.2 (Flutter Multiplataforma)',
                        trailing: const Text('V1 Lista', style: TextStyle(fontWeight: FontWeight.w700, color: CottagecoreColors.forest)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: CottagecoreColors.forest,
        ),
      ),
    );
  }

  Widget _settingRow({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF7A6F62))),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}
