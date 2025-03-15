import '../main.api.dart';

class SucursalAdminApi {
  final ApiClient _api;
  
  SucursalAdminApi(this._api);
  
  /// Obtiene los datos específicos de una sucursal
  Future<Map<String, dynamic>> getSucursalData(String sucursalId) async {
    try {
      final response = await _api.request(
        endpoint: '/$sucursalId',
        method: 'GET',
      );
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Obtiene los vehículos de una sucursal específica
  Future<List<dynamic>> getVehiculos(String sucursalId) async {
    try {
      final response = await _api.request(
        endpoint: '/$sucursalId/vehiculos',
        method: 'GET',
      );
      
      return response['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Obtiene un vehículo específico de una sucursal
  Future<Map<String, dynamic>> getVehiculo(String sucursalId, String vehiculoId) async {
    try {
      final response = await _api.request(
        endpoint: '/$sucursalId/vehiculos/$vehiculoId',
        method: 'GET',
      );
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Crea un nuevo vehículo en una sucursal
  Future<Map<String, dynamic>> createVehiculo(String sucursalId, Map<String, dynamic> vehiculoData) async {
    try {
      final response = await _api.request(
        endpoint: '/$sucursalId/vehiculos',
        method: 'POST',
        body: vehiculoData,
      );
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Actualiza un vehículo existente en una sucursal
  Future<Map<String, dynamic>> updateVehiculo(String sucursalId, String vehiculoId, Map<String, dynamic> vehiculoData) async {
    try {
      final response = await _api.request(
        endpoint: '/$sucursalId/vehiculos/$vehiculoId',
        method: 'PUT',
        body: vehiculoData,
      );
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Elimina un vehículo de una sucursal
  Future<void> deleteVehiculo(String sucursalId, String vehiculoId) async {
    try {
      await _api.request(
        endpoint: '/$sucursalId/vehiculos/$vehiculoId',
        method: 'DELETE',
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Obtiene los clientes de una sucursal específica
  Future<List<dynamic>> getClientes(String sucursalId) async {
    try {
      final response = await _api.request(
        endpoint: '/$sucursalId/clientes',
        method: 'GET',
      );
      
      return response['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Obtiene un cliente específico de una sucursal
  Future<Map<String, dynamic>> getCliente(String sucursalId, String clienteId) async {
    try {
      final response = await _api.request(
        endpoint: '/$sucursalId/clientes/$clienteId',
        method: 'GET',
      );
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Crea un nuevo cliente en una sucursal
  Future<Map<String, dynamic>> createCliente(String sucursalId, Map<String, dynamic> clienteData) async {
    try {
      final response = await _api.request(
        endpoint: '/$sucursalId/clientes',
        method: 'POST',
        body: clienteData,
      );
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Actualiza un cliente existente en una sucursal
  Future<Map<String, dynamic>> updateCliente(String sucursalId, String clienteId, Map<String, dynamic> clienteData) async {
    try {
      final response = await _api.request(
        endpoint: '/$sucursalId/clientes/$clienteId',
        method: 'PUT',
        body: clienteData,
      );
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Elimina un cliente de una sucursal
  Future<void> deleteCliente(String sucursalId, String clienteId) async {
    try {
      await _api.request(
        endpoint: '/$sucursalId/clientes/$clienteId',
        method: 'DELETE',
      );
    } catch (e) {
      rethrow;
    }
  }
} 