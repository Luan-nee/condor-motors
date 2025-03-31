import 'package:condorsmotors/api/protected/productos.api.dart';
import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:flutter/foundation.dart';

/// Repositorio para gestionar productos
///
/// Esta clase encapsula la lógica de negocio relacionada con productos,
/// actuando como una capa intermedia entre la UI y la API
class ProductoRepository {
  /// Instancia singleton del repositorio
  static final ProductoRepository _instance = ProductoRepository._internal();

  /// Getter para la instancia singleton
  static ProductoRepository get instance => _instance;

  /// API de productos
  late final ProductosApi _productosApi;

  /// Constructor privado para el patrón singleton
  ProductoRepository._internal() {
    _productosApi = api.productos;
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
}
