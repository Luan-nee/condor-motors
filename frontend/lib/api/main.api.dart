import 'dart:async';

import 'package:condorsmotors/utils/logger.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? errorCode;
  final dynamic data;
  final String? redirect;

  // Códigos de error alineados con el servidor
  static const String errorUnauthorized = 'unauthorized';
  static const String errorNotFound = 'not_found';
  static const String errorBadRequest = 'bad_request';
  static const String errorServer = 'server_error';
  static const String errorNetwork = 'network_error';
  static const String errorUnknown = 'unknown_error';
  static const String errorConnectionFailed = 'connection_failed';
  static const String errorConflict = 'conflict';
  static const String errorUnprocessable = 'unprocessable_entity';
  static const String errorTooManyRequests = 'too_many_requests';
  static const String errorNotImplemented = 'not_implemented';
  static const String errorBadGateway = 'bad_gateway';
  static const String errorServiceUnavailable = 'service_unavailable';

  // Estados de respuesta del servidor
  static const String statusSuccess = 'success';
  static const String statusFail = 'fail';
  static const String statusError = 'error';

  // Mensajes de error específicos del servidor
  static const String invalidTokenMessage =
      'Invalid or missing authorization token';

  ApiException({
    required this.statusCode,
    required this.message,
    this.errorCode,
    this.data,
    this.redirect,
  });

  factory ApiException.fromDioError(DioException error) {
    String errorMessage = error.message ?? 'Error desconocido';
    int errorStatusCode = error.response?.statusCode ?? 0;
    late String errorCodeValue;
    final dynamic errorData = error.response?.data;
    String? redirectUrl;

    // Extraer mensaje y redirección si existe en la respuesta
    if (errorData != null && errorData is Map<String, dynamic>) {
      final String? serverMessage = errorData['error']?.toString();
      if (serverMessage != null && serverMessage.isNotEmpty) {
        errorMessage = serverMessage;
      }
      redirectUrl = errorData['redirect']?.toString();
    }

    switch (error.type) {
      case DioExceptionType.badResponse:
        switch (errorStatusCode) {
          case 400:
            errorCodeValue = errorBadRequest;
            errorMessage =
                _extractErrorMessage(errorData) ?? 'Solicitud inválida';
            Logger.error('Error 400 - Bad Request: $errorMessage');
            break;
          case 401:
            errorCodeValue = errorUnauthorized;
            errorMessage = _extractErrorMessage(errorData) ?? 'No autorizado';

            // Verificar si es específicamente un error de token inválido
            if (errorMessage.toLowerCase() ==
                invalidTokenMessage.toLowerCase()) {
              Logger.error(
                  'Error de Autenticación: Token inválido o faltante - Se requiere iniciar sesión');
              errorMessage =
                  'Token inválido o faltante - Se requiere iniciar sesión';
            } else {
              Logger.error('Error 401 - Unauthorized: $errorMessage');
            }
            break;
          case 403:
            errorCodeValue = errorUnauthorized;
            errorMessage = _extractErrorMessage(errorData) ?? 'Acceso denegado';
            Logger.error('Error 403 - Forbidden: $errorMessage');
            break;
          case 404:
            errorCodeValue = errorNotFound;
            errorMessage =
                _extractErrorMessage(errorData) ?? 'Recurso no encontrado';
            Logger.error('Error 404 - Not Found: $errorMessage');
            break;
          case 409:
            errorCodeValue = errorConflict;
            errorMessage = _extractErrorMessage(errorData) ??
                'Conflicto con el estado actual';
            Logger.error('Error 409 - Conflict: $errorMessage');
            break;
          case 422:
            errorCodeValue = errorUnprocessable;
            errorMessage =
                _extractErrorMessage(errorData) ?? 'Entidad no procesable';
            Logger.error('Error 422 - Unprocessable Entity: $errorMessage');
            break;
          case 429:
            errorCodeValue = errorTooManyRequests;
            errorMessage =
                _extractErrorMessage(errorData) ?? 'Demasiadas solicitudes';
            Logger.error('Error 429 - Too Many Requests: $errorMessage');
            break;
          case 500:
            errorCodeValue = errorServer;
            errorMessage =
                _extractErrorMessage(errorData) ?? 'Error interno del servidor';
            Logger.error('Error 500 - Internal Server Error: $errorMessage');
            break;
          case 501:
            errorCodeValue = errorNotImplemented;
            errorMessage = _extractErrorMessage(errorData) ?? 'No implementado';
            Logger.error('Error 501 - Not Implemented: $errorMessage');
            break;
          case 502:
            errorCodeValue = errorBadGateway;
            errorMessage =
                _extractErrorMessage(errorData) ?? 'Error de puerta de enlace';
            Logger.error('Error 502 - Bad Gateway: $errorMessage');
            break;
          case 503:
            errorCodeValue = errorServiceUnavailable;
            errorMessage =
                _extractErrorMessage(errorData) ?? 'Servicio no disponible';
            Logger.error('Error 503 - Service Unavailable: $errorMessage');
            break;
          default:
            errorCodeValue = errorUnknown;
            errorMessage = _extractErrorMessage(errorData) ??
                'Error de respuesta desconocido';
            errorStatusCode = -1;
            Logger.error('Error Desconocido [$errorStatusCode]: $errorMessage');
        }
        break;
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorStatusCode = -2;
        errorCodeValue = errorNetwork;
        errorMessage = 'Tiempo de espera agotado en la conexión';
        Logger.error('Error de Red [-2]: $errorMessage');
        break;
      case DioExceptionType.cancel:
        errorStatusCode = -2;
        errorCodeValue = errorNetwork;
        errorMessage = 'Solicitud cancelada';
        Logger.warn('Solicitud Cancelada [-2]: $errorMessage');
        break;
      case DioExceptionType.connectionError:
        errorStatusCode = -3;
        errorCodeValue = errorConnectionFailed;
        errorMessage = 'Error de conexión: No se pudo conectar al servidor';
        Logger.error('Error de Conexión [-3]: $errorMessage');
        break;
      default:
        errorStatusCode = -4;
        errorCodeValue = errorUnknown;
        errorMessage = 'Error desconocido en la solicitud';
        Logger.error('Error Desconocido [-4]: $errorMessage');
    }

    // Log de datos adicionales si existen
    if (errorData != null) {
      Logger.debug('Datos adicionales del error: $errorData');
    }
    if (redirectUrl != null) {
      Logger.info('URL de redirección: $redirectUrl');
    }

    return ApiException(
      statusCode: errorStatusCode,
      message: errorMessage,
      errorCode: errorCodeValue,
      data: errorData,
      redirect: redirectUrl,
    );
  }

  static String? _extractErrorMessage(data) {
    if (data == null) {
      return null;
    }

    if (data is Map<String, dynamic>) {
      // Intentar obtener el mensaje de error en el formato del servidor
      final String? error = data['error']?.toString();
      final String? message = data['message']?.toString();

      // Si el error es específicamente de token inválido, retornarlo tal cual
      if (error == invalidTokenMessage) {
        return error;
      }

      return error ?? message ?? data['msg']?.toString();
    }

    if (data is String) {
      return data;
    }
    return null;
  }

  @override
  String toString() {
    if (message.toLowerCase() == invalidTokenMessage.toLowerCase()) {
      return 'ApiException: [$statusCode] ${errorCode ?? 'unauthorized'} - Token inválido o faltante';
    }
    return 'ApiException: [$statusCode] ${errorCode ?? 'unknown'} - $message';
  }
}

class ApiClient {
  String baseUrl;
  late final Dio _dio;
  bool _isRefreshingToken = false;
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // Headers por defecto
  final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Cache y estado
  final Map<String, dynamic> _cache = {};

  ApiClient({
    required this.baseUrl,
  }) {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      validateStatus: (int? status) => status != null && status < 500,
      headers: Map<String, String>.from(_defaultHeaders),
    ));

    // Interceptor para logs
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onResponse: _onResponse,
      onError: _onError,
    ));

    // Interceptor para tokens
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onTokenRequest,
      onError: _onTokenError,
    ));
  }

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String method = options.method;
    final String endpoint = options.uri.toString().replaceAll(baseUrl, '');
    logHttp(method, endpoint);

    if (method != 'GET' && options.data != null) {
      final String dataPreview = options.data.toString();
      final String truncated = dataPreview.length > 500
          ? '${dataPreview.substring(0, 500)}...'
          : dataPreview;
      Logger.debug('Request Body: $truncated');
    }

    return handler.next(options);
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    final int statusCode = response.statusCode ?? 0;
    final String method = response.requestOptions.method;
    final String endpoint =
        response.requestOptions.uri.toString().replaceAll(baseUrl, '');

    logHttp(method, endpoint, statusCode);

    if (response.data != null) {
      final String dataPreview = response.data.toString();
      final String truncated = dataPreview.length > 500
          ? '${dataPreview.substring(0, 500)}...'
          : dataPreview;
      Logger.debug('Response: $truncated');
    }

    return handler.next(response);
  }

  void _onError(DioException error, ErrorInterceptorHandler handler) {
    final int statusCode = error.response?.statusCode ?? 0;
    final String method = error.requestOptions.method;
    final String endpoint =
        error.requestOptions.uri.toString().replaceAll(baseUrl, '');

    logHttp(method, endpoint, statusCode);
    Logger.error('API Error: ${error.message}');
    if (error.response?.data != null) {
      Logger.error('Error data: ${error.response?.data}');
    }

    return handler.next(error);
  }

  Future<void> _onTokenRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString(_accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  Future<void> _onTokenError(
      DioException error, ErrorInterceptorHandler handler) async {
    if (error.response?.statusCode == 401 && !_isRefreshingToken) {
      _isRefreshingToken = true;
      try {
        final bool success = await _refreshToken();
        if (success) {
          final RequestOptions opts = error.requestOptions;
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final String? token = prefs.getString(_accessTokenKey);
          if (token != null) {
            opts.headers['Authorization'] = 'Bearer $token';
            final Response response = await _dio.fetch(opts);
            _isRefreshingToken = false;
            return handler.resolve(response);
          }
        }
      } catch (e) {
        Logger.error('Error refreshing token: $e');
      }
      _isRefreshingToken = false;
    }
    return handler.reject(error);
  }

  Future<bool> _refreshToken() async {
    try {
      Logger.info('Renovando token de acceso...');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? refreshToken = prefs.getString(_refreshTokenKey);

      if (refreshToken == null) {
        Logger.error('No hay refresh token disponible');
        return false;
      }

      final Response response = await _dio.post(
        '/auth/refresh',
        options: Options(
          headers: {
            'Cookie': refreshToken,
          },
        ),
      );

      if (response.data != null) {
        final String? newToken = response.headers
                .value('authorization')
                ?.replaceAll('Bearer ', '') ??
            response.data['authorization']
                ?.toString()
                .replaceAll('Bearer ', '');

        if (newToken != null && newToken.isNotEmpty) {
          await prefs.setString(_accessTokenKey, newToken);
          Logger.info('Token renovado exitosamente');
          return true;
        }
      }

      return false;
    } catch (e) {
      Logger.error('Error al renovar token: $e');
      return false;
    }
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
        validateStatus: (status) =>
            true, // Para manejar todos los códigos de estado
      );

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
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, token);
        Logger.debug(
            'Token actualizado desde headers: ${token.substring(0, 10)}...');
      }

      // Procesar refresh token si existe en las cookies
      final String? cookie = response.headers.value('set-cookie');
      if (cookie != null && cookie.isNotEmpty) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(_refreshTokenKey, cookie);
        Logger.debug('Refresh token actualizado desde cookies');
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
        errorCode: ApiException.errorUnknown,
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

  /// Limpia el estado del cliente API
  Future<void> clearState() async {
    try {
      Logger.info('Limpiando estado del cliente API...');

      // Limpiar caché y headers
      _cache.clear();
      _defaultHeaders
        ..clear()
        ..addAll({
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });

      // Cerrar el cliente Dio actual si existe
      _dio.close(force: true);

      // Reinicializar el cliente con la configuración base
      _initializeDio();

      Logger.info('Estado del cliente API limpiado correctamente');
    } catch (e) {
      Logger.error('Error al limpiar estado del cliente API: $e');
      // No relanzar el error ya que no es crítico
    }
  }
}
