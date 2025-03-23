import 'package:flutter/foundation.dart';

import '../../models/color.model.dart';
import '../main.api.dart';
import 'cache/fast_cache.dart';

/// API para la gestión de colores
class ColoresApi {
  final ApiClient _apiClient;
  // Fast Cache para las operaciones de colores
  final FastCache _cache = FastCache();

  ColoresApi({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  /// Obtiene todos los colores disponibles en el sistema
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<List<ColorApp>> getColores({bool useCache = true}) async {
    try {
      const cacheKey = 'colores_all';
      
      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final cachedData = _cache.get<List<ColorApp>>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Colores obtenidos desde caché');
          return cachedData;
        }
      }
      
      final response = await _apiClient.authenticatedRequest(
        endpoint: '/colores',
        method: 'GET',
      );

      if (response.containsKey('data')) {
        final List<dynamic> jsonData = response['data'];
        final colores = jsonData.map((json) => ColorApp.fromJson(json)).toList();
        
        // Guardar en caché si useCache es true
        if (useCache) {
          _cache.set(cacheKey, colores);
          debugPrint('✅ Colores guardados en caché');
        }
        
        return colores;
      } else {
        throw Exception('Error al obtener colores: Formato de respuesta inesperado');
      }
    } catch (e) {
      throw Exception('Error al obtener colores: $e');
    }
  }
  
  /// Método público para forzar refresco de caché
  void invalidateCache() {
    _cache.clear();
    debugPrint('✅ Caché de colores completamente invalidada');
  }
}
