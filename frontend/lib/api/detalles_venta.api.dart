import 'package:flutter/foundation.dart';
import 'main.api.dart';

class DetallesVentaApi {
  final ApiService _api;
  final String _endpoint = '/detalles_venta';

  DetallesVentaApi(this._api);

  // Obtener detalles por ID de venta
  Future<List<Map<String, dynamic>>> getDetallesByVenta(int ventaId) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?venta_id=eq.$ventaId',
        method: 'GET',
      );

      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al obtener detalles de venta: $e');
      return [];
    }
  }

  // Crear detalle de venta
  Future<Map<String, dynamic>> createDetalle(Map<String, dynamic> detalle) async {
    try {
      // Validaciones básicas
      if (!detalle.containsKey('venta_id') ||
          !detalle.containsKey('producto_id') ||
          !detalle.containsKey('cantidad') ||
          !detalle.containsKey('precio_unitario')) {
        throw Exception('Faltan campos requeridos');
      }

      // Calcular subtotal e IGV si no están definidos
      if (!detalle.containsKey('subtotal')) {
        final cantidad = detalle['cantidad'] as int;
        final precioUnitario = detalle['precio_unitario'] as num;
        final descuento = (detalle['descuento'] as num?) ?? 0;
        
        detalle['subtotal'] = (cantidad * precioUnitario) - descuento;
      }

      if (!detalle.containsKey('igv_unitario')) {
        detalle['igv_unitario'] = detalle['precio_unitario'] * 0.18; // 18% IGV
      }

      final response = await _api.request(
        endpoint: _endpoint,
        method: 'POST',
        body: detalle,
      );

      return response ?? {};
    } catch (e) {
      debugPrint('Error al crear detalle de venta: $e');
      rethrow;
    }
  }

  // Actualizar detalle de venta
  Future<void> updateDetalle(int id, Map<String, dynamic> detalle) async {
    try {
      // Recalcular subtotal si cambia cantidad, precio o descuento
      if (detalle.containsKey('cantidad') ||
          detalle.containsKey('precio_unitario') ||
          detalle.containsKey('descuento')) {
        
        final detalleActual = await getDetalle(id);
        if (detalleActual != null) {
          final cantidad = detalle['cantidad'] ?? detalleActual['cantidad'] as int;
          final precioUnitario = detalle['precio_unitario'] ?? 
              detalleActual['precio_unitario'] as num;
          final descuento = detalle['descuento'] ?? 
              (detalleActual['descuento'] as num?) ?? 0;

          detalle['subtotal'] = (cantidad * precioUnitario) - descuento;
          detalle['igv_unitario'] = precioUnitario * 0.18;
        }
      }

      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'PUT',
        body: detalle,
      );
    } catch (e) {
      debugPrint('Error al actualizar detalle de venta: $e');
      rethrow;
    }
  }

  // Obtener un detalle específico
  Future<Map<String, dynamic>?> getDetalle(int id) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'GET',
      );

      if (response == null || (response as List).isEmpty) return null;
      return Map<String, dynamic>.from(response[0]);
    } catch (e) {
      debugPrint('Error al obtener detalle: $e');
      return null;
    }
  }

  // Eliminar detalle de venta
  Future<void> deleteDetalle(int id) async {
    try {
      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'DELETE',
      );
    } catch (e) {
      debugPrint('Error al eliminar detalle de venta: $e');
      rethrow;
    }
  }
}
