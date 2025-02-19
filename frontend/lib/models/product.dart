import 'regla_descuento.dart';

class Product {
  final int id;
  final String nombre;
  final String codigo;
  final double precio;
  final double precioCompra;
  final int existencias;
  final String descripcion;
  final String categoria;
  final String marca;
  final String? imagenUrl;
  final bool esLiquidacion;
  final int localId;
  final DateTime? ultimaVenta;
  final List<ReglaDescuento> reglasDescuento;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  bool get hasDiscount => reglasDescuento.isNotEmpty || esLiquidacion;
  double get profit => precio - precioCompra;
  double get profitPercentage => (profit / precioCompra) * 100;

  // Getters para compatibilidad con código existente
  String get name => nombre;
  double get price => precio;
  double get purchasePrice => precioCompra;
  int get stock => existencias;
  String get description => descripcion;
  String get category => categoria;
  String get imageUrl => imagenUrl ?? '';
  String get local => localId.toString();
  List<ReglaDescuento> get discountRules => reglasDescuento;
  bool get isLiquidacion => esLiquidacion;

  // Calcular si aplica descuento por tiempo
  bool get hasTimeDiscount {
    if (ultimaVenta == null) return false;
    
    final timeRule = reglasDescuento.firstWhere(
      (rule) => rule.daysWithoutSale != null,
      orElse: () => ReglaDescuento(
        quantity: 0,
        discountPercentage: 0,
      ),
    );

    if (timeRule.daysWithoutSale == null) return false;

    final daysSinceLastSale = DateTime.now().difference(ultimaVenta!).inDays;
    return daysSinceLastSale >= timeRule.daysWithoutSale!;
  }

  // Obtener el descuento actual por tiempo
  double? get currentTimeDiscount {
    if (!hasTimeDiscount) return null;

    return reglasDescuento
        .firstWhere(
          (rule) => rule.daysWithoutSale != null,
          orElse: () => ReglaDescuento(
            quantity: 0,
            discountPercentage: 0,
          ),
        )
        .timeDiscount;
  }

  Product({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.precio,
    required this.precioCompra,
    required this.existencias,
    required this.descripcion,
    required this.categoria,
    required this.marca,
    this.imagenUrl,
    required this.esLiquidacion,
    required this.localId,
    this.ultimaVenta,
    required this.reglasDescuento,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      precio: (json['precio'] ?? 0.0) as double,
      precioCompra: (json['precio_compra'] ?? 0.0) as double,
      existencias: (json['existencias'] ?? 0) as int,
      descripcion: json['descripcion']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      marca: json['marca']?.toString() ?? '',
      imagenUrl: json['imagen_url']?.toString(),
      esLiquidacion: json['es_liquidacion'] as bool? ?? false,
      localId: json['local_id'] as int? ?? 0,
      ultimaVenta: json['ultima_venta'] != null 
          ? DateTime.parse(json['ultima_venta'] as String)
          : null,
      reglasDescuento: (json['reglas_descuento'] as List<dynamic>?)
          ?.map((e) => ReglaDescuento.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String? ?? DateTime.now().toIso8601String()),
      fechaActualizacion: DateTime.parse(json['fecha_actualizacion'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      'precio': precio,
      'precio_compra': precioCompra,
      'existencias': existencias,
      'descripcion': descripcion,
      'categoria': categoria,
      'marca': marca,
      'imagen_url': imagenUrl,
      'es_liquidacion': esLiquidacion,
      'local_id': localId,
      'reglas_descuento': reglasDescuento.map((r) => r.toJson()).toList(),
      'ultima_venta': ultimaVenta?.toIso8601String(),
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          codigo == other.codigo;

  @override
  int get hashCode => id.hashCode ^ codigo.hashCode;

  // Getters para el formulario
  int? get daysWithoutSale {
    final timeRule = reglasDescuento.firstWhere(
      (rule) => rule.daysWithoutSale != null,
      orElse: () => ReglaDescuento(quantity: 0, discountPercentage: 0),
    );
    return timeRule.daysWithoutSale;
  }

  double get timeDiscountPercentage {
    final timeRule = reglasDescuento.firstWhere(
      (rule) => rule.timeDiscount != null,
      orElse: () => ReglaDescuento(quantity: 0, discountPercentage: 0),
    );
    return timeRule.timeDiscount ?? 10.0;
  }
} 