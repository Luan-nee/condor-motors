import '../../models/color.model.dart';
import '../main.api.dart';

/// API para la gestión de colores
class ColoresApi {
  final ApiClient _apiClient;

  ColoresApi({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  /// Obtiene todos los colores disponibles en el sistema
  Future<List<ColorApp>> getColores() async {
    try {
      final response = await _apiClient.authenticatedRequest(
        endpoint: '/colores',
        method: 'GET',
      );

      if (response.containsKey('data')) {
        final List<dynamic> jsonData = response['data'];
        return jsonData.map((json) => ColorApp.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener colores: Formato de respuesta inesperado');
      }
    } catch (e) {
      throw Exception('Error al obtener colores: $e');
    }
  }
}
