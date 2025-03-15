import 'package:flutter/foundation.dart';
import '../main.api.dart';

class CategoriasApi {
  final ApiClient _api;
  final String _endpoint = '/categorias';
  
  CategoriasApi(this._api);
  
  /// Obtiene todas las categorías
  /// 
  /// [page] Número de página para paginación
  /// [pageSize] Tamaño de página para paginación
  Future<List<dynamic>> getCategorias({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      debugPrint('CategoriasApi: Obteniendo categorías');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
      
      final response = await _api.request(
        endpoint: _endpoint,
        method: 'GET',
        queryParams: queryParams,
      );
      
      debugPrint('CategoriasApi: Respuesta recibida, status: ${response['status']}');
      
      // Verificar estructura de respuesta
      if (response['data'] == null) {
        debugPrint('CategoriasApi: La respuesta no contiene datos');
        return [];
      }
      
      if (response['data'] is! List) {
        debugPrint('CategoriasApi: Formato de datos inesperado. Recibido: ${response['data'].runtimeType}');
        return [];
      }
      
      final categorias = response['data'] as List;
      debugPrint('CategoriasApi: ${categorias.length} categorías encontradas');
      
      return categorias;
    } catch (e) {
      debugPrint('CategoriasApi: Error al obtener categorías: $e');
      // Capturar más detalles sobre el error
      if (e is ApiException) {
        debugPrint('CategoriasApi: Código de error: ${e.statusCode}, Mensaje: ${e.message}');
        if (e.data != null) {
          debugPrint('CategoriasApi: Datos adicionales del error: ${e.data}');
        }
      }
      rethrow;
    }
  }
  
  /// Crea una nueva categoría
  /// 
  /// [nombre] Nombre de la categoría
  /// [descripcion] Descripción opcional de la categoría
  Future<Map<String, dynamic>> createCategoria({
    required String nombre,
    String? descripcion,
  }) async {
    try {
      debugPrint('CategoriasApi: Creando nueva categoría: $nombre');
      
      final body = <String, dynamic>{
        'nombre': nombre,
      };
      
      if (descripcion != null) {
        body['descripcion'] = descripcion;
      }
      
      final response = await _api.request(
        endpoint: _endpoint,
        method: 'POST',
        body: body,
      );
      
      debugPrint('CategoriasApi: Categoría creada con éxito');
      
      return response['data'];
    } catch (e) {
      debugPrint('CategoriasApi: Error al crear categoría: $e');
      // Capturar más detalles sobre el error
      if (e is ApiException) {
        debugPrint('CategoriasApi: Código de error: ${e.statusCode}, Mensaje: ${e.message}');
        if (e.data != null) {
          debugPrint('CategoriasApi: Datos adicionales del error: ${e.data}');
        }
      }
      rethrow;
    }
  }
}
