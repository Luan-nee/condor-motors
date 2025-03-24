class ReglaDescuento {
  final int quantity;
  final double discountPercentage;
  final int? daysWithoutSale;
  final double? timeDiscount;

  ReglaDescuento({
    required this.quantity,
    required this.discountPercentage,
    this.daysWithoutSale,
    this.timeDiscount,
  });

  factory ReglaDescuento.fromJson(Map<String, dynamic> json) {
    return ReglaDescuento(
      quantity: json['cantidad'] as int,
      discountPercentage: (json['porcentaje_descuento'] as num).toDouble(),
      daysWithoutSale: json['dias_sin_venta'] as int?,
      timeDiscount: (json['descuento_tiempo'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'cantidad': quantity,
    'porcentaje_descuento': discountPercentage,
    if (daysWithoutSale != null) 'dias_sin_venta': daysWithoutSale,
    if (timeDiscount != null) 'descuento_tiempo': timeDiscount,
  };
}

class Producto {
  final int id;
  final String sku;
  final String nombre;
  final String? descripcion;
  final int? maxDiasSinReabastecer;
  final int? stockMinimo;
  final int? cantidadMinimaDescuento;
  final int? cantidadGratisDescuento;
  final int? porcentajeDescuento;
  final String? color;
  final String categoria;
  final String marca;
  final DateTime fechaCreacion;
  final int? detalleProductoId;
  final double precioCompra;
  final double precioVenta;
  final double? precioOferta;
  final int stock;
  final bool stockBajo;

  Producto({
    required this.id,
    required this.sku,
    required this.nombre,
    this.descripcion,
    this.maxDiasSinReabastecer,
    this.stockMinimo,
    this.cantidadMinimaDescuento,
    this.cantidadGratisDescuento,
    this.porcentajeDescuento,
    this.color,
    required this.categoria,
    required this.marca,
    required this.fechaCreacion,
    this.detalleProductoId,
    required this.precioCompra,
    required this.precioVenta,
    this.precioOferta,
    required this.stock,
    this.stockBajo = false,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: _parseInt(json['id']),
      sku: json['sku'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      maxDiasSinReabastecer: json['maxDiasSinReabastecer'] != null ? _parseInt(json['maxDiasSinReabastecer']) : null,
      stockMinimo: json['stockMinimo'] != null ? _parseInt(json['stockMinimo']) : null,
      cantidadMinimaDescuento: json['cantidadMinimaDescuento'] != null ? _parseInt(json['cantidadMinimaDescuento']) : null,
      cantidadGratisDescuento: json['cantidadGratisDescuento'] != null ? _parseInt(json['cantidadGratisDescuento']) : null,
      porcentajeDescuento: json['porcentajeDescuento'] != null ? _parseInt(json['porcentajeDescuento']) : null,
      color: json['color'] as String?,
      categoria: json['categoria'] as String? ?? '',
      marca: json['marca'] as String? ?? '',
      fechaCreacion: DateTime.parse(json['fechaCreacion'] as String? ?? DateTime.now().toIso8601String()),
      detalleProductoId: json['detalleProductoId'] != null ? _parseInt(json['detalleProductoId']) : null,
      precioCompra: _parseDouble(json['precioCompra']),
      precioVenta: _parseDouble(json['precioVenta']),
      precioOferta: json['precioOferta'] != null ? _parseDouble(json['precioOferta']) : null,
      stock: _parseInt(json['stock']),
      stockBajo: json['stockBajo'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sku': sku,
    'nombre': nombre,
    if (descripcion != null) 'descripcion': descripcion,
    if (maxDiasSinReabastecer != null) 'maxDiasSinReabastecer': maxDiasSinReabastecer,
    if (stockMinimo != null) 'stockMinimo': stockMinimo,
    if (cantidadMinimaDescuento != null) 'cantidadMinimaDescuento': cantidadMinimaDescuento,
    if (cantidadGratisDescuento != null) 'cantidadGratisDescuento': cantidadGratisDescuento,
    if (porcentajeDescuento != null) 'porcentajeDescuento': porcentajeDescuento,
    if (color != null) 'color': color,
    'categoria': categoria,
    'marca': marca,
    'fechaCreacion': fechaCreacion.toIso8601String(),
    if (detalleProductoId != null) 'detalleProductoId': detalleProductoId,
    'precioCompra': precioCompra,
    'precioVenta': precioVenta,
    if (precioOferta != null) 'precioOferta': precioOferta,
    'stock': stock,
    'stockBajo': stockBajo,
  };
  
  /// Helper para convertir valores numéricos a double
  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0.0;
  }
  
  /// Helper para convertir valores a int de forma segura
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {
        return 0;
      }
    }
    return 0;
  }
  
  /// Formatea el precio de venta a soles peruanos
  String getPrecioVentaFormateado() {
    return 'S/ ${precioVenta.toStringAsFixed(2)}';
  }

  /// Formatea el precio de compra a soles peruanos
  String getPrecioCompraFormateado() {
    return 'S/ ${precioCompra.toStringAsFixed(2)}';
  }

  /// Formatea el precio de oferta a soles peruanos
  String? getPrecioOfertaFormateado() {
    return precioOferta != null ? 'S/ ${precioOferta!.toStringAsFixed(2)}' : null;
  }

  /// Calcula la ganancia
  double getGanancia() {
    return precioVenta - precioCompra;
  }

  /// Calcula el margen de ganancia en porcentaje
  double getMargenPorcentaje() {
    if (precioCompra <= 0) return 0;
    return (getGanancia() / precioCompra) * 100;
  }

  /// Verifica si el producto tiene stock bajo
  bool tieneStockBajo() {
    return stockBajo || (stockMinimo != null && stock <= stockMinimo!);
  }

  /// Verifica si el producto está en oferta
  bool estaEnOferta() {
    return precioOferta != null && precioOferta! < precioVenta;
  }

  /// Calcula el porcentaje de descuento de la oferta
  double? getPorcentajeDescuentoOferta() {
    if (!estaEnOferta()) return null;
    return ((precioVenta - precioOferta!) / precioVenta) * 100;
  }

  /// Formatea el porcentaje de descuento de la oferta
  String? getPorcentajeDescuentoOfertaFormateado() {
    final porcentaje = getPorcentajeDescuentoOferta();
    return porcentaje != null ? '${porcentaje.toStringAsFixed(0)}%' : null;
  }

  /// Create a new instance with updated fields
  Producto copyWith({
    int? id,
    String? sku,
    String? nombre,
    String? descripcion,
    int? maxDiasSinReabastecer,
    int? stockMinimo,
    int? cantidadMinimaDescuento,
    int? cantidadGratisDescuento,
    int? porcentajeDescuento,
    String? color,
    String? categoria,
    String? marca,
    DateTime? fechaCreacion,
    int? detalleProductoId,
    double? precioCompra,
    double? precioVenta,
    double? precioOferta,
    int? stock,
    bool? stockBajo,
  }) {
    return Producto(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      maxDiasSinReabastecer: maxDiasSinReabastecer ?? this.maxDiasSinReabastecer,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      cantidadMinimaDescuento: cantidadMinimaDescuento ?? this.cantidadMinimaDescuento,
      cantidadGratisDescuento: cantidadGratisDescuento ?? this.cantidadGratisDescuento,
      porcentajeDescuento: porcentajeDescuento ?? this.porcentajeDescuento,
      color: color ?? this.color,
      categoria: categoria ?? this.categoria,
      marca: marca ?? this.marca,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      detalleProductoId: detalleProductoId ?? this.detalleProductoId,
      precioCompra: precioCompra ?? this.precioCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      precioOferta: precioOferta ?? this.precioOferta,
      stock: stock ?? this.stock,
      stockBajo: stockBajo ?? this.stockBajo,
    );
  }
} 

