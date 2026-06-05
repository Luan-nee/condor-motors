import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/api/protected/transferencias.api.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:flutter/material.dart';

/// Repositorio para gestionar transferencias de inventario.
///
/// Encapsula la lógica de negocio y consumo de APIs de transferencias,
/// delegando la autenticación mediante el mixin [AuthDelegator].
class TransferenciaRepository with AuthDelegator implements BaseRepository {
  static final TransferenciaRepository _instance =
      TransferenciaRepository._internal();
  static TransferenciaRepository get instance => _instance;

  late final TransferenciasInventarioApi _transferenciasApi;

  TransferenciaRepository._internal() {
    _transferenciasApi = api_index.api.transferencias;
  }

  /// Invalida la caché de transferencias.
  void invalidateCache([String? sucursalId]) =>
      _transferenciasApi.invalidateCache(sucursalId);

  /// Obtiene todas las transferencias de inventario con paginación y filtros.
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
  }) =>
      _transferenciasApi.getTransferencias(
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

  /// Obtiene una transferencia específica por su ID.
  Future<TransferenciaInventario> getTransferencia(
    String id, {
    bool useCache = true,
  }) =>
      _transferenciasApi.getTransferencia(id, useCache: useCache);

  /// Crea una nueva transferencia de inventario.
  Future<TransferenciaInventario> createTransferencia({
    required int sucursalDestinoId,
    required List<Map<String, dynamic>> items,
    String? observaciones,
  }) =>
      _transferenciasApi.createTransferencia(
        sucursalDestinoId: sucursalDestinoId,
        items: items,
        observaciones: observaciones,
      );

  /// Envía una transferencia de inventario.
  Future<TransferenciaInventario> enviarTransferencia(
    String id, {
    required int sucursalOrigenId,
  }) =>
      _transferenciasApi.enviarTransferencia(
        id,
        sucursalOrigenId: sucursalOrigenId,
      );

  /// Recibe una transferencia de inventario.
  Future<TransferenciaInventario> recibirTransferencia(String id) =>
      _transferenciasApi.recibirTransferencia(id);

  /// Cancela una transferencia de inventario.
  Future<bool> cancelarTransferencia(String id) =>
      _transferenciasApi.cancelarTransferencia(id);

  /// Obtiene la comparación de stocks para una transferencia.
  Future<ComparacionTransferencia> compararTransferencia({
    required String id,
    required int sucursalOrigenId,
    bool useCache = false,
  }) =>
      _transferenciasApi.compararTransferencia(
        id: id,
        sucursalOrigenId: sucursalOrigenId,
        useCache: useCache,
      );

  /// Verifica si una transferencia puede ser comparada basado en su estado.
  bool puedeCompararTransferencia(String estadoCodigo) =>
      estadoCodigo.toUpperCase() == 'PEDIDO';

  /// Obtiene el mensaje de estado para la comparación de transferencias.
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

  /// Obtiene información de estilo según el estado de la transferencia.
  Map<String, dynamic> obtenerEstiloEstado(String estado) {
    Color backgroundColor;
    Color textColor;
    IconData iconData;
    String tooltipText;

    switch (estado.toUpperCase()) {
      case 'RECIBIDO':
        backgroundColor = const Color(0xFF2D8A3B).withValues(alpha: 0.15);
        textColor = AppTheme.successColor;
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
