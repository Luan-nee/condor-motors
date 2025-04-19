/// Modelo para las estadísticas de sucursal relacionadas con productos
class SucursalEstadisticaProducto {
  final int id;
  final String nombre;
  final int stockBajo;
  final int liquidacion;

  SucursalEstadisticaProducto({
    required this.id,
    required this.nombre,
    required this.stockBajo,
    required this.liquidacion,
  });

  factory SucursalEstadisticaProducto.fromJson(Map<String, dynamic> json) {
    return SucursalEstadisticaProducto(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
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
class SucursalEstadisticaVenta {
  final String nombre;
  final int ventas;
  final double totalVentas;

  SucursalEstadisticaVenta({
    required this.nombre,
    required this.ventas,
    required this.totalVentas,
  });

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
class EstadisticasProductos {
  final int stockBajo;
  final int liquidacion;
  final List<SucursalEstadisticaProducto> sucursales;

  EstadisticasProductos({
    required this.stockBajo,
    required this.liquidacion,
    required this.sucursales,
  });

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
class EstadisticasVentas {
  final Map<String, dynamic> ventas;
  final Map<String, dynamic> totalVentas;
  final List<SucursalEstadisticaVenta> sucursales;

  EstadisticasVentas({
    required this.ventas,
    required this.totalVentas,
    required this.sucursales,
  });

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
class ResumenEstadisticas {
  final EstadisticasProductos productos;
  final EstadisticasVentas ventas;

  ResumenEstadisticas({
    required this.productos,
    required this.ventas,
  });

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
