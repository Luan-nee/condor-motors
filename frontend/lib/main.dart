import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routes/routes.dart';
import 'api/index.dart';

// Configuración global de API
late CondorMotorsApi api;

// Clave global para el navegador
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Definir fuentes una sola vez para reutilizarlas
final interFontFamily = GoogleFonts.inter().fontFamily;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Precarga de fuentes para evitar parpadeo
  GoogleFonts.config.allowRuntimeFetching = false;
  
  // Configurar UI del sistema
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1A1A1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Inicializar API con la URL base
  debugPrint('Inicializando API...');
  String apiBaseUrl = 'http://localhost:3000/api';
  
  // En un entorno de producción, podrías cargar la URL desde un archivo de configuración
  debugPrint('URL base de la API: $apiBaseUrl');
  
  api = CondorMotorsApi(baseUrl: apiBaseUrl);
  await api.initAuthService();
  debugPrint('API inicializada correctamente');

  // Verificar si el usuario ya está autenticado
  String initialRoute = Routes.login;
  Map<String, dynamic>? userData;
  
  try {
    debugPrint('Verificando autenticación del usuario...');
    final isAuthenticated = await api.authService.loadTokens();
    
    if (isAuthenticated) {
      debugPrint('Token encontrado, obteniendo datos del usuario');
      userData = api.authService.getUserData();
      
      if (userData != null) {
        final rol = userData['rol']?.toString().toUpperCase();
        debugPrint('Usuario autenticado con rol: $rol');
        
        // Verificar que el token sea válido haciendo una petición de prueba
        try {
          debugPrint('Verificando validez del token...');
          // Intentar hacer una petición simple para verificar el token
          await api.sucursales.getSucursales();
          debugPrint('Token válido, continuando...');
          
          if (rol != null && Routes.roles.containsKey(rol)) {
            initialRoute = Routes.getInitialRoute(rol);
            debugPrint('Ruta inicial determinada: $initialRoute');
          } else {
            debugPrint('Rol no válido o no reconocido: $rol');
            // Si el rol no es válido, redirigir al login
            initialRoute = Routes.login;
            userData = null;
            await api.authService.logout(); // Limpiar datos de sesión inválidos
          }
        } catch (e) {
          debugPrint('Error al verificar token: $e');
          
          // Intentar refrescar el token antes de rendirse
          try {
            debugPrint('Intentando refrescar el token...');
            final newToken = await api.auth.refreshToken();
            if (newToken.isNotEmpty) {
              debugPrint('Token refrescado correctamente, verificando nuevamente...');
              // Intentar nuevamente con el token refrescado
              await api.sucursales.getSucursales();
              debugPrint('Token refrescado válido, continuando...');
              
              if (rol != null && Routes.roles.containsKey(rol)) {
                initialRoute = Routes.getInitialRoute(rol);
                debugPrint('Ruta inicial determinada: $initialRoute');
                // Actualizar el token en userData
                userData!['token'] = newToken;
              } else {
                throw Exception('Rol no válido después de refrescar token');
              }
            } else {
              throw Exception('No se pudo obtener un nuevo token');
            }
          } catch (refreshError) {
            debugPrint('Error al refrescar token: $refreshError');
            // Si hay un error en la petición, el token probablemente es inválido
            initialRoute = Routes.login;
            userData = null;
            await api.authService.logout(); // Limpiar token inválido
          }
        }
      } else {
        debugPrint('No se pudieron recuperar los datos del usuario');
        initialRoute = Routes.login;
        await api.authService.logout(); // Limpiar datos de sesión incompletos
      }
    } else {
      debugPrint('Usuario no autenticado, redirigiendo a login');
    }
  } catch (e) {
    debugPrint('Error al verificar autenticación: $e');
    // En caso de error, redirigir al login
    initialRoute = Routes.login;
    // Intentar limpiar cualquier dato de sesión que pueda estar causando problemas
    try {
      await api.authService.logout();
    } catch (e) {
      debugPrint('Error al limpiar datos de sesión: $e');
    }
  }

  runApp(MyApp(
    initialRoute: initialRoute,
    userData: userData,
  ));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final Map<String, dynamic>? userData;
  
  const MyApp({
    Key? key, 
    required this.initialRoute,
    this.userData,
  }) : super(key: key);

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
          displayLarge: TextStyle(
            fontFamily: interFontFamily,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            height: 1.2,
          ),
          displayMedium: TextStyle(
            fontFamily: interFontFamily,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            height: 1.2,
          ),
          // Texto del cuerpo
          bodyLarge: TextStyle(
            fontFamily: interFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontFamily: interFontFamily,
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
            bodyLarge: TextStyle(fontFamily: interFontFamily, fontSize: 16, height: 1.5),
            bodyMedium: TextStyle(fontFamily: interFontFamily, fontSize: 14, height: 1.5),
          ),
          white: Typography.whiteMountainView.copyWith(
            bodyLarge: TextStyle(fontFamily: interFontFamily, fontSize: 16, height: 1.5),
            bodyMedium: TextStyle(fontFamily: interFontFamily, fontSize: 14, height: 1.5),
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
      navigatorKey: navigatorKey,
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        // Si tenemos datos de usuario y no estamos en la pantalla de login,
        // pasarlos como argumentos a la ruta
        if (userData != null && settings.name != Routes.login) {
          debugPrint('Pasando datos de usuario a la ruta ${settings.name}');
          return Routes.generateRoute(
            RouteSettings(
              name: settings.name,
              arguments: userData,
            ),
          );
        }
        return Routes.generateRoute(settings);
      },
      navigatorObservers: [
        HeroController(),
      ],
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
