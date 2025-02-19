import 'package:flutter/material.dart';
import './api.service.dart';

class ProductosApi {
  final ApiService _api;

  ProductosApi(this._api);

  Future<List<Map<String, dynamic>>> getProducts({int skip = 0, int limit = 100}) async {
    try {
      final response = await _api.request(
        endpoint: '/productos',
        method: 'GET',
        queryParams: {
          'saltar': skip.toString(),
          'limite': limit.toString(),
        },
      );

      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      throw Exception('Formato de respuesta inválido');
    } catch (e) {
      debugPrint('Error al obtener productos: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> product) async {
    try {
      // Validar campos requeridos según la documentación
      final requiredFields = [
        'nombre', 'codigo', 'precio', 'precio_compra', 
        'existencias', 'descripcion', 'categoria', 
        'marca', 'local_id'
      ];

      for (var field in requiredFields) {
        if (!product.containsKey(field)) {
          throw Exception('Campo requerido faltante: $field');
        }
      }

      return await _api.request(
        endpoint: '/productos',
        method: 'POST',
        queryParams: const {},
        body: product,
      );
    } catch (e) {
      debugPrint('Error al crear producto: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> product) async {
    try {
      return await _api.request(
        endpoint: '/productos/$id',
        method: 'PUT',
        queryParams: const {},
        body: product,
      );
    } catch (e) {
      debugPrint('Error al actualizar producto: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _api.request(
        endpoint: '/productos/$id',
        method: 'DELETE',
        queryParams: const {},
      );
    } catch (e) {
      debugPrint('Error al eliminar producto: $e');
      rethrow;
    }
  }

  // Método para obtener productos con bajo stock
  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    try {
      final response = await _api.request(
        endpoint: '/productos/bajo-stock',
        method: 'GET',
        queryParams: const {},
      );

      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      throw Exception('Formato de respuesta inválido');
    } catch (e) {
      debugPrint('Error al obtener productos con bajo stock: $e');
      rethrow;
    }
  }

  // Método para obtener productos más vendidos
  Future<List<Map<String, dynamic>>> getBestSellingProducts() async {
    try {
      final response = await _api.request(
        endpoint: '/productos/mas-vendidos',
        method: 'GET',
        queryParams: const {},
      );

      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      throw Exception('Formato de respuesta inválido');
    } catch (e) {
      debugPrint('Error al obtener productos más vendidos: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getVendorInfo() async {
    try {
      final response = await _api.request(
        endpoint: '/usuarios/perfil',
        method: 'GET',
        queryParams: const {},
      );
      return response;
    } catch (e) {
      debugPrint('Error al obtener información del vendedor: $e');
      rethrow;
    }
  }

  Future<void> createSaleRequest(Map<String, dynamic> saleData) async {
    try {
      await _api.request(
        endpoint: '/ventas-pendientes',
        method: 'POST',
        queryParams: const {},
        body: saleData,
      );
    } catch (e) {
      debugPrint('Error al crear solicitud de venta: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getStock(String localId) async {
    try {
      final response = await _api.request(
        endpoint: '/stocks',
        method: 'GET',
        queryParams: {
          'local_id': localId,
        },
      );

      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      throw Exception('Formato de respuesta inválido');
    } catch (e) {
      debugPrint('Error al obtener stock: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProductStock(String localId, String productId) async {
    try {
      final response = await _api.request(
        endpoint: '/stocks/$localId/$productId',
        method: 'GET',
        queryParams: const {},
      );
      return response;
    } catch (e) {
      debugPrint('Error al obtener stock del producto: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProduct(String productId) async {
    try {
      final response = await _api.request(
        endpoint: '/productos/$productId',
        method: 'GET',
        queryParams: const {},
      );
      return response;
    } catch (e) {
      debugPrint('Error al obtener producto: $e');
      rethrow;
    }
  }
}
