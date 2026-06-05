import 'package:condorsmotors/utils/logger.dart';
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
