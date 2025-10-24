import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/material.dart';

/// Repositorio para gestionar transferencias de inventario
///
/// Esta clase encapsula la lógica de negocio relacionada con transferencias,
/// actuando como una capa intermedia entre la UI y la API
class TransferenciaRepository implements BaseRepository {
  /// Instancia singleton del repositorio
  static final TransferenciaRepository _instance =
      TransferenciaRepository._internal();

  /// Getter para la instancia singleton
  static TransferenciaRepository get instance => _instance;

  /// API de transferencias
  late final TransferenciasInventarioApi _transferenciasApi;

  /// Constructor privado para el patrón singleton
  TransferenciaRepository._internal() {
    try {
      // Utilizamos la API global inicializada en index.api.dart
      _transferenciasApi = api.transferencias;
    } catch (e) {
      debugPrint('Error al obtener TransferenciasInventarioApi: $e');
      // Si hay un error al acceder a la API global, lanzamos una excepción
      throw Exception('No se pudo inicializar TransferenciaRepository: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserData() =>
      AuthRepository.instance.getUserData();

  @override
  Future<String?> getCurrentSucursalId() =>
      AuthRepository.instance.getCurrentSucursalId();

  /// Invalida la caché de transferencias
  void invalidateCache([String? sucursalId]) {
    try {
      _transferenciasApi.invalidateCache(sucursalId);
    } catch (e) {
      debugPrint('Error en TransferenciaRepository.invalidateCache: $e');
    }
  }

  /// Obtiene todas las transferencias de inventario con paginación y filtros
  ///
  /// [sucursalId] ID de la sucursal para filtrar
  /// [estado] Estado de las transferencias para filtrar
  /// [fechaInicio] Fecha inicial para filtrar
  /// [fechaFin] Fecha final para filtrar
  /// [sortBy] Campo por el cual ordenar
  /// [order] Orden (asc/desc)
  /// [page] Página actual
  /// [pageSize] Tamaño de página
  /// [useCache] Indica si se debe usar la caché
  /// [forceRefresh] Indica si se debe forzar la recarga desde el servidor
  Future<PaginatedResponse<TransferenciaInventario>> getTransferencias({
    String? sucursalId,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? sortBy,
    String? order,
    int? page,
    int? pageSize,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      return await _transferenciasApi.getTransferencias(
        sucursalId: sucursalId,
        estado: estado,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        sortBy: sortBy,
        order: order,
        page: page,
        pageSize: pageSize,
        useCache: useCache,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      debugPrint('Error en TransferenciaRepository.getTransferencias: $e');
      rethrow;
    }
  }

  /// Obtiene una transferencia específica por ID
  ///
  /// [id] ID de la transferencia
  /// [useCache] Indica si se debe usar la caché
  Future<TransferenciaInventario> getTransferencia(
    String id, {
    bool useCache = true,
  }) async {
    try {
      return await _transferenciasApi.getTransferencia(
        id,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint('Error en TransferenciaRepository.getTransferencia: $e');
      rethrow;
    }
  }

  /// Crea una nueva transferencia de inventario
  ///
  /// [sucursalDestinoId] ID de la sucursal destino
  /// [items] Lista de items a transferir
  /// [observaciones] Observaciones opcionales
  Future<TransferenciaInventario> createTransferencia({
    required int sucursalDestinoId,
    required List<Map<String, dynamic>> items,
    String? observaciones,
  }) async {
    try {
      return await _transferenciasApi.createTransferencia(
        sucursalDestinoId: sucursalDestinoId,
        items: items,
        observaciones: observaciones,
      );
    } catch (e) {
      debugPrint('Error en TransferenciaRepository.createTransferencia: $e');
      rethrow;
    }
  }

  /// Envía una transferencia de inventario
  ///
  /// [id] ID de la transferencia
  /// [sucursalOrigenId] ID de la sucursal origen
  Future<TransferenciaInventario> enviarTransferencia(
    String id, {
    required int sucursalOrigenId,
  }) async {
    try {
      return await _transferenciasApi.enviarTransferencia(
        id,
        sucursalOrigenId: sucursalOrigenId,
      );
    } catch (e) {
      debugPrint('Error en TransferenciaRepository.enviarTransferencia: $e');
      rethrow;
    }
  }

  /// Recibe una transferencia de inventario
  ///
  /// [id] ID de la transferencia a recibir
  Future<TransferenciaInventario> recibirTransferencia(String id) async {
    try {
      return await _transferenciasApi.recibirTransferencia(id);
    } catch (e) {
      debugPrint('Error en TransferenciaRepository.recibirTransferencia: $e');
      rethrow;
    }
  }

  /// Cancela una transferencia de inventario
  ///
  /// [id] ID de la transferencia a cancelar
  Future<bool> cancelarTransferencia(String id) async {
    try {
      return await _transferenciasApi.cancelarTransferencia(id);
    } catch (e) {
      debugPrint('Error en TransferenciaRepository.cancelarTransferencia: $e');
      rethrow;
    }
  }

  /// Obtiene la comparación de stocks para una transferencia
  ///
  /// [id] ID de la transferencia
  /// [sucursalOrigenId] ID de la sucursal origen
  /// [useCache] Indica si se debe usar la caché
  Future<ComparacionTransferencia> compararTransferencia({
    required String id,
    required int sucursalOrigenId,
    bool useCache = false,
  }) async {
    try {
      return await _transferenciasApi.compararTransferencia(
        id: id,
        sucursalOrigenId: sucursalOrigenId,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint('Error en TransferenciaRepository.compararTransferencia: $e');
      rethrow;
    }
  }

  /// Verifica si una transferencia puede ser comparada basado en su estado
  ///
  /// [estadoCodigo] Código del estado de la transferencia
  bool puedeCompararTransferencia(String estadoCodigo) {
    return estadoCodigo.toUpperCase() == 'PEDIDO';
  }

  /// Obtiene el mensaje de estado para la comparación de transferencias
  ///
  /// [estadoCodigo] Código del estado de la transferencia
  String obtenerMensajeComparacion(String estadoCodigo) {
    switch (estadoCodigo.toUpperCase()) {
      case 'PEDIDO':
        return 'Seleccione una sucursal para comparar el stock disponible antes de enviar.';
      case 'RECIBIDO':
        return 'Transferencia completada. Los stocks mostrados reflejan el estado final.';
      case 'ENVIADO':
        return 'Transferencia en tránsito. La comparación de stock no está disponible.';
      default:
        return 'No es posible realizar la comparación en el estado actual.';
    }
  }

  /// Obtiene información de estilo según el estado de la transferencia
  ///
  /// [estado] Código del estado de la transferencia
  Map<String, dynamic> obtenerEstiloEstado(String estado) {
    Color backgroundColor;
    Color textColor;
    IconData iconData;
    String tooltipText;

    switch (estado.toUpperCase()) {
      case 'RECIBIDO':
        backgroundColor = const Color(0xFF2D8A3B).withValues(alpha: 0.15);
        textColor = const Color(0xFF4CAF50);
        iconData = Icons.check_circle;
        tooltipText = 'Transferencia completada';
      case 'PEDIDO':
        backgroundColor = const Color(0xFFFFA000).withValues(alpha: 0.15);
        textColor = const Color(0xFFFFA000);
        iconData = Icons.history;
        tooltipText = 'En proceso';
      case 'ENVIADO':
        backgroundColor = const Color(0xFF009688).withValues(alpha: 0.15);
        textColor = const Color(0xFF009688);
        iconData = Icons.local_shipping;
        tooltipText = 'En tránsito';
      default:
        backgroundColor = const Color(0xFF757575).withValues(alpha: 0.15);
        textColor = const Color(0xFF9E9E9E);
        iconData = Icons.hourglass_empty;
        tooltipText = 'Estado sin definir';
    }

    final estadoEnum = EstadoTransferencia.values.firstWhere(
      (e) => e.codigo == estado.toUpperCase(),
      orElse: () => EstadoTransferencia.pedido,
    );

    return {
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'iconData': iconData,
      'tooltipText': tooltipText,
      'estadoDisplay': estadoEnum.nombre,
    };
  }
}
