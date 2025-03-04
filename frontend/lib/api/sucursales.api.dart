import 'package:flutter/foundation.dart';
import 'main.api.dart';

class SucursalRequest {
  final String nombre;
  final String direccion;
  final bool sucursalCentral;

  SucursalRequest({
    required this.nombre,
    required this.direccion,
    this.sucursalCentral = false,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'direccion': direccion,
    'sucursalCentral': sucursalCentral,
  };

  // Validaciones básicas
  String? validate() {
    if (nombre.isEmpty) return 'El nombre es requerido';
    if (direccion.isEmpty) return 'La dirección es requerida';
    return null;
  }
}

class Sucursal {
  final int id;
  final String nombre;
  final String direccion;
  final bool sucursalCentral;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;
  final bool? activo;

  Sucursal.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      nombre = json['nombre'],
      direccion = json['direccion'],
      sucursalCentral = json['sucursalCentral'] ?? false,
      fechaCreacion = json['fechaCreacion'] != null 
        ? DateTime.parse(json['fechaCreacion'])
        : null,
      fechaActualizacion = json['fechaActualizacion'] != null
        ? DateTime.parse(json['fechaActualizacion'])
        : null,
      activo = json['activo'] ?? true;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'direccion': direccion,
    'sucursalCentral': sucursalCentral,
    if (fechaCreacion != null) 'fechaCreacion': fechaCreacion!.toIso8601String(),
    if (fechaActualizacion != null) 'fechaActualizacion': fechaActualizacion!.toIso8601String(),
    if (activo != null) 'activo': activo,
  };
}

class PaginatedSucursales {
  final List<Sucursal> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  PaginatedSucursales.fromJson(Map<String, dynamic> json)
    : items = (json['items'] as List).map((item) => Sucursal.fromJson(item)).toList(),
      total = json['total'] ?? 0,
      page = json['page'] ?? 1,
      pageSize = json['pageSize'] ?? 10,
      totalPages = json['totalPages'] ?? 1;
}

class SucursalUpdateRequest {
  final String? nombre;
  final String? direccion;
  final bool? sucursalCentral;

  SucursalUpdateRequest({
    this.nombre,
    this.direccion,
    this.sucursalCentral,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (nombre != null) data['nombre'] = nombre;
    if (direccion != null) data['direccion'] = direccion;
    if (sucursalCentral != null) data['sucursalCentral'] = sucursalCentral;
    return data;
  }

  // Validaciones básicas para campos opcionales
  String? validate() {
    if (nombre != null && nombre!.isEmpty) {
      return 'El nombre no puede estar vacío';
    }
    if (direccion != null && direccion!.isEmpty) {
      return 'La dirección no puede estar vacía';
    }
    return null;
  }

  // Verificar si hay campos para actualizar
  bool get hasChanges => nombre != null || direccion != null || sucursalCentral != null;
}

class SucursalesApi {
  final ApiService _api;
  final String _endpoint = '/sucursales';
  
  SucursalesApi(this._api);

  // Obtener sucursales con paginación y filtros
  Future<PaginatedSucursales> getSucursales({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? sortBy,
    String order = 'desc',
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sort_by'] = sortBy;
        queryParams['order'] = order;
      }

      final response = await _api.request(
        endpoint: _endpoint,
        method: 'GET',
        queryParams: queryParams,
      );

      if (response == null) {
        throw Exception('No se pudo obtener las sucursales');
      }

      return PaginatedSucursales.fromJson(response);
    } catch (e) {
      debugPrint('Error al obtener sucursales: $e');
      rethrow;
    }
  }

  // Obtener una sucursal por ID
  Future<Sucursal> getSucursal(int id) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint/$id',
        method: 'GET',
      );

      if (response == null) {
        throw Exception('Sucursal no encontrada');
      }

      return Sucursal.fromJson(response);
    } catch (e) {
      debugPrint('Error al obtener sucursal: $e');
      rethrow;
    }
  }

  // Crear una nueva sucursal
  Future<Sucursal> createSucursal(SucursalRequest sucursal) async {
    try {
      // Validar datos antes de enviar
      final validationError = sucursal.validate();
      if (validationError != null) {
        throw Exception(validationError);
      }

      final response = await _api.request(
        endpoint: _endpoint,
        method: 'POST',
        body: sucursal.toJson(),
      );

      if (response == null) {
        throw Exception('Error al crear sucursal: Sin respuesta del servidor');
      }

      return Sucursal.fromJson(response);
    } catch (e) {
      debugPrint('Error al crear sucursal: $e');
      rethrow;
    }
  }

  // Actualizar una sucursal (actualización completa)
  Future<Sucursal> updateSucursal(int id, SucursalRequest sucursal) async {
    try {
      // Validar datos antes de enviar
      final validationError = sucursal.validate();
      if (validationError != null) {
        throw Exception(validationError);
      }

      final response = await _api.request(
        endpoint: '$_endpoint/$id',
        method: 'PATCH',
        body: sucursal.toJson(),
      );

      if (response == null) {
        throw Exception('Error al actualizar sucursal: Sin respuesta del servidor');
      }

      return Sucursal.fromJson(response);
    } catch (e) {
      debugPrint('Error al actualizar sucursal: $e');
      rethrow;
    }
  }

  // Actualizar parcialmente una sucursal
  Future<Sucursal> updateSucursalPartial(int id, SucursalUpdateRequest update) async {
    try {
      // Validar que haya cambios para aplicar
      if (!update.hasChanges) {
        throw Exception('No hay cambios para actualizar');
      }

      // Validar datos antes de enviar
      final validationError = update.validate();
      if (validationError != null) {
        throw Exception(validationError);
      }

      final response = await _api.request(
        endpoint: '$_endpoint/$id',
        method: 'PATCH',
        body: update.toJson(),
      );

      if (response == null) {
        throw Exception('Error al actualizar parcialmente sucursal: Sin respuesta del servidor');
      }

      return Sucursal.fromJson(response);
    } catch (e) {
      debugPrint('Error al actualizar parcialmente sucursal: $e');
      rethrow;
    }
  }

  // Eliminar una sucursal
  Future<void> deleteSucursal(int id) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint/$id',
        method: 'DELETE',
      );

      // Verificar si la respuesta indica error
      if (response != null && response is Map<String, dynamic> && response.containsKey('error')) {
        throw Exception(response['error'] ?? 'Error al eliminar sucursal');
      }
    } catch (e) {
      debugPrint('Error al eliminar sucursal: $e');
      rethrow;
    }
  }

  // Verificar si existe una sucursal
  Future<bool> existeSucursal(int id) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint/$id',
        method: 'GET',
      );
      return response != null;
    } catch (e) {
      return false;
    }
  }
}
