import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget centralizado para manejar toasts de manera consistente
class ToastManager {
  static const Duration _defaultDuration = Duration(seconds: 3);
  static const Duration _longDuration = Duration(seconds: 4);

  /// Muestra un toast de éxito
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration? duration,
    VoidCallback? onTap,
  }) {
    _showToast(
      context,
      message: message,
      type: ToastType.success,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Muestra un toast de error
  static void showError(
    BuildContext context, {
    required String message,
    Duration? duration,
    VoidCallback? onTap,
  }) {
    _showToast(
      context,
      message: message,
      type: ToastType.error,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Muestra un toast de advertencia
  static void showWarning(
    BuildContext context, {
    required String message,
    Duration? duration,
    VoidCallback? onTap,
  }) {
    _showToast(
      context,
      message: message,
      type: ToastType.warning,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Muestra un toast de información
  static void showInfo(
    BuildContext context, {
    required String message,
    Duration? duration,
    VoidCallback? onTap,
  }) {
    _showToast(
      context,
      message: message,
      type: ToastType.info,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Muestra un toast de carga
  static void showLoading(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    _showToast(
      context,
      message: message,
      type: ToastType.loading,
      duration: duration ?? _longDuration,
    );
  }

  /// Método interno para mostrar toasts
  static void _showToast(
    BuildContext context, {
    required String message,
    required ToastType type,
    Duration? duration,
    VoidCallback? onTap,
  }) {
    if (!context.mounted) {
      return;
    }

    final snackBar = SnackBar(
      content: _ToastContent(
        message: message,
        type: type,
        onTap: onTap,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      duration: duration ?? _defaultDuration,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Cierra todos los toasts activos
  static void hideAll(BuildContext context) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}

/// Tipos de toast disponibles
enum ToastType {
  success,
  error,
  warning,
  info,
  loading,
}

/// Widget personalizado para el contenido del toast
class _ToastContent extends StatelessWidget {
  final String message;
  final ToastType type;
  final VoidCallback? onTap;

  const _ToastContent({
    required this.message,
    required this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _getIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _getTextColor(),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onTap,
              child: FaIcon(
                FontAwesomeIcons.xmark,
                color: _getTextColor().withValues(alpha: 0.7),
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
      case ToastType.success:
        return const Color(0xFF10B981); // Verde
      case ToastType.error:
        return const Color(0xFFEF4444); // Rojo
      case ToastType.warning:
        return const Color(0xFFF59E0B); // Amarillo
      case ToastType.info:
        return const Color(0xFF3B82F6); // Azul
      case ToastType.loading:
        return const Color(0xFF6B7280); // Gris
    }
  }

  Color _getTextColor() {
    return Colors.white;
  }

  Widget _getIcon() {
    switch (type) {
      case ToastType.success:
        return const FaIcon(
          FontAwesomeIcons.circleCheck,
          color: Colors.white,
          size: 20,
        );
      case ToastType.error:
        return const FaIcon(
          FontAwesomeIcons.circleXmark,
          color: Colors.white,
          size: 20,
        );
      case ToastType.warning:
        return const FaIcon(
          FontAwesomeIcons.triangleExclamation,
          color: Colors.white,
          size: 20,
        );
      case ToastType.info:
        return const FaIcon(
          FontAwesomeIcons.circleInfo,
          color: Colors.white,
          size: 20,
        );
      case ToastType.loading:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        );
    }
  }
}

/// Extension para facilitar el uso
extension ToastManagerExtension on BuildContext {
  void showSuccessToast(String message, {VoidCallback? onTap}) {
    ToastManager.showSuccess(this, message: message, onTap: onTap);
  }

  void showErrorToast(String message, {VoidCallback? onTap}) {
    ToastManager.showError(this, message: message, onTap: onTap);
  }

  void showWarningToast(String message, {VoidCallback? onTap}) {
    ToastManager.showWarning(this, message: message, onTap: onTap);
  }

  void showInfoToast(String message, {VoidCallback? onTap}) {
    ToastManager.showInfo(this, message: message, onTap: onTap);
  }

  void showLoadingToast(String message) {
    ToastManager.showLoading(this, message: message);
  }

  void hideAllToasts() {
    ToastManager.hideAll(this);
  }
}
