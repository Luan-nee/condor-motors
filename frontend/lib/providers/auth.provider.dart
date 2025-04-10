import 'package:condorsmotors/api/auth.api.dart';
import 'package:condorsmotors/models/auth.model.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApi _authApi;
  AuthState _state = AuthState.initial();

  // Getters
  AuthState get state => _state;
  bool get isAuthenticated => _state.isAuthenticated;
  bool get isLoading => _state.isLoading;
  String? get error => _state.error;
  AuthUser? get user => _state.user;
  String? get token => _state.token;

  AuthProvider(this._authApi) {
    _init();
  }

  Future<void> _init() async {
    try {
      final bool isAuth = await _authApi.isAuthenticated();
      if (isAuth) {
        final userData = await _authApi.getUserData();
        if (userData != null) {
          _state = AuthState.authenticated(
            AuthUser.fromJson(userData),
            userData['token'] ?? '',
          );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error al inicializar AuthProvider: $e');
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      _state = AuthState.loading();
      notifyListeners();

      final usuario = await _authApi.login(username, password);

      _state = AuthState.authenticated(
        AuthUser.fromJson(usuario.toMap()),
        usuario.toMap()['token'] ?? '',
      );
      notifyListeners();

      return true;
    } catch (e) {
      _state = AuthState.error(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      _state = AuthState.loading();
      notifyListeners();

      debugPrint('Iniciando proceso de cierre de sesión...');

      // 1. Cerrar sesión en la API y esperar respuesta
      await _authApi.logout();

      // 2. Limpiar preferencias manteniendo configuraciones críticas
      final prefs = await SharedPreferences.getInstance();
      final keysToKeep = {'theme_mode', 'language', 'server_url'};

      // Limpiar preferencias de autenticación específicas
      await Future.wait([
        prefs.setBool('stay_logged_in', false),
        prefs.remove('username_auto'),
        prefs.remove('password_auto'),
        prefs.remove('remember_me'),
        prefs.remove('username'),
        prefs.remove('password'),
        prefs.remove('last_sucursal'),
        prefs.remove('user_data'),
        prefs.remove('current_sucursal_id'),
        prefs.remove('current_sucursal_data'),
      ]);

      // Limpiar otras preferencias excepto las críticas
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (!keysToKeep.contains(key)) {
          await prefs.remove(key);
        }
      }

      debugPrint('Sesión cerrada exitosamente');

      _state = AuthState.initial();
      notifyListeners();
    } catch (e) {
      debugPrint('Error durante logout: $e');

      // Intentar limpieza de emergencia
      try {
        final prefs = await SharedPreferences.getInstance();

        // Limpiar solo datos críticos de autenticación
        await Future.wait([
          prefs.setBool('stay_logged_in', false),
          prefs.remove('username_auto'),
          prefs.remove('password_auto'),
          prefs.remove('remember_me'),
          prefs.remove('username'),
          prefs.remove('password'),
          prefs.remove('last_sucursal'),
          prefs.remove('user_data'),
        ]);
      } catch (cleanupError) {
        debugPrint('Error en limpieza de emergencia: $cleanupError');
      }

      // Asegurar que el estado se resetee
      _state = AuthState.initial();
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final bool isAuth = await _authApi.isAuthenticated();
      if (!isAuth) {
        await logout();
      }
    } catch (e) {
      debugPrint('Error al verificar estado de autenticación: $e');
      await logout();
    }
  }

  // Actualizar datos del usuario
  void updateUserData(Map<String, dynamic> userData) {
    if (_state.user != null) {
      _state = _state.copyWith(
        user: AuthUser.fromJson(userData),
      );
      notifyListeners();
    }
  }

  // Verificar si el token está por expirar
  bool get isTokenExpiring {
    if (_state.tokenExpiry == null) {
      return false;
    }
    final now = DateTime.now();
    final difference = _state.tokenExpiry!.difference(now);
    return difference.inMinutes < 5; // 5 minutos antes de expirar
  }

  // Refrescar token
  Future<void> refreshToken() async {
    try {
      await _authApi.refreshToken();
      await checkAuthStatus();
    } catch (e) {
      debugPrint('Error al refrescar token: $e');
      await logout();
    }
  }
}
