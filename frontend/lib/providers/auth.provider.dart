import 'dart:async';

import 'package:condorsmotors/models/auth.model.dart';
import 'package:condorsmotors/repositories/auth.repository.dart';
import 'package:condorsmotors/utils/role_utils.dart' as role_utils;
import 'package:condorsmotors/utils/secure_storage_utils.dart';
import 'package:flutter/material.dart';
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

  // Flags para centralizar la verificación de sesión
  bool _isVerifying = false;
  bool _hasVerified = false;
  bool _lastVerifyResult = false;
  Completer<bool>? _verifyCompleter;

  // Flags y estado para auto-login
  bool _autoLoginAttempted = false;
  bool _isAutoLoggingIn = false;
  String? _autoLoginError;
  bool get isAutoLoginAttempted => _autoLoginAttempted;
  bool get isAutoLoggingIn => _isAutoLoggingIn;
  String? get autoLoginError => _autoLoginError;

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
        usuario,
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

      await _authRepository.logout();

      _state = AuthState.initial();
      notifyListeners();

      debugPrint('Sesión cerrada exitosamente');
      resetSessionVerification(); // Limpiar flags al cerrar sesión
    } catch (e) {
      debugPrint('Error durante proceso de logout: $e');
      _state = AuthState.initial();
      notifyListeners();
      resetSessionVerification();
    }
  }

  /// Centraliza el proceso de logout y navegación al login
  Future<void> logoutAndRedirectToLogin(BuildContext context,
      {String? errorMessage}) async {
    try {
      await logout();
      if (!context.mounted) {
        return;
      }
      await Navigator.of(context).pushNamedAndRemoveUntil(
        role_utils.login,
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ??
                'Hubo un error, pero la sesión ha sido cerrada'),
            backgroundColor: Colors.orange,
          ),
        );
        await Navigator.of(context).pushNamedAndRemoveUntil(
          role_utils.login,
          (Route<dynamic> route) => false,
        );
      }
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

  // Guardar datos del usuario (si se requiere en la UI)
  Future<void> saveUserData(AuthUser usuario) async {
    try {
      await _authRepository.saveUserData(usuario);
      // Actualizar estado local si es necesario
      _state = _state.copyWith(user: usuario);
      notifyListeners();
    } catch (e) {
      debugPrint('Error al guardar datos de usuario: $e');
    }
  }

  /// Verifica la sesión solo una vez por ciclo de arranque/cambio de servidor
  /// Si ya está en curso, espera el resultado. Si ya se verificó, retorna el último resultado.
  Future<bool> verifySessionOnce() async {
    if (_hasVerified) {
      return _lastVerifyResult;
    }
    if (_isVerifying && _verifyCompleter != null) {
      // Esperar a que termine la verificación en curso
      return _verifyCompleter!.future;
    }
    _isVerifying = true;
    _verifyCompleter = Completer<bool>();
    try {
      final isValid = await _authRepository.verificarToken();
      _lastVerifyResult = isValid;
      _hasVerified = true;
      if (!_verifyCompleter!.isCompleted) {
        _verifyCompleter!.complete(isValid);
      }
      return isValid;
    } catch (e) {
      _hasVerified = false;
      _lastVerifyResult = false;
      if (_verifyCompleter != null && !_verifyCompleter!.isCompleted) {
        _verifyCompleter!.complete(false);
      }
      rethrow;
    } finally {
      _isVerifying = false;
    }
  }

  // Resetear flags tras logout o cuando se requiera nueva verificación
  void resetSessionVerification() {
    _isVerifying = false;
    _hasVerified = false;
    _lastVerifyResult = false;
    _verifyCompleter = null;
  }

  /// Lógica de auto-login centralizada en el provider
  Future<void> tryAutoLogin() async {
    if (_autoLoginAttempted) {
      return;
    }
    _autoLoginAttempted = true;
    _isAutoLoggingIn = true;
    _autoLoginError = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool stayLoggedIn = prefs.getBool('stay_logged_in') ?? false;
      debugPrint(
          '[AuthProvider] Auto-login: Permanecer conectado está ${stayLoggedIn ? 'activado' : 'desactivado'}');
      if (!stayLoggedIn) {
        debugPrint(
            '[AuthProvider] Auto-login: No está activado "Permanecer conectado"');
        _isAutoLoggingIn = false;
        notifyListeners();
        return;
      }
      final String? username = await SecureStorageUtils.read('username_auto');
      final String? password = await SecureStorageUtils.read('password_auto');
      if (username == null ||
          password == null ||
          username.isEmpty ||
          password.isEmpty) {
        debugPrint('[AuthProvider] Auto-login: No hay credenciales guardadas');
        _isAutoLoggingIn = false;
        notifyListeners();
        return;
      }
      debugPrint(
          '[AuthProvider] Auto-login: Intentando iniciar sesión automáticamente con usuario: $username');
      final usuario = await _authRepository.login(username, password);
      _state = AuthState.authenticated(
        usuario,
        usuario.toMap()['token'] ?? '',
      );
      notifyListeners();
      debugPrint(
          '[AuthProvider] Auto-login: Login exitoso, usuario autenticado: $usuario');
      // Guardar los datos del usuario en el servicio global de autenticación
      try {
        await _authRepository.saveUserData(usuario);
        debugPrint(
            '[AuthProvider] Auto-login: Datos de usuario guardados correctamente en el servicio global');
      } catch (e) {
        debugPrint(
            '[AuthProvider] Auto-login: Error al guardar datos en el servicio global: $e');
      }
      _isAutoLoggingIn = false;
      notifyListeners();
    } catch (e) {
      debugPrint(
          '[AuthProvider] Auto-login: Error durante el inicio de sesión automático: $e');
      _autoLoginError = e.toString();
      _isAutoLoggingIn = false;
      notifyListeners();
    }
  }
}
