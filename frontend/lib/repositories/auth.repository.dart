import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/foundation.dart';

/// Repositorio para gestionar la autenticación
///
/// Esta clase encapsula la lógica de negocio relacionada con la autenticación,
/// actuando como una capa intermedia entre la UI y la API
class AuthRepository implements BaseRepository {
  /// Instancia singleton del repositorio
  static final AuthRepository _instance = AuthRepository._internal();

  /// Getter para la instancia singleton
  static AuthRepository get instance => _instance;

  /// API de autenticación
  late final dynamic _authApi;

  /// Constructor privado para el patrón singleton
  AuthRepository._internal() {
    try {
      _authApi = api.auth;
    } catch (e) {
      debugPrint('Error al obtener API de autenticación: $e');
      throw Exception('No se pudo inicializar AuthRepository: $e');
    }
  }

  /// Obtiene datos del usuario desde la API centralizada
  @override
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      return await api.getUserData();
    } catch (e) {
      debugPrint('Error en AuthRepository.getUserData: $e');
      return null;
    }
  }

  /// Obtiene el ID de la sucursal del usuario actual
  @override
  Future<String?> getCurrentSucursalId() async {
    try {
      final userData = await getUserData();
      return userData?['sucursalId']?.toString();
    } catch (e) {
      debugPrint('Error en AuthRepository.getCurrentSucursalId: $e');
      return null;
    }
  }

  /// Inicia sesión con usuario y contraseña
  Future<UsuarioAutenticado> login(String usuario, String clave) async {
    try {
      return await _authApi.login(usuario, clave);
    } catch (e) {
      debugPrint('Error en AuthRepository.login: $e');
      rethrow;
    }
  }

  /// Cierra la sesión del usuario
  Future<void> logout() async {
    try {
      await _authApi.logout();
    } catch (e) {
      debugPrint('Error en AuthRepository.logout: $e');
      rethrow;
    }
  }

  /// Limpia los tokens y datos de usuario almacenados
  Future<void> clearTokens() async {
    try {
      await _authApi.clearTokens();
    } catch (e) {
      debugPrint('Error en AuthRepository.clearTokens: $e');
      rethrow;
    }
  }

  /// Refresca el token de acceso
  Future<void> refreshToken() async {
    try {
      await _authApi.refreshToken();
    } catch (e) {
      debugPrint('Error en AuthRepository.refreshToken: $e');
      rethrow;
    }
  }

  /// Guarda los datos del usuario
  Future<void> saveUserData(UsuarioAutenticado usuario) async {
    try {
      await api.authService.saveUserData(usuario);
    } catch (e) {
      debugPrint('Error en AuthRepository.saveUserData: $e');
      rethrow;
    }
  }
}
