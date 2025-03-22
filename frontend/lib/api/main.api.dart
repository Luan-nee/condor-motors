import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../services/token_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? errorCode;
  final dynamic data;
  
  // Códigos de error comunes
  static const String errorUnauthorized = 'unauthorized';
  static const String errorNotFound = 'not_found';
  static const String errorBadRequest = 'bad_request';
  static const String errorServer = 'server_error';
  static const String errorNetwork = 'network_error';
  static const String errorUnknown = 'unknown_error';
  ApiException({
    required this.statusCode,
    required this.message,
    this.errorCode,
    this.data,
  });
  
  // Constructor para crear excepciones desde códigos de estado HTTP
  static ApiException fromStatusCode(int statusCode, String message, {dynamic data}) {
    String errorCode;
    
    switch (statusCode) {
      case 400:
        errorCode = errorBadRequest;
        break;
      case 401:
      case 403:
        errorCode = errorUnauthorized;
        break;
      case 404:
        errorCode = errorNotFound;
        break;
      case 500:
      case 502:
      case 503:
        errorCode = errorServer;
        break;
      default:
        errorCode = errorUnknown;
    }
    
    return ApiException(
      statusCode: statusCode,
      message: message,
      errorCode: errorCode,
      data: data,
    );
  }
  
  @override
  String toString() => 'ApiException: $statusCode - $message';
}

// Constantes para tiempos de espera y reintentos
const int _defaultTimeoutSeconds = 15;

class ApiClient {
  final String baseUrl;
  final TokenService _tokenService;
// URL de respaldo para desarrollo local
  
  // Cliente HTTP con soporte para cookies persistentes
  final PersistentCookieClient _httpClient = PersistentCookieClient();
  
  ApiClient({
    required this.baseUrl,
    required TokenService tokenService,
  }) : _tokenService = tokenService;
  
  // Obtener headers con autenticación
  Map<String, String> get headers {
    final Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    
    final accessToken = _tokenService.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    
    return headers;
  }
  
  // Extraer token del cuerpo JSON
  String? _extractTokenFromBody(Map<String, dynamic> body) {
    try {
      // Buscar en ubicaciones comunes
      for (final tokenKey in ['token', 'access_token', 'accessToken']) {
        if (body[tokenKey] != null && body[tokenKey].toString().isNotEmpty) {
          final token = body[tokenKey].toString();
          debugPrint('ApiClient: Token extraído de body["$tokenKey"]');
          return token;
        }
      }
      
      // Buscar en data si existe
      if (body['data'] != null && body['data'] is Map) {
        final dataMap = body['data'] as Map;
        for (final tokenKey in ['token', 'access_token', 'accessToken']) {
          if (dataMap[tokenKey] != null && dataMap[tokenKey].toString().isNotEmpty) {
            final token = dataMap[tokenKey].toString();
            debugPrint('ApiClient: Token extraído de body["data"]["$tokenKey"]');
            return token;
          }
        }
      }
    } catch (e) {
      debugPrint('ApiClient: Error al extraer token del cuerpo JSON: $e');
    }
    
    return null;
  }
  
  // Métodos auxiliares - Movidos al principio para evitar errores de referencia
  dynamic _tryParseJson(String text) {
    try {
      return json.decode(text);
    } catch (e) {
      debugPrint('ApiClient: No se pudo parsear como JSON: $text');
      return text;
    }
  }
  
  String _getErrorMessage(http.Response response) {
    try {
      final data = json.decode(response.body);
      final errorMessage = data['error'] ?? data['message'] ?? 'Error en la solicitud';
      return errorMessage;
    } catch (e) {
      return 'Error en la solicitud (${response.statusCode})';
    }
  }
  
  /// Procesa los tokens de la respuesta y los guarda en el TokenService
  Future<void> _processTokenFromResponse(http.Response response, Map<String, dynamic> responseJson) async {
    // Primero intentar extraer token del cuerpo de la respuesta
    String? accessToken = _extractTokenFromBody(responseJson);
    String? refreshToken;
    
    debugPrint('ApiClient: Procesando tokens de la respuesta');
    
    // Si no hay token en el cuerpo, buscar en las cookies
    if (accessToken == null || accessToken.isEmpty) {
      // Buscar tokens en las cookies
      final cookies = (_httpClient).cookies;
      debugPrint('ApiClient: Cookies disponibles: ${cookies.keys.join(', ')}');
      
      // Buscar el token de acceso en las cookies (nombres comunes)
      for (final name in ['access_token', 'token', 'auth_token']) {
        if (cookies.containsKey(name)) {
          accessToken = cookies[name];
          debugPrint('ApiClient: Token encontrado en cookie "$name"');
          break;
        }
      }
        }
    
    // También extraer refresh token si está presente en el cuerpo
    if (responseJson.containsKey('refreshToken')) {
      refreshToken = responseJson['refreshToken']?.toString();
    } else if (responseJson.containsKey('data') && 
               responseJson.containsKey('data') &&
               responseJson['data'] is Map<String, dynamic> &&
               responseJson['data'].containsKey('refreshToken')) {
      refreshToken = responseJson['data']['refreshToken']?.toString();
    }
    
    // Verificar si hay refresh token en las cookies
    if ((refreshToken == null || refreshToken.isEmpty)) {
      final cookies = (_httpClient).cookies;
      if (cookies.containsKey('refresh_token')) {
        refreshToken = cookies['refresh_token'];
        debugPrint('ApiClient: Refresh token encontrado en cookie "refresh_token"');
      }
    }
    
    // Si encontramos un token de acceso, guardarlo
    if (accessToken != null && accessToken.isNotEmpty) {
      debugPrint('ApiClient: Token de acceso válido encontrado en la respuesta');
      
      // Intentar decodificar el token para determinar su expiración
      int expiryInSeconds = 3600; // 1 hora por defecto
      
      try {
        final payload = _tokenService.decodeToken(accessToken);
        if (payload != null && payload.containsKey('exp')) {
          final expTimestamp = payload['exp'];
          if (expTimestamp is int) {
            final expDate = DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);
            final now = DateTime.now();
            final seconds = expDate.difference(now).inSeconds;
            
            if (seconds > 0) {
              expiryInSeconds = seconds;
              debugPrint('ApiClient: Tiempo de expiración extraído del token: $expiryInSeconds segundos');
            } else {
              debugPrint('ApiClient: ADVERTENCIA - Token parece ya expirado');
            }
          }
        }
      } catch (e) {
        debugPrint('ApiClient: Error al decodificar token para extracción de expiración: $e');
      }
      
      // Guardar tokens en el servicio
      await _tokenService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiryInSeconds: expiryInSeconds,
      );
      
      debugPrint('ApiClient: Tokens guardados en TokenService');
    } else if (response.statusCode >= 200 && response.statusCode < 300) {
      // Si la respuesta es exitosa pero no hay tokens, mantener el token actual
      debugPrint('ApiClient: Respuesta exitosa pero sin tokens - Manteniendo token actual');
    }
  }
  
  /// Método para realizar peticiones HTTP autenticadas
  /// 
  /// Este método se asegura de incluir el token de autenticación y manejar automáticamente
  /// la renovación del token si es necesario
  Future<Map<String, dynamic>> authenticatedRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      debugPrint('ApiClient: Solicitud autenticada a $endpoint');
      
      // Usar directamente el método authenticatedRequest del TokenService
      return await _tokenService.authenticatedRequest(
        endpoint: endpoint,
        method: method,
        body: body,
        queryParams: queryParams,
        headers: headers,
      );
    } catch (e) {
      debugPrint('ApiClient: Error en solicitud autenticada: $e');
      rethrow;
    }
  }

  /// Método genérico para realizar peticiones HTTP
  /// 
  /// Este método maneja automáticamente los errores, la serialización y deserialización
  /// de datos, y la renovación del token de autenticación
  Future<Map<String, dynamic>> request({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requiresAuth = false,
    bool refreshOnFailure = true,
  }) async {
    try {
      // Si requiere autenticación, usar el método específico para ello
      if (requiresAuth) {
        return await authenticatedRequest(
          endpoint: endpoint,
          method: method,
          body: body,
          queryParams: queryParams,
        );
      }
      
      // Si no requiere autenticación, continuar con la implementación original
      // Construir la URL completa
      String url = baseUrl + endpoint;
      
      // Añadir parámetros de consulta si existen
      if (queryParams != null && queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url = '$url${url.contains('?') ? '&' : '?'}$queryString';
      }
      
      // Configurar headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
        
      // Realizar la solicitud HTTP
      final response = await _performRequest(
        method: method,
        url: url,
        headers: headers,
        body: body,
      ).timeout(Duration(seconds: _defaultTimeoutSeconds));
      
      // Procesar la respuesta
      return _processResponse(
        response: response,
        endpoint: endpoint,
        method: method,
        body: body,
        queryParams: queryParams,
        requiresAuth: requiresAuth,
        refreshOnFailure: refreshOnFailure,
      );
    } catch (e) {
      // Capturar y convertir excepciones no controladas
      if (e is ApiException) {
        rethrow;
      }
      
      if (e is http.ClientException || e is TimeoutException) {
        throw ApiException(
          statusCode: 0,
          message: 'Error de conexión: $e',
          errorCode: ApiException.errorNetwork,
        );
      }
      
      throw ApiException(
        statusCode: 0,
        message: 'Error en la solicitud: $e',
        errorCode: ApiException.errorUnknown,
      );
    }
  }
  
  /// Realiza la solicitud HTTP según el método indicado
  Future<http.Response> _performRequest({
    required String method,
    required String url,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) async {
    debugPrint('ApiClient: Enviando solicitud $method a $url');
    
    if (body != null) {
      try {
        // Intentar mostrar el cuerpo de forma segura, omitir campos sensibles
        final safeBody = Map<String, dynamic>.from(body);
        if (safeBody.containsKey('clave') || safeBody.containsKey('password')) {
          safeBody['clave'] = '******';
          safeBody['password'] = '******';
        }
        debugPrint('ApiClient: Cuerpo de la solicitud: ${json.encode(safeBody)}');
      } catch (e) {
        debugPrint('ApiClient: No se pudo mostrar el cuerpo de la solicitud: $e');
      }
    }
    
    switch (method.toUpperCase()) {
      case 'GET':
        return await _httpClient.get(Uri.parse(url), headers: headers);
      case 'POST':
        return await _httpClient.post(
          Uri.parse(url),
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
      case 'PUT':
        return await _httpClient.put(
          Uri.parse(url),
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
      case 'PATCH':
        return await _httpClient.patch(
          Uri.parse(url),
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
      case 'DELETE':
        return await _httpClient.delete(
          Uri.parse(url),
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
      default:
        throw ApiException(
          statusCode: 500,
          message: 'Método HTTP no soportado: $method',
        );
    }
  }
  
  /// Procesa la respuesta HTTP y maneja los posibles errores
  Future<Map<String, dynamic>> _processResponse({
    required http.Response response,
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    required bool requiresAuth,
    required bool refreshOnFailure,
  }) async {
    debugPrint('ApiClient: Respuesta recibida con código ${response.statusCode}');
    
    // Verificar respuesta exitosa (código 2xx)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Procesar posible token en encabezados
      if (response.headers['authorization'] != null) {
        final String? authHeader = response.headers['authorization'];
        if (authHeader != null && authHeader.startsWith('Bearer ')) {
          final token = authHeader.substring(7); // Extraer token sin "Bearer "
          debugPrint('ApiClient: Token encontrado en encabezado de respuesta');
          
          await _tokenService.saveTokens(
            accessToken: token,
          );
        }
      }
      
      // Respuesta vacía
      if (response.body.isEmpty) {
        debugPrint('ApiClient: Respuesta vacía');
        return {'status': 'success'};
      }
      
      try {
        // Decodificar respuesta JSON
        final decodedResponse = json.decode(response.body) as Map<String, dynamic>;
        
        // Procesar token de la respuesta
        await _processTokenFromResponse(response, decodedResponse);
        
        return decodedResponse;
      } catch (e) {
        debugPrint('ApiClient: Error al decodificar respuesta JSON: $e');
        debugPrint('ApiClient: Cuerpo de la respuesta: ${response.body}');
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Error al decodificar respuesta JSON: $e',
        );
      }
    }
    
    // Manejo de error 401 (No autorizado) con refresco de token
    if (response.statusCode == 401 && refreshOnFailure) {
      debugPrint('ApiClient: Token rechazado (401), intentando renovar...');
      
      try {
        // Intentar refrescar el token
        await _refreshTokenRequest();
        
        // Si el token se refrescó exitosamente, reintentar la solicitud original
        debugPrint('ApiClient: Token renovado exitosamente, reintentando solicitud original');
        return await request(
          endpoint: endpoint,
          method: method,
          body: body,
          queryParams: queryParams,
          requiresAuth: requiresAuth,
          refreshOnFailure: false, // Evitar bucles infinitos
        );
      } catch (refreshError) {
        debugPrint('ApiClient: Error al renovar token: $refreshError');
        
        // Si no podemos renovar el token, limpiar tokens y lanzar excepción
        await _tokenService.clearTokens();
        
        throw ApiException(
          statusCode: 401,
          message: 'Sesión expirada, inicie sesión nuevamente',
          errorCode: ApiException.errorUnauthorized,
        );
      }
    }
    
    // Para otros errores, crear una excepción genérica
    final errorMessage = _getErrorMessage(response);
    final errorData = _tryParseJson(response.body);
    
    debugPrint('ApiClient: Error en la solicitud - Código: ${response.statusCode}, Mensaje: $errorMessage');
    
    throw ApiException.fromStatusCode(
      response.statusCode,
      errorMessage,
      data: errorData,
    );
  }

  /// Método para refrescar el token de autenticación
  /// 
  /// Delega al TokenService para realizar la operación
  Future<void> _refreshTokenRequest() async {
    debugPrint('ApiClient: Solicitando renovación de token mediante TokenService');
    try {
      // Verificar que el TokenService esté configurado con la URL base
      if (baseUrl.isNotEmpty) {
        // Usar el método authenticatedRequest para llamar al endpoint /auth/refresh
        await authenticatedRequest(
          endpoint: '/auth/refresh',
          method: 'POST',
        );
        
        // Verificar que el token se haya actualizado correctamente
        if (_tokenService.isTokenExpired) {
          throw ApiException(
            statusCode: 401,
            message: 'No se pudo renovar el token de acceso',
            errorCode: ApiException.errorUnauthorized,
          );
        }
        
        debugPrint('ApiClient: Token renovado correctamente');
      } else {
        throw ApiException(
          statusCode: 500,
          message: 'URL base no configurada en ApiClient',
        );
      }
    } catch (e) {
      debugPrint('ApiClient: Error al renovar token: $e');
      rethrow;
    }
  }
}

// Clase para manejar cookies persistentes entre solicitudes
class PersistentCookieClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> _cookies = {};
  
  PersistentCookieClient() : _inner = http.Client();
  
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Añadir las cookies almacenadas a la solicitud
    if (_cookies.isNotEmpty) {
      final String cookieString = _cookies.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');
      
      request.headers['Cookie'] = cookieString;
      debugPrint('PersistentCookieClient: Enviando cookies: ${_cookies.keys.join(', ')}');
    }
    
    final response = await _inner.send(request);
    
    // Extraer y almacenar cookies de la respuesta
    if (response.headers.containsKey('set-cookie')) {
      final cookiesHeader = response.headers['set-cookie']!;
      _processCookies(cookiesHeader);
    }
    
    return response;
  }
  
  // Extraer y guardar cookies de un header Set-Cookie
  void _processCookies(String cookiesHeader) {
    try {
      final cookieStrings = cookiesHeader.split(',');
      
      for (var cookieString in cookieStrings) {
        // El formato estándar de Set-Cookie es: 
        // name=value; Domain=domain; Path=path; Expires=date; HttpOnly; Secure
        final mainParts = cookieString.split(';');
        if (mainParts.isEmpty) continue;
        
        final nameValuePair = mainParts[0].trim().split('=');
        if (nameValuePair.length != 2) continue;
        
        final name = nameValuePair[0].trim();
        final value = nameValuePair[1].trim();
        
        // Verificar si la cookie fue borrada (valor vacío o "deleted")
        if (value.isEmpty || value == 'deleted' || value == '"deleted"') {
          if (_cookies.containsKey(name)) {
            _cookies.remove(name);
            debugPrint('PersistentCookieClient: Cookie eliminada: $name');
          }
        } else {
          _cookies[name] = value;
          debugPrint('PersistentCookieClient: Cookie guardada: $name=${value.substring(0, math.min(10, value.length))}...');
        }
      }
    } catch (e) {
      debugPrint('PersistentCookieClient: Error al procesar cookies: $e');
    }
  }
  
  // Añadir una cookie manualmente
  void addCookie(String name, String value) {
    _cookies[name] = value;
    debugPrint('PersistentCookieClient: Cookie añadida manualmente: $name');
  }
  
  // Verificar si tenemos una cookie específica
  bool hasCookie(String name) {
    return _cookies.containsKey(name);
  }
  
  // Obtener todas las cookies como un mapa
  Map<String, String> get cookies => Map.unmodifiable(_cookies);
  
  // Cerrar el cliente interno
  @override
  void close() {
    _inner.close();
    super.close();
  }
  
  // Manejar específicamente el refresh token
  void setRefreshToken(String? refreshToken) {
    if (refreshToken == null || refreshToken.isEmpty) {
      _cookies.remove('refresh_token');
      debugPrint('PersistentCookieClient: Refresh token eliminado');
    } else {
      _cookies['refresh_token'] = refreshToken;
      debugPrint('PersistentCookieClient: Refresh token guardado manualmente');
    }
  }
  
  // Obtener el refresh token actual
  String? get refreshToken => _cookies['refresh_token'];
}