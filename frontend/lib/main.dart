import 'dart:io';

import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/components/proforma_notification.dart';
import 'package:condorsmotors/providers/admin/index.admin.provider.dart';
import 'package:condorsmotors/providers/computer/index.computer.provider.dart';
import 'package:condorsmotors/providers/paginacion.provider.dart';
import 'package:condorsmotors/routes/routes.dart' as routes;
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/utils/role_utils.dart' as role_utils;
import 'package:condorsmotors/widgets/connection_status.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Configuración global de API
late CondorMotorsApi api;

// Instancia global del sistema de notificaciones
final ProformaNotification proformaNotification = ProformaNotification();

// Lista de servidores posibles para intentar conectarse
final List<String> _serverUrls = <String>[
  'http://192.168.1.66:3000/api', // IP del servidor en la red local
  'http://192.168.1.42:3000/api', // IP de tu PC en la red WiFi local
  'http://192.168.1.42:3000/api', // IP principal
  'http://localhost:3000/api', // Servidor local
  'http://127.0.0.1:3000/api', // Localhost alternativo
  'http://10.0.2.2:3000/api', // Emulador Android
];

// Función para inicializar la API global
void initializeApi(CondorMotorsApi instance) {
  api = instance;
}

// Clave global para el navegador
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Clave global para el ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// Comprobar conectividad con un servidor
Future<bool> _checkServerConnectivity(String url) async {
  try {
    debugPrint('Comprobando conectividad con: $url');
    final Uri uri = Uri.parse(url.replaceAll('/api', ''));
    final Socket socket =
        await Socket.connect(uri.host, uri.port, timeout: Duration(seconds: 3));
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
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('server_url', url);
}

// Obtener la última URL del servidor usada
Future<String?> _getLastServerUrl() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
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

  // Inicializar sistema de notificaciones para Windows
  if (!kIsWeb && Platform.isWindows) {
    debugPrint('Inicializando sistema de notificaciones para proformas...');
    await proformaNotification.init();
  }

  // Inicializar API
  debugPrint('Inicializando API...');

  // Obtener la última URL usada
  final String? lastUrl = await _getLastServerUrl();
  if (lastUrl != null) {
    _serverUrls.insert(0, lastUrl); // Priorizar la última URL usada
  }

  // Verificar conectividad con los servidores en orden
  String? workingUrl;
  for (final String url in _serverUrls) {
    if (await _checkServerConnectivity(url)) {
      workingUrl = url;
      break;
    }
  }

  // Si no se encuentra ningún servidor disponible, usar el primero de la lista
  final String baseUrl = workingUrl ?? _serverUrls.first;
  debugPrint('URL base de la API: $baseUrl');

  // Guardar la URL seleccionada para futuras sesiones
  if (workingUrl != null) {
    await _saveServerUrl(workingUrl);
  }

  // Inicializar la API global
  final apiInstance = CondorMotorsApi(baseUrl: baseUrl);
  initializeApi(apiInstance);
  debugPrint('API inicializada correctamente');

  // Verificar autenticación del usuario
  debugPrint('Verificando autenticación del usuario...');
  final bool isAuthenticated = await api.auth.isAuthenticated();
  String initialRoute = role_utils.login;
  Map<String, dynamic>? userData;

  if (isAuthenticated) {
    // Verificar si el token es realmente válido intentando hacer una petición sencilla
    try {
      debugPrint('Validando token con el servidor...');
      final bool isTokenValid = await api.auth.verificarToken();

      if (!isTokenValid) {
        debugPrint('Token no validado por el servidor, redirigiendo a login');
        // Limpiar token inválido
        await api.auth.clearTokens();
        initialRoute = role_utils.login;
      } else {
        debugPrint('Token validado correctamente con el servidor');
      }
    } catch (e) {
      debugPrint('Error al validar token: $e');
      // Si hay un error, considerar que no está autenticado
      initialRoute = role_utils.login;
      // Limpiar token inválido
      await api.auth.clearTokens();
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
          final String rolUpper = rol.toUpperCase();
          if (role_utils.roles.containsKey(rolUpper)) {
            userData['rol'] = rolUpper;
            debugPrint('Rol normalizado a mayúsculas: ${userData['rol']}');
          }
          // Verificar casos específicos conocidos
          else if (rol == 'adminstrador' || rolUpper == 'ADMINSTRADOR') {
            userData['rol'] = 'ADMINISTRADOR';
            debugPrint(
                'Rol normalizado manualmente de "$rol" a "ADMINISTRADOR"');
          } else if (rol == 'computadora' || rolUpper == 'COMPUTADORA') {
            userData['rol'] = 'COMPUTADORA';
            debugPrint('Rol normalizado manualmente de "$rol" a "COMPUTADORA"');
          } else if (rol == 'vendedor' || rolUpper == 'VENDEDOR') {
            userData['rol'] = 'VENDEDOR';
            debugPrint('Rol normalizado manualmente de "$rol" a "VENDEDOR"');
          } else {
            // Si el rol no es reconocido, forzar logout
            debugPrint('Rol no reconocido: $rol, forzando logout');
            await api.auth.clearTokens();
            userData = null;
          }
        }

        // Si tenemos un rol normalizado válido, obtener la ruta inicial
        if (userData != null) {
          initialRoute = role_utils.getInitialRoute(userData['rol'] as String);
          debugPrint(
              'Usuario autenticado con rol: ${userData['rol']}, redirigiendo a $initialRoute');
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VentasComputerProvider()),
        // Provider para paginación global
        ChangeNotifierProvider<PaginacionProvider>(
          create: (_) => PaginacionProvider(),
        ),
        // Providers de administración
        ChangeNotifierProvider<CategoriasProvider>(
          create: (_) => CategoriasProvider(),
        ),
        ChangeNotifierProvider<MarcasProvider>(
          create: (_) => MarcasProvider(),
        ),
        ChangeNotifierProvider<EmpleadoProvider>(
          create: (_) => EmpleadoProvider(),
        ),
        ChangeNotifierProvider<MovimientoProvider>(
          create: (_) => MovimientoProvider(),
        ),
        ChangeNotifierProvider<ProductoProvider>(
          create: (_) => ProductoProvider(),
        ),
        ChangeNotifierProvider<StockProvider>(
          create: (_) => StockProvider(),
        ),
        ChangeNotifierProvider<SucursalProvider>(
          create: (_) => SucursalProvider(),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (_) => DashboardProvider(),
        ),
        // Providers para módulo de computadora
        ChangeNotifierProvider<ProformaComputerProvider>(
          create: (_) => ProformaComputerProvider(),
        ),
        // Aquí puedes agregar más providers según sea necesario
      ],
      child: ConnectionStatusWidget(
        child: CondorMotorsApp(
          initialRoute: initialRoute,
          userData: userData,
        ),
      ),
    ),
  );
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
    final MaterialApp app = MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Condor Motors',
      theme: AppTheme.theme,
      onGenerateRoute: (RouteSettings settings) {
        return routes.generateRoute(
          settings,
          initialRoute: initialRoute,
          userData: userData,
        );
      },
      initialRoute: initialRoute,
    );

    // Envolver la aplicación con MultiProvider para gestionar los estados
    // y después con el widget de estado de conexión
    return MultiProvider(
      providers: [
        // Provider para paginación global
        ChangeNotifierProvider<PaginacionProvider>(
          create: (_) => PaginacionProvider(),
        ),
        // Providers de administración
        ChangeNotifierProvider<CategoriasProvider>(
          create: (_) => CategoriasProvider(),
        ),
        ChangeNotifierProvider<MarcasProvider>(
          create: (_) => MarcasProvider(),
        ),
        ChangeNotifierProvider<EmpleadoProvider>(
          create: (_) => EmpleadoProvider(),
        ),
        ChangeNotifierProvider<MovimientoProvider>(
          create: (_) => MovimientoProvider(),
        ),
        ChangeNotifierProvider<ProductoProvider>(
          create: (_) => ProductoProvider(),
        ),
        ChangeNotifierProvider<StockProvider>(
          create: (_) => StockProvider(),
        ),
        ChangeNotifierProvider<VentasComputerProvider>(
          create: (_) {
            final provider = VentasComputerProvider();
            provider.messengerKey = scaffoldMessengerKey;
            return provider;
          },
        ),
        ChangeNotifierProvider<SucursalProvider>(
          create: (_) => SucursalProvider(),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (_) => DashboardProvider(),
        ),
        // Providers para módulo de computadora
        ChangeNotifierProvider<ProformaComputerProvider>(
          create: (_) => ProformaComputerProvider(),
        ),
        // Aquí puedes agregar más providers según sea necesario
      ],
      child: ConnectionStatusWidget(
        child: app,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('initialRoute', initialRoute))
      ..add(DiagnosticsProperty<Map<String, dynamic>?>('userData', userData));
  }
}
