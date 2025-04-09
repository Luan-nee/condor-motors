import 'package:condorsmotors/api/protected/sucursales.api.dart';
import 'package:condorsmotors/api/protected/transferencias.api.dart';
import 'package:condorsmotors/main.dart';
import 'package:condorsmotors/models/sucursal.model.dart' as sucursal_model;
import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:flutter/material.dart';

/// Provider para gestionar las transferencias de inventario desde la vista de administración
class TransferenciasProvider extends ChangeNotifier {
  final TransferenciasInventarioApi _transferenciasApi;
  final SucursalesApi _sucursalesApi = api.sucursales;

  List<TransferenciaInventario> _transferencias = [];
  List<sucursal_model.Sucursal> _sucursales = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'Todos';

  // Propiedades para filtrado avanzado
  String _searchQuery = '';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _ordenarPor = 'fecha';
  String _orden = 'desc';

  TransferenciasProvider(this._transferenciasApi) {
    // Cargar sucursales al inicializar
    cargarSucursales();
  }

  // Getters
  List<TransferenciaInventario> get transferencias => _transferencias;
  List<sucursal_model.Sucursal> get sucursales => _sucursales;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;
  DateTime? get fechaInicio => _fechaInicio;
  DateTime? get fechaFin => _fechaFin;
  String get ordenarPor => _ordenarPor;
  String get orden => _orden;

  // Lista de filtros disponibles
  final List<String> filters = [
    'Todos',
    'Pedido',
    'Enviado',
    'Recibido',
  ];

  /// Carga la lista de sucursales disponibles
  Future<void> cargarSucursales() async {
    try {
      _sucursales = await _sucursalesApi.getSucursales(forceRefresh: true);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar sucursales: $e');
    }
  }

  /// Obtiene una sucursal por su ID
  sucursal_model.Sucursal? obtenerSucursal(int sucursalId) {
    return _sucursales.firstWhere(
      (s) => int.parse(s.id) == sucursalId,
      orElse: () => sucursal_model.Sucursal(
        id: sucursalId.toString(),
        nombre: 'Sucursal no encontrada',
        sucursalCentral: false,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
      ),
    );
  }

  /// Carga la lista de transferencias aplicando los filtros especificados
  Future<void> cargarTransferencias({
    String? sucursalId,
    bool forceRefresh = false,
  }) async {
    _setLoading(true);

    try {
      String? estadoFiltro;
      if (_selectedFilter != 'Todos') {
        estadoFiltro = EstadoTransferencia.values
            .firstWhere(
              (e) => e.nombre == _selectedFilter,
              orElse: () => EstadoTransferencia.pedido,
            )
            .codigo;
      }

      final List<TransferenciaInventario> transferenciasData =
          await _transferenciasApi.getTransferencias(
        sucursalId: sucursalId,
        estado: estadoFiltro,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        sortBy: _ordenarPor,
        order: _orden,
        forceRefresh: forceRefresh,
      );

      _transferencias = transferenciasData;
      _errorMessage = null;
    } catch (e) {
      _setError('Error al cargar transferencias: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Obtiene los detalles de una transferencia específica
  Future<TransferenciaInventario> obtenerDetalleTransferencia(
    String id, {
    bool useCache = false,
  }) async {
    try {
      final TransferenciaInventario transferencia =
          await _transferenciasApi.getTransferencia(
        id,
        useCache: useCache,
      );
      return transferencia;
    } catch (e) {
      _setError('Error al obtener detalle de transferencia: $e');
      rethrow;
    }
  }

  /// Obtiene comparación de stocks entre sucursales
  Future<ComparacionTransferencia> obtenerComparacionTransferencia(
    String id,
    int sucursalOrigenId,
  ) async {
    try {
      return await _transferenciasApi.compararTransferencia(
        id: id,
        sucursalOrigenId: sucursalOrigenId,
        useCache: false,
      );
    } catch (e) {
      _setError('Error al obtener comparación de transferencia: $e');
      rethrow;
    }
  }

  /// Cambia el filtro seleccionado y recarga las transferencias
  Future<void> cambiarFiltro(String filtro) async {
    _selectedFilter = filtro;
    await cargarTransferencias();
  }

  /// Actualiza los filtros de búsqueda
  void actualizarFiltros({
    String? searchQuery,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? ordenarPor,
    String? orden,
  }) {
    bool cambios = false;

    if (searchQuery != null && searchQuery != _searchQuery) {
      _searchQuery = searchQuery;
      cambios = true;
    }
    if (fechaInicio != null && fechaInicio != _fechaInicio) {
      _fechaInicio = fechaInicio;
      cambios = true;
    }
    if (fechaFin != null && fechaFin != _fechaFin) {
      _fechaFin = fechaFin;
      cambios = true;
    }
    if (ordenarPor != null && ordenarPor != _ordenarPor) {
      _ordenarPor = ordenarPor;
      cambios = true;
    }
    if (orden != null && orden != _orden) {
      _orden = orden;
      cambios = true;
    }

    if (cambios) {
      notifyListeners();
    }
  }

  /// Restablece todos los filtros a sus valores por defecto
  void restablecerFiltros() {
    _searchQuery = '';
    _selectedFilter = 'Todos';
    _fechaInicio = null;
    _fechaFin = null;
    _ordenarPor = 'fecha';
    _orden = 'desc';
    notifyListeners();
  }

  /// Obtiene información de estilo según el estado de la transferencia
  Map<String, dynamic> obtenerEstiloEstado(String estado) {
    Color backgroundColor;
    Color textColor;
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

  // Helpers para manejar estados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
    debugPrint('Error: $message');
  }
}
