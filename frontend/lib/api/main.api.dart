import 'dart:async';
import 'dart:io'; // Necesario para HttpHeaders
import 'dart:math';

import 'package:condorsmotors/api/index.api.dart' show getCurrentBaseUrl;
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

class ApiClient {
  String baseUrl;
  late Dio _dio;
  final Map<String, dynamic> _cache = {};

  static const _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Singleton global para acceso centralizado
  static late final ApiClient instance;
  static bool _initialized = false;

  /// Inicializa el singleton global. Debe llamarse una sola vez al inicio de la app.
  static void initialize({required String baseUrl}) {
    if (_initialized) {
      return;
    }
    instance = ApiClient(baseUrl: baseUrl);
    _initialized = true;
  }

  ApiClient({required this.baseUrl}) {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio()
      ..options = BaseOptions(
        baseUrl: baseUrl,
        headers: Map<String, String>.from(_defaultHeaders),
        validateStatus: (status) => status != null && status < 300,
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
        final token = await RefreshTokenManager.getAccessToken(
            baseUrl: getCurrentBaseUrl());
        logDebug(
            'Interceptor onRequest: accessToken=${token != null ? token.substring(0, min(10, token.length)) : 'null'}');
        if (token != null) {
          options.headers[HttpHeaders.authorizationHeader] =
              'Bearer $token'; // Usar HttpHeaders.authorizationHeader
          logDebug(
              'Token agregado a la solicitud: ${token.substring(0, min(10, token.length))}...');
        } else {
          logWarning('No se agregó accessToken a la solicitud porque es null');
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final path = error.requestOptions.path;
        final queryParams = error.requestOptions.queryParameters;
        logDebug(
            'Interceptor onError: type=${error.runtimeType}, status=$status, path=$path');
        logDebug('Interceptor onError: responseBody=${error.response?.data}');

        if ((status == 401 || status == 403) &&
            !path.contains('/auth/refresh') &&
            !path.contains('/logout') &&
            queryParams['x-no-retry-on-401'] != 'true') {
          final currentBaseUrl = getCurrentBaseUrl();
          final accessToken =
              await RefreshTokenManager.getAccessToken(baseUrl: currentBaseUrl);
          if (currentBaseUrl.isEmpty) {
            logError(
                'AuthInterceptor: No se puede intentar refresh porque baseUrl es nulo o vacío.');
            return handler.next(error);
          }
          if (accessToken == null) {
            logInfo(
                'AuthInterceptor: No hay access token, no se intenta refresh automático.');
            return handler.next(error);
          }
          Logger.info(
              '🔄 🔄 🔄 ACTIVANDO REFRESH TOKEN AUTOMÁTICO PARA ERROR $status EN $path 🔄 🔄 🔄');

          try {
            final refreshResult =
                await RefreshTokenManager.refreshToken(baseUrl: currentBaseUrl);
            if (!refreshResult) {
              // Si el refresh falla, limpiar tokens y forzar logout
              await RefreshTokenManager.clearAccessToken();
              await RefreshTokenManager.clearRefreshToken();
              // TODO: Forzar logout desde aquí si tienes acceso al contexto
              Logger.error('❌ REFRESH TOKEN FALLÓ. Se eliminaron los tokens.');
              return handler.next(error);
            }
            Logger.info(
                '✅ REFRESH TOKEN EXITOSO - Reintentando solicitud original a $path');

            // Si el refresh fue exitoso, reintenta la petición original
            final newResponse = await _retryRequest(error.requestOptions);
            // Si el backend responde 401 tras el refresh, limpiar tokens y forzar logout
            if (newResponse.statusCode == 401 ||
                newResponse.statusCode == 403) {
              await RefreshTokenManager.clearAccessToken();
              await RefreshTokenManager.clearRefreshToken();
              // TODO: Forzar logout desde aquí si tienes acceso al contexto
              Logger.error(
                  '❌ BACKEND RESPONDIÓ 401/403 TRAS REFRESH. Se eliminaron los tokens.');
              return handler.next(error);
            }
            return handler.resolve(newResponse);
          } catch (e) {
            // Si el refresh falla, el provider hará logout y la UI reaccionará
            Logger.error(
                '❌ ERROR EN REFRESH TOKEN: ${e.toString()}. Se procederá con logout.');
            await RefreshTokenManager.clearAccessToken();
            await RefreshTokenManager.clearRefreshToken();
            // TODO: Forzar logout desde aquí si tienes acceso al contexto
            return handler.next(error);
          }
        } else {
          logDebug(
              'NO entra a la condición de refresh: status=$status, path=$path, x-no-retry-on-401=${queryParams['x-no-retry-on-401']}');
        }
        logInfo(
            'AuthInterceptor: El error no es 401/403 manejable por refresh o es de /auth/refresh/logout. Propagando error. Path: $path');
        return handler.next(error);
      },
    );
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) async {
    // Clonar las opciones y actualizar el token.
    final newOptions = Options(
      method: requestOptions.method,
      headers:
          Map<String, dynamic>.from(requestOptions.headers), // Clonar headers
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      validateStatus: requestOptions.validateStatus,
      receiveTimeout: requestOptions.receiveTimeout,
      sendTimeout: requestOptions.sendTimeout,
      extra: requestOptions.extra,
    );

    final newAccessToken =
        await RefreshTokenManager.getAccessToken(baseUrl: baseUrl);
    if (newAccessToken != null) {
      newOptions.headers![HttpHeaders.authorizationHeader] =
          'Bearer $newAccessToken';
    } else {
      // Esto no debería suceder si refreshToken() fue exitoso, pero como salvaguarda:
      logError(
          'RetryRequest: No se pudo obtener el nuevo access token para el reintento.');
      // Se podría lanzar un error aquí o proceder sin token, lo que probablemente fallará.
      // Por ahora, se procede, y si falla, el ciclo no debería repetirse si el path es el mismo.
    }

    logInfo(
        'RetryRequest: Reintentando solicitud a ${requestOptions.path} con nuevo token.');
    // Usar el cliente _dio principal para el reintento, ya que los interceptores (como el de log) aún son útiles.
    // El interceptor de Auth no debería causar un bucle aquí si el token es ahora válido.
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      cancelToken: requestOptions.cancelToken,
      onReceiveProgress: requestOptions.onReceiveProgress,
      onSendProgress: requestOptions.onSendProgress,
      options: newOptions,
    );
  }

  // Helper function para parsear el valor del refresh_token desde la cabecera set-cookie
  String? _parseRefreshTokenFromSetCookieHeader(String? setCookieValue) {
    if (setCookieValue == null || setCookieValue.isEmpty) {
      return null;
    }
    // Buscamos "refresh_token=valor"
    final parts = setCookieValue.split(';');
    for (final part in parts) {
      final keyValue = part.trim().split('=');
      if (keyValue.length == 2) {
        final key = keyValue[0].trim();
        final value = keyValue[1].trim();
        if (key == TokenConstants.refreshTokenKey) {
          // refreshTokenKey es 'refresh_token'
          // Asegurarse de que el valor no esté vacío
          return value.isNotEmpty ? value : null;
        }
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> request({
    required String endpoint,
    required String method,
    Object? body,
    Map<String, String>? queryParams,
    bool requiresAuth = false,
  }) async {
    try {
      final Options options = Options(
        method: method,
        headers: Map<String, String>.from(_defaultHeaders),
      );

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

      // Procesar token de autorización (access_token) si existe en los headers de la respuesta
      final String? authHeader = response.headers.value('authorization');
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        final String token = authHeader.substring(7);
        // En lugar de guardarlo directamente, usar TokenManager si centraliza la lógica de tokens
        await RefreshTokenManager.setAccessToken(
            baseUrl: baseUrl, token: token);
        logDebug(
            'Access token actualizado desde headers de respuesta: ${token.substring(0, min(10, token.length))}...');
      }

      // Procesar refresh token si existe en las cookies de la respuesta
      // Dio devuelve los headers 'set-cookie' como una lista si hay múltiples.
      final List<String>? setCookieValues =
          response.headers[HttpHeaders.setCookieHeader];
      if (setCookieValues != null && setCookieValues.isNotEmpty) {
        for (final setCookieValue in setCookieValues) {
          final String? parsedRefreshToken =
              _parseRefreshTokenFromSetCookieHeader(setCookieValue);
          if (parsedRefreshToken != null) {
            await SecureStorageUtils.write(
                TokenConstants.refreshTokenKey, parsedRefreshToken);
            logDebug(
                'Refresh token (${TokenConstants.refreshTokenKey}) actualizado desde set-cookie header: ${parsedRefreshToken.substring(0, min(10, parsedRefreshToken.length))}...');
            break; // Asumimos que solo hay un refresh_token relevante
          }
        }
      }

      // Procesar la respuesta
      // Nota: con validateStatus global, 401/403 provoca DioException y pasa por interceptor

      if (response.data == null) {
        return <String, dynamic>{'status': 'success'};
      }

      if (response.data is Map<String, dynamic>) {
        final Map<String, dynamic> responseData =
            Map<String, dynamic>.from(response.data);
        return responseData;
      }

      return <String, dynamic>{'data': response.data};
    } on DioException catch (e) {
      // El interceptor debería haber manejado 401/403 y reintentado. Si termina aquí,
      // convertir a excepción de API
      logError(
          'DioException en ApiClient.request: ${e.message}, Tipo: ${e.type}, Endpoint: $endpoint');
      throw ApiException.fromDioError(e);
    } catch (e) {
      logError(
          'Error inesperado en ApiClient.request: $e, Endpoint: $endpoint');
      throw ApiException(
        statusCode: 0, // genérico
        message: 'Error inesperado en la solicitud: $e',
        errorCode: ApiConstants.unknownError,
      );
    }
  }

  Future<Map<String, dynamic>> authenticatedRequest({
    required String endpoint,
    required String method,
    Object? body,
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
      final String? token =
          await RefreshTokenManager.getAccessToken(baseUrl: baseUrl);

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

  /// Refresca el token de acceso usando la clase centralizada.
  /// Retorna true si el refresh fue exitoso, false si falló (por ejemplo, refresh token inválido).
  Future<bool> refreshToken() async {
    return await RefreshTokenManager.refreshToken(baseUrl: baseUrl);
  }
}

// FIX: Métodos de acceso al access token centralizados aquí para compatibilidad con main.api.dart
class RefreshTokenManager {
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessTokenKey = 'access_token';
  static bool _isRefreshing = false;
  static Completer<bool>? _refreshCompleter;

  /// Lee el refresh token desde almacenamiento seguro
  static Future<String?> getRefreshToken() async {
    return await SecureStorageUtils.read(_refreshTokenKey);
  }

  /// Guarda o actualiza el refresh token en almacenamiento seguro
  static Future<void> setRefreshToken(String token) async {
    await SecureStorageUtils.write(_refreshTokenKey, token);
  }

  /// Elimina el refresh token del almacenamiento seguro
  static Future<void> clearRefreshToken() async {
    await SecureStorageUtils.delete(_refreshTokenKey);
  }

  /// Elimina el access token del almacenamiento seguro
  static Future<void> clearAccessToken() async {
    await SecureStorageUtils.delete(_accessTokenKey);
  }

  /// Lee el access token desde almacenamiento seguro
  static Future<String?> getAccessToken({String? baseUrl}) async {
    final token = await SecureStorageUtils.read(_accessTokenKey);
    logDebug('[getAccessToken] Token leído: '
        '${token != null ? token.substring(0, token.length > 10 ? 10 : token.length) : 'null'}');
    return token;
  }

  /// Guarda o actualiza el access token en almacenamiento seguro
  static Future<void> setAccessToken(
      {String? baseUrl, required String token}) async {
    await SecureStorageUtils.write(_accessTokenKey, token);
  }

  /// Refresca el access token usando el refresh token actual
  /// Devuelve true si el refresh fue exitoso, false si falló
  static Future<bool> refreshToken({required String baseUrl}) async {
    if (baseUrl.isEmpty) {
      logError(
          'RefreshTokenManager: baseUrl no puede estar vacío al refrescar el token.');
      return false;
    }
    if (_isRefreshing) {
      // Esperar a que termine el refresh en curso
      return _refreshCompleter?.future ?? false;
    }
    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();
    try {
      final refreshTokenValue = await getRefreshToken();
      if (refreshTokenValue == null || refreshTokenValue.isEmpty) {
        logError('RefreshTokenManager: No hay refresh token disponible.');
        await clearAccessToken();
        await clearRefreshToken();
        _isRefreshing = false;
        _refreshCompleter?.complete(false);
        _refreshCompleter = null;
        return false;
      }
      final Dio dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ));
      final response = await dio.post(
        '/auth/refresh',
        options: Options(
          headers: {
            'Cookie': '$_refreshTokenKey=$refreshTokenValue',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final authHeader = response.headers.value('authorization');
        logDebug(
            '[refreshToken] Header authorization recibido: ${authHeader ?? 'null'}');
        if (authHeader != null && authHeader.startsWith('Bearer ')) {
          final newAccessToken = authHeader.substring(7);
          logDebug('[refreshToken] Nuevo access token extraído: '
              '${newAccessToken.substring(0, newAccessToken.length > 10 ? 10 : newAccessToken.length)}');
          if (newAccessToken.isNotEmpty) {
            await setAccessToken(token: newAccessToken);
            logDebug('[refreshToken] Nuevo access token guardado.');
            // Leer inmediatamente después de guardar para verificar
            final checkToken = await getAccessToken();
            logDebug('[refreshToken] Token leído tras guardar: '
                '${checkToken != null ? checkToken.substring(0, checkToken.length > 10 ? 10 : checkToken.length) : 'null'}');
            _isRefreshing = false;
            _refreshCompleter?.complete(true);
            _refreshCompleter = null;
            return true;
          }
        }
        logError(
            'RefreshTokenManager: No se pudo extraer el nuevo access token.');
        await clearAccessToken();
        await clearRefreshToken();
        _isRefreshing = false;
        _refreshCompleter?.complete(false);
        _refreshCompleter = null;
        return false;
      } else {
        logError(
            'RefreshTokenManager: Error al refrescar token. Status: ${response.statusCode}');
        await clearAccessToken();
        await clearRefreshToken();
        _isRefreshing = false;
        _refreshCompleter?.complete(false);
        _refreshCompleter = null;
        return false;
      }
    } catch (e) {
      logError('RefreshTokenManager: Excepción durante el refresh', e);
      await clearAccessToken();
      await clearRefreshToken();
      _isRefreshing = false;
      _refreshCompleter?.complete(false);
      _refreshCompleter = null;
      return false;
    }
  }
}
