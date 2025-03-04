import 'package:flutter/foundation.dart';
import 'main.api.dart';

class Local {
  final int id;
  final String nombre;
  final String direccion;
  final String tipo;
  final String telefono;
  final String encargado;
  final bool activo;

  Local.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      nombre = json['nombre'],
      direccion = json['direccion'],
      tipo = json['tipo'],
      telefono = json['telefono'],
      encargado = json['encargado'],
      activo = json['activo'] ?? true;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'direccion': direccion,
    'tipo': tipo,
    'telefono': telefono,
    'encargado': encargado,
    'activo': activo,
  };
}

class LocalesApi {
  final ApiService _api;
  final String _endpoint = '/locales';

  LocalesApi(this._api);

  // Tipos de local válidos
  static const tipos = {
    'TIENDA': 'TIENDA',
    'ALMACEN': 'ALMACEN',
    'OFICINA': 'OFICINA',
  };

  // Obtener todos los locales
  Future<List<Local>> getLocales() async {
    try {
      final response = await _api.request(
        endpoint: _endpoint,
        method: 'GET',
      );

      if (response == null) return [];
      return (response as List)
        .map((json) => Local.fromJson(json))
        .toList();
    } catch (e) {
      debugPrint('Error al obtener locales: $e');
      return [];
    }
  }

  // Obtener un local por ID
  Future<Local?> getLocal(int id) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'GET',
      );

      if (response == null || (response as List).isEmpty) return null;
      return Local.fromJson(response[0]);
    } catch (e) {
      debugPrint('Error al obtener local: $e');
      return null;
    }
  }

  // Crear un nuevo local
  Future<Map<String, dynamic>> createLocal(Map<String, dynamic> local) async {
    try {
      // Validaciones básicas
      if (!local.containsKey('nombre') ||
          !local.containsKey('tipo')) {
        throw Exception('Nombre y tipo son requeridos');
      }

      // Validar tipo de local
      if (!tipos.containsKey(local['tipo'].toString().toUpperCase())) {
        throw Exception('Tipo de local inválido');
      }

      final response = await _api.request(
        endpoint: _endpoint,
        method: 'POST',
        body: local,
      );

      return response ?? {};
    } catch (e) {
      debugPrint('Error al crear local: $e');
      rethrow;
    }
  }

  // Actualizar un local
  Future<bool> updateLocal(int id, Map<String, dynamic> data) async {
    try {
      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'PATCH',
        body: data,
      );
      return true;
    } catch (e) {
      debugPrint('Error al actualizar local: $e');
      return false;
    }
  }

  // Eliminar un local (desactivar)
  Future<void> deleteLocal(int id) async {
    try {
      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'PATCH',
        body: {'activo': false},
      );
    } catch (e) {
      debugPrint('Error al eliminar local: $e');
      rethrow;
    }
  }

  // Obtener locales por tipo
  Future<List<Local>> getLocalesPorTipo(String tipo) async {
    try {
      if (!tipos.containsKey(tipo.toUpperCase())) {
        throw Exception('Tipo de local inválido');
      }

      final response = await _api.request(
        endpoint: '$_endpoint?tipo=eq.$tipo&activo=eq.true',
        method: 'GET',
      );

      if (response == null) return [];
      return (response as List)
        .map((json) => Local.fromJson(json))
        .toList();
    } catch (e) {
      debugPrint('Error al obtener locales por tipo: $e');
      return [];
    }
  }

  // Buscar locales
  Future<List<Local>> searchLocales(String query) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?or=(nombre.ilike.*$query*,direccion.ilike.*$query*)&activo=eq.true',
        method: 'GET',
      );

      if (response == null) return [];
      return (response as List)
        .map((json) => Local.fromJson(json))
        .toList();
    } catch (e) {
      debugPrint('Error al buscar locales: $e');
      return [];
    }
  }
}
