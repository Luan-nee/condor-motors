import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';

/// Repositorio para gestionar el stock de productos.
///
/// Encapsula la lógica de negocio y consumo de APIs de stocks y productos,
/// delegando la autenticación mediante el mixin [AuthDelegator].
class StockRepository with AuthDelegator implements BaseRepository {
  static final StockRepository _instance = StockRepository._internal();
  static StockRepository get instance => _instance;

  late final dynamic _productosApi;
  late final dynamic _stocksApi;

  StockRepository._internal() {
    _productosApi = api_index.api.productos;
    _stocksApi = api_index.api.stocks;
  }

  /// Obtiene todas las sucursales disponibles.
  Future<List<Sucursal>> getSucursales() =>
      api_index.api.sucursales.getSucursales();

  /// Obtiene productos con stock bajo de una sucursal específica.
  Future<PaginatedResponse<Producto>> getProductosConStockBajo({
    required String sucursalId,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
  }) =>
      _productosApi.getProductos(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy ?? 'nombre',
        order: 'asc',
        stockBajo: true,
      );

  /// Obtiene productos agotados (stock = 0) de una sucursal específica.
  Future<PaginatedResponse<Producto>> getProductosAgotados({
    required String sucursalId,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
  }) =>
      _productosApi.getProductos(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy ?? 'nombre',
        order: 'asc',
        stock: const {'value': 0, 'filterType': 'eq'},
      );

  /// Obtiene productos disponibles (stock > 0) de una sucursal específica.
  Future<PaginatedResponse<Producto>> getProductosDisponibles({
    required String sucursalId,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
  }) =>
      _productosApi.getProductos(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy ?? 'nombre',
        order: 'asc',
        stock: const {'value': 1, 'filterType': 'gte'},
      );

  /// Obtiene todos los productos de una sucursal específica.
  Future<PaginatedResponse<Producto>> getProductos({
    required String sucursalId,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    String? order,
    bool? stockBajo,
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
        stockBajo: stockBajo,
        stock: stock,
        useCache: useCache,
        forceRefresh: forceRefresh,
      );

  /// Busca productos por nombre en una sucursal específica.
  Future<PaginatedResponse<Producto>> buscarProductosPorNombre({
    required String sucursalId,
    required String nombre,
    int page = 1,
    int pageSize = 20,
    bool useCache = false,
  }) =>
      _productosApi.buscarProductosPorNombre(
        sucursalId: sucursalId,
        nombre: nombre,
        page: page,
        pageSize: pageSize,
        useCache: useCache,
      );

  /// Invalida la caché de productos.
  void invalidateCache(String? sucursalId) =>
      _productosApi.invalidateCache(sucursalId);

  /// Obtiene el stock de todos los productos de una sucursal específica.
  Future<List<dynamic>> getStockBySucursal({
    required String sucursalId,
    String? categoriaId,
    String? search,
    bool? stockBajo,
  }) =>
      _stocksApi.getStockBySucursal(
        sucursalId: sucursalId,
        categoriaId: categoriaId,
        search: search,
        stockBajo: stockBajo,
      );

  /// Obtiene productos con stock bajo de una sucursal usando el API de stocks.
  Future<List<dynamic>> getProductosStockBajo(String sucursalId) =>
      _stocksApi.getProductosStockBajo(sucursalId);

  /// Actualiza el stock de un producto en una sucursal.
  Future<Map<String, dynamic>> updateStock(
    String sucursalId,
    String productoId,
    int cantidad,
    String tipo,
  ) =>
      _stocksApi.updateStock(
        sucursalId,
        productoId,
        cantidad,
        tipo,
      );

  /// Registra un movimiento de stock (entrada o salida).
  Future<Map<String, dynamic>> registrarMovimientoStock(
    String sucursalId,
    String productoId,
    int cantidad,
    String tipo, {
    String? motivo,
  }) =>
      _stocksApi.registrarMovimientoStock(
        sucursalId,
        productoId,
        cantidad,
        tipo,
        motivo: motivo,
      );

  /// Obtiene el historial de movimientos de stock de un producto.
  Future<List<dynamic>> getHistorialStock(
    String sucursalId, {
    String? productoId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) =>
      _stocksApi.getHistorialStock(
        sucursalId,
        productoId: productoId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );

  /// Realiza una transferencia de stock entre sucursales.
  Future<Map<String, dynamic>> transferirStock(
    String sucursalOrigenId,
    String sucursalDestinoId,
    List<Map<String, dynamic>> productos,
  ) =>
      _stocksApi.transferirStock(
        sucursalOrigenId,
        sucursalDestinoId,
        productos,
      );

  /// Genera un reporte de stock de una sucursal.
  Future<String> generarReporteStock(
    String sucursalId,
    String formato,
  ) =>
      _stocksApi.generarReporteStock(sucursalId, formato);

  /// Obtiene productos por stock.
  Future<PaginatedResponse<Producto>> getProductosPorStock({
    required String sucursalId,
    required int? stockValue,
    required String filterType,
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

  /// Obtiene productos filtrados por cantidad de stock con opciones adicionales.
  Future<PaginatedResponse<Producto>> getProductosFiltrados({
    required String sucursalId,
    Map<String, dynamic>? filtroStock,
    Map<String, dynamic>? options,
  }) {
    final page = options?['page'] ?? 1;
    final pageSize = options?['pageSize'] ?? 20;
    final sortBy = options?['sortBy'] ?? 'nombre';
    final order = options?['order'] ?? 'asc';
    final search = options?['search'];
    final bool useCache = options?['useCache'] ?? true;

    if (filtroStock != null) {
      final stockValue = filtroStock['value'] as int;
      final filterType = filtroStock['filterType'] as String;

      return getProductosPorStock(
        sucursalId: sucursalId,
        stockValue: stockValue,
        filterType: filterType,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        order: order,
        useCache: useCache,
      );
    }

    if (options?['estado'] != null) {
      final estado = options?['estado'] as String;

      switch (estado) {
        case 'stockBajo':
          return getProductosConStockBajo(
            sucursalId: sucursalId,
            page: page,
            pageSize: pageSize,
            sortBy: sortBy,
          );
        case 'agotado':
          return getProductosAgotados(
            sucursalId: sucursalId,
            page: page,
            pageSize: pageSize,
            sortBy: sortBy,
          );
        case 'disponible':
          return getProductosDisponibles(
            sucursalId: sucursalId,
            page: page,
            pageSize: pageSize,
            sortBy: sortBy,
          );
      }
    }

    return getProductos(
      sucursalId: sucursalId,
      page: page,
      pageSize: pageSize,
      search: search,
      sortBy: sortBy,
      order: order,
      useCache: useCache,
    );
  }
}
