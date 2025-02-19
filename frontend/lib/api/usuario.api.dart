import 'package:flutter/material.dart';
import './api.service.dart';

class UsuarioApi {
  final ApiService _api;

  UsuarioApi(this._api);

  // Roles válidos según documentación
  static const roles = {
    'ADMINISTRADOR': 'ADMINISTRADOR',
    'COLABORADOR': 'COLABORADOR',
    'VENDEDOR': 'VENDEDOR',
  };

  // Login según documentación
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _api.request(
        endpoint: '/usuarios/login',
        method: 'POST',
        queryParams: const {},
        body: {
          'nombre_usuario': username,
          'contrasena': password,
        },
      );

      // Validar que el usuario esté activo según documentación
      if (response['activo'] != 1) {
        throw ApiException(
          statusCode: 403,
          message: 'Usuario inactivo. Contacta al administrador.',
        );
      }

      return response;
    } catch (e) {
      debugPrint('Error en login: $e');
      rethrow;
    }
  }

  // Crear usuario según documentación
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      // Validar campos requeridos
      final requiredFields = [
        'nombre_usuario',
        'nombre_completo',
        'rol',
        'lugar',
        'fecha_pago',
        'contrasena'
      ];

      for (var field in requiredFields) {
        if (!userData.containsKey(field)) {
          throw Exception('Campo requerido faltante: $field');
        }
      }

      // Validar rol
      if (!roles.containsKey(userData['rol'])) {
        throw Exception('Rol inválido. Debe ser: ADMINISTRADOR, COLABORADOR o VENDEDOR');
      }

      return await _api.request(
        endpoint: '/usuarios',
        method: 'POST',
        queryParams: const {},
        body: userData,
      );
    } catch (e) {
      debugPrint('Error al crear usuario: $e');
      rethrow;
    }
  }

  // Obtener usuarios con paginación
  Future<List<Map<String, dynamic>>> getUsers({int skip = 0, int limit = 100}) async {
    try {
      final response = await _api.request(
        endpoint: '/usuarios',
        method: 'GET',
        queryParams: {
          'saltar': skip.toString(),
          'limite': limit.toString(),
        },
      );

      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      throw Exception('Formato de respuesta inválido');
    } catch (e) {
      debugPrint('Error al obtener usuarios: $e');
      rethrow;
    }
  }

  // Obtener usuario específico
  Future<Map<String, dynamic>> getUser(int userId) async {
    try {
      return await _api.request(
        endpoint: '/usuarios/$userId',
        method: 'GET',
        queryParams: const {},
      );
    } catch (e) {
      debugPrint('Error al obtener usuario: $e');
      rethrow;
    }
  }

  // Actualizar usuario
  Future<Map<String, dynamic>> updateUser(int userId, Map<String, dynamic> userData) async {
    try {
      return await _api.request(
        endpoint: '/usuarios/$userId',
        method: 'PUT',
        queryParams: const {},
        body: userData,
      );
    } catch (e) {
      debugPrint('Error al actualizar usuario: $e');
      rethrow;
    }
  }

  // Método para verificar si el servidor está respondiendo
  Future<bool> testConnection() async {
    try {
      final response = await _api.request(
        endpoint: '/health',
        method: 'GET',
        queryParams: const {},
      );
      
      return response is bool && response;
    } catch (e) {
      debugPrint('Error en test de conexión: $e');
      return false;
    }
  }
}
