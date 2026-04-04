import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/cache/fast_cache.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:flutter/foundation.dart';

class SucursalesApi {
  final ApiClient _api;
  final FastCache _cache = FastCache(maxSize: 30);

  // Prefijos para las claves de caché
  static const String _prefixSucursal = 'sucursal_';
  static const String _prefixSucursales = 'sucursales';
  static const String _prefixProformas = 'proformas_sucursal_';
  static const String _prefixNotificaciones = 'notificaciones_sucursal_';
  static const String _prefixProductos = 'productos_sucursal_';
  static const String _prefixVentas = 'ventas_sucursal_';

  SucursalesApi(this._api);

  /// Invalida el caché para una sucursal específica o para todas las sucursales
  ///
  /// [sucursalId] - ID de la sucursal (opcional, si no se especifica invalida para todas las sucursales)
  void invalidateCache([String? sucursalId]) {
    if (sucursalId != null) {
      // Invalidar sólo los datos de esta sucursal
      _cache
        ..invalidate('$_prefixSucursal$sucursalId')
        ..invalidateByPattern('$_prefixProformas$sucursalId')
        ..invalidateByPattern('$_prefixNotificaciones$sucursalId')
        ..invalidateByPattern('$_prefixProductos$sucursalId')
        ..invalidateByPattern('$_prefixVentas$sucursalId');
      logCache('Caché invalidado para sucursal $sucursalId');
    } else {
      // Invalidar todas las sucursales en caché
      _cache
        ..invalidateByPattern(_prefixSucursal)
        ..invalidate(_prefixSucursales)
        ..invalidateByPattern(_prefixProformas)
        ..invalidateByPattern(_prefixNotificaciones)
        ..invalidateByPattern(_prefixProductos)
        ..invalidateByPattern(_prefixVentas);
      logCache('Caché de sucursales invalidado completamente');
    }
    logCache('Entradas en caché después de invalidación: ${_cache.size}');
  }

  /// Obtiene los datos específicos de una sucursal
  ///
  /// Este método obtiene información general sobre una sucursal específica
  Future<Sucursal> getSucursalData(
    String sucursalId, {
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      final String cacheKey = '$_prefixSucursal$sucursalId';

      // Si se requiere forzar la recarga, invalidar la caché primero
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }

      // Intentar obtener desde caché si corresponde
      if (useCache && !forceRefresh) {
        final Sucursal? cachedData = _cache.get<Sucursal>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          logCache('Usando datos en caché para sucursal $sucursalId');
          return cachedData;
        }
      }

      logCache(
          'SucursalesApi: Obteniendo datos de sucursal con ID: $sucursalId');
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/sucursales/$sucursalId',
        method: 'GET',
      );

      final Sucursal sucursal = Sucursal.fromJson(response['data']);

      // Guardar en caché
      if (useCache) {
        _cache.set(cacheKey, sucursal);
        logCache('Guardados datos de sucursal en caché: $sucursalId');
      }

      return sucursal;
    } catch (e) {
      logCache(
          'SucursalesApi: ERROR al obtener datos de sucursal #$sucursalId: $e');
      rethrow;
    }
  }

  /// Obtiene todas las sucursales
  Future<List<Sucursal>> getSucursales({
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Si se requiere forzar la recarga, invalidar la caché primero
      if (forceRefresh) {
        Logger.debug('Forzando recarga de sucursales');
        invalidateCache();
      }

      // Generar clave de caché
      const String cacheKey = 'sucursales';

      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final List<Sucursal>? cachedData = _cache.get<List<Sucursal>>(cacheKey);
        if (cachedData != null) {
          logCache('Sucursales obtenidas desde caché: $cacheKey');
          return cachedData;
        }
      }

      // Si no hay caché o useCache es false, obtener desde la API
      Logger.debug('Obteniendo sucursales desde la API');

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/sucursales',
        method: 'GET',
      );

      debugPrint('SucursalesApi: Respuesta de getSucursales recibida');

      // Manejar la respuesta y convertir los datos a objetos Sucursal
      final List<dynamic> rawData;

      // Manejar estructura anidada si es necesario
      if (response['data'] is Map && response['data'].containsKey('data')) {
        rawData = response['data']['data'] ?? <dynamic>[];
      } else {
        rawData = response['data'] ?? <dynamic>[];
      }

      // Convertir cada elemento en un objeto Sucursal
      final List<Sucursal> sucursales =
          rawData.map((item) => Sucursal.fromJson(item)).toList();

      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, sucursales);
        logCache('Sucursales guardadas en caché: $cacheKey');
      }

      return sucursales;
    } catch (e) {
      Logger.error('SucursalesApi: ERROR al obtener sucursales: $e');
      rethrow;
    }
  }

  // PROFORMAS DE VENTA

  /// Obtiene todas las proformas de venta de la sucursal
  Future<List<dynamic>> getProformasVenta(
    String sucursalId, {
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      final String cacheKey = '$_prefixProformas$sucursalId';

      // Si se requiere forzar la recarga, invalidar la caché primero
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }

      // Intentar obtener desde caché si corresponde
      if (useCache && !forceRefresh) {
        final List? cachedData = _cache.get<List<dynamic>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          logCache('Usando proformas en caché para sucursal $sucursalId');
          return cachedData;
        }
      }

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa',
        method: 'GET',
      );

      final proformas = response['data'] ?? <dynamic>[];

      // Guardar en caché
      if (useCache) {
        _cache.set(cacheKey, proformas);
        logCache('Guardadas proformas en caché para sucursal $sucursalId');
      }

      return proformas;
    } catch (e) {
      logCache(' Error al obtener proformas de venta: $e');
      rethrow;
    }
  }

  /// Crea una nueva proforma de venta
  Future<Map<String, dynamic>> createProformaVenta(
      String sucursalId, Map<String, dynamic> proformaData) async {
    try {
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa',
        method: 'POST',
        body: proformaData,
      );

      // Invalidar caché de proformas para esta sucursal
      _cache.invalidate('$_prefixProformas$sucursalId');
      logCache('Caché de proformas invalidado para sucursal $sucursalId');

      return response['data'];
    } catch (e) {
      logCache(' Error al crear proforma de venta: $e');
      rethrow;
    }
  }

  /// Actualiza una proforma de venta existente
  Future<Map<String, dynamic>> updateProformaVenta(String sucursalId,
      String proformaId, Map<String, dynamic> proformaData) async {
    try {
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa/$proformaId',
        method: 'PATCH',
        body: proformaData,
      );

      // Invalidar caché de proformas para esta sucursal
      _cache.invalidate('$_prefixProformas$sucursalId');
      logCache('Caché de proformas invalidado para sucursal $sucursalId');

      return response['data'];
    } catch (e) {
      logCache(' Error al actualizar proforma de venta: $e');
      rethrow;
    }
  }

  /// Elimina una proforma de venta
  Future<void> deleteProformaVenta(String sucursalId, String proformaId) async {
    try {
      await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa/$proformaId',
        method: 'DELETE',
      );

      // Invalidar caché de proformas para esta sucursal
      _cache.invalidate('$_prefixProformas$sucursalId');
      logCache('Caché de proformas invalidado para sucursal $sucursalId');
    } catch (e) {
      logCache(' Error al eliminar proforma de venta: $e');
      rethrow;
    }
  }

  // NOTIFICACIONES

  /// Obtiene todas las notificaciones de la sucursal
  Future<List<dynamic>> getNotificaciones(
    String sucursalId, {
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      final String cacheKey = '$_prefixNotificaciones$sucursalId';

      // Si se requiere forzar la recarga, invalidar la caché primero
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }

      // Intentar obtener desde caché si corresponde
      if (useCache && !forceRefresh) {
        final List? cachedData = _cache.get<List<dynamic>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          logCache('Usando notificaciones en caché para sucursal $sucursalId');
          return cachedData;
        }
      }

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/notificaciones',
        method: 'GET',
      );

      final notificaciones = response['data'] ?? <dynamic>[];

      // Guardar en caché
      if (useCache) {
        _cache.set(cacheKey, notificaciones);
        logCache(
            'Guardadas notificaciones en caché para sucursal $sucursalId');
      }

      return notificaciones;
    } catch (e) {
      logCache(' Error al obtener notificaciones: $e');
      rethrow;
    }
  }

  /// Elimina una notificación
  Future<void> deleteNotificacion(
      String sucursalId, String notificacionId) async {
    try {
      await _api.authenticatedRequest(
        endpoint: '/$sucursalId/notificaciones/$notificacionId',
        method: 'DELETE',
      );

      // Invalidar caché de notificaciones para esta sucursal
      _cache.invalidate('$_prefixNotificaciones$sucursalId');
      logCache('Caché de notificaciones invalidado para sucursal $sucursalId');
    } catch (e) {
      logCache(' Error al eliminar notificación: $e');
      rethrow;
    }
  }

  // SUCURSALES (operaciones generales)

  /// Obtiene todas las sucursales
  Future<List<Sucursal>> getAllSucursales({
    bool useCache = true,
    bool forceRefresh = false,
  }) {
    // Este método utiliza la misma lógica que getSucursales
    return getSucursales(useCache: useCache, forceRefresh: forceRefresh);
  }

  /// Crea una nueva sucursal
  Future<Sucursal> createSucursal(Map<String, dynamic> sucursalData) async {
    try {
      logCache(
          'SucursalesApi: Creando nueva sucursal: ${sucursalData['nombre']}');

      // Las validaciones de negocio deben estar en el Repository, no en la API

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/sucursales',
        method: 'POST',
        body: sucursalData,
      );

      final Sucursal sucursal = Sucursal.fromJson(response['data']);
      invalidateCache();

      logCache('Sucursal creada exitosamente: ${sucursal.nombre}');
      return sucursal;
    } catch (e) {
      logCache(' SucursalesApi: ERROR al crear sucursal: $e');
      rethrow;
    }
  }

  /// Actualiza una sucursal existente
  Future<Sucursal> updateSucursal(
      String sucursalId, Map<String, dynamic> sucursalData) async {
    try {
      logCache('SucursalesApi: Actualizando sucursal con ID: $sucursalId');

      // Las validaciones de negocio deben estar en el Repository, no en la API

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/sucursales/$sucursalId',
        method: 'PATCH',
        body: sucursalData,
      );

      final Sucursal sucursal = Sucursal.fromJson(response['data']);
      invalidateCache(sucursalId);

      logCache('Sucursal actualizada exitosamente: ${sucursal.nombre}');
      return sucursal;
    } catch (e) {
      logCache('SucursalesApi: ERROR al actualizar sucursal #$sucursalId: $e');
      rethrow;
    }
  }

  /// Elimina una sucursal
  Future<void> deleteSucursal(String sucursalId) async {
    try {
      logCache('SucursalesApi: Eliminando sucursal con ID: $sucursalId');
      await _api.authenticatedRequest(
        endpoint: '/sucursales/$sucursalId',
        method: 'DELETE',
      );

      invalidateCache();
      logCache('SucursalesApi: Sucursal eliminada correctamente');
    } catch (e) {
      logCache(' SucursalesApi: ERROR al eliminar sucursal #$sucursalId: $e');
      rethrow;
    }
  }

  // ENDPOINTS ESPECÍFICOS POR SUCURSAL

  /// Obtiene los productos de una sucursal
  Future<List<dynamic>> getProductosSucursal(
    String sucursalId, {
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      final String cacheKey = '$_prefixProductos$sucursalId';

      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }

      if (useCache && !forceRefresh) {
        final List? cachedData = _cache.get<List<dynamic>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          return cachedData;
        }
      }

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos',
        method: 'GET',
      );

      final productos = response['data'] ?? <dynamic>[];

      if (useCache) {
        _cache.set(cacheKey, productos);
      }

      return productos;
    } catch (e) {
      logCache(' Error al obtener productos de sucursal: $e');
      rethrow;
    }
  }

  /// Registra entrada de inventario
  Future<Map<String, dynamic>> registrarEntradaInventario(
      String sucursalId, Map<String, dynamic> entradaData) async {
    try {
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/inventarios/entradas',
        method: 'POST',
        body: entradaData,
      );

      _cache.invalidate('$_prefixProductos$sucursalId');
      return response['data'];
    } catch (e) {
      logCache(' Error al registrar entrada de inventario: $e');
      rethrow;
    }
  }

  /// Obtiene información de ventas
  Future<Map<String, dynamic>> getInformacionVentas(String sucursalId) async {
    try {
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/ventas/informacion',
        method: 'GET',
      );

      return response['data'];
    } catch (e) {
      logCache(' Error al obtener información de ventas: $e');
      rethrow;
    }
  }

  /// Declara facturación
  Future<Map<String, dynamic>> declararFacturacion(
      String sucursalId, Map<String, dynamic> declaracionData) async {
    try {
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/facturacion/declarar',
        method: 'POST',
        body: declaracionData,
      );

      return response['data'];
    } catch (e) {
      logCache(' Error al declarar facturación: $e');
      rethrow;
    }
  }

  /// Sincroniza facturación
  Future<Map<String, dynamic>> sincronizarFacturacion(
      String sucursalId, Map<String, dynamic> sincronizacionData) async {
    try {
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/facturacion/consultar',
        method: 'POST',
        body: sincronizacionData,
      );

      return response['data'];
    } catch (e) {
      logCache(' Error al sincronizar facturación: $e');
      rethrow;
    }
  }
}
