import 'package:flutter/material.dart';
import '../theme/cottagecore_theme.dart';

class EmptyBotanicalState extends StatelessWidget {
  const EmptyBotanicalState({
    required this.message,
    this.subMessage,
    this.emoji = '🌱',
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final String? subMessage;
  final String emoji;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: CottagecoreColors.sage.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 34),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: CottagecoreColors.forest,
              ),
            ),
            if (subMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                subMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7A7064),
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CottagecoreColors.forest,
                  side: const BorderSide(color: CottagecoreColors.sage),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
