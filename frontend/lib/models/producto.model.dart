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
  final String nombre;
  final String codigo;
  final double precio;
  final double precioCompra;
  final int existencias;
  final String descripcion;
  final String categoria;
  final String marca;
  final bool esLiquidacion;
  final String local;
  final List<ReglaDescuento> reglasDescuento;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final bool? tieneDescuentoTiempo;
  final int? diasSinVenta;
  final double? porcentajeDescuentoTiempo;
  final String? urlImagen;
  final bool tieneDescuento;

  Producto({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.precio,
    required this.precioCompra,
    required this.existencias,
    required this.descripcion,
    required this.categoria,
    required this.marca,
    required this.esLiquidacion,
    required this.local,
    required this.reglasDescuento,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.tieneDescuentoTiempo,
    this.diasSinVenta,
    this.porcentajeDescuentoTiempo,
    this.urlImagen,
    this.tieneDescuento = false,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String,
      precio: (json['precio'] as num).toDouble(),
      precioCompra: (json['precio_compra'] as num).toDouble(),
      existencias: json['existencias'] as int,
      descripcion: json['descripcion'] as String,
      categoria: json['categoria'] as String,
      marca: json['marca'] as String,
      esLiquidacion: json['es_liquidacion'] as bool,
      local: json['local'] as String,
      reglasDescuento: (json['reglas_descuento'] as List<dynamic>)
          .map((e) => ReglaDescuento.fromJson(e as Map<String, dynamic>))
          .toList(),
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
      fechaActualizacion: DateTime.parse(json['fecha_actualizacion'] as String),
      tieneDescuentoTiempo: json['tiene_descuento_tiempo'] as bool?,
      diasSinVenta: json['dias_sin_venta'] as int?,
      porcentajeDescuentoTiempo: (json['porcentaje_descuento_tiempo'] as num?)?.toDouble(),
      urlImagen: json['url_imagen'] as String?,
      tieneDescuento: json['tiene_descuento'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'codigo': codigo,
    'precio': precio,
    'precio_compra': precioCompra,
    'existencias': existencias,
    'descripcion': descripcion,
    'categoria': categoria,
    'marca': marca,
    'es_liquidacion': esLiquidacion,
    'local': local,
    'reglas_descuento': reglasDescuento.map((e) => e.toJson()).toList(),
    'fecha_creacion': fechaCreacion.toIso8601String(),
    'fecha_actualizacion': fechaActualizacion.toIso8601String(),
    if (tieneDescuentoTiempo != null) 'tiene_descuento_tiempo': tieneDescuentoTiempo,
    if (diasSinVenta != null) 'dias_sin_venta': diasSinVenta,
    if (porcentajeDescuentoTiempo != null) 'porcentaje_descuento_tiempo': porcentajeDescuentoTiempo,
    if (urlImagen != null) 'url_imagen': urlImagen,
    'tiene_descuento': tieneDescuento,
  };
} 

