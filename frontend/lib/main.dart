import 'dart:io';

import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/components/proforma_notification.dart';
import 'package:condorsmotors/providers/admin/index.admin.provider.dart';
import 'package:condorsmotors/providers/auth.provider.dart';
import 'package:condorsmotors/providers/colabs/index.colab.provider.dart';
import 'package:condorsmotors/providers/computer/index.computer.provider.dart';
import 'package:condorsmotors/providers/login.provider.dart';
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
  'http://192.168.1.42:3000/api', // IP de tu PC en la red WiFi local
  'http://localhost:3000/api', // Servidor local
  'http://127.0.0.1:3000/api', // Localhost alternativo
  'http://10.0.2.2:3000/api', // Emulador Android
  'https://fseh2hb1d1h2ra5822cdvo.top/api', // En Producción
];

// Función para construir URL completa del servidor
String buildServerUrl(String host, {int? port}) {
  if (host.startsWith('http://') || host.startsWith('https://')) {
    final Uri uri = Uri.parse(host);
    // Si ya tiene puerto y path, retornar como está
    if (uri.hasPort && uri.path.isNotEmpty) {
      return host;
    }
    // Si ya tiene puerto pero no path
    if (uri.hasPort) {
      return '${host.trimRight()}/api';
    }
    // Si no tiene puerto pero es HTTPS o tiene path
    if (uri.scheme == 'https' || uri.path.isNotEmpty) {
      return host;
    }
    // Si es HTTP y no tiene puerto ni path
    return '${host.trimRight()}:${port ?? 3000}/api';
  }
  // Si es solo un host sin protocolo
  return 'http://$host:${port ?? 3000}/api';
}

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
    final Uri uri = Uri.parse(url);
    final Socket socket = await Socket.connect(
        uri.host, uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 3000),
        timeout: const Duration(seconds: 3));
    socket.destroy();
    debugPrint('Conexión exitosa con: $url');
    return true;
  } catch (e) {
    debugPrint('No se pudo conectar a: $url - Error: $e');
    return false;
  }
}

// Guardar la URL del servidor en preferencias
Future<void> _saveServerUrl(String url, {int? port}) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String fullUrl = buildServerUrl(url, port: port);
  await prefs.setString('server_url', fullUrl);
  if (port != null) {
    await prefs.setInt('server_port', port);
  }
}

// Obtener la última URL y puerto del servidor usados
Future<Map<String, dynamic>> _getLastServerConfig() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? url = prefs.getString('server_url');
  final int? port = prefs.getInt('server_port');
  return {
    'url': url,
    'port': port,
  };
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

  // Obtener la última configuración usada
  final Map<String, dynamic> lastConfig = await _getLastServerConfig();
  if (lastConfig['url'] != null) {
    _serverUrls.insert(0, lastConfig['url'] as String);
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
    await _saveServerUrl(workingUrl, port: lastConfig['port']);
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
    try {
      debugPrint('Validando token con el servidor...');
      final bool isTokenValid = await api.auth.verificarToken();

      if (!isTokenValid) {
        debugPrint('Token no validado por el servidor, redirigiendo a login');
        await api.auth.clearTokens();
        initialRoute = role_utils.login;
      } else {
        debugPrint('Token validado correctamente con el servidor');
        userData = await api.authService.getUserData();

        if (userData != null && userData['rol'] != null) {
          // Extraer el código del rol correctamente
          String rolCodigo;
          if (userData['rol'] is Map) {
            rolCodigo = userData['rol']['codigo']?.toString() ?? '';
          } else {
            rolCodigo = userData['rol'].toString();
          }

          // Normalizar y obtener la ruta inicial
          final String rolNormalizado = role_utils.normalizeRole(rolCodigo);
          initialRoute = role_utils.getInitialRoute(rolNormalizado);

          debugPrint(
              'Usuario autenticado con rol: $rolCodigo, redirigiendo a $initialRoute');
        } else {
          debugPrint('No se encontraron datos de usuario válidos');
          initialRoute = role_utils.login;
        }
      }
    } catch (e) {
      debugPrint('Error al validar token: $e');
      await api.auth.clearTokens();
      initialRoute = role_utils.login;
    }
  } else {
    debugPrint('No se encontró un token válido, redirigiendo a login');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LoginProvider(api: api),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(api.auth),
        ),
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
        ChangeNotifierProvider<TransferenciasProvider>(
          create: (_) => TransferenciasProvider(api.transferencias),
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
        // Provider para transferencias de colaboradores
        ChangeNotifierProvider<TransferenciasColabProvider>(
          create: (_) => TransferenciasColabProvider(),
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
      // Forzar el uso de Material 3 para mejor soporte de temas
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.theme,
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
        ChangeNotifierProvider<TransferenciasProvider>(
          create: (_) => TransferenciasProvider(api.transferencias),
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
        // Provider para transferencias de colaboradores
        ChangeNotifierProvider<TransferenciasColabProvider>(
          create: (_) => TransferenciasColabProvider(),
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
