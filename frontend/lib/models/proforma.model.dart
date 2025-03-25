import 'package:flutter/foundation.dart';
import 'producto.model.dart';

/// Modelo para los detalles de una proforma de venta
class DetalleProforma {
  final int productoId;
  final String nombre;
  final int cantidad;
  final double subtotal;
  final double precioUnitario;
  
  // Campos adicionales para mejorar la experiencia
  final String? sku;
  final String? marca;
  final String? categoria;
  final Producto? producto; // Referencia opcional al producto completo

  const DetalleProforma({
    required this.productoId,
    required this.nombre,
    required this.cantidad,
    required this.subtotal,
    required this.precioUnitario,
    this.sku,
    this.marca,
    this.categoria,
    this.producto,
  });

  /// Crea un objeto DetalleProforma desde un mapa JSON
  factory DetalleProforma.fromJson(Map<String, dynamic> json) {
    return DetalleProforma(
      productoId: json['productoId'] as int,
      nombre: json['nombre'] as String,
      cantidad: json['cantidad'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
      precioUnitario: (json['precioUnitario'] as num?)?.toDouble() ?? 0.0,
      sku: json['sku'] as String?,
      marca: json['marca'] as String?,
      categoria: json['categoria'] as String?,
    );
  }

  /// Crea un objeto DetalleProforma a partir de un producto
  factory DetalleProforma.fromProducto(Producto producto, {required int cantidad}) {
    final subtotal = producto.precioVenta * cantidad;
    
    return DetalleProforma(
      productoId: producto.id,
      nombre: producto.nombre,
      cantidad: cantidad,
      subtotal: subtotal,
      precioUnitario: producto.precioVenta,
      sku: producto.sku,
      marca: producto.marca,
      categoria: producto.categoria,
      producto: producto,
    );
  }

  /// Convierte el objeto a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      'nombre': nombre,
      'cantidad': cantidad,
      'subtotal': subtotal,
      'precioUnitario': precioUnitario,
      if (sku != null) 'sku': sku,
      if (marca != null) 'marca': marca,
      if (categoria != null) 'categoria': categoria,
    };
  }
  
  /// Actualiza la cantidad y recalcula el subtotal
  DetalleProforma copyWithCantidad(int nuevaCantidad) {
    return DetalleProforma(
      productoId: productoId,
      nombre: nombre,
      cantidad: nuevaCantidad,
      subtotal: precioUnitario * nuevaCantidad, // Recalcular subtotal
      precioUnitario: precioUnitario,
      sku: sku,
      marca: marca,
      categoria: categoria,
      producto: producto,
    );
  }
  
  /// Formatea el precio unitario a moneda peruana
  String getPrecioUnitarioFormateado() {
    return 'S/ ${precioUnitario.toStringAsFixed(2)}';
  }
  
  /// Formatea el subtotal a moneda peruana
  String getSubtotalFormateado() {
    return 'S/ ${subtotal.toStringAsFixed(2)}';
  }
}

/// Estados posibles de una proforma
enum EstadoProforma {
  pendiente,
  convertida,
  cancelada,
  expirada
}

/// Extensión para manejar la conversión entre strings y enum
extension EstadoProformaExtension on EstadoProforma {
  String toText() {
    switch (this) {
      case EstadoProforma.pendiente:
        return 'Pendiente';
      case EstadoProforma.convertida:
        return 'Convertida a venta';
      case EstadoProforma.cancelada:
        return 'Cancelada';
      case EstadoProforma.expirada:
        return 'Expirada';
    }
  }
  
  static EstadoProforma fromText(String? text) {
    if (text == null) return EstadoProforma.pendiente;
    
    switch (text.toLowerCase()) {
      case 'convertida':
      case 'convertida a venta':
        return EstadoProforma.convertida;
      case 'cancelada':
        return EstadoProforma.cancelada;
      case 'expirada':
        return EstadoProforma.expirada;
      default:
        return EstadoProforma.pendiente;
    }
  }
}

/// Modelo para una proforma de venta
class Proforma {
  final int id;
  final String? nombre;
  final double total;
  final List<DetalleProforma> detalles;
  final int empleadoId;
  final int sucursalId;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;
  final int? clienteId;
  final EstadoProforma estado;
  final DateTime? fechaExpiracion;
  
  // Referencias a otros modelos completos
  final dynamic cliente;  // Puede ser un modelo o Map<String, dynamic>
  final dynamic empleado; // Puede ser un modelo o Map<String, dynamic>
  final dynamic sucursal; // Puede ser un modelo o Map<String, dynamic>

  Proforma({
    required this.id,
    this.nombre,
    required this.total,
    required this.detalles,
    required this.empleadoId,
    required this.sucursalId,
    required this.fechaCreacion,
    this.fechaActualizacion,
    this.clienteId,
    this.estado = EstadoProforma.pendiente,
    this.fechaExpiracion,
    this.cliente,
    this.empleado,
    this.sucursal,
  });

  /// Crea un objeto Proforma desde un mapa JSON
  factory Proforma.fromJson(Map<String, dynamic> json) {
    // Procesar fechas con manejo de diferentes campos y formatos
    DateTime parseFecha(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          debugPrint('Error al parsear fecha: $e');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    final fechaCreacion = parseFecha(
      json['fechaCreacion'] ?? json['created_at'] ?? DateTime.now()
    );
    
    final fechaActualizacion = parseFecha(
      json['fechaActualizacion'] ?? json['updated_at']
    );
    
    final fechaExpiracion = parseFecha(json['fechaExpiracion']);
    
    // Obtener IDs directamente o desde objetos anidados
    int getIdFromObject(String field) {
      if (json[field] is int) return json[field] as int;
      if (json[field] is Map<String, dynamic>) {
        return (json[field]['id'] as int?) ?? 0;
      }
      return 0;
    }
    
    // Obtener los detalles
    final List<DetalleProforma> detalles = [];
    if (json['detalles'] != null) {
      detalles.addAll((json['detalles'] as List)
          .map((item) => DetalleProforma.fromJson(item as Map<String, dynamic>))
          .toList());
    }
    
    // Obtener estado
    final estado = EstadoProformaExtension.fromText(json['estado'] as String?);
    
    return Proforma(
      id: json['id'] as int,
      nombre: json['nombre'] as String?,
      total: json['total'] is String 
          ? double.parse(json['total']) 
          : (json['total'] as num).toDouble(),
      detalles: detalles,
      empleadoId: getIdFromObject('empleadoId'),
      sucursalId: getIdFromObject('sucursalId'),
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion,
      clienteId: json['clienteId'] as int?,
      estado: estado,
      fechaExpiracion: fechaExpiracion,
      cliente: json['cliente'],
      empleado: json['empleado'],
      sucursal: json['sucursal'],
    );
  }

  /// Convierte el objeto a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (nombre != null) 'nombre': nombre,
      'total': total,
      'detalles': detalles.map((detalle) => detalle.toJson()).toList(),
      'empleadoId': empleadoId,
      'sucursalId': sucursalId,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      if (fechaActualizacion != null) 'fechaActualizacion': fechaActualizacion!.toIso8601String(),
      if (clienteId != null) 'clienteId': clienteId,
      'estado': estado.toText(),
      if (fechaExpiracion != null) 'fechaExpiracion': fechaExpiracion!.toIso8601String(),
    };
  }
  
  /// Formatea el total a moneda peruana
  String getTotalFormateado() {
    return 'S/ ${total.toStringAsFixed(2)}';
  }
  
  /// Comprueba si la proforma está pendiente y puede convertirse en venta
  bool puedeConvertirseEnVenta() {
    return estado == EstadoProforma.pendiente;
  }
  
  /// Comprueba si la proforma ha expirado
  bool haExpirado() {
    if (estado == EstadoProforma.expirada) return true;
    if (fechaExpiracion == null) return false;
    return DateTime.now().isAfter(fechaExpiracion!);
  }
  
  /// Devuelve el nombre del cliente si está disponible
  String getNombreCliente() {
    if (cliente == null) return 'Cliente no especificado';
    
    if (cliente is Map<String, dynamic>) {
      return cliente['nombre'] ?? 'Cliente no especificado';
    }
    
    try {
      // Intenta acceder a la propiedad nombre si el modelo cliente la tiene
      return (cliente.nombre as String?) ?? 'Cliente no especificado';
    } catch (_) {
      return 'Cliente no especificado';
    }
  }
  
  /// Devuelve el nombre del empleado si está disponible
  String getNombreEmpleado() {
    if (empleado == null) return 'Empleado no especificado';
    
    if (empleado is Map<String, dynamic>) {
      return empleado['nombre'] ?? 'Empleado no especificado';
    }
    
    try {
      // Intenta acceder a la propiedad nombre si el modelo empleado la tiene
      return (empleado.nombre as String?) ?? 'Empleado no especificado';
    } catch (_) {
      return 'Empleado no especificado';
    }
  }
  
  /// Devuelve el nombre de la sucursal si está disponible
  String getNombreSucursal() {
    if (sucursal == null) return 'Sucursal no especificada';
    
    if (sucursal is Map<String, dynamic>) {
      return sucursal['nombre'] ?? 'Sucursal no especificada';
    }
    
    try {
      // Intenta acceder a la propiedad nombre si el modelo sucursal la tiene
      return (sucursal.nombre as String?) ?? 'Sucursal no especificada';
    } catch (_) {
      return 'Sucursal no especificada';
    }
  }
  
  /// Crea una copia del objeto con algunos campos actualizados
  Proforma copyWith({
    int? id,
    String? nombre,
    double? total,
    List<DetalleProforma>? detalles,
    int? empleadoId,
    int? sucursalId,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    int? clienteId,
    EstadoProforma? estado,
    DateTime? fechaExpiracion,
    dynamic cliente,
    dynamic empleado,
    dynamic sucursal,
  }) {
    return Proforma(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      total: total ?? this.total,
      detalles: detalles ?? this.detalles,
      empleadoId: empleadoId ?? this.empleadoId,
      sucursalId: sucursalId ?? this.sucursalId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      clienteId: clienteId ?? this.clienteId,
      estado: estado ?? this.estado,
      fechaExpiracion: fechaExpiracion ?? this.fechaExpiracion,
      cliente: cliente ?? this.cliente,
      empleado: empleado ?? this.empleado,
      sucursal: sucursal ?? this.sucursal,
    );
  }
} 