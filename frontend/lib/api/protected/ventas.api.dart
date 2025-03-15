import 'package:flutter/foundation.dart';
import '../main.api.dart';

class VentasApi {
  final ApiClient _api;
  final String _endpoint = '/ventas';
  
  VentasApi(this._api);
  
  // Listar ventas con paginación y filtros
  Future<Map<String, dynamic>> getVentas({
    int page = 1,
    int pageSize = 10,
    String? search,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? sucursalId,
    String? estado,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      if (fechaInicio != null) {
        queryParams['fecha_inicio'] = fechaInicio.toIso8601String();
      }
      
      if (fechaFin != null) {
        queryParams['fecha_fin'] = fechaFin.toIso8601String();
      }
      
      if (sucursalId != null) {
        queryParams['sucursal_id'] = sucursalId;
      }
      
      if (estado != null && estado.isNotEmpty) {
        queryParams['estado'] = estado;
      }
      
      final response = await _api.request(
        endpoint: _endpoint,
        method: 'GET',
        queryParams: queryParams,
      );
      
      return response;
    } catch (e) {
      debugPrint('Error al obtener ventas: $e');
      rethrow;
    }
  }
  
  // Obtener una venta específica
  Future<Map<String, dynamic>> getVenta(String id) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint/$id',
        method: 'GET',
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al obtener venta: $e');
      rethrow;
    }
  }
  
  // Crear una nueva venta
  Future<Map<String, dynamic>> createVenta(Map<String, dynamic> ventaData) async {
    try {
      final response = await _api.request(
        endpoint: _endpoint,
        method: 'POST',
        body: ventaData,
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al crear venta: $e');
      rethrow;
    }
  }
  
  // Actualizar una venta existente
  Future<Map<String, dynamic>> updateVenta(String id, Map<String, dynamic> ventaData) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint/$id',
        method: 'PUT',
        body: ventaData,
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al actualizar venta: $e');
      rethrow;
    }
  }
  
  // Cancelar una venta
  Future<bool> cancelarVenta(String id, String motivo) async {
    try {
      await _api.request(
        endpoint: '$_endpoint/$id/cancel',
        method: 'POST',
        body: {
          'motivo': motivo
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error al cancelar venta: $e');
      return false;
    }
  }
  
  // Anular una venta
  Future<bool> anularVenta(String id, String motivo, {String? sucursalId}) async {
    try {
      final queryParams = <String, String>{};
      if (sucursalId != null) {
        queryParams['sucursal_id'] = sucursalId;
      }
      
      await _api.request(
        endpoint: '$_endpoint/$id/anular',
        method: 'POST',
        body: {
          'motivo': motivo,
          'fecha_anulacion': DateTime.now().toIso8601String(),
          if (sucursalId != null) 'sucursal_id': sucursalId,
        },
        queryParams: queryParams,
      );
      return true;
    } catch (e) {
      debugPrint('Error al anular venta: $e');
      return false;
    }
  }
  
  // Obtener estadísticas
  Future<Map<String, dynamic>> getEstadisticas({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? sucursal,
    String? sucursalId,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (fechaInicio != null) {
        queryParams['fecha_inicio'] = fechaInicio.toIso8601String();
      }
      
      if (fechaFin != null) {
        queryParams['fecha_fin'] = fechaFin.toIso8601String();
      }
      
      if (sucursal != null) {
        queryParams['sucursal'] = sucursal;
      }
      
      if (sucursalId != null) {
        queryParams['sucursal_id'] = sucursalId;
      }
      
      final response = await _api.request(
        endpoint: '$_endpoint/estadisticas',
        method: 'GET',
        queryParams: queryParams,
      );
      
      if (response == null) {
        return {};
      }
      
      return response;
    } catch (e) {
      debugPrint('Error al obtener estadísticas: $e');
      return {};
    }
  }
}