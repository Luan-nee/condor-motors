import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/api/protected/proforma.api.dart' as api_proforma;
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/proforma.model.dart' as model_proforma;
import 'package:condorsmotors/repositories/index.repository.dart';

/// Repositorio para gestionar proformas.
///
/// Encapsula la lógica de negocio y consumo de APIs de proformas,
/// delegando la autenticación mediante el mixin [AuthDelegator].
class ProformaRepository with AuthDelegator implements BaseRepository {
  static final ProformaRepository _instance = ProformaRepository._internal();
  static ProformaRepository get instance => _instance;

  late final api_proforma.ProformaVentaApi _proformasApi;

  ProformaRepository._internal() {
    _proformasApi = api_index.api.proformas;
  }

  /// Obtiene las proformas de una sucursal con paginación.
  Future<Map<String, dynamic>> getProformas({
    required String sucursalId,
    int page = 1,
    int pageSize = 10,
    String? search,
    bool useCache = true,
    bool forceRefresh = false,
  }) =>
      _proformasApi.getProformasVenta(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        search: search,
        useCache: useCache,
        forceRefresh: forceRefresh,
      );

  /// Obtiene una proforma específica.
  Future<Map<String, dynamic>> getProforma({
    required String sucursalId,
    required int proformaId,
    bool useCache = true,
    bool forceRefresh = false,
  }) =>
      _proformasApi.getProformaVenta(
        sucursalId: sucursalId,
        proformaId: proformaId,
        useCache: useCache,
        forceRefresh: forceRefresh,
      );

  /// Crea una nueva proforma de venta.
  Future<Map<String, dynamic>> createProforma({
    required String sucursalId,
    String? nombre,
    required double total,
    required List<model_proforma.DetalleProforma> detalles,
    required int empleadoId,
    int? clienteId,
    String? estado,
    DateTime? fechaExpiracion,
  }) {
    final List<api_proforma.DetalleProforma> detallesApi = detalles.map((detalle) {
      return api_proforma.DetalleProforma(
        productoId: detalle.productoId,
        nombre: detalle.nombre,
        cantidad: detalle.cantidad,
        subtotal: detalle.subtotal,
        precioUnitario: detalle.precioUnitario,
      );
    }).toList();

    return _proformasApi.createProformaVenta(
      sucursalId: sucursalId,
      nombre: nombre,
      total: total,
      detalles: detallesApi,
      empleadoId: empleadoId,
      clienteId: clienteId,
      estado: estado,
      fechaExpiracion: fechaExpiracion,
    );
  }

  /// Actualiza una proforma existente.
  Future<Map<String, dynamic>> updateProforma({
    required String sucursalId,
    required int proformaId,
    Map<String, dynamic>? data,
    String? estado,
  }) =>
      _proformasApi.updateProformaVenta(
        sucursalId: sucursalId,
        proformaId: proformaId,
        data: data,
        estado: estado,
      );

  /// Elimina una proforma.
  Future<Map<String, dynamic>> deleteProforma({
    required String sucursalId,
    required int proformaId,
  }) =>
      _proformasApi.deleteProformaVenta(
        sucursalId: sucursalId,
        proformaId: proformaId,
      );

  /// Convierte datos crudos de la API a una lista de objetos Proforma.
  List<model_proforma.Proforma> parseProformas(data) =>
      _proformasApi.parseProformasVenta(data);

  /// Convierte datos crudos de la API a un objeto Proforma.
  model_proforma.Proforma? parseProforma(data) =>
      _proformasApi.parseProformaVenta(data);

  /// Invalida la caché local de proformas.
  void invalidateCache([String? sucursalId]) =>
      _proformasApi.invalidateCache(sucursalId);

  /// Obtiene un ID de tipo de documento para BOLETA.
  Future<int> getTipoDocumentoIdBoleta(String sucursalId) =>
      api_index.api.documentos.getTipoDocumentoId(sucursalId, 'BOLETA');

  /// Obtiene el ID para tipo Tax Gravado (18% IGV).
  Future<int> getGravadoTaxId(String sucursalId) =>
      api_index.api.documentos.getGravadoTaxId(sucursalId);

  /// Convierte una proforma a venta.
  Future<Map<String, dynamic>> convertirAVenta({
    required String sucursalId,
    required model_proforma.Proforma proforma,
    int? tipoDocumentoId,
    String? observaciones,
  }) async {
    invalidateCache(sucursalId);

    final int docId = tipoDocumentoId ?? await getTipoDocumentoIdBoleta(sucursalId);
    final int tipoTaxId = await getGravadoTaxId(sucursalId);

    final proformaResponse = await getProforma(
      sucursalId: sucursalId,
      proformaId: proforma.id,
      forceRefresh: true,
    );

    if (proformaResponse.isEmpty ||
        !proformaResponse.containsKey('data') ||
        proformaResponse['data'] == null) {
      throw Exception('No se pudo obtener información de la proforma');
    }

    final proformaData = proformaResponse['data'];
    final List<dynamic> detalles = proformaData['detalles'] ?? [];

    if (detalles.isEmpty) {
      throw Exception('La proforma no tiene productos, no se puede convertir a venta');
    }

    final List<Map<String, dynamic>> detallesVenta = [];
    for (final dynamic detalle in detalles) {
      if (detalle == null || !detalle.containsKey('productoId')) {
        continue;
      }
      detallesVenta.add({
        'productoId': detalle['productoId'],
        'cantidad': detalle['cantidadPagada'] ?? detalle['cantidadTotal'] ?? 1,
        'tipoTaxId': tipoTaxId,
        'aplicarOferta': detalle['descuento'] != null && detalle['descuento'] > 0
      });
    }

    if (detallesVenta.isEmpty) {
      throw Exception('No hay productos válidos para convertir');
    }

    int clienteId = 1;
    if (proformaData.containsKey('clienteId') && proformaData['clienteId'] != null) {
      clienteId = int.tryParse(proformaData['clienteId'].toString()) ?? clienteId;
    } else if (proformaData.containsKey('cliente') &&
        proformaData['cliente'] is Map &&
        proformaData['cliente'].containsKey('id')) {
      clienteId = int.tryParse(proformaData['cliente']['id'].toString()) ?? clienteId;
    }

    int? empleadoId;
    final userData = await getUserData();
    if (userData != null && userData.containsKey('empleadoId')) {
      empleadoId = int.tryParse(userData['empleadoId'].toString());
    }

    if (empleadoId == null) {
      final empleados = await api_index.api.empleados.getEmpleadosPorSucursal(sucursalId);
      if (empleados.empleados.isNotEmpty) {
        empleadoId = int.tryParse(empleados.empleados.first.id);
      }
    }

    if (empleadoId == null) {
      throw Exception('No se pudo obtener un ID de empleado válido');
    }

    final Map<String, dynamic> ventaData = {
      'observaciones': observaciones ?? 'Convertida desde Proforma #${proforma.id}',
      'tipoDocumentoId': docId,
      'detalles': detallesVenta,
      'clienteId': clienteId,
      'empleadoId': empleadoId,
    };

    final ventaResponse = await api_index.api.ventas.createVenta(
      ventaData,
      sucursalId: sucursalId,
    );

    if (ventaResponse['status'] != 'success') {
      throw Exception(
          'Error al crear venta: ${ventaResponse['error'] ?? ventaResponse['message'] ?? "Error desconocido"}');
    }

    try {
      await deleteProforma(
        sucursalId: sucursalId,
        proformaId: proforma.id,
      );
    } catch (_) {}

    return ventaResponse;
  }

  /// Crea un detalle de proforma a partir de un producto.
  api_proforma.DetalleProforma crearDetalleDesdeProducto(
    Producto producto, {
    int cantidad = 1,
  }) =>
      api_proforma.DetalleProforma.fromProducto(producto, cantidad: cantidad);

  /// Crea una lista de detalles de proforma a partir de productos y cantidades.
  List<api_proforma.DetalleProforma> crearDetallesDesdeProductos(
    List<Producto> productos,
    Map<int, int> cantidades,
  ) =>
      _proformasApi.crearDetallesDesdeProductos(productos, cantidades);

  /// Calcula el total acumulado de una lista de detalles de proforma.
  double calcularTotal(List<api_proforma.DetalleProforma> detalles) =>
      _proformasApi.calcularTotal(detalles);
}

/// Clase auxiliar para adaptar objetos DetalleProforma del modelo a DetalleProforma de la API.
class DetalleProformaApi {
  /// Convierte un DetalleProforma de modelo a uno de API.
  static api_proforma.DetalleProforma fromProforma(
    model_proforma.DetalleProforma detalle,
  ) =>
      api_proforma.DetalleProforma(
        productoId: detalle.productoId,
        nombre: detalle.nombre,
        cantidad: detalle.cantidad,
        subtotal: detalle.subtotal,
        precioUnitario: detalle.precioUnitario,
      );

  /// Convierte un producto a DetalleProforma de API.
  static api_proforma.DetalleProforma fromProducto(
    Producto producto, {
    int cantidad = 1,
  }) =>
      api_proforma.DetalleProforma.fromProducto(producto, cantidad: cantidad);
}
