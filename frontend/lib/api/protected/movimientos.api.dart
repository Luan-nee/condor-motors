import 'package:flutter/foundation.dart';
import '../main.api.dart';

class MovimientosApi {
  final ApiClient _api;
  final String _endpoint = '/movimientos';
  
  MovimientosApi(this._api);
  
  // Estados de movimientos para mostrar en la UI
  static const Map<String, String> estadosDetalle = {
    'PENDIENTE': 'Pendiente',
    'EN_PROCESO': 'En Proceso',
    'EN_TRANSITO': 'En Tránsito',
    'ENTREGADO': 'Entregado',
    'COMPLETADO': 'Completado',
  };
  
  // Obtener todos los movimientos
  Future<List<dynamic>> getMovimientos({
    String? sucursalId,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (sucursalId != null) {
        queryParams['sucursal_id'] = sucursalId;
      }
      
      if (estado != null) {
        queryParams['estado'] = estado;
      }
      
      if (fechaInicio != null) {
        queryParams['fecha_inicio'] = fechaInicio.toIso8601String();
      }
      
      if (fechaFin != null) {
        queryParams['fecha_fin'] = fechaFin.toIso8601String();
      }
      
      final response = await _api.authenticatedRequest(
        endpoint: _endpoint,
        method: 'GET',
        queryParams: queryParams,
      );
      
      return response['data'] ?? [];
    } catch (e) {
      debugPrint('Error al obtener movimientos: $e');
      rethrow;
    }
  }
  
  // Obtener un movimiento específico
  Future<Map<String, dynamic>> getMovimiento(String id) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id',
        method: 'GET',
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al obtener movimiento: $e');
      rethrow;
    }
  }
  
  // Crear un nuevo movimiento
  Future<Map<String, dynamic>> createMovimiento(Map<String, dynamic> movimientoData) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: _endpoint,
        method: 'POST',
        body: movimientoData,
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al crear movimiento: $e');
      rethrow;
    }
  }
  
  // Actualizar un movimiento existente
  Future<Map<String, dynamic>> updateMovimiento(String id, Map<String, dynamic> movimientoData) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id',
        method: 'PATCH',
        body: movimientoData,
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al actualizar movimiento: $e');
      rethrow;
    }
  }
  
  // Cambiar el estado de un movimiento
  Future<Map<String, dynamic>> cambiarEstado(String id, String nuevoEstado, {String? observacion}) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id/estado',
        method: 'PATCH',
        body: {
          'estado': nuevoEstado,
          if (observacion != null) 'observacion': observacion,
        },
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al cambiar estado del movimiento: $e');
      rethrow;
    }
  }
  
  // Cancelar un movimiento
  Future<bool> cancelarMovimiento(String id, String motivo) async {
    try {
      await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id/cancelar',
        method: 'POST',
        body: {
          'motivo': motivo,
        },
      );
      
      return true;
    } catch (e) {
      debugPrint('Error al cancelar movimiento: $e');
      return false;
    }
  }
}
