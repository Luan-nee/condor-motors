import 'dart:async';

import 'package:condorsmotors/api/index.api.dart'
    show updateBaseUrl, serverConfigs;
import 'package:condorsmotors/providers/auth.provider.dart';
import 'package:condorsmotors/providers/login.provider.dart';
import 'package:condorsmotors/utils/role_utils.dart'
    as role_utils; // Importar utilidad de roles con alias
import 'package:condorsmotors/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importar para KeyboardListener
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:restart_app/restart_app.dart';
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
  bool _isLoading = false;
  bool _capsLockOn = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _stayLoggedIn = false; // Variable para "Permanecer conectado"
  late final AnimationController _animationController;
  String _errorMessage = '';
  String _serverIp = 'localhost'; // IP local para el servidor
  late final LifecycleObserver _lifecycleObserver;
  bool _hasNavigated = false;

  Future<bool>? _autoLoginFuture;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
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

  Future<void> _saveServerIp(String serverIp, {int? port}) async {
    try {
      await updateBaseUrl(serverIp, port: port);
      if (!mounted) {
        return;
      }
      setState(() {
        _serverIp = serverIp;
      });
      debugPrint('URL del servidor guardada: $serverIp');
      Restart.restartApp();
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
                        Restart.restartApp();
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
                  Restart.restartApp();
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

  Future<bool> _getAutoLoginFuture() async {
    final prefs = await SharedPreferences.getInstance();
    final stayLoggedIn = prefs.getBool('stay_logged_in') ?? false;
    if (stayLoggedIn) {
      return Provider.of<AuthProvider>(context, listen: false).autoLogin();
    }
    return false; // No loading, muestra login directo
  }

  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    final stayLoggedIn = prefs.getBool('stay_logged_in') ?? false;
    setState(() {
      _rememberMe = rememberMe;
      _stayLoggedIn = stayLoggedIn;
    });

    if (rememberMe) {
      // Leer usuario y clave de SecureStorage
      final storage = const FlutterSecureStorage();
      final username = await storage.read(key: 'username');
      final password = await storage.read(key: 'password');
      if (username != null) {
        _usernameController.text = username;
      }
      if (password != null) {
        _passwordController.text = password;
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
          // Loading de auto-login (solo si stay_logged_in == true)
          return Scaffold(
            backgroundColor: const Color(0xFF1A1A1A),
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
        } else if (snapshot.hasError) {
          // Error de auto-login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error en auto-login: ${snapshot.error}'),
                backgroundColor: Colors.red,
              ),
            );
          });
          return _buildLoginForm(context);
        } else if (snapshot.data == true) {
          // Auto-login exitoso, navegar automáticamente
          if (!_hasNavigated) {
            _hasNavigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final user =
                  Provider.of<AuthProvider>(context, listen: false).user;
              if (user != null) {
                final result = role_utils.getRoleAndInitialRoute(user.toMap());
                final String initialRoute = result['route']!;
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
          // Mostrar formulario de login normal
          return _buildLoginForm(context);
        }
      },
    );
  }

  Widget _buildLoginForm(BuildContext context) {
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
                                  onChanged: (bool? value) async {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setBool(
                                        'remember_me', _rememberMe);
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
                                  onChanged: (bool? value) async {
                                    setState(() {
                                      _stayLoggedIn = value ?? false;
                                    });
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setBool(
                                        'stay_logged_in', _stayLoggedIn);
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
                          Container(
                            margin: const EdgeInsets.only(top: 16.0),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Login button
                        Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _isLoading ? 60 : 320,
                            height: 50,
                            curve: Curves.easeInOut,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE31E24),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 2,
                                padding: EdgeInsets.zero,
                              ),
                              onPressed:
                                  _isLoading ? null : () => _handleLogin(),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth < 140) {
                                    // Mostrar solo el loader si el ancho es pequeño
                                    return const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      ),
                                    );
                                  } else {
                                    // Mostrar el contenido normal si hay espacio suficiente
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
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
                                    );
                                  }
                                },
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

  Future<void> _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAutoLoggingIn) {
      // Bloquear login manual mientras auto-login está en progreso
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      Provider.of<LoginProvider>(context, listen: false);
      final bool loginSuccess = await authProvider.login(
        _usernameController.text,
        _passwordController.text,
        saveAutoLogin: _stayLoggedIn,
      );
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      if (loginSuccess && !authProvider.isAutoLoggingIn) {
        // Guardar credenciales solo si el login fue exitoso y recordar credenciales está activado
        if (_rememberMe) {
          final storage = const FlutterSecureStorage();
          await storage.write(key: 'username', value: _usernameController.text);
          await storage.write(key: 'password', value: _passwordController.text);
          await storage.write(key: 'remember_me', value: 'true');
        } else {
          final storage = const FlutterSecureStorage();
          await storage.delete(key: 'username');
          await storage.delete(key: 'password');
          await storage.delete(key: 'remember_me');
        }
        final user = authProvider.user;
        if (user != null) {
          final result = role_utils.getRoleAndInitialRoute(user.toMap());
          final String initialRoute = result['route']!;
          final String rolNormalizado = result['rol']!;
          debugPrint(
              'Login exitoso, navegando a ruta: $initialRoute para rol: $rolNormalizado');
          await Navigator.pushReplacementNamed(
            context,
            initialRoute,
            arguments: user.toMap(),
          );
        }
      } else if (!loginSuccess) {
        // No guardar credenciales si el login falla
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión')),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        if (e.toString().contains('usuario o contraseña incorrectos') ||
            e.toString().toLowerCase().contains('incorrect')) {
          _errorMessage = 'Usuario o contraseña incorrectos';
        } else {
          _errorMessage = 'Error al iniciar sesión: $e';
        }
      });
      // No guardar credenciales si hay error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage),
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
}
