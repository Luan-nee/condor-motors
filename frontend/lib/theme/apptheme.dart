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
    appBarTheme: const AppBarTheme(
      backgroundColor: appBarColor,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: kFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    
    // Configuración de diálogos
    dialogTheme: DialogTheme(
      backgroundColor: cardColor,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: kFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: kFontFamily,
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
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    
    // Configuración de texto
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontFamily: kFontFamily,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontFamily: kFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontFamily: kFontFamily,
        fontSize: 16,
        color: Colors.white70,
      ),
      bodyMedium: TextStyle(
        fontFamily: kFontFamily,
        fontSize: 14,
        color: Colors.white70,
      ),
      labelLarge: TextStyle(
        fontFamily: kFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: spacingMedium, vertical: spacingMedium),
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
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.7),
      ),
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.5),
      ),
    ),
  );

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
