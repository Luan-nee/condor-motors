import 'package:flutter/foundation.dart';
import 'main.api.dart';

class DetallesMovimientoApi {
  final ApiService _api;
  final String _endpoint = '/detalles_movimiento';

  DetallesMovimientoApi(this._api);

  // Obtener detalles por ID de movimiento
  Future<List<Map<String, dynamic>>> getDetallesByMovimiento(int movimientoId) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?movimiento_id=eq.$movimientoId',
        method: 'GET',
      );

      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al obtener detalles: $e');
      return [];
    }
  }

  // Crear detalle de movimiento
  Future<Map<String, dynamic>> createDetalle(Map<String, dynamic> detalle) async {
    try {
      // Validaciones básicas
      if (!detalle.containsKey('movimiento_id') || 
          !detalle.containsKey('producto_id') ||
          !detalle.containsKey('cantidad') ||
          !detalle.containsKey('estado')) {
        throw Exception('Faltan campos requeridos');
      }

      final response = await _api.request(
        endpoint: _endpoint,
        method: 'POST',
        body: detalle,
      );

      return response ?? {};
    } catch (e) {
      debugPrint('Error al crear detalle: $e');
      rethrow;
    }
  }

  // Actualizar cantidad recibida
  Future<void> updateCantidadRecibida(int id, int cantidad) async {
    try {
      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'PUT',
        body: {
          'cantidad_recibida': cantidad,
          'estado': 'RECIBIDO'
        },
      );
    } catch (e) {
      debugPrint('Error al actualizar cantidad recibida: $e');
      rethrow;
    }
  }

  // Actualizar estado de detalle
  Future<void> updateEstado(int id, String estado) async {
    try {
      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'PUT',
        body: {'estado': estado},
      );
    } catch (e) {
      debugPrint('Error al actualizar estado: $e');
      rethrow;
    }
  }

  // Agregar observaciones
  Future<void> addObservacion(int id, String observacion) async {
    try {
      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'PUT',
        body: {'observaciones': observacion},
      );
    } catch (e) {
      debugPrint('Error al agregar observación: $e');
      rethrow;
    }
  }

  // Obtener detalles por producto
  Future<List<Map<String, dynamic>>> getDetallesByProducto(int productoId) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?producto_id=eq.$productoId',
        method: 'GET',
      );

      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al obtener detalles por producto: $e');
      return [];
    }
  }

  // Buscar detalles
  Future<List<Map<String, dynamic>>> searchDetalles({
    int? movimientoId,
    int? productoId,
    String? estado,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (movimientoId != null) queryParams['movimiento_id'] = 'eq.$movimientoId';
      if (productoId != null) queryParams['producto_id'] = 'eq.$productoId';
      if (estado != null) queryParams['estado'] = 'eq.$estado';

      final response = await _api.request(
        endpoint: _endpoint,
        method: 'GET',
        queryParams: queryParams,
      );

      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al buscar detalles: $e');
      return [];
    }
  }

  // Obtener historial de movimientos de un producto
  Future<List<Map<String, dynamic>>> getProductoMovimientos({
    required int productoId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      final response = await _api.request(
        endpoint: '/rpc/get_producto_movimientos',
        method: 'POST',
        body: {
          'p_producto_id': productoId,
          'p_fecha_inicio': fechaInicio.toIso8601String().split('T')[0],
          'p_fecha_fin': fechaFin.toIso8601String().split('T')[0],
        },
      );

      if (response == null) return [];

      return List<Map<String, dynamic>>.from(response).map((json) => {
        'fecha_movimiento': DateTime.parse(json['fecha_movimiento']),
        'tipo_movimiento': json['tipo_movimiento'],
        'cantidad': json['cantidad'],
        'local_origen': json['local_origen'],
        'local_destino': json['local_destino'],
        'estado': json['estado'],
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener historial de movimientos: $e');
      return [];
    }
  }
}
