import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/models/auth.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:condorsmotors/utils/role_utils.dart' as role_utils;
import 'package:condorsmotors/utils/secure_storage_utils.dart';
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
  final AuthRepository _authRepository;

  LoginStatus _status = LoginStatus.initial;
  String _errorMessage = '';
  bool _rememberMe = false;
  bool _stayLoggedIn = false;

  // Getters
  LoginStatus get status => _status;
  String get errorMessage => _errorMessage;
  bool get rememberMe => _rememberMe;
  bool get stayLoggedIn => _stayLoggedIn;

  LoginProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository.instance {
    _init();
  }

  Future<void> _init() async {
    await _loadPreferences();
    if (_stayLoggedIn) {
      await tryAutoLogin();
    }
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _stayLoggedIn = prefs.getBool('stay_logged_in') ?? false;
      _rememberMe = prefs.getBool('remember_me') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar preferencias: $e');
    }
  }

  Future<void> saveCredentials(String username, String password) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);

      if (_rememberMe) {
        await _storage.write(key: 'username', value: username);
        await _storage.write(key: 'password', value: password);
      } else {
        await _storage.delete(key: 'username');
        await _storage.delete(key: 'password');
      }

      await prefs.setBool('stay_logged_in', _stayLoggedIn);

      if (_stayLoggedIn) {
        await SecureStorageUtils.write('username_auto', username);
        await SecureStorageUtils.write('password_auto', password);
      } else {
        await SecureStorageUtils.delete('username_auto');
        await SecureStorageUtils.delete('password_auto');
      }
    } catch (e) {
      debugPrint('Error al guardar credenciales: $e');
      // No lanzar el error para no interrumpir el flujo de login
    }
  }

  Future<AuthUser?> tryAutoLogin() async {
    try {
      _status = LoginStatus.authenticating;
      notifyListeners();

      final String? username = await SecureStorageUtils.read('username_auto');
      final String? password = await SecureStorageUtils.read('password_auto');

      if (username == null || password == null) {
        _status = LoginStatus.initial;
        notifyListeners();
        return null;
      }

      final AuthUser usuario = await _authRepository.login(username, password);

      // Guardar datos del usuario
      await _authRepository.saveUserData(usuario);

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

  Future<AuthUser?> login(String username, String password) async {
    try {
      _status = LoginStatus.authenticating;
      _errorMessage = '';
      notifyListeners();

      final AuthUser usuario = await _authRepository.login(username, password);

      // Validar que el usuario tenga un rol válido
      if (usuario.rolCuentaEmpleadoCodigo.isEmpty) {
        throw ApiException(
          message: 'El usuario no tiene un rol asignado',
          errorCode: ApiConstants.errorCodes[401] ?? ApiConstants.unknownError,
          statusCode: 401,
        );
      }

      // Normalizar el rol antes de procesar
      final String rolNormalizado =
          role_utils.normalizeRole(usuario.rolCuentaEmpleadoCodigo);
      debugPrint('Rol normalizado para autenticación: $rolNormalizado');

      // Guardar datos del usuario
      await _authRepository.saveUserData(usuario);

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

      // Propagar el error formateado para que la UI pueda mostrarlo correctamente
      throw Exception(_errorMessage);
    }
  }

  String _formatErrorMessage(error) {
    if (error is ApiException) {
      final String errorCode = error.errorCode;

      if (errorCode == ApiConstants.errorCodes[401]) {
        return 'Usuario o contraseña incorrectos';
      }
      if (errorCode == ApiConstants.errorCodes[503] ||
          errorCode == ApiConstants.errorCodes[504]) {
        return 'Error de conexión. Verifique su conexión a internet o la configuración del servidor.';
      }
      if (errorCode == ApiConstants.errorCodes[500]) {
        return 'Error en el servidor. Intente más tarde.';
      }

      // Verificar si el mensaje contiene información sobre credenciales incorrectas
      if (error.message
              .toLowerCase()
              .contains('usuario o contraseña incorrectos') ||
          error.message.toLowerCase().contains('incorrect') ||
          error.message
              .toLowerCase()
              .contains('nombre de usuario o contraseña')) {
        return 'Usuario o contraseña incorrectos';
      }
      return 'Error: ${error.message}';
    }

    // Verificar mensajes de error comunes en formato string
    final String errorStr = error.toString().toLowerCase();
    if (errorStr.contains('usuario o contraseña incorrectos') ||
        errorStr.contains('incorrect') ||
        errorStr.contains('nombre de usuario o contraseña')) {
      return 'Usuario o contraseña incorrectos';
    }

    return 'Error inesperado: $error';
  }

  Future<void> logout() async {
    try {
      await _authRepository.clearSession();
      _status = LoginStatus.initial;
      _errorMessage = '';
      notifyListeners();
    } catch (e) {
      debugPrint('Error durante logout: $e');
      _status = LoginStatus.initial;
      _errorMessage = '';
      notifyListeners();
    }
  }

  /// Establece si se deben recordar las credenciales
  void setRememberMe({required bool value}) {
    _rememberMe = value;
    notifyListeners();
  }

  /// Establece si se debe mantener la sesión iniciada
  void setStayLoggedIn({required bool value}) {
    _stayLoggedIn = value;
    notifyListeners();
  }

  void resetError() {
    _errorMessage = '';
    _status = LoginStatus.initial;
    notifyListeners();
  }
}
