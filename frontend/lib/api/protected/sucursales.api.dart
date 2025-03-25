import 'package:flutter/foundation.dart';

import '../../models/sucursal.model.dart';
import '../main.api.dart';
import 'cache/fast_cache.dart';

class SucursalesApi {
  final ApiClient _api;
  final FastCache _cache = FastCache(maxSize: 30);
  
  // Prefijos para las claves de caché
  static const String _prefixSucursal = 'sucursal_';
  static const String _prefixSucursales = 'sucursales';
  static const String _prefixProformas = 'proformas_sucursal_';
  static const String _prefixNotificaciones = 'notificaciones_sucursal_';
  
  SucursalesApi(this._api);
  
  /// Invalida el caché para una sucursal específica o para todas las sucursales
  /// 
  /// [sucursalId] - ID de la sucursal (opcional, si no se especifica invalida para todas las sucursales)
  void invalidateCache([String? sucursalId]) {
    if (sucursalId != null) {
      // Invalidar sólo los datos de esta sucursal
      _cache.invalidate('$_prefixSucursal$sucursalId');
      _cache.invalidateByPattern('$_prefixProformas$sucursalId');
      _cache.invalidateByPattern('$_prefixNotificaciones$sucursalId');
      debugPrint('🔄 Caché invalidado para sucursal $sucursalId');
    } else {
      // Invalidar todas las sucursales en caché
      _cache.invalidateByPattern(_prefixSucursal);
      _cache.invalidate(_prefixSucursales);
      _cache.invalidateByPattern(_prefixProformas);
      _cache.invalidateByPattern(_prefixNotificaciones);
      debugPrint('🔄 Caché de sucursales invalidado completamente');
    }
    debugPrint('📊 Entradas en caché después de invalidación: ${_cache.size}');
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
      final cacheKey = '$_prefixSucursal$sucursalId';
      
      // Si se requiere forzar la recarga, invalidar la caché primero
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }
      
      // Intentar obtener desde caché si corresponde
      if (useCache && !forceRefresh) {
        final cachedData = _cache.get<Sucursal>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          debugPrint('🔍 Usando datos en caché para sucursal $sucursalId');
          return cachedData;
        }
      }
      
      debugPrint('SucursalesApi: Obteniendo datos de sucursal con ID: $sucursalId');
      final response = await _api.authenticatedRequest(
        endpoint: '/sucursales/$sucursalId',
        method: 'GET',
      );
      
      final sucursal = Sucursal.fromJson(response['data']);
      
      // Guardar en caché
      if (useCache) {
        _cache.set(cacheKey, sucursal);
        debugPrint('💾 Guardados datos de sucursal en caché: $sucursalId');
      }
      
      return sucursal;
    } catch (e) {
      debugPrint('❌ SucursalesApi: ERROR al obtener datos de sucursal #$sucursalId: $e');
      rethrow;
    }
  }
  
  /// Obtiene todas las sucursales
  Future<List<Sucursal>> getSucursales({
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = _prefixSucursales;
      
      // Si se requiere forzar la recarga, invalidar la caché primero
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }
      
      // Intentar obtener desde caché si corresponde
      if (useCache && !forceRefresh) {
        final cachedData = _cache.get<List<Sucursal>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          debugPrint('🔍 Usando lista de sucursales en caché');
          return cachedData;
        }
      }
      
      debugPrint('SucursalesApi: Obteniendo lista de sucursales');
      final response = await _api.authenticatedRequest(
        endpoint: '/sucursales',
        method: 'GET',
      );
      
      debugPrint('SucursalesApi: Respuesta de getSucursales recibida');
      
      // Manejar la respuesta y convertir los datos a objetos Sucursal
      final List<dynamic> rawData;
      
      // Manejar estructura anidada si es necesario
      if (response['data'] is Map && response['data'].containsKey('data')) {
        rawData = response['data']['data'] ?? [];
      } else {
        rawData = response['data'] ?? [];
      }
      
      // Convertir cada elemento en un objeto Sucursal
      final sucursales = rawData.map((item) => Sucursal.fromJson(item)).toList();
      
      // Guardar en caché
      if (useCache) {
        _cache.set(cacheKey, sucursales);
        debugPrint('💾 Guardada lista de sucursales en caché');
      }
      
      return sucursales;
    } catch (e) {
      debugPrint('❌ SucursalesApi: ERROR al obtener sucursales: $e');
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
      final cacheKey = '$_prefixProformas$sucursalId';
      
      // Si se requiere forzar la recarga, invalidar la caché primero
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }
      
      // Intentar obtener desde caché si corresponde
      if (useCache && !forceRefresh) {
        final cachedData = _cache.get<List<dynamic>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          debugPrint('🔍 Usando proformas en caché para sucursal $sucursalId');
          return cachedData;
        }
      }
      
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa',
        method: 'GET',
      );
      
      final proformas = response['data'] ?? [];
      
      // Guardar en caché
      if (useCache) {
        _cache.set(cacheKey, proformas);
        debugPrint('💾 Guardadas proformas en caché para sucursal $sucursalId');
      }
      
      return proformas;
    } catch (e) {
      debugPrint('❌ Error al obtener proformas de venta: $e');
      rethrow;
    }
  }
  
  /// Crea una nueva proforma de venta
  Future<Map<String, dynamic>> createProformaVenta(String sucursalId, Map<String, dynamic> proformaData) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa',
        method: 'POST',
        body: proformaData,
      );
      
      // Invalidar caché de proformas para esta sucursal
      _cache.invalidate('$_prefixProformas$sucursalId');
      debugPrint('🔄 Caché de proformas invalidado para sucursal $sucursalId');
      
      return response['data'];
    } catch (e) {
      debugPrint('❌ Error al crear proforma de venta: $e');
      rethrow;
    }
  }
  
  /// Actualiza una proforma de venta existente
  Future<Map<String, dynamic>> updateProformaVenta(String sucursalId, String proformaId, Map<String, dynamic> proformaData) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa/$proformaId',
        method: 'PATCH',
        body: proformaData,
      );
      
      // Invalidar caché de proformas para esta sucursal
      _cache.invalidate('$_prefixProformas$sucursalId');
      debugPrint('🔄 Caché de proformas invalidado para sucursal $sucursalId');
      
      return response['data'];
    } catch (e) {
      debugPrint('❌ Error al actualizar proforma de venta: $e');
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
      debugPrint('🔄 Caché de proformas invalidado para sucursal $sucursalId');
    } catch (e) {
      debugPrint('❌ Error al eliminar proforma de venta: $e');
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
      final cacheKey = '$_prefixNotificaciones$sucursalId';
      
      // Si se requiere forzar la recarga, invalidar la caché primero
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }
      
      // Intentar obtener desde caché si corresponde
      if (useCache && !forceRefresh) {
        final cachedData = _cache.get<List<dynamic>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          debugPrint('🔍 Usando notificaciones en caché para sucursal $sucursalId');
          return cachedData;
        }
      }
      
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/notificaciones',
        method: 'GET',
      );
      
      final notificaciones = response['data'] ?? [];
      
      // Guardar en caché
      if (useCache) {
        _cache.set(cacheKey, notificaciones);
        debugPrint('💾 Guardadas notificaciones en caché para sucursal $sucursalId');
      }
      
      return notificaciones;
    } catch (e) {
      debugPrint('❌ Error al obtener notificaciones: $e');
      rethrow;
    }
  }
  
  /// Elimina una notificación
  Future<void> deleteNotificacion(String sucursalId, String notificacionId) async {
    try {
      await _api.authenticatedRequest(
        endpoint: '/$sucursalId/notificaciones/$notificacionId',
        method: 'DELETE',
      );
      
      // Invalidar caché de notificaciones para esta sucursal
      _cache.invalidate('$_prefixNotificaciones$sucursalId');
      debugPrint('🔄 Caché de notificaciones invalidado para sucursal $sucursalId');
    } catch (e) {
      debugPrint('❌ Error al eliminar notificación: $e');
      rethrow;
    }
  }
  
  // SUCURSALES (operaciones generales)
  
  /// Obtiene todas las sucursales
  Future<List<Sucursal>> getAllSucursales({
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    // Este método utiliza la misma lógica que getSucursales
    return getSucursales(useCache: useCache, forceRefresh: forceRefresh);
  }
  
  /// Crea una nueva sucursal
  Future<Sucursal> createSucursal(Map<String, dynamic> sucursalData) async {
    try {
      debugPrint('SucursalesApi: Creando nueva sucursal: ${sucursalData['nombre']}');
      final response = await _api.authenticatedRequest(
        endpoint: '/sucursales',
        method: 'POST',
        body: sucursalData,
      );
      
      debugPrint('SucursalesApi: Respuesta de createSucursal recibida');
      
      // Convertir la respuesta en un objeto Sucursal
      final sucursal = Sucursal.fromJson(response['data']);
      
      // Invalidar caché de sucursales
      invalidateCache();
      
      return sucursal;
    } catch (e) {
      debugPrint('❌ SucursalesApi: ERROR al crear sucursal: $e');
      rethrow;
    }
  }
  
  /// Actualiza una sucursal existente
  Future<Sucursal> updateSucursal(String sucursalId, Map<String, dynamic> sucursalData) async {
    try {
      debugPrint('SucursalesApi: Actualizando sucursal con ID: $sucursalId');
      final response = await _api.authenticatedRequest(
        endpoint: '/sucursales/$sucursalId',
        method: 'PATCH',
        body: sucursalData,
      );
      
      debugPrint('SucursalesApi: Respuesta de updateSucursal recibida');
      
      // Convertir la respuesta en un objeto Sucursal
      final sucursal = Sucursal.fromJson(response['data']);
      
      // Invalidar caché de esta sucursal y lista de sucursales
      invalidateCache(sucursalId);
      _cache.invalidate(_prefixSucursales);
      
      return sucursal;
    } catch (e) {
      debugPrint('❌ SucursalesApi: ERROR al actualizar sucursal #$sucursalId: $e');
      rethrow;
    }
  }

  /// Elimina una sucursal
  Future<void> deleteSucursal(String sucursalId) async {
    try {
      debugPrint('SucursalesApi: Eliminando sucursal con ID: $sucursalId');
      await _api.authenticatedRequest(
        endpoint: '/sucursales/$sucursalId',
        method: 'DELETE',
      );
      
      debugPrint('SucursalesApi: Sucursal eliminada correctamente');
      
      // Invalidar caché de sucursales
      invalidateCache();
      
    } catch (e) {
      debugPrint('❌ SucursalesApi: ERROR al eliminar sucursal #$sucursalId: $e');
      rethrow;
    }
  }
} 