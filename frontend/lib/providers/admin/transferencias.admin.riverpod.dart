import 'dart:async';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart' as sucursal_model;
import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/repositories/sucursal.repository.dart';
import 'package:condorsmotors/repositories/transferencia.repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transferencias.admin.riverpod.g.dart';

class TransferenciasAdminState {
  final List<TransferenciaInventario> transferencias;
  final List<sucursal_model.Sucursal> sucursales;
  final bool isLoading;
  final String? errorMessage;
  final String selectedFilter;
  final String searchQuery;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String sortBy;
  final String order;
  final int currentPage;
  final int pageSize;
  final Paginacion paginacion;
  final TransferenciaInventario? detalleTransferenciaActual;

  TransferenciasAdminState({
    this.transferencias = const [],
    this.sucursales = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedFilter = 'Todos',
    this.searchQuery = '',
    this.fechaInicio,
    this.fechaFin,
    this.sortBy = 'fechaCreacion',
    this.order = 'desc',
    this.currentPage = 1,
    this.pageSize = 10,
    this.paginacion = Paginacion.emptyPagination,
    this.detalleTransferenciaActual,
  });

  TransferenciasAdminState copyWith({
    List<TransferenciaInventario>? transferencias,
    List<sucursal_model.Sucursal>? sucursales,
    bool? isLoading,
    String? errorMessage,
    String? selectedFilter,
    String? searchQuery,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? sortBy,
    String? order,
    int? currentPage,
    int? pageSize,
    Paginacion? paginacion,
    TransferenciaInventario? detalleTransferenciaActual,
  }) {
    return TransferenciasAdminState(
      transferencias: transferencias ?? this.transferencias,
      sucursales: sucursales ?? this.sucursales,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      sortBy: sortBy ?? this.sortBy,
      order: order ?? this.order,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      paginacion: paginacion ?? this.paginacion,
      detalleTransferenciaActual:
          detalleTransferenciaActual ?? this.detalleTransferenciaActual,
    );
  }
}

@riverpod
class TransferenciasAdmin extends _$TransferenciasAdmin {
  late final TransferenciaRepository _transferenciaRepository;
  late final SucursalRepository _sucursalRepository;

  @override
  TransferenciasAdminState build() {
    _transferenciaRepository = TransferenciaRepository.instance;
    _sucursalRepository = SucursalRepository.instance;
    
    // Cargar datos iniciales
    // Nota: rpod no debería llamar async en build si queremos que sea reactivo de forma simple,
    // pero aquí seguiremos el patrón de inicialización.
    Future.microtask(inicializar);
    
    return TransferenciasAdminState();
  }

  Future<void> inicializar() async {
    await cargarSucursales();
    await cargarTransferencias();
  }

  Future<void> recargarDatos() async {
    state = state.copyWith(isLoading: true);
    try {
      await cargarSucursales();
      await cargarTransferencias(forceRefresh: true);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al recargar datos: $e', isLoading: false);
    }
  }

  Future<void> cargarSucursales() async {
    try {
      final sucursales = await _sucursalRepository.getSucursales();
      state = state.copyWith(sucursales: sucursales);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al cargar sucursales: $e');
    }
  }

  sucursal_model.Sucursal? obtenerSucursal(int sucursalId) {
    try {
      return state.sucursales.firstWhere(
        (s) => int.parse(s.id) == sucursalId,
      );
    } catch (_) {
      return sucursal_model.Sucursal(
        id: sucursalId.toString(),
        nombre: 'Sucursal no encontrada',
        sucursalCentral: false,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
      );
    }
  }

  Future<void> cargarTransferencias({
    String? sucursalId,
    bool forceRefresh = false,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true);
    }

    try {
      String? estadoFiltro;
      if (state.selectedFilter != 'Todos') {
        estadoFiltro = EstadoTransferencia.values
            .firstWhere(
              (e) => e.nombre == state.selectedFilter,
              orElse: () => EstadoTransferencia.pedido,
            )
            .codigo;
      }

      final paginatedResponse = await _transferenciaRepository.getTransferencias(
        sucursalId: sucursalId,
        estado: estadoFiltro,
        fechaInicio: state.fechaInicio,
        fechaFin: state.fechaFin,
        sortBy: state.sortBy,
        order: state.order,
        page: state.currentPage,
        pageSize: state.pageSize,
        forceRefresh: forceRefresh,
      );

      state = state.copyWith(
        transferencias: paginatedResponse.items,
        paginacion: paginatedResponse.paginacion,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al cargar transferencias: $e',
        isLoading: false,
      );
    }
  }

  Future<void> cargarDetalleTransferencia(String id) async {
    state = state.copyWith(isLoading: true);

    try {
      final transferencia = await _transferenciaRepository.getTransferencia(id);
      state = state.copyWith(
        detalleTransferenciaActual: transferencia,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  bool puedeCompararTransferencia(String estadoCodigo) {
    return _transferenciaRepository.puedeCompararTransferencia(estadoCodigo);
  }

  String obtenerMensajeComparacion(String estadoCodigo) {
    return _transferenciaRepository.obtenerMensajeComparacion(estadoCodigo);
  }

  Future<ComparacionTransferencia> obtenerComparacionTransferencia(
    String id,
    int sucursalOrigenId,
  ) async {
    try {
      final transferencia = await _transferenciaRepository.getTransferencia(id);

      if (!puedeCompararTransferencia(transferencia.estado.codigo)) {
        throw Exception(
            'No se puede comparar una transferencia en estado ${transferencia.estado.nombre}');
      }

      return await _transferenciaRepository.compararTransferencia(
        id: id,
        sucursalOrigenId: sucursalOrigenId,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al obtener comparación: $e');
      rethrow;
    }
  }

  Future<void> cambiarFiltro(String filtro) async {
    state = state.copyWith(selectedFilter: filtro, currentPage: 1);
    await cargarTransferencias();
  }

  void actualizarFiltros({
    String? searchQuery,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? ordenarPor,
    String? orden,
  }) {
    state = state.copyWith(
      searchQuery: searchQuery ?? state.searchQuery,
      fechaInicio: fechaInicio ?? state.fechaInicio,
      fechaFin: fechaFin ?? state.fechaFin,
      sortBy: ordenarPor ?? state.sortBy,
      order: orden ?? state.order,
    );
  }

  void restablecerFiltros() {
    state = state.copyWith(
      searchQuery: '',
      selectedFilter: 'Todos',
      sortBy: 'fechaCreacion',
      order: 'desc',
      currentPage: 1,
    );
    cargarTransferencias();
  }

  Map<String, dynamic> obtenerEstiloEstado(String estado) {
    return _transferenciaRepository.obtenerEstiloEstado(estado);
  }

  Future<void> cambiarPagina(int nuevaPagina) async {
    if (nuevaPagina < 1 || nuevaPagina > state.paginacion.totalPages) {
      return;
    }

    state = state.copyWith(currentPage: nuevaPagina);
    await cargarTransferencias(showLoading: false);
  }

  Future<void> cambiarTamanoPagina(int nuevoTamano) async {
    if (nuevoTamano < 1 || nuevoTamano > 200) {
      return;
    }

    state = state.copyWith(pageSize: nuevoTamano, currentPage: 1);
    await cargarTransferencias(showLoading: false);
  }

  Future<void> cambiarOrden(String nuevoOrden) async {
    if (nuevoOrden != 'asc' && nuevoOrden != 'desc') {
      return;
    }

    state = state.copyWith(order: nuevoOrden);
    await cargarTransferencias(showLoading: false);
  }

  Future<void> cambiarOrdenarPor(String? nuevoOrdenarPor) async {
    final sort = nuevoOrdenarPor ?? 'fechaCreacion';
    if (sort == state.sortBy) {
      return;
    }

    state = state.copyWith(sortBy: sort, currentPage: 1);
    await cargarTransferencias(showLoading: false);
  }

  Future<void> completarEnvioTransferencia(
    String id,
    int sucursalOrigenId,
  ) async {
    try {
      state = state.copyWith(isLoading: true);

      final transferencia = await _transferenciaRepository.getTransferencia(id);
      if (!puedeCompararTransferencia(transferencia.estado.codigo)) {
        throw Exception(
            'No se puede completar el envío de una transferencia en estado ${transferencia.estado.nombre}');
      }

      final comparacion = await _transferenciaRepository.compararTransferencia(
        id: id,
        sucursalOrigenId: sucursalOrigenId,
      );

      if (!comparacion.todosProductosProcesables) {
        throw Exception(
            'No se puede completar el envío porque hay productos sin stock suficiente');
      }

      await _transferenciaRepository.enviarTransferencia(
        id,
        sucursalOrigenId: sucursalOrigenId,
      );

      await cargarTransferencias(forceRefresh: true);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al completar envío: $e',
        isLoading: false,
      );
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void limpiarErrores() {
    state = state.copyWith();
  }
}
