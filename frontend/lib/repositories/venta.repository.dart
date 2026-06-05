import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/api/protected/ventas.api.dart';
import 'package:condorsmotors/models/ventas.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';

/// Repositorio para gestionar ventas.
///
/// Encapsula la lógica de negocio y consumo de APIs de ventas,
/// delegando la autenticación mediante el mixin [AuthDelegator].
class VentaRepository with AuthDelegator implements BaseRepository {
  static final VentaRepository _instance = VentaRepository._internal();
  static VentaRepository get instance => _instance;

  late final VentasApi _ventasApi;

  VentaRepository._internal() {
    _ventasApi = api_index.api.ventas;
  }

  /// Obtiene las ventas de una sucursal con filtros y paginación.
  Future<Map<String, dynamic>> getVentas({
    required String sucursalId,
    int page = 1,
    int pageSize = 10,
    String? search,
    String? sortBy,
    String? order,
    bool useCache = true,
    bool forceRefresh = false,
  }) =>
      _ventasApi.getVentas(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        search: search,
        sortBy: sortBy,
        order: order,
        useCache: useCache,
        forceRefresh: forceRefresh,
      );

  /// Obtiene una venta específica.
  Future<Venta?> getVenta(
    String ventaId, {
    required String sucursalId,
    bool useCache = true,
    bool forceRefresh = false,
  }) =>
      _ventasApi.getVenta(
        ventaId,
        sucursalId: sucursalId,
        useCache: useCache,
        forceRefresh: forceRefresh,
      );

  /// Declara una venta ante la SUNAT delegándolo al repositorio de facturación.
  Future<Map<String, dynamic>> declararVenta(
    String ventaId, {
    required String sucursalId,
    bool enviarCliente = false,
  }) =>
      FacturacionRepository.instance.declararVenta(
        ventaId: ventaId,
        sucursalId: sucursalId,
        enviarCliente: enviarCliente,
      );

  /// Anula una venta.
  Future<bool> anularVenta(
    String ventaId,
    String motivo, {
    required String sucursalId,
  }) =>
      _ventasApi.anularVenta(
        ventaId,
        motivo,
        sucursalId: sucursalId,
      );

  /// Cancela una venta.
  Future<bool> cancelarVenta(
    String ventaId,
    String motivo, {
    required String sucursalId,
  }) =>
      _ventasApi.cancelarVenta(
        ventaId,
        motivo,
        sucursalId: sucursalId,
      );

  /// Crea una nueva venta.
  Future<Map<String, dynamic>> createVenta(
    Map<String, dynamic> ventaData, {
    required String sucursalId,
  }) =>
      _ventasApi.createVenta(
        ventaData,
        sucursalId: sucursalId,
      );

  /// Actualiza una venta existente.
  Future<Map<String, dynamic>> updateVenta(
    String ventaId,
    Map<String, dynamic> ventaData, {
    required String sucursalId,
  }) =>
      _ventasApi.updateVenta(
        ventaId,
        ventaData,
        sucursalId: sucursalId,
      );

  /// Invalida la caché de ventas de una sucursal específica o total.
  void invalidateCache([String? sucursalId]) =>
      _ventasApi.invalidateCache(sucursalId);

  /// Crea una venta optimizada utilizando solo los datos necesarios para el backend.
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
  }) {
    final Map<String, dynamic> ventaData = Venta.crearVentaOptimizada(
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

    return _ventasApi.createVenta(
      ventaData,
      sucursalId: sucursalId,
    );
  }
}
