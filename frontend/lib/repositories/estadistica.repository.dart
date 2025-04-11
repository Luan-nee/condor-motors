import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/foundation.dart';

/// Repositorio para gestionar estadísticas
///
/// Esta clase encapsula la lógica de negocio relacionada con estadísticas,
/// actuando como una capa intermedia entre la UI y la API
class EstadisticaRepository implements BaseRepository {
  /// Instancia singleton del repositorio
  static final EstadisticaRepository _instance =
      EstadisticaRepository._internal();

  /// Getter para la instancia singleton
  static EstadisticaRepository get instance => _instance;

  /// API de estadísticas
  late final dynamic _estadisticasApi;

  /// Constructor privado para el patrón singleton
  EstadisticaRepository._internal() {
    try {
      // Utilizamos la API global inicializada en index.api.dart
      _estadisticasApi = api.estadisticas;
    } catch (e) {
      debugPrint('Error al obtener EstadisticasApi: $e');
      // Si hay un error al acceder a la API global, lanzamos una excepción
      throw Exception('No se pudo inicializar EstadisticaRepository: $e');
    }
  }

  /// Obtiene datos del usuario desde la API centralizada
  ///
  /// Ayuda a los providers a acceder a la información del usuario autenticado
  @override
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      return await api.getUserData();
    } catch (e) {
      debugPrint('Error en EstadisticaRepository.getUserData: $e');
      return null;
    }
  }

  /// Obtiene el ID de la sucursal del usuario actual
  ///
  /// Útil para operaciones que requieren el ID de sucursal automáticamente
  @override
  Future<String?> getCurrentSucursalId() async {
    try {
      final userData = await getUserData();
      if (userData == null) {
        return null;
      }
      return userData['sucursalId']?.toString();
    } catch (e) {
      debugPrint('Error en EstadisticaRepository.getCurrentSucursalId: $e');
      return null;
    }
  }

  /// Obtiene un resumen general de estadísticas
  ///
  /// [useCache] Indica si se debe usar la caché
  /// [forceRefresh] Indica si se debe forzar la recarga desde el servidor
  Future<Map<String, dynamic>> getResumenEstadisticas({
    bool useCache = false,
    bool forceRefresh = true,
  }) async {
    try {
      return await _estadisticasApi.getResumenEstadisticas(
        useCache: useCache,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      debugPrint('Error en EstadisticaRepository.getResumenEstadisticas: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Obtiene estadísticas por sucursal
  ///
  /// [sucursalId] ID de la sucursal para la que se quieren obtener estadísticas
  /// [useCache] Indica si se debe usar la caché
  Future<Map<String, dynamic>> getEstadisticasPorSucursal(
    String sucursalId, {
    bool useCache = false,
  }) async {
    try {
      return await _estadisticasApi.getEstadisticasPorSucursal(
        sucursalId,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint(
          'Error en EstadisticaRepository.getEstadisticasPorSucursal: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Obtiene estadísticas de ventas para un período específico
  ///
  /// [fechaInicio] Fecha de inicio del período
  /// [fechaFin] Fecha de fin del período
  /// [sucursalId] ID de la sucursal (opcional)
  Future<Map<String, dynamic>> getEstadisticasVentas({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? sucursalId,
  }) async {
    try {
      return await _estadisticasApi.getEstadisticasVentas(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        sucursalId: sucursalId,
      );
    } catch (e) {
      debugPrint('Error en EstadisticaRepository.getEstadisticasVentas: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Obtiene estadísticas de productos
  ///
  /// [sucursalId] ID de la sucursal (opcional)
  /// [categoria] Categoría de productos (opcional)
  Future<Map<String, dynamic>> getEstadisticasProductos({
    String? sucursalId,
    String? categoria,
  }) async {
    try {
      return await _estadisticasApi.getEstadisticasProductos(
        sucursalId: sucursalId,
        categoria: categoria,
      );
    } catch (e) {
      debugPrint('Error en EstadisticaRepository.getEstadisticasProductos: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Obtiene datos para gráficos de ventas
  ///
  /// [tipo] Tipo de gráfico (diario, semanal, mensual, anual)
  /// [sucursalId] ID de la sucursal (opcional)
  /// [fechaInicio] Fecha de inicio (opcional)
  /// [fechaFin] Fecha de fin (opcional)
  Future<Map<String, dynamic>> getGraficosVentas({
    required String tipo,
    String? sucursalId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      return await _estadisticasApi.getGraficosVentas(
        tipo: tipo,
        sucursalId: sucursalId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
    } catch (e) {
      debugPrint('Error en EstadisticaRepository.getGraficosVentas: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
