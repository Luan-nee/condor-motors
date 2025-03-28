import 'package:flutter/foundation.dart';

import '../../models/movimiento.model.dart';
import '../main.api.dart';
import 'cache/fast_cache.dart';

class MovimientosApi {
  final ApiClient _api;
  final String _endpoint = '/transferenciasInventario';
  final FastCache _cache = FastCache(maxSize: 75);
  
  // Prefijos para las claves de caché
  static const String _prefixListaMovimientos = 'transferencias_lista_';
  static const String _prefixMovimiento = 'transferencia_detalle_';
  
  MovimientosApi(this._api);
  
  // Estados de movimientos para mostrar en la UI
  static const Map<String, String> estadosDetalle = {
    'PENDIENTE': 'Pendiente',
    'EN_PROCESO': 'En Proceso',
    'EN_TRANSITO': 'En Tránsito',
    'ENTREGADO': 'Entregado',
    'COMPLETADO': 'Completado',
  };
  
  /// Invalida el caché de transferencias, opcionalmente para una sucursal específica
  void invalidateCache([String? sucursalId]) {
    if (sucursalId != null) {
      // Invalidar sólo las transferencias de esta sucursal
      _cache.invalidateByPattern('$_prefixListaMovimientos$sucursalId');
      _cache.invalidateByPattern('$_prefixMovimiento$sucursalId');
      debugPrint('🔄 Caché de transferencias invalidado para sucursal $sucursalId');
    } else {
      // Invalidar todas las transferencias en caché
      _cache.invalidateByPattern(_prefixListaMovimientos);
      _cache.invalidateByPattern(_prefixMovimiento);
      debugPrint('🔄 Caché de transferencias invalidado completamente');
    }
    debugPrint('📊 Entradas en caché después de invalidación: ${_cache.size}');
  }
  
  // Obtener todas las transferencias de inventario
  Future<List<Movimiento>> getMovimientos({
    String? sucursalId,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Generar clave única para este conjunto de parámetros
      final cacheKey = _prefixListaMovimientos + [
        sucursalId ?? 'all',
        estado ?? 'all',
        fechaInicio?.toIso8601String().split('T')[0] ?? 'all',
        fechaFin?.toIso8601String().split('T')[0] ?? 'all',
      ].join('_');
      
      // Forzar refresco del caché si es necesario
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }
      
      // Intentar obtener desde caché si useCache es true
      if (useCache && !forceRefresh) {
        final cachedData = _cache.get<List<Movimiento>>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Transferencias obtenidas desde caché: $cacheKey');
          return cachedData;
        }
      }
      
      final queryParams = <String, String>{};
      
      if (sucursalId != null) {
        queryParams['sucursal_id'] = sucursalId;
      }
      
      if (estado != null) {
        queryParams['estado'] = estado;
      }
      
      if (fechaInicio != null) {
        queryParams['fecha_inicio'] = fechaInicio.toIso8601String();
      }
      
      if (fechaFin != null) {
        queryParams['fecha_fin'] = fechaFin.toIso8601String();
      }
      
      debugPrint('🔄 [MovimientosApi] Obteniendo lista de transferencias: $_endpoint');

      // Añadir un timeout a la solicitud para evitar esperas indefinidas
      final response = await _api.authenticatedRequest(
        endpoint: _endpoint,
        method: 'GET',
        queryParams: queryParams,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('⏱️ [MovimientosApi] Timeout al obtener lista de transferencias');
          throw ApiException(
            message: 'Tiempo de espera agotado al obtener transferencias',
            statusCode: 408,
          );
        },
      );
      
      debugPrint('🔄 [MovimientosApi] Respuesta recibida, procesando datos...');
      
      final List<dynamic> rawData = response['data'] ?? [];
      final List<Movimiento> movimientos = [];
      
      // Procesar cada movimiento con manejo de errores
      for (final item in rawData) {
        try {
          final movimiento = Movimiento.fromJson(item);
          movimientos.add(movimiento);
        } catch (e) {
          debugPrint('⚠️ [MovimientosApi] Error al procesar transferencia: $e');
          // Continuar con el siguiente item
        }
      }
      
      debugPrint('✅ [MovimientosApi] ${movimientos.length} transferencias procesadas');
      
      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, movimientos);
        debugPrint('✅ Transferencias guardadas en caché: $cacheKey');
      }
      
      return movimientos;
    } catch (e) {
      debugPrint('❌ [MovimientosApi] Error al obtener transferencias: $e');
      rethrow;
    }
  }
  
  // Obtener una transferencia específica
  Future<Movimiento> getMovimiento(String id, {bool useCache = true}) async {
    try {
      final cacheKey = '$_prefixMovimiento$id';
      
      debugPrint('🔍 [MovimientosApi] Inicio de getMovimiento para ID: $id (useCache: $useCache)');
      
      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final cachedData = _cache.get<Movimiento>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ [MovimientosApi] Transferencia obtenida desde caché: $cacheKey');
          return cachedData;
        }
      }
      
      debugPrint('🔄 [MovimientosApi] Obteniendo transferencia desde API: $_endpoint/$id');
      
      // Añadir un timeout a la solicitud para evitar esperas indefinidas
      final response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id',
        method: 'GET',
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('⏱️ [MovimientosApi] Timeout al obtener transferencia con ID: $id');
          throw ApiException(
            message: 'Tiempo de espera agotado al obtener detalles de la transferencia',
            statusCode: 408,
          );
        },
      );
      
      debugPrint('🔄 [MovimientosApi] Respuesta recibida para transferencia $id');
      
      // Verificar que la respuesta no sea nula
      if (response == null) {
        debugPrint('❌ [MovimientosApi] Respuesta nula para transferencia $id');
        throw ApiException(
          message: 'Respuesta nula del servidor',
          statusCode: 500,
        );
      }
      
      // La respuesta puede venir con o sin el campo 'data'
      Map<String, dynamic> responseData;
      
      if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          debugPrint('📦 [MovimientosApi] Respuesta contiene campo "data"');
          responseData = Map<String, dynamic>.from(response['data']);
        } else {
          debugPrint('📦 [MovimientosApi] Respuesta sin campo "data", usando respuesta directa');
          responseData = Map<String, dynamic>.from(response);
        }
        
        // Asegurar que el ID esté presente en los datos
        if (!responseData.containsKey('id')) {
          debugPrint('⚠️ [MovimientosApi] ID no encontrado en los datos, añadiendo manualmente');
          responseData['id'] = id;
        }
        
        // Verificar si la respuesta tiene productos o itemsVenta
        if (responseData.containsKey('productos')) {
          final productos = responseData['productos'] as List?;
          debugPrint('📦 [MovimientosApi] Respuesta contiene campo "productos": ${productos?.length ?? 0} items');
          if (productos != null && productos.isNotEmpty) {
            debugPrint('📦 [MovimientosApi] Primer producto: ${productos.first}');
          }
        } else if (responseData.containsKey('itemsVenta')) {
          final itemsVenta = responseData['itemsVenta'] as List?;
          debugPrint('📦 [MovimientosApi] Respuesta contiene campo "itemsVenta": ${itemsVenta?.length ?? 0} items');
          if (itemsVenta != null && itemsVenta.isNotEmpty) {
            debugPrint('📦 [MovimientosApi] Primer itemVenta: ${itemsVenta.first}');
          }
        } else {
          debugPrint('⚠️ [MovimientosApi] No se encontraron productos ni itemsVenta en la respuesta');
        }
      } else {
        debugPrint('⚠️ [MovimientosApi] Respuesta no es un mapa: ${response.runtimeType}');
        throw ApiException(
          message: 'Formato de respuesta inválido',
          statusCode: 500,
        );
      }
      
      debugPrint('📊 [MovimientosApi] Datos a convertir: ${responseData.keys.toList()}');
      
      try {
        // Convertir a objeto Movimiento
        final Movimiento movimiento = Movimiento.fromJson(responseData);
        
        // Verificar si se obtuvieron productos
        if (movimiento.productos != null) {
          debugPrint('✅ [MovimientosApi] Transferencia convertida con ${movimiento.productos!.length} productos');
        } else {
          debugPrint('⚠️ [MovimientosApi] Transferencia convertida sin productos');
        }
        
        // Guardar en caché si useCache es true
        if (useCache) {
          _cache.set(cacheKey, movimiento);
          debugPrint('✅ [MovimientosApi] Transferencia guardada en caché: $cacheKey');
        }
        
        return movimiento;
      } catch (e) {
        debugPrint('❌ [MovimientosApi] Error al convertir respuesta a Movimiento: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ [MovimientosApi] Error al obtener transferencia de inventario: $e');
      rethrow;
    }
  }
  
  // Crear una nueva transferencia de inventario
  Future<Movimiento> createMovimiento(Map<String, dynamic> movimientoData) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: _endpoint,
        method: 'POST',
        body: movimientoData,
      );
      
      // Invalidar el caché después de crear una nueva transferencia
      invalidateCache(movimientoData['sucursal_origen_id'] as String?);
      invalidateCache(movimientoData['sucursal_destino_id'] as String?);
      
      return Movimiento.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error al crear transferencia de inventario: $e');
      rethrow;
    }
  }
  
  // Actualizar una transferencia existente
  Future<Movimiento> updateMovimiento(String id, Map<String, dynamic> movimientoData) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id',
        method: 'PATCH',
        body: movimientoData,
      );
      
      // Invalidar el caché después de actualizar
      invalidateCache(movimientoData['sucursal_origen_id'] as String?);
      invalidateCache(movimientoData['sucursal_destino_id'] as String?);
      _cache.invalidate('$_prefixMovimiento$id');
      
      return Movimiento.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error al actualizar transferencia de inventario: $e');
      rethrow;
    }
  }
  
  // Cambiar el estado de una transferencia
  Future<Movimiento> cambiarEstado(String id, String nuevoEstado, {String? observacion}) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id/estado',
        method: 'PATCH',
        body: {
          'estado': nuevoEstado,
          if (observacion != null) 'observacion': observacion,
        },
      );
      
      // Invalidar el caché después de cambiar el estado
      _cache.invalidate('$_prefixMovimiento$id');
      _cache.invalidateByPattern(_prefixListaMovimientos);
      
      return Movimiento.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error al cambiar estado de la transferencia: $e');
      rethrow;
    }
  }
  
  // Cancelar una transferencia
  Future<bool> cancelarMovimiento(String id, String motivo) async {
    try {
      await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id/cancelar',
        method: 'POST',
        body: {
          'motivo': motivo,
        },
      );
      
      // Invalidar el caché después de cancelar
      _cache.invalidate('$_prefixMovimiento$id');
      _cache.invalidateByPattern(_prefixListaMovimientos);
      
      return true;
    } catch (e) {
      debugPrint('Error al cancelar transferencia de inventario: $e');
      return false;
    }
  }
}
