import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/utils/logger.dart';

// TokenService y AuthService eliminados - funcionalidad consolidada en AuthManager

/// API de autenticación simplificada
class AuthApi {
  AuthApi();

  /// Inicia sesión con usuario y contraseña
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      // Usar AuthManager directamente
      return await api_index.AuthManager.login(username, password);
    } catch (e) {
      logError('Error en AuthApi.login: $e');
      return null;
    }
  }

  /// Cierra la sesión
  Future<void> logout() async {
    try {
      // Usar AuthManager directamente
      await api_index.AuthManager.logout();
    } catch (e) {
      logError('Error en AuthApi.logout: $e');
    }
  }

  /// Verifica si el token es válido
  Future<bool> verificarToken() async {
    try {
      // Usar AuthManager directamente
      return await api_index.AuthManager.verificarToken();
    } catch (e) {
      logError('Error en AuthApi.verificarToken: $e');
      return false;
    }
  }

  /// Obtiene datos del usuario
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      // Usar AuthManager directamente
      return await api_index.AuthManager.getUserData();
    } catch (e) {
      logError('Error en AuthApi.getUserData: $e');
      return null;
    }
  }

  /// Guarda datos del usuario
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      // Usar AuthManager directamente
      await api_index.AuthManager.saveUserData(userData);
    } catch (e) {
      logError('Error en AuthApi.saveUserData: $e');
      rethrow;
    }
  }

  /// Limpia todos los tokens
  Future<void> clearTokens() async {
    try {
      // Usar AuthManager directamente
      await api_index.AuthManager.clearTokens();
    } catch (e) {
      logError('Error en AuthApi.clearTokens: $e');
    }
  }
}
