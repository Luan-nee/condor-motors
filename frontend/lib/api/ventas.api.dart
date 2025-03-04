import 'package:flutter/foundation.dart';
import 'main.api.dart';

class Venta {
  final int id;
  final double total;
  final String metodoPago;
  final String estado;
  final String? observaciones;
  final String tipoComprobante;
  final String? serieComprobante;
  final String? numeroComprobante;
  final DateTime? fechaComprobante;
  final String? guiaRemision;
  final String? ordenCompra;
  final String? condicionPago;
  final DateTime? fechaVencimiento;
  final double subtotal;
  final double igv;
  final double? descuentoTotal;
  final String? vendedorId;
  final String? computadoraId;
  final int? clienteId;
  final int localId;
  final DateTime? fechaCreacion;
  final DateTime? fechaConfirmacion;
  final DateTime? fechaAnulacion;
  final String? motivoAnulacion;
  final List<DetalleVenta> detalles;

  Venta.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      total = json['total'].toDouble(),
      metodoPago = json['metodo_pago'],
      estado = json['estado'],
      observaciones = json['observaciones'],
      tipoComprobante = json['tipo_comprobante'],
      serieComprobante = json['serie_comprobante'],
      numeroComprobante = json['numero_comprobante'],
      fechaComprobante = json['fecha_comprobante'] != null 
        ? DateTime.parse(json['fecha_comprobante'])
        : null,
      guiaRemision = json['guia_remision'],
      ordenCompra = json['orden_compra'],
      condicionPago = json['condicion_pago'],
      fechaVencimiento = json['fecha_vencimiento'] != null
        ? DateTime.parse(json['fecha_vencimiento'])
        : null,
      subtotal = json['subtotal'].toDouble(),
      igv = json['igv'].toDouble(),
      descuentoTotal = json['descuento_total']?.toDouble(),
      vendedorId = json['vendedor_id'],
      computadoraId = json['computadora_id'],
      clienteId = json['cliente_id'],
      localId = json['local_id'],
      fechaCreacion = json['fecha_creacion'] != null
        ? DateTime.parse(json['fecha_creacion'])
        : null,
      fechaConfirmacion = json['fecha_confirmacion'] != null
        ? DateTime.parse(json['fecha_confirmacion'])
        : null,
      fechaAnulacion = json['fecha_anulacion'] != null
        ? DateTime.parse(json['fecha_anulacion'])
        : null,
      motivoAnulacion = json['motivo_anulacion'],
      detalles = json['detalles'] != null
        ? (json['detalles'] as List)
            .map((d) => DetalleVenta.fromJson(d))
            .toList()
        : [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'total': total,
    'metodo_pago': metodoPago,
    'estado': estado,
    'observaciones': observaciones,
    'tipo_comprobante': tipoComprobante,
    'serie_comprobante': serieComprobante,
    'numero_comprobante': numeroComprobante,
    'fecha_comprobante': fechaComprobante?.toIso8601String(),
    'guia_remision': guiaRemision,
    'orden_compra': ordenCompra,
    'condicion_pago': condicionPago,
    'fecha_vencimiento': fechaVencimiento?.toIso8601String(),
    'subtotal': subtotal,
    'igv': igv,
    'descuento_total': descuentoTotal,
    'vendedor_id': vendedorId,
    'computadora_id': computadoraId,
    'cliente_id': clienteId,
    'local_id': localId,
    'detalles': detalles.map((d) => d.toJson()).toList(),
  };
}

class DetalleVenta {
  final int id;
  final int ventaId;
  final int productoId;
  final int cantidad;
  final double precioUnitario;
  final double? descuento;
  final double subtotal;

  DetalleVenta.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      ventaId = json['venta_id'],
      productoId = json['producto_id'],
      cantidad = json['cantidad'],
      precioUnitario = json['precio_unitario'].toDouble(),
      descuento = json['descuento']?.toDouble(),
      subtotal = json['subtotal'].toDouble();

  Map<String, dynamic> toJson() => {
    'id': id,
    'venta_id': ventaId,
    'producto_id': productoId,
    'cantidad': cantidad,
    'precio_unitario': precioUnitario,
    'descuento': descuento,
    'subtotal': subtotal,
  };
}

class VentasApi {
  final ApiService _api;
  final String _endpoint = '/ventas';

  VentasApi(this._api);

  static const estados = {
    'PENDIENTE': 'PENDIENTE',
    'CONFIRMADA': 'CONFIRMADA',
    'ANULADA': 'ANULADA',
  };

  static const tiposComprobante = {
    'BOLETA': 'BOLETA',
    'FACTURA': 'FACTURA',
    'TICKET': 'TICKET',
  };

  Future<List<Venta>> getVentas({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? sucursal,
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

      final response = await _api.request(
        endpoint: _endpoint,
        method: 'GET',
        queryParams: queryParams,
      );

      if (response == null) return [];
      return (response as List)
        .map((v) => Venta.fromJson(v))
        .toList();
    } catch (e) {
      debugPrint('Error al obtener ventas: $e');
      return [];
    }
  }

  Future<Venta?> getVenta(int id) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint/$id',
        method: 'GET',
      );

      if (response == null) return null;
      return Venta.fromJson(response);
    } catch (e) {
      debugPrint('Error al obtener venta: $e');
      return null;
    }
  }

  Future<Venta?> createVenta(Map<String, dynamic> venta) async {
    try {
      final response = await _api.request(
        endpoint: _endpoint,
        method: 'POST',
        body: venta,
      );

      if (response == null) return null;
      return Venta.fromJson(response);
    } catch (e) {
      debugPrint('Error al crear venta: $e');
      return null;
    }
  }

  Future<bool> updateVenta(int id, Map<String, dynamic> venta) async {
    try {
      await _api.request(
        endpoint: '$_endpoint/$id',
        method: 'PATCH',
        body: venta,
      );
      return true;
    } catch (e) {
      debugPrint('Error al actualizar venta: $e');
      return false;
    }
  }

  Future<bool> anularVenta(int id, String motivo) async {
    try {
      await _api.request(
        endpoint: '$_endpoint/$id/anular',
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

  Future<Map<String, dynamic>> getEstadisticas({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? sucursal,
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

      final response = await _api.request(
        endpoint: '$_endpoint/estadisticas',
        method: 'GET',
        queryParams: queryParams,
      );

      return response ?? {};
    } catch (e) {
      debugPrint('Error al obtener estadísticas: $e');
      return {};
    }
  }

  // Obtener dashboard de ventas
  Future<Map<String, dynamic>> getDashboardVentas({
    required int localId,
    DateTime? fecha,
  }) async {
    try {
      final response = await _api.request(
        endpoint: '/rpc/get_dashboard_ventas',
        method: 'POST',
        body: {
          'p_local_id': localId,
          'p_fecha': fecha?.toIso8601String().split('T')[0] ?? DateTime.now().toIso8601String().split('T')[0],
        },
      );

      if (response == null) return {};

      return {
        'ventas_hoy': (response['ventas_hoy'] ?? 0.0).toDouble(),
        'ventas_mes': (response['ventas_mes'] ?? 0.0).toDouble(),
        'cantidad_ventas_hoy': response['cantidad_ventas_hoy'] ?? 0,
        'cantidad_ventas_mes': response['cantidad_ventas_mes'] ?? 0,
        'promedio_venta_hoy': (response['promedio_venta_hoy'] ?? 0.0).toDouble(),
        'promedio_venta_mes': (response['promedio_venta_mes'] ?? 0.0).toDouble(),
        'productos_sin_stock': response['productos_sin_stock'] ?? 0,
      };
    } catch (e) {
      debugPrint('Error al obtener dashboard de ventas: $e');
      return {
        'ventas_hoy': 0.0,
        'ventas_mes': 0.0,
        'cantidad_ventas_hoy': 0,
        'cantidad_ventas_mes': 0,
        'promedio_venta_hoy': 0.0,
        'promedio_venta_mes': 0.0,
        'productos_sin_stock': 0,
      };
    }
  }
}
