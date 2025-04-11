import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/foundation.dart';

/// Repositorio para gestionar el stock de productos
///
/// Esta clase encapsula la lógica de negocio relacionada con el stock,
/// actuando como una capa intermedia entre la UI y la API
class StockRepository implements BaseRepository {
  /// Instancia singleton del repositorio
  static final StockRepository _instance = StockRepository._internal();

  /// Getter para la instancia singleton
  static StockRepository get instance => _instance;

  /// API de productos para operaciones específicas de productos
  late final dynamic _productosApi;

  /// API de stocks para operaciones específicas de stock
  late final dynamic _stocksApi;

  /// Constructor privado para el patrón singleton
  StockRepository._internal() {
    try {
      // Utilizamos la API global inicializada en index.api.dart
      _productosApi = api.productos;
      _stocksApi = api.stocks;
    } catch (e) {
      debugPrint('Error al obtener APIs: $e');
      // Si hay un error al acceder a la API global, lanzamos una excepción
      throw Exception('No se pudo inicializar StockRepository: $e');
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
      debugPrint('Error en StockRepository.getUserData: $e');
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
      debugPrint('Error en StockRepository.getCurrentSucursalId: $e');
      return null;
    }
  }

  /// Obtiene todas las sucursales disponibles
  ///
  /// Útil para mostrar el selector de sucursales en la interfaz
  Future<List<Sucursal>> getSucursales() async {
    try {
      return await api.sucursales.getSucursales();
    } catch (e) {
      debugPrint('Error en StockRepository.getSucursales: $e');
      rethrow;
    }
  }

  /// Obtiene productos con stock bajo de una sucursal específica
  ///
  /// [sucursalId] ID de la sucursal
  /// [page] Número de página para paginación
  /// [pageSize] Tamaño de página
  /// [sortBy] Campo por el cual ordenar
  Future<PaginatedResponse<Producto>> getProductosConStockBajo({
    required String sucursalId,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
  }) async {
    try {
      return await _productosApi.getProductosConStockBajo(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
      );
    } catch (e) {
      debugPrint('Error en StockRepository.getProductosConStockBajo: $e');
      rethrow;
    }
  }

  /// Obtiene productos agotados (stock = 0) de una sucursal específica
  ///
  /// [sucursalId] ID de la sucursal
  /// [page] Número de página para paginación
  /// [pageSize] Tamaño de página
  /// [sortBy] Campo por el cual ordenar
  Future<PaginatedResponse<Producto>> getProductosAgotados({
    required String sucursalId,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
  }) async {
    try {
      return await _productosApi.getProductosAgotados(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
      );
    } catch (e) {
      debugPrint('Error en StockRepository.getProductosAgotados: $e');
      rethrow;
    }
  }

  /// Obtiene productos disponibles (stock > 0) de una sucursal específica
  ///
  /// [sucursalId] ID de la sucursal
  /// [page] Número de página para paginación
  /// [pageSize] Tamaño de página
  /// [sortBy] Campo por el cual ordenar
  Future<PaginatedResponse<Producto>> getProductosDisponibles({
    required String sucursalId,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
  }) async {
    try {
      return await _productosApi.getProductosDisponibles(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
      );
    } catch (e) {
      debugPrint('Error en StockRepository.getProductosDisponibles: $e');
      rethrow;
    }
  }

  /// Obtiene todos los productos de una sucursal específica
  ///
  /// [sucursalId] ID de la sucursal
  /// [page] Número de página para paginación
  /// [pageSize] Tamaño de página
  /// [search] Término de búsqueda
  /// [sortBy] Campo por el cual ordenar
  /// [order] Dirección de ordenamiento
  /// [stockBajo] Filtro para productos con stock bajo
  Future<PaginatedResponse<Producto>> getProductos({
    required String sucursalId,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    String? order,
    bool? stockBajo,
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
        stockBajo: stockBajo,
        useCache: useCache,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      debugPrint('Error en StockRepository.getProductos: $e');
      rethrow;
    }
  }

  /// Busca productos por nombre en una sucursal específica
  ///
  /// [sucursalId] ID de la sucursal
  /// [nombre] Término de búsqueda
  /// [page] Número de página para paginación
  /// [pageSize] Tamaño de página
  Future<PaginatedResponse<Producto>> buscarProductosPorNombre({
    required String sucursalId,
    required String nombre,
    int page = 1,
    int pageSize = 20,
    bool useCache = false,
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
      debugPrint('Error en StockRepository.buscarProductosPorNombre: $e');
      rethrow;
    }
  }

  /// Invalida la caché de productos para una sucursal específica
  ///
  /// [sucursalId] ID de la sucursal. Si es null, invalida toda la caché.
  void invalidateCache(String? sucursalId) {
    _productosApi.invalidateCache(sucursalId);
  }

  /// Obtiene el stock de todos los productos de una sucursal específica usando el API de stocks
  ///
  /// [sucursalId] ID de la sucursal para consultar el stock
  /// [categoriaId] Opcional. Filtrar por categoría
  /// [search] Opcional. Búsqueda por nombre de producto
  /// [stockBajo] Opcional. Filtrar productos con stock bajo
  Future<List<dynamic>> getStockBySucursal({
    required String sucursalId,
    String? categoriaId,
    String? search,
    bool? stockBajo,
  }) async {
    try {
      return await _stocksApi.getStockBySucursal(
        sucursalId: sucursalId,
        categoriaId: categoriaId,
        search: search,
        stockBajo: stockBajo,
      );
    } catch (e) {
      debugPrint('Error en StockRepository.getStockBySucursal: $e');
      rethrow;
    }
  }

  /// Obtiene productos con stock bajo de una sucursal usando el API de stocks
  ///
  /// [sucursalId] ID de la sucursal
  Future<List<dynamic>> getProductosStockBajo(String sucursalId) async {
    try {
      return await _stocksApi.getProductosStockBajo(sucursalId);
    } catch (e) {
      debugPrint('Error en StockRepository.getProductosStockBajo: $e');
      rethrow;
    }
  }

  /// Actualiza el stock de un producto en una sucursal
  ///
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  /// [cantidad] Cantidad a modificar
  /// [tipo] Tipo de operación ("incremento" o "decremento")
  Future<Map<String, dynamic>> updateStock(
    String sucursalId,
    String productoId,
    int cantidad,
    String tipo,
  ) async {
    try {
      return await _stocksApi.updateStock(
        sucursalId,
        productoId,
        cantidad,
        tipo,
      );
    } catch (e) {
      debugPrint('Error en StockRepository.updateStock: $e');
      rethrow;
    }
  }

  /// Registra un movimiento de stock (entrada o salida)
  ///
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  /// [cantidad] Cantidad de productos
  /// [tipo] Tipo de movimiento ("entrada" o "salida")
  /// [motivo] Motivo del movimiento (opcional)
  Future<Map<String, dynamic>> registrarMovimientoStock(
    String sucursalId,
    String productoId,
    int cantidad,
    String tipo, {
    String? motivo,
  }) async {
    try {
      return await _stocksApi.registrarMovimientoStock(
        sucursalId,
        productoId,
        cantidad,
        tipo,
        motivo: motivo,
      );
    } catch (e) {
      debugPrint('Error en StockRepository.registrarMovimientoStock: $e');
      rethrow;
    }
  }

  /// Obtiene el historial de movimientos de stock de un producto
  ///
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto (opcional)
  /// [fechaInicio] Fecha de inicio para filtrar (opcional)
  /// [fechaFin] Fecha de fin para filtrar (opcional)
  Future<List<dynamic>> getHistorialStock(
    String sucursalId, {
    String? productoId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      return await _stocksApi.getHistorialStock(
        sucursalId,
        productoId: productoId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
    } catch (e) {
      debugPrint('Error en StockRepository.getHistorialStock: $e');
      rethrow;
    }
  }

  /// Realiza una transferencia de stock entre sucursales
  ///
  /// [sucursalOrigenId] ID de la sucursal de origen
  /// [sucursalDestinoId] ID de la sucursal de destino
  /// [productos] Lista de productos a transferir con sus cantidades
  Future<Map<String, dynamic>> transferirStock(
    String sucursalOrigenId,
    String sucursalDestinoId,
    List<Map<String, dynamic>> productos,
  ) async {
    try {
      return await _stocksApi.transferirStock(
        sucursalOrigenId,
        sucursalDestinoId,
        productos,
      );
    } catch (e) {
      debugPrint('Error en StockRepository.transferirStock: $e');
      rethrow;
    }
  }

  /// Genera un reporte de stock de una sucursal
  ///
  /// [sucursalId] ID de la sucursal
  /// [formato] Formato del reporte ("pdf", "excel", etc.)
  Future<String> generarReporteStock(
    String sucursalId,
    String formato,
  ) async {
    try {
      return await _stocksApi.generarReporteStock(sucursalId, formato);
    } catch (e) {
      debugPrint('Error en StockRepository.generarReporteStock: $e');
      rethrow;
    }
  }
}
