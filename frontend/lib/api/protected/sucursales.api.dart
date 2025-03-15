import '../main.api.dart';
import 'package:flutter/foundation.dart';

class SucursalesApi {
  final ApiClient _api;
  
  SucursalesApi(this._api);
  
  /// Obtiene todas las sucursales
  Future<List<dynamic>> getSucursales() async {
    try {
      debugPrint('SucursalesApi: Obteniendo lista de sucursales');
      final response = await _api.request(
        endpoint: '/sucursales',
        method: 'GET',
      );
      
      debugPrint('SucursalesApi: Respuesta de getSucursales recibida');
      return response['data'] ?? [];
    } catch (e) {
      debugPrint('SucursalesApi: ERROR al obtener sucursales: $e');
      rethrow;
    }
  }
  
  /// Obtiene una sucursal por su ID
  /// 
  /// El ID debe ser un string, aunque represente un número
  Future<Map<String, dynamic>> getSucursal(String sucursalId) async {
    try {
      // Validar que sucursalId no sea nulo o vacío
      if (sucursalId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de sucursal no puede estar vacío',
        );
      }
      
      debugPrint('SucursalesApi: Obteniendo sucursal con ID: $sucursalId');
      final response = await _api.request(
        endpoint: '/sucursales/$sucursalId',
        method: 'GET',
      );
      
      debugPrint('SucursalesApi: Respuesta de getSucursal recibida');
      if (response['data'] == null) {
        throw ApiException(
          statusCode: 404,
          message: 'Sucursal no encontrada',
        );
      }
      
      return response['data'];
    } catch (e) {
      debugPrint('SucursalesApi: ERROR al obtener sucursal #$sucursalId: $e');
      rethrow;
    }
  }
  
  /// Crea una nueva sucursal
  Future<Map<String, dynamic>> createSucursal(Map<String, dynamic> sucursalData) async {
    try {
      // Validar datos mínimos requeridos
      if (!sucursalData.containsKey('nombre') || !sucursalData.containsKey('direccion')) {
        throw ApiException(
          statusCode: 400,
          message: 'Datos incompletos para crear sucursal',
        );
      }
      
      debugPrint('SucursalesApi: Creando nueva sucursal: ${sucursalData['nombre']}');
      final response = await _api.request(
        endpoint: '/sucursales',
        method: 'POST',
        body: sucursalData,
      );
      
      debugPrint('SucursalesApi: Respuesta de createSucursal recibida');
      if (response['data'] == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Error al crear sucursal',
        );
      }
      
      return response['data'];
    } catch (e) {
      debugPrint('SucursalesApi: ERROR al crear sucursal: $e');
      rethrow;
    }
  }
  
  /// Actualiza una sucursal existente
  /// 
  /// El ID debe ser un string, aunque represente un número
  Future<Map<String, dynamic>> updateSucursal(String sucursalId, Map<String, dynamic> sucursalData) async {
    try {
      // Validar que sucursalId no sea nulo o vacío
      if (sucursalId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de sucursal no puede estar vacío',
        );
      }
      
      debugPrint('SucursalesApi: Actualizando sucursal con ID: $sucursalId');
      final response = await _api.request(
        endpoint: '/sucursales/$sucursalId',
        method: 'PUT',
        body: sucursalData,
      );
      
      debugPrint('SucursalesApi: Respuesta de updateSucursal recibida');
      if (response['data'] == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Error al actualizar sucursal',
        );
      }
      
      return response['data'];
    } catch (e) {
      debugPrint('SucursalesApi: ERROR al actualizar sucursal #$sucursalId: $e');
      rethrow;
    }
  }
  
  /// Elimina una sucursal
  /// 
  /// El ID debe ser un string, aunque represente un número
  Future<void> deleteSucursal(String sucursalId) async {
    try {
      // Validar que sucursalId no sea nulo o vacío
      if (sucursalId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de sucursal no puede estar vacío',
        );
      }
      
      debugPrint('SucursalesApi: Eliminando sucursal con ID: $sucursalId');
      await _api.request(
        endpoint: '/sucursales/$sucursalId',
        method: 'DELETE',
      );
      
      debugPrint('SucursalesApi: Sucursal eliminada correctamente');
    } catch (e) {
      debugPrint('SucursalesApi: ERROR al eliminar sucursal #$sucursalId: $e');
      rethrow;
    }
  }
  
  /// Obtiene las sucursales activas
  Future<List<dynamic>> getSucursalesActivas() async {
    try {
      debugPrint('SucursalesApi: Obteniendo sucursales activas');
      final response = await _api.request(
        endpoint: '/sucursales/activas',
        method: 'GET',
      );
      
      debugPrint('SucursalesApi: Respuesta de getSucursalesActivas recibida');
      return response['data'] ?? [];
    } catch (e) {
      debugPrint('SucursalesApi: ERROR al obtener sucursales activas: $e');
      rethrow;
    }
  }
}
