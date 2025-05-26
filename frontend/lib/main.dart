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
import 'package:condorsmotors/screens/login.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/widgets/connection_status.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Inicializar dependencias críticas antes de runApp
  final SharedPreferences sharedPrefs = await SharedPreferences.getInstance();

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
    // Puedes agregar aquí un Provider para sharedPrefs si lo necesitas globalmente
    Provider<SharedPreferences>.value(value: sharedPrefs),
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
    Phoenix(
      child: MultiProvider(
        providers: [
          ...globalProviders,
          ...adminProviders,
          ...computerProviders,
          ...colabProviders,
          // Aquí puedes agregar más grupos de providers según sea necesario
        ],
        child: AppInitializer(
          child: ConnectionStatusWidget(
            child: CondorMotorsApp(),
          ),
        ),
      ),
    ),
  );
}

/// Widget que muestra un splash/loading mientras se inicializan dependencias críticas
class AppInitializer extends StatefulWidget {
  final Widget child;
  const AppInitializer({super.key, required this.child});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Aquí podrías inicializar otras dependencias críticas si lo necesitas
      setState(() => _initialized = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }
    if (!_initialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: Center(
          child: Column(
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
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Inicializando dependencias...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    return widget.child;
  }
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
      home: const LoginScreen(),
    );
  }
}
