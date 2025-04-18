import 'package:condorsmotors/models/auth.model.dart';
import 'package:condorsmotors/repositories/auth.repository.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  AuthState _state = AuthState.initial();

  // Getters
  AuthState get state => _state;
  bool get isAuthenticated => _state.isAuthenticated;
  bool get isLoading => _state.isLoading;
  String? get error => _state.error;
  AuthUser? get user => _state.user;
  String? get token => _state.token;

  AuthProvider(this._authRepository) {
    _init();
  }

  Future<void> _init() async {
    try {
      final userData = await _authRepository.getUserData();
      if (userData != null) {
        _state = AuthState.authenticated(
          AuthUser.fromJson(userData),
          userData['token'] ?? '',
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al inicializar AuthProvider: $e');
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      _state = AuthState.loading();
      notifyListeners();

      final usuario = await _authRepository.login(username, password);

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

      try {
        // 1. Intentar hacer logout usando el repository
        await _authRepository.logout();
      } catch (serverError) {
        // Si hay error de conexión, solo lo registramos pero continuamos con la limpieza local
        debugPrint('Error al contactar servidor para logout: $serverError');
      }

      // 2. Limpiar tokens y estado independientemente de la respuesta del servidor
      await Future.wait([
        _authRepository.clearTokens(),
        _clearLocalData(),
      ]);

      // 3. Resetear el estado del provider
      _state = AuthState.initial();
      notifyListeners();

      debugPrint('Sesión cerrada exitosamente');
    } catch (e) {
      debugPrint('Error durante proceso de logout: $e');

      // Intentar limpieza de emergencia
      try {
        await _clearLocalData(emergencyCleanup: true);
      } catch (cleanupError) {
        debugPrint('Error en limpieza de emergencia: $cleanupError');
      }

      // Asegurar que el estado se resetee incluso si hay errores
      _state = AuthState.initial();
      notifyListeners();
    }
  }

  /// Limpia los datos locales manteniendo configuraciones críticas
  Future<void> _clearLocalData({bool emergencyCleanup = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // Configuraciones que siempre se deben mantener
    final keysToKeep = {'theme_mode', 'language', 'server_url'};

    if (emergencyCleanup) {
      // En caso de limpieza de emergencia, solo limpiar datos críticos
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
    } else {
      // Limpieza completa normal
      final keys = prefs.getKeys();

      // Crear lista de futures para borrar todo excepto las claves a conservar
      final List<Future<bool>> deleteFutures = keys
          .where((key) => !keysToKeep.contains(key))
          .map((key) => prefs.remove(key))
          .toList();

      await Future.wait([
        ...deleteFutures,
        // Asegurar que estas claves críticas se borren
        prefs.remove('access_token'),
        prefs.remove('refresh_token'),
        prefs.remove('user_data'),
        prefs.remove('current_sucursal_id'),
        prefs.remove('current_sucursal_data'),
        // Limpiar caches específicos
        prefs.remove('ventas_cache'),
        prefs.remove('productos_cache'),
        prefs.remove('proformas_cache'),
        prefs.remove('dashboard_cache'),
      ]);
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final userData = await _authRepository.getUserData();
      if (userData == null) {
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
      await _authRepository.refreshToken();
      await checkAuthStatus();
    } catch (e) {
      debugPrint('Error al refrescar token: $e');
      await logout();
    }
  }
}
