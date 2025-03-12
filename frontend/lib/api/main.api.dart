// ignore_for_file: unused_element
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

// Definición de la clase ApiException
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException: $message (Status Code: $statusCode)';
}

class ApiService {
  final String baseUrl;
  bool _initialized = false;
  bool _isOnline = false;
  final _logger = Logger('ApiService');
  String? _authToken;
  String? _refreshToken;
  DateTime? _tokenExpiration;
  late final Dio _dio;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal({
    this.baseUrl = 'http://localhost:3000/api', // Para Web
    // this.baseUrl = 'http://10.0.2.2:3000/api', // Para Android Emulator
    // this.baseUrl = 'http://127.0.0.1:3000/api', // Para iOS Simulator
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      contentType: 'application/json',
      responseType: ResponseType.json,
      validateStatus: (status) => true,
      receiveDataWhenStatusError: true,
      followRedirects: true,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      extra: {
        'withCredentials': true
      },
    ));

    // Agregar interceptor para debugging
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: true,
        responseHeader: true,
        request: true,
      ));
    }

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Debug log
        if (kDebugMode) {
          print('Request URL: ${options.uri}');
          print('Request Method: ${options.method}');
          print('Request Headers: ${options.headers}');
          print('Request Data: ${options.data}');
        }
        
        // Asegurar que el Content-Type esté establecido para POST/PUT
        if (options.method != 'GET') {
          options.headers['Content-Type'] = 'application/json';
        }
        
        // Agregar token de autorización si existe
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('Response Status: ${response.statusCode}');
          print('Response Headers: ${response.headers}');
          print('Response Data: ${response.data}');
        }

        // Verificar si hay headers de autorización
        final authHeader = response.headers.value('authorization');
        if (authHeader != null && authHeader.startsWith('Bearer ')) {
          _authToken = authHeader.substring(7);
        }

        final refreshTokenHeader = response.headers.value('refresh-token');
        if (refreshTokenHeader != null) {
          _refreshToken = refreshTokenHeader;
        }

        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (kDebugMode) {
          print('Error Type: ${e.type}');
          print('Error Message: ${e.message}');
          print('Error Response: ${e.response?.data}');
          print('Error Headers: ${e.response?.headers}');
        }

        // Manejar errores según la documentación
        if (e.response?.statusCode == 401 && e.requestOptions.path != '/auth/login') {
          // Intentar refrescar el token
          if (await refreshAccessToken()) {
            // Reintentar la petición original con el nuevo token
            final opts = e.requestOptions;
            opts.headers['Authorization'] = 'Bearer $_authToken';
            try {
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            } catch (retryError) {
              return handler.reject(retryError as DioException);
            }
          } else {
            // Si no se puede refrescar el token, limpiar la sesión
            await clearTokens();
            throw ApiException(
              statusCode: 401,
              message: 'Sesión expirada. Por favor, inicie sesión nuevamente.',
            );
          }
        }

        // Manejar otros errores según la documentación
        String message;
        switch (e.response?.statusCode) {
          case 400:
            message = e.response?.data?['error'] ?? 'Solicitud inválida';
            break;
          case 403:
            message = 'Acceso denegado';
            break;
          case 404:
            message = 'Recurso no encontrado';
            break;
          case 429:
            message = 'Demasiadas solicitudes. Intente más tarde';
            break;
          case 500:
            message = 'Error interno del servidor';
            break;
          default:
            if (e.type == DioExceptionType.connectionError) {
              message = 'No se pudo conectar al servidor. Verifica que el servidor esté corriendo y que CORS esté configurado correctamente.';
            } else {
              message = e.message ?? 'Error desconocido';
            }
        }
        
        throw ApiException(
          statusCode: e.response?.statusCode ?? 500,
          message: message,
        );
      },
    ));
  }

  // Getters para acceder a propiedades
  Map<String, String> get headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  bool get isInitialized => _initialized;
  bool get isAuthenticated => _authToken != null;

  bool get isOnline => _isOnline;
  String? get token => _authToken;
  String? get refreshToken => _refreshToken;

  // Inicializar el servicio
  Future<void> init() async {
    if (_initialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
      _refreshToken = prefs.getString('refresh_token');
      final expirationStr = prefs.getString('token_expiration');
      if (expirationStr != null) {
        _tokenExpiration = DateTime.parse(expirationStr);
      }
      
      _initialized = true;
      _isOnline = true;
    } catch (e) {
      _logger.severe('Error al inicializar ApiService: $e');
      rethrow;
    }
  }

  // Guardar tokens
  Future<void> setTokens({
    required String token,
    String? refreshToken,
    required DateTime expiration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      if (refreshToken != null) {
        await prefs.setString('refresh_token', refreshToken);
      }
      await prefs.setString('token_expiration', expiration.toIso8601String());
      
      _authToken = token;
      _refreshToken = refreshToken;
      _tokenExpiration = expiration;
    } catch (e) {
      _logger.severe('Error al guardar tokens: $e');
      rethrow;
    }
  }

  // Limpiar tokens
  Future<void> clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('refresh_token');
      await prefs.remove('token_expiration');
      
      _authToken = null;
      _refreshToken = null;
      _tokenExpiration = null;
    } catch (e) {
      _logger.severe('Error al limpiar tokens: $e');
      rethrow;
    }
  }

  // Verificar si el token necesita ser refrescado
  bool _needsTokenRefresh() {
    if (_tokenExpiration == null || _refreshToken == null) return false;
    // Refrescar si faltan menos de 5 minutos para que expire
    return _tokenExpiration!.difference(DateTime.now()).inMinutes < 5;
  }

  // Refrescar token de acceso
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;
    
    try {
      final response = await _dio.post(
        '/auth/refresh',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_refreshToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final newToken = response.headers['authorization']?.first;
        if (newToken?.startsWith('Bearer ') == true) {
          final token = newToken!.substring(7);
          await setTokens(
            token: token,
            refreshToken: _refreshToken, // Mantener el mismo refresh token
            expiration: DateTime.now().add(const Duration(minutes: 30)),
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      _logger.warning('Error al refrescar token: $e');
      return false;
    }
  }

  // Método genérico para realizar peticiones
  Future<dynamic> request({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      if (requiresAuth && _needsTokenRefresh()) {
        final refreshed = await refreshAccessToken();
        if (!refreshed) {
          throw ApiException(
            statusCode: 401,
            message: 'Sesión expirada. Por favor, inicie sesión nuevamente.',
          );
        }
      }

      final response = await _dio.request(
        endpoint,
        options: Options(
          method: method,
          headers: requiresAuth ? headers : null,
        ),
        queryParameters: queryParams,
        data: body != null ? json.encode(body) : null,
      );

      // Manejar respuesta según el formato documentado
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        final responseData = response.data;
        if (responseData['status'] == 'success') {
          return responseData['data'];
        } else {
          throw ApiException(
            statusCode: response.statusCode!,
            message: responseData['error'] ?? 'Error desconocido',
          );
        }
      }

      throw ApiException(
        statusCode: response.statusCode!,
        message: response.data['error'] ?? 'Error en la solicitud',
      );
    } on DioException {
      rethrow;
    }
  }

  // Verificar estado del servidor
  Future<bool> checkApiStatus() async {
    try {
      final response = await _dio.get(
        '/health',
        options: Options(
          validateStatus: (status) => true,
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      
      _isOnline = response.statusCode == 200;
      return _isOnline;
    } catch (e) {
      _isOnline = false;
      return false;
    }
  }
}
