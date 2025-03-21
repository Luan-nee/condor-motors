import '../main.api.dart';

class SucursalAdminApi {
  final ApiClient _api;
  
  SucursalAdminApi(this._api);
  
  /// Obtiene los datos específicos de una sucursal
  /// 
  /// Este método obtiene información general sobre una sucursal específica
  Future<Map<String, dynamic>> getSucursalData(String sucursalId) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/sucursales/$sucursalId',
        method: 'GET',
      );
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  // PRODUCTOS
  
  /// Obtiene todos los productos de una sucursal
  Future<List<dynamic>> getProductos(String sucursalId) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos',
        method: 'GET',
      );
      
      return response['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Obtiene un producto específico por ID
  Future<Map<String, dynamic>> getProductoById(String sucursalId, String productoId) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos/$productoId',
        method: 'GET',
      );
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Crea un nuevo producto en la sucursal
  Future<Map<String, dynamic>> createProducto(String sucursalId, Map<String, dynamic> productoData) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos',
        method: 'POST',
        body: productoData,
      );
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Añade existencias a un producto existente
  Future<Map<String, dynamic>> addExistenciasProducto(String sucursalId, String productoId, Map<String, dynamic> data) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos/$productoId',
        method: 'POST',
        body: data,
      );
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Actualiza un producto existente
  Future<Map<String, dynamic>> updateProducto(String sucursalId, String productoId, Map<String, dynamic> productoData) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos/$productoId',
        method: 'PATCH',
        body: productoData,
      );
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  // INVENTARIOS
  
  /// Registra entradas de inventario en la sucursal
  Future<Map<String, dynamic>> registrarEntradasInventario(String sucursalId, Map<String, dynamic> data) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/inventarios/entradas',
        method: 'POST',
        body: data,
      );
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  // PROFORMAS DE VENTA
  
  /// Obtiene todas las proformas de venta de la sucursal
  Future<List<dynamic>> getProformasVenta(String sucursalId) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa',
        method: 'GET',
      );
      
      return response['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Crea una nueva proforma de venta
  Future<Map<String, dynamic>> createProformaVenta(String sucursalId, Map<String, dynamic> proformaData) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa',
        method: 'POST',
        body: proformaData,
      );
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Actualiza una proforma de venta existente
  Future<Map<String, dynamic>> updateProformaVenta(String sucursalId, String proformaId, Map<String, dynamic> proformaData) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa/$proformaId',
        method: 'PATCH',
        body: proformaData,
      );
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Elimina una proforma de venta
  Future<void> deleteProformaVenta(String sucursalId, String proformaId) async {
    try {
      await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa/$proformaId',
        method: 'DELETE',
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // NOTIFICACIONES
  
  /// Obtiene todas las notificaciones de la sucursal
  Future<List<dynamic>> getNotificaciones(String sucursalId) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/notificaciones',
        method: 'GET',
      );
      
      return response['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Elimina una notificación
  Future<void> deleteNotificacion(String sucursalId, String notificacionId) async {
    try {
      await _api.authenticatedRequest(
        endpoint: '/$sucursalId/notificaciones/$notificacionId',
        method: 'DELETE',
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // SUCURSALES (operaciones generales)
  
  /// Obtiene todas las sucursales
  Future<List<dynamic>> getAllSucursales() async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/sucursales',
        method: 'GET',
      );
      
      return response['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Crea una nueva sucursal
  Future<Map<String, dynamic>> createSucursal(Map<String, dynamic> sucursalData) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/sucursales',
        method: 'POST',
        body: sucursalData,
      );
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Actualiza una sucursal existente
  Future<Map<String, dynamic>> updateSucursal(String sucursalId, Map<String, dynamic> sucursalData) async {
    try {
      final response = await _api.authenticatedRequest(
        endpoint: '/sucursales/$sucursalId',
        method: 'PATCH',
        body: sucursalData,
      );
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }

  /// Elimina una sucursal
  Future<void> deleteSucursal(String sucursalId) async {
    try {
      await _api.authenticatedRequest(
        endpoint: '/sucursales/$sucursalId',
        method: 'DELETE',
      );
    } catch (e) {
      rethrow;
    }
  }
} 