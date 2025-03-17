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
      
      final response = await _api.authenticatedRequest(
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
      
      final response = await _api.authenticatedRequest(
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
  
  /// Actualiza una categoría existente
  /// 
  /// [id] ID de la categoría a actualizar
  /// [nombre] Nuevo nombre de la categoría (opcional)
  /// [descripcion] Nueva descripción de la categoría (opcional)
  Future<Map<String, dynamic>> updateCategoria({
    required String id,
    String? nombre,
    String? descripcion,
  }) async {
    try {
      debugPrint('CategoriasApi: Actualizando categoría con ID: $id');
      
      // Construir el cuerpo de la solicitud solo con los campos que se van a actualizar
      final body = <String, dynamic>{};
      
      if (nombre != null) {
        body['nombre'] = nombre;
      }
      
      if (descripcion != null) {
        body['descripcion'] = descripcion;
      }
      
      // Si no hay campos para actualizar, lanzar un error
      if (body.isEmpty) {
        throw Exception('Debe proporcionar al menos un campo para actualizar');
      }
      
      final response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id',
        method: 'PATCH', // Usar PATCH para actualización parcial
        body: body,
      );
      
      debugPrint('CategoriasApi: Categoría actualizada con éxito');
      
      return response['data'];
    } catch (e) {
      debugPrint('CategoriasApi: Error al actualizar categoría: $e');
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
  
  /// Elimina una categoría
  /// 
  /// [id] ID de la categoría a eliminar
  Future<bool> deleteCategoria(String id) async {
    try {
      debugPrint('CategoriasApi: Eliminando categoría con ID: $id');
      
      await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id',
        method: 'DELETE',
      );
      
      debugPrint('CategoriasApi: Categoría eliminada con éxito');
      
      return true;
    } catch (e) {
      debugPrint('CategoriasApi: Error al eliminar categoría: $e');
      // Capturar más detalles sobre el error
      if (e is ApiException) {
        debugPrint('CategoriasApi: Código de error: ${e.statusCode}, Mensaje: ${e.message}');
        if (e.data != null) {
          debugPrint('CategoriasApi: Datos adicionales del error: ${e.data}');
        }
      }
      return false;
    }
  }
  
  /// Obtiene una categoría específica por su ID
  /// 
  /// [id] ID de la categoría a obtener
  Future<Map<String, dynamic>> getCategoria(String id) async {
    try {
      debugPrint('CategoriasApi: Obteniendo categoría con ID: $id');
      
      final response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id',
        method: 'GET',
      );
      
      debugPrint('CategoriasApi: Categoría obtenida con éxito');
      
      return response['data'];
    } catch (e) {
      debugPrint('CategoriasApi: Error al obtener categoría: $e');
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
