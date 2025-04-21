class DetalleReserva {
  final double total;
  final int cantidad;
  final double precioVenta;
  final double precioCompra;
  final String nombreProducto;

  DetalleReserva({
    required this.total,
    required this.cantidad,
    required this.precioVenta,
    required this.precioCompra,
    required this.nombreProducto,
  });

  // Convertir de JSON a objeto
  factory DetalleReserva.fromJson(Map<String, dynamic> json) {
    return DetalleReserva(
      total: (json['total'] as num).toDouble(),
      cantidad: json['cantidad'] as int,
      precioVenta: (json['precioVenta'] as num).toDouble(),
      precioCompra: (json['precioCompra'] as num).toDouble(),
      nombreProducto: json['nombreProducto'] as String,
    );
  }

  // Convertir de objeto a JSON
  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'cantidad': cantidad,
      'precioVenta': precioVenta,
      'precioCompra': precioCompra,
      'nombreProducto': nombreProducto,
    };
  }

  // Copia con cambios
  DetalleReserva copyWith({
    double? total,
    int? cantidad,
    double? precioVenta,
    double? precioCompra,
    String? nombreProducto,
  }) {
    return DetalleReserva(
      total: total ?? this.total,
      cantidad: cantidad ?? this.cantidad,
      precioVenta: precioVenta ?? this.precioVenta,
      precioCompra: precioCompra ?? this.precioCompra,
      nombreProducto: nombreProducto ?? this.nombreProducto,
    );
  }
}

class PedidoExclusivo {
  final int? id;
  final String descripcion;
  final List<DetalleReserva> detallesReserva;
  final double montoAdelantado;
  final String fechaRecojo;
  final String denominacion;
  final int clienteId;
  final int sucursalId;
  final String nombre;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;

  PedidoExclusivo({
    this.id,
    required this.descripcion,
    required this.detallesReserva,
    required this.montoAdelantado,
    required this.fechaRecojo,
    required this.denominacion,
    required this.clienteId,
    required this.sucursalId,
    required this.nombre,
    required this.fechaCreacion,
    this.fechaActualizacion,
  });

  // Convertir de JSON a objeto
  factory PedidoExclusivo.fromJson(Map<String, dynamic> json) {
    final List<dynamic> detallesJson =
        (json['detallesReserva'] ?? []) as List<dynamic>;
    return PedidoExclusivo(
      id: json['id'] as int?,
      descripcion: json['descripcion'] ?? '',
      detallesReserva: detallesJson
          .map((detalle) =>
              DetalleReserva.fromJson(detalle as Map<String, dynamic>))
          .toList(),
      montoAdelantado: (json['montoAdelantado'] == null)
          ? 0.0
          : (json['montoAdelantado'] is String)
              ? double.tryParse(json['montoAdelantado']) ?? 0.0
              : (json['montoAdelantado'] as num).toDouble(),
      fechaRecojo: json['fechaRecojo'] ?? '',
      denominacion: json['denominacion'] ?? '',
      clienteId: (json['clienteId'] is String)
          ? int.tryParse(json['clienteId']) ?? 0
          : (json['clienteId'] ?? 0) as int,
      sucursalId: (json['sucursalId'] is String)
          ? int.tryParse(json['sucursalId']) ?? 0
          : (json['sucursalId'] ?? 0) as int,
      nombre: json['nombre'] ?? '',
      fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
      fechaActualizacion: json['fechaActualizacion'] != null
          ? DateTime.parse(json['fechaActualizacion'] as String)
          : null,
    );
  }

  // Convertir de lista JSON a lista de objetos
  static List<PedidoExclusivo> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => PedidoExclusivo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Convertir de objeto a JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'descripcion': descripcion,
      'detallesReserva':
          detallesReserva.map((detalle) => detalle.toJson()).toList(),
      'montoAdelantado': montoAdelantado,
      'fechaRecojo': fechaRecojo,
      'denominacion': denominacion,
      'clienteId': clienteId,
      'sucursalId': sucursalId,
      'nombre': nombre,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      if (fechaActualizacion != null)
        'fechaActualizacion': fechaActualizacion!.toIso8601String(),
    };
  }

  // Copia con cambios
  PedidoExclusivo copyWith({
    int? id,
    String? descripcion,
    List<DetalleReserva>? detallesReserva,
    double? montoAdelantado,
    String? fechaRecojo,
    String? denominacion,
    int? clienteId,
    int? sucursalId,
    String? nombre,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return PedidoExclusivo(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      detallesReserva: detallesReserva ?? this.detallesReserva,
      montoAdelantado: montoAdelantado ?? this.montoAdelantado,
      fechaRecojo: fechaRecojo ?? this.fechaRecojo,
      denominacion: denominacion ?? this.denominacion,
      clienteId: clienteId ?? this.clienteId,
      sucursalId: sucursalId ?? this.sucursalId,
      nombre: nombre ?? this.nombre,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
