import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/api.service.dart';
import 'api/usuario.api.dart';
import 'api/productos.api.dart';

// Configuración global de APIs
late ApiService apiService;
late UsuarioApi usuarioApi;
late ProductosApi productosApi;

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

  // Verificar estado inicial de la API
  final apiService = ApiService();
  bool apiAvailable = false;

  try {
    debugPrint('Iniciando verificación de API...');
    apiAvailable = await apiService.checkApiStatus();
    debugPrint('Estado de la API: ${apiAvailable ? 'Online' : 'Offline'}');
  } catch (e) {
    debugPrint('Error al verificar API: $e');
  }

  // Inicializar servicios de API
  usuarioApi = UsuarioApi(apiService);
  productosApi = ProductosApi(apiService);

  // Mostrar estado de la API en consola
  debugPrint('URL Base: ${ApiService.baseUrl}');

  runApp(MyApp(
    isOnline: apiAvailable,
    apiService: apiService,
  ));
}

class MyApp extends StatelessWidget {
  final bool isOnline;
  final ApiService apiService;
  
  const MyApp({
    super.key, 
    required this.isOnline,
    required this.apiService,
  });

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
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE31E24),
          secondary: Color(0xFFE31E24),
          surface: Color(0xFF2D2D2D),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
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
      builder: (context, child) {
        return Banner(
          location: BannerLocation.topEnd,
          message: isOnline ? 'Online' : 'Offline',
          color: isOnline ? Colors.green : Colors.red,
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          child: child!,
        );
      },
      initialRoute: Routes.login,
      onGenerateRoute: Routes.generateRoute,
    );
  }
}
