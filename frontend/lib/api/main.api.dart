// ignore_for_file: unused_element
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

// Definición de la clase ApiException
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;

  ApiException({
    required this.statusCode, 
    required this.message,
    this.data,
  });

  @override
  String toString() => 'ApiException: $message (Status Code: $statusCode)';

  Map<String, dynamic> toJson() => {
    'statusCode': statusCode,
    'message': message,
    'data': data,
  };
}

// Clase para manejar el caché de respuestas
class ApiCache {
  final Map<String, _CacheEntry> _cache = {};
  final Duration defaultExpiration;
  
  ApiCache({this.defaultExpiration = const Duration(minutes: 5)});
  
  void set(String key, dynamic data, {Duration? expiration}) {
    final expiryTime = DateTime.now().add(expiration ?? defaultExpiration);
    _cache[key] = _CacheEntry(data, expiryTime);
  }
  
  dynamic get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (DateTime.now().isAfter(entry.expiryTime)) {
      _cache.remove(key);
      return null;
    }
    
    return entry.data;
  }
  
  bool has(String key) {
    return get(key) != null;
  }
  
  void remove(String key) {
    _cache.remove(key);
  }
  
  void clear() {
    _cache.clear();
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiryTime;
  
  _CacheEntry(this.data, this.expiryTime);
}

class ApiService {
  // Cambiamos la URL base para que funcione desde un dispositivo o emulador
  // Usamos 10.0.2.2 para emuladores Android o la IP de tu máquina para dispositivos físicos
  final String baseUrl;
  bool _initialized = false;
  bool _isOnline = false;
  final _logger = Logger('ApiService');
  String? _authToken;
  String? _refreshToken;
  DateTime? _tokenExpiration;
  late final Dio _dio;
  
  // Agregar caché
  final ApiCache _cache = ApiCache();

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  // Constantes para configuración
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
  static const int maxRetries = 3;

  ApiService._internal({
    String? baseUrl
  }) : baseUrl = baseUrl ?? 
       'http://localhost:3000/api' {
    _initializeDio();
  }

  // Método para cambiar la URL base (útil para configuración)
  void setBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      contentType: 'application/json',
      responseType: ResponseType.json,
      validateStatus: (status) => true,
      receiveDataWhenStatusError: true,
      followRedirects: true,
      connectTimeout: defaultTimeout,
      receiveTimeout: defaultTimeout,
      sendTimeout: defaultTimeout,
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
      onRequest: _onRequest,
      onResponse: _onResponse,
      onError: _onError,
    ));
  }

  // Manejadores de interceptores
  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.fine('Request URL: ${options.uri}');
      _logger.fine('Request Method: ${options.method}');
      _logger.fine('Request Headers: ${options.headers}');
      _logger.fine('Request Data: ${options.data}');
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
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.fine('Response Status: ${response.statusCode}');
      _logger.fine('Response Headers: ${response.headers}');
      _logger.fine('Response Data: ${response.data}');
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
  }

  Future<void> _onError(DioException e, ErrorInterceptorHandler handler) async {
    if (kDebugMode) {
      _logger.warning('Error Type: ${e.type}');
      _logger.warning('Error Message: ${e.message}');
      _logger.warning('Error Response: ${e.response?.data}');
      _logger.warning('Error Headers: ${e.response?.headers}');
    }

    // Manejar errores según la documentación
    if (e.response?.statusCode == 401 && e.requestOptions.path != '/auth/login') {
      try {
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
          return handler.reject(DioException(
            requestOptions: e.requestOptions,
            error: ApiException(
              statusCode: 401,
              message: 'Sesión expirada. Por favor, inicie sesión nuevamente.',
            ),
          ));
        }
      } catch (refreshError) {
        return handler.reject(DioException(
          requestOptions: e.requestOptions,
          error: ApiException(
            statusCode: 401,
            message: 'Error al refrescar la sesión: $refreshError',
          ),
        ));
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
          message = 'No se pudo conectar al servidor. Verifica tu conexión a internet.';
        } else {
          message = e.message ?? 'Error desconocido';
        }
    }
    
    return handler.reject(DioException(
      requestOptions: e.requestOptions,
      error: ApiException(
        statusCode: e.response?.statusCode ?? 500,
        message: message,
        data: e.response?.data,
      ),
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
  
  // Método para obtener información del usuario desde el token
  Map<String, dynamic>? getUserInfo() {
    if (_authToken == null) return null;
    
    try {
      // Decodificar el token JWT (formato: header.payload.signature)
      final parts = _authToken!.split('.');
      if (parts.length != 3) return null;
      
      // Decodificar la parte del payload (segunda parte)
      String normalizedPayload = base64Url.normalize(parts[1]);
      final payloadJson = utf8.decode(base64Url.decode(normalizedPayload));
      final payload = json.decode(payloadJson) as Map<String, dynamic>;
      
      return payload;
    } catch (e) {
      _logger.warning('Error al decodificar token: $e');
      return null;
    }
  }
  
  // Método para obtener el rol del usuario
  String? getUserRole() {
    final userInfo = getUserInfo();
    if (userInfo == null) return null;
    
    // El campo del rol puede variar según la estructura de tu token
    return userInfo['rol'] as String?;
  }

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
      
      // Verificar conectividad inicial
      _isOnline = await checkApiStatus();
      _initialized = true;
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
      if (token.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'Token inválido',
        );
      }

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
    return _tokenExpiration!.difference(DateTime.now()) < tokenRefreshThreshold;
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
            refreshToken: _refreshToken,
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
    int retryCount = 0,
    bool useCache = true,
    Duration? cacheExpiration,
  }) async {
    try {
      if (!_initialized) {
        throw ApiException(
          statusCode: 500,
          message: 'ApiService no está inicializado',
        );
      }

      if (requiresAuth && !isAuthenticated) {
        throw ApiException(
          statusCode: 401,
          message: 'Se requiere autenticación',
        );
      }

      if (requiresAuth && _needsTokenRefresh()) {
        final refreshed = await refreshAccessToken();
        if (!refreshed) {
          throw ApiException(
            statusCode: 401,
            message: 'Sesión expirada. Por favor, inicie sesión nuevamente.',
          );
        }
      }
      
      // Verificar caché para solicitudes GET
      final cacheKey = method == 'GET' ? 
        '$endpoint${queryParams != null ? '?${_mapToQueryString(queryParams)}' : ''}' : 
        null;
      
      if (useCache && method == 'GET' && cacheKey != null) {
        final cachedData = _cache.get(cacheKey);
        if (cachedData != null) {
          return cachedData;
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
          // Guardar en caché si es GET
          if (useCache && method == 'GET' && cacheKey != null) {
            _cache.set(cacheKey, responseData['data'], expiration: cacheExpiration);
          }
          return responseData['data'];
        } else {
          throw ApiException(
            statusCode: response.statusCode!,
            message: responseData['error'] ?? 'Error desconocido',
            data: responseData,
          );
        }
      }

      throw ApiException(
        statusCode: response.statusCode!,
        message: response.data['error'] ?? 'Error en la solicitud',
        data: response.data,
      );
    } on DioException catch (e) {
      // Reintentar en caso de error de conexión
      if (e.type == DioExceptionType.connectionError && retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: math.pow(2, retryCount).toInt()));
        return request(
          endpoint: endpoint,
          method: method,
          body: body,
          queryParams: queryParams,
          requiresAuth: requiresAuth,
          retryCount: retryCount + 1,
          useCache: useCache,
          cacheExpiration: cacheExpiration,
        );
      }
      rethrow;
    }
  }

  // Verificar estado del servidor
  Future<bool> checkApiStatus() async {
    try {
      // En lugar de usar /health, intentamos obtener la primera página de empleados
      // que es un endpoint que sabemos que existe y requiere autenticación
      final response = await _dio.get(
        '/empleados',
        queryParameters: {
          'page': 1,
          'page_size': 1,
        },
        options: Options(
          validateStatus: (status) => true,
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: headers,
        ),
      );
      
      // Si obtenemos 401 o 200, el servidor está funcionando
      _isOnline = response.statusCode == 200 || response.statusCode == 401;
      
      if (_isOnline) {
        _logger.info('Servidor conectado correctamente en ${_dio.options.baseUrl}');
      } else {
        _logger.warning('Servidor respondió con código ${response.statusCode}');
      }
      
      return _isOnline;
    } on DioException catch (e) {
      String errorMessage;
      
      switch (e.type) {
        case DioExceptionType.connectionError:
          errorMessage = 'Error de conexión: No se pudo conectar al servidor en ${_dio.options.baseUrl}';
          break;
        case DioExceptionType.connectionTimeout:
          errorMessage = 'Tiempo de espera agotado al conectar con el servidor';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Tiempo de espera agotado al recibir respuesta del servidor';
          break;
        case DioExceptionType.badResponse:
          errorMessage = 'Respuesta inesperada del servidor: ${e.response?.statusCode}';
          break;
        default:
          errorMessage = 'Error al verificar estado del servidor: ${e.message}';
      }
      
      _logger.warning(errorMessage);
      _isOnline = false;
      return false;
    } catch (e) {
      _logger.warning('Error inesperado al verificar estado del servidor: $e');
      _isOnline = false;
      return false;
    }
  }

  // Método auxiliar para convertir Map a query string
  String _mapToQueryString(Map<String, dynamic> map) {
    return map.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
  }
  
  // Método para invalidar caché
  void invalidateCache(String endpoint) {
    _cache.remove(endpoint);
  }
  
  void clearCache() {
    _cache.clear();
  }
}
