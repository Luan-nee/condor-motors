import 'package:flutter/foundation.dart';
import 'main.api.dart';

class MarcasApi {
  final ApiService _api;
  final String _endpoint = '/marcas';

  MarcasApi(this._api);

  // Obtener todas las marcas
  Future<List<Map<String, dynamic>>> getMarcas() async {
    try {
      final response = await _api.request(
        endpoint: _endpoint,
        method: 'GET',
      );

      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al obtener marcas: $e');
      return [];
    }
  }

  // Obtener una marca por ID
  Future<Map<String, dynamic>?> getMarca(int id) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'GET',
      );

      if (response == null || (response as List).isEmpty) return null;
      return Map<String, dynamic>.from(response[0]);
    } catch (e) {
      debugPrint('Error al obtener marca: $e');
      return null;
    }
  }

  // Crear una nueva marca
  Future<Map<String, dynamic>> createMarca(Map<String, dynamic> marca) async {
    try {
      // Validaciones básicas
      if (!marca.containsKey('nombre')) {
        throw Exception('El nombre es requerido');
      }

      // Verificar si ya existe una marca con el mismo nombre
      final existingMarcas = await getMarcas();
      if (existingMarcas.any((m) => 
          m['nombre'].toString().toLowerCase() == marca['nombre'].toString().toLowerCase())) {
        throw Exception('Ya existe una marca con este nombre');
      }

      final response = await _api.request(
        endpoint: _endpoint,
        method: 'POST',
        body: marca,
      );

      return response ?? {};
    } catch (e) {
      debugPrint('Error al crear marca: $e');
      rethrow;
    }
  }

  // Actualizar una marca
  Future<void> updateMarca(int id, Map<String, dynamic> marca) async {
    try {
      // Verificar si existe la marca
      final existingMarca = await getMarca(id);
      if (existingMarca == null) {
        throw Exception('Marca no encontrada');
      }

      // Verificar nombre duplicado si se va a actualizar
      if (marca.containsKey('nombre')) {
        final existingMarcas = await getMarcas();
        if (existingMarcas.any((m) => 
            m['id'] != id && 
            m['nombre'].toString().toLowerCase() == marca['nombre'].toString().toLowerCase())) {
          throw Exception('Ya existe una marca con este nombre');
        }
      }

      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'PUT',
        body: marca,
      );
    } catch (e) {
      debugPrint('Error al actualizar marca: $e');
      rethrow;
    }
  }

  // Eliminar una marca
  Future<void> deleteMarca(int id) async {
    try {
      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'DELETE',
      );
    } catch (e) {
      debugPrint('Error al eliminar marca: $e');
      rethrow;
    }
  }

  // Buscar marcas
  Future<List<Map<String, dynamic>>> searchMarcas(String query) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?or=(nombre.ilike.*$query*,descripcion.ilike.*$query*)',
        method: 'GET',
      );

      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al buscar marcas: $e');
      return [];
    }
  }
}
