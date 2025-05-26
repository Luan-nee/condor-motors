import 'dart:io';

import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/cache/fast_cache.dart';
import 'package:condorsmotors/api/protected/paginacion.api.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

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
  /// [stock] Filtrar productos por cantidad de stock, formato: {value: número, filterType: 'eq'|'gte'|'lte'|'ne'} (opcional)
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
    Map<String, dynamic>? stock,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Si se requiere forzar la recarga, invalidar la caché primero
      if (forceRefresh) {
        Logger.debug('Forzando recarga de productos para sucursal $sucursalId');
        invalidateCache(sucursalId);
      }

      // Crear objeto FiltroParams para manejar los parámetros de manera más estructurada
      final FiltroParams filtroParams = FiltroParams(
        search: search,
        page: page ?? 1,
        pageSize: pageSize ?? 20,
        sortBy: sortBy,
        order: order,
        filter: filter,
        filterValue: filterValue,
        filterType: filterType,
        extraParams: <String, String>{
          if (stockBajo != null) 'stockBajo': stockBajo.toString(),
          if (liquidacion != null) 'liquidacion': liquidacion.toString(),
          if (stock != null && stock['value'] != null)
            'stock': '${stock['value']},${stock['filterType'] ?? 'eq'}',
        },
      );

      // Generar clave de caché usando la utilidad
      final String cacheKey = PaginacionUtils.generateCacheKey(
        'productos_$sucursalId',
        filtroParams.toMap(),
      );

      // Intentar obtener desde caché si useCache es true
      if (useCache && !forceRefresh) {
        final PaginatedResponse<Producto>? cachedData =
            _cache.get<PaginatedResponse<Producto>>(cacheKey);
        if (cachedData != null) {
          logCache('Datos obtenidos desde caché: $cacheKey');
          return cachedData;
        }
      }

      // Si no hay caché o useCache es false, obtener desde la API
      PaginacionUtils.logPaginacion(
          'Productos de sucursal $sucursalId', filtroParams.toMap());

      // Construir query params usando la utilidad
      final Map<String, String> queryParams = filtroParams.buildQueryParams();

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos',
        method: 'GET',
        queryParams: queryParams,
      );

      // Procesar respuesta usando la utilidad
      final PaginatedResponse<Producto> result =
          PaginacionUtils.parsePaginatedResponse(
        response,
        (item) => Producto.fromJson(item),
      );

      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, result);
        logCache('Datos guardados en caché: $cacheKey');
      }

      return result;
    } catch (e) {
      Logger.debug('Error al obtener productos: $e');
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
    return getProductos(
      sucursalId: sucursalId,
      page: page ?? 1,
      pageSize: pageSize ?? 20,
      sortBy: sortBy ?? 'nombre',
      order: 'asc',
      stock: {'value': 0, 'filterType': 'eq'},
      useCache: useCache,
    );
  }

  /// Obtiene productos disponibles (stock > 0) de una sucursal específica
  ///
  /// [sucursalId] ID de la sucursal
  /// [page] Número de página para paginación (opcional)
  /// [pageSize] Número de elementos por página (opcional)
  /// [sortBy] Campo por el cual ordenar (opcional)
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<PaginatedResponse<Producto>> getProductosDisponibles({
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
      stock: {'value': 0, 'filterType': 'gt'}, // stock > 0
      useCache: useCache,
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
        errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
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
          logCache('Producto obtenido desde caché: $cacheKey');
          return cachedData;
        }
      }

      Logger.debug('Obteniendo producto $productoId de sucursal $sucursalId');

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos/$productoId',
        method: 'GET',
      );

      final Producto producto = Producto.fromJson(response['data']);

      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, producto);
        logCache('Producto guardado en caché: $cacheKey');
      }

      return producto;
    } catch (e) {
      Logger.debug('Error al obtener producto: $e');
      rethrow;
    }
  }

  /// Crea un nuevo producto en una sucursal
  ///
  /// [sucursalId] ID de la sucursal
  /// [productoData] Datos del producto a crear
  /// [fotoFile] Archivo de foto del producto (opcional)
  Future<Producto> createProducto({
    required String sucursalId,
    required Map<String, dynamic> productoData,
    File? fotoFile,
  }) async {
    try {
      Logger.debug('Creando nuevo producto en sucursal $sucursalId');

      dynamic bodyToSend = productoData;
      Options? options;
      if (fotoFile != null) {
        final String fileName =
            fotoFile.path.split(Platform.pathSeparator).last;
        final String fileExtension = fileName.contains('.')
            ? fileName.split('.').last.toLowerCase()
            : '';
        final int fileSize = await fotoFile.length();
        Logger.debug('[productos.api] Imagen a enviar:');
        Logger.debug('  Path: \\${fotoFile.path}');
        Logger.debug('  Nombre: $fileName');
        Logger.debug('  Extensión: $fileExtension');
        Logger.debug('  Tamaño: $fileSize bytes');
        // Forzar el tipo MIME correcto
        String mimeType = 'jpeg';
        switch (fileExtension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'jpeg';
            break;
          case 'png':
            mimeType = 'png';
            break;
          case 'webp':
            mimeType = 'webp';
            break;
          default:
            mimeType = 'jpeg';
        }
        final formData = FormData.fromMap({
          ...productoData,
          'foto': await MultipartFile.fromFile(
            fotoFile.path,
            filename: fileName,
            contentType: MediaType('image', mimeType),
          ),
        });
        Logger.debug('[productos.api] FormData campos: ${productoData.keys}');
        Logger.debug('[productos.api] Archivo: $fileName');
        bodyToSend = formData;
        options = Options(contentType: 'multipart/form-data');
      }

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos',
        method: 'POST',
        body: bodyToSend,
        headers: options?.headers?.cast<String, String>(),
      );

      // Invalidar caché relacionada de manera más agresiva
      invalidateCache(sucursalId);
      logCache(
          'Caché de productos completamente invalidada después de crear producto');

      return Producto.fromJson(response['data']);
    } catch (e) {
      Logger.debug('Error al crear producto: $e');
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
      Logger.debug('Añadiendo producto $productoId a sucursal $sucursalId');

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos/$productoId',
        method: 'POST',
        body: productoData,
      );

      return Producto.fromJson(response['data']);
    } catch (e) {
      Logger.debug('Error al añadir producto: $e');
      rethrow;
    }
  }

  /// Actualiza un producto existente en una sucursal
  ///
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  /// [productoData] Datos actualizados del producto
  /// [fotoFile] Archivo de foto del producto (opcional)
  Future<Producto> updateProducto({
    required String sucursalId,
    required int productoId,
    required Map<String, dynamic> productoData,
    File? fotoFile,
  }) async {
    try {
      // Validaciones
      if (sucursalId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de sucursal no puede estar vacío',
          errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
        );
      }

      if (productoId <= 0) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de producto inválido: $productoId',
          errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
        );
      }

      // Eliminar el ID del producto de los datos para evitar conflictos
      final Map<String, dynamic> dataToSend =
          Map<String, dynamic>.from(productoData)..remove('id');

      dynamic bodyToSend = dataToSend;
      Options? options;
      if (fotoFile != null) {
        final String fileName =
            fotoFile.path.split(Platform.pathSeparator).last;
        final String fileExtension = fileName.contains('.')
            ? fileName.split('.').last.toLowerCase()
            : '';
        final int fileSize = await fotoFile.length();
        Logger.debug('[productos.api] Imagen a enviar:');
        Logger.debug('  Path: \\${fotoFile.path}');
        Logger.debug('  Nombre: $fileName');
        Logger.debug('  Extensión: $fileExtension');
        Logger.debug('  Tamaño: $fileSize bytes');
        // Forzar el tipo MIME correcto
        String mimeType = 'jpeg';
        switch (fileExtension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'jpeg';
            break;
          case 'png':
            mimeType = 'png';
            break;
          case 'webp':
            mimeType = 'webp';
            break;
          default:
            mimeType = 'jpeg';
        }
        final formData = FormData.fromMap({
          ...dataToSend,
          'foto': await MultipartFile.fromFile(
            fotoFile.path,
            filename: fileName,
            contentType: MediaType('image', mimeType),
          ),
        });
        Logger.debug('[productos.api] FormData campos: ${dataToSend.keys}');
        Logger.debug('[productos.api] Archivo: $fileName');
        bodyToSend = formData;
        options = Options(contentType: 'multipart/form-data');
      }

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos/$productoId',
        method: 'PATCH',
        body: bodyToSend,
        headers: options?.headers?.cast<String, String>(),
      );

      Logger.debug('Respuesta recibida para la actualización del producto');

      // Invalidar caché relacionada de manera más agresiva
      invalidateCache(sucursalId);

      // Verificar estructura de respuesta
      if (response['data'] == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Respuesta inválida del servidor al actualizar el producto',
          errorCode: ApiConstants.errorCodes[500] ?? ApiConstants.unknownError,
        );
      }

      return Producto.fromJson(response['data']);
    } catch (e) {
      Logger.debug('Error al actualizar producto: $e');
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
      Logger.debug('Eliminando producto $productoId de sucursal $sucursalId');

      await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos/$productoId',
        method: 'DELETE',
      );

      return true;
    } catch (e) {
      Logger.debug('Error al eliminar producto: $e');
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
  /// Este método no debe usarse directamente para actualizar el stock.
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
      Logger.debug('Actualizando stock del producto $productoId a $nuevoStock');

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
      Logger.debug('Error al actualizar stock: $e');
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

      Logger.debug(
          'Disminuyendo $cantidad unidades al producto $productoId en sucursal $sucursalId');

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
      Logger.debug('Error al disminuir stock: $e');
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

      Logger.debug(
          'Agregando $cantidad unidades al producto $productoId en sucursal $sucursalId');

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
      Logger.debug('Error al agregar stock: $e');
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
          errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
        );
      }

      if (productoId <= 0) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de producto inválido: $productoId',
          errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
        );
      }

      // Si se está activando la liquidación, el precio de liquidación debe ser proporcionado
      if (enLiquidacion && precioLiquidacion == null) {
        throw ApiException(
          statusCode: 400,
          message:
              'Se requiere precio de liquidación al poner un producto en liquidación',
          errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
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

      Logger.debug(
          'Estableciendo liquidación para producto $productoId en sucursal $sucursalId: $enLiquidacion');
      if (precioLiquidacion != null) {
        Logger.debug('Precio de liquidación: $precioLiquidacion');
      }

      // Actualizar el producto con los datos de liquidación
      return await updateProducto(
        sucursalId: sucursalId,
        productoId: productoId,
        productoData: data,
      );
    } catch (e) {
      Logger.debug('Error al establecer liquidación: $e');
      rethrow;
    }
  }

  /// Descarga un reporte Excel con todos los productos y su stock en todas las sucursales
  ///
  /// El reporte incluye una hoja principal con todos los productos y su stock por sucursal,
  /// y hojas adicionales con el detalle de cada sucursal.
  ///
  /// Este método devuelve directamente los bytes del archivo Excel que se pueden guardar en disco
  /// o mostrar para descarga en la aplicación.
  Future<List<int>> getReporteExcel() async {
    try {
      Logger.debug('Solicitando reporte Excel de productos');

      // Esta solicitud es diferente porque devuelve directamente los bytes del archivo
      // No usamos el método authenticatedRequest estándar
      final response = await _api.authenticatedRequestRaw(
        endpoint: '/productos/reporte',
        method: 'GET',
      );

      Logger.debug('Reporte Excel obtenido: ${response.length} bytes');
      return response;
    } catch (e) {
      Logger.debug('Error al obtener reporte Excel: $e');
      rethrow;
    }
  }

  // Método para invalidar caché relacionada
  void _invalidateRelatedCache(String sucursalId, [int? productoId]) {
    if (productoId != null) {
      // Invalidar caché específica de este producto
      final String cacheKey = 'producto_${sucursalId}_$productoId';
      _cache.invalidate(cacheKey);
      logCache(
          'Caché invalidada para producto $productoId en sucursal $sucursalId: $cacheKey');
    }

    // Invalidar listas que podrían contener este producto
    _cache.invalidateByPattern('productos_$sucursalId');
    logCache('Caché de productos invalidada para sucursal $sucursalId');
    logCache(
        'Estado de caché después de invalidación: ${_cache.size} entradas');
  }

  // Método público para forzar refresco de caché
  void invalidateCache([String? sucursalId]) {
    if (sucursalId != null) {
      // Invalidar todos los productos de esta sucursal (listas paginadas)
      _cache.invalidateByPattern('productos_$sucursalId');

      // También invalidar todos los productos individuales de esta sucursal
      // ya que podrían haber cambiado
      final List<String> productKeys = _cache.keys
          .where((String key) => key.startsWith('producto_$sucursalId'))
          .toList();

      for (final String key in productKeys) {
        _cache.invalidate(key);
        logCache('Caché invalidada: $key');
      }

      logCache(
          'Caché de productos completamente invalidada para sucursal $sucursalId');
      logCache(
          'Estado de caché después de invalidación: ${_cache.size} entradas');
    } else {
      _cache.clear();
      logCache(
          'Caché de productos completamente invalidada para todas las sucursales');
      logCache(
          'Estado de caché después de invalidación: ${_cache.size} entradas');
    }
  }

  // Método para verificar si los datos en caché están obsoletos
  bool isCacheStale(
    String sucursalId, {
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
    final filtroParams = FiltroParams(
      search: search,
      page: page ?? 1,
      pageSize: pageSize ?? 20,
      sortBy: sortBy,
      order: order,
      filter: filter,
      filterValue: filterValue,
      filterType: filterType,
      extraParams: <String, String>{
        if (stockBajo != null) 'stockBajo': stockBajo.toString(),
      },
    );
    final String cacheKey = PaginacionUtils.generateCacheKey(
      'productos_$sucursalId',
      filtroParams.toMap(),
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
    // Construir search term para precios
    String searchTerm = '';
    if (precioMinimo != null) {
      searchTerm += 'precio>${precioMinimo.toStringAsFixed(2)} ';
    }
    if (precioMaximo != null) {
      searchTerm += 'precio<${precioMaximo.toStringAsFixed(2)} ';
    }
    searchTerm = searchTerm.trim();

    // Determinar filtro y valor
    String? filter;
    String? filterValue;
    // FIX: El backend solo permite un filtro a la vez, priorizamos categoría sobre marca
    if (categoria != null && categoria.isNotEmpty) {
      filter = 'categoria';
      filterValue = categoria;
    } else if (marca != null && marca.isNotEmpty) {
      filter = 'marca';
      filterValue = marca;
    }

    // Centralizar parámetros con FiltroParams
    final filtroParams = FiltroParams(
      search: searchTerm.isNotEmpty ? searchTerm : null,
      page: page ?? 1,
      pageSize: pageSize ?? 20,
      sortBy: 'nombre',
      filter: filter,
      filterValue: filterValue,
    );

    // Obtener resultados base
    final PaginatedResponse<Producto> resultados = await getProductos(
      sucursalId: sucursalId,
      page: filtroParams.page,
      pageSize: filtroParams.pageSize,
      sortBy: filtroParams.sortBy,
      order: filtroParams.order,
      search: filtroParams.search,
      filter: filtroParams.filter,
      filterValue: filtroParams.filterValue,
      useCache: useCache,
    );

    // Si no hay filtros adicionales, devolvemos los resultados directamente
    if ((stockPositivo != true && conPromocion != true) ||
        resultados.items.isEmpty) {
      return resultados;
    }

    // Filtros post-proceso (porque el backend no soporta estos filtros directamente)
    final List<Producto> productosFiltrados =
        resultados.items.where((Producto producto) {
      if (stockPositivo == true && (producto.stock <= 0)) {
        return false;
      }
      // Filtrar por promoción activa
      if (conPromocion == true) {
        final bool tienePromocion = producto.liquidacion ||
            (producto.cantidadGratisDescuento != null &&
                producto.cantidadGratisDescuento! > 0) ||
            (producto.cantidadMinimaDescuento != null &&
                producto.porcentajeDescuento != null &&
                producto.cantidadMinimaDescuento! > 0 &&
                producto.porcentajeDescuento! > 0);
        if (!tienePromocion) {
          return false;
        }
      }
      return true;
    }).toList();

    // Ajustar paginación para reflejar los resultados filtrados
    final int pageNumber = filtroParams.page;
    final int itemsPerPage = filtroParams.pageSize;
    final int totalItems = productosFiltrados.length;
    final int totalPages = (totalItems / itemsPerPage).ceil();
    final int startIndex = (pageNumber - 1) * itemsPerPage;
    final int endIndex = startIndex + itemsPerPage < totalItems
        ? startIndex + itemsPerPage
        : totalItems;
    final List<Producto> paginatedResults = startIndex < totalItems
        ? productosFiltrados.sublist(startIndex, endIndex)
        : <Producto>[];

    final Paginacion paginacionAjustada = Paginacion(
      currentPage: pageNumber,
      totalPages: totalPages > 0 ? totalPages : 1,
      totalItems: totalItems,
      hasNext: pageNumber < totalPages,
      hasPrev: pageNumber > 1,
    );

    return PaginatedResponse<Producto>(
      items: paginatedResults,
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
        productosFiltrados = resultados.items
            .where((Producto p) =>
                p.cantidadGratisDescuento != null &&
                p.cantidadGratisDescuento! > 0)
            .toList();
        break;
      case 'porcentaje':
        productosFiltrados = resultados.items
            .where((Producto p) =>
                p.cantidadMinimaDescuento != null &&
                p.porcentajeDescuento != null &&
                p.cantidadMinimaDescuento! > 0 &&
                p.porcentajeDescuento! > 0)
            .toList();
        break;
      case 'cualquiera':
      default:
        productosFiltrados = resultados.items
            .where((Producto p) =>
                    p.liquidacion || // Liquidación
                    (p.cantidadGratisDescuento != null &&
                        p.cantidadGratisDescuento! > 0) || // Promo gratis
                    (p.cantidadMinimaDescuento != null &&
                        p.porcentajeDescuento != null &&
                        p.cantidadMinimaDescuento! > 0 &&
                        p.porcentajeDescuento! > 0) // Descuento por cantidad
                )
            .toList();
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
    final List<Producto> paginatedResults =
        startIndex < productosFiltrados.length
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

    Logger.debug(
        'Obteniendo productos más vendidos en la sucursal $sucursalId durante los últimos $dias días');

    final PaginatedResponse<Producto> productos = await getProductos(
      sucursalId: sucursalId,
      page: page ?? 1,
      pageSize: pageSize ?? 20,
      sortBy:
          'fechaCreacion', // Esto es lo más cercano a "popularidad" sin tener estadísticas reales
      order: 'desc', // Más recientes primero como aproximación
      useCache: useCache,
    );

    // Nota: Aquí deberíamos aplicar la lógica real de ventas
    // Por ahora solo devolvemos los resultados como están

    return productos;
  }
}
