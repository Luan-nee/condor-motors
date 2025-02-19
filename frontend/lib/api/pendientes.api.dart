import 'package:flutter/material.dart';
import './api.service.dart';

class VentasApi {
  final ApiService _api;

  VentasApi(this._api);

  Future<List<Map<String, dynamic>>> getPendingOrders(
    String computadoraId, {
    Map<String, String>? queryParams,
  }) async {
    try {
      if (computadoraId.isEmpty) {
        throw Exception('ID de computadora requerido');
      }

      final params = {
        'computadora_id': computadoraId,
        'skip': '0',
        'limit': '100',
        ...?queryParams,
      };

      final response = await _api.request(
        endpoint: '/ventas-pendientes',
        method: 'GET',
        queryParams: params,
      );

      if (response == null) return [];

      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      debugPrint('Error al obtener ventas pendientes: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getOrder(String orderId) async {
    try {
      final response = await _api.request(
        endpoint: '/ventas-pendientes/$orderId',
        method: 'GET',
        queryParams: const {},
      );

      return response ?? {};
    } catch (e) {
      debugPrint('Error al obtener venta: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> confirmOrder(String orderId, String computadoraId) async {
    try {
      if (orderId.isEmpty || computadoraId.isEmpty) {
        throw Exception('ID de venta y computadora son requeridos');
      }

      final response = await _api.request(
        endpoint: '/ventas-pendientes/$orderId/confirmar',
        method: 'PUT',
        queryParams: {
          'computadora_id': computadoraId,
        },
      );

      return response ?? {};
    } catch (e) {
      debugPrint('Error al confirmar venta: $e');
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId, String usuarioId) async {
    try {
      if (orderId.isEmpty || usuarioId.isEmpty) {
        throw Exception('ID de venta y usuario son requeridos');
      }

      await _api.request(
        endpoint: '/ventas-pendientes/$orderId/cancelar',
        method: 'PUT',
        queryParams: {
          'usuario_id': usuarioId,
        },
      );
    } catch (e) {
      debugPrint('Error al cancelar venta: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPendingSale(Map<String, dynamic> data) async {
    try {
      if (!data.containsKey('detalles') || (data['detalles'] as List).isEmpty) {
        throw Exception('La venta debe tener al menos un detalle');
      }

      if (!data.containsKey('vendedor_id') || !data.containsKey('local_id')) {
        throw Exception('Vendedor y local son requeridos');
      }

      final ventaData = {
        'vendedor_id': int.parse(data['vendedor_id'].toString()),
        'local_id': int.parse(data['local_id'].toString()),
        'observaciones': data['observaciones'] ?? 'Venta desde app móvil',
        'detalles': (data['detalles'] as List).map((detalle) {
          if (!detalle.containsKey('producto_id') || 
              !detalle.containsKey('cantidad') ||
              !detalle.containsKey('precio_unitario')) {
            throw Exception('Datos de producto incompletos');
          }

          final cantidad = int.parse(detalle['cantidad'].toString());
          final precio = double.parse(detalle['precio_unitario'].toString());
          
          if (cantidad <= 0) {
            throw Exception('La cantidad debe ser mayor a 0');
          }
          if (precio <= 0) {
            throw Exception('El precio debe ser mayor a 0');
          }

          return {
            'producto_id': int.parse(detalle['producto_id'].toString()),
            'cantidad': cantidad,
            'precio_unitario': precio,
            'descuento': 0,
          };
        }).toList(),
      };

      final response = await _api.request(
        endpoint: '/ventas-pendientes',
        method: 'POST',
        body: ventaData,
        queryParams: const {},
      );

      return response;
    } catch (e) {
      debugPrint('Error al crear venta pendiente: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSalesHistory(String computadoraId) async {
    try {
      if (computadoraId.isEmpty) {
        throw Exception('ID de computadora no válido');
      }

      final response = await _api.request(
        endpoint: '/ventas-historial',
        method: 'GET',
        queryParams: {
          'computadora_id': computadoraId,
        },
      );

      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      throw Exception('Formato de respuesta inválido');
    } catch (e) {
      debugPrint('Error al obtener historial: $e');
      rethrow;
    }
  }

  Future<void> rejectOrder(String orderId) async {
    try {
      await _api.request(
        endpoint: '/ventas-pendientes/$orderId/rechazar',
        method: 'PUT',
        queryParams: const {},
      );
    } catch (e) {
      debugPrint('Error al rechazar venta: $e');
      rethrow;
    }
  }
} 