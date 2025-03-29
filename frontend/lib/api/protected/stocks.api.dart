import 'package:condorsmotors/api/main.api.dart';
import 'package:flutter/foundation.dart';

class StocksApi {
  final ApiClient _api;
  
  StocksApi(this._api);
  
  /// Obtiene el stock de todos los productos de una sucursal específica
  /// 
  /// [sucursalId] ID de la sucursal para consultar el stock
  /// [categoriaId] Opcional. Filtrar por categoría
  /// [search] Opcional. Búsqueda por nombre de producto
  /// [stockBajo] Opcional. Filtrar productos con stock bajo
  Future<List<dynamic>> getStockBySucursal({
    required String sucursalId,
    String? categoriaId,
    String? search,
    bool? stockBajo,
  }) async {
    try {
      // Validar el ID de sucursal
      if (sucursalId.isEmpty) {
        debugPrint('ERROR: Se requiere un ID de sucursal válido');
        throw Exception('ID de sucursal no válido');
      }
      
      debugPrint('StocksApi: Obteniendo productos para sucursal $sucursalId');
      
      final Map<String, String> queryParams = <String, String>{};
      
      if (categoriaId != null) {
        queryParams['categoria_id'] = categoriaId;
      }
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      if (stockBajo != null) {
        queryParams['stock_bajo'] = stockBajo.toString();
      }
      
      // Construir el endpoint correcto
      final String endpoint = '/stocks/$sucursalId/productos';
      debugPrint('StocksApi: Solicitando a endpoint: $endpoint con parámetros: $queryParams');
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: endpoint,
        method: 'GET',
        queryParams: queryParams,
      );
      
      debugPrint('StocksApi: Respuesta recibida, status: ${response['status']}');
      
      // Verificar estructura de respuesta
      if (response['data'] == null) {
        debugPrint('StocksApi: La respuesta no contiene datos');
        return <dynamic>[];
      }
      
      if (response['data'] is! List) {
        debugPrint('StocksApi: Formato de datos inesperado. Recibido: ${response['data'].runtimeType}');
        return <dynamic>[];
      }
      
      final List productos = response['data'] as List;
      debugPrint('StocksApi: ${productos.length} productos encontrados');
      
      return productos;
    } catch (e) {
      debugPrint('StocksApi: Error al obtener stock por sucursal: $e');
      // Capturar más detalles sobre el error
      if (e is ApiException) {
        debugPrint('StocksApi: Código de error: ${e.statusCode}, Mensaje: ${e.message}');
        if (e.data != null) {
          debugPrint('StocksApi: Datos adicionales del error: ${e.data}');
        }
      }
      rethrow;
    }
  }
  
  /// Obtiene el stock de un producto específico en una sucursal
  /// 
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto del cual consultar el stock
  Future<Map<String, dynamic>> getStockProducto(String sucursalId, String productoId) async {
    try {
      // Validar parámetros
      if (sucursalId.isEmpty || productoId.isEmpty) {
        throw Exception('Se requieren IDs de sucursal y producto válidos');
      }
      
      debugPrint('StocksApi: Obteniendo stock del producto $productoId en sucursal $sucursalId');
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos/$productoId',
        method: 'GET',
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al obtener stock de producto: $e');
      rethrow;
    }
  }
  
  /// Actualiza el stock de un producto en una sucursal específica
  /// 
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  /// [cantidad] Cantidad a modificar
  /// [tipo] Tipo de operación ("incremento" o "decremento")
  Future<Map<String, dynamic>> updateStock(
    String sucursalId, 
    String productoId, 
    int cantidad, 
    String tipo
  ) async {
    try {
      if (cantidad <= 0) {
        throw Exception('La cantidad debe ser un valor positivo');
      }
      
      if (tipo != 'incremento' && tipo != 'decremento') {
        throw Exception('Tipo de operación no válido. Debe ser "incremento" o "decremento"');
      }
      
      debugPrint('StocksApi: Actualizando stock del producto $productoId en sucursal $sucursalId');
      debugPrint('StocksApi: Operación: $tipo, Cantidad: $cantidad');
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/productos/$productoId/stock',
        method: 'PATCH',
        body: <String, dynamic>{
          'cantidad': cantidad,
          'tipo': tipo,
        },
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al actualizar stock: $e');
      rethrow;
    }
  }
  
  /// Registra un movimiento de stock (entrada o salida)
  /// 
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto
  /// [cantidad] Cantidad de productos
  /// [tipo] Tipo de movimiento ("entrada" o "salida")
  /// [motivo] Motivo del movimiento (opcional)
  Future<Map<String, dynamic>> registrarMovimientoStock(
    String sucursalId,
    String productoId,
    int cantidad,
    String tipo,
    {String? motivo}
  ) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'cantidad': cantidad,
        'tipo': tipo,
      };
      
      if (motivo != null) {
        body['motivo'] = motivo;
      }
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/movimientos',
        method: 'POST',
        body: <String, dynamic>{
          'sucursalId': sucursalId,
          'productoId': productoId,
          'cantidad': cantidad,
          'tipo': tipo,
          'motivo': motivo,
        },
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al registrar movimiento de stock: $e');
      rethrow;
    }
  }
  
  /// Obtiene el historial de movimientos de stock de un producto
  /// 
  /// [sucursalId] ID de la sucursal
  /// [productoId] ID del producto (opcional, si no se proporciona devuelve todos los movimientos)
  /// [fechaInicio] Fecha de inicio para filtrar (opcional)
  /// [fechaFin] Fecha de fin para filtrar (opcional)
  Future<List<dynamic>> getHistorialStock(
    String sucursalId, {
    String? productoId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      final Map<String, String> queryParams = <String, String>{};
      
      if (productoId != null) {
        queryParams['producto_id'] = productoId;
      }
      
      if (fechaInicio != null) {
        queryParams['fecha_inicio'] = fechaInicio.toIso8601String();
      }
      
      if (fechaFin != null) {
        queryParams['fecha_fin'] = fechaFin.toIso8601String();
      }
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/movimientos',
        method: 'GET',
        queryParams: queryParams,
      );
      
      return response['data'] ?? <dynamic>[];
    } catch (e) {
      debugPrint('Error al obtener historial de stock: $e');
      rethrow;
    }
  }
  
  /// Realiza una transferencia de stock entre sucursales
  /// 
  /// [sucursalOrigenId] ID de la sucursal de origen
  /// [sucursalDestinoId] ID de la sucursal de destino
  /// [productos] Lista de productos a transferir con sus cantidades
  Future<Map<String, dynamic>> transferirStock(
    String sucursalOrigenId,
    String sucursalDestinoId,
    List<Map<String, dynamic>> productos
  ) async {
    try {
      final Map<String, dynamic> response = await _api.request(
        endpoint: '/$sucursalOrigenId/transferir-stock',
        method: 'POST',
        body: <String, dynamic>{
          'sucursal_destino_id': sucursalDestinoId,
          'productos': productos,
        },
      );
      
      return response['data'];
    } catch (e) {
      debugPrint('Error al transferir stock: $e');
      rethrow;
    }
  }
  
  /// Genera un reporte de stock de una sucursal
  /// 
  /// [sucursalId] ID de la sucursal
  /// [formato] Formato del reporte ("pdf", "excel", etc.)
  Future<String> generarReporteStock(
    String sucursalId,
    String formato
  ) async {
    try {
      final Map<String, dynamic> response = await _api.request(
        endpoint: '/$sucursalId/reporte-stock',
        method: 'GET',
        queryParams: <String, String>{
          'formato': formato
        },
      );
      
      return response['data']['url'] ?? '';
    } catch (e) {
      debugPrint('Error al generar reporte de stock: $e');
      rethrow;
    }
  }
  
  /// Obtiene productos con stock bajo de una sucursal
  /// 
  /// Este método es una versión simplificada de getStockBySucursal específica para stock bajo
  Future<List<dynamic>> getProductosStockBajo(String sucursalId) async {
    debugPrint('StocksApi: Obteniendo productos con stock bajo para sucursal $sucursalId');
    return await getStockBySucursal(
      sucursalId: sucursalId,
      stockBajo: true,
    );
  }
}
