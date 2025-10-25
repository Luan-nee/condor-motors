import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/models/auth.model.dart';
import 'package:flutter/foundation.dart';

/// Repositorio de autenticación simplificado
class AuthRepository {
  /// Instancia singleton del repositorio
  static final AuthRepository _instance = AuthRepository._internal();
  static AuthRepository get instance => _instance;

  AuthRepository._internal();

  /// Inicia sesión con usuario y contraseña
  Future<AuthUser> login(String username, String password,
      {bool saveAutoLogin = false}) async {
    try {
      // Usar AuthManager directamente
      final userData = await api_index.AuthManager.login(username, password,
          saveAutoLogin: saveAutoLogin);

      if (userData == null) {
        throw Exception('Credenciales inválidas');
      }

      return AuthUser.fromJson(userData);
    } catch (e) {
      debugPrint('Error en AuthRepository.login: $e');
      rethrow;
    }
  }

  /// Cierra la sesión
  Future<void> logout() async {
    try {
      // Usar AuthManager directamente
      await api_index.AuthManager.logout();
    } catch (e) {
      debugPrint('Error en AuthRepository.logout: $e');
      rethrow;
    }
  }

  /// Verifica si el token es válido
  Future<bool> verificarToken() async {
    try {
      // Usar AuthManager directamente
      return await api_index.AuthManager.verificarToken();
    } catch (e) {
      debugPrint('Error en AuthRepository.verificarToken: $e');
      return false;
    }
  }

  /// Obtiene datos del usuario
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      // Usar AuthManager directamente
      return await api_index.AuthManager.getUserData();
    } catch (e) {
      debugPrint('Error en AuthRepository.getUserData: $e');
      return null;
    }
  }

  /// Guarda datos del usuario
  Future<void> saveUserData(AuthUser usuario) async {
    try {
      // Usar AuthManager directamente
      await api_index.AuthManager.saveUserData(usuario.toMap());
    } catch (e) {
      debugPrint('Error en AuthRepository.saveUserData: $e');
      rethrow;
    }
  }

  /// Limpia todos los tokens
  Future<void> clearTokens() async {
    try {
      // Usar AuthManager directamente
      await api_index.AuthManager.clearTokens();
    } catch (e) {
      debugPrint('Error en AuthRepository.clearTokens: $e');
      rethrow;
    }
  }
}
