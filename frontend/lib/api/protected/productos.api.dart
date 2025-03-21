import 'package:flutter/foundation.dart';
import '../main.api.dart';
import '../../models/producto.model.dart';

class ProductosApi {
  final ApiClient _api;
  
  ProductosApi(this._api);
  
  /// Obtiene todos los productos de una sucursal específica
  /// 
  /// [sucursalId] ID de la sucursal
  /// [search] Término de búsqueda para filtrar productos (opcional)
  /// [categoriaId] ID de la categoría para filtrar (opcional)
  /// [marcaId] ID de la marca para filtrar (opcional)
  /// [colorId] ID del color para filtrar (opcional)
  /// [page] Número de página para paginación (opcional)
  /// [limit] Límite de resultados por página (opcional)
  Future<List<Producto>> getProductos({
    required String sucursalId,
    String? search,
    int? categoriaId,
    int? marcaId,
    int? colorId,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      if (categoriaId != null) {
        queryParams['categoriaId'] = categoriaId.toString();
      }
      
      if (marcaId != null) {
        queryParams['marcaId'] = marcaId.toString();
      }
      
      if (colorId != null) {
        queryParams['colorId'] = colorId.toString();
      }
      
      if (page != null) {
        queryParams['page'] = page.toString();
      }
      
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }
      
      debugPrint('Obteniendo productos para sucursal $sucursalId');
      
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos',
        method: 'GET',
        queryParams: queryParams,
      );
      
      final List<dynamic> rawData = response['data'] ?? [];
      return rawData.map((item) => Producto.fromJson(item)).toList();
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
}
