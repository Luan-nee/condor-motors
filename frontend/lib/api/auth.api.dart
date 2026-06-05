import 'package:condorsmotors/api/index.api.dart' as api_index;

/// API de autenticación simplificada.
///
/// Actúa como fachada delegando las operaciones directamente en AuthManager.
class AuthApi {
  const AuthApi();

  /// Inicia sesión con usuario y contraseña.
  Future<Map<String, dynamic>?> login(String username, String password) =>
      api_index.AuthManager.login(username, password);

  /// Cierra la sesión activa.
  Future<void> logout() => api_index.AuthManager.logout();

  /// Verifica si el token actual es válido.
  Future<bool> verificarToken() => api_index.AuthManager.verificarToken();

  /// Obtiene los datos del usuario almacenados localmente.
  Future<Map<String, dynamic>?> getUserData() =>
      api_index.AuthManager.getUserData();

  /// Almacena los datos del usuario localmente.
  Future<void> saveUserData(Map<String, dynamic> userData) =>
      api_index.AuthManager.saveUserData(userData);

  /// Limpia todos los tokens de autenticación.
  Future<void> clearTokens() => api_index.AuthManager.clearTokens();
}
