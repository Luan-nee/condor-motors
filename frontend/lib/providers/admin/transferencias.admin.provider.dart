import 'package:condorsmotors/models/sucursal.model.dart' as sucursal_model;
import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/providers/paginacion.provider.dart';
import 'package:condorsmotors/repositories/sucursal.repository.dart';
// Importar los repositorios
import 'package:condorsmotors/repositories/transferencia.repository.dart';
import 'package:flutter/material.dart';

/// Provider para gestionar las transferencias de inventario desde la vista de administración
class TransferenciasProvider extends ChangeNotifier {
  // Instancias de repositorios
  final TransferenciaRepository _transferenciaRepository =
      TransferenciaRepository.instance;
  final SucursalRepository _sucursalRepository = SucursalRepository.instance;

  // API legacy que se seguirá usando hasta la transición completa

  final PaginacionProvider paginacionProvider = PaginacionProvider();

  List<TransferenciaInventario> _transferencias = [];
  List<sucursal_model.Sucursal> _sucursales = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'Todos';
  // Añadir una nueva propiedad para almacenar el detalle de transferencia actual
  TransferenciaInventario? _detalleTransferenciaActual;

  // Propiedades para filtrado avanzado
  String _searchQuery = '';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _ordenarPor = 'fechaCreacion';
  String _orden = 'desc';

  TransferenciasProvider() {
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
  // Añadir getter para el detalle de transferencia
  TransferenciaInventario? get detalleTransferenciaActual =>
      _detalleTransferenciaActual;

  /// Recarga todos los datos forzando actualización desde el servidor
  Future<void> recargarDatos() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      debugPrint('Forzando recarga de datos de transferencias desde la API...');
      await cargarSucursales();
      await cargarTransferencias(forceRefresh: true);
      debugPrint(
          'Datos de transferencias recargados exitosamente desde la API');
    } catch (e) {
      debugPrint('Error al recargar datos de transferencias: $e');
      _setError('Error al recargar datos: $e');
    } finally {
      _setLoading(false);
    }
  }

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
      _sucursales = await _sucursalRepository.getSucursales();
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

      final paginatedResponse =
          await _transferenciaRepository.getTransferencias(
        sucursalId: sucursalId,
        estado: estadoFiltro,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        sortBy: paginacionProvider.ordenarPor ?? 'fechaCreacion',
        order: paginacionProvider.orden,
        page: paginacionProvider.paginacion.currentPage,
        pageSize: paginacionProvider.itemsPerPage,
        forceRefresh: forceRefresh,
      );

      _transferencias = paginatedResponse.items;
      paginacionProvider.actualizarDesdeResponse(paginatedResponse);
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
          await _transferenciaRepository.getTransferencia(
        id,
        useCache: useCache,
      );
      return transferencia;
    } catch (e) {
      _setError('Error al obtener detalle de transferencia: $e');
      rethrow;
    }
  }

  /// Carga y almacena los detalles de una transferencia
  Future<void> cargarDetalleTransferencia(String id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      debugPrint('Cargando detalles de la transferencia #$id');
      final TransferenciaInventario transferencia =
          await _transferenciaRepository.getTransferencia(id);

      _detalleTransferenciaActual = transferencia;
      debugPrint('Detalles cargados correctamente');
      debugPrint('Productos: ${transferencia.productos?.length ?? 0}');
    } catch (e) {
      debugPrint('Error al cargar detalle de transferencia: $e');
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Verifica si una transferencia puede ser comparada basado en su estado
  bool puedeCompararTransferencia(String estadoCodigo) {
    return _transferenciaRepository.puedeCompararTransferencia(estadoCodigo);
  }

  /// Obtiene el mensaje de estado para la comparación de transferencias
  String obtenerMensajeComparacion(String estadoCodigo) {
    return _transferenciaRepository.obtenerMensajeComparacion(estadoCodigo);
  }

  /// Obtiene comparación de stocks entre sucursales
  Future<ComparacionTransferencia> obtenerComparacionTransferencia(
    String id,
    int sucursalOrigenId,
  ) async {
    try {
      // Primero obtenemos la transferencia para verificar su estado
      final transferencia =
          await obtenerDetalleTransferencia(id, useCache: true);

      if (!puedeCompararTransferencia(transferencia.estado.codigo)) {
        throw Exception(
            'No se puede comparar una transferencia en estado ${transferencia.estado.nombre}');
      }

      return await _transferenciaRepository.compararTransferencia(
        id: id,
        sucursalOrigenId: sucursalOrigenId,
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
    _ordenarPor = 'fechaCreacion';
    _orden = 'desc';
    notifyListeners();
  }

  /// Obtiene información de estilo según el estado de la transferencia
  Map<String, dynamic> obtenerEstiloEstado(String estado) {
    return _transferenciaRepository.obtenerEstiloEstado(estado);
  }

  /// Cambia la página actual y recarga los datos
  Future<void> cambiarPagina(int nuevaPagina) async {
    paginacionProvider.cambiarPagina(nuevaPagina);
    await cargarTransferencias();
  }

  /// Cambia el tamaño de página y recarga los datos
  Future<void> cambiarTamanoPagina(int nuevoTamano) async {
    paginacionProvider.cambiarItemsPorPagina(nuevoTamano);
    await cargarTransferencias();
  }

  /// Cambia el orden de los resultados y recarga los datos
  Future<void> cambiarOrden(String nuevoOrden) async {
    paginacionProvider.cambiarOrden(nuevoOrden);
    await cargarTransferencias();
  }

  /// Cambia el campo de ordenación y recarga los datos
  Future<void> cambiarOrdenarPor(String? nuevoOrdenarPor) async {
    paginacionProvider.cambiarOrdenarPor(nuevoOrdenarPor);
    await cargarTransferencias();
  }

  /// Completa el envío de una transferencia después de la comparación
  Future<void> completarEnvioTransferencia(
    String id,
    int sucursalOrigenId,
  ) async {
    try {
      _setLoading(true);

      // Primero verificamos que la transferencia esté en estado PEDIDO
      final transferencia =
          await obtenerDetalleTransferencia(id, useCache: true);
      if (!puedeCompararTransferencia(transferencia.estado.codigo)) {
        throw Exception(
            'No se puede completar el envío de una transferencia en estado ${transferencia.estado.nombre}');
      }

      // Obtenemos la comparación para validar que todo esté correcto
      final comparacion = await _transferenciaRepository.compararTransferencia(
        id: id,
        sucursalOrigenId: sucursalOrigenId,
      );

      // Validamos que todos los productos sean procesables
      if (!comparacion.todosProductosProcesables) {
        throw Exception(
            'No se puede completar el envío porque hay productos sin stock suficiente');
      }

      // Realizamos el envío
      await _transferenciaRepository.enviarTransferencia(
        id,
        sucursalOrigenId: sucursalOrigenId,
      );

      // Recargamos los datos
      await cargarTransferencias(forceRefresh: true);

      debugPrint('✅ Transferencia #$id enviada exitosamente');
    } catch (e) {
      debugPrint('❌ Error al completar envío de transferencia: $e');
      _setError('Error al completar envío: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
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
