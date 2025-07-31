import 'dart:convert';

import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/models/auth.model.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:condorsmotors/utils/role_utils.dart' as role_utils;
import 'package:condorsmotors/utils/secure_storage_utils.dart';
import 'package:dio/dio.dart';

/// Servicio para gestionar tokens de autenticación
///
/// Proporciona métodos para guardar, recuperar y gestionar tokens JWT
class TokenService {
  static final TokenService _instance = TokenService._internal();

  // Singleton
  static TokenService get instance => _instance;

  // Claves para almacenamiento en SharedPreferences
  static const String _accessTokenKey = 'access_token';
  static const String _expiryTimeKey = 'expiry_time';
  static const String _lastUsernameKey = 'last_username';
  static const String _lastPasswordKey = 'last_password';

  // URL base del API (será configurada por la aplicación)
  String _baseUrl = '';

  // Cliente Dio para peticiones HTTP
  late Dio _dio;

  // Variables en memoria
  String? _accessToken;
  DateTime? _expiryTime;

  // Constructor privado
  TokenService._internal() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      validateStatus: (status) =>
          true, // Aceptar cualquier código de estado para manejar errores manualmente
    ));
  }

  // Configurar URL base
  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
    _dio.options.baseUrl = baseUrl;
    logInfo('TokenService: URL base configurada: $_baseUrl');
  }

  // Getters
  String? get accessToken => _accessToken;
  DateTime? get expiryTime => _expiryTime;

  /// Verifica si el token está expirado o a punto de expirar
  bool get isTokenExpired {
    if (_accessToken == null || _expiryTime == null) {
      return true;
    }

    // Considerar expirado solo si ya ha expirado realmente
    final DateTime now = DateTime.now();
    return now.isAfter(_expiryTime!);
  }

  /// Verifica si hay un token de acceso válido
  bool get hasValidToken => _accessToken != null && !isTokenExpired;

  /// Carga los tokens desde Secure Storage
  Future<bool> loadTokens() async {
    try {
      logInfo('TokenService: Cargando tokens desde Secure Storage');

      _accessToken = await SecureStorageUtils.read(_accessTokenKey);
      final String? expiryTimeStr =
          await SecureStorageUtils.read(_expiryTimeKey);
      if (expiryTimeStr != null) {
        _expiryTime = DateTime.parse(expiryTimeStr);
      }

      // Verificar si el token está expirado
      if (isTokenExpired) {
        logInfo('TokenService: Token expirado o a punto de expirar');

        // Intentar hacer login automático si hay credenciales guardadas
        if (await _attemptAutoLogin()) {
          logInfo('TokenService: Login automático exitoso, token actualizado');
          return true;
        }

        return false;
      }

      logInfo('TokenService: Tokens cargados correctamente');
      return _accessToken != null;
    } catch (e) {
      logError('TokenService: ERROR al cargar tokens', e);
      return false;
    }
  }

  /// Intenta hacer login automático con credenciales guardadas
  Future<bool> _attemptAutoLogin() async {
    try {
      final String? username = await SecureStorageUtils.read(_lastUsernameKey);
      final String? password = await SecureStorageUtils.read(_lastPasswordKey);

      if (username == null ||
          password == null ||
          username.isEmpty ||
          password.isEmpty) {
        logInfo(
            'TokenService: No hay credenciales guardadas para login automático');
        return false;
      }

      if (_baseUrl.isEmpty) {
        logWarning(
            'TokenService: URL base no configurada, no se puede hacer login automático');
        return false;
      }

      logInfo(
          'TokenService: Intentando login automático para usuario: $username');

      // Realizar solicitud de login
      final Response response = await _dio.post(
        '/auth/login',
        data: <String, String>{
          'usuario': username,
          'clave': password,
        },
        options: Options(
          headers: <String, String>{'Content-Type': 'application/json'},
          validateStatus: (status) => true,
        ),
      );

      // Verificar respuesta
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final responseData = response.data;

        // Buscar token en la respuesta
        String? accessToken;

        if (responseData is Map<String, dynamic>) {
          // Buscar token en diferentes ubicaciones posibles
          if (responseData.containsKey('token')) {
            accessToken = responseData['token']?.toString();
          } else if (responseData.containsKey('access_token')) {
            accessToken = responseData['access_token']?.toString();
          } else if (responseData.containsKey('data') &&
              responseData['data'] is Map) {
            final Map<String, dynamic> data =
                responseData['data'] as Map<String, dynamic>;
            if (data.containsKey('token')) {
              accessToken = data['token']?.toString();
            } else if (data.containsKey('access_token')) {
              accessToken = data['access_token']?.toString();
            }
          }
        }

        // Si se encontró un token, guardarlo
        if (accessToken != null && accessToken.isNotEmpty) {
          await saveTokens(
            accessToken: accessToken,
          );

          logInfo('TokenService: Login automático exitoso, token guardado');
          return true;
        }
      }

      logWarning(
          'TokenService: Login automático falló: ${response.statusCode}');
      return false;
    } catch (e) {
      logError('TokenService: ERROR en login automático', e);
      return false;
    }
  }

  /// Guarda los tokens en almacenamiento seguro
  Future<void> saveTokens({
    required String accessToken,
  }) async {
    try {
      logInfo('TokenService: Guardando tokens en Secure Storage');

      // Actualizar variables en memoria primero
      _accessToken = accessToken;
      _expiryTime = DateTime.now().add(const Duration(seconds: 3600));

      // Guardar en Secure Storage
      await SecureStorageUtils.write(_accessTokenKey, accessToken);
      await SecureStorageUtils.write(
          _expiryTimeKey, _expiryTime!.toIso8601String());

      logInfo('TokenService: Tokens guardados correctamente en Secure Storage');
    } catch (e) {
      logError('TokenService: ERROR al guardar tokens', e);
    }
  }

  /// Elimina los tokens del almacenamiento seguro
  Future<void> clearTokens({void Function()? onLogout}) async {
    logInfo('TokenService: Limpiando tokens de SecureStorage y memoria');
    try {
      // Limpiar variables en memoria
      _accessToken = null;
      _expiryTime = null;

      // Limpiar solo los tokens específicos que gestiona esta clase
      await Future.wait([
        SecureStorageUtils.delete(_accessTokenKey),
        SecureStorageUtils.delete(_expiryTimeKey),
        SecureStorageUtils.delete(_lastUsernameKey),
        SecureStorageUtils.delete(_lastPasswordKey),
      ]);

      logInfo(
          'TokenService: Tokens limpiados correctamente de SecureStorage y memoria');

      // Notificar a la UI que el usuario debe ser deslogueado
      if (onLogout != null) {
        onLogout(); // Ejemplo: authProvider.logout() o callback para redirigir a login
      }
    } catch (e) {
      logError('TokenService: ERROR al limpiar tokens', e);
      rethrow;
    }
  }

  /// Decodifica un token JWT y devuelve su payload
  Map<String, dynamic>? decodeToken(String token) {
    try {
      // Dividir el token en partes
      final List<String> parts = token.split('.');
      if (parts.length < 2) {
        logWarning('TokenService: Formato de token inválido');
        return null;
      }

      // Decodificar la parte del payload (segunda parte)
      final String payload = parts[1];
      final String normalized = base64Url.normalize(payload);
      final String decodedPayload = utf8.decode(base64Url.decode(normalized));

      return json.decode(decodedPayload) as Map<String, dynamic>;
    } catch (e) {
      logError('TokenService: ERROR al decodificar token', e);
      return null;
    }
  }

  /// Extraer información específica del usuario del token
  Map<String, dynamic> extractUserInfoFromToken() {
    if (_accessToken == null) {
      return <String, dynamic>{};
    }

    final Map<String, dynamic>? decodedToken = decodeToken(_accessToken!);
    if (decodedToken == null) {
      return <String, dynamic>{};
    }

    // Obtener el rol original del token
    final String? rolOriginal = decodedToken['rolCuentaEmpleadoCodigo'];

    // Usar la función normalizeRole de role_utils para normalizar el rol
    String rolNormalizado = 'desconocido';
    if (rolOriginal != null) {
      rolNormalizado = role_utils.normalizeRole(rolOriginal);
    }

    return <String, dynamic>{
      'id': decodedToken['id']?.toString() ?? '',
      'usuario': decodedToken['usuario']?.toString() ?? '',
      'rol': rolNormalizado,
      'rolOriginal': rolOriginal,
      'sucursalId': decodedToken['sucursalId']?.toString() ?? '',
    };
  }

  /// Refresca el token delegando al ApiClient centralizado
  Future<void> refreshToken() async {
    final success =
        await api_index.RefreshTokenManager.refreshToken(baseUrl: _baseUrl);
    if (!success) {
      await clearTokens();
      throw Exception('Refresh token inválido o expirado');
    }
  }
}

/// Clase para gestionar la autenticación y tokens
class AuthApi {
  final ApiClient _api;

  // Claves para almacenamiento
  static const Map<String, String> _keys = {
    'token': 'access_token',
    'refresh': 'refresh_token',
    'userData': 'user_data',
    'sucursal': 'current_sucursal',
    'sucursalId': 'current_sucursal_id',
    'remember': 'remember_me',
    'username': 'username',
    'password': 'password',
    'usernameAuto': 'username_auto',
    'passwordAuto': 'password_auto',
    'stayLogged': 'stay_logged_in',
    'ventasCache': 'ventas_cache',
    'productosCache': 'productos_cache',
    'proformasCache': 'proformas_cache',
    'dashboardCache': 'dashboard_cache',
  };

  // Getter para obtener una clave de forma segura
  static String _getKey(String key) => _keys[key] ?? key;

  AuthApi(this._api);

  /// Obtiene los datos del usuario almacenados localmente
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final String? userData =
          await SecureStorageUtils.read(_getKey('userData'));
      if (userData == null) {
        return null;
      }
      return json.decode(userData) as Map<String, dynamic>;
    } catch (e) {
      logError('Error obteniendo datos del usuario', e);
      return null;
    }
  }

  /// Guarda los datos del usuario localmente
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      await SecureStorageUtils.write(
          _getKey('userData'), json.encode(userData));
      logInfo('Datos del usuario guardados correctamente en SecureStorage');
    } catch (e) {
      logError('Error al guardar datos del usuario', e);
      rethrow;
    }
  }

  /// Limpia los tokens y datos de usuario almacenados
  Future<void> clearTokens() async {
    logInfo('AuthApi: Limpiando tokens y datos específicos...');
    try {
      // Limpiar solo las claves específicas que gestiona esta clase
      await Future.wait([
        // Tokens de autenticación
        SecureStorageUtils.delete(_getKey('token')),
        SecureStorageUtils.delete(_getKey('refresh')),
        // Datos de usuario
        SecureStorageUtils.delete(_getKey('userData')),
        SecureStorageUtils.delete(_getKey('sucursal')),
        SecureStorageUtils.delete(_getKey('sucursalId')),
        // Datos de sesión
        SecureStorageUtils.delete(_getKey('remember')),
        SecureStorageUtils.delete(_getKey('username')),
        SecureStorageUtils.delete(_getKey('password')),
        SecureStorageUtils.delete(_getKey('usernameAuto')),
        SecureStorageUtils.delete(_getKey('passwordAuto')),
        // El flag stay_logged_in puede quedarse en SharedPreferences
      ]);

      logInfo(
          'AuthApi: Tokens y datos específicos limpiados correctamente de SecureStorage');
    } catch (e) {
      logError('AuthApi: Error al limpiar tokens y datos', e);
      rethrow;
    }
  }

  /// Cierra la sesión del usuario
  Future<void> logout() async {
    try {
      logInfo('Iniciando proceso de logout en el servidor...');

      // Intentar hacer logout en el servidor
      final Map<String, dynamic> response = await _api.request(
        endpoint: '/auth/logout',
        method: 'POST',
        requiresAuth: true,
        queryParams: {
          'x-no-retry-on-401': 'true' // Evitar reintentos si el token ya expiró
        },
      );

      // Verificar la respuesta del servidor
      if (response['status'] == 'success') {
        logInfo(
            'Servidor: ${response['message'] ?? 'Sesión terminada exitosamente'}');
      }

      // Limpiar todos los datos locales independientemente de la respuesta del servidor
      await clearTokens();

      // Reiniciar el estado del cliente API sin propagar errores
      try {
        await _api.clearState();
      } catch (stateError) {
        logWarning(
            'Error no crítico al limpiar estado del cliente API: $stateError');
      }

      logInfo('Logout completado exitosamente');
    } catch (e) {
      logError('Error durante proceso de logout', e);
      // Intentar limpiar datos locales incluso si falla la comunicación con el servidor
      try {
        await clearTokens();
        try {
          await _api.clearState();
        } catch (stateError) {
          logWarning(
              'Error no crítico al limpiar estado del cliente API: $stateError');
        }
      } catch (cleanupError) {
        logError('Error adicional durante limpieza', cleanupError);
      }
    }
  }

  /// Verifica si hay un token válido almacenado
  Future<bool> isAuthenticated() async {
    try {
      final bool hasToken = await _hasValidToken();
      if (!hasToken) {
        return false;
      }

      // Verificar con el backend si el token es válido
      return await verificarToken();
    } catch (e) {
      logError('Error verificando autenticación', e);
      return false;
    }
  }

  /// Verifica si hay un token almacenado y es válido
  Future<bool> _hasValidToken() async {
    final String? token = await SecureStorageUtils.read(_getKey('token'));
    return token != null && token.isNotEmpty;
  }

  /// Verifica si el token actual es válido con el backend
  Future<bool> verificarToken() async {
    try {
      final Map<String, dynamic> response = await _api.request(
        endpoint: '/auth/testsession',
        method: 'POST',
        requiresAuth: true,
      );

      if (response['status'] != 'success' ||
          response['data'] == null ||
          response['data'] is! Map<String, dynamic>) {
        logWarning('Token inválido: respuesta con formato incorrecto');
        await clearTokens();
        return false;
      }

      // Actualizar datos del usuario en Secure Storage
      final Map<String, dynamic> userData =
          response['data'] as Map<String, dynamic>;
      await SecureStorageUtils.write(
          _getKey('userData'), json.encode(userData));

      return true;
    } catch (e) {
      logError('Error verificando token', e);

      // Si el error contiene "Invalid or missing authorization token", consideramos que estamos deslogueados
      if (e
          .toString()
          .toLowerCase()
          .contains('invalid or missing authorization token')) {
        logInfo(
            'Estado de sesión: Usuario no logueado o token inválido - Se requiere iniciar sesión');
        await clearTokens();
        return false;
      }

      // Para otros tipos de errores, verificar si es un error de autorización
      if (e is ApiException && (e.statusCode == 401 || e.statusCode == 403)) {
        logInfo(
            'Error de autorización: Usuario no autorizado - Se requiere iniciar sesión');
        await clearTokens();
        return false;
      }

      return false;
    }
  }

  /// Inicia sesión con usuario y contraseña
  Future<AuthUser> login(String usuario, String clave,
      {bool saveAutoLogin = false}) async {
    try {
      final Map<String, dynamic> response = await _api.request(
        endpoint: '/auth/login',
        method: 'POST',
        body: <String, String>{
          'usuario': usuario,
          'clave': clave,
        },
      );

      if (response['status'] != 'success' ||
          response['data'] == null ||
          response['data'] is! Map<String, dynamic>) {
        // Manejo específico para errores de respuesta con formato correcto pero estatus 'fail'
        if (response['status'] == 'fail' && response['error'] != null) {
          final String errorMsg = response['error'].toString();
          if (errorMsg.toLowerCase().contains('contraseña incorrectos') ||
              errorMsg.toLowerCase().contains('nombre de usuario') ||
              errorMsg.toLowerCase().contains('credenciales')) {
            throw ApiException(
              statusCode: 401,
              message: 'Usuario o contraseña incorrectos',
              errorCode:
                  ApiConstants.errorCodes[401] ?? ApiConstants.unknownError,
            );
          }
        }

        throw ApiException(
          statusCode: 500,
          message: 'Error: Formato de datos de usuario inválido',
          errorCode: ApiConstants.errorCodes[500] ?? ApiConstants.unknownError,
        );
      }

      // Guardar datos del usuario
      final Map<String, dynamic> userData =
          response['data'] as Map<String, dynamic>;
      await SecureStorageUtils.write(
          _getKey('userData'), json.encode(userData));

      // Guardar credenciales para auto-login si corresponde
      if (saveAutoLogin) {
        await saveAutoLoginCredentials(usuario, clave);
      }

      // Crear instancia de AuthUser con los datos recibidos
      final AuthUser usuarioAutenticado = AuthUser.fromJson(userData);
      logInfo('Login exitoso para usuario: ${usuarioAutenticado.usuario}');
      return usuarioAutenticado;
    } catch (e) {
      logError('Error durante login', e);

      // Mejorar la detección de errores de credenciales incorrectas
      if (e is ApiException) {
        if (e.statusCode == 400) {
          // Extraer el mensaje de error si existe
          final dynamic errorData = e.data;
          if (errorData is Map<String, dynamic> && errorData['error'] != null) {
            final String errorMsg = errorData['error'].toString();
            if (errorMsg.toLowerCase().contains('contraseña incorrectos') ||
                errorMsg.toLowerCase().contains('nombre de usuario') ||
                errorMsg.contains('credenciales')) {
              throw ApiException(
                statusCode: 401,
                message: 'Usuario o contraseña incorrectos',
                errorCode:
                    ApiConstants.errorCodes[401] ?? ApiConstants.unknownError,
              );
            }
          }
        }
      }

      rethrow;
    }
  }

  /// Guarda las credenciales del usuario para futuros login automáticos
  Future<void> saveAutoLoginCredentials(
      String username, String password) async {
    await SecureStorageUtils.write(_getKey('usernameAuto'), username);
    await SecureStorageUtils.write(_getKey('passwordAuto'), password);
  }
}

class AuthService {
  final AuthApi _auth;
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _userRoleKey = 'user_role';
  static const String _userSucursalKey = 'user_sucursal';
  static const String _userSucursalIdKey = 'user_sucursal_id';

  AuthService(this._auth);

  Future<void> saveUserData(AuthUser usuario) async {
    // Guardar data usando AuthApi primero
    await _auth.saveUserData(usuario.toMap());

    // Guardar atributos específicos para acceso rápido en Secure Storage
    await SecureStorageUtils.write(_userIdKey, usuario.id);
    await SecureStorageUtils.write(_usernameKey, usuario.usuario);
    final String rolCodigo = usuario.rolCuentaEmpleadoCodigo.toLowerCase();
    await SecureStorageUtils.write(_userRoleKey, rolCodigo);
    await SecureStorageUtils.write(_userSucursalKey, usuario.sucursal);
    await SecureStorageUtils.write(
        _userSucursalIdKey, usuario.sucursalId.toString());
  }

  Future<Map<String, dynamic>?> getUserData() async {
    // Intenta obtener los datos desde el AuthApi primero
    final userData = await _auth.getUserData();
    if (userData != null) {
      return userData;
    }

    // Si no hay datos en AuthApi, intenta recuperar desde las claves específicas en Secure Storage
    final String? id = await SecureStorageUtils.read(_userIdKey);
    final String? username = await SecureStorageUtils.read(_usernameKey);
    final String? rolCodigo = await SecureStorageUtils.read(_userRoleKey);
    final String? sucursal = await SecureStorageUtils.read(_userSucursalKey);
    final String? sucursalId =
        await SecureStorageUtils.read(_userSucursalIdKey);

    if (id == null || username == null || rolCodigo == null) {
      return null;
    }

    return <String, dynamic>{
      'id': id,
      'usuario': username,
      'rol': {'codigo': rolCodigo, 'nombre': rolCodigo},
      'sucursal': sucursal,
      'sucursalId': sucursalId,
    };
  }

  Future<void> logout() async {
    await _auth.clearTokens();
  }
}

/// Clase para manejar operaciones relacionadas con cuentas de empleados
///
/// Esta clase proporciona métodos para interactuar con el endpoint /api/cuentasempleados
class CuentasEmpleadosApi {
  final ApiClient _api;

  CuentasEmpleadosApi(this._api);

  /// Obtiene todas las cuentas de empleados con información detallada
  ///
  /// Retorna una lista con todas las cuentas de empleados incluyendo información
  /// sobre el empleado, rol y sucursal asociados
  Future<List<Map<String, dynamic>>> getCuentasEmpleados() async {
    try {
      logInfo('CuentasEmpleadosApi: Obteniendo lista de cuentas de empleados');

      final Map<String, dynamic> response = await _api.request(
        endpoint: '/cuentasempleados',
        method: 'GET',
        requiresAuth: true,
      );

      // Procesar la respuesta
      final List<dynamic> data = response['data'];
      final List<Map<String, dynamic>> items =
          data.map((item) => item as Map<String, dynamic>).toList();

      logInfo(
          'CuentasEmpleadosApi: Total de cuentas encontradas: ${items.length}');
      return items;
    } catch (e) {
      logError('CuentasEmpleadosApi: ERROR al obtener cuentas de empleados', e);
      rethrow;
    }
  }

  /// Obtiene una cuenta de empleado por su ID
  ///
  /// Retorna la información completa de una cuenta específica
  Future<Map<String, dynamic>?> getCuentaEmpleadoById(int id) async {
    try {
      logInfo('CuentasEmpleadosApi: Obteniendo cuenta de empleado con ID $id');

      final Map<String, dynamic> response = await _api.request(
        endpoint: '/cuentasempleados/$id',
        method: 'GET',
        requiresAuth: true,
      );

      if (response['data'] is Map<String, dynamic>) {
        return response['data'];
      }

      return null;
    } catch (e) {
      // Si el error es 404, simplemente retornar null
      if (e is ApiException && e.statusCode == 404) {
        logInfo('CuentasEmpleadosApi: No se encontró la cuenta con ID $id');
        return null;
      }

      logError('CuentasEmpleadosApi: ERROR al obtener cuenta de empleado', e);
      rethrow;
    }
  }

  /// Actualiza la información de una cuenta de empleado
  ///
  /// Permite modificar el usuario o el rol de una cuenta existente
  Future<Map<String, dynamic>> updateCuentaEmpleado({
    required int id,
    String? usuario,
    String? clave,
    int? rolCuentaEmpleadoId,
  }) async {
    try {
      logInfo(
          'CuentasEmpleadosApi: Actualizando cuenta de empleado con ID $id');

      // Verificar que se haya proporcionado al menos un campo
      if (usuario == null && clave == null && rolCuentaEmpleadoId == null) {
        throw ApiException(
          statusCode: 400,
          message: 'Debe proporcionar al menos un campo para actualizar',
          errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
        );
      }

      // Construir cuerpo de la solicitud
      final Map<String, dynamic> body = <String, dynamic>{};
      if (usuario != null) {
        body['usuario'] = usuario;
      }
      if (clave != null) {
        body['clave'] = clave;
      }
      if (rolCuentaEmpleadoId != null) {
        body['rolCuentaEmpleadoId'] = rolCuentaEmpleadoId;
      }

      final Map<String, dynamic> response = await _api.request(
        endpoint: '/cuentasempleados/$id',
        method: 'PATCH',
        body: body,
        requiresAuth: true,
      );

      if (response['data'] is Map<String, dynamic>) {
        return response['data'];
      }

      throw ApiException(
        statusCode: 500,
        message: 'Formato de respuesta inesperado',
        errorCode: ApiConstants.errorCodes[500] ?? ApiConstants.unknownError,
      );
    } catch (e) {
      logError(
          'CuentasEmpleadosApi: ERROR al actualizar cuenta de empleado', e);
      rethrow;
    }
  }

  /// Elimina una cuenta de empleado
  ///
  /// Elimina permanentemente una cuenta de usuario
  Future<bool> deleteCuentaEmpleado(int id) async {
    try {
      logInfo('CuentasEmpleadosApi: Eliminando cuenta de empleado con ID $id');

      await _api.request(
        endpoint: '/cuentasempleados/$id',
        method: 'DELETE',
        requiresAuth: true,
      );

      logInfo(
          'CuentasEmpleadosApi: Cuenta de empleado eliminada correctamente');
      return true;
    } catch (e) {
      logError('CuentasEmpleadosApi: ERROR al eliminar cuenta de empleado', e);
      return false;
    }
  }

  /// Obtiene la cuenta de un empleado por su ID de empleado
  ///
  /// Útil para verificar si un empleado ya tiene una cuenta asociada
  Future<Map<String, dynamic>?> getCuentaByEmpleadoId(String empleadoId) async {
    try {
      logInfo(
          'CuentasEmpleadosApi: Obteniendo cuenta para empleado con ID $empleadoId');

      final Map<String, dynamic> response = await _api.request(
        endpoint: '/cuentasempleados/empleado/$empleadoId',
        method: 'GET',
        requiresAuth: true,
      );

      if (response['data'] is Map<String, dynamic>) {
        return response['data'];
      }

      return null;
    } catch (e) {
      // Si el error es 404 o 401, simplemente retornar null (el empleado no tiene cuenta)
      // El backend a veces devuelve 401 en lugar de 404 para este caso específico
      if (e is ApiException && (e.statusCode == 404 || e.statusCode == 401)) {
        logInfo(
            'CuentasEmpleadosApi: El empleado $empleadoId no tiene cuenta asociada (${e.statusCode})');
        return null;
      }

      logError('CuentasEmpleadosApi: ERROR al obtener cuenta por empleado', e);
      rethrow;
    }
  }

  /// Obtiene los roles disponibles para cuentas de empleados
  ///
  /// Retorna una lista de todos los roles que pueden asignarse a una cuenta
  Future<List<Map<String, dynamic>>> getRolesCuentas() async {
    try {
      logInfo('CuentasEmpleadosApi: Obteniendo roles para cuentas');

      final Map<String, dynamic> response = await _api.request(
        endpoint: '/rolescuentas',
        method: 'GET',
        requiresAuth: true,
      );

      if (response['data'] is List) {
        return (response['data'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }

      return <Map<String, dynamic>>[];
    } catch (e) {
      logError('CuentasEmpleadosApi: ERROR al obtener roles de cuentas', e);
      return <Map<String, dynamic>>[];
    }
  }

  /// Registra una nueva cuenta para un empleado
  ///
  /// Crea una cuenta de usuario asociada a un empleado existente
  Future<Map<String, dynamic>> registerEmpleadoAccount({
    required String empleadoId,
    required String usuario,
    required String clave,
    required int rolCuentaEmpleadoId,
  }) async {
    try {
      logInfo(
          'CuentasEmpleadosApi: Registrando cuenta para empleado con ID $empleadoId');

      // Preparar datos para la petición
      final Map<String, dynamic> body = <String, dynamic>{
        'usuario': usuario,
        'clave': clave,
        'rolCuentaEmpleadoId': rolCuentaEmpleadoId,
        'empleadoId': empleadoId,
      };

      // Hacer la petición al endpoint adecuado
      final Map<String, dynamic> response = await _api.request(
        endpoint: '/cuentasempleados',
        method: 'POST',
        body: body,
        requiresAuth: true,
      );

      // Verificar y devolver la respuesta
      if (response['data'] is Map<String, dynamic>) {
        logInfo('CuentasEmpleadosApi: Cuenta registrada exitosamente');
        return response['data'];
      }

      throw ApiException(
        statusCode: 500,
        message: 'Formato de respuesta inesperado al registrar cuenta',
        errorCode: ApiConstants.errorCodes[500] ?? ApiConstants.unknownError,
      );
    } catch (e) {
      logError('CuentasEmpleadosApi: ERROR al registrar cuenta de empleado', e);
      rethrow;
    }
  }
}
