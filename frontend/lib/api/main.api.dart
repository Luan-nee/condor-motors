import 'dart:async';
import 'dart:math';

import 'package:condorsmotors/utils/logger.dart';
import 'package:condorsmotors/utils/secure_storage_utils.dart';
import 'package:dio/dio.dart';

// Constantes de error y estado
class ApiConstants {
  static const errorCodes = {
    400: 'bad_request',
    401: 'unauthorized',
    403: 'unauthorized',
    404: 'not_found',
    409: 'conflict',
    422: 'unprocessable_entity',
    429: 'too_many_requests',
    500: 'server_error',
    501: 'not_implemented',
    502: 'bad_gateway',
    503: 'service_unavailable',
  };

  static const errorMessages = {
    'bad_request': 'Solicitud inválida',
    'unauthorized': 'No autorizado',
    'not_found': 'Recurso no encontrado',
    'conflict': 'Conflicto con el estado actual',
    'unprocessable_entity': 'Entidad no procesable',
    'too_many_requests': 'Demasiadas solicitudes',
    'server_error': 'Error interno del servidor',
    'not_implemented': 'No implementado',
    'bad_gateway': 'Error de puerta de enlace',
    'service_unavailable': 'Servicio no disponible',
    'network_error': 'Error de red',
    'connection_failed': 'Error de conexión',
    'unknown_error': 'Error inesperado',
  };

  static const String invalidTokenMessage =
      'Invalid or missing authorization token';
  static const String unknownError = 'unknown_error';
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String errorCode;
  final dynamic data;
  final String? redirect;

  ApiException({
    required this.statusCode,
    required this.message,
    required this.errorCode,
    this.data,
    this.redirect,
  });

  factory ApiException.fromDioError(DioException error) {
    final errorStatusCode = error.response?.statusCode ?? 500;
    final errorData = error.response?.data;

    // Si hay un mensaje del servidor, usarlo directamente
    if (errorData is Map<String, dynamic> && errorData['error'] != null) {
      return ApiException(
        statusCode: errorStatusCode,
        message: errorData['error'].toString(),
        errorCode: ApiConstants.errorCodes[errorStatusCode] ??
            ApiConstants.unknownError,
        data: errorData,
        redirect: errorData['redirect']?.toString(),
      );
    }

    // Determinar código de error basado en el tipo de error
    final errorCode = _getErrorCodeFromDioError(error);
    final message = _extractErrorMessage(errorData) ??
        ApiConstants.errorMessages[errorCode] ??
        'Error inesperado';

    Logger.error('${error.type} - $errorCode: $message');

    return ApiException(
      statusCode: errorStatusCode,
      message: message,
      errorCode: errorCode,
      data: errorData,
    );
  }

  static String _getErrorCodeFromDioError(DioException error) {
    if (error.type == DioExceptionType.badResponse) {
      return ApiConstants.errorCodes[error.response?.statusCode] ??
          ApiConstants.unknownError;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'network_error';
      case DioExceptionType.connectionError:
        return 'connection_failed';
      default:
        return ApiConstants.unknownError;
    }
  }

  static String? _extractErrorMessage(data) {
    if (data == null) {
      return null;
    }
    if (data is String) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      return data['error']?.toString() ??
          data['message']?.toString() ??
          data['msg']?.toString();
    }
    return null;
  }

  @override
  String toString() => message;
}

// Constantes para almacenamiento de tokens
class TokenConstants {
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
}

class TokenManager {
  final Dio _dio;
  bool _isRefreshing = false;

  TokenManager(this._dio);

  Future<String?> getAccessToken() async {
    return await SecureStorageUtils.read(TokenConstants.accessTokenKey);
  }

  Future<void> setAccessToken(String token) async {
    await SecureStorageUtils.write(TokenConstants.accessTokenKey, token);
  }

  Future<bool> refreshToken() async {
    if (_isRefreshing) {
      return false;
    }
    _isRefreshing = true;

    try {
      Logger.info('Renovando token de acceso...');
      final refreshToken =
          await SecureStorageUtils.read(TokenConstants.refreshTokenKey);

      if (refreshToken == null) {
        Logger.error('No hay refresh token disponible');
        return false;
      }

      final response = await _dio.post(
        '/auth/refresh',
        options: Options(headers: {'Cookie': refreshToken}),
      );

      final newToken = _extractTokenFromResponse(response);
      if (newToken != null) {
        await setAccessToken(newToken);
        Logger.info('Token renovado exitosamente');
        return true;
      }

      return false;
    } catch (e) {
      Logger.error('Error al renovar token: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  String? _extractTokenFromResponse(Response response) {
    return response.headers.value('authorization')?.replaceAll('Bearer ', '') ??
        response.data?['authorization']?.toString().replaceAll('Bearer ', '');
  }
}

class ApiClient {
  String baseUrl;
  late Dio _dio;
  late TokenManager _tokenManager;
  final Map<String, dynamic> _cache = {};

  static const _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  ApiClient({required this.baseUrl}) {
    _initializeDio();
    _tokenManager = TokenManager(_dio);
  }

  void _initializeDio() {
    _dio = Dio()
      ..options = BaseOptions(
        baseUrl: baseUrl,
        headers: Map<String, String>.from(_defaultHeaders),
        validateStatus: (status) => status != null && status < 500,
        followRedirects: true,
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        connectTimeout: const Duration(seconds: 30),
      )
      ..interceptors.addAll([
        _createLogInterceptor(),
        _createAuthInterceptor(),
      ]);
  }

  Interceptor _createLogInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // Construir URL completa incluyendo query parameters
        String fullUrl = '${options.baseUrl}${options.path}';
        if (options.queryParameters.isNotEmpty) {
          fullUrl +=
              '?${Uri(queryParameters: options.queryParameters.map((key, value) => MapEntry(key, value.toString()))).query}';
        }

        logHttp(
          options.method,
          fullUrl,
        );

        // Añadir logging del cuerpo de la solicitud sin formateo
        if (options.data != null) {
          try {
            if (options.data is Map || options.data is List) {
              // Imprimir JSON sin formato para ahorrar espacio
              logDebug('Request Body: ${options.data}');
            } else {
              logDebug('Request Body: ${options.data}');
            }
          } catch (e) {
            logDebug(
                'Request Body: [No se pudo serializar - ${options.data.runtimeType}]');
          }
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Construir URL completa incluyendo query parameters para la respuesta
        String fullUrl =
            '${response.requestOptions.baseUrl}${response.requestOptions.path}';
        if (response.requestOptions.queryParameters.isNotEmpty) {
          fullUrl +=
              '?${Uri(queryParameters: response.requestOptions.queryParameters.map((key, value) => MapEntry(key, value.toString()))).query}';
        }

        logHttp(
          response.requestOptions.method,
          fullUrl,
          response.statusCode,
        );

        if (response.data != null) {
          try {
            // Si la respuesta es un Map y tiene una lista grande en 'data', resumirla
            if (response.data is Map<String, dynamic> &&
                response.data['data'] is List &&
                (response.data['data'] as List).length > 10) {
              final Map<String, dynamic> logMap =
                  Map<String, dynamic>.from(response.data);
              logMap['data'] = '...';
              logDebug('Response Body (resumido): $logMap');
            } else {
              // Imprimir JSON sin formato para ahorrar espacio
              logDebug('Response Body: ${response.data}');
            }
          } catch (e) {
            logDebug(
                'Response Body: [No se pudo serializar - [1m${response.data.runtimeType}]');
          }
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        logError(
          'Error en solicitud HTTP: ${error.message}',
          error,
          error.stackTrace,
        );

        // Añadir detalles adicionales del error sin formateo
        if (error.response?.data != null) {
          try {
            if (error.response!.data is Map || error.response!.data is List) {
              // Imprimir JSON sin formato para ahorrar espacio
              logDebug('Error Response Body: ${error.response!.data}');
            } else {
              logDebug('Error Response Body: ${error.response!.data}');
            }
          } catch (e) {
            logDebug('Error Response Body: [No se pudo serializar]');
          }
        }

        return handler.next(error);
      },
    );
  }

  Interceptor _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenManager.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          logDebug(
              'Token agregado a la solicitud: ${token.substring(0, 10)}...');
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            await _tokenManager.refreshToken()) {
          logInfo('Token renovado, reintentando solicitud...');
          return handler.resolve(await _retryRequest(error.requestOptions));
        }
        return handler.next(error);
      },
    );
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions options) async {
    final token = await _tokenManager.getAccessToken();
    options.headers['Authorization'] = 'Bearer $token';
    logDebug(
        'Reintentando solicitud con nuevo token: ${token?.substring(0, 10)}...');
    return _dio.fetch(options);
  }

  Future<Map<String, dynamic>> request({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requiresAuth = false,
  }) async {
    try {
      final Options options = Options(
        method: method,
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => true,
      );

      // Log simple de la solicitud sin formateo JSON
      logInfo('Enviando solicitud $method a $endpoint');
      if (body != null) {
        logDebug('Body: $body');
      }
      if (queryParams != null) {
        logDebug('Query Params: $queryParams');
      }

      final Response response = await _dio.request(
        endpoint,
        data: body,
        queryParameters: queryParams,
        options: options,
      );

      // Procesar token de autorización si existe en los headers
      final String? authHeader = response.headers.value('authorization');
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        final String token = authHeader.substring(7);
        await SecureStorageUtils.write(TokenConstants.accessTokenKey, token);
        logDebug(
            'Token actualizado desde headers: [1m${token.substring(0, min(10, token.length))}...');
      }

      // Procesar refresh token si existe en las cookies
      final String? cookie = response.headers.value('set-cookie');
      if (cookie != null && cookie.isNotEmpty) {
        await SecureStorageUtils.write(TokenConstants.refreshTokenKey, cookie);
        logDebug('Refresh token actualizado desde cookies');
      }

      // Procesar la respuesta
      if (response.statusCode == null || response.statusCode! >= 400) {
        throw DioException(
          response: response,
          requestOptions: response.requestOptions,
          error: response.statusMessage,
        );
      }

      if (response.data == null) {
        return <String, dynamic>{'status': 'success'};
      }

      if (response.data is Map<String, dynamic>) {
        // Agregar el token a la respuesta si existe en los headers
        final Map<String, dynamic> responseData =
            Map<String, dynamic>.from(response.data);
        if (authHeader != null) {
          responseData['authorization'] = authHeader;
        }
        if (cookie != null) {
          responseData['cookie'] = cookie;
        }
        return responseData;
      }

      return <String, dynamic>{'data': response.data};
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Error inesperado: $e',
        errorCode: ApiConstants.unknownError,
      );
    }
  }

  Future<Map<String, dynamic>> authenticatedRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    return request(
      endpoint: endpoint,
      method: method,
      body: body,
      queryParams: queryParams,
      requiresAuth: true,
    );
  }

  /// Realiza una solicitud autenticada que devuelve datos binarios como Uint8List
  ///
  /// Útil para descarga de archivos como Excel, PDF, imágenes, etc.
  ///
  /// [endpoint] La ruta relativa del endpoint (sin la baseUrl)
  /// [method] Método HTTP (GET, POST, etc.)
  /// [body] Cuerpo de la solicitud para POST, PUT, PATCH (opcional)
  /// [queryParams] Parámetros de consulta para la URL (opcional)
  /// [responseType] Tipo esperado de respuesta (normalmente 'arraybuffer' o 'blob')
  Future<List<int>> authenticatedRequestRaw({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    String responseType = 'arraybuffer',
  }) async {
    try {
      final String? token = await _tokenManager.getAccessToken();

      final Options options = Options(
        method: method,
        headers: <String, String>{
          'Accept': '*/*', // Aceptar cualquier tipo de contenido
          if (body != null) 'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        responseType:
            ResponseType.bytes, // Importante: indicar que esperamos bytes
        validateStatus: (status) => status != null && status < 500,
      );

      logInfo(
          'Enviando solicitud $method a $endpoint para descarga de archivo');

      final Response<List<int>> response = await _dio.request<List<int>>(
        endpoint,
        data: body,
        queryParameters: queryParams,
        options: options,
      );

      if (response.statusCode != 200 || response.data == null) {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: 'Error al descargar archivo',
          errorCode: ApiConstants.errorCodes[response.statusCode] ??
              ApiConstants.unknownError,
        );
      }

      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Error inesperado: $e',
        errorCode: ApiConstants.unknownError,
      );
    }
  }

  /// Limpia el estado del cliente API
  Future<void> clearState() async {
    try {
      logInfo('Limpiando estado del cliente API...');

      // Limpiar caché
      _cache.clear();

      // Restaurar headers por defecto
      _defaultHeaders
        ..clear()
        ..addAll({
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });

      try {
        // Cerrar el cliente Dio actual y sus conexiones
        _dio.close(force: true);

        // Esperar un momento para asegurar que todas las conexiones se cierren
        await Future.delayed(const Duration(milliseconds: 100));

        // Reinicializar Dio con la configuración limpia
        _initializeDio();
      } catch (dioError) {
        logDebug('Error no crítico al reiniciar cliente Dio: $dioError');
        // Intentar reinicializar Dio incluso si hubo error al cerrar
        _initializeDio();
      }

      logInfo('Estado del cliente API limpiado correctamente');
    } catch (e) {
      logError('Error al limpiar estado del cliente API', e);
      // No relanzar el error ya que no es crítico
    }
  }
}
