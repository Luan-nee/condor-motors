import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/cache/fast_cache.dart';
import 'package:condorsmotors/models/color.model.dart';
import 'package:flutter/foundation.dart';

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
      const String cacheKey = 'colores_all';
      
      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final List<ColorApp>? cachedData = _cache.get<List<ColorApp>>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Colores obtenidos desde caché');
          return cachedData;
        }
      }
      
      final Map<String, dynamic> response = await _apiClient.authenticatedRequest(
        endpoint: '/colores',
        method: 'GET',
      );

      if (response.containsKey('data')) {
        final List<dynamic> jsonData = response['data'];
        final List<ColorApp> colores = jsonData.map((json) => ColorApp.fromJson(json)).toList();
        
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
