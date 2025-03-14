import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // Importar para KeyboardListener
import '../routes/routes.dart';
import '../widgets/background.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/empleados.api.dart';
import '../api/main.api.dart';
import '../api/sucursales.api.dart';  // Importar SucursalesApi

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _storage = const FlutterSecureStorage();
  final _apiService = ApiService();
  late final EmpleadoApi _empleadoApi;
  late final SucursalesApi _sucursalesApi;  // Agregar SucursalesApi
  bool _isLoading = false;
  bool _capsLockOn = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  late final AnimationController _animationController;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _empleadoApi = EmpleadoApi(_apiService);
    _sucursalesApi = SucursalesApi(_apiService);  // Inicializar SucursalesApi
    _initializeApi();
    _loadSavedCredentials();
  }

  Future<void> _initializeApi() async {
    try {
      await _apiService.init();
      final isOnline = await _apiService.checkApiStatus();
      if (!isOnline) {
        setState(() {
          _errorMessage = 'No se puede conectar al servidor. Verifique su conexión.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al inicializar la conexión: $e';
      });
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
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

  Future<void> _loadSavedCredentials() async {
    try {
      final username = await _storage.read(key: 'username');
      final password = await _storage.read(key: 'password');
      final shouldRemember = await _storage.read(key: 'remember_me');

      if (username != null && password != null && shouldRemember == 'true') {
        setState(() {
          _usernameController.text = username;
          _passwordController.text = password;
          _rememberMe = true;
        });
      }
    } catch (e) {
      // Ignorar errores al cargar credenciales
    }
  }

  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      await _storage.write(key: 'username', value: _usernameController.text);
      await _storage.write(key: 'password', value: _passwordController.text);
      await _storage.write(key: 'remember_me', value: 'true');
    } else {
      await _storage.deleteAll();
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _empleadoApi.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (_rememberMe) {
        await _saveCredentials();
      }

      if (!mounted) return;

      final empleadoData = response['empleado'];
      if (empleadoData == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Error: Datos de empleado no encontrados en la respuesta',
        );
      }

      // Convertir el código de rol a un rol válido
      final rol = EmpleadoApi.getRoleFromCodigo(empleadoData['rolCuentaEmpleadoCodigo'] as String);
      
      if (rol == 'DESCONOCIDO') {
        throw ApiException(
          statusCode: 500,
          message: 'Error: Rol no reconocido',
        );
      }

      final token = response['token'];
      if (token == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Error: Token de autenticación no encontrado',
        );
      }

      // Establecer el token en el servicio API antes de hacer la llamada a sucursales
      await _apiService.setTokens(
        token: token,
        refreshToken: response['refresh_token'],
        expiration: DateTime.now().add(const Duration(minutes: 30)),
      );

      // Obtener información de la sucursal
      Sucursal? sucursal;
      if (empleadoData['sucursalId'] != null) {
        try {
          // Ahora que el token está establecido, podemos obtener la información de la sucursal
          sucursal = await _sucursalesApi.getSucursal(empleadoData['sucursalId']);
          debugPrint('Sucursal obtenida: ${sucursal.nombre}');
        } catch (e) {
          debugPrint('Error al obtener información de la sucursal: $e');
          // No lanzamos excepción aquí para permitir que el login continúe
        }
      }

      Navigator.pushReplacementNamed(
        context,
        Routes.getInitialRoute(rol),
        arguments: {
          'token': token,
          'rol': rol,
          'usuario': empleadoData['usuario'],
          'nombre': empleadoData['nombre'] ?? empleadoData['usuario'],
          'apellido': empleadoData['apellidos'] ?? '',
          'sucursalId': empleadoData['sucursalId'],
          'sucursal': sucursal != null ? {
            'id': sucursal.id,
            'nombre': sucursal.nombre,
            'direccion': sucursal.direccion,
            'sucursalCentral': sucursal.sucursalCentral,
          } : null,
        },
      );
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // Fondo animado
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: BackgroundPainter(
                    animation: _animationController,
                  ),
                );
              },
            ),
          ),
          // Contenido del login
          Center(
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
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
                      children: [
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
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
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
                            prefixIcon: const Icon(Icons.person, color: Color(0xFFE31E24)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE31E24), width: 2),
                            ),
                          ),
                          validator: (value) {
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
                            prefixIcon: const Icon(Icons.lock, color: Color(0xFFE31E24)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE31E24), width: 2),
                            ),
                          ),
                          validator: (value) {
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
                              children: [
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

                        // Remember me checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              fillColor: WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.selected)) {
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
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE31E24),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : () => _handleLogin(),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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
