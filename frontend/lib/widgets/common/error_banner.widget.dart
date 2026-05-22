import 'package:condorsmotors/theme/apptheme.dart';
import 'package:flutter/material.dart';

/// Widget unificado para mostrar alertas de error con fondo degradado suave en la sección de administración
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const ErrorBanner({
    super.key,
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
