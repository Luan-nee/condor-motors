import 'dart:async';

import 'package:condorsmotors/api/auth.api.dart';
import 'package:condorsmotors/api/index.api.dart' show CondorMotorsApi;
import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/providers/login.provider.dart';
import 'package:condorsmotors/utils/role_utils.dart'
    as role_utils; // Importar utilidad de roles con alias
import 'package:condorsmotors/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importar para KeyboardListener
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importamos SharedPreferences

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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  bool _capsLockOn = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _stayLoggedIn = false; // Variable para "Permanecer conectado"
  late final AnimationController _animationController;
  final String _errorMessage = '';
  String _serverIp = 'localhost'; // IP local para el servidor
  late final LifecycleObserver _lifecycleObserver;
  bool _isCheckingAutoLogin = true; // Flag para controlar el auto-login

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    // Configuramos una animación con una curva más suave y una duración más larga
    // para que el loop sea menos perceptible
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
          seconds: 10), // Aumentamos la duración para un ciclo más largo
    );

    // Iniciamos con una curva de animación suave
    _animationController.repeat();

    _loadServerIp();

    // Intentamos auto-login antes de cargar las credenciales normales
    _tryAutoLogin().then((_) {
      // Si no hubo auto-login exitoso, cargamos las credenciales guardadas
      if (mounted && !_isCheckingAutoLogin) {
        _loadSavedCredentials();
        _loadStayLoggedInPreference();
      }
    });

    // Reducir la velocidad de la animación cuando la app está en segundo plano
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

  Future<void> _loadServerIp() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? serverUrl = prefs.getString('server_url');

      if (serverUrl != null && serverUrl.isNotEmpty) {
        final Uri uri = Uri.parse(serverUrl);
        setState(() {
          _serverIp = uri.host;
        });
        // Actualizar la URL base de la API global
        await _updateApiBaseUrl(serverUrl);
      } else {
        // Si no hay URL guardada, usar localhost
        setState(() {
          _serverIp = 'localhost';
        });
        // Actualizar la URL base de la API global con localhost
        await _updateApiBaseUrl('http://localhost:3000/api');
      }
    } catch (e) {
      debugPrint('Error al cargar la URL del servidor: $e');
      // En caso de error, asegurar que se use localhost
      setState(() {
        _serverIp = 'localhost';
      });
      // Actualizar la URL base de la API global
      await _updateApiBaseUrl('http://localhost:3000/api');
    }
  }

  // Método para intentar iniciar sesión automáticamente
  Future<void> _tryAutoLogin() async {
    setState(() {
      _isCheckingAutoLogin = true;
      _isLoading = true;
    });

    try {
      // Obtenemos las SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Verificamos si "Permanecer conectado" está activado
      final bool stayLoggedIn = prefs.getBool('stay_logged_in') ?? false;
      debugPrint(
          'Auto-login: Permanecer conectado está ${stayLoggedIn ? 'activado' : 'desactivado'}');

      if (!stayLoggedIn) {
        debugPrint('Auto-login: No está activado "Permanecer conectado"');
        setState(() {
          _isCheckingAutoLogin = false;
          _isLoading = false;
        });
        return;
      }

      // Obtenemos las credenciales guardadas
      final String? username = prefs.getString('username_auto');
      final String? password = prefs.getString('password_auto');

      if (username == null ||
          password == null ||
          username.isEmpty ||
          password.isEmpty) {
        debugPrint('Auto-login: No hay credenciales guardadas');
        setState(() {
          _isCheckingAutoLogin = false;
          _isLoading = false;
        });
        return;
      }

      debugPrint(
          'Auto-login: Intentando iniciar sesión automáticamente con usuario: $username');

      // Intentamos el login
      final UsuarioAutenticado usuarioAutenticado = await api.auth.login(
        username,
        password,
      );

      debugPrint(
          'Auto-login: Login exitoso, usuario autenticado: $usuarioAutenticado');

      // Guardar los datos del usuario en el servicio global de autenticación
      try {
        await api.authService.saveUserData(usuarioAutenticado);
        debugPrint(
            'Auto-login: Datos de usuario guardados correctamente en el servicio global');
      } catch (e) {
        debugPrint(
            'Auto-login: Error al guardar datos en el servicio global: $e');
      }

      // Si llegamos hasta aquí, el login fue exitoso, navegamos a la pantalla correspondiente
      if (!mounted) {
        return;
      }

      // Determinamos la ruta inicial basada en el rol normalizado
      final String rolCodigo = usuarioAutenticado.rolCuentaEmpleadoCodigo;
      final String rolNormalizado = role_utils.normalizeRole(rolCodigo);
      final String initialRoute = role_utils.getInitialRoute(rolNormalizado);

      debugPrint('Auto-login: Navegando a la ruta inicial: $initialRoute');

      // Navegamos a la pantalla correspondiente
      if (!mounted) {
        return;
      }

      await Navigator.pushReplacementNamed(
        context,
        initialRoute,
        arguments: usuarioAutenticado.toMap(),
      );
    } catch (e) {
      // Si hay un error en el auto-login, simplemente mostramos la pantalla de login normal
      debugPrint(
          'Auto-login: Error durante el inicio de sesión automático: $e');
      if (mounted) {
        setState(() {
          _isCheckingAutoLogin = false;
          _isLoading = false;
        });
      }
    }
  }

  // Método para actualizar la URL base de la API global
  Future<void> _updateApiBaseUrl(String serverUrl) async {
    debugPrint('Actualizando URL base de la API a: $serverUrl');
    try {
      // Reinicializar la API global con la nueva URL base
      api = CondorMotorsApi(
        baseUrl: serverUrl,
      );

      // Verificar conectividad con el servidor
      final bool isConnected = await api.checkConnectivity();
      if (!isConnected) {
        debugPrint('No se pudo establecer conexión con el servidor');
        throw Exception('No se pudo establecer conexión con el servidor');
      }

      debugPrint('API inicializada correctamente con nueva URL base');
    } catch (e) {
      debugPrint('Error al inicializar API con nueva URL base: $e');
      rethrow;
    }
  }

  Future<void> _saveServerIp(String serverIp, {int? port}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Construir la URL completa usando la función del main.dart
      String fullUrl = serverIp;
      if (!serverIp.startsWith('http://') && !serverIp.startsWith('https://')) {
        fullUrl = 'http://$serverIp${port != null ? ':$port' : ':3000'}/api';
      } else if (!serverIp.contains(':') && !serverIp.startsWith('https://')) {
        // Si es http pero no tiene puerto
        fullUrl = '$serverIp${port != null ? ':$port' : ':3000'}/api';
      }

      // Guardar la URL completa y el puerto
      await prefs.setString('server_url', fullUrl);
      if (port != null) {
        await prefs.setInt('server_port', port);
      }

      setState(() {
        _serverIp = serverIp;
      });

      // Actualizar la URL base de la API global
      await _updateApiBaseUrl(fullUrl);

      debugPrint('URL del servidor guardada: $fullUrl');
    } catch (e) {
      debugPrint('Error al guardar la URL del servidor: $e');
      rethrow;
    }
  }

  void _showServerConfigDialog() {
    final TextEditingController ipController =
        TextEditingController(text: _serverIp);
    final TextEditingController portController =
        TextEditingController(text: '3000');

    // Lista de servidores disponibles
    final List<Map<String, dynamic>> serverConfigs = <Map<String, dynamic>>[
      {'url': 'http://192.168.1.42', 'port': 3000},
      {'url': 'http://localhost', 'port': 3000},
      {'url': 'http://127.0.0.1', 'port': 3000},
      {'url': 'http://10.0.2.2', 'port': 3000},
      {'url': 'https://fseh2hb1d1h2ra5822cdvo.top/api', 'port': null},
    ];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Configuración del Servidor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Seleccione un servidor predefinido:',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              ...serverConfigs.map((Map<String, dynamic> config) => ListTile(
                    title: Text(
                      config['port'] != null
                          ? '${config['url']}:${config['port']}'
                          : config['url'] as String,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () async {
                      Navigator.pop(dialogContext);
                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        await _saveServerIp(
                          config['url'] as String,
                          port: config['port'] as int?,
                        );

                        if (!mounted) {
                          return;
                        }

                        setState(() {
                          _isLoading = false;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Servidor actualizado a: ${config['url']}${config['port'] != null ? ':${config['port']}' : ''}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) {
                          return;
                        }

                        setState(() {
                          _isLoading = false;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al actualizar servidor: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  )),
              const Divider(),
              Text(
                'O ingrese una dirección personalizada:',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: TextFormField(
                      controller: ipController,
                      decoration: InputDecoration(
                        labelText: 'Dirección del Servidor',
                        hintText: 'Ej: localhost o 192.168.1.66',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: portController,
                      decoration: InputDecoration(
                        labelText: 'Puerto',
                        hintText: '3000',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• Para desarrollo local (PC): localhost o 127.0.0.1\n'
                '• Para emuladores Android: 10.0.2.2\n'
                '• Para dispositivos físicos: IP de tu PC en la red WiFi\n'
                '• Puerto por defecto: 3000\n'
                '• Para dominios HTTPS no es necesario el puerto',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final String newIp = ipController.text.trim();
              final String portText = portController.text.trim();

              if (newIp.isNotEmpty) {
                Navigator.pop(dialogContext);
                setState(() {
                  _isLoading = true;
                });

                try {
                  int? port;
                  if (portText.isNotEmpty && !newIp.startsWith('https://')) {
                    port = int.tryParse(portText);
                  }

                  await _saveServerIp(newIp, port: port);

                  if (!mounted) {
                    return;
                  }

                  setState(() {
                    _isLoading = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Servidor actualizado a: $newIp${port != null ? ':$port' : ''}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) {
                    return;
                  }

                  setState(() {
                    _isLoading = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al actualizar servidor: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.capsLock) {
      setState(() {
        _capsLockOn = HardwareKeyboard.instance.lockModesEnabled
            .contains(KeyboardLockMode.capsLock);
      });
    }
    return false;
  }

  // Método para cargar la preferencia de "Permanecer conectado"
  Future<void> _loadStayLoggedInPreference() async {
    try {
      // Cambiamos a SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _stayLoggedIn = prefs.getBool('stay_logged_in') ?? false;
      });
      debugPrint(
          'Cargada preferencia de permanencia de sesión: $_stayLoggedIn');
    } catch (e) {
      debugPrint('Error al cargar preferencia de permanencia de sesión: $e');
    }
  }

  Future<void> _loadSavedCredentials() async {
    try {
      // Mantenemos FlutterSecureStorage para las credenciales "Recordar" normal
      // ya que son menos sensibles que el auto-login
      final String? username = await _storage.read(key: 'username');
      final String? password = await _storage.read(key: 'password');
      final String? shouldRemember = await _storage.read(key: 'remember_me');

      if (username != null && password != null && shouldRemember == 'true') {
        setState(() {
          _usernameController.text = username;
          _passwordController.text = password;
          _rememberMe = true;
        });
      }
    } catch (e) {
      // Ignorar errores al cargar credenciales
      debugPrint('Error al cargar credenciales: $e');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      final usuario = await loginProvider.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      if (usuario != null) {
        // Guardar credenciales si "Recordar me" está activado
        if (_rememberMe) {
          await _storage.write(
              key: 'username', value: _usernameController.text);
          await _storage.write(
              key: 'password', value: _passwordController.text);
          await _storage.write(key: 'remember_me', value: 'true');
        }

        // Guardar credenciales para auto-login si "Permanecer conectado" está activado
        if (_stayLoggedIn) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('stay_logged_in', true);
          await prefs.setString('username_auto', _usernameController.text);
          await prefs.setString('password_auto', _passwordController.text);
        }

        // Extraer el código del rol del formato correcto
        String rolCodigo = '';
        final Map<String, dynamic> userData = usuario.toMap();

        if (userData['rol'] is Map) {
          rolCodigo = (userData['rol'] as Map)['codigo']?.toString() ?? '';
        } else {
          rolCodigo = userData['rol']?.toString() ?? '';
        }

        rolCodigo = rolCodigo.toLowerCase();
        final String initialRoute = role_utils.getInitialRoute(rolCodigo);

        debugPrint(
            'Login exitoso, navegando a ruta: $initialRoute para rol: $rolCodigo');

        if (!mounted) {
          return;
        }

        await Navigator.pushReplacementNamed(
          context,
          initialRoute,
          arguments: userData,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar sesión: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: _handleLogin,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si estamos verificando el auto-login, mostrar pantalla de carga
    if (_isCheckingAutoLogin) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Logo
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
              Text(
                'Iniciando sesión automáticamente...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Pantalla normal de login
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: <Widget>[
          // Fondo animado
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (BuildContext context, Widget? child) {
                return CustomPaint(
                  painter: BackgroundPainter(
                    animation: _animationController,
                    speedFactor:
                        0.25, // Reducir aún más la velocidad de la animación
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
          // Contenido del login
          Center(
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // Logo
                        Center(
                          child: Container(
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
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          'Iniciar Sesión',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                color: Colors.white,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Username field
                        TextFormField(
                          controller: _usernameController,
                          focusNode: _usernameFocusNode,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Usuario',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.person,
                                color: Color(0xFFE31E24)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE31E24), width: 2),
                            ),
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su usuario';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            _passwordFocusNode.requestFocus();
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Clave',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.lock,
                                color: Color(0xFFE31E24)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: const Color(0xFFE31E24),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE31E24), width: 2),
                            ),
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su clave';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _handleLogin(),
                        ),

                        // Caps Lock warning
                        if (_capsLockOn)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFE31E24),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Bloq Mayús está activado',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Opciones de login
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // Recordar credenciales checkbox
                            Row(
                              children: <Widget>[
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  fillColor:
                                      WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                                      if (states
                                          .contains(WidgetState.selected)) {
                                        return const Color(0xFFE31E24);
                                      }
                                      return Colors.white54;
                                    },
                                  ),
                                ),
                                const Text(
                                  'Recordar credenciales',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),

                            // Permanecer conectado checkbox
                            Row(
                              children: <Widget>[
                                Checkbox(
                                  value: _stayLoggedIn,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _stayLoggedIn = value ?? false;
                                    });
                                  },
                                  fillColor:
                                      WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                                      if (states
                                          .contains(WidgetState.selected)) {
                                        return const Color(0xFFE31E24);
                                      }
                                      return Colors.white54;
                                    },
                                  ),
                                ),
                                const Text(
                                  'Permanecer conectado',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Tooltip(
                                  message:
                                      'Iniciar sesión automáticamente al abrir la aplicación',
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Error message
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Login button
                        Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _isLoading ? 50 : 320,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE31E24),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: _isLoading ? 0 : 24,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 2,
                              ),
                              onPressed:
                                  _isLoading ? null : () => _handleLogin(),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (Widget child,
                                    Animation<double> animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: _isLoading
                                    ? Container(
                                        width: 24,
                                        height: 24,
                                        padding: const EdgeInsets.all(2),
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.login, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Iniciar Sesión',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
