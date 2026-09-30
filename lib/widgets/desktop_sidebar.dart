import 'package:flutter/material.dart';
import '../theme/cottagecore_theme.dart';

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    required this.selectedIndex,
    required this.onSelect,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: CottagecoreColors.creamCard,
        border: const Border(
          right: BorderSide(color: CottagecoreColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Branding
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CottagecoreColors.sage.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: CottagecoreColors.forest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🌿', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mi agenda',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: CottagecoreColors.forest,
                          fontFamily: 'serif',
                        ),
                      ),
                      Text(
                        'Espacio académico',
                        style: TextStyle(fontSize: 11, color: Color(0xFF7D7266)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Primary Navigation Group
          _sidebarItem(0, '🏡', 'Inicio'),
          _sidebarItem(1, '✓', 'Tareas'),
          _sidebarItem(2, '📅', 'Calendario'),
          _sidebarItem(3, '📚', 'Asignaturas'),
          _sidebarItem(4, '🍂', 'Mi semana'),
          _sidebarItem(5, '📖', 'Exámenes'),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),

          // Secondary Group
          _sidebarItem(6, '✓', 'Historial'),
          _sidebarItem(7, '📊', 'Progreso'),

          const Spacer(),

          const Divider(height: 1),
          const SizedBox(height: 8),

          // Settings
          _sidebarItem(8, '⚙️', 'Ajustes'),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, String icon, String label) {
    final isSelected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected
            ? CottagecoreColors.sage.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => onSelect(index),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    icon,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                      color: isSelected ? CottagecoreColors.forest : const Color(0xFF6B6053),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? CottagecoreColors.forest : const Color(0xFF4C4237),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: CottagecoreColors.forest,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
