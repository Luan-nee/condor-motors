import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/foundation.dart';

/// Repositorio para gestionar productos
///
/// Esta clase encapsula la lógica de negocio relacionada con productos,
/// actuando como una capa intermedia entre la UI y la API
class ProductoRepository implements BaseRepository {
  /// Instancia singleton del repositorio
  static final ProductoRepository _instance = ProductoRepository._internal();

  /// Getter para la instancia singleton
  static ProductoRepository get instance => _instance;

  /// API de productos
  late final ProductosApi _productosApi;

  /// Constructor privado para el patrón singleton
  ProductoRepository._internal() {
    try {
      // Utilizamos la API global inicializada en index.api.dart
      _productosApi = api.productos;
    } catch (e) {
      debugPrint('Error al obtener ProductosApi: $e');
      // Si hay un error al acceder a la API global, lanzamos una excepción
      throw Exception('No se pudo inicializar ProductoRepository: $e');
    }
  }

  /// Obtiene datos del usuario desde la API centralizada
  ///
  /// Ayuda a los providers a acceder a la información del usuario autenticado
  @override
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      return await api.getUserData();
    } catch (e) {
      debugPrint('Error en ProductoRepository.getUserData: $e');
      return null;
    }
  }

  /// Obtiene el ID de la sucursal del usuario actual
  ///
  /// Útil para operaciones que requieren el ID de sucursal automáticamente
  @override
  Future<String?> getCurrentSucursalId() async {
    try {
      final userData = await getUserData();
      if (userData == null) {
        return null;
      }
      return userData['sucursalId']?.toString();
    } catch (e) {
      debugPrint('Error en ProductoRepository.getCurrentSucursalId: $e');
      return null;
    }
  }

  /// Obtiene los productos de una sucursal con filtros y paginación
  ///
  /// [sucursalId] ID de la sucursal
  /// [page] Número de página actual
  /// [pageSize] Tamaño de página
  /// [search] Texto para buscar productos
  /// [sortBy] Campo por el cual ordenar
  /// [order] Tipo de ordenamiento (asc/desc)
  /// [filter] Filtro adicional
  /// [filterValue] Valor del filtro
  /// [filterType] Tipo de filtro
  /// [stockBajo] Filtrar por stock bajo
  /// [liquidacion] Filtrar productos en liquidación
  /// [stock] Filtrar productos por cantidad de stock, formato: {value: número, filterType: 'eq'|'gte'|'lte'|'ne'}
  Future<PaginatedResponse<Producto>> getProductos({
    required String sucursalId,
    int page = 1,
    int pageSize = 10,
    String? search,
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
      return await _productosApi.getProductos(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        search: search,
        sortBy: sortBy,
        order: order,
        filter: filter,
        filterValue: filterValue,
        filterType: filterType,
        stockBajo: stockBajo,
        liquidacion: liquidacion,
        stock: stock,
        useCache: useCache,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      debugPrint('Error en ProductoRepository.getProductos: $e');
      rethrow;
    }
  }

  /// Obtiene productos con stock bajo
  ///
  /// [sucursalId] ID de la sucursal
  /// [page] Número de página
  /// [pageSize] Tamaño de página
  Future<PaginatedResponse<Producto>> getProductosConStockBajo({
    required String sucursalId,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    bool useCache = true,
  }) async {
    try {
      return await _productosApi.getProductosConStockBajo(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint('Error en ProductoRepository.getProductosConStockBajo: $e');
      rethrow;
    }
  }

  /// Obtiene productos agotados (stock = 0)
  ///
  /// [sucursalId] ID de la sucursal
  /// [page] Número de página
  /// [pageSize] Tamaño de página
  Future<PaginatedResponse<Producto>> getProductosAgotados({
    required String sucursalId,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    bool useCache = true,
  }) async {
    try {
      return await _productosApi.getProductosAgotados(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint('Error en ProductoRepository.getProductosAgotados: $e');
      rethrow;
    }
  }

  /// Busca productos por nombre
  ///
  /// [sucursalId] ID de la sucursal
  /// [nombre] Término de búsqueda
  /// [page] Número de página
  /// [pageSize] Tamaño de página
  Future<PaginatedResponse<Producto>> buscarProductosPorNombre({
    required String sucursalId,
    required String nombre,
    int page = 1,
    int pageSize = 20,
    bool useCache = true,
  }) async {
    try {
      return await _productosApi.buscarProductosPorNombre(
        sucursalId: sucursalId,
        nombre: nombre,
        page: page,
        pageSize: pageSize,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint('Error en ProductoRepository.buscarProductosPorNombre: $e');
      rethrow;
    }
  }

  /// Obtiene un producto específico
  ///
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  Future<Producto?> getProducto({
    required String sucursalId,
    required int productoId,
    bool useCache = true,
  }) async {
    try {
      return await _productosApi.getProducto(
        sucursalId: sucursalId,
        productoId: productoId,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint('Error en ProductoRepository.getProducto: $e');
      return null;
    }
  }

  /// Crea un nuevo producto
  ///
  /// [sucursalId] ID de la sucursal
  /// [productoData] Datos del producto
  Future<Producto?> createProducto({
    required String sucursalId,
    required Map<String, dynamic> productoData,
  }) async {
    try {
      return await _productosApi.createProducto(
        sucursalId: sucursalId,
        productoData: productoData,
      );
    } catch (e) {
      debugPrint('Error en ProductoRepository.createProducto: $e');
      return null;
    }
  }

  /// Actualiza un producto existente
  ///
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  /// [productoData] Datos actualizados
  Future<Producto?> updateProducto({
    required String sucursalId,
    required int productoId,
    required Map<String, dynamic> productoData,
  }) async {
    try {
      return await _productosApi.updateProducto(
        sucursalId: sucursalId,
        productoId: productoId,
        productoData: productoData,
      );
    } catch (e) {
      debugPrint('Error en ProductoRepository.updateProducto: $e');
      return null;
    }
  }

  /// Elimina un producto
  ///
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  Future<bool> deleteProducto({
    required String sucursalId,
    required int productoId,
  }) async {
    try {
      return await _productosApi.deleteProducto(
        sucursalId: sucursalId,
        productoId: productoId,
      );
    } catch (e) {
      debugPrint('Error en ProductoRepository.deleteProducto: $e');
      return false;
    }
  }

  /// Actualiza el stock de un producto
  ///
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  /// [nuevoStock] Nueva cantidad de stock
  Future<Producto?> updateStock({
    required String sucursalId,
    required int productoId,
    required int nuevoStock,
  }) async {
    try {
      return await _productosApi.updateStock(
        sucursalId: sucursalId,
        productoId: productoId,
        nuevoStock: nuevoStock,
      );
    } catch (e) {
      debugPrint('Error en ProductoRepository.updateStock: $e');
      return null;
    }
  }

  /// Agrega stock al producto
  ///
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  /// [cantidad] Cantidad a agregar
  /// [motivo] Motivo del ingreso
  Future<bool> agregarStock({
    required String sucursalId,
    required int productoId,
    required int cantidad,
    String? motivo,
  }) async {
    try {
      return await _productosApi.agregarStock(
        sucursalId: sucursalId,
        productoId: productoId,
        cantidad: cantidad,
        motivo: motivo,
      );
    } catch (e) {
      debugPrint('Error en ProductoRepository.agregarStock: $e');
      return false;
    }
  }

  /// Disminuye stock del producto
  ///
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  /// [cantidad] Cantidad a restar
  /// [motivo] Motivo de la salida
  Future<bool> disminuirStock({
    required String sucursalId,
    required int productoId,
    required int cantidad,
    String? motivo,
  }) async {
    try {
      return await _productosApi.disminuirStock(
        sucursalId: sucursalId,
        productoId: productoId,
        cantidad: cantidad,
        motivo: motivo,
      );
    } catch (e) {
      debugPrint('Error en ProductoRepository.disminuirStock: $e');
      return false;
    }
  }

  /// Obtiene productos en liquidación
  ///
  /// [sucursalId] ID de la sucursal
  /// [page] Número de página
  /// [pageSize] Tamaño de página
  Future<PaginatedResponse<Producto>> getProductosEnLiquidacion({
    required String sucursalId,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    bool useCache = true,
  }) async {
    try {
      return await _productosApi.getProductosEnLiquidacion(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint('Error en ProductoRepository.getProductosEnLiquidacion: $e');
      rethrow;
    }
  }

  /// Pone o quita un producto de liquidación
  ///
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  /// [enLiquidacion] Si debe estar en liquidación
  /// [precioLiquidacion] Precio de liquidación
  Future<Producto?> setLiquidacion({
    required String sucursalId,
    required int productoId,
    required bool enLiquidacion,
    double? precioLiquidacion,
  }) async {
    try {
      return await _productosApi.setLiquidacion(
        sucursalId: sucursalId,
        productoId: productoId,
        enLiquidacion: enLiquidacion,
        precioLiquidacion: precioLiquidacion,
      );
    } catch (e) {
      debugPrint('Error en ProductoRepository.setLiquidacion: $e');
      return null;
    }
  }

  /// Busca productos por filtros combinados
  ///
  /// [sucursalId] ID de la sucursal
  /// [categoria] Categoría de productos
  /// [marca] Marca de productos
  /// [precioMinimo] Precio mínimo
  /// [precioMaximo] Precio máximo
  /// [stockPositivo] Solo productos con stock > 0
  /// [conPromocion] Solo productos con promoción
  Future<PaginatedResponse<Producto>> getProductosPorFiltros({
    required String sucursalId,
    String? categoria,
    String? marca,
    double? precioMinimo,
    double? precioMaximo,
    bool? stockPositivo,
    bool? conPromocion,
    int page = 1,
    int pageSize = 20,
    bool useCache = true,
  }) async {
    try {
      return await _productosApi.getProductosPorFiltros(
        sucursalId: sucursalId,
        categoria: categoria,
        marca: marca,
        precioMinimo: precioMinimo,
        precioMaximo: precioMaximo,
        stockPositivo: stockPositivo,
        conPromocion: conPromocion,
        page: page,
        pageSize: pageSize,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint('Error en ProductoRepository.getProductosPorFiltros: $e');
      rethrow;
    }
  }

  /// Obtiene productos con promociones
  ///
  /// [sucursalId] ID de la sucursal
  /// [tipoPromocion] Tipo de promoción ('cualquiera', 'liquidacion', 'gratis', 'porcentaje')
  /// [page] Número de página
  /// [pageSize] Tamaño de página
  Future<PaginatedResponse<Producto>> getProductosConPromocion({
    required String sucursalId,
    String tipoPromocion = 'cualquiera',
    int page = 1,
    int pageSize = 20,
    bool useCache = true,
  }) async {
    try {
      return await _productosApi.getProductosConPromocion(
        sucursalId: sucursalId,
        tipoPromocion: tipoPromocion,
        page: page,
        pageSize: pageSize,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint('Error en ProductoRepository.getProductosConPromocion: $e');
      rethrow;
    }
  }

  /// Obtiene productos más vendidos
  ///
  /// [sucursalId] ID de la sucursal
  /// [dias] Días a considerar
  /// [page] Número de página
  /// [pageSize] Tamaño de página
  Future<PaginatedResponse<Producto>> getProductosMasVendidos({
    required String sucursalId,
    int dias = 30,
    int page = 1,
    int pageSize = 20,
    bool useCache = false,
  }) async {
    try {
      return await _productosApi.getProductosMasVendidos(
        sucursalId: sucursalId,
        dias: dias,
        page: page,
        pageSize: pageSize,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint('Error en ProductoRepository.getProductosMasVendidos: $e');
      rethrow;
    }
  }

  /// Invalida la caché de productos
  void invalidateCache([String? sucursalId]) {
    _productosApi.invalidateCache(sucursalId);
  }

  /// Descarga un reporte Excel con todos los productos y su stock en todas las sucursales
  ///
  /// El reporte incluye una hoja principal con todos los productos y su stock por sucursal,
  /// y hojas adicionales con el detalle de cada sucursal.
  ///
  /// @returns bytes del archivo Excel para guardar o mostrar en la interfaz
  Future<List<int>?> getReporteExcel() async {
    try {
      return await _productosApi.getReporteExcel();
    } catch (e) {
      debugPrint('Error en ProductoRepository.getReporteExcel: $e');
      return null;
    }
  }

  /// Obtiene productos filtrados por cantidad de stock
  ///
  /// [sucursalId] ID de la sucursal
  /// [stockValue] Valor de stock para comparar
  /// [filterType] Tipo de comparación: 'eq' (igual), 'gte' (mayor o igual), 'lte' (menor o igual), 'ne' (diferente)
  /// [page] Número de página
  /// [pageSize] Tamaño de página
  /// [sortBy] Campo por el cual ordenar
  /// [order] Dirección del ordenamiento (asc/desc)
  /// [useCache] Usar caché
  Future<PaginatedResponse<Producto>> getProductosPorStock({
    required String sucursalId,
    required int stockValue,
    String filterType = 'eq',
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    String? order,
    bool useCache = true,
  }) async {
    try {
      // Validar que filterType sea uno de los valores permitidos
      if (!['eq', 'gte', 'lte', 'ne'].contains(filterType)) {
        throw ArgumentError(
            'filterType debe ser uno de los siguientes valores: eq, gte, lte, ne');
      }

      return await getProductos(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy ?? 'nombre',
        order: order ?? 'asc',
        stock: {
          'value': stockValue,
          'filterType': filterType,
        },
        useCache: useCache,
      );
    } catch (e) {
      debugPrint('Error en ProductoRepository.getProductosPorStock: $e');
      rethrow;
    }
  }

  /// Obtiene productos con stock exactamente igual a un valor
  ///
  /// [sucursalId] ID de la sucursal
  /// [stockValue] Valor exacto de stock a buscar
  /// [page] Número de página
  /// [pageSize] Tamaño de página
  /// [sortBy] Campo por el cual ordenar
  /// [order] Dirección del ordenamiento (asc/desc)
  /// [useCache] Usar caché
  Future<PaginatedResponse<Producto>> getProductosConStockIgualA({
    required String sucursalId,
    required int stockValue,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    String? order,
    bool useCache = true,
  }) async {
    try {
      return await getProductosPorStock(
        sucursalId: sucursalId,
        stockValue: stockValue,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        order: order,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint('Error en ProductoRepository.getProductosConStockIgualA: $e');
      rethrow;
    }
  }

  /// Obtiene productos con stock mayor o igual a un valor
  ///
  /// [sucursalId] ID de la sucursal
  /// [stockValue] Valor mínimo de stock
  /// [page] Número de página
  /// [pageSize] Tamaño de página
  /// [sortBy] Campo por el cual ordenar
  /// [order] Dirección del ordenamiento (asc/desc)
  /// [useCache] Usar caché
  Future<PaginatedResponse<Producto>> getProductosConStockMayorIgualA({
    required String sucursalId,
    required int stockValue,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    String? order,
    bool useCache = true,
  }) async {
    try {
      return await getProductosPorStock(
        sucursalId: sucursalId,
        stockValue: stockValue,
        filterType: 'gte', // Mayor o igual a
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        order: order,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint(
          'Error en ProductoRepository.getProductosConStockMayorIgualA: $e');
      rethrow;
    }
  }

  /// Obtiene productos con stock menor o igual a un valor
  ///
  /// [sucursalId] ID de la sucursal
  /// [stockValue] Valor máximo de stock
  /// [page] Número de página
  /// [pageSize] Tamaño de página
  /// [sortBy] Campo por el cual ordenar
  /// [order] Dirección del ordenamiento (asc/desc)
  /// [useCache] Usar caché
  Future<PaginatedResponse<Producto>> getProductosConStockMenorIgualA({
    required String sucursalId,
    required int stockValue,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    String? order,
    bool useCache = true,
  }) async {
    try {
      return await getProductosPorStock(
        sucursalId: sucursalId,
        stockValue: stockValue,
        filterType: 'lte', // Menor o igual a
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        order: order,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint(
          'Error en ProductoRepository.getProductosConStockMenorIgualA: $e');
      rethrow;
    }
  }

  /// Obtiene productos con stock diferente a un valor
  ///
  /// [sucursalId] ID de la sucursal
  /// [stockValue] Valor de stock a excluir
  /// [page] Número de página
  /// [pageSize] Tamaño de página
  /// [sortBy] Campo por el cual ordenar
  /// [order] Dirección del ordenamiento (asc/desc)
  /// [useCache] Usar caché
  Future<PaginatedResponse<Producto>> getProductosConStockDiferenteA({
    required String sucursalId,
    required int stockValue,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    String? order,
    bool useCache = true,
  }) async {
    try {
      return await getProductosPorStock(
        sucursalId: sucursalId,
        stockValue: stockValue,
        filterType: 'ne', // No igual a
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        order: order,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint(
          'Error en ProductoRepository.getProductosConStockDiferenteA: $e');
      rethrow;
    }
  }

  /// Añade un producto existente a una sucursal (POST)
  Future<Producto?> addProducto({
    required String sucursalId,
    required int productoId,
    required Map<String, dynamic> productoData,
  }) async {
    try {
      return await _productosApi.addProducto(
        sucursalId: sucursalId,
        productoId: productoId,
        productoData: productoData,
      );
    } catch (e) {
      debugPrint('Error en ProductoRepository.addProducto: $e');
      return null;
    }
  }
}
