import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/cache/fast_cache.dart';
import 'package:condorsmotors/utils/logger.dart';

/// Clase para manejar las estadísticas de productos y ventas
class EstadisticasApi {
  final ApiClient _api;
  final String _endpoint = '/estadisticas';
  final FastCache _cache = FastCache(maxSize: 50);

  // Prefijos para las claves de caché
  static const String _prefixEstadisticasProductos = 'estadisticas_productos_';
  static const String _prefixEstadisticasVentas = 'estadisticas_ventas_';

  EstadisticasApi(this._api);

  /// Invalida el caché de estadísticas
  void invalidateCache() {
    _cache
      ..invalidateByPattern(_prefixEstadisticasProductos)
      ..invalidateByPattern(_prefixEstadisticasVentas);
    logCache('Caché de estadísticas invalidado');
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

      // Si se requiere forzar la recarga, invalidar la caché primero
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }

      // Intentar obtener desde caché si corresponde
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

      // Guardar en caché
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
        'data': <String, dynamic>{
          'stockBajo': 0,
          'liquidacion': 0,
          'sucursales': <Map<String, dynamic>>[]
        }
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

      // Si se requiere forzar la recarga, invalidar la caché primero
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }

      // Intentar obtener desde caché si corresponde
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

      // Guardar en caché
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
        'data': <String, dynamic>{
          'ventas': <String, dynamic>{
            'hoy': 0,
            'esteMes': 0,
          },
          'totalVentas': <String, dynamic>{
            'hoy': 0,
            'esteMes': 0,
          },
          'sucursales': <Map<String, dynamic>>[]
        }
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

      // Combinar las estadísticas
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
        'data': <String, dynamic>{
          'productos': <String, dynamic>{
            'stockBajo': 0,
            'liquidacion': 0,
            'sucursales': <Map<String, dynamic>>[]
          },
          'ventas': <String, dynamic>{
            'ventas': <String, dynamic>{
              'hoy': 0,
              'esteMes': 0,
            },
            'totalVentas': <String, dynamic>{
              'hoy': 0,
              'esteMes': 0,
            },
            'sucursales': <Map<String, dynamic>>[]
          }
        }
      };
    }
  }
}
