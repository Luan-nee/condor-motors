import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/cache/fast_cache.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:flutter/foundation.dart';

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
  /// [stockBajo] Filtrar productos con stock bajo (opcional)
  /// [liquidacion] Filtrar productos en liquidación (opcional)
  /// [useCache] Indica si se debe usar el caché (default: true)
  /// [forceRefresh] Si es true, invalida la caché antes de obtener los datos
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
    bool? stockBajo,
    bool? liquidacion,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Si se requiere forzar la recarga, invalidar la caché primero
      if (forceRefresh) {
        debugPrint('Forzando recarga de productos para sucursal $sucursalId');
        invalidateCache(sucursalId);
      }
      
      // Generar clave única para este conjunto de parámetros
      final String cacheKey = _generateCacheKey(
        'productos_$sucursalId',
        search: search,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        order: order,
        filter: filter,
        filterValue: filterValue,
        filterType: filterType,
        stockBajo: stockBajo,
        liquidacion: liquidacion,
      );
      
      // Intentar obtener desde caché si useCache es true
      if (useCache && !forceRefresh) {
        final PaginatedResponse<Producto>? cachedData = _cache.get<PaginatedResponse<Producto>>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Datos obtenidos desde caché: $cacheKey');
          return cachedData;
        }
      }
      
      // Si no hay caché o useCache es false, obtener desde la API
      debugPrint('Obteniendo productos para sucursal $sucursalId con parámetros: '
          '{ search: $search, page: $page, pageSize: $pageSize, sortBy: $sortBy, order: $order, filter: $filter, stockBajo: $stockBajo, liquidacion: $liquidacion }');
      
      final Map<String, String> queryParams = <String, String>{};
      
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
      
      // Añadir parámetro stockBajo si está definido
      if (stockBajo != null) {
        queryParams['stockBajo'] = stockBajo.toString();
      }
      
      // Añadir parámetro liquidacion si está definido
      if (liquidacion != null) {
        queryParams['liquidacion'] = liquidacion.toString();
      }
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos',
        method: 'GET',
        queryParams: queryParams,
      );
      
      // Extraer los datos de productos
      final List<dynamic> rawData = response['data'] ?? <dynamic>[];
      final List<Producto> productos = rawData.map((item) => Producto.fromJson(item)).toList();
      
      // Extraer información de paginación
      Map<String, dynamic> paginacionData = <String, dynamic>{};
      if (response.containsKey('pagination') && response['pagination'] != null) {
        paginacionData = response['pagination'] as Map<String, dynamic>;
      }
      
      // Extraer metadata si está disponible
      Map<String, dynamic>? metadata;
      if (response.containsKey('metadata') && response['metadata'] != null) {
        metadata = response['metadata'] as Map<String, dynamic>;
      }
      
      // Crear la respuesta paginada
      final PaginatedResponse<Producto> result = PaginatedResponse<Producto>(
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
  
  /// Obtiene productos con stock bajo de una sucursal específica
  /// 
  /// Método helper que utiliza getProductos con el parámetro stockBajo=true
  /// 
  /// [sucursalId] ID de la sucursal
  /// [page] Número de página para paginación (opcional)
  /// [pageSize] Número de elementos por página (opcional)
  /// [sortBy] Campo por el cual ordenar (opcional)
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<PaginatedResponse<Producto>> getProductosConStockBajo({
    required String sucursalId,
    int? page,
    int? pageSize,
    String? sortBy,
    bool useCache = true,
  }) async {
    return getProductos(
      sucursalId: sucursalId,
      page: page ?? 1,
      pageSize: pageSize ?? 20,
      sortBy: sortBy ?? 'nombre',
      order: 'asc',
      stockBajo: true,
      useCache: useCache,
    );
  }
  
  /// Obtiene productos agotados (stock = 0) de una sucursal específica
  /// 
  /// [sucursalId] ID de la sucursal
  /// [page] Número de página para paginación (opcional)
  /// [pageSize] Número de elementos por página (opcional)
  /// [sortBy] Campo por el cual ordenar (opcional)
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<PaginatedResponse<Producto>> getProductosAgotados({
    required String sucursalId,
    int? page,
    int? pageSize,
    String? sortBy,
    bool useCache = true,
  }) async {
    // Usamos el método general y filtramos manualmente
    // porque el backend no tiene un endpoint específico para agotados
    final PaginatedResponse<Producto> response = await getProductos(
      sucursalId: sucursalId,
      page: page ?? 1,
      pageSize: pageSize ?? 50, // Tamaño grande para tener suficientes después de filtrar
      sortBy: sortBy ?? 'nombre',
      order: 'asc',
      useCache: useCache,
    );
    
    // Filtramos solo los productos agotados (stock = 0)
    final List<Producto> productosAgotados = response.items.where((Producto p) => p.stock <= 0).toList();
    
    // Mantenemos la misma información de paginación pero ajustamos totalItems
    final Paginacion paginacionAjustada = Paginacion(
      currentPage: response.paginacion.currentPage,
      totalPages: response.paginacion.totalPages,
      totalItems: productosAgotados.length,
      hasNext: response.paginacion.hasNext,
      hasPrev: response.paginacion.hasPrev,
    );
    
    // Devolvemos una nueva respuesta paginada con solo los productos agotados
    return PaginatedResponse<Producto>(
      items: productosAgotados,
      paginacion: paginacionAjustada,
      metadata: response.metadata,
    );
  }
  
  /// Obtiene productos sin stock bajo de una sucursal específica
  /// 
  /// Método helper que utiliza getProductos con el parámetro stockBajo=false
  /// 
  /// [sucursalId] ID de la sucursal
  /// [page] Número de página para paginación (opcional)
  /// [pageSize] Número de elementos por página (opcional)
  /// [sortBy] Campo por el cual ordenar (opcional)
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<PaginatedResponse<Producto>> getProductosSinStockBajo({
    required String sucursalId,
    int? page,
    int? pageSize,
    String? sortBy,
    bool useCache = true,
  }) async {
    return getProductos(
      sucursalId: sucursalId,
      page: page ?? 1,
      pageSize: pageSize ?? 20,
      sortBy: sortBy ?? 'nombre',
      order: 'asc',
      stockBajo: false,
      useCache: useCache,
    );
  }
  
  /// Busca productos por nombre en una sucursal específica
  /// 
  /// Método helper que utiliza getProductos con el parámetro search
  /// 
  /// [sucursalId] ID de la sucursal
  /// [nombre] Término de búsqueda para filtrar productos por nombre
  /// [page] Número de página para paginación (opcional)
  /// [pageSize] Número de elementos por página (opcional)
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<PaginatedResponse<Producto>> buscarProductosPorNombre({
    required String sucursalId,
    required String nombre,
    int? page,
    int? pageSize,
    bool useCache = true,
  }) async {
    if (nombre.isEmpty) {
      throw ApiException(
        statusCode: 400,
        message: 'El término de búsqueda no puede estar vacío',
      );
    }
    
    return getProductos(
      sucursalId: sucursalId,
      search: nombre,
      page: page ?? 1,
      pageSize: pageSize ?? 20,
      sortBy: 'nombre',
      order: 'asc',
      useCache: useCache,
    );
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
      final String cacheKey = 'producto_${sucursalId}_$productoId';
      
      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final Producto? cachedData = _cache.get<Producto>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Producto obtenido desde caché: $cacheKey');
          return cachedData;
        }
      }
      
      debugPrint('Obteniendo producto $productoId de sucursal $sucursalId');
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos/$productoId',
        method: 'GET',
      );
      
      final Producto producto = Producto.fromJson(response['data']);
      
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
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos',
        method: 'POST',
        body: productoData,
      );
      
      // Invalidar caché relacionada de manera más agresiva
      invalidateCache(sucursalId);
      debugPrint('✅ Caché de productos completamente invalidada después de crear producto');
      
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
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
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
      // Validaciones
      if (sucursalId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de sucursal no puede estar vacío',
        );
      }
      
      if (productoId <= 0) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de producto inválido: $productoId',
        );
      }
      
      // Eliminar el ID del producto de los datos para evitar conflictos
      final Map<String, dynamic> dataToSend = Map<String, dynamic>.from(productoData);
      dataToSend.remove('id'); // No enviar el ID en el cuerpo
      
      debugPrint('ProductosApi: Actualizando producto $productoId en sucursal $sucursalId');
      debugPrint('ProductosApi: Endpoint: /$sucursalId/productos/$productoId');
      debugPrint('ProductosApi: Método: PATCH');
      debugPrint('ProductosApi: Datos a enviar: $dataToSend');
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos/$productoId',
        method: 'PATCH',
        body: dataToSend,
      );
      
      debugPrint('ProductosApi: Respuesta recibida para la actualización del producto');
      
      // Invalidar caché relacionada de manera más agresiva
      invalidateCache(sucursalId);
      
      // Verificar estructura de respuesta
      if (response['data'] == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Respuesta inválida del servidor al actualizar el producto',
        );
      }
      
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
  /// 
  /// TODO: Este método no debe usarse directamente para actualizar el stock.
  /// La forma correcta de gestionar el stock es a través del endpoint de inventarios:
  /// - Para incrementar stock: usar el método agregarStock() que utiliza el endpoint de entradas de inventario.
  /// - Para decrementar stock: crear un método similar que utilice el endpoint de salidas de inventario.
  /// El backend no procesa cambios de stock mediante PATCH en /productos, solo a través de las APIs de inventario.
  Future<Producto> updateStock({
    required String sucursalId,
    required int productoId,
    required int nuevoStock,
  }) async {
    try {
      debugPrint('Actualizando stock del producto $productoId a $nuevoStock');
      
      final Producto producto = await updateProducto(
        sucursalId: sucursalId,
        productoId: productoId,
        productoData: <String, dynamic>{
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
  
  /// Disminuye stock de un producto mediante el endpoint de salidas de inventario
  /// 
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  /// [cantidad] Cantidad a restar (debe ser positiva)
  /// [motivo] Motivo de la salida de inventario (opcional)
  Future<bool> disminuirStock({
    required String sucursalId,
    required int productoId,
    required int cantidad,
    String? motivo,
  }) async {
    try {
      if (cantidad <= 0) {
        throw Exception('La cantidad a disminuir debe ser mayor a 0');
      }
      
      debugPrint('Disminuyendo $cantidad unidades al producto $productoId en sucursal $sucursalId');
      
      // Asegurarse de que los tipos sean los correctos para la API
      final Map<String, dynamic> body = <String, dynamic>{
        'productoId': productoId, // Asegurarse que sea un entero
        'cantidad': cantidad, // Asegurarse que sea un entero
      };
      
      if (motivo != null && motivo.isNotEmpty) {
        body['motivo'] = motivo;
      }
      
      await _api.authenticatedRequest(
        endpoint: '/$sucursalId/inventarios/salidas',
        method: 'POST',
        body: body,
      );
      
      // Invalidar caché relacionada
      _invalidateRelatedCache(sucursalId, productoId);
      
      return true;
    } catch (e) {
      debugPrint('Error al disminuir stock: $e');
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
      
      // Asegurarse de que los tipos sean los correctos para la API
      final Map<String, dynamic> body = <String, dynamic>{
        'productoId': productoId, // Asegurarse que sea un entero
        'cantidad': cantidad, // Asegurarse que sea un entero
      };
      
      if (motivo != null && motivo.isNotEmpty) {
        body['motivo'] = motivo;
      }
      
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
  
  /// Obtiene productos en liquidación de una sucursal específica
  /// 
  /// [sucursalId] ID de la sucursal
  /// [page] Número de página para paginación (opcional)
  /// [pageSize] Número de elementos por página (opcional)
  /// [sortBy] Campo por el cual ordenar (opcional)
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<PaginatedResponse<Producto>> getProductosEnLiquidacion({
    required String sucursalId,
    int? page,
    int? pageSize,
    String? sortBy,
    bool useCache = true,
  }) async {
    return getProductos(
      sucursalId: sucursalId,
      page: page ?? 1,
      pageSize: pageSize ?? 20,
      sortBy: sortBy ?? 'nombre',
      order: 'asc',
      liquidacion: true,
      useCache: useCache,
    );
  }
  
  /// Establece un producto en liquidación o quita la liquidación
  /// 
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  /// [enLiquidacion] Si es true, pone el producto en liquidación, si es false, quita la liquidación
  /// [precioLiquidacion] Precio de liquidación (opcional si enLiquidacion es false)
  Future<Producto> setLiquidacion({
    required String sucursalId,
    required int productoId,
    required bool enLiquidacion,
    double? precioLiquidacion,
  }) async {
    try {
      if (sucursalId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de sucursal no puede estar vacío',
        );
      }
      
      if (productoId <= 0) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de producto inválido: $productoId',
        );
      }
      
      // Si se está activando la liquidación, el precio de liquidación debe ser proporcionado
      if (enLiquidacion && precioLiquidacion == null) {
        throw ApiException(
          statusCode: 400,
          message: 'Se requiere precio de liquidación al poner un producto en liquidación',
        );
      }
      
      // Datos a enviar al servidor
      final Map<String, dynamic> data = <String, dynamic>{
        'liquidacion': enLiquidacion,
      };
      
      // Añadir precio de liquidación si está presente
      if (precioLiquidacion != null) {
        data['precioOferta'] = precioLiquidacion;
      }
      
      debugPrint('Estableciendo liquidación para producto $productoId en sucursal $sucursalId: $enLiquidacion');
      if (precioLiquidacion != null) {
        debugPrint('Precio de liquidación: $precioLiquidacion');
      }
      
      // Actualizar el producto con los datos de liquidación
      return await updateProducto(
        sucursalId: sucursalId,
        productoId: productoId,
        productoData: data,
      );
    } catch (e) {
      debugPrint('Error al establecer liquidación: $e');
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
    bool? stockBajo,
    bool? liquidacion,
  }) {
    final List<String> components = <String>[base];
    
    if (search != null && search.isNotEmpty) {
      components.add('s:$search');
    }
    if (page != null) {
      components.add('p:$page');
    }
    if (pageSize != null) {
      components.add('ps:$pageSize');
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      components.add('sb:$sortBy');
    }
    if (order != null && order.isNotEmpty) {
      components.add('o:$order');
    }
    if (filter != null && filter.isNotEmpty) {
      components.add('f:$filter');
    }
    if (filterValue != null) {
      components.add('fv:$filterValue');
    }
    if (filterType != null && filterType.isNotEmpty) {
      components.add('ft:$filterType');
    }
    if (stockBajo != null) {
      components.add('stb:${stockBajo ? 'true' : 'false'}');
    }
    if (liquidacion != null) {
      components.add('liq:${liquidacion ? 'true' : 'false'}');
    }
    
    return components.join('_');
  }
  
  // Método para invalidar caché relacionada
  void _invalidateRelatedCache(String sucursalId, [int? productoId]) {
    if (productoId != null) {
      // Invalidar caché específica de este producto
      final String cacheKey = 'producto_${sucursalId}_$productoId';
      _cache.invalidate(cacheKey);
      debugPrint('✅ Caché invalidada para producto $productoId en sucursal $sucursalId: $cacheKey');
    }
    
    // Invalidar listas que podrían contener este producto
    _cache.invalidateByPattern('productos_$sucursalId');
    debugPrint('✅ Caché de productos invalidada para sucursal $sucursalId');
    debugPrint('📊 Estado de caché después de invalidación: ${_cache.size} entradas');
  }
  
  // Método público para forzar refresco de caché
  void invalidateCache([String? sucursalId]) {
    if (sucursalId != null) {
      // Invalidar todos los productos de esta sucursal (listas paginadas)
      _cache.invalidateByPattern('productos_$sucursalId');
      
      // También invalidar todos los productos individuales de esta sucursal 
      // ya que podrían haber cambiado
      final List<String> productKeys = _cache.keys.where((String key) => 
          key.startsWith('producto_$sucursalId')).toList();
      
      for (final String key in productKeys) {
        _cache.invalidate(key);
        debugPrint('✅ Caché invalidada: $key');
      }
      
      debugPrint('✅ Caché de productos completamente invalidada para sucursal $sucursalId');
      debugPrint('📊 Estado de caché después de invalidación: ${_cache.size} entradas');
    } else {
      _cache.clear();
      debugPrint('✅ Caché de productos completamente invalidada para todas las sucursales');
      debugPrint('📊 Estado de caché después de invalidación: ${_cache.size} entradas');
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
    bool? stockBajo,
  }) {
    final String cacheKey = _generateCacheKey(
      'productos_$sucursalId',
      search: search,
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      order: order,
      filter: filter,
      filterValue: filterValue,
      filterType: filterType,
      stockBajo: stockBajo,
    );
    
    return _cache.isStale(cacheKey);
  }

  /// Obtiene productos por filtros combinados
  /// 
  /// Método helper que permite combinar múltiples filtros para búsquedas avanzadas
  /// 
  /// [sucursalId] ID de la sucursal
  /// [categoria] Categoría de productos (opcional)
  /// [marca] Marca de productos (opcional)
  /// [precioMinimo] Precio mínimo (opcional)
  /// [precioMaximo] Precio máximo (opcional)
  /// [stockPositivo] Mostrar solo productos con stock > 0 (opcional)
  /// [conPromocion] Mostrar solo productos con alguna promoción activa (opcional)
  /// [page] Número de página para paginación (opcional)
  /// [pageSize] Número de elementos por página (opcional)
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<PaginatedResponse<Producto>> getProductosPorFiltros({
    required String sucursalId,
    String? categoria,
    String? marca,
    double? precioMinimo,
    double? precioMaximo,
    bool? stockPositivo,
    bool? conPromocion,
    int? page,
    int? pageSize,
    bool useCache = true,
  }) async {
    // Construir parámetros base
    final Map<String, String> queryParams = <String, String>{};
    
    if (categoria != null && categoria.isNotEmpty) {
      queryParams['filter'] = 'categoria';
      queryParams['filter_value'] = categoria;
      queryParams['filter_type'] = 'eq';
    }
    
    if (marca != null && marca.isNotEmpty) {
      // Nota: Este es un caso especial ya que filter solo permite un valor a la vez
      // Para aplicar múltiples filtros, el backend necesitaría soporte especial
      // Por ahora, damos prioridad a la categoría sobre la marca si ambos están presentes
      if (!queryParams.containsKey('filter')) {
        queryParams['filter'] = 'marca';
        queryParams['filter_value'] = marca;
        queryParams['filter_type'] = 'eq';
      }
    }
    
    // Para precio, podemos usar search como alternativa
    String searchTerm = '';
    if (precioMinimo != null || precioMaximo != null) {
      if (precioMinimo != null) {
        searchTerm += 'precio>${precioMinimo.toStringAsFixed(2)} ';
      }
      if (precioMaximo != null) {
        searchTerm += 'precio<${precioMaximo.toStringAsFixed(2)} ';
      }
    }
    
    // Obtenemos resultados base
    final PaginatedResponse<Producto> resultados = await getProductos(
      sucursalId: sucursalId,
      page: page ?? 1,
      pageSize: pageSize ?? 20,
      sortBy: 'nombre', // Default
      order: 'asc',
      search: searchTerm.isNotEmpty ? searchTerm : null,
      useCache: useCache,
    );
    
    // Si no hay filtros adicionales, devolvemos los resultados directamente
    if ((stockPositivo != true && conPromocion != true) || resultados.items.isEmpty) {
      return resultados;
    }
    
    // Filtros post-proceso (porque el backend no soporta estos filtros directamente)
    final List<Producto> productosFiltrados = resultados.items.where((Producto producto) {
      // Filtrar por stock positivo
      if (stockPositivo == true && (producto.stock <= 0)) {
        return false;
      }
      
      // Filtrar por promoción activa
      if (conPromocion == true) {
        final bool tienePromocion = producto.liquidacion || // Liquidación
                             (producto.cantidadGratisDescuento != null && producto.cantidadGratisDescuento! > 0) || // Promo gratis
                             (producto.cantidadMinimaDescuento != null && producto.porcentajeDescuento != null && 
                              producto.cantidadMinimaDescuento! > 0 && producto.porcentajeDescuento! > 0); // Descuento por cantidad
        
        if (!tienePromocion) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // Ajustar paginación para reflejar los resultados filtrados
    final Paginacion paginacionAjustada = Paginacion(
      currentPage: resultados.paginacion.currentPage,
      totalPages: (productosFiltrados.length / (pageSize ?? 20)).ceil(),
      totalItems: productosFiltrados.length,
      hasNext: (page ?? 1) < ((productosFiltrados.length / (pageSize ?? 20)).ceil()),
      hasPrev: (page ?? 1) > 1,
    );
    
    return PaginatedResponse<Producto>(
      items: productosFiltrados,
      paginacion: paginacionAjustada,
      metadata: resultados.metadata,
    );
  }

  /// Obtiene productos con alguna promoción activa
  /// 
  /// [sucursalId] ID de la sucursal
  /// [tipoPromocion] Tipo de promoción: 'cualquiera', 'liquidacion', 'gratis', 'porcentaje' (opcional)
  /// [page] Número de página para paginación (opcional)
  /// [pageSize] Número de elementos por página (opcional)
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<PaginatedResponse<Producto>> getProductosConPromocion({
    required String sucursalId,
    String tipoPromocion = 'cualquiera',
    int? page,
    int? pageSize,
    bool useCache = true,
  }) async {
    // Para liquidación, usar el endpoint directo
    if (tipoPromocion == 'liquidacion') {
      return getProductosEnLiquidacion(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        useCache: useCache,
      );
    }
    
    // Para otros tipos, obtenemos todos y filtramos
    final PaginatedResponse<Producto> resultados = await getProductos(
      sucursalId: sucursalId,
      page: page ?? 1,
      pageSize: 100, // Obtenemos más para poder filtrar adecuadamente
      sortBy: 'nombre',
      order: 'asc',
      useCache: useCache,
    );
    
    if (resultados.items.isEmpty) {
      return resultados;
    }
    
    // Filtrar según el tipo de promoción
    List<Producto> productosFiltrados;
    
    switch (tipoPromocion) {
      case 'gratis':
        productosFiltrados = resultados.items.where((Producto p) => 
          p.cantidadGratisDescuento != null && p.cantidadGratisDescuento! > 0
        ).toList();
        break;
      case 'porcentaje':
        productosFiltrados = resultados.items.where((Producto p) => 
          p.cantidadMinimaDescuento != null && p.porcentajeDescuento != null &&
          p.cantidadMinimaDescuento! > 0 && p.porcentajeDescuento! > 0
        ).toList();
        break;
      case 'cualquiera':
      default:
        productosFiltrados = resultados.items.where((Producto p) => 
          p.liquidacion || // Liquidación
          (p.cantidadGratisDescuento != null && p.cantidadGratisDescuento! > 0) || // Promo gratis
          (p.cantidadMinimaDescuento != null && p.porcentajeDescuento != null && 
           p.cantidadMinimaDescuento! > 0 && p.porcentajeDescuento! > 0) // Descuento por cantidad
        ).toList();
        break;
    }
    
    // Paginar los resultados manualmente
    final int pageNumber = page ?? 1;
    final int itemsPerPage = pageSize ?? 20;
    final int startIndex = (pageNumber - 1) * itemsPerPage;
    final int endIndex = startIndex + itemsPerPage < productosFiltrados.length 
        ? startIndex + itemsPerPage 
        : productosFiltrados.length;
    
    // Asegurarnos de no ir fuera de rango
    final List<Producto> paginatedResults = startIndex < productosFiltrados.length 
        ? productosFiltrados.sublist(startIndex, endIndex)
        : <Producto>[];
    
    // Ajustar paginación
    final int totalPages = (productosFiltrados.length / itemsPerPage).ceil();
    final Paginacion paginacionAjustada = Paginacion(
      currentPage: pageNumber,
      totalPages: totalPages > 0 ? totalPages : 1,
      totalItems: productosFiltrados.length,
      hasNext: pageNumber < totalPages,
      hasPrev: pageNumber > 1,
    );
    
    return PaginatedResponse<Producto>(
      items: paginatedResults,
      paginacion: paginacionAjustada,
      metadata: resultados.metadata,
    );
  }

  /// Obtiene productos ordenados por más vendidos
  /// 
  /// Este método simula la funcionalidad ya que el backend aún no provee estadísticas directas
  /// En una implementación real, se debería consultar un endpoint específico en el servidor
  /// 
  /// [sucursalId] ID de la sucursal
  /// [dias] Días a considerar para el cálculo (7=semana, 30=mes, etc.)
  /// [page] Número de página para paginación (opcional)
  /// [pageSize] Número de elementos por página (opcional)
  /// [useCache] Indica si se debe usar el caché (default: false - no recomendado para datos estadísticos)
  Future<PaginatedResponse<Producto>> getProductosMasVendidos({
    required String sucursalId,
    int dias = 30,
    int? page,
    int? pageSize,
    bool useCache = false,
  }) async {
    // En una implementación completa, consultaríamos un endpoint específico con estadísticas
    // Por ahora, obtenemos productos normales y simulamos la ordenación
    
    debugPrint('Obteniendo productos más vendidos en la sucursal $sucursalId durante los últimos $dias días');
    
    final PaginatedResponse<Producto> productos = await getProductos(
      sucursalId: sucursalId,
      page: page ?? 1,
      pageSize: pageSize ?? 20,
      sortBy: 'fechaCreacion', // Esto es lo más cercano a "popularidad" sin tener estadísticas reales
      order: 'desc', // Más recientes primero como aproximación
      useCache: useCache,
    );
    
    // Nota: Aquí deberíamos aplicar la lógica real de ventas
    // Por ahora solo devolvemos los resultados como están
    
    return productos;
  }
}
