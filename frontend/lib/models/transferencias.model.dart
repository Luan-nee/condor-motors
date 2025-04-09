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
  final Producto? producto;

  const DetalleProducto({
    required this.id,
    required this.nombre,
    this.codigo,
    required this.cantidad,
    this.producto,
  });

  /// Crea una instancia desde un mapa JSON (formato estándar)
  factory DetalleProducto.fromJson(Map<String, dynamic> json) {
    return DetalleProducto(
      id: _parseId(json['id']),
      nombre: json['nombre']?.toString() ?? 'Sin nombre',
      codigo: json['codigo']?.toString(),
      cantidad: _parseCantidad(json['cantidad']),
      producto: json['producto'] != null
          ? Producto.fromJson(json['producto'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Crea una instancia desde un mapa JSON del formato itemsVenta
  factory DetalleProducto.fromItemVenta(Map<String, dynamic> json) {
    return DetalleProducto(
      id: _parseId(json['productoId'] ?? json['producto_id']),
      nombre: _parseNombre(json),
      codigo: _parseCodigo(json),
      cantidad: _parseCantidad(json['cantidad']),
      producto: json['producto'] != null
          ? Producto.fromJson(json['producto'] as Map<String, dynamic>)
          : null,
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
    return <String, dynamic>{
      'id': id,
      'nombre': nombre,
      if (codigo != null) 'codigo': codigo,
      'cantidad': cantidad,
      if (producto != null) 'producto': producto!.toJson(),
    };
  }

  // Métodos de ayuda para el parsing
  static int _parseId(value) {
    if (value == null) {
      return 0;
    }
    try {
      return value is int ? value : int.parse(value.toString());
    } catch (e) {
      debugPrint('Error al parsear ID: $e');
      return 0;
    }
  }

  static int _parseCantidad(value) {
    if (value == null) {
      return 0;
    }
    try {
      return value is int ? value : int.parse(value.toString());
    } catch (e) {
      debugPrint('Error al parsear cantidad: $e');
      return 0;
    }
  }

  static String _parseNombre(Map<String, dynamic> json) {
    return json['nombreProducto']?.toString() ??
        json['nombre']?.toString() ??
        json['producto_nombre']?.toString() ??
        'Sin nombre';
  }

  static String? _parseCodigo(Map<String, dynamic> json) {
    return json['codigo']?.toString() ??
        json['codigoProducto']?.toString() ??
        json['producto_codigo']?.toString();
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
    return TransferenciaInventario(
      id: _parseId(json['id']),
      estado: _parseEstado(json['estado']),
      nombreSucursalOrigen: _parseSucursal(json['sucursalOrigen']),
      nombreSucursalDestino: _parseSucursal(json['sucursalDestino']) ?? 'N/A',
      sucursalDestinoId: _parseSucursalId(json['sucursalDestino']) ??
          _parseId(json['sucursalDestinoId'] ?? json['sucursal_destino_id']),
      sucursalOrigenId: _parseSucursalId(json['sucursalOrigen']) ??
          _parseId(json['sucursalOrigenId'] ?? json['sucursal_origen_id']),
      modificable: json['modificable'] == true,
      salidaOrigen: _parseFecha(json['salidaOrigen']),
      llegadaDestino: _parseFecha(json['llegadaDestino']),
      productos: _parseProductos(json),
      observaciones: json['observaciones']?.toString(),
    );
  }

  /// Convierte la instancia a un mapa JSON para la API de creación
  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'sucursalDestinoId': sucursalDestinoId,
      if (sucursalOrigenId != null) 'sucursalOrigenId': sucursalOrigenId,
      'items': productos?.map((p) => p.toApiJson()).toList() ?? [],
      if (observaciones != null) 'observaciones': observaciones,
    };
  }

  /// Convierte la instancia a un mapa JSON completo
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'estado': estado.codigo,
      'nombreSucursalOrigen': nombreSucursalOrigen,
      'nombreSucursalDestino': nombreSucursalDestino,
      'sucursalDestinoId': sucursalDestinoId,
      if (sucursalOrigenId != null) 'sucursalOrigenId': sucursalOrigenId,
      'modificable': modificable,
      'salidaOrigen': salidaOrigen?.toIso8601String(),
      'llegadaDestino': llegadaDestino?.toIso8601String(),
      if (productos != null)
        'productos': productos!.map((p) => p.toJson()).toList(),
      if (observaciones != null) 'observaciones': observaciones,
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

  // Métodos de ayuda para el parsing
  static int _parseId(value) {
    if (value == null) {
      return 0;
    }
    try {
      return value is int ? value : int.parse(value.toString());
    } catch (e) {
      debugPrint('Error al parsear ID: $e');
      return 0;
    }
  }

  static DateTime? _parseFecha(value) {
    if (value == null) {
      return null;
    }
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      debugPrint('Error al parsear fecha: $e');
      return null;
    }
  }

  static List<DetalleProducto>? _parseProductos(Map<String, dynamic> json) {
    List<DetalleProducto> productos = [];

    // Intentar parsear productos en formato estándar
    if (json['productos'] is List) {
      try {
        productos = (json['productos'] as List)
            .map((item) =>
                DetalleProducto.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Error al parsear productos: $e');
      }
    }
    // Intentar parsear productos en formato itemsVenta
    else if (json['itemsVenta'] is List) {
      try {
        productos = (json['itemsVenta'] as List)
            .map((item) =>
                DetalleProducto.fromItemVenta(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Error al parsear itemsVenta: $e');
      }
    }

    return productos.isEmpty ? null : productos;
  }

  static EstadoTransferencia _parseEstado(dynamic estado) {
    if (estado == null) {
      return EstadoTransferencia.pedido;
    }

    try {
      if (estado is Map) {
        return EstadoTransferencia.fromString(
            estado['codigo']?.toString() ?? 'pedido');
      }
      return EstadoTransferencia.fromString(estado.toString());
    } catch (e) {
      debugPrint('Error al parsear estado: $e');
      return EstadoTransferencia.pedido;
    }
  }

  static String? _parseSucursal(dynamic sucursal) {
    if (sucursal == null) {
      return null;
    }

    try {
      if (sucursal is Map) {
        return sucursal['nombre']?.toString();
      }
      return sucursal.toString();
    } catch (e) {
      debugPrint('Error al parsear nombre de sucursal: $e');
      return null;
    }
  }

  static int? _parseSucursalId(dynamic sucursal) {
    if (sucursal == null) {
      return null;
    }

    try {
      if (sucursal is Map) {
        return _parseId(sucursal['id']);
      }
      return null;
    } catch (e) {
      debugPrint('Error al parsear ID de sucursal: $e');
      return null;
    }
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
