import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/cache/fast_cache.dart';
import 'package:condorsmotors/models/categoria.model.dart';
import 'package:flutter/foundation.dart';

class CategoriasApi {
  final ApiClient _api;
  final String _endpoint = '/categorias';
  // Fast Cache para las operaciones de categorías
  final FastCache _cache = FastCache();
  
  CategoriasApi(this._api);
  
  /// Obtiene todas las categorías
  /// 
  /// Ordenadas alfabéticamente por nombre
  /// [useCache] Indica si se debe usar el caché (default: true)
  /// 
  /// La respuesta incluye el campo `totalProductos` que indica la cantidad de
  /// productos asociados a cada categoría.
  Future<List<dynamic>> getCategorias({bool useCache = true}) async {
    try {
      const String cacheKey = 'categorias_all';
      
      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final List? cachedData = _cache.get<List<dynamic>>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Categorías obtenidas desde caché');
          return cachedData;
        }
      }
      
      debugPrint('CategoriasApi: Obteniendo categorías');
      
      final Map<String, String> queryParams = <String, String>{
        'sort_by': 'nombre',
      };
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: _endpoint,
        method: 'GET',
        queryParams: queryParams,
      );
      
      debugPrint('CategoriasApi: Respuesta recibida, status: ${response['status']}');
      
      // Verificar estructura de respuesta
      if (response['data'] == null) {
        debugPrint('CategoriasApi: La respuesta no contiene datos');
        return <List<dynamic>>[];
      }
      
      if (response['data'] is! List) {
        debugPrint('CategoriasApi: Formato de datos inesperado. Recibido: ${response['data'].runtimeType}');
        return <List<dynamic>>[];
      }
      
      final List categorias = response['data'] as List;
      debugPrint('CategoriasApi: ${categorias.length} categorías encontradas');
      
      // Información adicional sobre totalProductos
      int totalProductosGlobal = 0;
      for (final cat in categorias) {
        if (cat is Map && cat.containsKey('totalProductos')) {
          totalProductosGlobal += (cat['totalProductos'] as int? ?? 0);
        }
      }
      debugPrint('CategoriasApi: Total de productos en todas las categorías: $totalProductosGlobal');
      
      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, categorias);
        debugPrint('✅ Categorías guardadas en caché');
      }
      
      return categorias;
    } catch (e) {
      debugPrint('CategoriasApi: Error al obtener categorías: $e');
      // Capturar más detalles sobre el error
      if (e is ApiException) {
        debugPrint('CategoriasApi: Código de error: ${e.statusCode}, Mensaje: ${e.message}');
        if (e.data != null) {
          debugPrint('CategoriasApi: Datos adicionales del error: ${e.data}');
        }
      }
      rethrow;
    }
  }
  
  /// Obtiene todas las categorías como objetos [Categoria]
  /// 
  /// Ordenadas alfabéticamente por nombre
  /// [useCache] Indica si se debe usar el caché (default: true)
  /// 
  /// La respuesta incluye el campo `totalProductos` que indica la cantidad de
  /// productos asociados a cada categoría.
  Future<List<Categoria>> getCategoriasObjetos({bool useCache = true}) async {
    try {
      final List categoriasRaw = await getCategorias(useCache: useCache);
      final List<Categoria> categorias = categoriasRaw.map((data) => Categoria.fromJson(data)).toList();
      
      // Ordenar categorías por nombre (extra)
      categorias.sort((Categoria a, Categoria b) => a.nombre.compareTo(b.nombre));
      
      return categorias;
    } catch (e) {
      debugPrint('CategoriasApi: ERROR al obtener categorías como objetos: $e');
      rethrow;
    }
  }
  
  /// Crea una nueva categoría
  /// 
  /// [nombre] Nombre de la categoría
  /// [descripcion] Descripción opcional de la categoría
  Future<Map<String, dynamic>> createCategoria({
    required String nombre,
    String? descripcion,
  }) async {
    try {
      debugPrint('CategoriasApi: Creando nueva categoría: $nombre');
      
      final Map<String, dynamic> body = <String, dynamic>{
        'nombre': nombre,
      };
      
      if (descripcion != null) {
        body['descripcion'] = descripcion;
      }
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: _endpoint,
        method: 'POST',
        body: body,
      );
      
      debugPrint('CategoriasApi: Categoría creada con éxito');
      
      // Invalidar caché de categorías
      _invalidateCache();
      
      return response['data'];
    } catch (e) {
      debugPrint('CategoriasApi: Error al crear categoría: $e');
      // Capturar más detalles sobre el error
      if (e is ApiException) {
        debugPrint('CategoriasApi: Código de error: ${e.statusCode}, Mensaje: ${e.message}');
        if (e.data != null) {
          debugPrint('CategoriasApi: Datos adicionales del error: ${e.data}');
        }
      }
      rethrow;
    }
  }
  
  /// Crea una nueva categoría usando un objeto [Categoria]
  Future<Categoria> createCategoriaObjeto(Categoria categoria) async {
    try {
      final Map<String, dynamic> data = await createCategoria(
        nombre: categoria.nombre,
        descripcion: categoria.descripcion,
      );
      return Categoria.fromJson(data);
    } catch (e) {
      debugPrint('CategoriasApi: ERROR al crear categoría como objeto: $e');
      rethrow;
    }
  }
  
  /// Actualiza una categoría existente
  /// 
  /// [id] ID de la categoría a actualizar
  /// [nombre] Nuevo nombre de la categoría (opcional)
  /// [descripcion] Nueva descripción de la categoría (opcional)
  Future<Map<String, dynamic>> updateCategoria({
    required String id,
    String? nombre,
    String? descripcion,
  }) async {
    try {
      debugPrint('CategoriasApi: Actualizando categoría con ID: $id');
      
      // Construir el cuerpo de la solicitud solo con los campos que se van a actualizar
      final Map<String, dynamic> body = <String, dynamic>{};
      
      if (nombre != null) {
        body['nombre'] = nombre;
      }
      
      if (descripcion != null) {
        body['descripcion'] = descripcion;
      }
      
      // Si no hay campos para actualizar, lanzar un error
      if (body.isEmpty) {
        throw Exception('Debe proporcionar al menos un campo para actualizar');
      }
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id',
        method: 'PATCH', // Usar PATCH para actualización parcial
        body: body,
      );
      
      debugPrint('CategoriasApi: Categoría actualizada con éxito');
      
      // Invalidar caché
      _invalidateCache();
      _cache.invalidate('categoria_$id');
      
      return response['data'];
    } catch (e) {
      debugPrint('CategoriasApi: Error al actualizar categoría: $e');
      // Capturar más detalles sobre el error
      if (e is ApiException) {
        debugPrint('CategoriasApi: Código de error: ${e.statusCode}, Mensaje: ${e.message}');
        if (e.data != null) {
          debugPrint('CategoriasApi: Datos adicionales del error: ${e.data}');
        }
      }
      rethrow;
    }
  }
  
  /// Actualiza una categoría existente usando un objeto [Categoria]
  Future<Categoria> updateCategoriaObjeto(Categoria categoria) async {
    try {
      final Map<String, dynamic> data = await updateCategoria(
        id: categoria.id.toString(),
        nombre: categoria.nombre,
        descripcion: categoria.descripcion,
      );
      return Categoria.fromJson(data);
    } catch (e) {
      debugPrint('CategoriasApi: ERROR al actualizar categoría como objeto: $e');
      rethrow;
    }
  }
  
  /// Elimina una categoría
  /// 
  /// [id] ID de la categoría a eliminar
  Future<bool> deleteCategoria(String id) async {
    try {
      debugPrint('CategoriasApi: Eliminando categoría con ID: $id');
      
      await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id',
        method: 'DELETE',
      );
      
      debugPrint('CategoriasApi: Categoría eliminada con éxito');
      
      // Invalidar caché
      _invalidateCache();
      _cache.invalidate('categoria_$id');
      
      return true;
    } catch (e) {
      debugPrint('CategoriasApi: Error al eliminar categoría: $e');
      // Capturar más detalles sobre el error
      if (e is ApiException) {
        debugPrint('CategoriasApi: Código de error: ${e.statusCode}, Mensaje: ${e.message}');
        if (e.data != null) {
          debugPrint('CategoriasApi: Datos adicionales del error: ${e.data}');
        }
      }
      return false;
    }
  }
  
  /// Obtiene una categoría específica por su ID
  /// 
  /// [id] ID de la categoría a obtener
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<Map<String, dynamic>> getCategoria(String id, {bool useCache = true}) async {
    try {
      final String cacheKey = 'categoria_$id';
      
      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final Map<String, dynamic>? cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Categoría obtenida desde caché: $cacheKey');
          return cachedData;
        }
      }
      
      debugPrint('CategoriasApi: Obteniendo categoría con ID: $id');
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id',
        method: 'GET',
      );
      
      debugPrint('CategoriasApi: Categoría obtenida con éxito');
      
      final Map<String, dynamic> categoria = response['data'] as Map<String, dynamic>;
      
      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, categoria);
        debugPrint('✅ Categoría guardada en caché: $cacheKey');
      }
      
      return categoria;
    } catch (e) {
      debugPrint('CategoriasApi: Error al obtener categoría: $e');
      // Capturar más detalles sobre el error
      if (e is ApiException) {
        debugPrint('CategoriasApi: Código de error: ${e.statusCode}, Mensaje: ${e.message}');
        if (e.data != null) {
          debugPrint('CategoriasApi: Datos adicionales del error: ${e.data}');
        }
      }
      rethrow;
    }
  }
  
  /// Obtiene una categoría específica por su ID como objeto [Categoria]
  Future<Categoria> getCategoriaObjeto(String id, {bool useCache = true}) async {
    try {
      final Map<String, dynamic> categoriaData = await getCategoria(id, useCache: useCache);
      return Categoria.fromJson(categoriaData);
    } catch (e) {
      debugPrint('CategoriasApi: ERROR al obtener categoría como objeto: $e');
      rethrow;
    }
  }
  
  /// Invalidar caché de categorías
  void _invalidateCache() {
    _cache.invalidate('categorias_all');
    debugPrint('✅ Caché de categorías invalidada');
  }
  
  /// Método público para forzar refresco de caché
  void invalidateCache([String? categoriaId]) {
    if (categoriaId != null) {
      _cache.invalidate('categoria_$categoriaId');
      _invalidateCache();
      debugPrint('✅ Caché invalidada para categoría: $categoriaId');
    } else {
      _cache.clear();
      debugPrint('✅ Caché de categorías completamente invalidada');
    }
  }
}
