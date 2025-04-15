import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/models/ventas.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/foundation.dart';

/// Repositorio para gestionar ventas
///
/// Esta clase encapsula la lógica de negocio relacionada con ventas,
/// actuando como una capa intermedia entre la UI y la API
class VentaRepository implements BaseRepository {
  /// Instancia singleton del repositorio
  static final VentaRepository _instance = VentaRepository._internal();

  /// Getter para la instancia singleton
  static VentaRepository get instance => _instance;

  /// API de ventas
  late final VentasApi _ventasApi;

  /// Constructor privado para el patrón singleton
  VentaRepository._internal() {
    try {
      // Utilizamos la API global inicializada en index.api.dart
      _ventasApi = api.ventas;
    } catch (e) {
      debugPrint('Error al obtener VentasApi: $e');
      // Si hay un error al acceder a la API global, lanzamos una excepción
      throw Exception('No se pudo inicializar VentaRepository: $e');
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
      debugPrint('Error en VentaRepository.getUserData: $e');
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
      debugPrint('Error en VentaRepository.getCurrentSucursalId: $e');
      return null;
    }
  }

  /// Obtiene las ventas de una sucursal con filtros y paginación
  ///
  /// [sucursalId] ID de la sucursal
  /// [page] Número de página actual
  /// [pageSize] Tamaño de página
  /// [search] Texto para buscar ventas
  /// [fechaInicio] Fecha de inicio para filtrar
  /// [fechaFin] Fecha de fin para filtrar
  /// [estado] Estado de la venta para filtrar
  /// [sortBy] Campo por el cual ordenar
  /// [order] Tipo de ordenamiento (asc/desc)
  Future<Map<String, dynamic>> getVentas({
    required sucursalId,
    int page = 1,
    int pageSize = 10,
    String? search,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? estado,
    String? sortBy,
    String? order,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      return await _ventasApi.getVentas(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        search: search,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        estado: estado,
        useCache: useCache,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      debugPrint('Error en VentaRepository.getVentas: $e');
      rethrow;
    }
  }

  /// Obtiene una venta específica
  ///
  /// [ventaId] ID de la venta
  /// [sucursalId] ID de la sucursal
  Future<Venta?> getVenta(
    String ventaId, {
    required sucursalId,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      return await _ventasApi.getVenta(
        ventaId,
        sucursalId: sucursalId,
        useCache: useCache,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      debugPrint('Error en VentaRepository.getVenta: $e');
      return null;
    }
  }

  /// Declara una venta ante SUNAT
  ///
  /// [ventaId] ID de la venta
  /// [sucursalId] ID de la sucursal
  /// [enviarCliente] Indica si se debe enviar el comprobante al cliente
  Future<Map<String, dynamic>> declararVenta(
    String ventaId, {
    required sucursalId,
    bool enviarCliente = false,
  }) async {
    try {
      return await _ventasApi.declararVenta(
        ventaId,
        sucursalId: sucursalId,
        enviarCliente: enviarCliente,
      );
    } catch (e) {
      debugPrint('Error en VentaRepository.declararVenta: $e');
      return {'status': 'error', 'message': 'Error al declarar venta: $e'};
    }
  }

  /// Anula una venta
  ///
  /// [ventaId] ID de la venta
  /// [sucursalId] ID de la sucursal
  /// [motivo] Motivo de la anulación
  Future<bool> anularVenta(
    String ventaId,
    String motivo, {
    required sucursalId,
  }) async {
    try {
      return await _ventasApi.anularVenta(
        ventaId,
        motivo,
        sucursalId: sucursalId,
      );
    } catch (e) {
      debugPrint('Error en VentaRepository.anularVenta: $e');
      return false;
    }
  }

  /// Cancela una venta
  ///
  /// [ventaId] ID de la venta
  /// [sucursalId] ID de la sucursal
  /// [motivo] Motivo de la cancelación
  Future<bool> cancelarVenta(
    String ventaId,
    String motivo, {
    required sucursalId,
  }) async {
    try {
      return await _ventasApi.cancelarVenta(
        ventaId,
        motivo,
        sucursalId: sucursalId,
      );
    } catch (e) {
      debugPrint('Error en VentaRepository.cancelarVenta: $e');
      return false;
    }
  }

  /// Obtiene ventas por rango de fechas
  ///
  /// [sucursalId] ID de la sucursal
  /// [fechaInicio] Fecha de inicio
  /// [fechaFin] Fecha de fin
  /// [page] Número de página
  /// [pageSize] Tamaño de página
  Future<Map<String, dynamic>> getVentasPorFecha({
    required sucursalId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    int page = 1,
    int pageSize = 10,
    bool useCache = false,
  }) async {
    try {
      return await _ventasApi.getVentas(
        sucursalId: sucursalId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        page: page,
        pageSize: pageSize,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint('Error en VentaRepository.getVentasPorFecha: $e');
      rethrow;
    }
  }

  /// Obtiene ventas por estado
  ///
  /// [sucursalId] ID de la sucursal
  /// [estado] Estado de la venta
  /// [page] Número de página
  /// [pageSize] Tamaño de página
  Future<Map<String, dynamic>> getVentasPorEstado({
    required sucursalId,
    required String estado,
    int page = 1,
    int pageSize = 10,
    bool useCache = false,
  }) async {
    try {
      return await _ventasApi.getVentas(
        sucursalId: sucursalId,
        estado: estado,
        page: page,
        pageSize: pageSize,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint('Error en VentaRepository.getVentasPorEstado: $e');
      rethrow;
    }
  }

  /// Crear una nueva venta
  ///
  /// [ventaData] Datos de la venta
  /// [sucursalId] ID de la sucursal
  Future<Map<String, dynamic>> createVenta(
    Map<String, dynamic> ventaData, {
    required sucursalId,
  }) async {
    try {
      return await _ventasApi.createVenta(
        ventaData,
        sucursalId: sucursalId,
      );
    } catch (e) {
      debugPrint('Error en VentaRepository.createVenta: $e');
      rethrow;
    }
  }

  /// Actualiza una venta existente
  ///
  /// [ventaId] ID de la venta
  /// [ventaData] Datos actualizados
  /// [sucursalId] ID de la sucursal
  Future<Map<String, dynamic>> updateVenta(
    String ventaId,
    Map<String, dynamic> ventaData, {
    required sucursalId,
  }) async {
    try {
      return await _ventasApi.updateVenta(
        ventaId,
        ventaData,
        sucursalId: sucursalId,
      );
    } catch (e) {
      debugPrint('Error en VentaRepository.updateVenta: $e');
      rethrow;
    }
  }

  /// Invalida la caché de ventas
  void invalidateCache([String? sucursalId]) {
    _ventasApi.invalidateCache(sucursalId);
  }
}
