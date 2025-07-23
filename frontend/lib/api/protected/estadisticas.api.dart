import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/cache/fast_cache.dart';
import 'package:condorsmotors/models/estadisticas.model.dart';
import 'package:condorsmotors/utils/logger.dart';

/// Clase para manejar las estadísticas de productos y ventas
class EstadisticasApi {
  final ApiClient _api;
  final String _endpoint = '/estadisticas';
  final FastCache _cache = FastCache(maxSize: 50);

  // Prefijos para las claves de caché
  static const String _prefixEstadisticasProductos = 'estadisticas_productos_';
  static const String _prefixEstadisticasVentas = 'estadisticas_ventas_';
  static const String _prefixUltimasVentas = 'ultimas_ventas_';

  EstadisticasApi(this._api);

  /// Invalida el caché de estadísticas
  void invalidateCache() {
    _cache
      ..invalidateByPattern(_prefixEstadisticasProductos)
      ..invalidateByPattern(_prefixEstadisticasVentas)
      ..invalidateByPattern(_prefixUltimasVentas);
    logCache('Caché de estadísticas invalidado');
  }

  /// Obtiene las últimas ventas registradas
  ///
  /// [useCache] - Indica si se debe usar el caché
  /// [forceRefresh] - Indica si se debe forzar la actualización del caché
  Future<Map<String, dynamic>> getUltimasVentas({
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      final String cacheKey = '${_prefixUltimasVentas}global';

      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }

      if (useCache && !forceRefresh) {
        final Map<String, dynamic>? cachedData =
            _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          logCache('Usando últimas ventas en caché');
          return cachedData;
        }
      }

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/ultimasventas',
        method: 'GET',
      );

      if (useCache) {
        _cache.set(cacheKey, response);
        logCache('Últimas ventas guardadas en caché');
      }

      return response;
    } catch (e) {
      Logger.error('Error al obtener últimas ventas: $e');
      return <String, dynamic>{
        'status': 'error',
        'message': 'Error al obtener últimas ventas',
        'data': <dynamic>[],
      };
    }
  }

  /// Obtiene las estadísticas de productos (stock bajo y liquidación)
  ///
  /// [useCache] - Indica si se debe usar el caché
  /// [forceRefresh] - Indica si se debe forzar la actualización del caché
  Future<Map<String, dynamic>> getEstadisticasProductos({
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      final String cacheKey = '${_prefixEstadisticasProductos}global';

      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }

      if (useCache && !forceRefresh) {
        final Map<String, dynamic>? cachedData =
            _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          logCache('Usando estadísticas de productos en caché');
          return cachedData;
        }
      }

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/productos',
        method: 'GET',
      );

      // Validar y normalizar la respuesta
      if (response['status'] == 'success' && response['data'] != null) {
        final Object? dataObj = response['data'];
        if (dataObj is Map<String, dynamic>) {
          final Map<String, dynamic> data = dataObj;

          // Si sucursales no es una lista, convertirlo a lista vacía
          if (data.containsKey('sucursales') && data['sucursales'] != null && data['sucursales'] is! List) {
            data['sucursales'] = <dynamic>[];
          }

          // Normalizar valores numéricos
          if (data.containsKey('stockBajo') && data['stockBajo'] is String) {
            try {
              data['stockBajo'] = int.parse(data['stockBajo'] as String);
            } catch (e) {
              data['stockBajo'] = 0;
            }
          }

          if (data.containsKey('liquidacion') && data['liquidacion'] is String) {
            try {
              data['liquidacion'] = int.parse(data['liquidacion'] as String);
            } catch (e) {
              data['liquidacion'] = 0;
            }
          }
        }
      }

      if (useCache) {
        _cache.set(cacheKey, response);
        logCache('Estadísticas de productos guardadas en caché');
      }

      return response;
    } catch (e) {
      Logger.error('Error al obtener estadísticas de productos: $e');
      return <String, dynamic>{
        'status': 'error',
        'message': 'Error al obtener estadísticas de productos',
        'data': const EstadisticasProductos(
          stockBajo: 0,
          liquidacion: 0,
          sucursales: [],
        ).toJson(),
      };
    }
  }

  /// Obtiene los productos con stock bajo de una sucursal específica
  ///
  /// [sucursalId] - ID de la sucursal
  /// [useCache] - Indica si se debe usar el caché
  /// [forceRefresh] - Indica si se debe forzar la actualización del caché
  Future<Map<String, dynamic>> getProductosStockBajoSucursal({
    required String sucursalId,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      final String cacheKey =
          '${_prefixEstadisticasProductos}stock_bajo_$sucursalId';

      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }

      if (useCache && !forceRefresh) {
        final Map<String, dynamic>? cachedData =
            _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          logCache(
              'Usando productos de stock bajo en caché para sucursal $sucursalId');
          return cachedData;
        }
      }

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/productos',
        method: 'GET',
      );

      if (response['status'] == 'success' && response['data'] != null) {
        final Object? dataObj = response['data'];
        if (dataObj is Map<String, dynamic>) {
          final Map<String, dynamic> data = dataObj;
          final List<dynamic> sucursales = data['sucursales'] is List ? data['sucursales'] as List<dynamic> : <dynamic>[];

          for (final Object? sucursalObj in sucursales) {
            if (sucursalObj is Map<String, dynamic>) {
              final Map<String, dynamic> sucursal = sucursalObj;
              final String? idStr = sucursal['id']?.toString();
              if (idStr == sucursalId) {
                Map<String, dynamic> sucursalStats = {
                  'status': 'success',
                  'data': [
                    {
                      'id': 'placeholder-${sucursal['id']}',
                      'nombre': 'Productos con stock bajo en ${sucursal['nombre']}',
                      'stock': 1,
                      'stockMinimo': 10,
                      'sucursalId': sucursal['id'],
                      'sucursalNombre': sucursal['nombre'],
                      'categoria': 'Varias categorías',
                      'marca': 'Varias marcas',
                      'stockBajo': sucursal['stockBajo'],
                      'liquidacion': sucursal['liquidacion'],
                    }
                  ]
                };

                if (useCache) {
                  _cache.set(cacheKey, sucursalStats);
                  logCache(
                      'Datos de stock bajo para sucursal $sucursalId guardados en caché');
                }

                return sucursalStats;
              }
            }
          }
        }
      }

      return <String, dynamic>{
        'status': 'error',
        'message':
            'No se encontraron datos de productos con stock bajo para la sucursal $sucursalId',
        'data': <dynamic>[],
      };
    } catch (e) {
      Logger.error(
          'Error al obtener productos con stock bajo para sucursal $sucursalId: $e');
      return <String, dynamic>{
        'status': 'error',
        'message': 'Error al obtener productos con stock bajo',
        'data': <dynamic>[],
      };
    }
  }

  /// Obtiene las estadísticas de ventas
  ///
  /// [useCache] - Indica si se debe usar el caché
  /// [forceRefresh] - Indica si se debe forzar la actualización del caché
  Future<Map<String, dynamic>> getEstadisticasVentas({
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      final String cacheKey = '${_prefixEstadisticasVentas}global';

      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }

      if (useCache && !forceRefresh) {
        final Map<String, dynamic>? cachedData =
            _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          logCache('Usando estadísticas de ventas en caché');
          return cachedData;
        }
      }

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/ventas',
        method: 'GET',
      );

      if (response['status'] == 'success' && response['data'] != null) {
        final Object? dataObj = response['data'];
        if (dataObj is Map<String, dynamic>) {
          final Map<String, dynamic> data = dataObj;

          if (data.containsKey('sucursales') && data['sucursales'] != null && data['sucursales'] is! List) {
            data['sucursales'] = <dynamic>[];
          }

          // Normalizar el mapa de ventas
          if (data.containsKey('ventas') && data['ventas'] != null) {
            if (data['ventas'] is! Map) {
              data['ventas'] = {'hoy': 0, 'esteMes': 0};
            } else {
              final Map<String, dynamic> ventasMap =
                  Map<String, dynamic>.from(data['ventas'] as Map);
              ventasMap.forEach((key, value) {
                if (value is String) {
                  try {
                    ventasMap[key] = num.parse(value);
                  } catch (e) {
                    ventasMap[key] = 0;
                  }
                }
              });
              data['ventas'] = ventasMap;
            }
          } else {
            data['ventas'] = {'hoy': 0, 'esteMes': 0};
          }

          // Normalizar el mapa de totalVentas
          if (data.containsKey('totalVentas') && data['totalVentas'] != null) {
            if (data['totalVentas'] is! Map) {
              data['totalVentas'] = {'hoy': 0, 'esteMes': 0};
            } else {
              final Map<String, dynamic> totalVentasMap =
                  Map<String, dynamic>.from(data['totalVentas'] as Map);
              totalVentasMap.forEach((key, value) {
                if (value is String) {
                  try {
                    totalVentasMap[key] = num.parse(value);
                  } catch (e) {
                    totalVentasMap[key] = 0;
                  }
                }
              });
              data['totalVentas'] = totalVentasMap;
            }
          } else {
            data['totalVentas'] = {'hoy': 0, 'esteMes': 0};
          }
        }
      }

      if (useCache) {
        _cache.set(cacheKey, response);
        logCache('Estadísticas de ventas guardadas en caché');
      }

      return response;
    } catch (e) {
      Logger.error('Error al obtener estadísticas de ventas: $e');
      return <String, dynamic>{
        'status': 'error',
        'message': 'Error al obtener estadísticas de ventas',
        'data': const EstadisticasVentas(
          ventas: {'hoy': 0, 'esteMes': 0},
          totalVentas: {'hoy': 0, 'esteMes': 0},
          sucursales: [],
        ).toJson(),
      };
    }
  }

  /// Obtiene un resumen consolidado de las estadísticas
  ///
  /// [useCache] - Indica si se debe usar el caché
  /// [forceRefresh] - Indica si se debe forzar la actualización del caché
  Future<Map<String, dynamic>> getResumenEstadisticas({
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      final Map<String, dynamic> estadisticasProductos =
          await getEstadisticasProductos(
        useCache: useCache,
        forceRefresh: forceRefresh,
      );

      final Map<String, dynamic> estadisticasVentas =
          await getEstadisticasVentas(
        useCache: useCache,
        forceRefresh: forceRefresh,
      );

      return <String, dynamic>{
        'status': 'success',
        'data': <String, dynamic>{
          'productos': estadisticasProductos['data'],
          'ventas': estadisticasVentas['data'],
        }
      };
    } catch (e) {
      Logger.error('Error al obtener resumen de estadísticas: $e');
      return <String, dynamic>{
        'status': 'error',
        'message': 'Error al obtener resumen de estadísticas',
        'data': const ResumenEstadisticas(
          productos: EstadisticasProductos(
              stockBajo: 0, liquidacion: 0, sucursales: []),
          ventas: EstadisticasVentas(
            ventas: {'hoy': 0, 'esteMes': 0},
            totalVentas: {'hoy': 0, 'esteMes': 0},
            sucursales: [],
          ),
        ).toJson(),
      };
    }
  }
}
