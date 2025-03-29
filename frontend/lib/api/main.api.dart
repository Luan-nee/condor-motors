import 'dart:async';

import 'package:condorsmotors/services/token_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
            errorMessage = _extractErrorMessage(errorData) ?? 'Solicitud inválida';
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
  final TokenService _tokenService;
  late final Dio _dio;
  
  ApiClient({
    required this.baseUrl,
    required TokenService tokenService,
  }) : _tokenService = tokenService {
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
    _dio.interceptors.add(LogInterceptor(
      requestBody: kDebugMode,
      responseBody: kDebugMode,
      logPrint: (Object object) => debugPrint('🌐 DIO: $object'),
    ));

    // Interceptor para tokens
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
        final String? token = _tokenService.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, ErrorInterceptorHandler handler) async {
        if (error.response?.statusCode == 401) {
          try {
            await _refreshToken();
            final RequestOptions opts = error.requestOptions;
            final String? token = _tokenService.accessToken;
            opts.headers['Authorization'] = 'Bearer $token';
            final Response response = await _dio.fetch(opts);
            return handler.resolve(response);
          } catch (e) {
            await _tokenService.clearTokens();
            return handler.reject(error);
          }
        }
        return handler.reject(error);
      },
    ));
  }

  Future<void> _refreshToken() async {
    try {
      final Response response = await _dio.post('/auth/refresh');
      if (response.data != null) {
        await _processTokenFromResponse(response);
      } else {
        throw DioException(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          error: 'No se pudo renovar el token',
        );
      }
    } catch (e) {
      debugPrint('❌ Error al renovar token: $e');
      rethrow;
    }
  }

  Future<void> _processTokenFromResponse(Response response) async {
    final data = response.data;
    String? accessToken;
    String? refreshToken;

    if (data != null && data is Map<String, dynamic>) {
      accessToken = _extractToken(data);
      refreshToken = data['refreshToken']?.toString();
    }

    if (accessToken == null) {
      final String? authHeader = response.headers.value('authorization');
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        accessToken = authHeader.substring(7);
      }
    }

    if (accessToken != null) {
      int expiryInSeconds = 3600;
      try {
        final Map<String, dynamic>? payload = _tokenService.decodeToken(accessToken);
        if (payload != null && payload['exp'] != null) {
          final DateTime expDate = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
          expiryInSeconds = expDate.difference(DateTime.now()).inSeconds;
        }
      } catch (e) {
        debugPrint('⚠️ Error al decodificar token: $e');
      }

      await _tokenService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiryInSeconds: expiryInSeconds,
      );
    }
  }

  String? _extractToken(Map<String, dynamic> data) {
    final List<String> tokenKeys = <String>['token', 'access_token', 'accessToken'];
    
    for (final String key in tokenKeys) {
      if (data[key] != null) {
        return data[key].toString();
      }
    }
    
    if (data['data'] is Map<String, dynamic>) {
      final Map<String, dynamic> dataMap = data['data'] as Map<String, dynamic>;
      for (final String key in tokenKeys) {
        if (dataMap[key] != null) {
          return dataMap[key].toString();
        }
      }
    }
    
    return null;
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
      );

      final Response response = await _dio.request(
        endpoint,
        data: body,
        queryParameters: queryParams,
        options: options,
      );

      if (response.data == null) {
        return <String, dynamic>{'status': 'success'};
      }

      if (response.data is Map<String, dynamic>) {
        await _processTokenFromResponse(response);
        return response.data as Map<String, dynamic>;
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