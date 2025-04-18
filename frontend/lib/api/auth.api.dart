import 'dart:convert';

import 'package:condorsmotors/api/main.api.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar tokens de autenticación
///
/// Proporciona métodos para guardar, recuperar y gestionar tokens JWT
class TokenService {
  static final TokenService _instance = TokenService._internal();

  // Singleton
  static TokenService get instance => _instance;

  // Claves para almacenamiento en SharedPreferences
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiryTimeKey = 'expiry_time';
  static const String _lastUsernameKey = 'last_username';
  static const String _lastPasswordKey = 'last_password';

  // URL base del API (será configurada por la aplicación)
  String _baseUrl = '';

  // Variables en memoria
  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiryTime;

  // Control de recursividad para evitar ciclos infinitos
  bool _isRefreshingToken = false;
  int _requestRetryCount = 0;
  static const int _maxRetryCount = 2;

  // Constructor privado
  TokenService._internal();

  // Configurar URL base
  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
    debugPrint('TokenService: URL base configurada: $_baseUrl');
  }

  // Getters
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
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

  /// Verifica si hay un token de refresco disponible
  bool get hasRefreshToken =>
      _refreshToken != null && _refreshToken!.isNotEmpty;

  /// Verifica si hay un token de acceso válido
  bool get hasValidToken => _accessToken != null && !isTokenExpired;

  /// Carga los tokens desde SharedPreferences
  Future<bool> loadTokens() async {
    try {
      debugPrint('TokenService: Cargando tokens desde SharedPreferences');

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      _accessToken = prefs.getString(_accessTokenKey);
      _refreshToken = prefs.getString(_refreshTokenKey);

      final String? expiryTimeStr = prefs.getString(_expiryTimeKey);
      if (expiryTimeStr != null) {
        _expiryTime = DateTime.parse(expiryTimeStr);
      }

      // Verificar si el token está expirado
      if (isTokenExpired) {
        debugPrint('TokenService: Token expirado o a punto de expirar');

        // Intentar hacer login automático si hay credenciales guardadas
        if (await _attemptAutoLogin()) {
          debugPrint(
              'TokenService: Login automático exitoso, token actualizado');
          return true;
        }

        return false;
      }

      debugPrint('TokenService: Tokens cargados correctamente');
      return _accessToken != null;
    } catch (e) {
      debugPrint('TokenService: ERROR al cargar tokens: $e');
      return false;
    }
  }

  /// Intenta hacer login automático con credenciales guardadas
  Future<bool> _attemptAutoLogin() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? username = prefs.getString(_lastUsernameKey);
      final String? password = prefs.getString(_lastPasswordKey);

      if (username == null ||
          password == null ||
          username.isEmpty ||
          password.isEmpty) {
        debugPrint(
            'TokenService: No hay credenciales guardadas para login automático');
        return false;
      }

      if (_baseUrl.isEmpty) {
        debugPrint(
            'TokenService: URL base no configurada, no se puede hacer login automático');
        return false;
      }

      debugPrint(
          'TokenService: Intentando login automático para usuario: $username');

      // Construir URL completa para login
      final String loginUrl = '$_baseUrl/auth/login';

      // Realizar solicitud de login
      final http.Response response = await http
          .post(
            Uri.parse(loginUrl),
            headers: <String, String>{'Content-Type': 'application/json'},
            body: json.encode(<String, String>{
              'usuario': username,
              'clave': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      // Verificar respuesta
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);

        // Buscar token en la respuesta
        String? accessToken;
        String? refreshToken;
        int expiryInSeconds = 3600; // 1 hora por defecto

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

          // Buscar refresh token
          if (responseData.containsKey('refresh_token')) {
            refreshToken = responseData['refresh_token']?.toString();
          } else if (responseData.containsKey('refreshToken')) {
            refreshToken = responseData['refreshToken']?.toString();
          } else if (responseData.containsKey('data') &&
              responseData['data'] is Map) {
            final Map<String, dynamic> data =
                responseData['data'] as Map<String, dynamic>;
            if (data.containsKey('refresh_token')) {
              refreshToken = data['refresh_token']?.toString();
            } else if (data.containsKey('refreshToken')) {
              refreshToken = data['refreshToken']?.toString();
            }
          }

          // Buscar tiempo de expiración
          if (responseData.containsKey('expires_in')) {
            expiryInSeconds = responseData['expires_in'] is int
                ? responseData['expires_in']
                : int.tryParse(responseData['expires_in'].toString()) ?? 3600;
          } else if (responseData.containsKey('expiresIn')) {
            expiryInSeconds = responseData['expiresIn'] is int
                ? responseData['expiresIn']
                : int.tryParse(responseData['expiresIn'].toString()) ?? 3600;
          }
        }

        // Si se encontró un token, guardarlo
        if (accessToken != null && accessToken.isNotEmpty) {
          await saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiryInSeconds: expiryInSeconds,
          );

          debugPrint('TokenService: Login automático exitoso, token guardado');
          return true;
        }
      }

      debugPrint(
          'TokenService: Login automático falló: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('TokenService: ERROR en login automático: $e');
      return false;
    }
  }

  /// Guarda los tokens en SharedPreferences
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    int expiryInSeconds = 3600, // 1 hora por defecto
  }) async {
    try {
      debugPrint('TokenService: Guardando tokens en SharedPreferences');

      // Actualizar variables en memoria primero
      _accessToken = accessToken;
      if (refreshToken != null) {
        _refreshToken = refreshToken;
      }

      // Calcular tiempo de expiración
      _expiryTime = DateTime.now().add(Duration(seconds: expiryInSeconds));

      // Guardar en SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString(_accessTokenKey, accessToken);
      if (refreshToken != null) {
        await prefs.setString(_refreshTokenKey, refreshToken);
      }
      await prefs.setString(_expiryTimeKey, _expiryTime!.toIso8601String());

      debugPrint('TokenService: Tokens guardados correctamente');
    } catch (e) {
      debugPrint('TokenService: ERROR al guardar tokens: $e');
    }
  }

  /// Guarda las credenciales del usuario para futuros login automáticos
  Future<void> saveCredentials(String username, String password) async {
    try {
      debugPrint('TokenService: Guardando credenciales para login automático');

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUsernameKey, username);
      await prefs.setString(_lastPasswordKey, password);

      debugPrint('TokenService: Credenciales guardadas correctamente');
    } catch (e) {
      debugPrint('TokenService: ERROR al guardar credenciales: $e');
    }
  }

  /// Elimina los tokens del almacenamiento
  Future<void> clearTokens() async {
    debugPrint('Limpiando tokens y datos de usuario...');
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Obtener todas las claves almacenadas
      final Set<String> keys = prefs.getKeys();

      // Lista de claves específicas que queremos conservar (como configuraciones de app)
      final Set<String> keysToKeep = {
        'theme_mode',
        'language',
        // Agregar otras configuraciones de app que no deban borrarse
      };

      // Crear lista de futures para borrar todo excepto las claves a conservar
      final List<Future<bool>> deleteFutures = keys
          .where((key) => !keysToKeep.contains(key))
          .map((key) => prefs.remove(key))
          .toList();

      // Ejecutar todas las operaciones de borrado
      await Future.wait([
        ...deleteFutures,
        // Asegurar que estas claves específicas se borren
        prefs.remove(_accessTokenKey),
        prefs.remove(_refreshTokenKey),
        prefs.remove('remember_me'),
        prefs.remove('username'),
        prefs.remove('password'),
        prefs.remove('username_auto'),
        prefs.remove('password_auto'),
        prefs.remove('last_sucursal'),
        prefs.remove('user_data'),
        prefs.setBool('stay_logged_in', false),
        // Limpiar datos de sucursal actual
        prefs.remove('current_sucursal_id'),
        prefs.remove('current_sucursal_data'),
        // Limpiar cualquier caché de datos
        prefs.remove('ventas_cache'),
        prefs.remove('productos_cache'),
        prefs.remove('proformas_cache'),
      ]);

      debugPrint('Tokens y datos de usuario limpiados correctamente');
    } catch (e) {
      debugPrint('Error al limpiar tokens y datos: $e');
      rethrow;
    }
  }

  /// Decodifica un token JWT y devuelve su payload
  Map<String, dynamic>? decodeToken(String token) {
    try {
      // Dividir el token en partes
      final List<String> parts = token.split('.');
      if (parts.length < 2) {
        debugPrint('TokenService: Formato de token inválido');
        return null;
      }

      // Decodificar la parte del payload (segunda parte)
      final String payload = parts[1];
      final String normalized = base64Url.normalize(payload);
      final String decodedPayload = utf8.decode(base64Url.decode(normalized));

      return json.decode(decodedPayload) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('TokenService: ERROR al decodificar token: $e');
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

    // Normalizar el rol
    final String? rolOriginal = decodedToken['rolCuentaEmpleadoCodigo'];
    String rolNormalizado = 'DESCONOCIDO';

    if (rolOriginal != null) {
      // Normalizar el rol según las reglas conocidas
      switch (rolOriginal.toUpperCase()) {
        case 'ADMINISTRADOR':
        case 'ADMINSTRADOR': // Typo en backend
        case 'ADM':
        case 'ADMIN':
          rolNormalizado = 'ADMINISTRADOR';
          break;
        case 'VENDEDOR':
        case 'VEN':
          rolNormalizado = 'VENDEDOR';
          break;
        case 'COMPUTADORA':
        case 'COMP':
          rolNormalizado = 'COMPUTADORA';
          break;
        default:
          rolNormalizado = 'DESCONOCIDO';
      }
    }

    return <String, dynamic>{
      'id': decodedToken['id']?.toString() ?? '',
      'usuario': decodedToken['usuario']?.toString() ?? '',
      'rol': rolNormalizado,
      'rolOriginal': rolOriginal,
      'sucursalId': decodedToken['sucursalId']?.toString() ?? '',
    };
  }

  /// Actualiza solo el refresh token manteniendo el access token existente
  Future<void> updateRefreshToken(String refreshToken) async {
    try {
      debugPrint('TokenService: Actualizando solo el refresh token');

      _refreshToken = refreshToken;

      // Guardar en SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshTokenKey, refreshToken);

      debugPrint('TokenService: Refresh token actualizado correctamente');
    } catch (e) {
      debugPrint('TokenService: ERROR al actualizar refresh token: $e');
    }
  }

  /// Realiza una solicitud HTTP autenticada con manejo de tokens
  Future<Map<String, dynamic>> authenticatedRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    if (_baseUrl.isEmpty) {
      throw Exception('URL base no configurada en TokenService');
    }

    // Construir URL completa
    String url = endpoint.startsWith('http')
        ? endpoint
        : '$_baseUrl${endpoint.startsWith('/') ? endpoint : '/$endpoint'}';

    // Agregar parámetros de consulta si existen
    if (queryParams != null && queryParams.isNotEmpty) {
      final String queryString = queryParams.entries
          .map((MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      url = '$url${url.contains('?') ? '&' : '?'}$queryString';
    }

    // Verificar si necesitamos refrescar el token antes de hacer la solicitud
    if (_accessToken != null &&
        isTokenExpired &&
        hasRefreshToken &&
        !_isRefreshingToken) {
      debugPrint(
          'TokenService: Token expirado, intentando refrescar antes de la solicitud');
      try {
        await _refreshTokenRequest();
      } catch (e) {
        debugPrint('TokenService: Error al refrescar token expirado: $e');
        // Si no podemos refrescar, continuamos con el token actual (podría ser rechazado)
      }
    }

    // Preparar encabezados
    final Map<String, String> requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (headers != null) ...headers,
    };

    // Agregar token de autorización si existe
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      requestHeaders['Authorization'] = 'Bearer $_accessToken';
    } else {
      debugPrint(
          'TokenService: ADVERTENCIA - Realizando solicitud sin token de autenticación');
    }

    http.Response response;

    // Realizar la solicitud HTTP según el método
    try {
      debugPrint('TokenService: Enviando solicitud $method a $url');

      // Para solicitudes PATCH, añadir más detalles
      if (method.toUpperCase() == 'PATCH') {
        debugPrint('TokenService: [PATCH] URL completa: $url');
        debugPrint('TokenService: [PATCH] Headers: $requestHeaders');
        if (body != null) {
          debugPrint('TokenService: [PATCH] Body: ${json.encode(body)}');
        }
      }

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(
                Uri.parse(url),
                headers: requestHeaders,
              )
              .timeout(const Duration(seconds: 30));
          break;
        case 'POST':
          response = await http
              .post(
                Uri.parse(url),
                headers: requestHeaders,
                body: body != null ? json.encode(body) : null,
              )
              .timeout(const Duration(seconds: 30));
          break;
        case 'PUT':
          response = await http
              .put(
                Uri.parse(url),
                headers: requestHeaders,
                body: body != null ? json.encode(body) : null,
              )
              .timeout(const Duration(seconds: 30));
          break;
        case 'PATCH':
          response = await http
              .patch(
                Uri.parse(url),
                headers: requestHeaders,
                body: body != null ? json.encode(body) : null,
              )
              .timeout(const Duration(seconds: 30));
          break;
        case 'DELETE':
          response = await http
              .delete(
                Uri.parse(url),
                headers: requestHeaders,
                body: body != null ? json.encode(body) : null,
              )
              .timeout(const Duration(seconds: 30));
          break;
        default:
          throw Exception('Método HTTP no soportado: $method');
      }

      // Procesar la respuesta
      final int statusCode = response.statusCode;

      // Extraer token de la respuesta si existe
      _processTokenFromResponse(response);

      if (statusCode >= 200 && statusCode < 300) {
        // Respuesta exitosa
        if (response.body.isEmpty) {
          return <String, dynamic>{'status': 'success'};
        }

        try {
          final responseData = json.decode(response.body);
          if (responseData is Map<String, dynamic>) {
            return responseData;
          } else {
            return <String, dynamic>{'status': 'success', 'data': responseData};
          }
        } catch (e) {
          return <String, dynamic>{'status': 'success', 'data': response.body};
        }
      } else if (statusCode == 401 &&
          _accessToken != null &&
          _requestRetryCount < _maxRetryCount) {
        // Token rechazado, verificar si debemos intentar refrescar el token
        // Si se ha especificado que no se debe reintentar con el header x-no-retry-on-401, respetarlo
        final bool noRetryOn401 = headers != null &&
            headers.containsKey('x-no-retry-on-401') &&
            headers['x-no-retry-on-401'] == 'true';

        if (noRetryOn401) {
          debugPrint(
              'TokenService: Token rechazado (401), pero no se reintentará debido al header x-no-retry-on-401');
          // Convertir a una respuesta que indique claramente "no encontrado" (404)
          if (response.body.toLowerCase().contains('not found') ||
              response.body.toLowerCase().contains('no encontrado') ||
              response.body.toLowerCase().contains('no existe')) {
            throw Exception('404 - Resource not found: ${response.body}');
          }
          // Propagar el error original
          throw _createExceptionFromResponse(statusCode, response.body);
        }

        debugPrint(
            'TokenService: Token rechazado (401), intentando refrescar y reintentar');

        _requestRetryCount++;

        try {
          // Intentar refrescar el token
          await _refreshTokenRequest();

          // Reintentar la solicitud original con el nuevo token
          final Map<String, dynamic> retriedResponse =
              await authenticatedRequest(
            endpoint: endpoint,
            method: method,
            body: body,
            queryParams: queryParams,
            headers: headers,
          );

          _requestRetryCount = 0;
          return retriedResponse;
        } catch (refreshError) {
          debugPrint(
              'TokenService: Error al refrescar token rechazado: $refreshError');
          _requestRetryCount = 0;

          // Propagar el error original
          throw _createExceptionFromResponse(statusCode, response.body);
        }
      } else {
        // Otro tipo de error
        throw _createExceptionFromResponse(statusCode, response.body);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error en la solicitud: $e');
    } finally {
      _requestRetryCount = 0;
    }
  }

  /// Procesa y extrae tokens de la respuesta HTTP si existen
  void _processTokenFromResponse(http.Response response) {
    try {
      final Map<String, String> headers = response.headers;
      final body = response.body.isNotEmpty ? json.decode(response.body) : null;

      // Verificar si hay token en los encabezados
      final String authHeader = headers['authorization'] ?? '';
      if (authHeader.startsWith('Bearer ')) {
        final String token = authHeader.substring(7);
        if (token.isNotEmpty) {
          debugPrint(
              'TokenService: Token encontrado en encabezados de respuesta');

          // Decodificar token para obtener tiempo de expiración
          final Map<String, dynamic>? decodedToken = decodeToken(token);
          int expiryInSeconds = 3600; // 1 hora por defecto

          if (decodedToken != null && decodedToken.containsKey('exp')) {
            final int expTimestamp = decodedToken['exp'] as int;
            final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            expiryInSeconds = expTimestamp - now;
          }

          // Guardar el token
          saveTokens(
            accessToken: token,
            expiryInSeconds: expiryInSeconds,
          );
        }
      }

      // Si no hay token en los encabezados, buscar en el cuerpo
      if (body != null && body is Map<String, dynamic>) {
        String? accessToken;
        String? refreshToken;
        int expiryInSeconds = 3600; // 1 hora por defecto

        // Buscar token de acceso en diferentes ubicaciones posibles
        if (body.containsKey('token')) {
          accessToken = body['token']?.toString();
        } else if (body.containsKey('access_token')) {
          accessToken = body['access_token']?.toString();
        } else if (body.containsKey('data') && body['data'] is Map) {
          final Map<String, dynamic> data =
              body['data'] as Map<String, dynamic>;
          if (data.containsKey('token')) {
            accessToken = data['token']?.toString();
          } else if (data.containsKey('access_token')) {
            accessToken = data['access_token']?.toString();
          }
        }

        // Buscar refresh token
        if (body.containsKey('refresh_token')) {
          refreshToken = body['refresh_token']?.toString();
        } else if (body.containsKey('refreshToken')) {
          refreshToken = body['refreshToken']?.toString();
        } else if (body.containsKey('data') && body['data'] is Map) {
          final Map<String, dynamic> data =
              body['data'] as Map<String, dynamic>;
          if (data.containsKey('refresh_token')) {
            refreshToken = data['refresh_token']?.toString();
          } else if (data.containsKey('refreshToken')) {
            refreshToken = data['refreshToken']?.toString();
          }
        }

        // Buscar tiempo de expiración
        if (body.containsKey('expires_in')) {
          expiryInSeconds = body['expires_in'] is int
              ? body['expires_in']
              : int.tryParse(body['expires_in'].toString()) ?? 3600;
        } else if (body.containsKey('expiresIn')) {
          expiryInSeconds = body['expiresIn'] is int
              ? body['expiresIn']
              : int.tryParse(body['expiresIn'].toString()) ?? 3600;
        }

        // Si el token fue encontrado en el cuerpo, guardarlo
        if (accessToken != null && accessToken.isNotEmpty) {
          debugPrint('TokenService: Token encontrado en cuerpo de respuesta');

          // Decodificar token para verificar/ajustar tiempo de expiración
          final Map<String, dynamic>? decodedToken = decodeToken(accessToken);
          if (decodedToken != null && decodedToken.containsKey('exp')) {
            final int expTimestamp = decodedToken['exp'] as int;
            final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            expiryInSeconds = expTimestamp - now;
          }

          // Guardar tokens
          saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiryInSeconds: expiryInSeconds,
          );
        }
      }
    } catch (e) {
      debugPrint('TokenService: ERROR al procesar tokens de respuesta: $e');
    }
  }

  /// Refresca el token usando el endpoint /auth/refresh
  Future<void> _refreshTokenRequest() async {
    if (_isRefreshingToken) {
      debugPrint(
          'TokenService: Ya hay una operación de refresh en curso, esperando...');
      // Esperar a que termine la operación actual
      int attempts = 0;
      while (_isRefreshingToken && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 300));
        attempts++;
      }

      if (_isRefreshingToken) {
        throw Exception('Timeout esperando por operación de refresh token');
      }

      // Si ya no estamos refrescando y el token es válido, regresar
      if (!isTokenExpired) {
        return;
      }
    }

    // Verificar que tenemos un refresh token
    if (!hasRefreshToken) {
      throw Exception('No hay refresh token disponible para renovar el token');
    }

    // Marcar que estamos refrescando para evitar llamadas simultáneas
    _isRefreshingToken = true;

    try {
      debugPrint(
          'TokenService: Intentando refrescar token con endpoint /auth/refresh');

      // Construir URL para refresh
      final String url = '$_baseUrl/auth/refresh';

      // Preparar encabezados con el refresh token
      final Map<String, String> headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Incluir refresh token en body
      final Map<String, String?> body = <String, String?>{
        'refresh_token': _refreshToken,
      };

      // Realizar solicitud POST
      final http.Response response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      final int statusCode = response.statusCode;

      if (statusCode >= 200 && statusCode < 300) {
        // Procesar tokens de la respuesta
        _processTokenFromResponse(response);

        // Verificar que se haya actualizado el token
        if (isTokenExpired) {
          throw Exception('Token sigue expirado después de refresh');
        }

        debugPrint('TokenService: Token refrescado exitosamente');
      } else {
        // Error al refrescar token
        debugPrint('TokenService: Error al refrescar token: $statusCode');
        throw _createExceptionFromResponse(statusCode, response.body);
      }
    } catch (e) {
      debugPrint('TokenService: ERROR durante refresh token: $e');
      // Si hay un error durante el refresh, limpiar tokens
      await clearTokens();
      rethrow;
    } finally {
      // Marcar que ya no estamos refrescando
      _isRefreshingToken = false;
    }
  }

  /// Crea una excepción a partir de la respuesta HTTP
  Exception _createExceptionFromResponse(int statusCode, String responseBody) {
    try {
      // Intentar parsear el cuerpo para obtener mensaje de error
      if (responseBody.isNotEmpty) {
        final responseData = json.decode(responseBody);
        if (responseData is Map<String, dynamic>) {
          final message = responseData['message'] ??
              responseData['error'] ??
              'Error en la solicitud HTTP';
          return Exception('$statusCode - $message');
        }
      }
    } catch (e) {
      // Si no se puede parsear, usar mensaje genérico
    }

    return Exception('$statusCode - Error en la solicitud HTTP');
  }
}

/// Clase para gestionar la autenticación y tokens
class AuthApi {
  final ApiClient _api;

  // Claves de almacenamiento
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
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString(_getKey('userData'));
      if (userData == null) {
        return null;
      }
      return json.decode(userData) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error obteniendo datos del usuario: $e');
      return null;
    }
  }

  /// Guarda los datos del usuario localmente
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_getKey('userData'), json.encode(userData));
      debugPrint('Datos del usuario guardados correctamente');
    } catch (e) {
      debugPrint('Error al guardar datos del usuario: $e');
      rethrow;
    }
  }

  /// Limpia los tokens y datos de usuario almacenados
  Future<void> clearTokens() async {
    debugPrint('Limpiando tokens y datos de usuario...');
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Obtener todas las claves almacenadas
      final Set<String> keys = prefs.getKeys();

      // Lista de claves específicas que queremos conservar
      final Set<String> keysToKeep = {
        'theme_mode',
        'language',
        'server_url', // Mantener la configuración del servidor
      };

      // Crear lista de futures para borrar todo excepto las claves a conservar
      final List<Future<bool>> deleteFutures = keys
          .where((key) => !keysToKeep.contains(key))
          .map((key) => prefs.remove(key))
          .toList();

      // Ejecutar todas las operaciones de borrado
      await Future.wait([
        ...deleteFutures,
        // Asegurar que estas claves críticas se borren
        prefs.remove(_getKey('token')),
        prefs.remove(_getKey('refresh')),
        prefs.remove(_getKey('userData')),
        prefs.remove(_getKey('sucursal')),
        prefs.remove(_getKey('sucursalId')),
        // Limpiar datos de sesión
        prefs.remove(_getKey('remember')),
        prefs.remove(_getKey('username')),
        prefs.remove(_getKey('password')),
        prefs.remove(_getKey('usernameAuto')),
        prefs.remove(_getKey('passwordAuto')),
        prefs.setBool(_getKey('stayLogged'), false),
        // Limpiar caches específicos
        prefs.remove(_getKey('ventasCache')),
        prefs.remove(_getKey('productosCache')),
        prefs.remove(_getKey('proformasCache')),
        prefs.remove(_getKey('dashboardCache')),
      ]);

      debugPrint('Tokens y datos de usuario limpiados correctamente');
    } catch (e) {
      debugPrint('Error al limpiar tokens y datos: $e');
      rethrow;
    }
  }

  /// Cierra la sesión del usuario
  Future<void> logout() async {
    try {
      debugPrint('Iniciando proceso de logout en el servidor...');

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
        debugPrint(
            'Servidor: ${response['message'] ?? 'Sesión terminada exitosamente'}');
      }

      // Limpiar todos los datos locales independientemente de la respuesta del servidor
      await clearTokens();

      // Reiniciar el estado del cliente API sin propagar errores
      try {
        await _api.clearState();
      } catch (stateError) {
        debugPrint(
            'Error no crítico al limpiar estado del cliente API: $stateError');
      }

      debugPrint('Logout completado exitosamente');
    } catch (e) {
      debugPrint('Error durante proceso de logout: $e');
      // Intentar limpiar datos locales incluso si falla la comunicación con el servidor
      try {
        await clearTokens();
        try {
          await _api.clearState();
        } catch (stateError) {
          debugPrint(
              'Error no crítico al limpiar estado del cliente API: $stateError');
        }
      } catch (cleanupError) {
        debugPrint('Error adicional durante limpieza: $cleanupError');
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
      debugPrint('Error verificando autenticación: $e');
      return false;
    }
  }

  /// Verifica si hay un token almacenado y es válido
  Future<bool> _hasValidToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString(_getKey('token'));
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
        debugPrint('Token inválido: respuesta con formato incorrecto');
        await clearTokens();
        return false;
      }

      // Actualizar datos del usuario en SharedPreferences
      final Map<String, dynamic> userData =
          response['data'] as Map<String, dynamic>;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_getKey('userData'), json.encode(userData));

      return true;
    } catch (e) {
      debugPrint('Error verificando token: $e');

      // Si el error contiene "Invalid or missing authorization token", consideramos que estamos deslogueados
      if (e
          .toString()
          .toLowerCase()
          .contains('invalid or missing authorization token')) {
        debugPrint(
            'Estado de sesión: Usuario no logueado o token inválido - Se requiere iniciar sesión');
        await clearTokens();
        return false;
      }

      // Para otros tipos de errores, verificar si es un error de autorización
      if (e is ApiException && (e.statusCode == 401 || e.statusCode == 403)) {
        debugPrint(
            'Error de autorización: Usuario no autorizado - Se requiere iniciar sesión');
        await clearTokens();
        return false;
      }

      return false;
    }
  }

  /// Inicia sesión con usuario y contraseña
  Future<UsuarioAutenticado> login(String usuario, String clave) async {
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
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_getKey('userData'), json.encode(userData));

      // Crear instancia de UsuarioAutenticado con los datos recibidos
      final UsuarioAutenticado usuarioAutenticado =
          UsuarioAutenticado.fromJson(userData);
      debugPrint('Login exitoso para usuario: ${usuarioAutenticado.usuario}');
      return usuarioAutenticado;
    } catch (e) {
      debugPrint('Error durante login: $e');

      // Mejorar la detección de errores de credenciales incorrectas
      if (e is ApiException) {
        if (e.statusCode == 400) {
          // Extraer el mensaje de error si existe
          final dynamic errorData = e.data;
          if (errorData is Map<String, dynamic> && errorData['error'] != null) {
            final String errorMsg = errorData['error'].toString();
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
        }
      }

      rethrow;
    }
  }

  /// Refresca el token de acceso usando el refresh token
  Future<void> refreshToken() async {
    try {
      final Map<String, dynamic> response = await _api.request(
        endpoint: '/auth/refresh',
        method: 'POST',
        requiresAuth: true,
      );

      final String? newToken =
          response['authorization']?.toString().replaceAll('Bearer ', '');
      if (newToken == null || newToken.isEmpty) {
        throw ApiException(
          statusCode: 401,
          message: 'Error: No se pudo obtener el nuevo token',
          errorCode: ApiConstants.errorCodes[401] ?? ApiConstants.unknownError,
        );
      }

      // Guardar nuevo token
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_getKey('token'), newToken);
    } catch (e) {
      debugPrint('Error durante refresh token: $e');
      rethrow;
    }
  }
}

/// Clase para representar los datos del usuario autenticado
class UsuarioAutenticado {
  final String id;
  final String usuario;
  final String rolCuentaEmpleadoId;
  final String rolCuentaEmpleadoCodigo;
  final String empleadoId;
  final Map<String, dynamic> empleado;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final String sucursal;
  final int sucursalId;

  UsuarioAutenticado({
    required this.id,
    required this.usuario,
    required this.rolCuentaEmpleadoId,
    required this.rolCuentaEmpleadoCodigo,
    required this.empleadoId,
    required this.empleado,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.sucursal,
    required this.sucursalId,
  });

  // Convertir a Map para almacenamiento o navegación
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'usuario': usuario,
      'rol': {
        'codigo': rolCuentaEmpleadoCodigo.toLowerCase(),
        'nombre': rolCuentaEmpleadoCodigo
      },
      'rolId': rolCuentaEmpleadoId,
      'empleadoId': empleadoId,
      'empleado': empleado,
      'sucursal': sucursal,
      'sucursalId': sucursalId.toString(),
    };
  }

  // Crear desde respuesta JSON
  factory UsuarioAutenticado.fromJson(Map<String, dynamic> json) {
    debugPrint('Procesando datos de usuario: ${json.toString()}');

    // Extraer sucursalId con manejo seguro de tipos
    int sucursalId;
    try {
      if (json['sucursalId'] is int) {
        sucursalId = json['sucursalId'];
      } else if (json['sucursalId'] is String) {
        sucursalId = int.tryParse(json['sucursalId']) ?? 0;
        debugPrint('Convertido sucursalId de String a int: $sucursalId');
      } else {
        sucursalId = 0;
        debugPrint(
            'ADVERTENCIA: sucursalId no es int ni String, usando valor por defecto 0');
      }
    } catch (e) {
      sucursalId = 0;
      debugPrint('ERROR al procesar sucursalId: $e');
    }

    // Procesar datos del empleado
    final Map<String, dynamic> empleadoData =
        json['empleado'] as Map<String, dynamic>? ??
            <String, dynamic>{'activo': true, 'nombres': '', 'apellidos': ''};

    return UsuarioAutenticado(
      id: json['id']?.toString() ?? '',
      usuario: json['usuario'] ?? '',
      rolCuentaEmpleadoId: json['rolCuentaEmpleadoId']?.toString() ?? '',
      rolCuentaEmpleadoCodigo:
          json['rolCuentaEmpleadoCodigo']?.toString().toLowerCase() ?? '',
      empleadoId: json['empleadoId']?.toString() ?? '',
      empleado: empleadoData,
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'])
          : DateTime.now(),
      fechaActualizacion: json['fechaActualizacion'] != null
          ? DateTime.parse(json['fechaActualizacion'])
          : DateTime.now(),
      sucursal: json['sucursal'] ?? '',
      sucursalId: sucursalId,
    );
  }

  @override
  String toString() {
    return 'UsuarioAutenticado{id: $id, usuario: $usuario, rol: $rolCuentaEmpleadoCodigo, empleado: ${empleado['nombres']} ${empleado['apellidos']}, sucursal: $sucursal, sucursalId: $sucursalId}';
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

  Future<void> saveUserData(UsuarioAutenticado usuario) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, usuario.id);
    await prefs.setString(_usernameKey, usuario.usuario);

    // Guardar el código del rol
    final String rolCodigo = usuario.rolCuentaEmpleadoCodigo.toLowerCase();
    await prefs.setString(_userRoleKey, rolCodigo);

    await prefs.setString(_userSucursalKey, usuario.sucursal);
    await prefs.setString(_userSucursalIdKey, usuario.sucursalId.toString());
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? id = prefs.getString(_userIdKey);
    final String? username = prefs.getString(_usernameKey);
    final String? rolCodigo = prefs.getString(_userRoleKey);
    final String? sucursal = prefs.getString(_userSucursalKey);
    final String? sucursalId = prefs.getString(_userSucursalIdKey);

    if (id == null || username == null || rolCodigo == null) {
      return null;
    }

    return <String, dynamic>{
      'id': id,
      'usuario': username,
      'rol': {
        'codigo': rolCodigo,
        'nombre':
            rolCodigo // Por simplicidad, usamos el mismo código como nombre
      },
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
      debugPrint(
          'CuentasEmpleadosApi: Obteniendo lista de cuentas de empleados');

      final Map<String, dynamic> response = await _api.request(
        endpoint: '/cuentasempleados',
        method: 'GET',
        requiresAuth: true,
      );

      // Procesar la respuesta
      final List<dynamic> data = response['data'];
      final List<Map<String, dynamic>> items =
          data.map((item) => item as Map<String, dynamic>).toList();

      debugPrint(
          'CuentasEmpleadosApi: Total de cuentas encontradas: ${items.length}');
      return items;
    } catch (e) {
      debugPrint(
          'CuentasEmpleadosApi: ERROR al obtener cuentas de empleados: $e');
      rethrow;
    }
  }

  /// Obtiene una cuenta de empleado por su ID
  ///
  /// Retorna la información completa de una cuenta específica
  Future<Map<String, dynamic>?> getCuentaEmpleadoById(int id) async {
    try {
      debugPrint(
          'CuentasEmpleadosApi: Obteniendo cuenta de empleado con ID $id');

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
        debugPrint('CuentasEmpleadosApi: No se encontró la cuenta con ID $id');
        return null;
      }

      debugPrint(
          'CuentasEmpleadosApi: ERROR al obtener cuenta de empleado: $e');
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
      debugPrint(
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
      debugPrint(
          'CuentasEmpleadosApi: ERROR al actualizar cuenta de empleado: $e');
      rethrow;
    }
  }

  /// Elimina una cuenta de empleado
  ///
  /// Elimina permanentemente una cuenta de usuario
  Future<bool> deleteCuentaEmpleado(int id) async {
    try {
      debugPrint(
          'CuentasEmpleadosApi: Eliminando cuenta de empleado con ID $id');

      await _api.request(
        endpoint: '/cuentasempleados/$id',
        method: 'DELETE',
        requiresAuth: true,
      );

      debugPrint(
          'CuentasEmpleadosApi: Cuenta de empleado eliminada correctamente');
      return true;
    } catch (e) {
      debugPrint(
          'CuentasEmpleadosApi: ERROR al eliminar cuenta de empleado: $e');
      return false;
    }
  }

  /// Obtiene la cuenta de un empleado por su ID de empleado
  ///
  /// Útil para verificar si un empleado ya tiene una cuenta asociada
  Future<Map<String, dynamic>?> getCuentaByEmpleadoId(String empleadoId) async {
    try {
      debugPrint(
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
        debugPrint(
            'CuentasEmpleadosApi: El empleado $empleadoId no tiene cuenta asociada (${e.statusCode})');
        return null;
      }

      debugPrint(
          'CuentasEmpleadosApi: ERROR al obtener cuenta por empleado: $e');
      rethrow;
    }
  }

  /// Obtiene los roles disponibles para cuentas de empleados
  ///
  /// Retorna una lista de todos los roles que pueden asignarse a una cuenta
  Future<List<Map<String, dynamic>>> getRolesCuentas() async {
    try {
      debugPrint('CuentasEmpleadosApi: Obteniendo roles para cuentas');

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
      debugPrint('CuentasEmpleadosApi: ERROR al obtener roles de cuentas: $e');
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
      debugPrint(
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
        debugPrint('CuentasEmpleadosApi: Cuenta registrada exitosamente');
        return response['data'];
      }

      throw ApiException(
        statusCode: 500,
        message: 'Formato de respuesta inesperado al registrar cuenta',
        errorCode: ApiConstants.errorCodes[500] ?? ApiConstants.unknownError,
      );
    } catch (e) {
      debugPrint(
          'CuentasEmpleadosApi: ERROR al registrar cuenta de empleado: $e');
      rethrow;
    }
  }
}
