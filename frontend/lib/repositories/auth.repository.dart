import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/models/auth.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<AuthUser> login(String usuario, String clave) async {
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
      debugPrint('AuthRepository: Iniciando proceso de logout');

      try {
        // Intentar hacer logout en el servidor si es posible
        await _authApi.logout();
        debugPrint('AuthRepository: Logout en servidor exitoso');
      } catch (serverError) {
        // Si hay error de comunicación con el servidor, solo lo registramos
        // pero continuamos con la limpieza local
        debugPrint(
            'AuthRepository: Error al contactar servidor para logout: $serverError');
      }

      // Limpiar tokens y datos independientemente del resultado del servidor
      await clearTokens();

      debugPrint('AuthRepository: Proceso de logout completado');
    } catch (e) {
      debugPrint('AuthRepository: Error durante proceso de logout: $e');

      // Intentar limpiar tokens incluso si hay errores
      try {
        await clearTokens();
      } catch (cleanupError) {
        debugPrint(
            'AuthRepository: Error adicional durante limpieza: $cleanupError');
      }

      rethrow;
    }
  }

  /// Limpia los tokens y datos de usuario almacenados
  Future<void> clearTokens() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Lista de claves específicas que queremos conservar
      final Set<String> keysToKeep = {
        'theme_mode',
        'language',
        'server_url',
      };

      // Obtener todas las claves almacenadas
      final Set<String> keys = prefs.getKeys();

      // Crear lista de futures para borrar todo excepto las claves a conservar
      final List<Future<bool>> deleteFutures = keys
          .where((key) => !keysToKeep.contains(key))
          .map((key) => prefs.remove(key))
          .toList();

      // Ejecutar todas las operaciones de borrado
      await Future.wait([
        ...deleteFutures,
        // Asegurar que estas claves críticas se borren
        prefs.remove('access_token'),
        prefs.remove('refresh_token'),
        prefs.remove('expiry_time'),
        prefs.remove('last_username'),
        prefs.remove('last_password'),
        prefs.remove('remember_me'),
        prefs.remove('username'),
        prefs.remove('password'),
        prefs.remove('username_auto'),
        prefs.remove('password_auto'),
        prefs.remove('user_data'),
        prefs.remove('current_sucursal_id'),
        prefs.remove('current_sucursal_data'),
        prefs.setBool('stay_logged_in', false),
        // Limpiar caches específicos
        prefs.remove('ventas_cache'),
        prefs.remove('productos_cache'),
        prefs.remove('proformas_cache'),
        prefs.remove('dashboard_cache'),
      ]);

      debugPrint(
          'AuthRepository: Tokens y datos de usuario limpiados correctamente');
    } catch (e) {
      debugPrint('AuthRepository: Error al limpiar tokens y datos: $e');
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
  Future<void> saveUserData(AuthUser usuario) async {
    try {
      await api.authService.saveUserData(usuario);
    } catch (e) {
      debugPrint('Error en AuthRepository.saveUserData: $e');
      rethrow;
    }
  }
}
