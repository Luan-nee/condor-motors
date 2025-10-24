import 'package:equatable/equatable.dart';
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
class DetalleVenta extends Equatable {
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
  final String tipoUnidad;
  final bool aplicarOferta;

  const DetalleVenta({
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
    this.tipoUnidad = 'NIU',
    this.aplicarOferta = false,
  });

  @override
  List<Object?> get props => [
        id,
        sku,
        nombre,
        cantidad,
        precioSinIgv,
        precioConIgv,
        tipoTaxId,
        totalBaseTax,
        totalTax,
        total,
        productoId,
        ventaId,
        tipoUnidad,
        aplicarOferta,
      ];

  /// Crea un detalle de venta desde un JSON
  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      sku: json['codigo'] ?? json['sku'] ?? '',
      nombre: json['nombre'] ?? '',
      cantidad: json['cantidad'] ?? 0,
      precioSinIgv: _parseDouble(json['precioSinIgv']) ?? 0.0,
      precioConIgv: _parseDouble(json['precioConIgv']) ?? 0.0,
      tipoTaxId: json['tipoTaxId'] is String
          ? int.tryParse(json['tipoTaxId']) ?? 1
          : json['tipoTaxId'] ?? 1,
      totalBaseTax: _parseDouble(json['totalBaseTax']) ?? 0.0,
      totalTax: _parseDouble(json['totalTax']) ?? 0.0,
      total: _parseDouble(json['total']) ?? 0.0,
      productoId: json['productoId'] is String
          ? int.tryParse(json['productoId'])
          : json['productoId'],
      ventaId: json['ventaId'] is String
          ? int.tryParse(json['ventaId'])
          : json['ventaId'],
      tipoUnidad: json['tipoUnidad'] ?? 'NIU',
      aplicarOferta: json['aplicarOferta'] ?? false,
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
      'tipoUnidad': tipoUnidad,
      if (productoId != null) 'productoId': productoId,
      if (ventaId != null) 'ventaId': ventaId,
      'aplicarOferta': aplicarOferta,
    };
  }

  /// Versión simplificada para crear una venta desde un detalle de proforma o personalizado
  Map<String, dynamic> toCreateJson() {
    if (productoId != null) {
      // Producto registrado (DefinedProduct)
      // El backend calculará precios e impuestos según el producto en la base de datos
      return {
        'productoId': productoId,
        'cantidad': cantidad,
        'tipoTaxId': tipoTaxId,
        'aplicarOferta': aplicarOferta,
      };
    } else {
      // Producto personalizado (CustomProduct)
      // El backend necesita el precio SIN IGV para hacer sus cálculos
      return {
        'productoId': null,
        'nombre': nombre,
        'cantidad': cantidad,
        'tipoTaxId': tipoTaxId,
        'precio':
            precioSinIgv, // Precio unitario sin IGV para que el backend calcule correctamente
      };
    }
  }

  /// Crea un detalle de venta para un producto personalizado
  ///
  /// [nombre] - Nombre del producto
  /// [cantidad] - Cantidad de unidades
  /// [precio] - Precio unitario sin IGV
  /// [tipoTaxId] - Tipo de impuesto (10: Gravado IGV 18%, 20: Exonerado, 30: Inafecto)
  /// [sku] - Código o SKU opcional
  /// [tipoUnidad] - Tipo de unidad (por defecto 'NIU')
  factory DetalleVenta.personalizado({
    required String nombre,
    required int cantidad,
    required double precio,
    required int tipoTaxId,
    String sku = '',
    String tipoUnidad = 'NIU',
  }) {
    // Calcular impuestos según el tipo de impuesto
    final double precioSinIgv = precio;
    final double precioConIgv = tipoTaxId == 10 ? precio * 1.18 : precio;

    final double subtotal = precioSinIgv * cantidad;
    final double montoIgv = tipoTaxId == 10 ? subtotal * 0.18 : 0.0;

    // Los campos totalBaseTax, totalTax y total se calculan según el tipo de impuesto
    double totalBaseTax = 0.0;
    double totalTax = 0.0;
    double total = 0.0;

    switch (tipoTaxId) {
      case 10: // Gravado
        totalBaseTax = subtotal;
        totalTax = montoIgv;
        total = subtotal + montoIgv;
      case 20: // Exonerado
        totalBaseTax = subtotal;
        totalTax = 0.0;
        total = subtotal;
      case 30: // Inafecto
        totalBaseTax = 0.0;
        totalTax = 0.0;
        total = subtotal;
      default: // Por defecto tratar como gravado
        totalBaseTax = subtotal;
        totalTax = montoIgv;
        total = subtotal + montoIgv;
    }

    return DetalleVenta(
      sku: sku,
      nombre: nombre,
      cantidad: cantidad,
      precioSinIgv: precioSinIgv,
      precioConIgv: precioConIgv,
      tipoTaxId: tipoTaxId,
      totalBaseTax: totalBaseTax,
      totalTax: totalTax,
      total: total,
      tipoUnidad: tipoUnidad,
    );
  }
}

/// Clase que representa los totales de una venta
class TotalesVenta extends Equatable {
  final int ventaId;
  final double totalGravadas;
  final double totalExoneradas;
  final double totalGratuitas;
  final double totalTax;
  final double totalVenta;

  const TotalesVenta({
    required this.ventaId,
    required this.totalGravadas,
    required this.totalExoneradas,
    required this.totalGratuitas,
    required this.totalTax,
    required this.totalVenta,
  });

  @override
  List<Object?> get props => [
        ventaId,
        totalGravadas,
        totalExoneradas,
        totalGratuitas,
        totalTax,
        totalVenta,
      ];

  /// Crea los totales desde un JSON
  factory TotalesVenta.fromJson(Map<String, dynamic> json) {
    return TotalesVenta(
      ventaId: json['ventaId'] is String
          ? int.tryParse(json['ventaId']) ?? 0
          : json['ventaId'] ?? 0,
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

/// Clase para representar la información de facturación electrónica
class DocumentoFacturacion {
  final int id;
  final String? codigoEstadoSunat;
  final String? factproDocumentId;
  final String? hash;
  final String? qr;
  final String? linkXml;
  final String? linkPdf;
  final String? linkCdr;
  final String? factproDocumentIdAnulado;
  final String? linkXmlAnulado;
  final String? linkPdfAnulado;
  final String? linkCdrAnulado;
  final String? ticketAnulado;
  final Map<String, dynamic>? informacionSunat;
  final String? linkPdfA4;
  final String? linkPdfTicket;
  final String? identificadorAnulado;
  final String? descripcionEstado;

  DocumentoFacturacion({
    required this.id,
    this.codigoEstadoSunat,
    this.factproDocumentId,
    this.hash,
    this.qr,
    this.linkXml,
    this.linkPdf,
    this.linkCdr,
    this.factproDocumentIdAnulado,
    this.linkXmlAnulado,
    this.linkPdfAnulado,
    this.linkCdrAnulado,
    this.ticketAnulado,
    this.informacionSunat,
    this.linkPdfA4,
    this.linkPdfTicket,
    this.identificadorAnulado,
    this.descripcionEstado,
  });

  factory DocumentoFacturacion.fromJson(Map<String, dynamic> json) {
    return DocumentoFacturacion(
      id: json['id'] is String
          ? int.tryParse(json['id']) ?? 0
          : json['id'] ?? 0,
      codigoEstadoSunat: json['codigoEstadoSunat'] ?? json['estadoRawId'],
      factproDocumentId: json['factproDocumentId'],
      hash: json['hash'],
      qr: json['qr'],
      linkXml: json['linkXml'],
      linkPdf: json['linkPdf'],
      linkCdr: json['linkCdr'],
      factproDocumentIdAnulado: json['factproDocumentIdAnulado'],
      linkXmlAnulado: json['linkXmlAnulado'],
      linkPdfAnulado: json['linkPdfAnulado'],
      linkCdrAnulado: json['linkCdrAnulado'],
      ticketAnulado: json['ticketAnulado'],
      informacionSunat: json['informacionSunat'],
      linkPdfA4: json['linkPdfA4'],
      linkPdfTicket: json['linkPdfTicket'],
      identificadorAnulado: json['identificadorAnulado'],
      descripcionEstado: json['descripcionEstado'],
    );
  }
}

/// Clase para representar información de cliente
class Cliente {
  final int id;
  final String? tipoDocumento;
  final String? numeroDocumento;
  final String denominacion;

  Cliente({
    required this.id,
    this.tipoDocumento,
    this.numeroDocumento,
    required this.denominacion,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] is String
          ? int.tryParse(json['id']) ?? 0
          : json['id'] ?? 0,
      tipoDocumento: json['tipoDocumento'],
      numeroDocumento: json['numeroDocumento'],
      denominacion: json['denominacion'] ?? '',
    );
  }
}

/// Clase para representar información básica de empleado
class Empleado {
  final int id;
  final String nombre;
  final String apellidos;

  Empleado({
    required this.id,
    required this.nombre,
    required this.apellidos,
  });

  factory Empleado.fromJson(Map<String, dynamic> json) {
    return Empleado(
      id: json['id'] is String
          ? int.tryParse(json['id']) ?? 0
          : json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
    );
  }

  String getNombreCompleto() {
    return '$nombre $apellidos';
  }
}

/// Clase para representar información básica de sucursal
class SucursalBasica {
  final int id;
  final String nombre;

  SucursalBasica({
    required this.id,
    required this.nombre,
  });

  factory SucursalBasica.fromJson(Map<String, dynamic> json) {
    return SucursalBasica(
      id: json['id'] is String
          ? int.tryParse(json['id']) ?? 0
          : json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
    );
  }
}

/// Representa una venta completa
class Venta extends Equatable {
  final int id;
  final String? observaciones;
  final String? motivoAnulado;
  final String tipoOperacion;
  final int porcentajeVenta;
  final int tipoDocumentoId;
  final String serieDocumento;
  final String numeroDocumento;
  final int monedaId;
  final String? moneda;
  final int metodoPagoId;
  final String? metodoPago;
  final int clienteId;
  final Cliente? clienteDetalle;
  final int empleadoId;
  final Empleado? empleadoDetalle;
  final int sucursalId;
  final SucursalBasica? sucursalDetalle;
  final DateTime fechaEmision;
  final String horaEmision;
  final bool declarada;
  final bool anulada;
  final bool cancelada;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final List<DetalleVenta> detalles;
  final TotalesVenta? totales;
  final EstadoVenta estado;
  final String? tipoDocumento;
  final DocumentoFacturacion? documentoFacturacion;
  final String? nombreCliente;
  final String? nombreEmpleado;
  final String? nombreSucursal;

  const Venta({
    required this.id,
    this.observaciones,
    this.motivoAnulado,
    this.tipoOperacion = '0101',
    this.porcentajeVenta = 18,
    required this.tipoDocumentoId,
    required this.serieDocumento,
    required this.numeroDocumento,
    required this.monedaId,
    this.moneda,
    required this.metodoPagoId,
    this.metodoPago,
    required this.clienteId,
    this.clienteDetalle,
    required this.empleadoId,
    this.empleadoDetalle,
    required this.sucursalId,
    this.sucursalDetalle,
    required this.fechaEmision,
    required this.horaEmision,
    this.declarada = false,
    this.anulada = false,
    this.cancelada = false,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.detalles,
    this.totales,
    this.estado = EstadoVenta.pendiente,
    this.tipoDocumento,
    this.documentoFacturacion,
    this.nombreCliente,
    this.nombreEmpleado,
    this.nombreSucursal,
  });

  @override
  List<Object?> get props => [
        id,
        clienteId,
        empleadoId,
        sucursalId,
        tipoDocumentoId,
        serieDocumento,
        numeroDocumento,
        fechaEmision,
        fechaCreacion,
        fechaActualizacion,
        detalles,
        totales,
        clienteDetalle,
        empleadoDetalle,
        sucursalDetalle,
        nombreCliente,
        nombreEmpleado,
        nombreSucursal,
      ];

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
    final fechaCreacion =
        parseDate(json['fechaCreacion'] ?? json['fecha_creacion']);
    final fechaActualizacion =
        parseDate(json['fechaActualizacion'] ?? json['fecha_actualizacion']);

    // Extraer estado - con manejo seguro de diferentes formatos
    EstadoVenta estado;
    if (json['estado'] == null) {
      estado = EstadoVenta.pendiente;
    } else if (json['estado'] is String) {
      estado = EstadoVenta.fromText(json['estado'] as String);
    } else if (json['estado'] is Map) {
      // Si el estado viene como un objeto, intentar extraer el código o nombre
      final estadoMap = json['estado'] as Map<String, dynamic>;
      estado = EstadoVenta.fromText(estadoMap['codigo'] ?? estadoMap['nombre']);
    } else {
      estado = EstadoVenta.pendiente;
    }

    // Extraer detalles - pueden venir como detalles o detallesVenta
    List<DetalleVenta> detalles = [];
    if (json['detalles'] != null) {
      if (json['detalles'] is List) {
        detalles = (json['detalles'] as List)
            .map((detalle) => DetalleVenta.fromJson(detalle))
            .toList();
      }
    } else if (json['detallesVenta'] != null) {
      if (json['detallesVenta'] is List) {
        detalles = (json['detallesVenta'] as List)
            .map((detalle) => DetalleVenta.fromJson(detalle))
            .toList();
      }
    }

    // Extraer totales
    TotalesVenta? totales;
    if (json['totales'] != null) {
      totales = TotalesVenta.fromJson(json['totales']);
    } else if (json['totalesVenta'] != null) {
      // Manejar el caso donde los totales vienen como 'totalesVenta'
      final totalesData = json['totalesVenta'];
      if (totalesData is Map<String, dynamic>) {
        totales = TotalesVenta.fromJson({
          'ventaId': id ?? 0,
          'totalGravadas': totalesData['totalGravadas'],
          'totalExoneradas': totalesData['totalExoneradas'],
          'totalGratuitas': totalesData['totalGratuitas'],
          'totalTax': totalesData['totalTax'],
          'totalVenta': totalesData['totalVenta'],
        });
      }
    }

    // Extraer información del cliente
    Cliente? clienteDetalle;
    if (json['cliente'] != null && json['cliente'] is Map<String, dynamic>) {
      clienteDetalle = Cliente.fromJson(json['cliente']);
    }

    // Extraer información del empleado
    Empleado? empleadoDetalle;
    if (json['empleado'] != null && json['empleado'] is Map<String, dynamic>) {
      empleadoDetalle = Empleado.fromJson(json['empleado']);
    }

    // Extraer información de la sucursal
    SucursalBasica? sucursalDetalle;
    if (json['sucursal'] != null && json['sucursal'] is Map<String, dynamic>) {
      sucursalDetalle = SucursalBasica.fromJson(json['sucursal']);
    }

    // Extraer documento facturación
    DocumentoFacturacion? documentoFacturacion;
    if (json['documentoFacturacion'] != null &&
        json['documentoFacturacion'] is Map<String, dynamic>) {
      documentoFacturacion =
          DocumentoFacturacion.fromJson(json['documentoFacturacion']);
    }

    return Venta(
      id: id ?? 0,
      observaciones: json['observaciones'],
      motivoAnulado: json['motivoAnulado'],
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
      moneda: json['moneda'],
      metodoPagoId: json['metodoPagoId'] is String
          ? int.tryParse(json['metodoPagoId']) ?? 1
          : json['metodoPagoId'] ?? 1,
      metodoPago: json['metodoPago'],
      clienteId: json['clienteId'] is String
          ? int.tryParse(json['clienteId']) ?? 0
          : json['clienteId'] ?? 0,
      clienteDetalle: clienteDetalle,
      empleadoId: json['empleadoId'] is String
          ? int.tryParse(json['empleadoId']) ?? 0
          : json['empleadoId'] ?? 0,
      empleadoDetalle: empleadoDetalle,
      sucursalId: json['sucursalId'] is String
          ? int.tryParse(json['sucursalId']) ?? 0
          : json['sucursalId'] ?? 0,
      sucursalDetalle: sucursalDetalle,
      fechaEmision: fechaEmision,
      horaEmision: json['horaEmision'] ?? '00:00:00',
      declarada: json['declarada'] ?? false,
      anulada: json['anulada'] ?? false,
      cancelada: json['cancelada'] ?? false,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion,
      detalles: detalles,
      totales: totales,
      estado: estado,
      tipoDocumento: json['tipoDocumento'],
      documentoFacturacion: documentoFacturacion,
      nombreCliente: json['nombreCliente'],
      nombreEmpleado: json['nombreEmpleado'],
      nombreSucursal: json['nombreSucursal'],
    );
  }

  /// Convierte a JSON para la API
  Map<String, dynamic> toJson() {
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

    return {
      'id': id,
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
      'anulada': anulada,
      'cancelada': cancelada,
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
    return 'Venta #$id';
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

  /// Método estático para crear un objeto de venta optimizado para enviar al backend
  static Map<String, dynamic> crearVentaOptimizada({
    required int tipoDocumentoId,
    required int clienteId,
    required int empleadoId,
    required List<DetalleVenta> detalles,
    String? observaciones,
    int? monedaId,
    int? metodoPagoId,
    DateTime? fechaEmision,
    String? horaEmision,
  }) {
    // Transformar detalles al formato que espera el backend
    final detallesFormateados =
        detalles.map((detalle) => detalle.toCreateJson()).toList();

    // Preparar datos de la venta según la estructura de CreateVentaDto
    final Map<String, dynamic> ventaData = {
      'tipoDocumentoId': tipoDocumentoId,
      'clienteId': clienteId,
      'empleadoId': empleadoId,
      'detalles': detallesFormateados,
    };

    // Añadir campos opcionales solo si tienen valor
    if (observaciones != null && observaciones.isNotEmpty) {
      ventaData['observaciones'] = observaciones;
    }

    if (monedaId != null) {
      ventaData['monedaId'] = monedaId;
    }

    if (metodoPagoId != null) {
      ventaData['metodoPagoId'] = metodoPagoId;
    }

    // Formatear fecha y hora si se proporcionan
    if (fechaEmision != null) {
      final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
      ventaData['fechaEmision'] = dateFormat.format(fechaEmision);
    }

    if (horaEmision != null && horaEmision.isNotEmpty) {
      ventaData['horaEmision'] = horaEmision;
    }

    return ventaData;
  }

  /// Obtiene la cantidad total de productos en la venta
  int get cantidadTotalProductos {
    return detalles.fold(0, (sum, item) => sum + item.cantidad);
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
