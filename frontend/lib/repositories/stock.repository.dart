import 'package:condorsmotors/api/index.api.dart' as api_index;
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
      _productosApi = api_index.api.productos;
      _stocksApi = api_index.api.stocks;
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
  Future<Map<String, dynamic>?> getUserData() =>
      api_index.AuthManager.getUserData();

  /// Obtiene el ID de la sucursal del usuario actual
  ///
  /// Útil para operaciones que requieren el ID de sucursal automáticamente
  @override
  Future<String?> getCurrentSucursalId() =>
      api_index.AuthManager.getCurrentSucursalId();

  /// Obtiene todas las sucursales disponibles
  ///
  /// Útil para mostrar el selector de sucursales en la interfaz
  Future<List<Sucursal>> getSucursales() async {
    try {
      return await api_index.api.sucursales.getSucursales();
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
      debugPrint('[StockRepository] Solicitando productos con stock bajo');
      debugPrint(
          'Parámetros: sucursalId=$sucursalId, page=$page, pageSize=$pageSize, sortBy=$sortBy');

      // Usar el endpoint con stockBajo=true
      return await _productosApi.getProductos(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy ?? 'nombre',
        order: 'asc',
        stockBajo: true,
      );
    } catch (e) {
      debugPrint('[StockRepository] Error en getProductosConStockBajo: $e');
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
      debugPrint('[StockRepository] Solicitando productos agotados');
      debugPrint(
          'Parámetros: sucursalId=$sucursalId, page=$page, pageSize=$pageSize, sortBy=$sortBy');

      // Usar el endpoint con stock=0
      return await _productosApi.getProductos(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy ?? 'nombre',
        order: 'asc',
        stock: {'value': 0, 'filterType': 'eq'}, // stock igual a 0
      );
    } catch (e) {
      debugPrint('[StockRepository] Error en getProductosAgotados: $e');
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
      debugPrint('[StockRepository] Solicitando productos disponibles');
      debugPrint(
          'Parámetros: sucursalId=$sucursalId, page=$page, pageSize=$pageSize, sortBy=$sortBy');

      // Usar el endpoint con stock>=1 para obtener todos los productos con al menos 1 unidad
      return await _productosApi.getProductos(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy ?? 'nombre',
        order: 'asc',
        stock: {'value': 1, 'filterType': 'gte'}, // stock mayor o igual a 1
      );
    } catch (e) {
      debugPrint('[StockRepository] Error en getProductosDisponibles: $e');
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
    Map<String, dynamic>? stock,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      debugPrint('[StockRepository] Solicitando productos');
      debugPrint(
          'Parámetros: sucursalId=$sucursalId, page=$page, pageSize=$pageSize, search=$search, sortBy=$sortBy, order=$order, stockBajo=$stockBajo, stock=$stock');

      return await _productosApi.getProductos(
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
    } catch (e) {
      debugPrint('[StockRepository] Error en getProductos: $e');
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

  /// Método para invalidar la caché de productos
  void invalidateCache(String? sucursalId) {
    debugPrint(
        '[StockRepository] Invalidando caché para sucursal: $sucursalId');
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

  /// Método para obtener productos por stock con soporte para null
  Future<PaginatedResponse<Producto>> getProductosPorStock({
    required String sucursalId,
    required stockValue, // Cambiado a dynamic para soportar null
    required String filterType,
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

      // Crear el filtro de stock
      final Map<String, dynamic> stock = {
        'value': stockValue,
        'filterType': filterType,
      };

      debugPrint('[StockRepository] Solicitando productos por stock');
      debugPrint('Filtro de stock: $stock');

      // Usar el método general de obtención de productos con el filtro de stock
      return await getProductos(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy ?? 'nombre',
        order: order ?? 'asc',
        stock: stock,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint('[StockRepository] Error en getProductosPorStock: $e');
      rethrow;
    }
  }

  /// Obtiene productos filtrados por cantidad de stock con tipo de filtro y opciones adicionales
  ///
  /// [sucursalId] ID de la sucursal
  /// [filtroStock] Configuración del filtro de stock {valor: int, tipo: 'eq'|'gte'|'lte'|'ne'}
  /// [options] Opciones adicionales (paginación, ordenamiento, búsqueda)
  Future<PaginatedResponse<Producto>> getProductosFiltrados({
    required String sucursalId,
    Map<String, dynamic>? filtroStock,
    Map<String, dynamic>? options,
  }) async {
    try {
      // Valores por defecto para opciones
      final page = options?['page'] ?? 1;
      final pageSize = options?['pageSize'] ?? 20;
      final sortBy = options?['sortBy'] ?? 'nombre';
      final order = options?['order'] ?? 'asc';
      final search = options?['search'];
      final bool useCache = options?['useCache'] ?? true;

      // Si tiene filtro de stock, usar el método especializado
      if (filtroStock != null) {
        final stockValue = filtroStock['value'] as int;
        final filterType = filtroStock['filterType'] as String;

        return await getProductosPorStock(
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

      // Si tiene filtro de estado (stockBajo, agotado, etc.)
      if (options?['estado'] != null) {
        final estado = options?['estado'] as String;

        switch (estado) {
          case 'stockBajo':
            return await getProductosConStockBajo(
              sucursalId: sucursalId,
              page: page,
              pageSize: pageSize,
              sortBy: sortBy,
            );
          case 'agotado':
            return await getProductosAgotados(
              sucursalId: sucursalId,
              page: page,
              pageSize: pageSize,
              sortBy: sortBy,
            );
          case 'disponible':
            return await getProductosDisponibles(
              sucursalId: sucursalId,
              page: page,
              pageSize: pageSize,
              sortBy: sortBy,
            );
        }
      }

      // Caso general: obtener productos con posibles filtros de búsqueda
      return await getProductos(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        search: search,
        sortBy: sortBy,
        order: order,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint('Error en StockRepository.getProductosFiltrados: $e');
      rethrow;
    }
  }
}
