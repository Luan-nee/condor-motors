import 'dart:io';

import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/components/proforma_notification.dart';
import 'package:condorsmotors/providers/admin/index.admin.provider.dart';
import 'package:condorsmotors/providers/auth.provider.dart';
import 'package:condorsmotors/providers/colabs/index.colab.provider.dart';
import 'package:condorsmotors/providers/computer/index.computer.provider.dart';
import 'package:condorsmotors/providers/login.provider.dart';
import 'package:condorsmotors/providers/paginacion.provider.dart';
import 'package:condorsmotors/repositories/auth.repository.dart';
import 'package:condorsmotors/routes/routes.dart' as routes;
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/utils/role_utils.dart' as role_utils;
import 'package:condorsmotors/widgets/connection_status.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Configuración global de API
// Nota: La variable api ahora se define en index.api.dart

// Instancia global del sistema de notificaciones
final ProformaNotification proformaNotification = ProformaNotification();

// Clave global para el navegador
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Clave global para el ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

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

  // Inicializar API usando la función centralizada en index.api.dart
  await initializeApi();

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
          create: (_) => LoginProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthRepository.instance),
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
          create: (_) => TransferenciasProvider(),
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
          create: (context) => ProformaComputerProvider(
            Provider.of<VentasComputerProvider>(context, listen: false),
          ),
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
          create: (_) => TransferenciasProvider(),
        ),
        ChangeNotifierProvider<ProductoProvider>(
          create: (_) => ProductoProvider(),
        ),
        ChangeNotifierProvider<StockProvider>(
          create: (_) => StockProvider(),
        ),
        ChangeNotifierProvider<VentasComputerProvider>(
          create: (_) =>
              VentasComputerProvider()..messengerKey = scaffoldMessengerKey,
        ),
        ChangeNotifierProvider<SucursalProvider>(
          create: (_) => SucursalProvider(),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (_) => DashboardProvider(),
        ),
        // Providers para módulo de computadora
        ChangeNotifierProvider<ProformaComputerProvider>(
          create: (context) => ProformaComputerProvider(
            Provider.of<VentasComputerProvider>(context, listen: false),
          ),
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
