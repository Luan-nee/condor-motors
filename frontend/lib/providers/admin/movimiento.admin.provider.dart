import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/movimiento.model.dart';
import 'package:flutter/material.dart';

/// Provider para gestionar los movimientos de inventario
class MovimientoProvider extends ChangeNotifier {
  List<Movimiento> _movimientos = <Movimiento>[];
  bool _cargando = false;
  String? _errorMensaje;

  // Getters
  List<Movimiento> get movimientos => _movimientos;
  bool get cargando => _cargando;
  String? get errorMensaje => _errorMensaje;

  /// Carga la lista de movimientos aplicando los filtros especificados
  Future<void> cargarMovimientos({
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
      final List<Movimiento> movimientos = await api.movimientos.getMovimientos(
        sucursalId: sucursalId,
        estado: estado != 'Todos' ? estado?.toUpperCase() : null,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        forceRefresh: forceRefresh,
      );

      _movimientos = movimientos;
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _errorMensaje = 'Error al cargar las transferencias: $e';
      _cargando = false;
      notifyListeners();
    }
  }

  /// Obtiene los detalles de un movimiento específico por su ID
  Future<Movimiento> obtenerDetalleMovimiento(String id,
      {bool useCache = false}) async {
    try {
      final Movimiento detalleMovimiento = await api.movimientos.getMovimiento(
        id,
        useCache: useCache,
      );

      return detalleMovimiento;
    } catch (e) {
      // En caso de error, propagamos la excepción para que sea manejada por el widget
      throw Exception('Error al cargar detalles del movimiento: $e');
    }
  }

  /// Método para obtener un mapa de los estados de movimientos y sus descripciones
  Map<String, String> obtenerEstadosDetalle() {
    return MovimientosApi.estadosDetalle;
  }

  /// Verifica si un estado corresponde a un movimiento completado
  bool esMovimientoCompletado(String estado) {
    return estado.toUpperCase() == 'RECIBIDO';
  }

  /// Verifica si un estado corresponde a un movimiento en proceso
  bool esMovimientoPendiente(String estado) {
    return estado.toUpperCase() == 'PENDIENTE';
  }

  /// Verifica si un estado corresponde a un movimiento solicitado/entregado
  bool esMovimientoSolicitando(String estado) {
    return estado.toUpperCase() == 'SOLICITANDO';
  }

  /// Obtiene información de estilo (colores, icono) según el estado del movimiento
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
        tooltipText = 'Movimiento completado';
        break;
      case 'PENDIENTE':
        backgroundColor = const Color(0xFFFFA000).withOpacity(0.15);
        textColor = const Color(0xFFFFA000);
        iconData = Icons.history;
        tooltipText = 'En proceso';
        break;
      case 'SOLICITANDO':
        backgroundColor = const Color(0xFF009688).withOpacity(0.15);
        textColor = const Color(0xFF009688);
        iconData = Icons.local_shipping;
        tooltipText = 'Entregado';
        break;
      default:
        backgroundColor = const Color(0xFF757575).withOpacity(0.15);
        textColor = const Color(0xFF9E9E9E);
        iconData = Icons.hourglass_empty;
        tooltipText = 'Estado sin definir';
    }

    return {
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'iconData': iconData,
      'tooltipText': tooltipText,
      'estadoDisplay': MovimientosApi.estadosDetalle[estado] ?? estado,
    };
  }
}
