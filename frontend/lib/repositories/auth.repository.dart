import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/models/auth.model.dart';

/// Repositorio de autenticación.
///
/// Encapsula el acceso y gestión del estado de autenticación,
/// delegando operaciones directamente en AuthManager.
class AuthRepository {
  static final AuthRepository _instance = AuthRepository._internal();
  static AuthRepository get instance => _instance;

  AuthRepository._internal();

  /// Inicia sesión con credenciales de usuario.
  Future<AuthUser> login(
    String username,
    String password, {
    bool saveAutoLogin = false,
  }) async {
    final userData = await api_index.AuthManager.login(
      username,
      password,
      saveAutoLogin: saveAutoLogin,
    );
    if (userData == null) {
      throw Exception('Credenciales inválidas');
    }
    return AuthUser.fromJson(userData);
  }

  /// Cierra la sesión activa del usuario.
  Future<void> logout() => api_index.AuthManager.logout();

  /// Verifica la validez del token de acceso actual.
  Future<bool> verificarToken() => api_index.AuthManager.verificarToken();

  /// Obtiene los datos del usuario autenticado.
  Future<Map<String, dynamic>?> getUserData() =>
      api_index.AuthManager.getUserData();

  /// Almacena localmente los datos de un usuario autenticado.
  Future<void> saveUserData(AuthUser usuario) =>
      api_index.AuthManager.saveUserData(usuario.toMap());

  /// Limpia todos los tokens y credenciales locales almacenadas.
  Future<void> clearTokens() => api_index.AuthManager.clearTokens();
}
