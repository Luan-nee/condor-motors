import 'product.dart';

class Movement {
  final String id;
  final int productoId;
  final int cantidad;
  final DateTime fechaMovimiento;
  final String sucursalOrigen;
  final String sucursalDestino;
  final String estado;
  final Map<String, dynamic>? usuario;
  final Map<String, dynamic>? usuarioAprobador;
  final DateTime? fechaAprobacion;
  final Map<String, dynamic>? local;
  final Product? producto;

  Movement({
    required this.id,
    required this.productoId,
    required this.cantidad,
    required this.fechaMovimiento,
    required this.sucursalOrigen,
    required this.sucursalDestino,
    required this.estado,
    this.usuario,
    this.usuarioAprobador,
    this.fechaAprobacion,
    this.local,
    this.producto,
  });

  factory Movement.fromJson(Map<String, dynamic> json) {
    return Movement(
      id: json['id'].toString(),
      productoId: json['producto_id'] as int,
      cantidad: json['cantidad'] as int,
      fechaMovimiento: DateTime.parse(json['fecha_movimiento']),
      sucursalOrigen: json['sucursal_origen'] as String,
      sucursalDestino: json['sucursal_destino'] as String,
      estado: json['estado'] as String,
      usuario: json['usuario'] as Map<String, dynamic>?,
      usuarioAprobador: json['usuario_aprobador'] as Map<String, dynamic>?,
      fechaAprobacion: json['fecha_aprobacion'] != null 
          ? DateTime.parse(json['fecha_aprobacion'])
          : null,
      local: json['local'] as Map<String, dynamic>?,
      producto: json['producto'] != null 
          ? Product.fromJson(json['producto'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'producto_id': productoId,
      'cantidad': cantidad,
      'fecha_movimiento': fechaMovimiento.toIso8601String(),
      'sucursal_origen': sucursalOrigen,
      'sucursal_destino': sucursalDestino,
      'estado': estado,
      if (usuario != null) 'usuario': usuario,
      if (usuarioAprobador != null) 'usuario_aprobador': usuarioAprobador,
      if (fechaAprobacion != null) 'fecha_aprobacion': fechaAprobacion!.toIso8601String(),
      if (local != null) 'local': local,
    };
  }

  Movement copyWith({
    String? id,
    int? productoId,
    int? cantidad,
    DateTime? fechaMovimiento,
    String? sucursalOrigen,
    String? sucursalDestino,
    String? estado,
    Map<String, dynamic>? usuario,
    Map<String, dynamic>? usuarioAprobador,
    DateTime? fechaAprobacion,
    Map<String, dynamic>? local,
    Product? producto,
  }) {
    return Movement(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      cantidad: cantidad ?? this.cantidad,
      fechaMovimiento: fechaMovimiento ?? this.fechaMovimiento,
      sucursalOrigen: sucursalOrigen ?? this.sucursalOrigen,
      sucursalDestino: sucursalDestino ?? this.sucursalDestino,
      estado: estado ?? this.estado,
      usuario: usuario ?? this.usuario,
      usuarioAprobador: usuarioAprobador ?? this.usuarioAprobador,
      fechaAprobacion: fechaAprobacion ?? this.fechaAprobacion,
      local: local ?? this.local,
      producto: producto ?? this.producto,
    );
  }
} 