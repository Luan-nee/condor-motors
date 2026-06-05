import 'dart:io';

import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/api/protected/productos.api.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';

/// Repositorio para gestionar productos.
///
/// Encapsula la lógica de negocio y consumo de APIs de productos,
/// delegando la autenticación mediante el mixin [AuthDelegator].
class ProductoRepository with AuthDelegator implements BaseRepository {
  static final ProductoRepository _instance = ProductoRepository._internal();
  static ProductoRepository get instance => _instance;

  late final ProductosApi _productosApi;

  ProductoRepository._internal() {
    _productosApi = api_index.api.productos;
  }

  /// Obtiene los productos de una sucursal con filtros y paginación.
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
  }) =>
      _productosApi.getProductos(
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

  /// Obtiene productos con stock bajo.
  Future<PaginatedResponse<Producto>> getProductosConStockBajo({
    required String sucursalId,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    bool useCache = true,
  }) =>
      _productosApi.getProductosConStockBajo(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        useCache: useCache,
      );

  /// Obtiene productos agotados (stock = 0).
  Future<PaginatedResponse<Producto>> getProductosAgotados({
    required String sucursalId,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    bool useCache = true,
  }) =>
      _productosApi.getProductosAgotados(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        useCache: useCache,
      );

  /// Busca productos por coincidencia de nombre.
  Future<PaginatedResponse<Producto>> buscarProductosPorNombre({
    required String sucursalId,
    required String nombre,
    int page = 1,
    int pageSize = 20,
    bool useCache = true,
  }) =>
      _productosApi.buscarProductosPorNombre(
        sucursalId: sucursalId,
        nombre: nombre,
        page: page,
        pageSize: pageSize,
        useCache: useCache,
      );

  /// Obtiene un producto específico por ID.
  Future<Producto?> getProducto({
    required String sucursalId,
    required int productoId,
    bool useCache = true,
  }) =>
      _productosApi.getProducto(
        sucursalId: sucursalId,
        productoId: productoId,
        useCache: useCache,
      );

  /// Crea un nuevo producto con imagen opcional.
  Future<Producto?> createProducto({
    required String sucursalId,
    required Map<String, dynamic> productoData,
    File? fotoFile,
  }) =>
      _productosApi.createProducto(
        sucursalId: sucursalId,
        productoData: productoData,
        fotoFile: fotoFile,
      );

  /// Actualiza un producto existente.
  Future<Producto?> updateProducto({
    required String sucursalId,
    required int productoId,
    required Map<String, dynamic> productoData,
    File? fotoFile,
  }) =>
      _productosApi.updateProducto(
        sucursalId: sucursalId,
        productoId: productoId,
        productoData: productoData,
        fotoFile: fotoFile,
      );

  /// Elimina un producto de una sucursal.
  Future<bool> deleteProducto({
    required String sucursalId,
    required int productoId,
  }) =>
      _productosApi.deleteProducto(
        sucursalId: sucursalId,
        productoId: productoId,
      );

  /// Actualiza el stock directo de un producto.
  Future<Producto?> updateStock({
    required String sucursalId,
    required int productoId,
    required int nuevoStock,
  }) =>
      _productosApi.updateStock(
        sucursalId: sucursalId,
        productoId: productoId,
        nuevoStock: nuevoStock,
      );

  /// Incrementa el stock de un producto.
  Future<bool> agregarStock({
    required String sucursalId,
    required int productoId,
    required int cantidad,
    String? motivo,
  }) =>
      _productosApi.agregarStock(
        sucursalId: sucursalId,
        productoId: productoId,
        cantidad: cantidad,
        motivo: motivo,
      );

  /// Disminuye el stock de un producto.
  Future<bool> disminuirStock({
    required String sucursalId,
    required int productoId,
    required int cantidad,
    String? motivo,
  }) =>
      _productosApi.disminuirStock(
        sucursalId: sucursalId,
        productoId: productoId,
        cantidad: cantidad,
        motivo: motivo,
      );

  /// Obtiene productos marcados en liquidación.
  Future<PaginatedResponse<Producto>> getProductosEnLiquidacion({
    required String sucursalId,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    bool useCache = true,
  }) =>
      _productosApi.getProductosEnLiquidacion(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        useCache: useCache,
      );

  /// Configura el estado de liquidación de un producto.
  Future<Producto?> setLiquidacion({
    required String sucursalId,
    required int productoId,
    required bool enLiquidacion,
    double? precioLiquidacion,
  }) =>
      _productosApi.setLiquidacion(
        sucursalId: sucursalId,
        productoId: productoId,
        enLiquidacion: enLiquidacion,
        precioLiquidacion: precioLiquidacion,
      );

  /// Busca productos usando filtros combinados avanzados.
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
  }) =>
      _productosApi.getProductosPorFiltros(
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

  /// Obtiene productos que posean promociones activas.
  Future<PaginatedResponse<Producto>> getProductosConPromocion({
    required String sucursalId,
    String tipoPromocion = 'cualquiera',
    int page = 1,
    int pageSize = 20,
    bool useCache = true,
  }) =>
      _productosApi.getProductosConPromocion(
        sucursalId: sucursalId,
        tipoPromocion: tipoPromocion,
        page: page,
        pageSize: pageSize,
        useCache: useCache,
      );

  /// Obtiene productos más vendidos.
  Future<PaginatedResponse<Producto>> getProductosMasVendidos({
    required String sucursalId,
    int dias = 30,
    int page = 1,
    int pageSize = 20,
    bool useCache = false,
  }) =>
      _productosApi.getProductosMasVendidos(
        sucursalId: sucursalId,
        dias: dias,
        page: page,
        pageSize: pageSize,
        useCache: useCache,
      );

  /// Invalida la caché local de productos.
  void invalidateCache([String? sucursalId]) =>
      _productosApi.invalidateCache(sucursalId);

  /// Descarga un reporte Excel de stock consolidado de productos.
  Future<List<int>?> getReporteExcel() =>
      _productosApi.getReporteExcel();

  /// Obtiene productos comparando cantidades de stock bajo un filtro relacional.
  Future<PaginatedResponse<Producto>> getProductosPorStock({
    required String sucursalId,
    required int stockValue,
    String filterType = 'eq',
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    String? order,
    bool useCache = true,
  }) {
    if (!['eq', 'gte', 'lte', 'ne'].contains(filterType)) {
      throw ArgumentError(
          'filterType debe ser uno de los siguientes valores: eq, gte, lte, ne');
    }

    return getProductos(
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
  }

  /// Obtiene productos con stock exactamente igual a un valor.
  Future<PaginatedResponse<Producto>> getProductosConStockIgualA({
    required String sucursalId,
    required int stockValue,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    String? order,
    bool useCache = true,
  }) =>
      getProductosPorStock(
        sucursalId: sucursalId,
        stockValue: stockValue,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        order: order,
        useCache: useCache,
      );

  /// Obtiene productos con stock mayor o igual a un valor.
  Future<PaginatedResponse<Producto>> getProductosConStockMayorIgualA({
    required String sucursalId,
    required int stockValue,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    String? order,
    bool useCache = true,
  }) =>
      getProductosPorStock(
        sucursalId: sucursalId,
        stockValue: stockValue,
        filterType: 'gte',
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        order: order,
        useCache: useCache,
      );

  /// Obtiene productos con stock menor o igual a un valor.
  Future<PaginatedResponse<Producto>> getProductosConStockMenorIgualA({
    required String sucursalId,
    required int stockValue,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    String? order,
    bool useCache = true,
  }) =>
      getProductosPorStock(
        sucursalId: sucursalId,
        stockValue: stockValue,
        filterType: 'lte',
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        order: order,
        useCache: useCache,
      );

  /// Obtiene productos con stock diferente a un valor.
  Future<PaginatedResponse<Producto>> getProductosConStockDiferenteA({
    required String sucursalId,
    required int stockValue,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    String? order,
    bool useCache = true,
  }) =>
      getProductosPorStock(
        sucursalId: sucursalId,
        stockValue: stockValue,
        filterType: 'ne',
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        order: order,
        useCache: useCache,
      );

  /// Asocia un producto existente a otra sucursal.
  Future<Producto?> addProducto({
    required String sucursalId,
    required int productoId,
    required Map<String, dynamic> productoData,
  }) =>
      _productosApi.addProducto(
        sucursalId: sucursalId,
        productoId: productoId,
        productoData: productoData,
      );

  /// Obtiene la URL de la imagen del producto.
  static String? getProductoImageUrl(Producto producto) {
    final String baseUrl = api_index.api.getBaseUrlSinApi();
    return producto.getFotoUrlCompleta(baseUrl);
  }
}
