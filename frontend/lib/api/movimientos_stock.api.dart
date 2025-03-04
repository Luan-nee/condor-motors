import 'package:flutter/foundation.dart';
import 'main.api.dart';

class MovimientoStock {
  final String id;
  final String tipo;
  final String estado;
  final int localOrigenId;
  final int localDestinoId;
  final String? observaciones;
  final String? solicitanteId;
  final String? aprobadorId;
  final DateTime fechaCreacion;
  final DateTime? fechaAprobacion;
  final DateTime? fechaPreparacion;
  final DateTime? fechaDespacho;
  final DateTime? fechaRecepcion;
  final DateTime? fechaAnulacion;
  final String? motivoAnulacion;
  final List<DetalleMovimiento> detalles;

  MovimientoStock.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      tipo = json['tipo'],
      estado = json['estado'],
      localOrigenId = json['local_origen_id'],
      localDestinoId = json['local_destino_id'],
      observaciones = json['observaciones'],
      solicitanteId = json['solicitante_id'],
      aprobadorId = json['aprobador_id'],
      fechaCreacion = DateTime.parse(json['fecha_creacion']),
      fechaAprobacion = json['fecha_aprobacion'] != null
        ? DateTime.parse(json['fecha_aprobacion'])
        : null,
      fechaPreparacion = json['fecha_preparacion'] != null
        ? DateTime.parse(json['fecha_preparacion'])
        : null,
      fechaDespacho = json['fecha_despacho'] != null
        ? DateTime.parse(json['fecha_despacho'])
        : null,
      fechaRecepcion = json['fecha_recepcion'] != null
        ? DateTime.parse(json['fecha_recepcion'])
        : null,
      fechaAnulacion = json['fecha_anulacion'] != null
        ? DateTime.parse(json['fecha_anulacion'])
        : null,
      motivoAnulacion = json['motivo_anulacion'],
      detalles = json['detalles'] != null
        ? (json['detalles'] as List)
            .map((d) => DetalleMovimiento.fromJson(d))
            .toList()
        : [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipo': tipo,
    'estado': estado,
    'local_origen_id': localOrigenId,
    'local_destino_id': localDestinoId,
    'observaciones': observaciones,
    'solicitante_id': solicitanteId,
    'aprobador_id': aprobadorId,
    'detalles': detalles.map((d) => d.toJson()).toList(),
  };
}

class DetalleMovimiento {
  final int id;
  final int movimientoId;
  final int productoId;
  final int cantidad;
  final int? cantidadRecibida;
  final String estado;
  final String? observaciones;

  DetalleMovimiento.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      movimientoId = json['movimiento_id'],
      productoId = json['producto_id'],
      cantidad = json['cantidad'],
      cantidadRecibida = json['cantidad_recibida'],
      estado = json['estado'],
      observaciones = json['observaciones'];

  Map<String, dynamic> toJson() => {
    'id': id,
    'movimiento_id': movimientoId,
    'producto_id': productoId,
    'cantidad': cantidad,
    'cantidad_recibida': cantidadRecibida,
    'estado': estado,
    'observaciones': observaciones,
  };
}

class MovimientosStockApi {
  final ApiService _api;
  final String _endpoint = '/movimientos_stock';

  MovimientosStockApi(this._api);

  static const tipos = {
    'ENTRADA': 'ENTRADA',
    'SALIDA': 'SALIDA',
    'TRASLADO': 'TRASLADO',
  };


  static const estadosDetalle = {
    'PENDIENTE': 'PENDIENTE',
    'PREPARADO': 'PREPARADO',
    'DESPACHADO': 'DESPACHADO',
    'RECIBIDO': 'RECIBIDO',
    'ANULADO': 'ANULADO'
  };

  Future<List<MovimientoStock>> getMovimientos({
    String? tipo,
    String? estado,
    int? localId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (tipo != null) queryParams['tipo'] = tipo;
      if (estado != null) queryParams['estado'] = estado;
      if (localId != null) queryParams['local_id'] = localId.toString();
      if (fechaInicio != null) {
        queryParams['fecha_inicio'] = fechaInicio.toIso8601String();
      }
      if (fechaFin != null) {
        queryParams['fecha_fin'] = fechaFin.toIso8601String();
      }

      final response = await _api.request(
        endpoint: _endpoint,
        method: 'GET',
        queryParams: queryParams,
      );

      if (response == null) return [];
      return (response as List)
        .map((m) => MovimientoStock.fromJson(m))
        .toList();
    } catch (e) {
      debugPrint('Error al obtener movimientos: $e');
      return [];
    }
  }

  Future<MovimientoStock?> getMovimiento(String id) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint/$id',
        method: 'GET',
      );

      if (response == null) return null;
      return MovimientoStock.fromJson(response);
    } catch (e) {
      debugPrint('Error al obtener movimiento: $e');
      return null;
    }
  }

  Future<MovimientoStock?> createMovimiento(Map<String, dynamic> movimiento) async {
    try {
      final response = await _api.request(
        endpoint: _endpoint,
        method: 'POST',
        body: movimiento,
      );

      if (response == null) return null;
      return MovimientoStock.fromJson(response);
    } catch (e) {
      debugPrint('Error al crear movimiento: $e');
      return null;
    }
  }

  Future<bool> updateMovimiento(String id, Map<String, dynamic> movimiento) async {
    try {
      await _api.request(
        endpoint: '$_endpoint/$id',
        method: 'PATCH',
        body: movimiento,
      );
      return true;
    } catch (e) {
      debugPrint('Error al actualizar movimiento: $e');
      return false;
    }
  }

  Future<bool> aprobarMovimiento(String id, String aprobadorId) async {
    try {
      await _api.request(
        endpoint: '$_endpoint/$id/aprobar',
        method: 'POST',
        body: {
          'aprobador_id': aprobadorId,
          'fecha_aprobacion': DateTime.now().toIso8601String(),
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error al aprobar movimiento: $e');
      return false;
    }
  }

  Future<bool> prepararMovimiento(String id) async {
    try {
      await _api.request(
        endpoint: '$_endpoint/$id/preparar',
        method: 'POST',
        body: {
          'fecha_preparacion': DateTime.now().toIso8601String(),
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error al preparar movimiento: $e');
      return false;
    }
  }

  Future<bool> despacharMovimiento(String id) async {
    try {
      await _api.request(
        endpoint: '$_endpoint/$id/despachar',
        method: 'POST',
        body: {
          'fecha_despacho': DateTime.now().toIso8601String(),
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error al despachar movimiento: $e');
      return false;
    }
  }

  Future<bool> recibirMovimiento(String id) async {
    try {
      await _api.request(
        endpoint: '$_endpoint/$id/recibir',
        method: 'POST',
        body: {
          'fecha_recepcion': DateTime.now().toIso8601String(),
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error al recibir movimiento: $e');
      return false;
    }
  }

  Future<bool> anularMovimiento(String id, String motivo) async {
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
      debugPrint('Error al anular movimiento: $e');
      return false;
    }
  }
} 