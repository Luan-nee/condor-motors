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
      
      if (estado != null && estado.isNotEmpty) {
        queryParams['estado'] = estado;
      }
      
      // Construir el endpoint de forma adecuada cuando se especifica la sucursal
      String endpoint = _endpoint;
      if (sucursalId != null && sucursalId.isNotEmpty) {
        // Ruta con sucursal: /api/{sucursalId}/ventas
        endpoint = '/$sucursalId/ventas';
        debugPrint('Solicitando ventas para sucursal específica: $endpoint');
      } else {
        // Ruta general: /api/ventas (sin sucursal específica)
        debugPrint('Solicitando ventas globales: $endpoint');
      }
      
      final response = await _api.authenticatedRequest(
        endpoint: endpoint,
        method: 'GET',
        queryParams: queryParams,
      );
      
      debugPrint('Respuesta de getVentas recibida: ${response.keys.toString()}');
      return response;
    } catch (e) {
      debugPrint('Error al obtener ventas: $e');
      rethrow;
    }
  }
  
  // Obtener una venta específica
  Future<Map<String, dynamic>> getVenta(String id, {String? sucursalId}) async {
    try {
      // Construir el endpoint según si hay sucursal o no
      String endpoint = _endpoint;
      if (sucursalId != null && sucursalId.isNotEmpty) {
        endpoint = '/$sucursalId/ventas';
      }
      
      final response = await _api.authenticatedRequest(
        endpoint: '$endpoint/$id',
        method: 'GET',
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al obtener venta: $e');
      rethrow;
    }
  }
  
  // Crear una nueva venta
  Future<Map<String, dynamic>> createVenta(Map<String, dynamic> ventaData, {String? sucursalId}) async {
    try {
      // Construir el endpoint según si hay sucursal o no
      String endpoint = _endpoint;
      if (sucursalId != null && sucursalId.isNotEmpty) {
        endpoint = '/$sucursalId/ventas';
      }
      
      final response = await _api.authenticatedRequest(
        endpoint: endpoint,
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
  Future<Map<String, dynamic>> updateVenta(String id, Map<String, dynamic> ventaData, {String? sucursalId}) async {
    try {
      // Construir el endpoint según si hay sucursal o no
      String endpoint = _endpoint;
      if (sucursalId != null && sucursalId.isNotEmpty) {
        endpoint = '/$sucursalId/ventas';
      }
      
      final response = await _api.authenticatedRequest(
        endpoint: '$endpoint/$id',
        method: 'PATCH',
        body: ventaData,
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al actualizar venta: $e');
      rethrow;
    }
  }
  
  // Cancelar una venta
  Future<bool> cancelarVenta(String id, String motivo, {String? sucursalId}) async {
    try {
      // Construir el endpoint según si hay sucursal o no
      String endpoint = _endpoint;
      if (sucursalId != null && sucursalId.isNotEmpty) {
        endpoint = '/$sucursalId/ventas';
      }
      
      await _api.authenticatedRequest(
        endpoint: '$endpoint/$id/cancel',
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
      // Construir el endpoint según si hay sucursal o no
      String endpoint = _endpoint;
      if (sucursalId != null && sucursalId.isNotEmpty) {
        endpoint = '/$sucursalId/ventas';
      }
      
      await _api.authenticatedRequest(
        endpoint: '$endpoint/$id/anular',
        method: 'POST',
        body: {
          'motivo': motivo,
          'fecha_anulacion': DateTime.now().toIso8601String(),
        },
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
      
      // Construir el endpoint según si hay sucursal o no
      String endpoint = '$_endpoint/estadisticas';
      if (sucursalId != null && sucursalId.isNotEmpty) {
        endpoint = '/$sucursalId/ventas/estadisticas';
      }
      
      final response = await _api.authenticatedRequest(
        endpoint: endpoint,
        method: 'GET',
        queryParams: queryParams,
      );
      
      return response;
    } catch (e) {
      debugPrint('Error al obtener estadísticas: $e');
      return {};
    }
  }
}