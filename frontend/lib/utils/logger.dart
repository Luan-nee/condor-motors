import 'package:flutter/foundation.dart';

/// Niveles de log para filtrar mensajes
enum LogLevel {
  debug,
  info,
  warn,
  error,
}

/// Utilidad para centralizar la funcionalidad de registros (logs)
class Logger {
  /// Nivel mínimo de log para mostrar. En producción, podría configurarse a info o warn
  static LogLevel _currentLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  /// Establece el nivel mínimo de log
  static void setLevel(LogLevel level) {
    _currentLevel = level;
  }

  /// Registra un mensaje de depuración
  static void debug(String message) {
    if (_currentLevel.index <= LogLevel.debug.index) {
      _log('DEBUG', message);
    }
  }

  /// Registra un mensaje informativo
  static void info(String message) {
    if (_currentLevel.index <= LogLevel.info.index) {
      _log('INFO', message);
    }
  }

  /// Registra una advertencia
  static void warn(String message) {
    if (_currentLevel.index <= LogLevel.warn.index) {
      _log('WARN', message);
    }
  }

  /// Registra un error
  static void error(String message) {
    if (_currentLevel.index <= LogLevel.error.index) {
      _log('ERROR', message);
    }
  }

  /// Método interno para mostrar los logs con formato
  static void _log(String level, String message) {
    final DateTime now = DateTime.now();
    final String timestamp = 
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    
    final String logMessage = '[$timestamp] $level: $message';
    
    if (kDebugMode) {
      print(logMessage);
    }
    
    // TODO: Implementar almacenamiento persistente de logs para producción
    // Esto podría incluir enviar logs a un servicio remoto o guardarlos localmente
  }
}

/// Utilidades para registro de logs en la aplicación
/// Centraliza el sistema de logs para facilitar cambios globales

/// Registra un mensaje de depuración
void logDebug(String message) {
  if (kDebugMode) {
    debugPrint('🔍 DEBUG: $message');
  }
}

/// Registra un mensaje informativo
void logInfo(String message) {
  if (kDebugMode) {
    debugPrint('ℹ️ INFO: $message');
  }
}

/// Registra un mensaje de advertencia
void logWarning(String message) {
  if (kDebugMode) {
    debugPrint('⚠️ WARN: $message');
  }
}

/// Registra un error con su excepción opcional
void logError(String message, [dynamic error, StackTrace? stackTrace]) {
  if (kDebugMode) {
    debugPrint('❌ ERROR: $message');
    if (error != null) {
      debugPrint('  └─ $error');
      if (stackTrace != null) {
        debugPrint('  └─ $stackTrace');
      }
    }
  }
}

/// Registra un mensaje para operaciones de API
void logApi(String message) {
  if (kDebugMode) {
    debugPrint('🌐 API: $message');
  }
}

/// Registra información relacionada con el ciclo de vida de widgets
void logLifecycle(String message) {
  if (kDebugMode) {
    debugPrint('♻️ LIFECYCLE: $message');
  }
}

/// Registra mensajes relacionados con la navegación
void logNavigation(String message) {
  if (kDebugMode) {
    debugPrint('🧭 NAVIGATION: $message');
  }
}

/// Registra mensajes personalizados con un prefijo específico
void logCustom(String prefix, String message) {
  if (kDebugMode) {
    debugPrint('$prefix $message');
  }
} 