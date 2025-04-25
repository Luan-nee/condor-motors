import 'package:condorsmotors/models/auth.model.dart';
import 'package:condorsmotors/repositories/auth.repository.dart';
import 'package:condorsmotors/utils/role_utils.dart' as role_utils;
import 'package:flutter/material.dart';

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

      await _authRepository.clearSession();

      _state = AuthState.initial();
      notifyListeners();

      debugPrint('Sesión cerrada exitosamente');
    } catch (e) {
      debugPrint('Error durante proceso de logout: $e');
      _state = AuthState.initial();
      notifyListeners();
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
}
