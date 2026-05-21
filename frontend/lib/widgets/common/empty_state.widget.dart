import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget unificado para representar un estado sin datos disponibles (Empty State)
/// en las tablas y listados del sistema de forma parametrizada y desacoplada
class EmptyState extends StatelessWidget {
  final dynamic icon;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.buttonLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final hasAction = buttonLabel != null && onAction != null;

    Widget iconWidget;
    if (icon is FaIconData) {
      iconWidget = FaIcon(
        icon as FaIconData,
        color: Colors.grey[500],
        size: 48,
      );
    } else if (icon is IconData) {
      iconWidget = Icon(
        icon as IconData,
        color: Colors.grey[500],
        size: 48,
      );
    } else {
      iconWidget = const SizedBox.shrink();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasAction) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
                label: Text(buttonLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE31E24),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
