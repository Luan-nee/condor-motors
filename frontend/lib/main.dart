import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/index.dart';
import 'routes/routes.dart' as routes;
import 'services/token_service.dart';
import 'utils/role_utils.dart' as role_utils;
import 'widgets/connection_status.dart';

// Configuración global de API
late CondorMotorsApi api;

// Lista de servidores posibles para intentar conectarse
final List<String> _serverUrls = [
  'http://192.168.1.100:3000/api', // IP principal
  'http://localhost:3000/api',      // Servidor local
  'http://127.0.0.1:3000/api',      // Localhost alternativo
];

// Función para inicializar la API global
void initializeApi(CondorMotorsApi instance) {
  api = instance;
}

// Clave global para el navegador
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Nombre de la fuente principal
const String kFontFamily = 'SourceSans3';

// Comprobar conectividad con un servidor
Future<bool> _checkServerConnectivity(String url) async {
  try {
    debugPrint('Comprobando conectividad con: $url');
    final uri = Uri.parse(url.replaceAll('/api', ''));
    final socket = await Socket.connect(uri.host, uri.port, timeout: Duration(seconds: 3));
    socket.destroy();
    debugPrint('Conexión exitosa con: $url');
    return true;
  } catch (e) {
    debugPrint('No se pudo conectar a: $url - Error: $e');
    return false;
  }
}

// Guardar la URL del servidor en preferencias
Future<void> _saveServerUrl(String url) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('server_url', url);
}

// Obtener la última URL del servidor usada
Future<String?> _getLastServerUrl() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('server_url');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar UI del sistema
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1A1A1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Inicializar API
  debugPrint('Inicializando API...');
  
  // Obtener la última URL usada
  final lastUrl = await _getLastServerUrl();
  if (lastUrl != null) {
    _serverUrls.insert(0, lastUrl); // Priorizar la última URL usada
  }
  
  // Verificar conectividad con los servidores en orden
  String? workingUrl;
  for (final url in _serverUrls) {
    if (await _checkServerConnectivity(url)) {
      workingUrl = url;
      break;
    }
  }
  
  // Si no se encuentra ningún servidor disponible, usar el primero de la lista
  final baseUrl = workingUrl ?? _serverUrls.first;
  debugPrint('URL base de la API: $baseUrl');
  
  // Guardar la URL seleccionada para futuras sesiones
  if (workingUrl != null) {
    await _saveServerUrl(workingUrl);
  }
  
  final tokenService = TokenService.instance;
  
  // Configurar la URL base en TokenService
  tokenService.setBaseUrl(baseUrl);
  
  final apiInstance = CondorMotorsApi(baseUrl: baseUrl, tokenService: tokenService);
  
  // Inicializar la API global
  initializeApi(apiInstance);
  debugPrint('API inicializada correctamente');
  
  // Verificar autenticación del usuario
  debugPrint('Verificando autenticación del usuario...');
  final isAuthenticated = await tokenService.loadTokens();
  String initialRoute = role_utils.login;
  Map<String, dynamic>? userData;
  
  if (isAuthenticated) {
    // Verificar si el token es realmente válido intentando hacer una petición sencilla
    try {
      debugPrint('Validando token con el servidor...');
      // En lugar de solo hacer ping, verificamos si el token es válido
      // usando el endpoint específico para ello
      final isTokenValid = await apiInstance.auth.verificarToken();
      
      if (!isTokenValid) {
        debugPrint('Token no validado por el servidor, redirigiendo a login');
        // Limpiar token inválido
        await tokenService.clearTokens();
        initialRoute = role_utils.login;
      } else {
        debugPrint('Token validado correctamente con el servidor');
      }
    } catch (e) {
      debugPrint('Error al validar token: $e');
      // Si hay un error, considerar que no está autenticado
      initialRoute = role_utils.login;
      // Limpiar token inválido
      await tokenService.clearTokens();
    }

    if (initialRoute != role_utils.login) {
      // Obtener datos del usuario guardados de forma segura
      userData = await api.authService.getUserData();
      
      if (userData != null && userData['rol'] != null) {
        // Normalizar el rol para asegurarnos de que es válido
        final String rol = userData['rol'] as String;
        
        // Verificar si necesitamos normalizar el rol
        if (!role_utils.roles.containsKey(rol)) {
          // Intentar con versión en mayúsculas
          final rolUpper = rol.toUpperCase();
          if (role_utils.roles.containsKey(rolUpper)) {
            userData['rol'] = rolUpper;
            debugPrint('Rol normalizado a mayúsculas: ${userData['rol']}');
          } 
          // Verificar casos específicos conocidos
          else if (rol == 'adminstrador' || rolUpper == 'ADMINSTRADOR') {
            userData['rol'] = 'ADMINISTRADOR';
            debugPrint('Rol normalizado manualmente de "$rol" a "ADMINISTRADOR"');
          }
          else if (rol == 'computadora' || rolUpper == 'COMPUTADORA') {
            userData['rol'] = 'COMPUTADORA';
            debugPrint('Rol normalizado manualmente de "$rol" a "COMPUTADORA"');
          }
          else if (rol == 'vendedor' || rolUpper == 'VENDEDOR') {
            userData['rol'] = 'VENDEDOR';
            debugPrint('Rol normalizado manualmente de "$rol" a "VENDEDOR"');
          }
          else {
            // Si el rol no es reconocido, forzar logout
            debugPrint('Rol no reconocido: $rol, forzando logout');
            await api.authService.logout();
            userData = null;
          }
        }
        
        // Si tenemos un rol normalizado válido, obtener la ruta inicial
        if (userData != null) {
          initialRoute = role_utils.getInitialRoute(userData['rol'] as String);
          debugPrint('Usuario autenticado con rol: ${userData['rol']}, redirigiendo a $initialRoute');
        }
      } else {
        debugPrint('No se encontró un token válido, redirigiendo a login');
      }
    } else {
      debugPrint('No se encontró un token válido, redirigiendo a login');
    }
  } else {
    debugPrint('No se encontró un token válido, redirigiendo a login');
  }
  
  runApp(CondorMotorsApp(
    initialRoute: initialRoute,
    userData: userData,
  ));
}

class CondorMotorsApp extends StatelessWidget {
  final String initialRoute;
  final Map<String, dynamic>? userData;

  const CondorMotorsApp({
    super.key,
    required this.initialRoute,
    this.userData,
  });

  @override
  Widget build(BuildContext context) {
    // Crear la aplicación base
    final app = MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Condor Motors',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE31E24),
          brightness: Brightness.dark,
        ),
        fontFamily: kFontFamily,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        
        // Configuración de AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
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
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
            backgroundColor: const Color(0xFFE31E24),
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontFamily: kFontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
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
      ),
      onGenerateRoute: (settings) {
        return routes.generateRoute(
          settings,
          initialRoute: initialRoute,
          userData: userData,
        );
      },
      initialRoute: initialRoute,
    );
    
    // Envolver la aplicación con el widget de estado de conexión
    // Esto mostrará una barra de estado cuando haya problemas de conectividad
    return ConnectionStatusWidget(
      child: app,
    );
  }
}
