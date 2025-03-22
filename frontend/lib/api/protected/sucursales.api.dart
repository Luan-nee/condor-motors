import 'package:flutter/foundation.dart';

import '../../models/sucursal.model.dart';
import '../main.api.dart';

class SucursalesApi {
  final ApiClient _api;
  
  SucursalesApi(this._api);
  
  /// Obtiene los datos específicos de una sucursal
  /// 
  /// Este método obtiene información general sobre una sucursal específica
  Future<Sucursal> getSucursalData(String sucursalId) async {
    try {
      debugPrint('SucursalesApi: Obteniendo datos de sucursal con ID: $sucursalId');
      final response = await _api.authenticatedRequest(
        endpoint: '/sucursales/$sucursalId',
        method: 'GET',
      );
      
      return Sucursal.fromJson(response['data']);
    } catch (e) {
      debugPrint('SucursalesApi: ERROR al obtener datos de sucursal #$sucursalId: $e');
      rethrow;
    }
  }
  
  /// Obtiene todas las sucursales
  Future<List<Sucursal>> getSucursales() async {
    try {
      debugPrint('SucursalesApi: Obteniendo lista de sucursales');
      final response = await _api.authenticatedRequest(
        endpoint: '/sucursales',
        method: 'GET',
      );
      
      debugPrint('SucursalesApi: Respuesta de getSucursales recibida');
      
      // Manejar la respuesta y convertir los datos a objetos Sucursal
      final List<dynamic> rawData;
      
      // Manejar estructura anidada si es necesario
      if (response['data'] is Map && response['data'].containsKey('data')) {
        rawData = response['data']['data'] ?? [];
      } else {
        rawData = response['data'] ?? [];
      }
      
      // Convertir cada elemento en un objeto Sucursal
      return rawData.map((item) => Sucursal.fromJson(item)).toList();
    } catch (e) {
      debugPrint('SucursalesApi: ERROR al obtener sucursales: $e');
      rethrow;
    }
  }
  
  // PROFORMAS DE VENTA
  
  /// Obtiene todas las proformas de venta de la sucursal
  Future<List<dynamic>> getProformasVenta(String sucursalId) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa',
        method: 'GET',
      );
      
      return response['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Crea una nueva proforma de venta
  Future<Map<String, dynamic>> createProformaVenta(String sucursalId, Map<String, dynamic> proformaData) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa',
        method: 'POST',
        body: proformaData,
      );
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Actualiza una proforma de venta existente
  Future<Map<String, dynamic>> updateProformaVenta(String sucursalId, String proformaId, Map<String, dynamic> proformaData) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa/$proformaId',
        method: 'PATCH',
        body: proformaData,
      );
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Elimina una proforma de venta
  Future<void> deleteProformaVenta(String sucursalId, String proformaId) async {
    try {
      await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa/$proformaId',
        method: 'DELETE',
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // NOTIFICACIONES
  
  /// Obtiene todas las notificaciones de la sucursal
  Future<List<dynamic>> getNotificaciones(String sucursalId) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/notificaciones',
        method: 'GET',
      );
      
      return response['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Elimina una notificación
  Future<void> deleteNotificacion(String sucursalId, String notificacionId) async {
    try {
      await _api.authenticatedRequest(
        endpoint: '/$sucursalId/notificaciones/$notificacionId',
        method: 'DELETE',
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // SUCURSALES (operaciones generales)
  
  /// Obtiene todas las sucursales
  Future<List<Sucursal>> getAllSucursales() async {
    try {
      debugPrint('SucursalesApi: Obteniendo todas las sucursales');
      final response = await _api.authenticatedRequest(
        endpoint: '/sucursales',
        method: 'GET',
      );
      
      // Convertir la respuesta en una lista de objetos Sucursal
      final List<dynamic> rawData = response['data'] ?? [];
      return rawData.map((item) => Sucursal.fromJson(item)).toList();
    } catch (e) {
      debugPrint('SucursalesApi: ERROR al obtener todas las sucursales: $e');
      rethrow;
    }
  }
  
  /// Crea una nueva sucursal
  Future<Sucursal> createSucursal(Map<String, dynamic> sucursalData) async {
    try {
      debugPrint('SucursalesApi: Creando nueva sucursal: ${sucursalData['nombre']}');
      final response = await _api.authenticatedRequest(
        endpoint: '/sucursales',
        method: 'POST',
        body: sucursalData,
      );
      
      debugPrint('SucursalesApi: Respuesta de createSucursal recibida');
      
      // Convertir la respuesta en un objeto Sucursal
      return Sucursal.fromJson(response['data']);
    } catch (e) {
      debugPrint('SucursalesApi: ERROR al crear sucursal: $e');
      rethrow;
    }
  }
  
  /// Actualiza una sucursal existente
  Future<Sucursal> updateSucursal(String sucursalId, Map<String, dynamic> sucursalData) async {
    try {
      debugPrint('SucursalesApi: Actualizando sucursal con ID: $sucursalId');
      final response = await _api.authenticatedRequest(
        endpoint: '/sucursales/$sucursalId',
        method: 'PATCH',
        body: sucursalData,
      );
      
      debugPrint('SucursalesApi: Respuesta de updateSucursal recibida');
      
      // Convertir la respuesta en un objeto Sucursal
      return Sucursal.fromJson(response['data']);
    } catch (e) {
      debugPrint('SucursalesApi: ERROR al actualizar sucursal #$sucursalId: $e');
      rethrow;
    }
  }

  /// Elimina una sucursal
  Future<void> deleteSucursal(String sucursalId) async {
    try {
      debugPrint('SucursalesApi: Eliminando sucursal con ID: $sucursalId');
      await _api.authenticatedRequest(
        endpoint: '/sucursales/$sucursalId',
        method: 'DELETE',
      );
      
      debugPrint('SucursalesApi: Sucursal eliminada correctamente');
    } catch (e) {
      debugPrint('SucursalesApi: ERROR al eliminar sucursal #$sucursalId: $e');
      rethrow;
    }
  }
} 