import 'dart:async';

import 'package:condorsmotors/providers/auth.riverpod.dart';
import 'package:condorsmotors/screens/widgets/login_form.widget.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/utils/role_utils.dart' as role_utils;
import 'package:condorsmotors/widgets/background.dart';
import 'package:condorsmotors/widgets/dialogs/server_config.dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Clase para manejar el ciclo de vida de la aplicación
class LifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback resumeCallBack;
  final VoidCallback pauseCallBack;

  LifecycleObserver({
    required this.resumeCallBack,
    required this.pauseCallBack,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      resumeCallBack();
    } else if (state == AppLifecycleState.paused) {
      pauseCallBack();
    }
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _stayLoggedIn = false;
  String _errorMessage = '';
  String _serverIp = 'localhost';
  String _savedUsername = '';
  String _savedPassword = '';
  bool _hasNavigated = false;

  late final AnimationController _animationController;
  late final LifecycleObserver _lifecycleObserver;
  Future<bool>? _autoLoginFuture;
  DateTime? _loginTransitionStart;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    );
    _animationController.repeat();
    _loadServerIp();
    _loadRememberedCredentials();
    _autoLoginFuture = _getAutoLoginFuture();
    _lifecycleObserver = LifecycleObserver(
      resumeCallBack: () {
        if (!_animationController.isAnimating) {
          _animationController.repeat();
        }
      },
      pauseCallBack: () {
        if (_animationController.isAnimating) {
          _animationController.stop();
        }
      },
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  Future<void> _loadServerIp() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? serverUrl = prefs.getString('server_url');

      if (!mounted) {
        return;
      }

      if (serverUrl != null && serverUrl.isNotEmpty) {
        final Uri uri = Uri.parse(serverUrl);
        if (!mounted) {
          return;
        }
        setState(() {
          _serverIp = uri.host;
        });
      } else {
        if (!mounted) {
          return;
        }
        setState(() {
          _serverIp = 'localhost';
        });
      }
    } catch (e) {
      debugPrint('Error al cargar la URL del servidor: $e');
      if (!mounted) {
        return;
      }
      setState(() {
        _serverIp = 'localhost';
      });
    }
  }

  Future<void> _loadRememberedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('remember_me') ?? false;
      final stayLoggedIn = prefs.getBool('stay_logged_in') ?? false;

      if (!mounted) {
        return;
      }

      setState(() {
        _rememberMe = rememberMe;
        _stayLoggedIn = stayLoggedIn;
      });

      if (rememberMe) {
        const storage = FlutterSecureStorage();
        final username = await storage.read(key: 'username');
        final password = await storage.read(key: 'password');
        
        if (!mounted) {
          return;
        }

        setState(() {
          _savedUsername = username ?? '';
          _savedPassword = password ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error al cargar credenciales guardadas: $e');
    }
  }

  Future<bool> _getAutoLoginFuture() async {
    final prefs = await SharedPreferences.getInstance();
    final stayLoggedIn = prefs.getBool('stay_logged_in') ?? false;
    if (stayLoggedIn && mounted) {
      return ref.read(authProvider.notifier).autoLogin();
    }
    return false;
  }

  void _showServerConfigDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => ServerConfigDialog(
        currentServerIp: _serverIp,
      ),
    );
  }

  Future<void> _handleLogin({
    required String username,
    required String password,
    required bool rememberMe,
    required bool stayLoggedIn,
  }) async {
    debugPrint('[LoginScreen] Iniciando procesamiento de login');
    _loginTransitionStart = DateTime.now();
    final authNotifier = ref.read(authProvider.notifier);
    if (authNotifier.isAutoLoggingIn) {
      debugPrint('[LoginScreen] Ignorado: autoLogin en progreso');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _rememberMe = rememberMe;
      _stayLoggedIn = stayLoggedIn;
    });

    try {
      debugPrint('[LoginScreen] Llamando a authProvider.login...');
      final bool loginSuccess = await authNotifier.login(
        username,
        password,
        saveAutoLogin: stayLoggedIn,
      );
      debugPrint('[LoginScreen] Resultado login: $loginSuccess');

      if (!mounted) {
        debugPrint('[LoginScreen] Widget desmontado tras login');
        return;
      }

      setState(() => _isLoading = false);

      if (loginSuccess && !authNotifier.isAutoLoggingIn) {
        debugPrint('[LoginScreen] Login exitoso, procesando navegación');

        // Persistir preferencias locales de checkboxes
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', rememberMe);
        await prefs.setBool('stay_logged_in', stayLoggedIn);

        // Guardar o borrar credenciales seguras
        const storage = FlutterSecureStorage();
        if (rememberMe) {
          await storage.write(key: 'username', value: username);
          await storage.write(key: 'password', value: password);
        } else {
          await storage.delete(key: 'username');
          await storage.delete(key: 'password');
        }

        final user = ref.read(authProvider).user;
        if (user != null) {
          final result = role_utils.getRoleAndInitialRoute(user.toMap());
          final String initialRoute = result['route']!;
          final String rolNormalizado = result['rol']!;
          debugPrint(
              '[LoginScreen] Navegando a ruta: $initialRoute para rol: $rolNormalizado');
          
          final transitionEnd = DateTime.now();
          if (_loginTransitionStart != null) {
            final diff =
                transitionEnd.difference(_loginTransitionStart!).inMilliseconds;
            debugPrint(
                '[LoginScreen] Tiempo de transición login->admin: ${diff}ms');
            _loginTransitionStart = null;
          }

          if (!mounted) {
            return;
          }

          await Navigator.pushReplacementNamed(
            context,
            initialRoute,
            arguments: user.toMap(),
          );
        }
      } else if (!loginSuccess) {
        debugPrint('[LoginScreen] Login fallido');
        if (mounted) {
          setState(() {
            _errorMessage = 'Credenciales inválidas o usuario desactivado';
          });
        }
      }
    } catch (e) {
      debugPrint('[LoginScreen] Excepción en login: $e');
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        if (e.toString().contains('usuario o contraseña incorrectos') ||
            e.toString().toLowerCase().contains('incorrect')) {
          _errorMessage = 'Usuario o contraseña incorrectos';
        } else if (e.toString().contains('desactivado') ||
            e.toString().toLowerCase().contains('inactive')) {
          _errorMessage =
              'El usuario está desactivado. Contacte al administrador.';
        } else {
          _errorMessage = 'Error al iniciar sesión: $e';
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            ),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () => _handleLogin(
                username: username,
                password: password,
                rememberMe: rememberMe,
                stayLoggedIn: stayLoggedIn,
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[LoginScreen] build ejecutado');
    return FutureBuilder<bool>(
      future: _autoLoginFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.darkSurface,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: Image.asset(
                      'assets/images/condor-motors-logo.webp',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Iniciando sesión automáticamente...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error en auto-login: ${snapshot.error}'),
                backgroundColor: Colors.red,
              ),
            );
          });
          return _buildMainLayout(context);
        } else if (snapshot.data == true) {
          if (!_hasNavigated) {
            _hasNavigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final user = ref.read(authProvider).user;
              if (user != null) {
                final result = role_utils.getRoleAndInitialRoute(user.toMap());
                final String initialRoute = result['route']!;
                
                if (!mounted) {
                  return;
                }

                await Navigator.pushReplacementNamed(
                  context,
                  initialRoute,
                  arguments: user.toMap(),
                );
              }
            });
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          return _buildMainLayout(context);
        }
      },
    );
  }

  Widget _buildMainLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkSurface,
      body: Stack(
        children: <Widget>[
          // Fondo animado optimizado
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (BuildContext context, Widget? child) {
                return CustomPaint(
                  painter: BackgroundPainter(
                    animation: _animationController,
                  ),
                );
              },
            ),
          ),
          // Botón de configuración del servidor
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70),
              onPressed: _showServerConfigDialog,
              tooltip: 'Configurar servidor',
            ),
          ),
          // Componente de formulario de login modular
          LoginForm(
            isLoading: _isLoading,
            errorMessage: _errorMessage,
            initialUsername: _savedUsername,
            initialPassword: _savedPassword,
            initialRememberMe: _rememberMe,
            initialStayLoggedIn: _stayLoggedIn,
            onLoginSubmitted: _handleLogin,
          ),
        ],
      ),
    );
  }
}
