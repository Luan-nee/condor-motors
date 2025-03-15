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
      
      final response = await _api.request(
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
      final response = await _api.request(
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
      final response = await _api.request(
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
      final response = await _api.request(
        endpoint: '$_endpoint/$id',
        method: 'PUT',
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
      await _api.request(
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
      final response = await _api.request(
        endpoint: '$_endpoint/$id/stock',
        method: 'PUT',
        body: {
          'cantidad': cantidad,
          'tipo': tipo, // "incremento" o "decremento"
        },
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al actualizar stock: $e');
      rethrow;
    }
  }
}
