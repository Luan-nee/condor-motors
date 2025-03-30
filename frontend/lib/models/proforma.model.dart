import 'package:condorsmotors/models/producto.model.dart';
import 'package:flutter/foundation.dart';

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
  
  // Nuevos campos del servidor para descuentos y promociones
  final double? precioOriginal;
  final int? descuento;
  final int? cantidadGratis;
  final int? cantidadPagada;

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
    this.precioOriginal,
    this.descuento,
    this.cantidadGratis,
    this.cantidadPagada,
  });

  /// Crea un objeto DetalleProforma desde un mapa JSON
  factory DetalleProforma.fromJson(Map<String, dynamic> json) {
    try {
      // Funciones auxiliares para parsear valores de forma segura
      int parseEntero(valor) {
        if (valor == null) {
          return 0;
        }
        if (valor is int) {
          return valor;
        }
        if (valor is double) {
          return valor.toInt();
        }
        if (valor is String) {
          return int.tryParse(valor) ?? 0;
        }
        if (valor is num) {
          return valor.toInt();
        }
        return 0;
      }
      
      double parseDouble(valor) {
        if (valor == null) {
          return 0.0;
        }
        if (valor is double) {
          return valor;
        }
        if (valor is int) {
          return valor.toDouble();
        }
        if (valor is String) {
          return double.tryParse(valor) ?? 0.0;
        }
        if (valor is num) {
          return valor.toDouble();
        }
        return 0.0;
      }
      
      // Priorizar el uso de cantidadTotal si está disponible en el JSON
      int cantidadFinal = 0;
      
      // Verificar si existe cantidadTotal en el JSON (nueva estructura)
      if (json.containsKey('cantidadTotal')) {
        cantidadFinal = parseEntero(json['cantidadTotal']);
      }
      // Si no existe cantidadTotal, verificar si existe cantidadPagada
      else if (json.containsKey('cantidadPagada')) {
        cantidadFinal = parseEntero(json['cantidadPagada']);
      }
      // Si no hay ninguno de los anteriores, usar el campo 'cantidad' tradicional
      else {
        cantidadFinal = parseEntero(json['cantidad']);
      }
      
      return DetalleProforma(
        productoId: parseEntero(json['productoId']),
        nombre: json['nombre']?.toString() ?? 'Producto desconocido',
        cantidad: cantidadFinal, // Usar la cantidad procesada según prioridad
        subtotal: parseDouble(json['subtotal']),
        precioUnitario: parseDouble(json['precioUnitario']),
        sku: json['sku']?.toString(),
        marca: json['marca']?.toString(),
        categoria: json['categoria']?.toString(),
        // Nuevos campos
        precioOriginal: json.containsKey('precioOriginal') ? parseDouble(json['precioOriginal']) : null,
        descuento: json.containsKey('descuento') ? parseEntero(json['descuento']) : null,
        cantidadGratis: json.containsKey('cantidadGratis') ? parseEntero(json['cantidadGratis']) : null,
        cantidadPagada: json.containsKey('cantidadPagada') ? parseEntero(json['cantidadPagada']) : null,
      );
    } catch (e) {
      debugPrint('Error al parsear DetalleProforma: $e');
      // En caso de error, retornar un objeto básico para evitar nulos
      return DetalleProforma(
        productoId: 0,
        nombre: 'Error en datos',
        cantidad: 0,
        subtotal: 0.0,
        precioUnitario: 0.0,
      );
    }
  }

  /// Crea un objeto DetalleProforma a partir de un producto
  factory DetalleProforma.fromProducto(Producto producto, {required int cantidad}) {
    final double subtotal = producto.precioVenta * cantidad;
    
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
    return <String, dynamic>{
      'productoId': productoId,
      'nombre': nombre,
      'cantidad': cantidad,
      'subtotal': subtotal,
      'precioUnitario': precioUnitario,
      if (sku != null) 'sku': sku,
      if (marca != null) 'marca': marca,
      if (categoria != null) 'categoria': categoria,
      // Nuevos campos
      if (precioOriginal != null) 'precioOriginal': precioOriginal,
      if (descuento != null) 'descuento': descuento,
      if (cantidadGratis != null) 'cantidadGratis': cantidadGratis,
      if (cantidadPagada != null) 'cantidadPagada': cantidadPagada,
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
    if (text == null) {
      return EstadoProforma.pendiente;
    }
    
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
    try {
      // Función auxiliar para extraer IDs de forma segura, maneja diferentes formatos y nulos
      int getIdSafely(value) {
        if (value == null) {
          return 0;
        }
        if (value is int) {
          return value;
        }
        if (value is String) {
          return int.tryParse(value) ?? 0;
        }
        if (value is Map<String, dynamic> && value.containsKey('id')) {
          final dynamic id = value['id'];
          if (id is int) {
            return id;
          }
          if (id is String) {
            return int.tryParse(id) ?? 0;
          }
          if (id is num) {
            return id.toInt();
          }
        }
        return 0;
      }
      
      // Procesar fechas con manejo de diferentes campos y formatos
      DateTime parseFecha(value) {
        if (value == null) {
          return DateTime.now();
        }
        if (value is DateTime) {
          return value;
        }
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

      final DateTime fechaCreacion = parseFecha(
        json['fechaCreacion'] ?? json['created_at'] ?? DateTime.now()
      );
      
      final DateTime fechaActualizacion = parseFecha(
        json['fechaActualizacion'] ?? json['updated_at']
      );
      
      final DateTime? fechaExpiracion = json['fechaExpiracion'] != null 
          ? parseFecha(json['fechaExpiracion'])
          : null;
      
      // Obtener los detalles con manejo de errores
      final List<DetalleProforma> detalles = <DetalleProforma>[];
      if (json['detalles'] != null) {
        for (final dynamic item in json['detalles'] as List) {
          try {
            if (item is Map<String, dynamic>) {
              detalles.add(DetalleProforma.fromJson(item));
            }
          } catch (e) {
            debugPrint('Error al procesar detalle de proforma: $e');
            // Continuar con el siguiente detalle en caso de error
          }
        }
      }
      
      // Obtener estado con valor por defecto
      final EstadoProforma estado = EstadoProformaExtension.fromText(
        json['estado'] as String?
      );
      
      // Parsear total de forma segura
      double parseTotal(value) {
        if (value == null) {
          return 0.0;
        }
        if (value is double) {
          return value;
        }
        if (value is int) {
          return value.toDouble();
        }
        if (value is String) {
          return double.tryParse(value) ?? 0.0;
        }
        if (value is num) {
          return value.toDouble();
        }
        return 0.0;
      }
      
      return Proforma(
        id: json['id'] is int ? json['id'] : (int.tryParse(json['id'].toString()) ?? 0),
        nombre: json['nombre'] as String?,
        total: parseTotal(json['total']),
        detalles: detalles,
        empleadoId: getIdSafely(json['empleadoId'] ?? json['empleado']),
        sucursalId: getIdSafely(json['sucursalId'] ?? json['sucursal']),
        fechaCreacion: fechaCreacion,
        fechaActualizacion: fechaActualizacion,
        clienteId: json['clienteId'] != null ? getIdSafely(json['clienteId']) : null,
        estado: estado,
        fechaExpiracion: fechaExpiracion,
        cliente: json['cliente'],
        empleado: json['empleado'],
        sucursal: json['sucursal'],
      );
    } catch (e) {
      debugPrint('Error general al procesar proforma: $e');
      // Crear proforma básica en caso de error general
      return Proforma(
        id: 0,
        nombre: 'Error en datos',
        total: 0.0,
        detalles: <DetalleProforma>[],
        empleadoId: 0,
        sucursalId: 0,
        fechaCreacion: DateTime.now(),
      );
    }
  }

  /// Convierte el objeto a un mapa JSON
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      if (nombre != null) 'nombre': nombre,
      'total': total,
      'detalles': detalles.map((DetalleProforma detalle) => detalle.toJson()).toList(),
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
    if (estado == EstadoProforma.expirada) {
      return true;
    }
    if (fechaExpiracion == null) {
      return false;
    }
    return DateTime.now().isAfter(fechaExpiracion!);
  }
  
  /// Devuelve el nombre del cliente si está disponible
  String getNombreCliente() {
    if (cliente == null) {
      return 'Cliente no especificado';
    }
    
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
    if (empleado == null) {
      return 'Empleado no especificado';
    }
    
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
    if (sucursal == null) {
      return 'Sucursal no especificada';
    }
    
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
    cliente,
    empleado,
    sucursal,
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