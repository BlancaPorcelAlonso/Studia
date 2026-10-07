import 'package:flutter/material.dart';
import '../theme/cottagecore_theme.dart';

/// Helper para abrir modales consistentes en desktop (diálogo) y móvil (bottom sheet)
class StudiaModalHelper {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double maxWidth = 580,
    double maxHeight = 820,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    if (isDesktop) {
      return showDialog<T>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
            child: child,
          ),
        ),
      );
    } else {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => child,
      );
    }
  }
}

/// Contenedor unificado para modales y formularios de Studia con estética cottagecore
class StudiaModalContainer extends StatelessWidget {
  const StudiaModalContainer({
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.maxWidth = 580,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    return Container(
      decoration: BoxDecoration(
        color: CottagecoreColors.creamCard,
        borderRadius: isDesktop
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: CottagecoreColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x143E3123),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(22, 16, 22, bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle en móviles
          if (!isDesktop)
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: CottagecoreColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

          // Cabecera unificada
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: CottagecoreColors.forest,
                        fontFamily: 'serif',
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CottagecoreColors.warmBrown,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: CottagecoreColors.warmBrown),
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Contenido con scroll
          Flexible(
            child: SingleChildScrollView(
              child: child,
            ),
          ),

          // Acciones inferiores opcionales
          if (actions != null) ...[
            const SizedBox(height: 20),
            actions!,
          ],
        ],
      ),
    );
  }
}

/// Campo de formulario con espaciado vertical estandarizado:
/// 8px entre etiqueta e input, y 18px tras el input al siguiente campo.
class StudiaFormField extends StatelessWidget {
  const StudiaFormField({
    required this.label,
    required this.child,
    this.isRequired = false,
    this.helperText,
    this.bottomSpacing = 18,
    super.key,
  });

  final String label;
  final Widget child;
  final bool isRequired;
  final String? helperText;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CottagecoreColors.warmBrown,
                ),
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: CottagecoreColors.terracotta,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
          if (helperText != null) ...[
            const SizedBox(height: 4),
            Text(
              helperText!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8C8276),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Separador de sección con título para formularios y fichas
class StudiaSectionHeader extends StatelessWidget {
  const StudiaSectionHeader({
    required this.title,
    this.action,
    super.key,
  });

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CottagecoreColors.forest,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Divider(
              color: CottagecoreColors.border,
              thickness: 1,
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Botón principal estilo Cottagecore con padding e iconos consistentes
class StudiaPrimaryButton extends StatelessWidget {
  const StudiaPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: CottagecoreColors.forest,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : (icon != null ? Icon(icon, size: 20) : const SizedBox.shrink()),
      label: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}
