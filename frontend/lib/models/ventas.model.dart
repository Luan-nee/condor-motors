import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Enumeración para los estados posibles de una venta
enum EstadoVenta {
  pendiente,
  completada,
  anulada,
  declarada;

  /// Convierte el enum a string para la API
  String toText() {
    switch (this) {
      case EstadoVenta.pendiente:
        return 'PENDIENTE';
      case EstadoVenta.completada:
        return 'COMPLETADA';
      case EstadoVenta.anulada:
        return 'ANULADA';
      case EstadoVenta.declarada:
        return 'DECLARADA';
      default:
        return 'PENDIENTE';
    }
  }

  /// Crea un enum desde un texto
  static EstadoVenta fromText(String? text) {
    if (text == null) {
      return EstadoVenta.pendiente;
    }
    
    switch (text.toUpperCase()) {
      case 'COMPLETADA':
        return EstadoVenta.completada;
      case 'ANULADA':
        return EstadoVenta.anulada;
      case 'DECLARADA':
        return EstadoVenta.declarada;
      case 'PENDIENTE':
      default:
        return EstadoVenta.pendiente;
    }
  }
}

/// Clase que representa un detalle de venta
class DetalleVenta {
  final int? id;
  final String sku;
  final String nombre;
  final int cantidad;
  final double precioSinIgv;
  final double precioConIgv;
  final int tipoTaxId;
  final double totalBaseTax;
  final double totalTax;
  final double total;
  final int? productoId;
  final int? ventaId;

  DetalleVenta({
    this.id,
    required this.sku,
    required this.nombre,
    required this.cantidad,
    required this.precioSinIgv,
    required this.precioConIgv,
    required this.tipoTaxId,
    required this.totalBaseTax,
    required this.totalTax,
    required this.total,
    this.productoId,
    this.ventaId,
  });

  /// Crea un detalle de venta desde un JSON
  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      sku: json['sku'] ?? '',
      nombre: json['nombre'] ?? '',
      cantidad: json['cantidad'] ?? 0,
      precioSinIgv: _parseDouble(json['precioSinIgv']) ?? 0.0,
      precioConIgv: _parseDouble(json['precioConIgv']) ?? 0.0,
      tipoTaxId: json['tipoTaxId'] is String ? int.tryParse(json['tipoTaxId']) ?? 1 : json['tipoTaxId'] ?? 1,
      totalBaseTax: _parseDouble(json['totalBaseTax']) ?? 0.0,
      totalTax: _parseDouble(json['totalTax']) ?? 0.0,
      total: _parseDouble(json['total']) ?? 0.0,
      productoId: json['productoId'] is String ? int.tryParse(json['productoId']) : json['productoId'],
      ventaId: json['ventaId'] is String ? int.tryParse(json['ventaId']) : json['ventaId'],
    );
  }

  /// Convierte a JSON para enviar a la API
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'sku': sku,
      'nombre': nombre,
      'cantidad': cantidad,
      'precioSinIgv': precioSinIgv,
      'precioConIgv': precioConIgv,
      'tipoTaxId': tipoTaxId,
      'totalBaseTax': totalBaseTax,
      'totalTax': totalTax,
      'total': total,
      if (productoId != null) 'productoId': productoId,
      if (ventaId != null) 'ventaId': ventaId,
    };
  }

  /// Versión simplificada para crear una venta desde un detalle de proforma
  Map<String, dynamic> toCreateJson() {
    return {
      'productoId': productoId,
      'cantidad': cantidad,
      'tipoTaxId': tipoTaxId,
      'aplicarOferta': true,
    };
  }
}

/// Clase que representa los totales de una venta
class TotalesVenta {
  final int ventaId;
  final double totalGravadas;
  final double totalExoneradas;
  final double totalGratuitas;
  final double totalTax;
  final double totalVenta;

  TotalesVenta({
    required this.ventaId,
    required this.totalGravadas,
    required this.totalExoneradas,
    required this.totalGratuitas,
    required this.totalTax,
    required this.totalVenta,
  });

  /// Crea los totales desde un JSON
  factory TotalesVenta.fromJson(Map<String, dynamic> json) {
    return TotalesVenta(
      ventaId: json['ventaId'] is String ? int.tryParse(json['ventaId']) ?? 0 : json['ventaId'] ?? 0,
      totalGravadas: _parseDouble(json['totalGravadas']) ?? 0.0,
      totalExoneradas: _parseDouble(json['totalExoneradas']) ?? 0.0,
      totalGratuitas: _parseDouble(json['totalGratuitas']) ?? 0.0,
      totalTax: _parseDouble(json['totalTax']) ?? 0.0,
      totalVenta: _parseDouble(json['totalVenta']) ?? 0.0,
    );
  }

  /// Convierte a JSON para la API
  Map<String, dynamic> toJson() {
    return {
      'ventaId': ventaId,
      'totalGravadas': totalGravadas,
      'totalExoneradas': totalExoneradas,
      'totalGratuitas': totalGratuitas,
      'totalTax': totalTax,
      'totalVenta': totalVenta,
    };
  }
}

/// Representa una venta completa
class Venta {
  final int? id;
  final String? observaciones;
  final String tipoOperacion;
  final int porcentajeVenta;
  final int tipoDocumentoId;
  final String serieDocumento;
  final String numeroDocumento;
  final int monedaId;
  final int metodoPagoId;
  final int clienteId;
  final int empleadoId;
  final int sucursalId;
  final DateTime fechaEmision;
  final String horaEmision;
  final bool declarada;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final List<DetalleVenta> detalles;
  final TotalesVenta? totales;
  final EstadoVenta estado;

  Venta({
    this.id,
    this.observaciones,
    this.tipoOperacion = '0101',
    this.porcentajeVenta = 18,
    required this.tipoDocumentoId,
    required this.serieDocumento,
    required this.numeroDocumento,
    required this.monedaId,
    required this.metodoPagoId,
    required this.clienteId,
    required this.empleadoId,
    required this.sucursalId,
    required this.fechaEmision,
    required this.horaEmision,
    this.declarada = false,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.detalles,
    this.totales,
    this.estado = EstadoVenta.pendiente,
  });

  /// Crea una venta desde un JSON
  factory Venta.fromJson(Map<String, dynamic> json) {
    // Parseamos fechas de forma segura
    DateTime parseDate(value) {
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

    // Extraer datos
    final id = json['id'] is String ? int.tryParse(json['id']) : json['id'];
    final fechaEmision = parseDate(json['fechaEmision']);
    final fechaCreacion = parseDate(json['fechaCreacion'] ?? json['fecha_creacion']);
    final fechaActualizacion = parseDate(json['fechaActualizacion'] ?? json['fecha_actualizacion']);
    
    // Extraer estado
    final estado = EstadoVenta.fromText(json['estado']);
    
    // Extraer detalles
    List<DetalleVenta> detalles = [];
    if (json['detalles'] != null) {
      if (json['detalles'] is List) {
        detalles = (json['detalles'] as List)
            .map((detalle) => DetalleVenta.fromJson(detalle))
            .toList();
      }
    }
    
    // Extraer totales
    TotalesVenta? totales;
    if (json['totales'] != null) {
      totales = TotalesVenta.fromJson(json['totales']);
    }

    return Venta(
      id: id,
      observaciones: json['observaciones'],
      tipoOperacion: json['tipoOperacion'] ?? '0101',
      porcentajeVenta: json['porcentajeVenta'] ?? 18,
      tipoDocumentoId: json['tipoDocumentoId'] is String 
          ? int.tryParse(json['tipoDocumentoId']) ?? 0 
          : json['tipoDocumentoId'] ?? 0,
      serieDocumento: json['serieDocumento'] ?? '',
      numeroDocumento: json['numeroDocumento'] ?? '',
      monedaId: json['monedaId'] is String 
          ? int.tryParse(json['monedaId']) ?? 1 
          : json['monedaId'] ?? 1,
      metodoPagoId: json['metodoPagoId'] is String 
          ? int.tryParse(json['metodoPagoId']) ?? 1 
          : json['metodoPagoId'] ?? 1,
      clienteId: json['clienteId'] is String 
          ? int.tryParse(json['clienteId']) ?? 0 
          : json['clienteId'] ?? 0,
      empleadoId: json['empleadoId'] is String 
          ? int.tryParse(json['empleadoId']) ?? 0 
          : json['empleadoId'] ?? 0,
      sucursalId: json['sucursalId'] is String 
          ? int.tryParse(json['sucursalId']) ?? 0 
          : json['sucursalId'] ?? 0,
      fechaEmision: fechaEmision,
      horaEmision: json['horaEmision'] ?? '00:00:00',
      declarada: json['declarada'] ?? false,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion,
      detalles: detalles,
      totales: totales,
      estado: estado,
    );
  }

  /// Convierte a JSON para la API
  Map<String, dynamic> toJson() {
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    
    return {
      if (id != null) 'id': id,
      if (observaciones != null) 'observaciones': observaciones,
      'tipoOperacion': tipoOperacion,
      'porcentajeVenta': porcentajeVenta,
      'tipoDocumentoId': tipoDocumentoId,
      'serieDocumento': serieDocumento,
      'numeroDocumento': numeroDocumento,
      'monedaId': monedaId,
      'metodoPagoId': metodoPagoId,
      'clienteId': clienteId,
      'empleadoId': empleadoId,
      'sucursalId': sucursalId,
      'fechaEmision': dateFormat.format(fechaEmision),
      'horaEmision': horaEmision,
      'declarada': declarada,
      'detalles': detalles.map((detalle) => detalle.toJson()).toList(),
      'estado': estado.toText(),
    };
  }

  /// Versión simplificada para crear una nueva venta
  Map<String, dynamic> toCreateJson() {
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    
    return {
      if (observaciones != null) 'observaciones': observaciones,
      'tipoDocumentoId': tipoDocumentoId,
      'detalles': detalles.map((detalle) => detalle.toCreateJson()).toList(),
      'monedaId': monedaId,
      'metodoPagoId': metodoPagoId,
      'clienteId': clienteId,
      'empleadoId': empleadoId,
      'fechaEmision': dateFormat.format(fechaEmision),
      'horaEmision': horaEmision,
    };
  }

  /// Nombre formateado para la UI
  String getNombreFormateado() {
    return 'Venta #${id ?? ''}';
  }

  /// Fecha formateada para la UI
  String getFechaFormateada() {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(fechaCreacion);
  }

  /// Calcula el total a partir de los detalles
  double calcularTotal() {
    if (totales != null) {
      return totales!.totalVenta;
    }
    return detalles.fold(0, (sum, detalle) => sum + detalle.total);
  }
}

/// Utilidad para parsear valores numéricos de manera segura
double? _parseDouble(value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}
