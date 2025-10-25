import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/api/protected/proforma.api.dart' as api_proforma;
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/proforma.model.dart' as model_proforma;
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/foundation.dart';

/// Repositorio para gestionar proformas
///
/// Esta clase encapsula la lógica de negocio relacionada con proformas,
/// actuando como una capa intermedia entre la UI y la API
class ProformaRepository implements BaseRepository {
  /// Instancia singleton del repositorio
  static final ProformaRepository _instance = ProformaRepository._internal();

  /// Getter para la instancia singleton
  static ProformaRepository get instance => _instance;

  /// API de proformas
  late final api_proforma.ProformaVentaApi _proformasApi;

  /// Constructor privado para el patrón singleton
  ProformaRepository._internal() {
    try {
      // Utilizamos la API global inicializada en index.api.dart
      _proformasApi = api_index.api.proformas;
    } catch (e) {
      debugPrint('Error al obtener ProformaVentaApi: $e');
      // Si hay un error al acceder a la API global, lanzamos una excepción
      throw Exception('No se pudo inicializar ProformaRepository: $e');
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

  /// Obtiene las proformas de una sucursal con paginación
  ///
  /// [sucursalId] ID de la sucursal
  /// [page] Número de página actual
  /// [pageSize] Tamaño de página
  /// [search] Texto para buscar proformas
  /// [useCache] Indica si se debe usar la caché
  /// [forceRefresh] Indica si se debe forzar la recarga desde el servidor
  Future<Map<String, dynamic>> getProformas({
    required String sucursalId,
    int page = 1,
    int pageSize = 10,
    String? search,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      return await _proformasApi.getProformasVenta(
        sucursalId: sucursalId,
        page: page,
        pageSize: pageSize,
        search: search,
        useCache: useCache,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      debugPrint('Error en ProformaRepository.getProformas: $e');
      rethrow;
    }
  }

  /// Obtiene una proforma específica
  ///
  /// [sucursalId] ID de la sucursal
  /// [proformaId] ID de la proforma
  /// [useCache] Indica si se debe usar la caché
  /// [forceRefresh] Indica si se debe forzar la recarga desde el servidor
  Future<Map<String, dynamic>> getProforma({
    required String sucursalId,
    required int proformaId,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      return await _proformasApi.getProformaVenta(
        sucursalId: sucursalId,
        proformaId: proformaId,
        useCache: useCache,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      debugPrint('Error en ProformaRepository.getProforma: $e');
      rethrow;
    }
  }

  /// Crea una nueva proforma
  ///
  /// [sucursalId] ID de la sucursal
  /// [nombre] Nombre de la proforma (opcional)
  /// [total] Total de la proforma
  /// [detalles] Lista de detalles de la proforma
  /// [empleadoId] ID del empleado
  /// [clienteId] ID del cliente (opcional)
  /// [estado] Estado de la proforma (opcional)
  /// [fechaExpiracion] Fecha de expiración (opcional)
  Future<Map<String, dynamic>> createProforma({
    required String sucursalId,
    String? nombre,
    required double total,
    required List<model_proforma.DetalleProforma> detalles,
    required int empleadoId,
    int? clienteId,
    String? estado,
    DateTime? fechaExpiracion,
  }) async {
    try {
      // Convertir detalles del modelo a detalles de la API
      final List<api_proforma.DetalleProforma> detallesApi =
          detalles.map((detalle) {
        return api_proforma.DetalleProforma(
          productoId: detalle.productoId,
          nombre: detalle.nombre,
          cantidad: detalle.cantidad,
          subtotal: detalle.subtotal,
          precioUnitario: detalle.precioUnitario,
        );
      }).toList();

      return await _proformasApi.createProformaVenta(
        sucursalId: sucursalId,
        nombre: nombre,
        total: total,
        detalles: detallesApi,
        empleadoId: empleadoId,
        clienteId: clienteId,
        estado: estado,
        fechaExpiracion: fechaExpiracion,
      );
    } catch (e) {
      debugPrint('Error en ProformaRepository.createProforma: $e');
      rethrow;
    }
  }

  /// Actualiza una proforma existente
  ///
  /// [sucursalId] ID de la sucursal
  /// [proformaId] ID de la proforma
  /// [data] Datos a actualizar
  /// [estado] Nuevo estado (opcional)
  Future<Map<String, dynamic>> updateProforma({
    required String sucursalId,
    required int proformaId,
    Map<String, dynamic>? data,
    String? estado,
  }) async {
    try {
      return await _proformasApi.updateProformaVenta(
        sucursalId: sucursalId,
        proformaId: proformaId,
        data: data,
        estado: estado,
      );
    } catch (e) {
      debugPrint('Error en ProformaRepository.updateProforma: $e');
      rethrow;
    }
  }

  /// Elimina una proforma
  ///
  /// [sucursalId] ID de la sucursal
  /// [proformaId] ID de la proforma
  Future<Map<String, dynamic>> deleteProforma({
    required String sucursalId,
    required int proformaId,
  }) async {
    try {
      return await _proformasApi.deleteProformaVenta(
        sucursalId: sucursalId,
        proformaId: proformaId,
      );
    } catch (e) {
      debugPrint('Error en ProformaRepository.deleteProforma: $e');
      rethrow;
    }
  }

  /// Convierte datos de la API a una lista de objetos Proforma
  ///
  /// [data] Datos de la API
  List<model_proforma.Proforma> parseProformas(data) {
    return _proformasApi.parseProformasVenta(data);
  }

  /// Convierte datos de la API a un objeto Proforma
  ///
  /// [data] Datos de la API
  model_proforma.Proforma? parseProforma(data) {
    return _proformasApi.parseProformaVenta(data);
  }

  /// Invalida la caché de proformas
  ///
  /// [sucursalId] ID de la sucursal (opcional)
  void invalidateCache([String? sucursalId]) {
    try {
      _proformasApi.invalidateCache(sucursalId);
    } catch (e) {
      debugPrint('Error en ProformaRepository.invalidateCache: $e');
    }
  }

  /// Obtiene un ID de tipo de documento para BOLETA
  ///
  /// [sucursalId] ID de la sucursal
  Future<int> getTipoDocumentoIdBoleta(String sucursalId) async {
    try {
      return await api_index.api.documentos
          .getTipoDocumentoId(sucursalId, 'BOLETA');
    } catch (e) {
      debugPrint('Error en ProformaRepository.getTipoDocumentoIdBoleta: $e');
      rethrow;
    }
  }

  /// Obtiene el ID para tipo Tax Gravado (18% IGV)
  ///
  /// [sucursalId] ID de la sucursal
  Future<int> getGravadoTaxId(String sucursalId) async {
    try {
      return await api_index.api.documentos.getGravadoTaxId(sucursalId);
    } catch (e) {
      debugPrint('Error en ProformaRepository.getGravadoTaxId: $e');
      rethrow;
    }
  }

  /// Convierte una proforma a venta
  ///
  /// [sucursalId] ID de la sucursal
  /// [proforma] Proforma a convertir
  /// [tipoDocumentoId] ID del tipo de documento (BOLETA por defecto)
  /// [observaciones] Observaciones adicionales
  Future<Map<String, dynamic>> convertirAVenta({
    required String sucursalId,
    required model_proforma.Proforma proforma,
    int? tipoDocumentoId,
    String? observaciones,
  }) async {
    try {
      // Invalidar caché antes de la conversión
      invalidateCache(sucursalId);

      // Obtener un ID de tipo de documento para BOLETA si no se proporciona
      final int docId =
          tipoDocumentoId ?? await getTipoDocumentoIdBoleta(sucursalId);

      // Obtener ID del tipoTax para gravado (18% IGV)
      final int tipoTaxId = await getGravadoTaxId(sucursalId);

      // Obtener detalles completos de la proforma
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
        throw Exception(
            'La proforma no tiene productos, no se puede convertir a venta');
      }

      // Transformar los detalles para la venta
      final List<Map<String, dynamic>> detallesVenta = [];
      for (final dynamic detalle in detalles) {
        if (detalle == null || !detalle.containsKey('productoId')) {
          continue;
        }

        detallesVenta.add({
          'productoId': detalle['productoId'],
          'cantidad':
              detalle['cantidadPagada'] ?? detalle['cantidadTotal'] ?? 1,
          'tipoTaxId': tipoTaxId,
          'aplicarOferta':
              detalle['descuento'] != null && detalle['descuento'] > 0
        });
      }

      if (detallesVenta.isEmpty) {
        throw Exception('No hay productos válidos para convertir');
      }

      // Obtener cliente (intentar usar el de la proforma o uno predeterminado)
      int clienteId = 1; // Cliente por defecto
      if (proformaData.containsKey('clienteId') &&
          proformaData['clienteId'] != null) {
        clienteId =
            int.tryParse(proformaData['clienteId'].toString()) ?? clienteId;
      } else if (proformaData.containsKey('cliente') &&
          proformaData['cliente'] is Map &&
          proformaData['cliente'].containsKey('id')) {
        clienteId =
            int.tryParse(proformaData['cliente']['id'].toString()) ?? clienteId;
      }

      // Obtener empleadoId
      int? empleadoId;
      final userData = await getUserData();
      if (userData != null && userData.containsKey('empleadoId')) {
        empleadoId = int.tryParse(userData['empleadoId'].toString());
      }

      if (empleadoId == null) {
        // Buscar un empleado de la sucursal
        final empleados =
            await api_index.api.empleados.getEmpleadosPorSucursal(sucursalId);
        if (empleados.empleados.isNotEmpty) {
          empleadoId = int.tryParse(empleados.empleados.first.id);
        }
      }

      if (empleadoId == null) {
        throw Exception('No se pudo obtener un ID de empleado válido');
      }

      // Crear los datos para la venta
      final Map<String, dynamic> ventaData = {
        'observaciones':
            observaciones ?? 'Convertida desde Proforma #${proforma.id}',
        'tipoDocumentoId': docId,
        'detalles': detallesVenta,
        'clienteId': clienteId,
        'empleadoId': empleadoId,
      };

      // Crear la venta
      final ventaResponse = await api_index.api.ventas.createVenta(
        ventaData,
        sucursalId: sucursalId,
      );

      if (ventaResponse['status'] != 'success') {
        throw Exception(
            'Error al crear venta: ${ventaResponse['error'] ?? ventaResponse['message'] ?? "Error desconocido"}');
      }

      // CAMBIO: Eliminar la proforma en lugar de actualizarla
      try {
        await deleteProforma(
          sucursalId: sucursalId,
          proformaId: proforma.id,
        );
        debugPrint(
            'Proforma #${proforma.id} eliminada después de convertirse a venta');
      } catch (deleteError) {
        // Si hay error al eliminar, registrarlo pero no fallar el proceso completo
        debugPrint(
            'Advertencia: No se pudo eliminar la proforma #${proforma.id} después de convertirla: $deleteError');
      }

      return ventaResponse;
    } catch (e) {
      debugPrint('Error en ProformaRepository.convertirAVenta: $e');
      throw Exception('Error al convertir proforma a venta: $e');
    }
  }

  /// Crea un detalle de proforma a partir de un producto
  api_proforma.DetalleProforma crearDetalleDesdeProducto(Producto producto,
      {int cantidad = 1}) {
    return api_proforma.DetalleProforma.fromProducto(producto,
        cantidad: cantidad);
  }

  /// Crea una lista de detalles de proforma a partir de productos y cantidades
  List<api_proforma.DetalleProforma> crearDetallesDesdeProductos(
    List<Producto> productos,
    Map<int, int> cantidades,
  ) {
    return _proformasApi.crearDetallesDesdeProductos(productos, cantidades);
  }

  /// Calcula el total de una lista de detalles de proforma
  double calcularTotal(List<api_proforma.DetalleProforma> detalles) {
    return _proformasApi.calcularTotal(detalles);
  }
}

/// Clase auxiliar para adaptar objetos DetalleProforma del modelo a DetalleProforma de la API
class DetalleProformaApi {
  /// Convierte un DetalleProforma del modelo a un DetalleProforma para la API
  static api_proforma.DetalleProforma fromProforma(
      model_proforma.DetalleProforma detalle) {
    return api_proforma.DetalleProforma(
      productoId: detalle.productoId,
      nombre: detalle.nombre,
      cantidad: detalle.cantidad,
      subtotal: detalle.subtotal,
      precioUnitario: detalle.precioUnitario,
    );
  }

  /// Convierte un producto a DetalleProforma para la API
  static api_proforma.DetalleProforma fromProducto(Producto producto,
      {int cantidad = 1}) {
    return api_proforma.DetalleProforma.fromProducto(producto,
        cantidad: cantidad);
  }
}
