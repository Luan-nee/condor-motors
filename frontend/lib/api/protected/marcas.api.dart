import 'package:flutter/foundation.dart';

import '../../models/marca.model.dart';
import '../../models/paginacion.model.dart';
import '../main.api.dart';
import 'cache/fast_cache.dart';

/// Clase para gestionar las operaciones de API relacionadas con Marcas
class MarcasApi {
  final ApiClient _api;
  // Fast Cache para las operaciones de marcas
  final FastCache _cache = FastCache(maxSize: 50);
  
  // Prefijos para las claves de caché
  static const String _prefixListaMarcas = 'marcas_lista_';
  static const String _prefixMarca = 'marca_detalle_';
  
  MarcasApi(this._api);
  
  /// Obtiene todas las marcas con paginación opcional
  /// 
  /// [page] Número de página (1-based, default: 1)
  /// [pageSize] Tamaño de página (default: 10)
  /// [useCache] Indica si se debe usar el caché (default: true)
  /// [forceRefresh] Fuerza a obtener datos frescos del servidor (default: false)
  Future<ResultadoPaginado<Marca>> getMarcasPaginadas({
    int page = 1,
    int pageSize = 10,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Validar parámetros
      if (page < 1) page = 1;
      if (pageSize < 1) pageSize = 10;
      
      // Generar clave única para este conjunto de parámetros
      final cacheKey = '$_prefixListaMarcas${page}_$pageSize';
      
      // Forzar refresco del caché si es necesario
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }
      
      // Intentar obtener desde caché si useCache es true
      if (useCache && !forceRefresh) {
        final cachedData = _cache.get<ResultadoPaginado<Marca>>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ [MarcasApi] Marcas paginadas obtenidas desde caché: $cacheKey');
          return cachedData;
        }
      }
      
      debugPrint('🔄 [MarcasApi] Obteniendo lista de marcas paginada (página: $page, tamaño: $pageSize)');
      final response = await _api.authenticatedRequest(
        endpoint: '/marcas',
        method: 'GET',
        queryParams: {
          'page': page.toString(),
          'pageSize': pageSize.toString(),
        },
      );
      
      debugPrint('✅ [MarcasApi] Respuesta de getMarcasPaginadas recibida');
      
      // Extraer datos de la respuesta
      final data = response['data'];
      if (data == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Respuesta inesperada del servidor: falta campo "data"',
        );
      }
      
      // Extraer lista de marcas
      final List<dynamic> items = data['data'] ?? [];
      
      // Extraer información de paginación
      final paginationData = data['pagination'];
      if (paginationData == null) {
        debugPrint('⚠️ [MarcasApi] La respuesta no contiene información de paginación');
      }
      
      final int totalItems = paginationData?['total'] ?? items.length;
      final int currentPage = paginationData?['page'] ?? page;
      final int totalPages = paginationData?['totalPages'] ?? 1;
      final int actualPageSize = paginationData?['pageSize'] ?? pageSize;
      
      debugPrint('📊 [MarcasApi] Marcas recuperadas: ${items.length}, total: $totalItems, página: $currentPage de $totalPages');
      
      // Convertir a objetos Marca
      final List<Marca> marcas = items.map((item) {
        try {
          return Marca.fromJson(item);
        } catch (e) {
          debugPrint('⚠️ [MarcasApi] Error al convertir marca: $e');
          // Si hay un error en la conversión, lo ignoramos y continuamos
          return Marca(id: 0, nombre: 'Error');
        }
      }).where((marca) => marca.id > 0).toList();
      
      // Crear resultado paginado
      final resultado = ResultadoPaginado<Marca>(
        items: marcas,
        total: totalItems,
        page: currentPage,
        totalPages: totalPages,
        pageSize: actualPageSize,
      );
      
      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, resultado);
        debugPrint('✅ [MarcasApi] Marcas paginadas guardadas en caché: $cacheKey');
      }
      
      return resultado;
    } catch (e) {
      debugPrint('❌ [MarcasApi] ERROR al obtener marcas paginadas: $e');
      rethrow;
    }
  }
  
  /// Obtiene todas las marcas (sin paginación)
  /// 
  /// [useCache] Indica si se debe usar el caché (default: true)
  /// [forceRefresh] Fuerza a obtener datos frescos del servidor (default: false)
  Future<List<Marca>> getMarcas({
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Generar clave única
      const cacheKey = '${_prefixListaMarcas}todas';
      
      // Forzar refresco del caché si es necesario
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }
      
      // Intentar obtener desde caché si useCache es true
      if (useCache && !forceRefresh) {
        final cachedData = _cache.get<List<Marca>>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ [MarcasApi] Todas las marcas obtenidas desde caché');
          return cachedData;
        }
      }
      
      // Obtener todas las marcas a través de la paginación
      // Usando un tamaño de página grande para reducir peticiones
      final resultado = await getMarcasPaginadas(
        pageSize: 100, // Tamaño grande para obtener más marcas en una sola petición
        useCache: false, // No usar caché para la paginación interna
      );
      
      final marcas = resultado.items;
      
      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, marcas);
        debugPrint('✅ [MarcasApi] Todas las marcas guardadas en caché: ${marcas.length} elementos');
      }
      
      return marcas;
    } catch (e) {
      debugPrint('❌ [MarcasApi] ERROR al obtener todas las marcas: $e');
      rethrow;
    }
  }
  
  /// Obtiene una marca por su ID
  /// 
  /// [marcaId] ID de la marca a obtener
  /// [useCache] Indica si se debe usar el caché (default: true)
  /// [forceRefresh] Fuerza a obtener datos frescos del servidor (default: false)
  Future<Marca> getMarca(dynamic marcaId, {
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Validar que marcaId no sea nulo o vacío
      final id = marcaId.toString();
      if (id.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de marca no puede estar vacío',
        );
      }
      
      final cacheKey = '$_prefixMarca$id';
      
      // Forzar refresco del caché si es necesario
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }
      
      // Intentar obtener desde caché si useCache es true
      if (useCache && !forceRefresh) {
        final cachedData = _cache.get<Marca>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ [MarcasApi] Marca obtenida desde caché: $cacheKey');
          return cachedData;
        }
      }
      
      debugPrint('🔄 [MarcasApi] Obteniendo marca con ID: $id');
      final response = await _api.authenticatedRequest(
        endpoint: '/marcas/$id',
        method: 'GET',
      );
      
      debugPrint('✅ [MarcasApi] Respuesta de getMarca recibida');
      
      // Extraer datos de la respuesta
      final dynamic data = response['data'];
      if (data == null) {
        throw ApiException(
          statusCode: 404,
          message: 'Marca no encontrada',
        );
      }
      
      // Convertir a objeto Marca
      final Marca marca = Marca.fromJson(data);
      
      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, marca);
        debugPrint('✅ [MarcasApi] Marca guardada en caché: $cacheKey');
      }
      
      return marca;
    } catch (e) {
      debugPrint('❌ [MarcasApi] ERROR al obtener marca #$marcaId: $e');
      rethrow;
    }
  }

  /// Crea una nueva marca
  /// 
  /// [marcaData] Datos de la marca a crear
  Future<Marca> createMarca(Map<String, dynamic> marcaData) async {
    try {
      // Validar datos mínimos requeridos
      if (!marcaData.containsKey('nombre') || marcaData['nombre'].toString().isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'Nombre de marca es requerido',
        );
      }
      
      debugPrint('🔄 [MarcasApi] Creando nueva marca: ${marcaData['nombre']}');
      final response = await _api.authenticatedRequest(
        endpoint: '/marcas',
        method: 'POST',
        body: marcaData,
      );
      
      debugPrint('✅ [MarcasApi] Respuesta de createMarca recibida');
      
      // Extraer datos de la respuesta
      final dynamic data = response['data'];
      if (data == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Error al crear marca: respuesta inesperada del servidor',
        );
      }
      
      // Convertir a objeto Marca
      final Marca marca = Marca.fromJson(data);
      
      // Invalidar caché
      invalidateCache();
      
      return marca;
    } catch (e) {
      debugPrint('❌ [MarcasApi] ERROR al crear marca: $e');
      rethrow;
    }
  }

  /// Crea una nueva marca usando un objeto [Marca]
  /// 
  /// [marca] Objeto Marca con los datos a crear
  Future<Marca> createMarcaObjeto(Marca marca) async {
    return createMarca(marca.toJson());
  }
  
  /// Actualiza una marca existente
  /// 
  /// [marcaId] ID de la marca a actualizar
  /// [marcaData] Datos actualizados de la marca
  Future<Marca> updateMarca(dynamic marcaId, Map<String, dynamic> marcaData) async {
    try {
      // Validar que marcaId no sea nulo o vacío
      final id = marcaId.toString();
      if (id.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de marca no puede estar vacío',
        );
      }
      
      // Validar datos mínimos requeridos
      if (!marcaData.containsKey('nombre') || marcaData['nombre'].toString().isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'Nombre de marca es requerido',
        );
      }
      
      debugPrint('🔄 [MarcasApi] Actualizando marca con ID: $id');
      final response = await _api.authenticatedRequest(
        endpoint: '/marcas/$id',
        method: 'PATCH',
        body: marcaData,
      );
      
      debugPrint('✅ [MarcasApi] Respuesta de updateMarca recibida');
      
      // Extraer datos de la respuesta
      final dynamic data = response['data'];
      if (data == null) {
        throw ApiException(
          statusCode: 404,
          message: 'Marca no encontrada',
        );
      }
      
      // Convertir a objeto Marca
      final Marca marca = Marca.fromJson(data);
      
      // Invalidar caché específico y general
      _cache.invalidate('$_prefixMarca$id');
      invalidateCache();
      
      return marca;
    } catch (e) {
      debugPrint('❌ [MarcasApi] ERROR al actualizar marca #$marcaId: $e');
      rethrow;
    }
  }

  /// Actualiza una marca existente usando un objeto [Marca]
  /// 
  /// [marca] Objeto Marca con los datos actualizados
  Future<Marca> updateMarcaObjeto(Marca marca) async {
    return updateMarca(marca.id, marca.toJson());
  }
  
  /// Elimina una marca
  /// 
  /// [marcaId] ID de la marca a eliminar
  Future<bool> deleteMarca(dynamic marcaId) async {
    try {
      // Validar que marcaId no sea nulo o vacío
      final id = marcaId.toString();
      if (id.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de marca no puede estar vacío',
        );
      }
      
      debugPrint('🔄 [MarcasApi] Eliminando marca con ID: $id');
      final response = await _api.authenticatedRequest(
        endpoint: '/marcas/$id',
        method: 'DELETE',
      );
      
      debugPrint('✅ [MarcasApi] Marca eliminada correctamente');
      
      // Invalidar caché específico y general
      _cache.invalidate('$_prefixMarca$id');
      invalidateCache();
      
      return response['ok'] == true;
    } catch (e) {
      debugPrint('❌ [MarcasApi] ERROR al eliminar marca #$marcaId: $e');
      rethrow;
    }
  }
  
  /// Método público para invalidar el caché de marcas
  /// 
  /// [marcaId] ID opcional de la marca específica a invalidar
  void invalidateCache([String? marcaId]) {
    if (marcaId != null) {
      _cache.invalidate('$_prefixMarca$marcaId');
      debugPrint('✅ [MarcasApi] Caché invalidada para marca: $marcaId');
    }
    
    // Invalidar todas las listas de marcas
    _cache.invalidateByPattern(_prefixListaMarcas);
    debugPrint('✅ [MarcasApi] Caché de listas de marcas invalidada');
  }
  
  /// Método público para limpiar completamente el caché
  void clearCache() {
    _cache.clear();
    debugPrint('✅ [MarcasApi] Caché completamente limpiada');
  }
}
