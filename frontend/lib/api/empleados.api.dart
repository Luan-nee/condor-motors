import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'main.api.dart';

// Definición de tipos para mejor manejo
typedef EmpleadoData = Map<String, dynamic>;
typedef PaginatedResponse = Map<String, dynamic>;

class EmpleadoApi {
  final ApiService _api;
  final String _endpoint = '/empleados';
  late final Dio _dio;
  
  // Roles válidos según el servidor
  static const roles = {
    'ADMINISTRADOR': 'ADMINISTRADOR',
    'VENDEDOR': 'VENDEDOR',
    'COMPUTADORA': 'COMPUTADORA',
  };

  // Mapa de IDs de roles
  static const roleIds = {
    1: 'ADMINISTRADOR',
    2: 'VENDEDOR',
    3: 'COMPUTADORA',
  };

  // Mapa inverso para obtener ID desde rol
  static const rolesToId = {
    'ADMINISTRADOR': 1,
    'VENDEDOR': 2,
    'COMPUTADORA': 3,
  };

  // Método para convertir ID a rol
  static String getRoleFromId(int id) {
    return roleIds[id] ?? 'DESCONOCIDO';
  }

  // Método para convertir código a rol
  static String getRoleFromCodigo(String codigo) {
    switch (codigo.toLowerCase()) {
      case 'administrador':
      case 'adminstrador': // Manejar el error de tipeo del servidor
        return 'ADMINISTRADOR';
      case 'vendedor':
        return 'VENDEDOR';
      case 'computadora':
        return 'COMPUTADORA';
      default:
        return 'DESCONOCIDO';
    }
  }

  // Método para convertir rol a ID
  static int? getIdFromRole(String role) {
    return rolesToId[role.toUpperCase()];
  }

  // Validación de datos de empleado
  static void validateEmpleadoData(Map<String, dynamic> data, {bool isUpdate = false}) {
    if (!isUpdate) {
      final requiredFields = ['usuario', 'clave', 'rol', 'nombre', 'apellido'];
      for (final field in requiredFields) {
        if (!data.containsKey(field) || data[field] == null || data[field].toString().isEmpty) {
          throw ApiException(
            statusCode: 400,
            message: 'El campo $field es requerido'
          );
        }
      }
    }

    if (data.containsKey('rol') && !roles.containsKey(data['rol'])) {
      throw ApiException(
        statusCode: 400,
        message: 'Rol inválido: ${data['rol']}'
      );
    }

    // Validar formato de email si se proporciona
    if (data.containsKey('email') && data['email'] != null && data['email'].toString().isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(data['email'])) {
        throw ApiException(
          statusCode: 400,
          message: 'Formato de email inválido'
        );
      }
    }
  }

  EmpleadoApi(this._api) {
    _dio = Dio(BaseOptions(
      baseUrl: _api.baseUrl,
      contentType: 'application/json',
      responseType: ResponseType.json,
      validateStatus: (status) => true,
      receiveDataWhenStatusError: true,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      extra: {
        'withCredentials': true,
      },
    ));

    // Configuración de interceptores
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
      print('Request URL: ${options.uri}');
      print('Request Method: ${options.method}');
      print('Request Headers: ${options.headers}');
      print('Request Data: ${options.data}');
    }
    return handler.next(options);
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Data: ${response.data}');
    }
    return handler.next(response);
  }

  void _onError(DioException e, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('Error Type: ${e.type}');
      print('Error Message: ${e.message}');
      print('Error Response: ${e.response?.data}');
      print('Error Request: ${e.requestOptions.uri}');
    }

    if (e.type == DioExceptionType.connectionError) {
      throw ApiException(
        statusCode: 503,
        message: 'Error de conexión: Verifica que el servidor esté corriendo y que CORS esté configurado correctamente'
      );
    }
    return handler.next(e);
  }

  // Login usando Dio
  Future<Map<String, dynamic>> login(String username, String clave) async {
    try {
      if (username.isEmpty || clave.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'Usuario y contraseña son requeridos'
        );
      }

      final response = await _dio.post(
        '/auth/login',
        data: {
          "usuario": username,
          "clave": clave
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => true,
          followRedirects: true,
          extra: {
            'withCredentials': true,
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode != 200 || response.data['status'] != 'success') {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['error'] ?? 'Error al iniciar sesión'
        );
      }

      final authHeader = response.headers.value('authorization');
      final refreshToken = response.headers.value('refresh-token');
      
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        throw ApiException(
          statusCode: 401,
          message: 'Token de acceso inválido'
        );
      }

      final token = authHeader.substring(7);
      await _api.setTokens(
        token: token,
        refreshToken: refreshToken,
        expiration: DateTime.now().add(const Duration(minutes: 30)),
      );

      final empleadoData = response.data['data'];
      if (empleadoData == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Datos de empleado no encontrados en la respuesta'
        );
      }

      // Asegurarnos de que los campos necesarios estén presentes
      if (empleadoData['usuario'] == null || empleadoData['rolCuentaEmpleadoCodigo'] == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Datos de empleado incompletos en la respuesta'
        );
      }

      // Obtener la información de la sucursal del empleado
      try {
        final empleadoResponse = await _dio.get(
          '/empleados/${empleadoData['empleadoId']}',
          options: Options(
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ),
        );

        if (empleadoResponse.statusCode == 200 && empleadoResponse.data['status'] == 'success') {
          final empleadoCompleto = empleadoResponse.data['data'];
          if (empleadoCompleto != null && empleadoCompleto['sucursalId'] != null) {
            empleadoData['sucursalId'] = empleadoCompleto['sucursalId'];
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error al obtener información adicional del empleado: $e');
        }
      }

      return {
        'token': token,
        'refresh_token': refreshToken,
        'empleado': empleadoData,
      };
    } on DioException catch (e) {
      String message;
      switch (e.type) {
        case DioExceptionType.connectionError:
          message = 'Error de conexión: Verifica tu conexión a internet y que el servidor esté disponible';
          break;
        case DioExceptionType.connectionTimeout:
          message = 'Tiempo de espera agotado. Verifica tu conexión a internet';
          break;
        case DioExceptionType.badResponse:
          message = e.response?.data?['error'] ?? 'Error en la respuesta del servidor';
          break;
        default:
          message = e.message ?? 'Error desconocido';
      }
      throw ApiException(
        statusCode: e.response?.statusCode ?? 500,
        message: message
      );
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: 'Error inesperado durante el login: $e'
      );
    }
  }

  // Obtener empleados con paginación
  Future<PaginatedResponse> getEmpleados({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? sortBy,
    bool ascending = true,
  }) async {
    try {
      if (page < 1) throw ApiException(statusCode: 400, message: 'Página inválida');
      if (pageSize < 1) throw ApiException(statusCode: 400, message: 'Tamaño de página inválido');

      final queryParams = {
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (sortBy != null) ...{
          'sort_by': sortBy,
          'order': ascending ? 'asc' : 'desc',
        },
      };

      final response = await _dio.get(
        _endpoint,
        queryParameters: queryParams,
        options: Options(headers: _api.headers),
      );

      if (response.statusCode != 200 || response.data['status'] != 'success') {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['error'] ?? 'Error al obtener empleados'
        );
      }

      return {
        'data': response.data['data'] as List<dynamic>,
        'pagination': response.data['pagination'] as Map<String, dynamic>,
      };
    } on DioException catch (e) {
      throw ApiException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error'] ?? 'Error al obtener empleados'
      );
    }
  }

  // Obtener un empleado por ID
  Future<EmpleadoData> getEmpleado(int id) async {
    try {
      if (id <= 0) throw ApiException(statusCode: 400, message: 'ID de empleado inválido');

      final response = await _dio.get(
        '$_endpoint/$id',
        options: Options(headers: _api.headers),
      );

      if (response.statusCode != 200 || response.data['status'] != 'success') {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['error'] ?? 'Error al obtener empleado'
        );
      }

      return response.data['data'];
    } on DioException catch (e) {
      throw ApiException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error'] ?? 'Error al obtener empleado'
      );
    }
  }

  // Crear un nuevo empleado
  Future<EmpleadoData> createEmpleado(Map<String, dynamic> data) async {
    try {
      validateEmpleadoData(data);

      final response = await _dio.post(
        _endpoint,
        data: data,
        options: Options(headers: _api.headers),
      );

      if (response.statusCode != 201 || response.data['status'] != 'success') {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['error'] ?? 'Error al crear empleado'
        );
      }

      return response.data['data'];
    } on DioException catch (e) {
      throw ApiException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error'] ?? 'Error al crear empleado'
      );
    }
  }

  // Actualizar un empleado
  Future<EmpleadoData> updateEmpleado(int id, Map<String, dynamic> data) async {
    try {
      if (id <= 0) throw ApiException(statusCode: 400, message: 'ID de empleado inválido');
      validateEmpleadoData(data, isUpdate: true);

      final response = await _dio.put(
        '$_endpoint/$id',
        data: data,
        options: Options(headers: _api.headers),
      );

      if (response.statusCode != 200 || response.data['status'] != 'success') {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['error'] ?? 'Error al actualizar empleado'
        );
      }

      return response.data['data'];
    } on DioException catch (e) {
      throw ApiException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error'] ?? 'Error al actualizar empleado'
      );
    }
  }

  // Eliminar un empleado
  Future<void> deleteEmpleado(int id) async {
    try {
      if (id <= 0) throw ApiException(statusCode: 400, message: 'ID de empleado inválido');

      final response = await _dio.delete(
        '$_endpoint/$id',
        options: Options(headers: _api.headers),
      );

      if (response.statusCode != 200 || response.data['status'] != 'success') {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['error'] ?? 'Error al eliminar empleado'
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error'] ?? 'Error al eliminar empleado'
      );
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    try {
      final response = await _dio.post(
        '/auth/logout',
        options: Options(
          headers: _api.headers,
        ),
      );

      if (response.statusCode != 200) {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['error'] ?? 'Error al cerrar sesión'
        );
      }
    } finally {
      await _api.clearTokens();
    }
  }

  // Cambiar contraseña
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      if (currentPassword.isEmpty || newPassword.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'Las contraseñas no pueden estar vacías'
        );
      }

      if (newPassword.length < 6) {
        throw ApiException(
          statusCode: 400,
          message: 'La nueva contraseña debe tener al menos 6 caracteres'
        );
      }

      final response = await _dio.post(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        options: Options(headers: _api.headers),
      );

      if (response.statusCode != 200 || response.data['status'] != 'success') {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['error'] ?? 'Error al cambiar contraseña'
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error'] ?? 'Error al cambiar contraseña'
      );
    }
  }
}
