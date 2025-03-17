import '../main.api.dart';
import 'package:flutter/foundation.dart';

/// Modelo para representar una sucursal
class Sucursal {
  final String id;
  final String nombre;
  final String? direccion;
  final String? telefono;
  final String? email;
  final String? ciudad;
  final String? provincia;
  final String? codigoPostal;
  final String? pais;
  final String? fechaRegistro;
  final bool activo;

  Sucursal({
    required this.id,
    required this.nombre,
    this.direccion,
    this.telefono,
    this.email,
    this.ciudad,
    this.provincia,
    this.codigoPostal,
    this.pais,
    this.fechaRegistro,
    this.activo = true,
  });

  factory Sucursal.fromJson(Map<String, dynamic> json) {
    return Sucursal(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      direccion: json['direccion'],
      telefono: json['telefono'],
      email: json['email'],
      ciudad: json['ciudad'],
      provincia: json['provincia'],
      codigoPostal: json['codigoPostal'],
      pais: json['pais'],
      fechaRegistro: json['fechaRegistro'],
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'email': email,
      'ciudad': ciudad,
      'provincia': provincia,
      'codigoPostal': codigoPostal,
      'pais': pais,
      'activo': activo,
    };
  }
  
  @override
  String toString() {
    return 'Sucursal{id: $id, nombre: $nombre, activo: $activo}';
  }
}

class SucursalesApi {
  final ApiClient _api;
  
  SucursalesApi(this._api);
  
  /// Obtiene todas las sucursales
  Future<List<dynamic>> getSucursales() async {
    try {
      debugPrint('SucursalesApi: Obteniendo lista de sucursales');
      final response = await _api.authenticatedRequest(
        endpoint: '/sucursales',
        method: 'GET',
      );
      
      debugPrint('SucursalesApi: Respuesta de getSucursales recibida');
      
      // Manejar estructura anidada: response.data.data
      if (response['data'] is Map && response['data'].containsKey('data')) {
        debugPrint('SucursalesApi: Encontrada estructura anidada en la respuesta');
        final items = response['data']['data'] ?? [];
        debugPrint('SucursalesApi: Total de sucursales encontradas: ${items.length}');
        return items;
      }
      
      // Si la estructura cambia en el futuro y ya no está anidada
      debugPrint('SucursalesApi: Usando estructura directa de respuesta');
      final items = response['data'] ?? [];
      debugPrint('SucursalesApi: Total de sucursales encontradas: ${items.length}');
      return items;
    } catch (e) {
      debugPrint('SucursalesApi: ERROR al obtener sucursales: $e');
      rethrow;
    }
  }
  
  /// Obtiene una sucursal por su ID
  /// 
  /// El ID debe ser un string, aunque represente un número
  Future<Map<String, dynamic>> getSucursal(String sucursalId) async {
    try {
      // Validar que sucursalId no sea nulo o vacío
      if (sucursalId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de sucursal no puede estar vacío',
        );
      }
      
      debugPrint('SucursalesApi: Obteniendo sucursal con ID: $sucursalId');
      final response = await _api.authenticatedRequest(
        endpoint: '/sucursales/$sucursalId',
        method: 'GET',
      );
      
      debugPrint('SucursalesApi: Respuesta de getSucursal recibida');
      
      // Manejar estructura anidada
      Map<String, dynamic>? data;
      if (response['data'] is Map && response['data'].containsKey('data')) {
        data = response['data']['data'];
      } else {
        data = response['data'];
      }
      
      if (data == null) {
        throw ApiException(
          statusCode: 404,
          message: 'Sucursal no encontrada',
        );
      }
      
      return data;
    } catch (e) {
      debugPrint('SucursalesApi: ERROR al obtener sucursal #$sucursalId: $e');
      rethrow;
    }
  }
  
  /// Crea una nueva sucursal
  Future<Map<String, dynamic>> createSucursal(Map<String, dynamic> sucursalData) async {
    try {
      // Validar datos mínimos requeridos
      if (!sucursalData.containsKey('nombre')) {
        throw ApiException(
          statusCode: 400,
          message: 'Nombre es requerido para crear sucursal',
        );
      }
      
      debugPrint('SucursalesApi: Creando nueva sucursal: ${sucursalData['nombre']}');
      final response = await _api.authenticatedRequest(
        endpoint: '/sucursales',
        method: 'POST',
        body: sucursalData,
      );
      
      debugPrint('SucursalesApi: Respuesta de createSucursal recibida');
      
      // Manejar estructura anidada
      Map<String, dynamic>? data;
      if (response['data'] is Map && response['data'].containsKey('data')) {
        data = response['data']['data'];
      } else {
        data = response['data'];
      }
      
      if (data == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Error al crear sucursal',
        );
      }
      
      return data;
    } catch (e) {
      debugPrint('SucursalesApi: ERROR al crear sucursal: $e');
      rethrow;
    }
  }
  
  /// Actualiza una sucursal existente
  /// 
  /// El ID debe ser un string, aunque represente un número
  Future<Map<String, dynamic>> updateSucursal(String sucursalId, Map<String, dynamic> sucursalData) async {
    try {
      // Validar que sucursalId no sea nulo o vacío
      if (sucursalId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de sucursal no puede estar vacío',
        );
      }
      
      debugPrint('SucursalesApi: Actualizando sucursal con ID: $sucursalId');
      final response = await _api.authenticatedRequest(
        endpoint: '/sucursales/$sucursalId',
        method: 'PATCH',
        body: sucursalData,
      );
      
      debugPrint('SucursalesApi: Respuesta de updateSucursal recibida');
      
      // Manejar estructura anidada
      Map<String, dynamic>? data;
      if (response['data'] is Map && response['data'].containsKey('data')) {
        data = response['data']['data'];
      } else {
        data = response['data'];
      }
      
      if (data == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Error al actualizar sucursal',
        );
      }
      
      return data;
    } catch (e) {
      debugPrint('SucursalesApi: ERROR al actualizar sucursal #$sucursalId: $e');
      rethrow;
    }
  }
  
  /// Elimina una sucursal
  /// 
  /// El ID debe ser un string, aunque represente un número
  /// NOTA: Este endpoint está comentado en el servidor actualmente
  Future<void> deleteSucursal(String sucursalId) async {
    try {
      // Validar que sucursalId no sea nulo o vacío
      if (sucursalId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de sucursal no puede estar vacío',
        );
      }
      
      debugPrint('SucursalesApi: Eliminando sucursal con ID: $sucursalId');
      
      // Como el endpoint DELETE está comentado en el servidor,
      // usamos PATCH para desactivar la sucursal en su lugar
      await _api.authenticatedRequest(
        endpoint: '/sucursales/$sucursalId',
        method: 'PATCH',
        body: {'activo': false},
      );
      
      debugPrint('SucursalesApi: Sucursal desactivada correctamente');
    } catch (e) {
      debugPrint('SucursalesApi: ERROR al eliminar sucursal #$sucursalId: $e');
      rethrow;
    }
  }
  
  /// Obtiene sucursales activas
  Future<List<dynamic>> getSucursalesActivas() async {
    try {
      debugPrint('SucursalesApi: Obteniendo sucursales activas');
      final response = await _api.authenticatedRequest(
        endpoint: '/sucursales',
        method: 'GET',
        queryParams: {'filter': 'activo', 'filter_value': 'true'},
      );
      
      debugPrint('SucursalesApi: Respuesta de getSucursalesActivas recibida');
      
      // Manejar estructura anidada
      if (response['data'] is Map && response['data'].containsKey('data')) {
        final items = response['data']['data'] ?? [];
        return items;
      }
      
      final items = response['data'] ?? [];
      return items;
    } catch (e) {
      debugPrint('SucursalesApi: ERROR al obtener sucursales activas: $e');
      rethrow;
    }
  }
}
