import 'dart:convert';

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
  bool get hasRefreshToken => _refreshToken != null && _refreshToken!.isNotEmpty;
  
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
          debugPrint('TokenService: Login automático exitoso, token actualizado');
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
      
      if (username == null || password == null || username.isEmpty || password.isEmpty) {
        debugPrint('TokenService: No hay credenciales guardadas para login automático');
        return false;
      }
      
      if (_baseUrl.isEmpty) {
        debugPrint('TokenService: URL base no configurada, no se puede hacer login automático');
        return false;
      }
      
      debugPrint('TokenService: Intentando login automático para usuario: $username');
      
      // Construir URL completa para login
      final String loginUrl = '$_baseUrl/auth/login';
      
      // Realizar solicitud de login
      final http.Response response = await http.post(
        Uri.parse(loginUrl),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: json.encode(<String, String>{
          'usuario': username,
          'clave': password,
        }),
      ).timeout(const Duration(seconds: 10));
      
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
          } else if (responseData.containsKey('data') && responseData['data'] is Map) {
            final Map<String, dynamic> data = responseData['data'] as Map<String, dynamic>;
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
          } else if (responseData.containsKey('data') && responseData['data'] is Map) {
            final Map<String, dynamic> data = responseData['data'] as Map<String, dynamic>;
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
      
      debugPrint('TokenService: Login automático falló: ${response.statusCode}');
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
    try {
      debugPrint('TokenService: Eliminando tokens');
      
      // Limpiar memoria
      _accessToken = null;
      _refreshToken = null;
      _expiryTime = null;
      
      // Limpiar SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_expiryTimeKey);
      
      debugPrint('TokenService: Tokens eliminados correctamente');
    } catch (e) {
      debugPrint('TokenService: ERROR al eliminar tokens: $e');
      // No propagar el error, para asegurarnos de que por lo menos en memoria se eliminan
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
  
  /// Genera un token temporal cuando el backend no proporciona uno
  /// 
  /// Útil como solución temporal cuando el backend no implementa tokens
  Future<String> generateTemporaryToken({
    required Map<String, dynamic> userData,
    int expiryInSeconds = 86400, // 24 horas por defecto
  }) async {
    debugPrint('TokenService: ADVERTENCIA - Se solicitó generar un token temporal, pero esta funcionalidad está deshabilitada');
    debugPrint('TokenService: Se recomienda usar el login normal para obtener un token válido');
    
    // En lugar de generar un token temporal, lanzamos una excepción
    // para forzar el flujo de autenticación normal
    throw Exception('Generación de tokens temporales deshabilitada - Use login normal');
  }
  
  /// Verifica si el token actual es un token temporal generado por la aplicación
  bool isTemporaryToken() {
    // Ya no generamos tokens temporales, así que siempre devolvemos false
    return false;
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
  /// 
  /// Útil cuando se recibe un nuevo refresh token sin un nuevo access token
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
  /// 
  /// Este método maneja automáticamente:
  /// - Agregar el token de acceso al encabezado de autorización
  /// - Renovar el token si está expirado antes de la solicitud
  /// - Reintentar la solicitud si el token es rechazado
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
          .map((MapEntry<String, String> e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      url = '$url${url.contains('?') ? '&' : '?'}$queryString';
    }
    
    // Verificar si necesitamos refrescar el token antes de hacer la solicitud
    if (_accessToken != null && isTokenExpired && hasRefreshToken && !_isRefreshingToken) {
      debugPrint('TokenService: Token expirado, intentando refrescar antes de la solicitud');
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
      debugPrint('TokenService: ADVERTENCIA - Realizando solicitud sin token de autenticación');
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
          response = await http.get(
            Uri.parse(url),
            headers: requestHeaders,
          ).timeout(const Duration(seconds: 30));
          break;
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          ).timeout(const Duration(seconds: 30));
          break;
        case 'PUT':
          response = await http.put(
            Uri.parse(url),
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          ).timeout(const Duration(seconds: 30));
          break;
        case 'PATCH':
          response = await http.patch(
            Uri.parse(url),
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          ).timeout(const Duration(seconds: 30));
          break;
        case 'DELETE':
          response = await http.delete(
            Uri.parse(url),
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          ).timeout(const Duration(seconds: 30));
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
      } else if (statusCode == 401 && _accessToken != null && _requestRetryCount < _maxRetryCount) {
        // Token rechazado, verificar si debemos intentar refrescar el token
        // Si se ha especificado que no se debe reintentar con el header x-no-retry-on-401, respetarlo
        final bool noRetryOn401 = headers != null && headers.containsKey('x-no-retry-on-401') && headers['x-no-retry-on-401'] == 'true';
        
        if (noRetryOn401) {
          debugPrint('TokenService: Token rechazado (401), pero no se reintentará debido al header x-no-retry-on-401');
          // Convertir a una respuesta que indique claramente "no encontrado" (404)
          if (response.body.toLowerCase().contains('not found') || 
              response.body.toLowerCase().contains('no encontrado') ||
              response.body.toLowerCase().contains('no existe')) {
            throw Exception('404 - Resource not found: ${response.body}');
          }
          // Propagar el error original
          throw _createExceptionFromResponse(statusCode, response.body);
        }
        
        debugPrint('TokenService: Token rechazado (401), intentando refrescar y reintentar');
        
        _requestRetryCount++;
        
        try {
          // Intentar refrescar el token
          await _refreshTokenRequest();
          
          // Reintentar la solicitud original con el nuevo token
          final Map<String, dynamic> retriedResponse = await authenticatedRequest(
            endpoint: endpoint,
            method: method,
            body: body,
            queryParams: queryParams,
            headers: headers,
          );
          
          _requestRetryCount = 0;
          return retriedResponse;
        } catch (refreshError) {
          debugPrint('TokenService: Error al refrescar token rechazado: $refreshError');
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
          debugPrint('TokenService: Token encontrado en encabezados de respuesta');
          
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
          final Map<String, dynamic> data = body['data'] as Map<String, dynamic>;
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
          final Map<String, dynamic> data = body['data'] as Map<String, dynamic>;
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
      debugPrint('TokenService: Ya hay una operación de refresh en curso, esperando...');
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
      debugPrint('TokenService: Intentando refrescar token con endpoint /auth/refresh');
      
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
      final http.Response response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));
      
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