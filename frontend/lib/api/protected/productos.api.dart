import 'package:flutter/foundation.dart';

import '../../models/paginacion.model.dart';
import '../../models/producto.model.dart';
import '../main.api.dart';
import 'cache/fast_cache.dart';

class ProductosApi {
  final ApiClient _api;
  // Fast Cache para todas las operaciones de productos
  final FastCache _cache = FastCache();
  
  ProductosApi(this._api);
  
  /// Obtiene todos los productos de una sucursal específica
  /// 
  /// [sucursalId] ID de la sucursal
  /// [search] Término de búsqueda para filtrar productos (opcional)
  /// [page] Número de página para paginación (opcional)
  /// [pageSize] Número de elementos por página (opcional)
  /// [sortBy] Campo por el cual ordenar (opcional)
  /// [order] Orden ascendente o descendente (opcional)
  /// [filter] Campo por el cual filtrar (opcional)
  /// [filterValue] Valor para el filtro (opcional)
  /// [filterType] Tipo de filtro a aplicar (opcional)
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<PaginatedResponse<Producto>> getProductos({
    required String sucursalId,
    String? search,
    int? page,
    int? pageSize,
    String? sortBy,
    String? order,
    String? filter,
    String? filterValue,
    String? filterType,
    bool useCache = true,
  }) async {
    try {
      // Generar clave única para este conjunto de parámetros
      final cacheKey = _generateCacheKey(
        'productos_$sucursalId',
        search: search,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        order: order,
        filter: filter,
        filterValue: filterValue,
        filterType: filterType,
      );
      
      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final cachedData = _cache.get<PaginatedResponse<Producto>>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Datos obtenidos desde caché: $cacheKey');
          return cachedData;
        }
      }
      
      // Si no hay caché o useCache es false, obtener desde la API
      debugPrint('Obteniendo productos para sucursal $sucursalId con parámetros: '
          '{ search: $search, page: $page, pageSize: $pageSize, sortBy: $sortBy, order: $order, filter: $filter }');
      
      final queryParams = <String, String>{};
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      if (page != null) {
        queryParams['page'] = page.toString();
      }
      
      if (pageSize != null) {
        queryParams['page_size'] = pageSize.toString();
      }
      
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sort_by'] = sortBy;
      }
      
      if (order != null && order.isNotEmpty) {
        queryParams['order'] = order;
      }
      
      if (filter != null && filter.isNotEmpty) {
        queryParams['filter'] = filter;
      }
      
      if (filterValue != null) {
        queryParams['filter_value'] = filterValue;
      }
      
      if (filterType != null && filterType.isNotEmpty) {
        queryParams['filter_type'] = filterType;
      }
      
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos',
        method: 'GET',
        queryParams: queryParams,
      );
      
      // Extraer los datos de productos
      final List<dynamic> rawData = response['data'] ?? [];
      final productos = rawData.map((item) => Producto.fromJson(item)).toList();
      
      // Extraer información de paginación
      Map<String, dynamic> paginacionData = {};
      if (response.containsKey('pagination') && response['pagination'] != null) {
        paginacionData = response['pagination'] as Map<String, dynamic>;
      }
      
      // Extraer metadata si está disponible
      Map<String, dynamic>? metadata;
      if (response.containsKey('metadata') && response['metadata'] != null) {
        metadata = response['metadata'] as Map<String, dynamic>;
      }
      
      // Crear la respuesta paginada
      final result = PaginatedResponse<Producto>(
        items: productos,
        paginacion: Paginacion.fromJson(paginacionData),
        metadata: metadata,
      );
      
      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, result);
        debugPrint('✅ Datos guardados en caché: $cacheKey');
      }
      
      return result;
    } catch (e) {
      debugPrint('Error al obtener productos: $e');
      rethrow;
    }
  }
  
  /// Obtiene un producto específico de una sucursal
  /// 
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<Producto> getProducto({
    required String sucursalId,
    required int productoId,
    bool useCache = true,
  }) async {
    try {
      final cacheKey = 'producto_${sucursalId}_$productoId';
      
      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final cachedData = _cache.get<Producto>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Producto obtenido desde caché: $cacheKey');
          return cachedData;
        }
      }
      
      debugPrint('Obteniendo producto $productoId de sucursal $sucursalId');
      
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos/$productoId',
        method: 'GET',
      );
      
      final producto = Producto.fromJson(response['data']);
      
      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, producto);
        debugPrint('✅ Producto guardado en caché: $cacheKey');
      }
      
      return producto;
    } catch (e) {
      debugPrint('Error al obtener producto: $e');
      rethrow;
    }
  }
  
  /// Crea un nuevo producto en una sucursal
  /// 
  /// [sucursalId] ID de la sucursal
  /// [productoData] Datos del producto a crear
  Future<Producto> createProducto({
    required String sucursalId,
    required Map<String, dynamic> productoData,
  }) async {
    try {
      debugPrint('Creando nuevo producto en sucursal $sucursalId');
      
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos',
        method: 'POST',
        body: productoData,
      );
      
      // Invalidar caché relacionada con esta sucursal
      _invalidateRelatedCache(sucursalId);
      
      return Producto.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error al crear producto: $e');
      rethrow;
    }
  }
  
  /// Añade un producto existente a una sucursal
  /// 
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto existente a añadir
  /// [productoData] Datos específicos del producto para esta sucursal
  Future<Producto> addProducto({
    required String sucursalId,
    required int productoId,
    required Map<String, dynamic> productoData,
  }) async {
    try {
      debugPrint('Añadiendo producto $productoId a sucursal $sucursalId');
      
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos/$productoId',
        method: 'POST',
        body: productoData,
      );
      
      return Producto.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error al añadir producto: $e');
      rethrow;
    }
  }
  
  /// Actualiza un producto existente en una sucursal
  /// 
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  /// [productoData] Datos actualizados del producto
  Future<Producto> updateProducto({
    required String sucursalId,
    required int productoId,
    required Map<String, dynamic> productoData,
  }) async {
    try {
      debugPrint('Actualizando producto $productoId en sucursal $sucursalId');
      
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos/$productoId',
        method: 'PATCH',
        body: productoData,
      );
      
      // Invalidar caché relacionada
      _invalidateRelatedCache(sucursalId, productoId);
      
      return Producto.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error al actualizar producto: $e');
      rethrow;
    }
  }
  
  /// Elimina un producto de una sucursal (No implementado en el servidor)
  /// 
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  Future<bool> deleteProducto({
    required String sucursalId,
    required int productoId,
  }) async {
    try {
      debugPrint('Eliminando producto $productoId de sucursal $sucursalId');
      
      await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos/$productoId',
        method: 'DELETE',
      );
      
      return true;
    } catch (e) {
      debugPrint('Error al eliminar producto: $e');
      return false;
    }
  }
  
  /// Actualiza el stock de un producto
  /// 
  /// Este método es un helper que utiliza updateProducto internamente
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  /// [nuevoStock] Nueva cantidad de stock
  Future<Producto> updateStock({
    required String sucursalId,
    required int productoId,
    required int nuevoStock,
  }) async {
    try {
      debugPrint('Actualizando stock del producto $productoId a $nuevoStock');
      
      final producto = await updateProducto(
        sucursalId: sucursalId,
        productoId: productoId,
        productoData: {
          'stock': nuevoStock,
        },
      );
      
      // La invalidación del caché ya ocurre en updateProducto
      
      return producto;
    } catch (e) {
      debugPrint('Error al actualizar stock: $e');
      rethrow;
    }
  }
  
  /// Agrega stock a un producto mediante el endpoint de entradas de inventario
  /// 
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  /// [cantidad] Cantidad a agregar (debe ser positiva)
  /// [motivo] Motivo de la entrada de inventario (opcional)
  Future<bool> agregarStock({
    required String sucursalId,
    required int productoId,
    required int cantidad,
    String? motivo,
  }) async {
    try {
      if (cantidad <= 0) {
        throw Exception('La cantidad a agregar debe ser mayor a 0');
      }
      
      debugPrint('Agregando $cantidad unidades al producto $productoId en sucursal $sucursalId');
      
      final body = {
        'productoId': productoId,
        'cantidad': cantidad,
      };
      
      await _api.authenticatedRequest(
        endpoint: '/$sucursalId/inventarios/entradas',
        method: 'POST',
        body: body,
      );
      
      // Invalidar caché relacionada
      _invalidateRelatedCache(sucursalId, productoId);
      
      return true;
    } catch (e) {
      debugPrint('Error al agregar stock: $e');
      rethrow;
    }
  }
  
  // Método helper para generar claves de caché consistentes
  String _generateCacheKey(
    String base, {
    String? search,
    int? page,
    int? pageSize,
    String? sortBy,
    String? order,
    String? filter,
    String? filterValue,
    String? filterType,
  }) {
    final List<String> components = [base];
    
    if (search != null && search.isNotEmpty) components.add('s:$search');
    if (page != null) components.add('p:$page');
    if (pageSize != null) components.add('ps:$pageSize');
    if (sortBy != null && sortBy.isNotEmpty) components.add('sb:$sortBy');
    if (order != null && order.isNotEmpty) components.add('o:$order');
    if (filter != null && filter.isNotEmpty) components.add('f:$filter');
    if (filterValue != null) components.add('fv:$filterValue');
    if (filterType != null && filterType.isNotEmpty) components.add('ft:$filterType');
    
    return components.join('_');
  }
  
  // Método para invalidar caché relacionada
  void _invalidateRelatedCache(String sucursalId, [int? productoId]) {
    if (productoId != null) {
      // Invalidar caché específica de este producto
      _cache.invalidate('producto_${sucursalId}_$productoId');
      debugPrint('✅ Caché invalidada para producto $productoId en sucursal $sucursalId');
    }
    
    // Invalidar listas que podrían contener este producto
    _cache.invalidateByPattern('productos_$sucursalId');
    debugPrint('✅ Caché de productos invalidada para sucursal $sucursalId');
  }
  
  // Método público para forzar refresco de caché
  void invalidateCache([String? sucursalId]) {
    if (sucursalId != null) {
      _cache.invalidateByPattern('productos_$sucursalId');
      debugPrint('✅ Caché de productos invalidada para sucursal $sucursalId');
    } else {
      _cache.clear();
      debugPrint('✅ Caché de productos completamente invalidada');
    }
  }
  
  // Método para verificar si los datos en caché están obsoletos
  bool isCacheStale(String sucursalId, {
    String? search,
    int? page,
    int? pageSize,
    String? sortBy,
    String? order,
    String? filter,
    String? filterValue,
    String? filterType,
  }) {
    final cacheKey = _generateCacheKey(
      'productos_$sucursalId',
      search: search,
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      order: order,
      filter: filter,
      filterValue: filterValue,
      filterType: filterType,
    );
    
    return _cache.isStale(cacheKey);
  }
}
