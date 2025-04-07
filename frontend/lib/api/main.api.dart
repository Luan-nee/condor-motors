import 'dart:async';

import 'package:condorsmotors/utils/logger.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? errorCode;
  final dynamic data;

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

  factory ApiException.fromDioError(DioException error) {
    String errorMessage = error.message ?? 'Error desconocido';
    int errorStatusCode = error.response?.statusCode ?? 0;
    late String errorCodeValue;
    final dynamic errorData = error.response?.data;

    switch (error.type) {
      case DioExceptionType.badResponse:
        switch (errorStatusCode) {
          case 400:
            errorCodeValue = errorBadRequest;
            errorMessage =
                _extractErrorMessage(errorData) ?? 'Solicitud inválida';
            break;
          case 401:
          case 403:
            errorCodeValue = errorUnauthorized;
            errorMessage = 'No autorizado';
            break;
          case 404:
            errorCodeValue = errorNotFound;
            errorMessage = 'Recurso no encontrado';
            break;
          case 500:
          case 502:
          case 503:
            errorCodeValue = errorServer;
            errorMessage = 'Error del servidor';
            break;
          default:
            errorCodeValue = errorUnknown;
        }
        break;
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorStatusCode = -1;
        errorCodeValue = errorNetwork;
        errorMessage = 'Tiempo de espera agotado';
        break;
      case DioExceptionType.cancel:
        errorStatusCode = -2;
        errorCodeValue = errorNetwork;
        errorMessage = 'Solicitud cancelada';
        break;
      default:
        errorStatusCode = -3;
        errorCodeValue = errorUnknown;
        errorMessage = 'Error desconocido';
    }

    return ApiException(
      statusCode: errorStatusCode,
      message: errorMessage,
      errorCode: errorCodeValue,
      data: errorData,
    );
  }

  static String? _extractErrorMessage(data) {
    if (data == null) {
      return null;
    }
    if (data is Map<String, dynamic>) {
      return data['error'] ?? data['message'] ?? data['msg'];
    }
    if (data is String) {
      return data;
    }
    return null;
  }

  @override
  String toString() => 'ApiException: $statusCode - $message';
}

class ApiClient {
  final String baseUrl;
  late final Dio _dio;
  bool _isRefreshingToken = false;
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

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
}
