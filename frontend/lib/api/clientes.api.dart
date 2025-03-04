import 'package:flutter/foundation.dart';
import 'main.api.dart';

class ClientesApi {
  final ApiService _api;
  final String _endpoint = '/clientes';

  ClientesApi(this._api);

  // Obtener todos los clientes
  Future<List<Map<String, dynamic>>> getClientes() async {
    try {
      final response = await _api.request(
        endpoint: _endpoint,
        method: 'GET',
      );

      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al obtener clientes: $e');
      return [];
    }
  }

  // Obtener un cliente por ID
  Future<Map<String, dynamic>?> getCliente(int id) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'GET',
      );

      if (response == null || (response as List).isEmpty) return null;
      return Map<String, dynamic>.from(response[0]);
    } catch (e) {
      debugPrint('Error al obtener cliente: $e');
      return null;
    }
  }

  // Crear un nuevo cliente
  Future<Map<String, dynamic>> createCliente(Map<String, dynamic> cliente) async {
    try {
      // Validaciones básicas
      if (!cliente.containsKey('tipo')) {
        throw Exception('El tipo de cliente es requerido');
      }

      // Validar campos según tipo de cliente
      if (cliente['tipo'] == 'PERSONA') {
        if (!cliente.containsKey('nombres_apellidos') || !cliente.containsKey('dni')) {
          throw Exception('Nombres, apellidos y DNI son requeridos para personas');
        }
      } else if (cliente['tipo'] == 'EMPRESA') {
        if (!cliente.containsKey('razon_social') || !cliente.containsKey('ruc')) {
          throw Exception('Razón social y RUC son requeridos para empresas');
        }
      }

      final response = await _api.request(
        endpoint: _endpoint,
        method: 'POST',
        body: cliente,
      );

      return response ?? {};
    } catch (e) {
      debugPrint('Error al crear cliente: $e');
      rethrow;
    }
  }

  // Actualizar un cliente
  Future<void> updateCliente(int id, Map<String, dynamic> cliente) async {
    try {
      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'PUT',
        body: cliente,
      );
    } catch (e) {
      debugPrint('Error al actualizar cliente: $e');
      rethrow;
    }
  }

  // Eliminar un cliente
  Future<void> deleteCliente(int id) async {
    try {
      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'DELETE',
      );
    } catch (e) {
      debugPrint('Error al eliminar cliente: $e');
      rethrow;
    }
  }

  // Buscar clientes
  Future<List<Map<String, dynamic>>> searchClientes({
    String? query,
    String? tipo,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (query != null) {
        queryParams['or'] = 'nombres_apellidos.ilike.*$query*,razon_social.ilike.*$query*,dni.ilike.*$query*,ruc.ilike.*$query*';
      }
      if (tipo != null) queryParams['tipo'] = 'eq.$tipo';

      final response = await _api.request(
        endpoint: _endpoint,
        method: 'GET',
        queryParams: queryParams,
      );

      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al buscar clientes: $e');
      return [];
    }
  }
}
