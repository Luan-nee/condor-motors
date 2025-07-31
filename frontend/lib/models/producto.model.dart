import 'package:equatable/equatable.dart';

class ReglaDescuento extends Equatable {
  final int cantidad;
  final double discountPercentage;
  final int? daysWithoutSale;
  final double? timeDiscount;

  const ReglaDescuento({
    required this.cantidad,
    required this.discountPercentage,
    this.daysWithoutSale,
    this.timeDiscount,
  });

  @override
  List<Object?> get props =>
      [cantidad, discountPercentage, daysWithoutSale, timeDiscount];

  factory ReglaDescuento.fromJson(Map<String, dynamic> json) {
    return ReglaDescuento(
      cantidad: json['cantidad'] as int,
      discountPercentage: (json['porcentaje_descuento'] as num).toDouble(),
      daysWithoutSale: json['dias_sin_venta'] as int?,
      timeDiscount: (json['descuento_tiempo'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'cantidad': cantidad,
        'porcentaje_descuento': discountPercentage,
        if (daysWithoutSale != null) 'dias_sin_venta': daysWithoutSale,
        if (timeDiscount != null) 'descuento_tiempo': timeDiscount,
      };
}

class Producto extends Equatable {
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
  final int? colorId;
  final String categoria;
  final int categoriaId;
  final String marca;
  final int marcaId;
  final DateTime fechaCreacion;
  final int? detalleProductoId;
  final double precioCompra;
  final double precioVenta;
  final double? precioOferta;
  final int stock;
  final bool stockBajo;
  final bool liquidacion;
  final String? pathFoto;

  const Producto({
    required this.id,
    required this.sku,
    required this.nombre,
    required this.categoria,
    required this.categoriaId,
    required this.marca,
    required this.marcaId,
    required this.fechaCreacion,
    required this.precioCompra,
    required this.precioVenta,
    required this.stock,
    this.descripcion,
    this.maxDiasSinReabastecer,
    this.stockMinimo,
    this.cantidadMinimaDescuento,
    this.cantidadGratisDescuento,
    this.porcentajeDescuento,
    this.color,
    this.colorId,
    this.detalleProductoId,
    this.precioOferta,
    this.stockBajo = false,
    this.liquidacion = false,
    this.pathFoto,
  });

  @override
  List<Object?> get props => [
        id,
        sku,
        nombre,
        descripcion,
        maxDiasSinReabastecer,
        stockMinimo,
        cantidadMinimaDescuento,
        cantidadGratisDescuento,
        porcentajeDescuento,
        color,
        colorId,
        categoria,
        categoriaId,
        marca,
        marcaId,
        fechaCreacion,
        detalleProductoId,
        precioCompra,
        precioVenta,
        precioOferta,
        stock,
        stockBajo,
        liquidacion,
        pathFoto,
      ];

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: _parseInt(json['id']),
      sku: json['sku'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      maxDiasSinReabastecer: json['maxDiasSinReabastecer'] != null
          ? _parseInt(json['maxDiasSinReabastecer'])
          : null,
      stockMinimo:
          json['stockMinimo'] != null ? _parseInt(json['stockMinimo']) : null,
      cantidadMinimaDescuento: json['cantidadMinimaDescuento'] != null
          ? _parseInt(json['cantidadMinimaDescuento'])
          : null,
      cantidadGratisDescuento: json['cantidadGratisDescuento'] != null
          ? _parseInt(json['cantidadGratisDescuento'])
          : null,
      porcentajeDescuento: json['porcentajeDescuento'] != null
          ? _parseInt(json['porcentajeDescuento'])
          : null,
      color: json['color'] as String?,
      colorId: json['colorId'] != null ? _parseInt(json['colorId']) : null,
      categoria: json['categoria'] as String? ?? '',
      categoriaId: _parseInt(json['categoriaId'] ?? 0),
      marca: json['marca'] as String? ?? '',
      marcaId: _parseInt(json['marcaId'] ?? 0),
      fechaCreacion: DateTime.parse(
          json['fechaCreacion'] as String? ?? DateTime.now().toIso8601String()),
      detalleProductoId: json['detalleProductoId'] != null
          ? _parseInt(json['detalleProductoId'])
          : null,
      precioCompra: _parseDouble(json['precioCompra']),
      precioVenta: _parseDouble(json['precioVenta']),
      precioOferta: json['precioOferta'] != null
          ? _parseDouble(json['precioOferta'])
          : null,
      stock: _parseInt(json['stock']),
      stockBajo: json['stockBajo'] as bool? ?? false,
      liquidacion: json['liquidacion'] as bool? ?? false,
      pathFoto: json['pathFoto'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'sku': sku,
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (maxDiasSinReabastecer != null)
          'maxDiasSinReabastecer': maxDiasSinReabastecer,
        if (stockMinimo != null) 'stockMinimo': stockMinimo,
        if (cantidadMinimaDescuento != null)
          'cantidadMinimaDescuento': cantidadMinimaDescuento,
        if (cantidadGratisDescuento != null)
          'cantidadGratisDescuento': cantidadGratisDescuento,
        if (porcentajeDescuento != null)
          'porcentajeDescuento': porcentajeDescuento,
        if (color != null) 'color': color,
        if (colorId != null) 'colorId': colorId,
        'categoria': categoria,
        'categoriaId': categoriaId,
        'marca': marca,
        'marcaId': marcaId,
        'fechaCreacion': fechaCreacion.toIso8601String(),
        if (detalleProductoId != null) 'detalleProductoId': detalleProductoId,
        'precioCompra': precioCompra,
        'precioVenta': precioVenta,
        if (precioOferta != null) 'precioOferta': precioOferta,
        'stock': stock,
        'stockBajo': stockBajo,
        'liquidacion': liquidacion,
        if (pathFoto != null) 'pathFoto': pathFoto,
      };

  /// Helper para convertir valores numéricos a double
  static double _parseDouble(value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is String) {
      return double.parse(value);
    }
    return 0.0;
  }

  /// Helper para convertir valores a int de forma segura
  static int _parseInt(value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
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
    return precioOferta != null
        ? 'S/ ${precioOferta!.toStringAsFixed(2)}'
        : null;
  }

  /// Calcula la ganancia
  double getGanancia() {
    return precioVenta - precioCompra;
  }

  /// Calcula el margen de ganancia en porcentaje
  double getMargenPorcentaje() {
    if (precioCompra <= 0) {
      return 0;
    }
    return (getGanancia() / precioCompra) * 100;
  }

  /// Verifica si el producto tiene stock bajo
  bool tieneStockBajo() {
    return stockBajo ||
        (stockMinimo != null && stock <= stockMinimo! && stock != 0);
  }

  /// Verifica si el producto está en oferta
  bool estaEnOferta() {
    return precioOferta != null && precioOferta! < precioVenta;
  }

  /// Calcula el porcentaje de descuento de la oferta
  double? getPorcentajeDescuentoOferta() {
    if (!estaEnOferta()) {
      return null;
    }
    return ((precioVenta - precioOferta!) / precioVenta) * 100;
  }

  /// Formatea el porcentaje de descuento de la oferta
  String? getPorcentajeDescuentoOfertaFormateado() {
    final double? porcentaje = getPorcentajeDescuentoOferta();
    return porcentaje != null ? '${porcentaje.toStringAsFixed(0)}%' : null;
  }

  /// Indica si el producto está en liquidación
  bool get estaEnLiquidacion => liquidacion;

  /// Indica si el producto tiene alguna promoción (liquidación, gratis, o porcentual)
  bool get tienePromocion =>
      estaEnLiquidacion || tienePromocionGratis || tieneDescuentoPorcentual;

  /// Obtiene el precio actual considerando si está en liquidación o oferta
  double getPrecioActual() {
    if (liquidacion && precioOferta != null) {
      return precioOferta!;
    } else if (estaEnOferta()) {
      return precioOferta!;
    } else {
      return precioVenta;
    }
  }

  /// Formatea el precio actual considerando liquidación a soles peruanos
  String getPrecioActualFormateado() {
    return 'S/ ${getPrecioActual().toStringAsFixed(2)}';
  }

  /// Calcula la ganancia considerando la liquidación
  double getGananciaActual() {
    return getPrecioActual() - precioCompra;
  }

  /// Calcula el margen de ganancia en porcentaje considerando la liquidación
  double getMargenPorcentajeActual() {
    if (precioCompra <= 0) {
      return 0;
    }
    return (getGananciaActual() / precioCompra) * 100;
  }

  /// Calcula el precio con descuento según cantidad
  Map<String, dynamic> calcularPrecioConDescuento(int cantidad) {
    double precio = getPrecioActual();
    int cantidadGratis = 0;
    double descuentoPorcentaje = 0;

    if (cantidadMinimaDescuento == null ||
        cantidad < cantidadMinimaDescuento!) {
      return {
        'precio': precio,
        'cantidadGratis': cantidadGratis,
        'descuentoPorcentaje': descuentoPorcentaje
      };
    }

    if (cantidadGratisDescuento != null && cantidadGratisDescuento! > 0) {
      cantidadGratis = cantidadGratisDescuento!;
      return {
        'precio': precio,
        'cantidadGratis': cantidadGratis,
        'descuentoPorcentaje': descuentoPorcentaje
      };
    } else if (porcentajeDescuento != null && porcentajeDescuento! > 0) {
      descuentoPorcentaje = porcentajeDescuento!.toDouble();
      precio = precio * (1 - descuentoPorcentaje / 100);
      return {
        'precio': precio,
        'cantidadGratis': cantidadGratis,
        'descuentoPorcentaje': descuentoPorcentaje
      };
    }

    return {
      'precio': precio,
      'cantidadGratis': cantidadGratis,
      'descuentoPorcentaje': descuentoPorcentaje
    };
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
    int? colorId,
    String? categoria,
    int? categoriaId,
    String? marca,
    int? marcaId,
    DateTime? fechaCreacion,
    int? detalleProductoId,
    double? precioCompra,
    double? precioVenta,
    double? precioOferta,
    int? stock,
    bool? stockBajo,
    bool? liquidacion,
    String? pathFoto,
  }) {
    return Producto(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      maxDiasSinReabastecer:
          maxDiasSinReabastecer ?? this.maxDiasSinReabastecer,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      cantidadMinimaDescuento:
          cantidadMinimaDescuento ?? this.cantidadMinimaDescuento,
      cantidadGratisDescuento:
          cantidadGratisDescuento ?? this.cantidadGratisDescuento,
      porcentajeDescuento: porcentajeDescuento ?? this.porcentajeDescuento,
      color: color ?? this.color,
      colorId: colorId ?? this.colorId,
      categoria: categoria ?? this.categoria,
      categoriaId: categoriaId ?? this.categoriaId,
      marca: marca ?? this.marca,
      marcaId: marcaId ?? this.marcaId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      detalleProductoId: detalleProductoId ?? this.detalleProductoId,
      precioCompra: precioCompra ?? this.precioCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      precioOferta: precioOferta ?? this.precioOferta,
      stock: stock ?? this.stock,
      stockBajo: stockBajo ?? this.stockBajo,
      liquidacion: liquidacion ?? this.liquidacion,
      pathFoto: pathFoto ?? this.pathFoto,
    );
  }

  /// Devuelve la url de la foto del producto, o un placeholder si es null
  String get fotoUrl => pathFoto ?? 'https://via.placeholder.com/150';

  /// Indica si el producto tiene promoción de productos gratis
  bool get tienePromocionGratis =>
      cantidadGratisDescuento != null && cantidadGratisDescuento! > 0;

  /// Indica si el producto tiene descuento porcentual
  bool get tieneDescuentoPorcentual {
    if (porcentajeDescuento != null && cantidadMinimaDescuento != null) {
      return porcentajeDescuento! > 0 && cantidadMinimaDescuento! > 0;
    }
    return false;
  }

  /// Calcula el precio con descuento según la cantidad
  double getPrecioConDescuento(int cantidad) {
    if (estaEnLiquidacion && precioOferta != null) {
      return precioOferta!;
    } else if (tieneDescuentoPorcentual &&
        cantidad >= (cantidadMinimaDescuento ?? 0)) {
      final descuento = (precioVenta * (porcentajeDescuento ?? 0)) / 100;
      return precioVenta - descuento;
    } else {
      return precioVenta;
    }
  }

  /// Calcula la cantidad de productos gratis según la cantidad comprada
  int getProductosGratis(int cantidad) {
    if (tienePromocionGratis &&
        cantidadMinimaDescuento != null &&
        cantidadGratisDescuento != null &&
        cantidad >= cantidadMinimaDescuento!) {
      final gruposCompletos = cantidad ~/ cantidadMinimaDescuento!;
      return gruposCompletos * cantidadGratisDescuento!;
    }
    return 0;
  }

  /// Devuelve la url completa de la foto del producto, o un placeholder si no hay imagen
  String getFotoUrlCompleta(String baseUrl) {
    if (pathFoto == null || pathFoto!.isEmpty) {
      return 'https://via.placeholder.com/150';
    }
    String normalized = pathFoto!.replaceAll('\\', '/');
    if (normalized.startsWith('http')) {
      return normalized;
    }
    // Elimina barra final de baseUrl y barra inicial de normalized
    String cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    String cleanPath =
        normalized.startsWith('/') ? normalized.substring(1) : normalized;
    return '$cleanBase/$cleanPath';
  }
}
