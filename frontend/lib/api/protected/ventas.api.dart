import 'package:flutter/foundation.dart';
import '../main.api.dart';
import 'cache/fast_cache.dart';

class VentasApi {
  final ApiClient _api;
  final String _endpoint = '/ventas';
  final FastCache _cache = FastCache(maxSize: 75);
  
  // Prefijos para las claves de caché
  static const String _prefixListaVentas = 'ventas_lista_';
  static const String _prefixVenta = 'venta_detalle_';
  static const String _prefixEstadisticas = 'ventas_estadisticas_';
  
  VentasApi(this._api);
  
  /// Invalida el caché para una sucursal específica o para todas las sucursales
  /// 
  /// [sucursalId] - ID de la sucursal (opcional, si no se especifica invalida para todas las sucursales)
  void invalidateCache([String? sucursalId]) {
    if (sucursalId != null) {
      // Invalidar sólo las ventas de esta sucursal
      _cache.invalidateByPattern('$_prefixListaVentas$sucursalId');
      _cache.invalidateByPattern('$_prefixVenta$sucursalId');
      _cache.invalidateByPattern('$_prefixEstadisticas$sucursalId');
      debugPrint('🔄 Caché de ventas invalidado para sucursal $sucursalId');
    } else {
      // Invalidar todas las ventas en caché
      _cache.invalidateByPattern(_prefixListaVentas);
      _cache.invalidateByPattern(_prefixVenta);
      _cache.invalidateByPattern(_prefixEstadisticas);
      debugPrint('🔄 Caché de ventas invalidado completamente');
    }
    debugPrint('📊 Entradas en caché después de invalidación: ${_cache.size}');
  }
  
  // Listar ventas con paginación y filtros
  Future<Map<String, dynamic>> getVentas({
    int page = 1,
    int pageSize = 10,
    String? search,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? sucursalId,
    String? estado,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Generar clave de caché
      final String sucursalKey = sucursalId ?? 'global';
      final String fechaInicioStr = fechaInicio?.toIso8601String() ?? '';
      final String fechaFinStr = fechaFin?.toIso8601String() ?? '';
      final String searchStr = search ?? '';
      final String estadoStr = estado ?? '';
      
      final cacheKey = '${_prefixListaVentas}${sucursalKey}_p${page}_s${pageSize}_q${searchStr}_f${fechaInicioStr}_t${fechaFinStr}_e${estadoStr}';
      
      // Si se requiere forzar la recarga, invalidar la caché primero
      if (forceRefresh) {
        debugPrint('🔄 Forzando recarga de ventas para sucursal $sucursalId');
        if (sucursalId != null) {
          _cache.invalidate(cacheKey);
        } else {
          invalidateCache();
        }
      }
      
      // Intentar obtener desde caché si corresponde
      if (useCache && !forceRefresh) {
        final cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          debugPrint('🔍 Usando ventas en caché para sucursal $sucursalId (clave: $cacheKey)');
          return cachedData;
        }
      }
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      if (fechaInicio != null) {
        queryParams['fecha_inicio'] = fechaInicio.toIso8601String();
      }
      
      if (fechaFin != null) {
        queryParams['fecha_fin'] = fechaFin.toIso8601String();
      }
      
      if (estado != null && estado.isNotEmpty) {
        queryParams['estado'] = estado;
      }
      
      // Construir el endpoint de forma adecuada cuando se especifica la sucursal
      String endpoint = _endpoint;
      if (sucursalId != null && sucursalId.isNotEmpty) {
        // Ruta con sucursal: /api/{sucursalId}/ventas
        endpoint = '/$sucursalId/ventas';
        debugPrint('Solicitando ventas para sucursal específica: $endpoint');
      } else {
        // Ruta general: /api/ventas (sin sucursal específica)
        debugPrint('Solicitando ventas globales: $endpoint');
      }
      
      final response = await _api.authenticatedRequest(
        endpoint: endpoint,
        method: 'GET',
        queryParams: queryParams,
      );
      
      // Guardar en caché
      if (useCache) {
        _cache.set(cacheKey, response);
        debugPrint('💾 Guardadas ventas en caché (clave: $cacheKey)');
      }
      
      debugPrint('Respuesta de getVentas recibida: ${response.keys.toString()}');
      return response;
    } catch (e) {
      debugPrint('❌ Error al obtener ventas: $e');
      rethrow;
    }
  }
  
  // Obtener una venta específica
  Future<Map<String, dynamic>> getVenta(
    String id, {
    String? sucursalId,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Generar clave de caché
      final String sucursalKey = sucursalId ?? 'global';
      final cacheKey = '${_prefixVenta}${sucursalKey}_$id';
      
      // Si se requiere forzar la recarga, invalidar la caché primero
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }
      
      // Intentar obtener desde caché si corresponde
      if (useCache && !forceRefresh) {
        final cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          debugPrint('🔍 Usando venta en caché: $cacheKey');
          return cachedData;
        }
      }
      
      // Construir el endpoint según si hay sucursal o no
      String endpoint = _endpoint;
      if (sucursalId != null && sucursalId.isNotEmpty) {
        endpoint = '/$sucursalId/ventas';
      }
      
      final response = await _api.authenticatedRequest(
        endpoint: '$endpoint/$id',
        method: 'GET',
      );
      
      final data = response['data'];
      
      // Guardar en caché
      if (useCache) {
        _cache.set(cacheKey, data);
        debugPrint('💾 Guardada venta en caché: $cacheKey');
      }
      
      return data;
    } catch (e) {
      debugPrint('❌ Error al obtener venta: $e');
      rethrow;
    }
  }
  
  // Crear una nueva venta
  Future<Map<String, dynamic>> createVenta(Map<String, dynamic> ventaData, {String? sucursalId}) async {
    try {
      // Construir el endpoint según si hay sucursal o no
      String endpoint = _endpoint;
      if (sucursalId != null && sucursalId.isNotEmpty) {
        endpoint = '/$sucursalId/ventas';
      }
      
      final response = await _api.authenticatedRequest(
        endpoint: endpoint,
        method: 'POST',
        body: ventaData,
      );
      
      // Invalidar caché al crear una nueva venta
      if (sucursalId != null) {
        invalidateCache(sucursalId);
      } else {
        invalidateCache();
      }
      
      return response['data'];
    } catch (e) {
      debugPrint('❌ Error al crear venta: $e');
      rethrow;
    }
  }
  
  // Actualizar una venta existente
  Future<Map<String, dynamic>> updateVenta(String id, Map<String, dynamic> ventaData, {String? sucursalId}) async {
    try {
      // Construir el endpoint según si hay sucursal o no
      String endpoint = _endpoint;
      if (sucursalId != null && sucursalId.isNotEmpty) {
        endpoint = '/$sucursalId/ventas';
      }
      
      final response = await _api.authenticatedRequest(
        endpoint: '$endpoint/$id',
        method: 'PATCH',
        body: ventaData,
      );
      
      // Invalidar caché de esta venta específica
      final String sucursalKey = sucursalId ?? 'global';
      final cacheKey = '${_prefixVenta}${sucursalKey}_$id';
      _cache.invalidate(cacheKey);
      
      // También invalidar listas que podrían contener esta venta
      invalidateCache(sucursalId);
      
      return response['data'];
    } catch (e) {
      debugPrint('❌ Error al actualizar venta: $e');
      rethrow;
    }
  }
  
  // Cancelar una venta
  Future<bool> cancelarVenta(String id, String motivo, {String? sucursalId}) async {
    try {
      // Construir el endpoint según si hay sucursal o no
      String endpoint = _endpoint;
      if (sucursalId != null && sucursalId.isNotEmpty) {
        endpoint = '/$sucursalId/ventas';
      }
      
      await _api.authenticatedRequest(
        endpoint: '$endpoint/$id/cancel',
        method: 'POST',
        body: {
          'motivo': motivo
        },
      );
      
      // Invalidar caché relacionada
      invalidateCache(sucursalId);
      
      return true;
    } catch (e) {
      debugPrint('❌ Error al cancelar venta: $e');
      return false;
    }
  }
  
  // Anular una venta
  Future<bool> anularVenta(String id, String motivo, {String? sucursalId}) async {
    try {
      // Construir el endpoint según si hay sucursal o no
      String endpoint = _endpoint;
      if (sucursalId != null && sucursalId.isNotEmpty) {
        endpoint = '/$sucursalId/ventas';
      }
      
      await _api.authenticatedRequest(
        endpoint: '$endpoint/$id/anular',
        method: 'POST',
        body: {
          'motivo': motivo,
          'fecha_anulacion': DateTime.now().toIso8601String(),
        },
      );
      
      // Invalidar caché relacionada
      invalidateCache(sucursalId);
      
      return true;
    } catch (e) {
      debugPrint('❌ Error al anular venta: $e');
      return false;
    }
  }
  
  // Obtener estadísticas
  Future<Map<String, dynamic>> getEstadisticas({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? sucursalId,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Generar clave de caché
      final String sucursalKey = sucursalId ?? 'global';
      final String fechaInicioStr = fechaInicio?.toIso8601String() ?? '';
      final String fechaFinStr = fechaFin?.toIso8601String() ?? '';
      final cacheKey = '${_prefixEstadisticas}${sucursalKey}_f${fechaInicioStr}_t${fechaFinStr}';
      
      // Si se requiere forzar la recarga, invalidar la caché primero
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }
      
      // Intentar obtener desde caché si corresponde
      if (useCache && !forceRefresh) {
        final cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          debugPrint('🔍 Usando estadísticas en caché: $cacheKey');
          return cachedData;
        }
      }
      
      final queryParams = <String, String>{};
      
      if (fechaInicio != null) {
        queryParams['fecha_inicio'] = fechaInicio.toIso8601String();
      }
      
      if (fechaFin != null) {
        queryParams['fecha_fin'] = fechaFin.toIso8601String();
      }
      
      // Construir el endpoint según si hay sucursal o no
      String endpoint = '$_endpoint/estadisticas';
      if (sucursalId != null && sucursalId.isNotEmpty) {
        endpoint = '/$sucursalId/ventas/estadisticas';
      }
      
      final response = await _api.authenticatedRequest(
        endpoint: endpoint,
        method: 'GET',
        queryParams: queryParams,
      );
      
      // Guardar en caché
      if (useCache) {
        _cache.set(cacheKey, response);
        debugPrint('💾 Guardadas estadísticas en caché: $cacheKey');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Error al obtener estadísticas: $e');
      return {};
    }
  }
}