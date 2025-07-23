import 'package:equatable/equatable.dart';

/// Modelo para las estadísticas de sucursal relacionadas con productos
class SucursalEstadisticaProducto extends Equatable {
  final int id;
  final String nombre;
  final int stockBajo;
  final int liquidacion;

  const SucursalEstadisticaProducto({
    required this.id,
    required this.nombre,
    required this.stockBajo,
    required this.liquidacion,
  });

  @override
  List<Object?> get props => [id, nombre, stockBajo, liquidacion];

  factory SucursalEstadisticaProducto.fromJson(Map<String, dynamic> json) {
    return SucursalEstadisticaProducto(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      stockBajo: json['stockBajo'] is String
          ? int.parse(json['stockBajo'])
          : json['stockBajo'] ?? 0,
      liquidacion: json['liquidacion'] is String
          ? int.parse(json['liquidacion'])
          : json['liquidacion'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'stockBajo': stockBajo,
      'liquidacion': liquidacion,
    };
  }
}

/// Modelo para las estadísticas de sucursal relacionadas con ventas
class SucursalEstadisticaVenta extends Equatable {
  final String nombre;
  final int ventas;
  final double totalVentas;

  const SucursalEstadisticaVenta({
    required this.nombre,
    required this.ventas,
    required this.totalVentas,
  });

  @override
  List<Object?> get props => [nombre, ventas, totalVentas];

  factory SucursalEstadisticaVenta.fromJson(Map<String, dynamic> json) {
    return SucursalEstadisticaVenta(
      nombre: json['nombre'] ?? '',
      ventas: json['ventas'] is String
          ? int.parse(json['ventas'])
          : json['ventas'] ?? 0,
      totalVentas: json['totalVentas'] is String
          ? double.parse(json['totalVentas'])
          : (json['totalVentas'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'ventas': ventas,
      'totalVentas': totalVentas,
    };
  }
}

/// Modelo para las estadísticas de productos
class EstadisticasProductos extends Equatable {
  final int stockBajo;
  final int liquidacion;
  final List<SucursalEstadisticaProducto> sucursales;

  const EstadisticasProductos({
    required this.stockBajo,
    required this.liquidacion,
    required this.sucursales,
  });

  @override
  List<Object?> get props => [stockBajo, liquidacion, sucursales];

  factory EstadisticasProductos.fromJson(Map<String, dynamic> json) {
    List<SucursalEstadisticaProducto> sucursalesList = [];
    if (json['sucursales'] != null) {
      if (json['sucursales'] is List) {
        sucursalesList = (json['sucursales'] as List)
            .map((item) => SucursalEstadisticaProducto.fromJson(item))
            .toList();
      }
    }

    return EstadisticasProductos(
      stockBajo: json['stockBajo'] is String
          ? int.parse(json['stockBajo'])
          : json['stockBajo'] ?? 0,
      liquidacion: json['liquidacion'] is String
          ? int.parse(json['liquidacion'])
          : json['liquidacion'] ?? 0,
      sucursales: sucursalesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stockBajo': stockBajo,
      'liquidacion': liquidacion,
      'sucursales': sucursales.map((e) => e.toJson()).toList(),
    };
  }
}

/// Modelo para las estadísticas de ventas
class EstadisticasVentas extends Equatable {
  final Map<String, dynamic> ventas;
  final Map<String, dynamic> totalVentas;
  final List<SucursalEstadisticaVenta> sucursales;

  const EstadisticasVentas({
    required this.ventas,
    required this.totalVentas,
    required this.sucursales,
  });

  @override
  List<Object?> get props => [ventas, totalVentas, sucursales];

  /// Obtiene un valor numérico seguro de un mapa de ventas, con manejo de tipos
  static num _safeGetNum(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value;
    }
    if (value is String) {
      try {
        return num.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  /// Normaliza un mapa de ventas para asegurar que sus valores sean numéricos
  static Map<String, dynamic> _normalizeVentasMap(
      Map<String, dynamic>? rawMap) {
    if (rawMap == null) {
      return {'hoy': 0, 'esteMes': 0};
    }

    final Map<String, dynamic> normalizedMap = {};
    rawMap.forEach((key, value) {
      if (value is String) {
        try {
          normalizedMap[key] = num.parse(value);
        } catch (e) {
          normalizedMap[key] = 0;
        }
      } else if (value is num) {
        normalizedMap[key] = value;
      } else {
        normalizedMap[key] = 0;
      }
    });

    // Asegurar que al menos tenga las claves estándar
    if (!normalizedMap.containsKey('hoy')) {
      normalizedMap['hoy'] = 0;
    }
    if (!normalizedMap.containsKey('esteMes')) {
      normalizedMap['esteMes'] = 0;
    }

    return normalizedMap;
  }

  factory EstadisticasVentas.fromJson(Map<String, dynamic> json) {
    List<SucursalEstadisticaVenta> sucursalesList = [];
    if (json['sucursales'] != null) {
      if (json['sucursales'] is List) {
        sucursalesList = (json['sucursales'] as List)
            .map((item) => SucursalEstadisticaVenta.fromJson(item))
            .toList();
      }
    }

    // Normalizar los mapas de ventas para asegurar valores numéricos
    Map<String, dynamic> ventasMap =
        _normalizeVentasMap(json['ventas'] as Map<String, dynamic>?);
    Map<String, dynamic> totalVentasMap =
        _normalizeVentasMap(json['totalVentas'] as Map<String, dynamic>?);

    return EstadisticasVentas(
      ventas: ventasMap,
      totalVentas: totalVentasMap,
      sucursales: sucursalesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ventas': ventas,
      'totalVentas': totalVentas,
      'sucursales': sucursales.map((e) => e.toJson()).toList(),
    };
  }

  /// Obtiene un valor de ventas como doble de forma segura
  double getVentasValue(String key) {
    return _safeGetNum(ventas, key).toDouble();
  }

  /// Obtiene un valor de total de ventas como doble de forma segura
  double getTotalVentasValue(String key) {
    return _safeGetNum(totalVentas, key).toDouble();
  }
}

/// Modelo para el resumen de estadísticas
class ResumenEstadisticas extends Equatable {
  final EstadisticasProductos productos;
  final EstadisticasVentas ventas;

  const ResumenEstadisticas({
    required this.productos,
    required this.ventas,
  });

  @override
  List<Object?> get props => [productos, ventas];

  factory ResumenEstadisticas.fromJson(Map<String, dynamic> json) {
    return ResumenEstadisticas(
      productos: EstadisticasProductos.fromJson(json['productos'] ?? {}),
      ventas: EstadisticasVentas.fromJson(json['ventas'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productos': productos.toJson(),
      'ventas': ventas.toJson(),
    };
  }
}

/// Modelo para representar una sucursal en el contexto de una venta
class SucursalVenta extends Equatable {
  final int id;
  final bool sucursalCentral;
  final String nombre;

  const SucursalVenta({
    required this.id,
    required this.sucursalCentral,
    required this.nombre,
  });

  @override
  List<Object?> get props => [id, sucursalCentral, nombre];

  factory SucursalVenta.fromJson(Map<String, dynamic> json) {
    return SucursalVenta(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] ?? 0,
      sucursalCentral: json['sucursalCentral'] ?? false,
      nombre: json['nombre'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sucursalCentral': sucursalCentral,
      'nombre': nombre,
    };
  }
}

/// Modelo para representar el estado de un documento de facturación
class EstadoDocumentoFacturacion {
  final String codigo;
  final String nombre;

  EstadoDocumentoFacturacion({
    required this.codigo,
    required this.nombre,
  });

  factory EstadoDocumentoFacturacion.fromJson(Map<String, dynamic> json) {
    return EstadoDocumentoFacturacion(
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'nombre': nombre,
    };
  }
}

/// Modelo para los totales de una venta
class TotalesVenta {
  final double totalVenta;

  TotalesVenta({
    required this.totalVenta,
  });

  factory TotalesVenta.fromJson(Map<String, dynamic> json) {
    var total = json['totalVenta'];
    if (total is String) {
      try {
        total = double.parse(total);
      } catch (e) {
        total = 0.0;
      }
    } else if (total is num) {
      total = total.toDouble();
    } else {
      total = 0.0;
    }

    return TotalesVenta(
      totalVenta: total,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalVenta': totalVenta,
    };
  }
}

/// Modelo para representar una venta reciente
class UltimaVenta {
  final String id;
  final bool declarada;
  final bool anulada;
  final bool cancelada;
  final String? serieDocumento;
  final String? numeroDocumento;
  final String? tipoDocumento;
  final String? fechaEmision;
  final String? horaEmision;
  final SucursalVenta sucursal;
  final TotalesVenta totalesVenta;
  final EstadoDocumentoFacturacion estado;

  UltimaVenta({
    required this.id,
    required this.declarada,
    required this.anulada,
    required this.cancelada,
    this.serieDocumento,
    this.numeroDocumento,
    this.tipoDocumento,
    this.fechaEmision,
    this.horaEmision,
    required this.sucursal,
    required this.totalesVenta,
    required this.estado,
  });

  factory UltimaVenta.fromJson(Map<String, dynamic> json) {
    return UltimaVenta(
      id: json['id']?.toString() ?? '',
      declarada: json['declarada'] ?? false,
      anulada: json['anulada'] ?? false,
      cancelada: json['cancelada'] ?? false,
      serieDocumento: json['serieDocumento'],
      numeroDocumento: json['numeroDocumento'],
      tipoDocumento: json['tipoDocumento'],
      fechaEmision: json['fechaEmision'],
      horaEmision: json['horaEmision'],
      sucursal: SucursalVenta.fromJson(json['sucursal'] ?? {}),
      totalesVenta: TotalesVenta.fromJson(json['totalesVenta'] ?? {}),
      estado: EstadoDocumentoFacturacion.fromJson(json['estado'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'declarada': declarada,
      'anulada': anulada,
      'cancelada': cancelada,
      'serieDocumento': serieDocumento,
      'numeroDocumento': numeroDocumento,
      'tipoDocumento': tipoDocumento,
      'fechaEmision': fechaEmision,
      'horaEmision': horaEmision,
      'sucursal': sucursal.toJson(),
      'totalesVenta': totalesVenta.toJson(),
      'estado': estado.toJson(),
    };
  }
}
