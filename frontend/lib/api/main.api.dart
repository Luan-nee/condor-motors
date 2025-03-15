import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class ApiClient {
  final String baseUrl;
  String? _authToken;
  final http.Client _httpClient = http.Client();
  
  ApiClient({required this.baseUrl});
  
  // Establecer tokens después del login
  void setTokens({required String? token, String? refreshToken}) {
    debugPrint('ApiClient: Configurando token - ${token != null ? 'presente' : 'nulo'}');
    _authToken = token;
  }
  
  // Obtener headers con autenticación
  Map<String, String> get headers {
    final Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }
  
  // Extraer token de las cookies de la respuesta
  String? _extractTokenFromCookies(http.Response response) {
    final cookies = response.headers['set-cookie'];
    if (cookies == null) return null;
    
    debugPrint('ApiClient: Cookies recibidas: $cookies');
    
    // Buscar el token en las cookies (incluir refresh_token)
    final tokenCookie = cookies.split(';').firstWhere(
      (cookie) => cookie.trim().startsWith('token=') || 
                   cookie.trim().startsWith('auth=') || 
                   cookie.trim().startsWith('refresh_token='),
      orElse: () => '',
    );
    
    if (tokenCookie.isEmpty) return null;
    
    // Extraer el valor del token
    final tokenValue = tokenCookie.split('=')[1].trim();
    debugPrint('ApiClient: Token extraído de cookies: ${tokenValue.substring(0, min(10, tokenValue.length))}...');
    
    return tokenValue;
  }
  
  // Extraer token del encabezado Authorization
  String? _extractTokenFromAuthHeader(http.Response response) {
    final authHeader = response.headers['authorization'];
    if (authHeader == null) return null;
    
    debugPrint('ApiClient: Encabezado Authorization recibido: $authHeader');
    
    if (authHeader.startsWith('Bearer ')) {
      final token = authHeader.substring('Bearer '.length);
      debugPrint('ApiClient: Token extraído del encabezado Authorization: ${token.substring(0, min(10, token.length))}...');
      return token;
    }
    
    return null;
  }
  
  // Extraer token de la respuesta (intenta todas las fuentes posibles)
  String? _extractTokenFromResponse(http.Response response) {
    // 1. Intentar extraer del encabezado Authorization
    final authToken = _extractTokenFromAuthHeader(response);
    if (authToken != null) return authToken;
    
    // 2. Intentar extraer de cookies
    final cookieToken = _extractTokenFromCookies(response);
    if (cookieToken != null) return cookieToken;
    
    // 3. Intentar extraer del cuerpo JSON
    try {
      if (response.body.isNotEmpty) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse is Map) {
          // Buscar en ubicaciones comunes
          for (final tokenKey in ['token', 'access_token', 'accessToken']) {
            if (decodedResponse[tokenKey] != null && decodedResponse[tokenKey].toString().isNotEmpty) {
              final token = decodedResponse[tokenKey].toString();
              debugPrint('ApiClient: Token extraído de response["$tokenKey"]: ${token.substring(0, min(10, token.length))}...');
              return token;
            }
          }
          
          // Buscar en data si existe
          if (decodedResponse['data'] != null && decodedResponse['data'] is Map) {
            final dataMap = decodedResponse['data'] as Map;
            for (final tokenKey in ['token', 'access_token', 'accessToken']) {
              if (dataMap[tokenKey] != null && dataMap[tokenKey].toString().isNotEmpty) {
                final token = dataMap[tokenKey].toString();
                debugPrint('ApiClient: Token extraído de response["data"]["$tokenKey"]: ${token.substring(0, min(10, token.length))}...');
                return token;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('ApiClient: Error al extraer token del cuerpo JSON: $e');
    }
    
    return null;
  }
  
  // Guardar token en SharedPreferences
  Future<void> _saveTokenToPrefs(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      debugPrint('ApiClient: Token guardado en SharedPreferences');
    } catch (e) {
      debugPrint('ApiClient: Error al guardar token en SharedPreferences: $e');
    }
  }
  
  // Método genérico para peticiones
  Future<dynamic> request({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams,
    );
    
    debugPrint('ApiClient: Enviando solicitud $method a $uri');
    if (body != null) {
      debugPrint('ApiClient: Cuerpo de la solicitud: ${jsonEncode(body)}');
    }
    debugPrint('ApiClient: Headers: ${headers.toString()}');
    
    http.Response response;
    
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _httpClient.get(uri, headers: headers);
          break;
        case 'POST':
          response = await _httpClient.post(
            uri, 
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PUT':
          response = await _httpClient.put(
            uri, 
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          response = await _httpClient.delete(uri, headers: headers);
          break;
        default:
          throw Exception('Método HTTP no soportado: $method');
      }
      
      debugPrint('ApiClient: Respuesta recibida con código ${response.statusCode}');
      debugPrint('ApiClient: Headers de respuesta: ${response.headers}');
      
      // Intentar extraer token de la respuesta (de cualquier fuente disponible)
      final extractedToken = _extractTokenFromResponse(response);
      if (extractedToken != null) {
        debugPrint('ApiClient: Token encontrado en la respuesta, actualizando...');
        setTokens(token: extractedToken, refreshToken: null);
        _saveTokenToPrefs(extractedToken);
      }
      
      // Verificar respuesta
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          debugPrint('ApiClient: Respuesta vacía');
          return null;
        }
        
        try {
          final decodedResponse = json.decode(response.body);
          debugPrint('ApiClient: Respuesta decodificada: ${decodedResponse.toString()}');
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
      
      // Manejar errores
      final errorMessage = _getErrorMessage(response);
      final errorData = _tryParseJson(response.body);
      
      debugPrint('ApiClient: Error en la solicitud - Código: ${response.statusCode}, Mensaje: $errorMessage');
      if (errorData != null) {
        debugPrint('ApiClient: Datos del error: $errorData');
      }
      
      throw ApiException.fromStatusCode(
        response.statusCode,
        errorMessage,
        data: errorData,
      );
      
    } catch (e) {
      // Manejar errores de red y otros
      if (e is ApiException) {
        rethrow;
      }
      
      debugPrint('ApiClient: Error de red u otro error: $e');
      throw ApiException(
        statusCode: 0,
        message: 'Error de conexión: $e',
        errorCode: ApiException.errorNetwork,
      );
    }
  }
  
  // Métodos auxiliares
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
  
  // Función auxiliar para min
  int min(int a, int b) {
    return a < b ? a : b;
  }
  
  /// Método para peticiones autenticadas con renovación automática de token
  /// 
  /// Este método maneja automáticamente la renovación del token si ha expirado
  Future<dynamic> authenticatedRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool attemptingRefresh = false,
  }) async {
    try {
      // Intenta hacer la solicitud normalmente
      return await request(
        endpoint: endpoint,
        method: method,
        body: body,
        queryParams: queryParams,
      );
    } on ApiException catch (e) {
      // Si es un error de autorización y no estamos ya intentando renovar
      if ((e.statusCode == 401 || e.errorCode == ApiException.errorUnauthorized) && !attemptingRefresh) {
        debugPrint('ApiClient: Token expirado, intentando renovar automáticamente');
        
        try {
          // Intentar renovar el token
          await request(
            endpoint: '/auth/refresh',
            method: 'POST',
          );
          
          debugPrint('ApiClient: Token renovado exitosamente, reintentando solicitud original');
          
          // Reintentar la solicitud original con el nuevo token
          return await request(
            endpoint: endpoint,
            method: method,
            body: body,
            queryParams: queryParams,
          );
        } catch (refreshError) {
          debugPrint('ApiClient: Error al renovar el token: $refreshError');
          // Propagar un error de sesión expirada para que la UI pueda manejarlo
          throw ApiException(
            statusCode: 401,
            message: 'Sesión expirada, inicie sesión nuevamente',
            errorCode: ApiException.errorUnauthorized,
          );
        }
      }
      
      // Propagar el error original si no es un problema de token o no pudimos renovarlo
      rethrow;
    }
  }
}