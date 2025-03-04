import 'package:flutter/foundation.dart';
import 'main.api.dart';

class CategoriasApi {
  final ApiService _api;
  final String _endpoint = '/categorias';

  CategoriasApi(this._api);

  // Obtener todas las categorías
  Future<List<Map<String, dynamic>>> getCategorias() async {
    try {
      final response = await _api.request(
        endpoint: _endpoint,
        method: 'GET',
      );

      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al obtener categorías: $e');
      return [];
    }
  }

  // Obtener una categoría por ID
  Future<Map<String, dynamic>?> getCategoria(int id) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'GET',
      );

      if (response == null || (response as List).isEmpty) return null;
      return Map<String, dynamic>.from(response[0]);
    } catch (e) {
      debugPrint('Error al obtener categoría: $e');
      return null;
    }
  }

  // Crear una nueva categoría
  Future<Map<String, dynamic>> createCategoria(Map<String, dynamic> categoria) async {
    try {
      // Validación básica
      if (!categoria.containsKey('nombre')) {
        throw Exception('El nombre es requerido');
      }

      final response = await _api.request(
        endpoint: _endpoint,
        method: 'POST',
        body: categoria,
      );

      return response ?? {};
    } catch (e) {
      debugPrint('Error al crear categoría: $e');
      rethrow;
    }
  }

  // Actualizar una categoría
  Future<void> updateCategoria(int id, Map<String, dynamic> categoria) async {
    try {
      if (!categoria.containsKey('nombre')) {
        throw Exception('El nombre es requerido');
      }

      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'PUT',
        body: categoria,
      );
    } catch (e) {
      debugPrint('Error al actualizar categoría: $e');
      rethrow;
    }
  }

  // Eliminar una categoría
  Future<void> deleteCategoria(int id) async {
    try {
      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'DELETE',
      );
    } catch (e) {
      debugPrint('Error al eliminar categoría: $e');
      rethrow;
    }
  }

  // Buscar categorías por nombre
  Future<List<Map<String, dynamic>>> searchCategorias(String query) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?nombre=ilike.*$query*',
        method: 'GET',
      );

      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al buscar categorías: $e');
      return [];
    }
  }
}
