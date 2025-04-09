import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/utils/role_utils.dart' as role_utils;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LoginStatus {
  initial,
  authenticating,
  authenticated,
  error,
}

class LoginProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final CondorMotorsApi api;

  LoginStatus _status = LoginStatus.initial;
  String _errorMessage = '';
  bool _rememberMe = false;
  bool _stayLoggedIn = false;
  bool _isCheckingAutoLogin = true;

  // Getters
  LoginStatus get status => _status;
  String get errorMessage => _errorMessage;
  bool get rememberMe => _rememberMe;
  bool get stayLoggedIn => _stayLoggedIn;
  bool get isCheckingAutoLogin => _isCheckingAutoLogin;

  LoginProvider({required this.api}) {
    _init();
  }

  Future<void> _init() async {
    await _loadStayLoggedInPreference();
    if (_stayLoggedIn) {
      await tryAutoLogin();
    } else {
      await _loadSavedCredentials();
    }
    _isCheckingAutoLogin = false;
    notifyListeners();
  }

  Future<void> _loadStayLoggedInPreference() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _stayLoggedIn = prefs.getBool('stay_logged_in') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar preferencia de permanencia de sesión: $e');
    }
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final String? username = await _storage.read(key: 'username');
      final String? password = await _storage.read(key: 'password');
      final String? shouldRemember = await _storage.read(key: 'remember_me');

      if (username != null && password != null && shouldRemember == 'true') {
        _rememberMe = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al cargar credenciales: $e');
    }
  }

  Future<void> saveCredentials(String username, String password) async {
    try {
      if (_rememberMe) {
        await _storage.write(key: 'username', value: username);
        await _storage.write(key: 'password', value: password);
        await _storage.write(key: 'remember_me', value: 'true');
      } else {
        await _storage.delete(key: 'username');
        await _storage.delete(key: 'password');
        await _storage.delete(key: 'remember_me');
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('stay_logged_in', _stayLoggedIn);

      if (_stayLoggedIn) {
        await prefs.setString('username_auto', username);
        await prefs.setString('password_auto', password);
      } else {
        await prefs.remove('username_auto');
        await prefs.remove('password_auto');
      }
    } catch (e) {
      debugPrint('Error al guardar credenciales: $e');
      // No lanzar el error para no interrumpir el flujo de login
    }
  }

  Future<UsuarioAutenticado?> tryAutoLogin() async {
    try {
      _status = LoginStatus.authenticating;
      notifyListeners();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? username = prefs.getString('username_auto');
      final String? password = prefs.getString('password_auto');

      if (username == null || password == null) {
        _status = LoginStatus.initial;
        notifyListeners();
        return null;
      }

      final UsuarioAutenticado usuario =
          await api.auth.login(username, password);

      // Guardar datos del usuario
      await api.authService.saveUserData(usuario);

      _status = LoginStatus.authenticated;
      notifyListeners();

      debugPrint(
          'Auto-login exitoso con rol: ${usuario.rolCuentaEmpleadoCodigo}');
      return usuario;
    } catch (e) {
      _status = LoginStatus.error;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<UsuarioAutenticado?> login(String username, String password) async {
    try {
      _status = LoginStatus.authenticating;
      _errorMessage = '';
      notifyListeners();

      final UsuarioAutenticado usuario =
          await api.auth.login(username, password);

      // Validar que el usuario tenga un rol válido
      if (usuario.rolCuentaEmpleadoCodigo.isEmpty) {
        throw ApiException(
            message: 'El usuario no tiene un rol asignado',
            errorCode: ApiException.errorUnauthorized,
            statusCode: 401);
      }

      // Normalizar el rol antes de procesar
      final String rolNormalizado =
          role_utils.normalizeRole(usuario.rolCuentaEmpleadoCodigo);
      debugPrint('Rol normalizado para autenticación: $rolNormalizado');

      // Guardar datos del usuario
      await api.authService.saveUserData(usuario);

      // Guardar credenciales si es necesario
      await saveCredentials(username, password);

      _status = LoginStatus.authenticated;
      notifyListeners();

      debugPrint('Login exitoso con rol normalizado: $rolNormalizado');
      return usuario;
    } catch (e) {
      _status = LoginStatus.error;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  String _formatErrorMessage(error) {
    if (error is ApiException) {
      switch (error.errorCode) {
        case ApiException.errorUnauthorized:
          return 'Usuario o contraseña incorrectos';
        case ApiException.errorNetwork:
          return 'Error de conexión. Verifique su conexión a internet o la configuración del servidor.';
        case ApiException.errorServer:
          return 'Error en el servidor. Intente más tarde.';
        default:
          return 'Error: ${error.message}';
      }
    }
    return 'Error inesperado: $error';
  }

  Future<void> logout() async {
    try {
      await api.auth.logout();
      _status = LoginStatus.initial;
      _errorMessage = '';

      // Limpiar todas las preferencias
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.clear(), // Limpiar todas las preferencias
        api.auth.clearTokens(), // Limpiar tokens
      ]);

      notifyListeners();
    } catch (e) {
      debugPrint('Error durante logout: $e');
      // Asegurar que se limpie el estado incluso si hay error
      _status = LoginStatus.initial;
      _errorMessage = '';

      // Intentar limpiar datos incluso si hubo error
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await Future.wait([
          prefs.clear(),
          api.auth.clearTokens(),
        ]);
      } catch (cleanupError) {
        debugPrint('Error adicional durante limpieza de datos: $cleanupError');
      }

      notifyListeners();
    }
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void setStayLoggedIn(bool value) {
    _stayLoggedIn = value;
    notifyListeners();
  }

  void resetError() {
    _errorMessage = '';
    _status = LoginStatus.initial;
    notifyListeners();
  }
}
