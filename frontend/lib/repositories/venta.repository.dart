import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/api/protected/ventas.api.dart';
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
      _ventasApi = api_index.api.ventas;
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
  Future<Map<String, dynamic>?> getUserData() =>
      api_index.AuthManager.getUserData();

  /// Obtiene el ID de la sucursal del usuario actual
  ///
  /// Útil para operaciones que requieren el ID de sucursal automáticamente
  @override
  Future<String?> getCurrentSucursalId() =>
      api_index.AuthManager.getCurrentSucursalId();

  /// Obtiene las ventas de una sucursal con filtros y paginación
  ///
  /// [sucursalId] ID de la sucursal
  /// [page] Número de página actual
  /// [pageSize] Tamaño de página
  /// [search] Texto para buscar ventas
  /// [sortBy] Campo por el cual ordenar
  /// [order] Tipo de ordenamiento (asc/desc)
  Future<Map<String, dynamic>> getVentas({
    required sucursalId,
    int page = 1,
    int pageSize = 10,
    String? search,
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
        sortBy: sortBy,
        order: order,
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
      // Delegamos esta funcionalidad a FacturacionRepository para mantener
      // toda la lógica de facturación centralizada
      return await FacturacionRepository.instance.declararVenta(
        ventaId: ventaId,
        sucursalId: sucursalId.toString(),
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

  /// Crea una venta optimizada utilizando solo los datos necesarios para el backend
  ///
  /// [tipoDocumentoId] - Tipo de documento (1: Factura, 2: Boleta)
  /// [clienteId] - ID del cliente
  /// [empleadoId] - ID del empleado
  /// [detalles] - Lista de detalles de venta
  /// [sucursalId] - ID de la sucursal
  /// [observaciones] - Observaciones opcionales
  /// [monedaId] - ID de la moneda (opcional)
  /// [metodoPagoId] - ID del método de pago (opcional)
  /// [fechaEmision] - Fecha de emisión (opcional)
  /// [horaEmision] - Hora de emisión (opcional)
  Future<Map<String, dynamic>> crearVentaOptimizada({
    required int tipoDocumentoId,
    required int clienteId,
    required int empleadoId,
    required List<DetalleVenta> detalles,
    required String sucursalId,
    String? observaciones,
    int? monedaId,
    int? metodoPagoId,
    DateTime? fechaEmision,
    String? horaEmision,
  }) async {
    try {
      // Crear objeto optimizado utilizando el modelo de Venta
      final ventaData = Venta.crearVentaOptimizada(
        tipoDocumentoId: tipoDocumentoId,
        clienteId: clienteId,
        empleadoId: empleadoId,
        detalles: detalles,
        observaciones: observaciones,
        monedaId: monedaId,
        metodoPagoId: metodoPagoId,
        fechaEmision: fechaEmision,
        horaEmision: horaEmision,
      );

      // Llamar a la API con datos optimizados
      return await _ventasApi.createVenta(
        ventaData,
        sucursalId: sucursalId,
      );
    } catch (e) {
      debugPrint('Error en VentaRepository.crearVentaOptimizada: $e');
      rethrow;
    }
  }
}
