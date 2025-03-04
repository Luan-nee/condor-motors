import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/main.api.dart';
import 'api/empleados.api.dart';
import 'api/productos.api.dart';
import 'api/sucursales.api.dart';

// Configuración global de APIs
late ApiService apiService;
late EmpleadoApi empleadoApi;
late ProductosApi productosApi;
late SucursalesApi sucursalesApi;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    SharedPreferences.setMockInitialValues({});
  }

  // Configurar UI del sistema
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1A1A1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Inicializar ApiService y servicios
  apiService = ApiService();
  await apiService.init();
  empleadoApi = EmpleadoApi(apiService);
  productosApi = ProductosApi(apiService);
  sucursalesApi = SucursalesApi(apiService);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Condors Motors',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFE31E24),
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFFE31E24),
          primary: const Color(0xFFE31E24),
          secondary: const Color(0xFF1E88E5),
        ),
        textTheme: TextTheme(
          // Títulos
          displayLarge: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            height: 1.2,
          ),
          displayMedium: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            height: 1.2,
          ),
          // Texto del cuerpo
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            height: 1.5,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.25,
            height: 1.5,
          ),
        ).apply(
          displayColor: Colors.white,
          bodyColor: Colors.white,
        ),
        platform: TargetPlatform.windows,
        typography: Typography.material2021(
          platform: TargetPlatform.windows,
          black: Typography.blackMountainView.copyWith(
            bodyLarge: GoogleFonts.inter(fontSize: 16, height: 1.5),
            bodyMedium: GoogleFonts.inter(fontSize: 14, height: 1.5),
          ),
          white: Typography.whiteMountainView.copyWith(
            bodyLarge: GoogleFonts.inter(fontSize: 16, height: 1.5),
            bodyMedium: GoogleFonts.inter(fontSize: 14, height: 1.5),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE31E24), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE31E24),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      initialRoute: Routes.login,
      onGenerateRoute: Routes.generateRoute,
    );
  }
}
