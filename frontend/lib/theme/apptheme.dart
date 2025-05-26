import 'package:flutter/material.dart';

// Nombre de la fuente principal
const String kFontFamily = 'SourceSans3';

/// Clase para manejar los temas de la aplicación
/// Esta clase no debe ser instanciada - use los métodos estáticos
abstract class AppTheme {
  // Constructor privado para evitar instanciación
  AppTheme._();

  // Colores principales
  static const Color primaryColor = Color(0xFFE31E24);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color cardColor = Color(0xFF1E1E1E);
  static const Color scaffoldBackgroundColor = Color(0xFF121212);
  static const Color appBarColor = Color(0xFF1E1E1E);

  // Radios de borde comunes
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 16.0;

  // Espaciado común
  static const double spacing = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;

  /// Estilo de texto base que hereda la fuente principal
  static const TextStyle _baseTextStyle = TextStyle(
    fontFamily: kFontFamily,
    color: Colors.white,
  );

  /// Retorna el tema principal de la aplicación
  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
        ),
        fontFamily: kFontFamily,
        useMaterial3: true,
        scaffoldBackgroundColor: scaffoldBackgroundColor,

        // Configuración de AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: appBarColor,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: _baseTextStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          toolbarTextStyle: _baseTextStyle,
        ),

        // Configuración de diálogos
        dialogTheme: DialogTheme(
          backgroundColor: cardColor,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(mediumRadius),
          ),
          titleTextStyle: _baseTextStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: _baseTextStyle.copyWith(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),

        // Configuración de botones
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(smallRadius),
            ),
            textStyle: _baseTextStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),

        // Configuración de texto por defecto
        textTheme: TextTheme(
          // Títulos
          displayLarge: _baseTextStyle.copyWith(
              fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: _baseTextStyle.copyWith(
              fontSize: 28, fontWeight: FontWeight.bold),
          displaySmall: _baseTextStyle.copyWith(
              fontSize: 24, fontWeight: FontWeight.bold),

          // Encabezados
          headlineLarge: _baseTextStyle.copyWith(
              fontSize: 22, fontWeight: FontWeight.w600),
          headlineMedium: _baseTextStyle.copyWith(
              fontSize: 20, fontWeight: FontWeight.w600),
          headlineSmall: _baseTextStyle.copyWith(
              fontSize: 18, fontWeight: FontWeight.w600),

          // Títulos
          titleLarge: _baseTextStyle.copyWith(
              fontSize: 22, fontWeight: FontWeight.bold),
          titleMedium: _baseTextStyle.copyWith(
              fontSize: 18, fontWeight: FontWeight.w500),
          titleSmall: _baseTextStyle.copyWith(
              fontSize: 16, fontWeight: FontWeight.w500),

          // Cuerpo de texto
          bodyLarge:
              _baseTextStyle.copyWith(fontSize: 16, color: Colors.white70),
          bodyMedium:
              _baseTextStyle.copyWith(fontSize: 14, color: Colors.white70),
          bodySmall:
              _baseTextStyle.copyWith(fontSize: 12, color: Colors.white70),

          // Etiquetas
          labelLarge: _baseTextStyle.copyWith(
              fontSize: 16, fontWeight: FontWeight.w500),
          labelMedium: _baseTextStyle.copyWith(
              fontSize: 14, fontWeight: FontWeight.w500),
          labelSmall: _baseTextStyle.copyWith(
              fontSize: 12, fontWeight: FontWeight.w500),
        ),

        // Configuración de tarjetas
        cardTheme: CardTheme(
          color: cardColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(mediumRadius),
          ),
        ),

        // Configuración de campos de texto
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardColor,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: spacingMedium, vertical: spacingMedium),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(smallRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(smallRadius),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(smallRadius),
            borderSide: const BorderSide(color: primaryColor),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(smallRadius),
            borderSide: const BorderSide(color: Colors.red),
          ),
          labelStyle: _baseTextStyle.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
          hintStyle: _baseTextStyle.copyWith(
            color: Colors.white.withOpacity(0.5),
          ),
        ),

        // Configuración de Snackbar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: cardColor,
          behavior: SnackBarBehavior.floating,
          elevation: 6,
          width: 400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(mediumRadius),
          ),
          contentTextStyle: _baseTextStyle.copyWith(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
          actionTextColor: primaryColor,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 20,
          ),
        ),

        // Configuración de Tooltip
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(smallRadius),
          ),
          textStyle: _baseTextStyle.copyWith(fontSize: 12),
        ),

        // Configuración de PopupMenu
        popupMenuTheme: PopupMenuThemeData(
          color: cardColor,
          textStyle: _baseTextStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(smallRadius),
          ),
        ),
      );

  // Helper method for SnackBar styles
  static SnackBar getStyledSnackBar({
    required BuildContext context,
    required String message,
    required bool isError,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    return SnackBar(
      content: GestureDetector(
        onHorizontalDragEnd: (_) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isError
                    ? Colors.red.withOpacity(0.1)
                    : primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(smallRadius),
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? Colors.red : primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: _baseTextStyle.copyWith(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: cardColor,
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      width: 400,
      duration: duration,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
      ),
      action: action,
    );
  }

  // Helper method for success SnackBar
  static void showSuccessSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      getStyledSnackBar(
        context: context,
        message: message,
        isError: false,
        duration: duration,
        action: action,
      ),
    );
  }

  // Helper method for error SnackBar
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      getStyledSnackBar(
        context: context,
        message: message,
        isError: true,
        duration: duration,
        action: action,
      ),
    );
  }

  /// Retorna un conjunto de sombras para usar en la aplicación
  static List<BoxShadow> get commonShadows => <BoxShadow>[
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          spreadRadius: 1,
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ];

  /// Aplica un gradiente de color primario a rojo
  static LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          primaryColor,
          Color(0xFFC41015),
        ],
      );
}
