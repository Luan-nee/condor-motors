import 'package:flutter/foundation.dart';
import '../main.api.dart';

class ProductosApi {
  final ApiClient _api;
  final String _endpoint = '/productos';
  
  ProductosApi(this._api);
  
  // Obtener todos los productos
  Future<List<dynamic>> getProductos({
    String? sucursalId,
    String? categoriaId,
    String? search,
    bool? disponible,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (sucursalId != null) {
        queryParams['sucursal_id'] = sucursalId;
      }
      
      if (categoriaId != null) {
        queryParams['categoria_id'] = categoriaId;
      }
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      if (disponible != null) {
        queryParams['disponible'] = disponible.toString();
      }
      
      final response = await _api.authenticatedRequest(
        endpoint: _endpoint,
        method: 'GET',
        queryParams: queryParams,
      );
      
      return response['data'] ?? [];
    } catch (e) {
      debugPrint('Error al obtener productos: $e');
      rethrow;
    }
  }
  
  // Obtener un producto específico
  Future<Map<String, dynamic>> getProducto(String id) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id',
        method: 'GET',
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al obtener producto: $e');
      rethrow;
    }
  }
  
  // Crear un nuevo producto
  Future<Map<String, dynamic>> createProducto(Map<String, dynamic> productoData) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: _endpoint,
        method: 'POST',
        body: productoData,
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al crear producto: $e');
      rethrow;
    }
  }
  
  // Actualizar un producto existente
  Future<Map<String, dynamic>> updateProducto(String id, Map<String, dynamic> productoData) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id',
        method: 'PATCH',
        body: productoData,
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al actualizar producto: $e');
      rethrow;
    }
  }
  
  // Eliminar un producto
  Future<bool> deleteProducto(String id) async {
    try {
      await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id',
        method: 'DELETE',
      );
      
      return true;
    } catch (e) {
      debugPrint('Error al eliminar producto: $e');
      return false;
    }
  }
  
  // Actualizar el stock de un producto
  Future<Map<String, dynamic>> updateStock(String id, int cantidad, String tipo) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id/stock',
        method: 'PATCH',
        body: {
          'cantidad': cantidad,
          'tipo': tipo,
        },
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al actualizar stock: $e');
      rethrow;
    }
  }
  
  /// Agregar un producto existente a una sucursal específica
  /// 
  /// [sucursalId] ID de la sucursal donde se agregará el producto
  /// [productoId] ID del producto a agregar
  /// [precioCompra] Precio de compra del producto (opcional)
  /// [precioVenta] Precio de venta del producto (opcional)
  /// [precioOferta] Precio de oferta del producto (opcional)
  /// [stock] Stock inicial del producto (opcional)
  Future<Map<String, dynamic>> addProductoToSucursal({
    required String sucursalId,
    required String productoId,
    double? precioCompra,
    double? precioVenta,
    double? precioOferta,
    int? stock,
  }) async {
    try {
      debugPrint('Agregando producto $productoId a sucursal $sucursalId');
      
      // Construir el cuerpo de la solicitud con los datos proporcionados
      final Map<String, dynamic> body = {};
      
      if (precioCompra != null) {
        body['precioCompra'] = precioCompra;
      }
      
      if (precioVenta != null) {
        body['precioVenta'] = precioVenta;
      }
      
      if (precioOferta != null) {
        body['precioOferta'] = precioOferta;
      }
      
      if (stock != null) {
        body['stock'] = stock;
      }
      
      // Construir el endpoint específico para la sucursal
      final endpoint = '/$sucursalId/productos/$productoId';
      
      final response = await _api.authenticatedRequest(
        endpoint: endpoint,
        method: 'POST',
        body: body,
      );
      
      debugPrint('Producto agregado correctamente a la sucursal');
      return response['data'];
    } catch (e) {
      debugPrint('Error al agregar producto a sucursal: $e');
      // Capturar más detalles sobre el error
      if (e is ApiException) {
        debugPrint('Código de error: ${e.statusCode}, Mensaje: ${e.message}');
        if (e.data != null) {
          debugPrint('Datos adicionales del error: ${e.data}');
        }
      }
      rethrow;
    }
  }
  
  /// Obtener todos los productos de una sucursal específica
  /// 
  /// [sucursalId] ID de la sucursal
  /// [categoriaId] Filtrar por categoría (opcional)
  /// [search] Buscar por nombre o código (opcional)
  Future<List<dynamic>> getProductosBySucursal({
    required String sucursalId,
    String? categoriaId,
    String? search,
  }) async {
    try {
      debugPrint('Obteniendo productos para sucursal $sucursalId');
      
      final queryParams = <String, String>{};
      
      if (categoriaId != null) {
        queryParams['categoria_id'] = categoriaId;
      }
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      // Construir el endpoint específico para la sucursal
      final endpoint = '/$sucursalId/productos';
      
      final response = await _api.authenticatedRequest(
        endpoint: endpoint,
        method: 'GET',
        queryParams: queryParams,
      );
      
      return response['data'] ?? [];
    } catch (e) {
      debugPrint('Error al obtener productos por sucursal: $e');
      rethrow;
    }
  }
  
  /// Obtener un producto específico de una sucursal
  /// 
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  Future<Map<String, dynamic>> getProductoBySucursal({
    required String sucursalId,
    required String productoId,
  }) async {
    try {
      // Construir el endpoint específico para la sucursal
      final endpoint = '/$sucursalId/productos/$productoId';
      
      final response = await _api.authenticatedRequest(
        endpoint: endpoint,
        method: 'GET',
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al obtener producto por sucursal: $e');
      rethrow;
    }
  }
  
  /// Actualizar un producto en una sucursal específica
  /// 
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  /// [productoData] Datos actualizados del producto
  Future<Map<String, dynamic>> updateProductoInSucursal({
    required String sucursalId,
    required String productoId,
    required Map<String, dynamic> productoData,
  }) async {
    try {
      // Construir el endpoint específico para la sucursal
      final endpoint = '/$sucursalId/productos/$productoId';
      
      final response = await _api.authenticatedRequest(
        endpoint: endpoint,
        method: 'PATCH',
        body: productoData,
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al actualizar producto en sucursal: $e');
      rethrow;
    }
  }
  
  /// Eliminar un producto de una sucursal específica
  /// 
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  Future<bool> deleteProductoFromSucursal({
    required String sucursalId,
    required String productoId,
  }) async {
    try {
      // Construir el endpoint específico para la sucursal
      final endpoint = '/$sucursalId/productos/$productoId';
      
      await _api.authenticatedRequest(
        endpoint: endpoint,
        method: 'DELETE',
      );
      
      return true;
    } catch (e) {
      debugPrint('Error al eliminar producto de sucursal: $e');
      return false;
    }
  }
}
