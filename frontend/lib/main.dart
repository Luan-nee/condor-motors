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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

// Configuración global de API
// Nota: La variable api ahora se define en index.api.dart

// Instancia global del sistema de notificaciones
final ProformaNotification proformaNotification = ProformaNotification();

// Clave global para el navegador
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Clave global para el ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// Instancia global para acceso desde interceptores (ej: main.api.dart)
late AuthProvider globalAuthProvider;

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
  await ApiInitializer.instance.initializeApiIfNeeded();

  // Inicializar globalAuthProvider ANTES de cualquier petición protegida
  globalAuthProvider = AuthProvider(AuthRepository.instance);

  // Agrupación de providers por dominio
  final List<SingleChildWidget> globalProviders = [
    ChangeNotifierProvider(
      create: (_) => LoginProvider(),
    ),
    ChangeNotifierProvider<AuthProvider>.value(
      value: globalAuthProvider,
    ),
    ChangeNotifierProvider(create: (_) => PaginacionProvider()),
  ];

  final List<SingleChildWidget> adminProviders = [
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
    ChangeNotifierProvider<PedidoAdminProvider>(
      create: (_) => PedidoAdminProvider(),
    ),
    ChangeNotifierProvider<DashboardProvider>(
      create: (_) => DashboardProvider(),
    ),
  ];

  final List<SingleChildWidget> computerProviders = [
    ChangeNotifierProvider<VentasComputerProvider>(
      create: (_) => VentasComputerProvider(),
    ),
    ChangeNotifierProvider<ProformaComputerProvider>(
      create: (context) => ProformaComputerProvider(
        Provider.of<VentasComputerProvider>(context, listen: false),
      ),
    ),
  ];

  final List<SingleChildWidget> colabProviders = [
    ChangeNotifierProvider<TransferenciasColabProvider>(
      create: (_) => TransferenciasColabProvider(),
    ),
  ];

  runApp(
    MultiProvider(
      providers: [
        ...globalProviders,
        ...adminProviders,
        ...computerProviders,
        ...colabProviders,
        // Aquí puedes agregar más grupos de providers según sea necesario
      ],
      child: ConnectionStatusWidget(
        child: CondorMotorsApp(),
      ),
    ),
  );
}

class CondorMotorsApp extends StatelessWidget {
  const CondorMotorsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Condor Motors',
      theme: AppTheme.theme,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.theme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''),
        Locale('en', ''),
      ],
      locale: const Locale('es', ''),
      onGenerateRoute: routes.generateRoute,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthAndRedirect();
  }

  Future<void> _checkAuthAndRedirect() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Timeout de 10 segundos para autenticación
      final result = await _tryAuthWithTimeout(const Duration(seconds: 10));
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(
        result['route'],
        arguments: result['userData'],
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<Map<String, dynamic>> _tryAuthWithTimeout(Duration timeout) async {
    return await (() async {
      debugPrint('Verificando autenticación del usuario (SplashScreen)...');
      final bool isAuthenticated = await api.auth.isAuthenticated();
      String initialRoute = role_utils.login;
      Map<String, dynamic>? userData;

      if (isAuthenticated) {
        try {
          debugPrint('Validando token con el servidor (centralizado)...');
          final bool isTokenValid =
              await globalAuthProvider.verifySessionOnce();

          if (!isTokenValid) {
            debugPrint(
                'Token no validado por el servidor, redirigiendo a login');
            await api.auth.clearTokens();
            initialRoute = role_utils.login;
          } else {
            debugPrint('Token validado correctamente con el servidor');
            userData = await api.authService.getUserData();

            if (userData != null && userData['rol'] != null) {
              final result = role_utils.getRoleAndInitialRoute(userData);
              final String rolNormalizado = result['rol']!;
              initialRoute = result['route']!;
              debugPrint(
                  'Usuario autenticado con rol: $rolNormalizado, redirigiendo a $initialRoute');
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
      return {'route': initialRoute, 'userData': userData};
    })()
        .timeout(timeout, onTimeout: () {
      throw Exception(
          'Tiempo de espera agotado al verificar autenticación. Verifica tu conexión o reintenta.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: Image.asset(
                      'assets/images/condor-motors-logo.webp',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Verificando autenticación...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage ?? 'Error desconocido',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _checkAuthAndRedirect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
      ),
    );
  }
}
