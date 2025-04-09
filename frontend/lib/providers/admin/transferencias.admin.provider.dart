import 'package:condorsmotors/api/protected/transferencias.api.dart';
import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:flutter/material.dart';

/// Provider para gestionar las transferencias de inventario
class TransferenciasProvider extends ChangeNotifier {
  final TransferenciasInventarioApi _api;
  List<TransferenciaInventario> _transferencias = <TransferenciaInventario>[];
  bool _cargando = false;
  String? _errorMensaje;

  TransferenciasProvider(this._api);

  // Getters
  List<TransferenciaInventario> get transferencias => _transferencias;
  bool get cargando => _cargando;
  String? get errorMensaje => _errorMensaje;

  /// Carga la lista de transferencias aplicando los filtros especificados
  Future<void> cargarTransferencias({
    String? sucursalId,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool forceRefresh = false,
  }) async {
    _cargando = true;
    _errorMensaje = null;
    notifyListeners();

    try {
      final List<TransferenciaInventario> transferencias =
          await _api.getTransferencias(
        sucursalId: sucursalId,
        estado: estado != 'Todos' ? estado?.toUpperCase() : null,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        forceRefresh: forceRefresh,
      );

      _transferencias = transferencias;
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _errorMensaje = 'Error al cargar las transferencias: $e';
      _cargando = false;
      notifyListeners();
    }
  }

  /// Obtiene los detalles de una transferencia específica por su ID
  Future<TransferenciaInventario> obtenerDetalleTransferencia(
    String id, {
    bool useCache = false,
  }) async {
    try {
      return await _api.getTransferencia(
        id,
        useCache: useCache,
      );
    } catch (e) {
      throw Exception('Error al cargar detalles de la transferencia: $e');
    }
  }

  /// Obtiene un mapa de los estados de transferencias disponibles
  Map<String, String> obtenerEstadosDetalle() {
    return Map.fromEntries(
      EstadoTransferencia.values.map(
        (estado) => MapEntry(estado.codigo, estado.nombre),
      ),
    );
  }

  /// Verifica si un estado corresponde a una transferencia completada
  bool esMovimientoCompletado(String estado) {
    return estado.toUpperCase() == EstadoTransferencia.recibido.codigo;
  }

  /// Verifica si un estado corresponde a una transferencia pendiente
  bool esMovimientoPendiente(String estado) {
    return estado.toUpperCase() == EstadoTransferencia.pedido.codigo;
  }

  /// Verifica si un estado corresponde a una transferencia en tránsito
  bool esMovimientoSolicitando(String estado) {
    return estado.toUpperCase() == EstadoTransferencia.enviado.codigo;
  }

  /// Obtiene información de estilo (colores, icono) según el estado de la transferencia
  Map<String, dynamic> obtenerEstiloEstado(String estado) {
    Color backgroundColor;
    Color textColor = Colors.white;
    IconData iconData;
    String tooltipText;

    switch (estado.toUpperCase()) {
      case 'RECIBIDO':
        backgroundColor = const Color(0xFF2D8A3B).withOpacity(0.15);
        textColor = const Color(0xFF4CAF50);
        iconData = Icons.check_circle;
        tooltipText = 'Transferencia completada';
        break;
      case 'PEDIDO':
        backgroundColor = const Color(0xFFFFA000).withOpacity(0.15);
        textColor = const Color(0xFFFFA000);
        iconData = Icons.history;
        tooltipText = 'En proceso';
        break;
      case 'ENVIADO':
        backgroundColor = const Color(0xFF009688).withOpacity(0.15);
        textColor = const Color(0xFF009688);
        iconData = Icons.local_shipping;
        tooltipText = 'En tránsito';
        break;
      default:
        backgroundColor = const Color(0xFF757575).withOpacity(0.15);
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
