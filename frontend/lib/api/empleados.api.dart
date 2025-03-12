import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'main.api.dart';

class EmpleadoApi {
  final ApiService _api;
  final String _endpoint = '/empleados';
  late final Dio _dio;
  
  // Roles válidos según documentación
  static const roles = {
    'ADMINISTRADOR': 'ADMINISTRADOR',
    'COLABORADOR': 'COLABORADOR', 
    'VENDEDOR': 'VENDEDOR',
    'COMPUTADORA': 'COMPUTADORA',
  };

  // Mapa de IDs de roles
  static const roleIds = {
    1: 'ADMINISTRADOR',
    2: 'COLABORADOR',
    3: 'VENDEDOR',
    4: 'COMPUTADORA',
  };

  // Mapa inverso para obtener ID desde rol
  static const rolesToId = {
    'ADMINISTRADOR': 1,
    'COLABORADOR': 2,
    'VENDEDOR': 3,
    'COMPUTADORA': 4,
  };

  // Método para convertir ID a rol
  static String getRoleFromId(int id) {
    return roleIds[id] ?? 'DESCONOCIDO';
  }

  // Método para convertir rol a ID
  static int? getIdFromRole(String role) {
    return rolesToId[role.toUpperCase()];
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
        if (kDebugMode) {
          print('Request URL: ${options.uri}');
          print('Request Method: ${options.method}');
          print('Request Headers: ${options.headers}');
          print('Request Data: ${options.data}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('Response Status: ${response.statusCode}');
          print('Response Headers: ${response.headers}');
          print('Response Data: ${response.data}');
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        if (kDebugMode) {
          print('Error Type: ${e.type}');
          print('Error Message: ${e.message}');
          print('Error Response: ${e.response?.data}');
          print('Error Request: ${e.requestOptions.uri}');
        }

        if (e.type == DioExceptionType.connectionError) {
          throw Exception(
            'Error de conexión: Verifica que el servidor esté corriendo y que CORS esté configurado correctamente. ' 'El servidor debe permitir solicitudes desde http://localhost:51251'
          );
        }
        return handler.next(e);
      },
    ));
  }

  // Login usando Dio
  Future<Map<String, dynamic>> login(String username, String clave) async {
    try {
      if (kDebugMode) {
        print('Intentando login con usuario: $username');
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

      if (kDebugMode) {
        print('Respuesta del servidor: ${response.statusCode}');
        print('Headers: ${response.headers}');
        print('Data: ${response.data}');
      }

      if (response.statusCode != 200 || response.data['status'] != 'success') {
        throw Exception(response.data['error'] ?? 'Error al iniciar sesión');
      }

      final authHeader = response.headers.value('authorization');
      final refreshToken = response.headers.value('refresh-token');
      
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        throw Exception('Token de acceso inválido');
      }

      final token = authHeader.substring(7);
      await _api.setTokens(
        token: token,
        refreshToken: refreshToken,
        expiration: DateTime.now().add(const Duration(minutes: 30)),
      );

      // Convertir el ID de rol a string de rol
      final empleadoData = response.data['data'];
      if (empleadoData != null && empleadoData['rolCuentaEmpleadoId'] != null) {
        empleadoData['rol'] = getRoleFromId(empleadoData['rolCuentaEmpleadoId']);
      }

      return {
        'token': token,
        'refresh_token': refreshToken,
        'empleado': empleadoData,
      };
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error DioException: ${e.type}');
        print('Error Message: ${e.message}');
        print('Error Response: ${e.response?.data}');
        print('Error Headers: ${e.response?.headers}');
      }

      String message;
      switch (e.type) {
        case DioExceptionType.connectionError:
          message = 'Error de conexión: Verifica que el servidor esté corriendo y que CORS esté configurado correctamente';
          break;
        case DioExceptionType.connectionTimeout:
          message = 'Tiempo de espera agotado. Verifica tu conexión a internet y que el servidor esté respondiendo';
          break;
        case DioExceptionType.badResponse:
          message = e.response?.data?['error'] ?? 'Error en la respuesta del servidor';
          break;
        default:
          message = e.message ?? 'Error desconocido';
      }
      throw Exception(message);
    } catch (e) {
      if (kDebugMode) {
        print('Error general: $e');
      }
      throw Exception('Error inesperado durante el login: $e');
    }
  }

  // Obtener empleados con paginación
  Future<Map<String, dynamic>> getEmpleados({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? sortBy,
    bool ascending = true,
  }) async {
    try {
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
        throw Exception(response.data['error'] ?? 'Error al obtener empleados');
      }

      return {
        'data': response.data['data'] as List<dynamic>,
        'pagination': response.data['pagination'] as Map<String, dynamic>,
      };
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al obtener empleados');
    }
  }

  // Obtener un empleado por ID
  Future<Map<String, dynamic>> getEmpleado(int id) async {
    try {
      final response = await _dio.get(
        '$_endpoint/$id',
        options: Options(headers: _api.headers),
      );

      if (response.statusCode != 200 || response.data['status'] != 'success') {
        throw Exception(response.data['error'] ?? 'Error al obtener empleado');
      }

      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al obtener empleado');
    }
  }

  // Crear un nuevo empleado
  Future<Map<String, dynamic>> createEmpleado(Map<String, dynamic> data) async {
    try {
      // Validar datos requeridos
      final requiredFields = ['usuario', 'clave', 'rol', 'nombre', 'apellido'];
      for (final field in requiredFields) {
        if (!data.containsKey(field) || data[field] == null || data[field].toString().isEmpty) {
          throw Exception('El campo $field es requerido');
        }
      }

      // Validar rol
      if (!roles.containsKey(data['rol'])) {
        throw Exception('Rol inválido');
      }

      final response = await _dio.post(
        _endpoint,
        data: data,
        options: Options(headers: _api.headers),
      );

      if (response.statusCode != 201 || response.data['status'] != 'success') {
        throw Exception(response.data['error'] ?? 'Error al crear empleado');
      }

      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al crear empleado');
    }
  }

  // Actualizar un empleado
  Future<Map<String, dynamic>> updateEmpleado(int id, Map<String, dynamic> data) async {
    try {
      // Validar rol si se está actualizando
      if (data.containsKey('rol') && !roles.containsKey(data['rol'])) {
        throw Exception('Rol inválido');
      }

      final response = await _dio.put(
        '$_endpoint/$id',
        data: data,
        options: Options(headers: _api.headers),
      );

      if (response.statusCode != 200 || response.data['status'] != 'success') {
        throw Exception(response.data['error'] ?? 'Error al actualizar empleado');
      }

      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al actualizar empleado');
    }
  }

  // Eliminar un empleado
  Future<void> deleteEmpleado(int id) async {
    try {
      final response = await _dio.delete(
        '$_endpoint/$id',
        options: Options(headers: _api.headers),
      );

      if (response.statusCode != 200 || response.data['status'] != 'success') {
        throw Exception(response.data['error'] ?? 'Error al eliminar empleado');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al eliminar empleado');
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
        throw Exception(response.data['error'] ?? 'Error al cerrar sesión');
      }
    } finally {
      await _api.clearTokens();
    }
  }

  // Cambiar contraseña
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _dio.post(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        options: Options(headers: _api.headers),
      );

      if (response.statusCode != 200 || response.data['status'] != 'success') {
        throw Exception(response.data['error'] ?? 'Error al cambiar contraseña');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Error al cambiar contraseña');
    }
  }
}
