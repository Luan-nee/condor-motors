import 'package:flutter/foundation.dart';

import '../../models/marca.model.dart';
import '../main.api.dart';
import 'cache/fast_cache.dart';

class MarcasApi {
  final ApiClient _api;
  // Fast Cache para las operaciones de marcas
  final FastCache _cache = FastCache();
  
  MarcasApi(this._api);
  
  /// Obtiene todas las marcas
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<List<dynamic>> getMarcas({bool useCache = true}) async {
    try {
      const cacheKey = 'marcas_all';
      
      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final cachedData = _cache.get<List<dynamic>>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Marcas obtenidas desde caché');
          return cachedData;
        }
      }
      
      debugPrint('MarcasApi: Obteniendo lista de marcas');
      final response = await _api.authenticatedRequest(
        endpoint: '/marcas',
        method: 'GET',
      );
      
      debugPrint('MarcasApi: Respuesta de getMarcas recibida');
      debugPrint('MarcasApi: Estructura de respuesta: ${response.keys.toList()}');
      
      List<dynamic> items = [];
      
      // Manejar estructura anidada: response.data.data
      if (response['data'] is Map && response['data'].containsKey('data')) {
        debugPrint('MarcasApi: Encontrada estructura anidada en la respuesta');
        items = response['data']['data'] ?? [];
      } 
      // Si la estructura cambia en el futuro y ya no está anidada
      else {
        debugPrint('MarcasApi: Usando estructura directa de respuesta');
        items = response['data'] ?? [];
      }
      
      debugPrint('MarcasApi: Total de marcas encontradas: ${items.length}');
      
      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, items);
        debugPrint('✅ Marcas guardadas en caché');
      }
      
      return items;
    } catch (e) {
      debugPrint('MarcasApi: ERROR al obtener marcas: $e');
      rethrow;
    }
  }
  
  /// Obtiene todas las marcas como objetos [Marca]
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<List<Marca>> getMarcasObjetos({bool useCache = true}) async {
    try {
      final marcasRaw = await getMarcas(useCache: useCache);
      return marcasRaw.map((data) => Marca.fromJson(data)).toList();
    } catch (e) {
      debugPrint('MarcasApi: ERROR al obtener marcas como objetos: $e');
      rethrow;
    }
  }
  
  /// Obtiene una marca por su ID
  /// 
  /// El ID debe ser un string, aunque represente un número
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<Map<String, dynamic>> getMarca(String marcaId, {bool useCache = true}) async {
    try {
      // Validar que marcaId no sea nulo o vacío
      if (marcaId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de marca no puede estar vacío',
        );
      }
      
      final cacheKey = 'marca_$marcaId';
      
      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Marca obtenida desde caché: $cacheKey');
          return cachedData;
        }
      }
      
      debugPrint('MarcasApi: Obteniendo marca con ID: $marcaId');
      final response = await _api.authenticatedRequest(
        endpoint: '/marcas/$marcaId',
        method: 'GET',
      );
      
      debugPrint('MarcasApi: Respuesta de getMarca recibida');
      
      // Manejar estructura anidada
      Map<String, dynamic>? data;
      if (response['data'] is Map && response['data'].containsKey('data')) {
        data = response['data']['data'];
      } else {
        data = response['data'];
      }
      
      if (data == null) {
        throw ApiException(
          statusCode: 404,
          message: 'Marca no encontrada',
        );
      }
      
      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, data);
        debugPrint('✅ Marca guardada en caché: $cacheKey');
      }
      
      return data;
    } catch (e) {
      debugPrint('MarcasApi: ERROR al obtener marca #$marcaId: $e');
      rethrow;
    }
  }

  /// Obtiene una marca por su ID como objeto [Marca]
  Future<Marca> getMarcaObjeto(String marcaId, {bool useCache = true}) async {
    try {
      final marcaData = await getMarca(marcaId, useCache: useCache);
      return Marca.fromJson(marcaData);
    } catch (e) {
      debugPrint('MarcasApi: ERROR al obtener marca como objeto: $e');
      rethrow;
    }
  }
  
  /// Crea una nueva marca
  Future<Map<String, dynamic>> createMarca(Map<String, dynamic> marcaData) async {
    try {
      // Validar datos mínimos requeridos
      if (!marcaData.containsKey('nombre')) {
        throw ApiException(
          statusCode: 400,
          message: 'Nombre de marca es requerido',
        );
      }
      
      debugPrint('MarcasApi: Creando nueva marca: ${marcaData['nombre']}');
      final response = await _api.authenticatedRequest(
        endpoint: '/marcas',
        method: 'POST',
        body: marcaData,
      );
      
      debugPrint('MarcasApi: Respuesta de createMarca recibida');
      
      // Manejar estructura anidada
      Map<String, dynamic>? data;
      if (response['data'] is Map && response['data'].containsKey('data')) {
        data = response['data']['data'];
      } else {
        data = response['data'];
      }
      
      if (data == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Error al crear marca',
        );
      }
      
      // Invalidar caché de marcas
      _invalidateCache();
      
      return data;
    } catch (e) {
      debugPrint('MarcasApi: ERROR al crear marca: $e');
      rethrow;
    }
  }

  /// Crea una nueva marca usando un objeto [Marca]
  Future<Marca> createMarcaObjeto(Marca marca) async {
    try {
      final data = await createMarca(marca.toJson());
      return Marca.fromJson(data);
    } catch (e) {
      debugPrint('MarcasApi: ERROR al crear marca como objeto: $e');
      rethrow;
    }
  }
  
  /// Actualiza una marca existente
  /// 
  /// El ID debe ser un string, aunque represente un número
  Future<Map<String, dynamic>> updateMarca(String marcaId, Map<String, dynamic> marcaData) async {
    try {
      // Validar que marcaId no sea nulo o vacío
      if (marcaId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de marca no puede estar vacío',
        );
      }
      
      debugPrint('MarcasApi: Actualizando marca con ID: $marcaId');
      final response = await _api.authenticatedRequest(
        endpoint: '/marcas/$marcaId',
        method: 'PATCH',
        body: marcaData,
      );
      
      debugPrint('MarcasApi: Respuesta de updateMarca recibida');
      
      // Manejar estructura anidada
      Map<String, dynamic>? data;
      if (response['data'] is Map && response['data'].containsKey('data')) {
        data = response['data']['data'];
      } else {
        data = response['data'];
      }
      
      if (data == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Error al actualizar marca',
        );
      }
      
      // Invalidar caché
      _invalidateCache();
      _cache.invalidate('marca_$marcaId');
      
      return data;
    } catch (e) {
      debugPrint('MarcasApi: ERROR al actualizar marca #$marcaId: $e');
      rethrow;
    }
  }

  /// Actualiza una marca existente usando un objeto [Marca]
  Future<Marca> updateMarcaObjeto(Marca marca) async {
    try {
      final data = await updateMarca(marca.id.toString(), marca.toJson());
      return Marca.fromJson(data);
    } catch (e) {
      debugPrint('MarcasApi: ERROR al actualizar marca como objeto: $e');
      rethrow;
    }
  }
  
  /// Elimina una marca
  /// 
  /// El ID debe ser un string, aunque represente un número
  Future<void> deleteMarca(String marcaId) async {
    try {
      // Validar que marcaId no sea nulo o vacío
      if (marcaId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de marca no puede estar vacío',
        );
      }
      
      debugPrint('MarcasApi: Eliminando marca con ID: $marcaId');
      await _api.authenticatedRequest(
        endpoint: '/marcas/$marcaId',
        method: 'DELETE',
      );
      
      // Invalidar caché
      _invalidateCache();
      _cache.invalidate('marca_$marcaId');
      
      debugPrint('MarcasApi: Marca eliminada correctamente');
    } catch (e) {
      debugPrint('MarcasApi: ERROR al eliminar marca #$marcaId: $e');
      rethrow;
    }
  }
  
  /// Obtiene solo las marcas activas
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<List<dynamic>> getMarcasActivas({bool useCache = true}) async {
    try {
      const cacheKey = 'marcas_activas';
      
      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final cachedData = _cache.get<List<dynamic>>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Marcas activas obtenidas desde caché');
          return cachedData;
        }
      }
      
      debugPrint('MarcasApi: Obteniendo marcas activas');
      final response = await _api.authenticatedRequest(
        endpoint: '/marcas/activas',
        method: 'GET',
      );
      
      debugPrint('MarcasApi: Respuesta de getMarcasActivas recibida');
      
      List<dynamic> items = [];
      
      // Manejar estructura anidada
      if (response['data'] is Map && response['data'].containsKey('data')) {
        items = response['data']['data'] ?? [];
      } else {
        items = response['data'] ?? [];
      }
      
      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, items);
        debugPrint('✅ Marcas activas guardadas en caché');
      }
      
      return items;
    } catch (e) {
      debugPrint('MarcasApi: ERROR al obtener marcas activas: $e');
      rethrow;
    }
  }

  /// Obtiene solo las marcas activas como objetos [Marca]
  Future<List<Marca>> getMarcasActivasObjetos({bool useCache = true}) async {
    try {
      final marcasRaw = await getMarcasActivas(useCache: useCache);
      return marcasRaw.map((data) => Marca.fromJson(data)).toList();
    } catch (e) {
      debugPrint('MarcasApi: ERROR al obtener marcas activas como objetos: $e');
      rethrow;
    }
  }
  
  /// Invalidar caché de marcas
  void _invalidateCache() {
    _cache.invalidate('marcas_all');
    _cache.invalidate('marcas_activas');
    debugPrint('✅ Caché de marcas invalidada');
  }
  
  /// Método público para forzar refresco de caché
  void invalidateCache([String? marcaId]) {
    if (marcaId != null) {
      _cache.invalidate('marca_$marcaId');
      _invalidateCache();
      debugPrint('✅ Caché invalidada para marca: $marcaId');
    } else {
      _cache.clear();
      debugPrint('✅ Caché de marcas completamente invalidada');
    }
  }
}
