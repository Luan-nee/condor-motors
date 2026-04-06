import 'dart:async'; // Analyzer trigger

import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/models/auth.model.dart';
import 'package:condorsmotors/utils/role_utils.dart' as role_utils;
import 'package:condorsmotors/utils/secure_storage_utils.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth.riverpod.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  // Flags para centralizar la verificación de sesión
  bool _isVerifying = false;
  bool _hasVerified = false;
  bool _lastVerifyResult = false;
  Completer<bool>? _verifyCompleter;

  // Flag para inicialización centralizada
  bool _isInitializing = true;
  bool get isInitializing => _isInitializing;

  // Flags y estado para auto-login
  bool get isAutoLoggingIn => state.isLoading;

  bool get isAuthenticated => state.isAuthenticated;
  bool get isLoading => state.isLoading;
  String? get error => state.error;
  AuthUser? get user => state.user;
  String? get token => state.token;

  @override
  AuthState build() {
    debugPrint('[Auth Riverpod] Constructor ejecutado');
    // Como no podemos hacer llamadas asíncronas directamente en build() si retornamos de forma síncrona,
    // disparamos _init() sin await y devolvemos el estado inicial.
    Future.microtask(_init);
    return AuthState.initial();
  }

  Future<void> _init() async {
    _isInitializing = true;
    try {
      final results = await Future.wait([
        api_index.AuthManager.getUserData(),
      ]);
      final userData = results[0];
      if (userData != null) {
        state = AuthState.authenticated(
          AuthUser.fromJson(userData),
          userData['token'] ?? '',
        );
      }
    } catch (e) {
      debugPrint('Error al inicializar Auth Riverpod: $e');
    } finally {
      _isInitializing = false;
    }
  }

  Future<bool> login(String username, String password,
      {bool saveAutoLogin = false}) async {
    try {
      state = AuthState.loading();

      final userData = await api_index.AuthManager.login(username, password,
          saveAutoLogin: saveAutoLogin);

      if (userData == null) {
        state = AuthState.error('Credenciales inválidas');
        return false;
      }

      final usuario = AuthUser.fromJson(userData);
      state = AuthState.authenticated(
        usuario,
        userData['token'] ?? '',
      );

      return true;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    try {
      state = AuthState.loading();
      debugPrint('Iniciando proceso de cierre de sesión...');

      await api_index.AuthManager.logout();

      state = AuthState.initial();
      debugPrint('Sesión cerrada exitosamente');

      resetSessionVerification();
      await _init();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('stay_logged_in', false);
    } catch (e) {
      debugPrint('Error durante proceso de logout: $e');
      state = AuthState.initial();
      resetSessionVerification();
      await _init();
    }
  }

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
      final userData = await api_index.AuthManager.getUserData();
      if (userData == null) {
        await logout();
      }
    } catch (e) {
      debugPrint('Error al verificar estado de autenticación: $e');
      await logout();
    }
  }

  void updateUserData(Map<String, dynamic> userData) {
    if (state.user != null) {
      state = state.copyWith(
        user: AuthUser.fromJson(userData),
      );
    }
  }

  bool get isTokenExpiring {
    if (state.tokenExpiry == null) {
      return false;
    }
    final now = DateTime.now();
    final difference = state.tokenExpiry!.difference(now);
    return difference.inMinutes < 5;
  }

  Future<void> refreshToken() async {
    try {
      final success = await api_index.RefreshTokenManager.refreshToken(
        baseUrl: api_index.getCurrentBaseUrl(),
      );
      if (!success) {
        await logout();
        return;
      }
      await checkAuthStatus();
    } catch (e) {
      debugPrint('Error al refrescar token: $e');
      await logout();
    }
  }

  Future<void> saveUserData(AuthUser usuario) async {
    try {
      await api_index.AuthManager.saveUserData(usuario.toMap());
      state = state.copyWith(user: usuario);
    } catch (e) {
      debugPrint('Error al guardar datos de usuario: $e');
    }
  }

  Future<bool> verifySessionOnce() async {
    if (_hasVerified) {
      return _lastVerifyResult;
    }
    if (_isVerifying && _verifyCompleter != null) {
      return _verifyCompleter!.future;
    }

    _isVerifying = true;
    _verifyCompleter = Completer<bool>();
    try {
      final isValid = await api_index.AuthManager.verificarToken();
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

  void resetSessionVerification() {
    _isVerifying = false;
    _hasVerified = false;
    _lastVerifyResult = false;
    _verifyCompleter = null;
  }

  Future<bool> autoLogin() async {
    state = AuthState.loading();
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool stayLoggedIn = prefs.getBool('stay_logged_in') ?? false;
      if (!stayLoggedIn) {
        state = AuthState.initial();
        return false;
      }
      final String? username = await SecureStorageUtils.read('username_auto');
      final String? password = await SecureStorageUtils.read('password_auto');
      if (username == null ||
          password == null ||
          username.isEmpty ||
          password.isEmpty) {
        state = AuthState.initial();
        return false;
      }
      final userData = await api_index.AuthManager.login(username, password);
      if (userData == null) {
        throw Exception('Credenciales inválidas');
      }
      final usuario = AuthUser.fromJson(userData);
      state = AuthState.authenticated(usuario, usuario.toMap()['token'] ?? '');
      try {
        await api_index.AuthManager.saveUserData(usuario.toMap());
      } catch (e) {
        debugPrint('[Auth Riverpod] Error al guardar datos: $e');
      }
      return true;
    } catch (e) {
      state = AuthState.error(e.toString());
      rethrow;
    }
  }
}
