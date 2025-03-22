import 'package:flutter/foundation.dart';

import '../../models/paginacion.model.dart';
import '../../models/producto.model.dart';
import '../main.api.dart';

class ProductosApi {
  final ApiClient _api;
  
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
  }) async {
    try {
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
      
      debugPrint('Obteniendo productos para sucursal $sucursalId con parámetros: $queryParams');
      
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
      return PaginatedResponse<Producto>(
        items: productos,
        paginacion: Paginacion.fromJson(paginacionData),
        metadata: metadata,
      );
    } catch (e) {
      debugPrint('Error al obtener productos: $e');
      rethrow;
    }
  }
  
  /// Obtiene un producto específico de una sucursal
  /// 
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  Future<Producto> getProducto({
    required String sucursalId,
    required int productoId,
  }) async {
    try {
      debugPrint('Obteniendo producto $productoId de sucursal $sucursalId');
      
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos/$productoId',
        method: 'GET',
      );
      
      return Producto.fromJson(response['data']);
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
      
      return await updateProducto(
        sucursalId: sucursalId,
        productoId: productoId,
        productoData: {
          'stock': nuevoStock,
        },
      );
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
      
      return true;
    } catch (e) {
      debugPrint('Error al agregar stock: $e');
      rethrow;
    }
  }
}
