import 'package:condorsmotors/api/protected/productos.api.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:flutter/foundation.dart';

/// Estados posibles de una transferencia de inventario
enum EstadoTransferencia {
  pedido('pedido', 'Pedido'),
  enviado('enviado', 'Enviado'),
  recibido('recibido', 'Recibido');

  final String codigo;
  final String nombre;
  const EstadoTransferencia(this.codigo, this.nombre);

  static EstadoTransferencia fromString(String estado) {
    return EstadoTransferencia.values.firstWhere(
      (e) => e.codigo == estado,
      orElse: () => EstadoTransferencia.pedido,
    );
  }
}

/// Representa un producto incluido en una transferencia de inventario
class DetalleProducto {
  final int id;
  final String nombre;
  final String? codigo;
  final int cantidad;
  final int? stockOrigenActual;
  final int? stockOrigenResultante;
  final int? stockDestinoActual;
  final int? stockMinimo;
  final int? cantidadSolicitada;
  final bool? stockDisponible;
  final bool? stockBajoEnOrigen;
  final Producto? producto;

  DetalleProducto({
    required this.id,
    required this.nombre,
    this.codigo,
    required this.cantidad,
    this.stockOrigenActual,
    this.stockOrigenResultante,
    this.stockDestinoActual,
    this.stockMinimo,
    this.cantidadSolicitada,
    this.stockDisponible,
    this.stockBajoEnOrigen,
    this.producto,
  });

  /// Crea una instancia desde un mapa JSON (formato estándar)
  factory DetalleProducto.fromJson(Map<String, dynamic> json) {
    return DetalleProducto(
      id: json['productoId'] ?? json['id'],
      nombre: json['nombre'],
      codigo: json['codigo'],
      cantidad: json['cantidadSolicitada'] ?? json['cantidad'],
      stockOrigenActual: json['stockOrigenActual'],
      stockOrigenResultante: json['stockOrigenResultante'],
      stockDestinoActual: json['stockDestinoActual'],
      stockMinimo: json['stockMinimo'],
      cantidadSolicitada: json['cantidadSolicitada'],
      stockDisponible: json['stockDisponible'],
      stockBajoEnOrigen: json['stockBajoEnOrigen'],
      producto:
          json['producto'] != null ? Producto.fromJson(json['producto']) : null,
    );
  }

  /// Crea una instancia desde un mapa JSON del formato itemsVenta
  factory DetalleProducto.fromItemVenta(Map<String, dynamic> json) {
    debugPrint('Mapeando DetalleProducto desde itemVenta: ${json.toString()}');
    return DetalleProducto(
      id: json['id'] ?? 0,
      nombre: json['nombreProducto'] ?? 'Sin nombre',
      codigo: json['codigoProducto'],
      cantidad: json['cantidad'] ?? 0,
    );
  }

  /// Carga los datos completos del producto usando la API
  Future<DetalleProducto> cargarDatosProducto(
      ProductosApi api, String sucursalId) async {
    if (producto != null) {
      return this;
    }
    try {
      final Producto productoCompleto = await api.getProducto(
        productoId: id,
        sucursalId: sucursalId,
      );
      return DetalleProducto(
        id: id,
        nombre: nombre,
        codigo: codigo,
        cantidad: cantidad,
        producto: productoCompleto,
      );
    } catch (e) {
      debugPrint('Error al cargar datos del producto: $e');
      return this;
    }
  }

  /// Convierte la instancia a un mapa JSON para la API
  Map<String, dynamic> toApiJson() {
    return <String, dynamic>{
      'productoId': id,
      'cantidad': cantidad,
    };
  }

  /// Convierte la instancia a un mapa JSON completo
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (codigo != null) 'codigo': codigo,
      'cantidad': cantidad,
      if (stockOrigenActual != null) 'stockOrigenActual': stockOrigenActual,
      if (stockOrigenResultante != null)
        'stockOrigenResultante': stockOrigenResultante,
      if (stockDestinoActual != null) 'stockDestinoActual': stockDestinoActual,
      if (stockMinimo != null) 'stockMinimo': stockMinimo,
      if (cantidadSolicitada != null) 'cantidadSolicitada': cantidadSolicitada,
      if (stockDisponible != null) 'stockDisponible': stockDisponible,
      if (stockBajoEnOrigen != null) 'stockBajoEnOrigen': stockBajoEnOrigen,
      if (producto != null) 'producto': producto!.toJson(),
    };
  }

  // Métodos de ayuda para el parsing

  DetalleProducto copyWith({
    int? id,
    String? nombre,
    String? codigo,
    int? cantidad,
    int? stockOrigenActual,
    int? stockOrigenResultante,
    int? stockDestinoActual,
    int? stockMinimo,
    int? cantidadSolicitada,
    bool? stockDisponible,
    bool? stockBajoEnOrigen,
    Producto? producto,
  }) {
    return DetalleProducto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      cantidad: cantidad ?? this.cantidad,
      stockOrigenActual: stockOrigenActual ?? this.stockOrigenActual,
      stockOrigenResultante:
          stockOrigenResultante ?? this.stockOrigenResultante,
      stockDestinoActual: stockDestinoActual ?? this.stockDestinoActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      cantidadSolicitada: cantidadSolicitada ?? this.cantidadSolicitada,
      stockDisponible: stockDisponible ?? this.stockDisponible,
      stockBajoEnOrigen: stockBajoEnOrigen ?? this.stockBajoEnOrigen,
      producto: producto ?? this.producto,
    );
  }

  @override
  String toString() =>
      'DetalleProducto{id: $id, nombre: $nombre, cantidad: $cantidad}';
}

/// Representa una transferencia de inventario entre sucursales
class TransferenciaInventario {
  final int id;
  final EstadoTransferencia estado;
  final String? nombreSucursalOrigen;
  final String nombreSucursalDestino;
  final int sucursalDestinoId;
  final int? sucursalOrigenId;
  final bool modificable;
  final DateTime? salidaOrigen;
  final DateTime? llegadaDestino;
  final List<DetalleProducto>? productos;
  final String? observaciones;

  const TransferenciaInventario({
    required this.id,
    required this.estado,
    this.nombreSucursalOrigen,
    required this.nombreSucursalDestino,
    required this.sucursalDestinoId,
    this.sucursalOrigenId,
    required this.modificable,
    this.salidaOrigen,
    this.llegadaDestino,
    this.productos,
    this.observaciones,
  });

  /// Obtiene la cantidad total de productos
  int getCantidadTotal() {
    if (productos == null) {
      return 0;
    }
    return productos!.fold(0, (sum, detalle) => sum + detalle.cantidad);
  }

  /// Carga los datos completos de todos los productos
  Future<TransferenciaInventario> cargarDatosProductos(ProductosApi api) async {
    if (productos == null || productos!.isEmpty) {
      return this;
    }

    try {
      final List<DetalleProducto> productosActualizados = await Future.wait(
        productos!.map((p) => p.cargarDatosProducto(
              api,
              sucursalOrigenId?.toString() ?? sucursalDestinoId.toString(),
            )),
      );

      return copyWith(productos: productosActualizados);
    } catch (e) {
      debugPrint('Error al cargar datos de productos: $e');
      return this;
    }
  }

  /// Crea una instancia desde un mapa JSON
  factory TransferenciaInventario.fromJson(Map<String, dynamic> json) {
    debugPrint('Mapeando TransferenciaInventario desde JSON:');
    debugPrint(json.toString());

    // Si los datos vienen dentro de data, usar ese objeto
    final data = json['data'] ?? json;

    // Mapear estado
    final estado = EstadoTransferencia.values.firstWhere(
      (e) => e.codigo == data['estado']['codigo'],
      orElse: () => EstadoTransferencia.pedido,
    );

    // Mapear sucursales
    final Map<String, dynamic>? sucursalOrigen = data['sucursalOrigen'];
    final Map<String, dynamic>? sucursalDestino = data['sucursalDestino'];

    // Mapear productos desde items, itemsVenta o productos
    List<DetalleProducto>? productos;
    if (data['items'] != null) {
      productos = (data['items'] as List)
          .map((item) => DetalleProducto(
                id: item['id'],
                nombre: item['nombre'],
                cantidad: item['cantidad'],
              ))
          .toList();
      debugPrint('Productos mapeados desde items: ${productos.length}');
    } else if (data['itemsVenta'] != null) {
      productos = (data['itemsVenta'] as List)
          .map((item) => DetalleProducto.fromItemVenta(item))
          .toList();
      debugPrint('Productos mapeados desde itemsVenta: ${productos.length}');
    } else if (data['productos'] != null) {
      productos = (data['productos'] as List)
          .map((p) => DetalleProducto.fromJson(p))
          .toList();
      debugPrint('Productos mapeados desde productos: ${productos.length}');
    }

    return TransferenciaInventario(
      id: data['id'],
      estado: estado,
      sucursalOrigenId: sucursalOrigen?['id'],
      nombreSucursalOrigen: sucursalOrigen?['nombre'],
      sucursalDestinoId: sucursalDestino?['id'] ?? 0,
      nombreSucursalDestino: sucursalDestino?['nombre'] ?? 'Sin destino',
      productos: productos,
      observaciones: data['observaciones'],
      modificable: data['modificable'] ?? true,
      salidaOrigen: data['salidaOrigen'] != null
          ? DateTime.parse(data['salidaOrigen'])
          : null,
      llegadaDestino: data['llegadaDestino'] != null
          ? DateTime.parse(data['llegadaDestino'])
          : null,
    );
  }

  /// Convierte la instancia a un mapa JSON para la API de creación
  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'sucursalDestinoId': sucursalDestinoId,
      if (sucursalOrigenId != null) 'sucursalOrigenId': sucursalOrigenId,
      'items': productos
              ?.map((p) => {
                    'id': p.id,
                    'cantidad': p.cantidad,
                    'nombre': p.nombre,
                  })
              .toList() ??
          [],
      if (observaciones != null) 'observaciones': observaciones,
    };
  }

  /// Convierte la instancia a un mapa JSON completo
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estado': {
        'nombre': estado.nombre,
        'codigo': estado.codigo,
      },
      'sucursalOrigen': sucursalOrigenId != null
          ? {
              'id': sucursalOrigenId,
              'nombre': nombreSucursalOrigen,
            }
          : null,
      'sucursalDestino': {
        'id': sucursalDestinoId,
        'nombre': nombreSucursalDestino,
      },
      'items': productos
          ?.map((p) => {
                'id': p.id,
                'cantidad': p.cantidad,
                'nombre': p.nombre,
              })
          .toList(),
      'observaciones': observaciones,
      'modificable': modificable,
      'salidaOrigen': salidaOrigen?.toIso8601String(),
      'llegadaDestino': llegadaDestino?.toIso8601String(),
    };
  }

  /// Crea una copia del objeto con cambios específicos
  TransferenciaInventario copyWith({
    int? id,
    EstadoTransferencia? estado,
    String? nombreSucursalOrigen,
    String? nombreSucursalDestino,
    int? sucursalDestinoId,
    int? sucursalOrigenId,
    bool? modificable,
    DateTime? salidaOrigen,
    DateTime? llegadaDestino,
    List<DetalleProducto>? productos,
    String? observaciones,
  }) {
    return TransferenciaInventario(
      id: id ?? this.id,
      estado: estado ?? this.estado,
      nombreSucursalOrigen: nombreSucursalOrigen ?? this.nombreSucursalOrigen,
      nombreSucursalDestino:
          nombreSucursalDestino ?? this.nombreSucursalDestino,
      sucursalDestinoId: sucursalDestinoId ?? this.sucursalDestinoId,
      sucursalOrigenId: sucursalOrigenId ?? this.sucursalOrigenId,
      modificable: modificable ?? this.modificable,
      salidaOrigen: salidaOrigen ?? this.salidaOrigen,
      llegadaDestino: llegadaDestino ?? this.llegadaDestino,
      productos: productos ?? this.productos,
      observaciones: observaciones ?? this.observaciones,
    );
  }

  @override
  String toString() =>
      'TransferenciaInventario{id: $id, estado: ${estado.nombre}, origen: $nombreSucursalOrigen, destino: $nombreSucursalDestino}';
}

// Extensión de utilidad
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

/// Representa el estado del stock en origen o destino
class EstadoStock {
  final int stockActual;
  final int stockDespues;
  final int? stockMinimo;
  final bool? stockBajoDespues;

  const EstadoStock({
    required this.stockActual,
    required this.stockDespues,
    this.stockMinimo,
    this.stockBajoDespues,
  });

  factory EstadoStock.fromJson(Map<String, dynamic>? json) {
    if (json == null) return EstadoStock(stockActual: 0, stockDespues: 0);

    return EstadoStock(
      stockActual: json['stockActual'] as int,
      stockDespues: json['stockDespues'] as int,
      stockMinimo: json['stockMinimo'] as int?,
      stockBajoDespues: json['stockBajoDespues'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stockActual': stockActual,
      'stockDespues': stockDespues,
      if (stockMinimo != null) 'stockMinimo': stockMinimo,
      if (stockBajoDespues != null) 'stockBajoDespues': stockBajoDespues,
    };
  }
}

/// Representa la comparación de stock para un producto en una transferencia
class ComparacionProducto {
  final int productoId;
  final String nombre;
  final int cantidadSolicitada;
  final EstadoStock? origen;
  final EstadoStock destino;
  final bool procesable;

  const ComparacionProducto({
    required this.productoId,
    required this.nombre,
    required this.cantidadSolicitada,
    this.origen,
    required this.destino,
    required this.procesable,
  });

  factory ComparacionProducto.fromJson(Map<String, dynamic> json) {
    return ComparacionProducto(
      productoId: json['productoId'] as int,
      nombre: json['nombre'] as String,
      cantidadSolicitada: json['cantidadSolicitada'] as int,
      origen: EstadoStock.fromJson(json['origen'] as Map<String, dynamic>?),
      destino: EstadoStock.fromJson(json['destino'] as Map<String, dynamic>),
      procesable: json['procesable'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      'nombre': nombre,
      'cantidadSolicitada': cantidadSolicitada,
      'origen': origen?.toJson(),
      'destino': destino.toJson(),
      'procesable': procesable,
    };
  }

  /// Verifica si el producto quedará con stock bajo después de la transferencia
  bool get quedaConStockBajo => origen?.stockBajoDespues ?? false;

  /// Verifica si hay suficiente stock para procesar la transferencia
  bool get hayStockSuficiente =>
      origen?.stockActual != null && origen!.stockActual >= cantidadSolicitada;
}

/// Representa la comparación completa de una transferencia
class ComparacionTransferencia {
  final Sucursal sucursalOrigen;
  final Sucursal sucursalDestino;
  final bool procesable;
  final List<ComparacionProducto> productos;

  const ComparacionTransferencia({
    required this.sucursalOrigen,
    required this.sucursalDestino,
    required this.procesable,
    required this.productos,
  });

  factory ComparacionTransferencia.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    return ComparacionTransferencia(
      sucursalOrigen: Sucursal.fromJson(data['sucursalOrigen']),
      sucursalDestino: Sucursal.fromJson(data['sucursalDestino']),
      procesable: data['procesable'] as bool? ?? false,
      productos: (data['productos'] as List)
          .map((p) => ComparacionProducto.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sucursalOrigen': sucursalOrigen.toJson(),
      'sucursalDestino': sucursalDestino.toJson(),
      'procesable': procesable,
      'productos': productos.map((p) => p.toJson()).toList(),
    };
  }

  /// Obtiene la lista de productos que quedarán con stock bajo
  List<ComparacionProducto> get productosConStockBajo =>
      productos.where((p) => p.quedaConStockBajo).toList();

  /// Verifica si todos los productos son procesables
  bool get todosProductosProcesables => productos.every((p) => p.procesable);

  /// Verifica si todos los productos tienen stock suficiente
  bool get todosProductosConStock =>
      productos.every((p) => p.hayStockSuficiente);
}

/// Representa una sucursal en la comparación
class Sucursal {
  final int id;
  final String nombre;

  const Sucursal({
    required this.id,
    required this.nombre,
  });

  factory Sucursal.fromJson(Map<String, dynamic> json) {
    return Sucursal(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }
}
