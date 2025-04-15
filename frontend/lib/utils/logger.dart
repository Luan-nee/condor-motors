import 'package:flutter/foundation.dart';

/// Constantes para colores ANSI en terminal
class ConsoleColor {
  // Colores básicos
  static const String reset = '\x1B[0m';
  static const String black = '\x1B[30m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';

  // Colores brillantes
  static const String brightBlack = '\x1B[90m';
  static const String brightRed = '\x1B[91m';
  static const String brightGreen = '\x1B[92m';
  static const String brightYellow = '\x1B[93m';
  static const String brightBlue = '\x1B[94m';
  static const String brightMagenta = '\x1B[95m';
  static const String brightCyan = '\x1B[96m';
  static const String brightWhite = '\x1B[97m';

  // Estilos de texto
  static const String bold = '\x1B[1m';
  static const String underline = '\x1B[4m';
  static const String dim = '\x1B[2m'; // Texto tenue (opacidad 50%)

  // Fondos
  static const String bgBlack = '\x1B[40m';
  static const String bgRed = '\x1B[41m';
  static const String bgGreen = '\x1B[42m';
  static const String bgYellow = '\x1B[43m';
  static const String bgBlue = '\x1B[44m';
  static const String bgMagenta = '\x1B[45m';
  static const String bgCyan = '\x1B[46m';
  static const String bgWhite = '\x1B[47m';

  // Colores para métodos HTTP
  static const String get = brightGreen;
  static const String post = brightBlue;
  static const String put = brightYellow;
  static const String patch = brightMagenta;
  static const String delete = brightRed;

  // Colores para funcionalidades específicas
  static const String cache = '$dim$brightBlack'; // Gris con opacidad 50%

  /// Obtiene el color para un método HTTP específico
  static String getHttpMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return get;
      case 'POST':
        return post;
      case 'PUT':
        return put;
      case 'PATCH':
        return patch;
      case 'DELETE':
        return delete;
      default:
        return reset;
    }
  }

  /// Aplica color a un texto
  static String colorize(String text, String color) {
    if (!kDebugMode) {
      return text; // Solo aplicar colores en modo debug
    }
    return '$color$text$reset';
  }
}

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
      _log('DEBUG', message, ConsoleColor.cyan);
    }
  }

  /// Registra un mensaje informativo
  static void info(String message) {
    if (_currentLevel.index <= LogLevel.info.index) {
      _log('INFO', message, ConsoleColor.blue);
    }
  }

  /// Registra una advertencia
  static void warn(String message) {
    if (_currentLevel.index <= LogLevel.warn.index) {
      _log('WARN', message, ConsoleColor.yellow);
    }
  }

  /// Registra un error
  static void error(String message) {
    if (_currentLevel.index <= LogLevel.error.index) {
      _log('ERROR', message, ConsoleColor.red);
    }
  }

  /// Registra un mensaje relacionado con caché (con color gris y opacidad 50%)
  static void cache(String message) {
    if (_currentLevel.index <= LogLevel.info.index) {
      _log('CACHE', message, ConsoleColor.cache);
    }
  }

  /// Registra una petición HTTP
  static void http(String method, String endpoint, [int? statusCode]) {
    if (_currentLevel.index <= LogLevel.debug.index) {
      final String methodColor = ConsoleColor.getHttpMethodColor(method);

      // Usar un enfoque alternativo para rellenar el string sin padEnd
      String paddedMethod = method;
      while (paddedMethod.length < 6) {
        paddedMethod += ' ';
      }

      final String coloredMethod =
          ConsoleColor.colorize(paddedMethod, methodColor);

      String message = '$coloredMethod $endpoint';

      if (statusCode != null) {
        final String statusColor = statusCode >= 400
            ? ConsoleColor.red
            : (statusCode >= 300 ? ConsoleColor.yellow : ConsoleColor.green);
        message +=
            ' ${ConsoleColor.colorize('[${statusCode.toString()}]', statusColor)}';
      }

      _rawLog(message);
    }
  }

  /// Método interno para mostrar los logs con formato
  static void _log(String level, String message, String color) {
    final DateTime now = DateTime.now();
    final String timestamp = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    final String coloredLevel = ConsoleColor.colorize(level, color);
    final String logMessage = '[$timestamp] $coloredLevel: $message';

    _rawLog(logMessage);
  }

  /// Muestra un mensaje sin formato adicional
  static void _rawLog(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(message);
    }
  }
}

/// Utilidades para registro de logs en la aplicación
/// Centraliza el sistema de logs para facilitar cambios globales

/// Registra un mensaje de depuración
void logDebug(String message) {
  Logger.debug(message);
}

/// Registra un mensaje informativo
void logInfo(String message) {
  Logger.info(message);
}

/// Registra un mensaje de advertencia
void logWarning(String message) {
  Logger.warn(message);
}

/// Registra un error con su excepción opcional
void logError(String message, [error, StackTrace? stackTrace]) {
  Logger.error(message);
  if (error != null && kDebugMode) {
    // ignore: avoid_print
    print(ConsoleColor.colorize('  └─ $error', ConsoleColor.brightRed));
    if (stackTrace != null) {
      // ignore: avoid_print
      print(ConsoleColor.colorize('  └─ $stackTrace', ConsoleColor.brightRed));
    }
  }
}

/// Registra un mensaje relacionado con caché
void logCache(String message) {
  Logger.cache(message);
}

/// Registra un mensaje para operaciones de API
void logApi(String message) {
  Logger.info('API: $message');
}

/// Registra información relacionada con el ciclo de vida de widgets
void logLifecycle(String message) {
  Logger.debug('LIFECYCLE: $message');
}

/// Registra mensajes relacionados con la navegación
void logNavigation(String message) {
  Logger.info('NAVIGATION: $message');
}

/// Registra una petición HTTP
void logHttp(String method, String endpoint, [int? statusCode]) {
  Logger.http(method, endpoint, statusCode);
}

/// Registra mensajes personalizados con un prefijo específico
void logCustom(String prefix, String message) {
  if (kDebugMode) {
    // ignore: avoid_print
    print('$prefix $message');
  }
}
