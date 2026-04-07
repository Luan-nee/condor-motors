import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/models/ventas.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ventas.admin.riverpod.g.dart';

class VentasAdminState {
  final bool isLoadingVentas;
  final bool isLoadingSucursales;
  final bool isActionLoading;
  final List<Sucursal> sucursales;
  final Sucursal? selectedSucursal;
  final List<Venta> ventas;
  final Paginacion paginacion;
  final String searchQuery;
  final String sortBy;
  final String order;
  final int itemsPerPage;
  final int userPreferredPageSize;
  final String? errorMessage;
  final String? successMessage;

  VentasAdminState({
    this.isLoadingVentas = false,
    this.isLoadingSucursales = false,
    this.isActionLoading = false,
    this.sucursales = const [],
    this.selectedSucursal,
    this.ventas = const [],
    this.paginacion = Paginacion.emptyPagination,
    this.searchQuery = '',
    this.sortBy = 'fechaCreacion',
    this.order = 'desc',
    this.itemsPerPage = 25,
    this.userPreferredPageSize = 25,
    this.errorMessage,
    this.successMessage,
  });

  VentasAdminState copyWith({
    bool? isLoadingVentas,
    bool? isLoadingSucursales,
    bool? isActionLoading,
    List<Sucursal>? sucursales,
    Sucursal? selectedSucursal,
    List<Venta>? ventas,
    Paginacion? paginacion,
    String? searchQuery,
    String? sortBy,
    String? order,
    int? itemsPerPage,
    int? userPreferredPageSize,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return VentasAdminState(
      isLoadingVentas: isLoadingVentas ?? this.isLoadingVentas,
      isLoadingSucursales: isLoadingSucursales ?? this.isLoadingSucursales,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      sucursales: sucursales ?? this.sucursales,
      selectedSucursal: selectedSucursal ?? this.selectedSucursal,
      ventas: ventas ?? this.ventas,
      paginacion: paginacion ?? this.paginacion,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      order: order ?? this.order,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      userPreferredPageSize: userPreferredPageSize ?? this.userPreferredPageSize,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

@riverpod
class VentasAdmin extends _$VentasAdmin {
  late final VentaRepository _ventaRepository;
  late final SucursalRepository _sucursalRepository;

  @override
  VentasAdminState build() {
    _ventaRepository = VentaRepository.instance;
    _sucursalRepository = SucursalRepository.instance;

    // Inicializar cargando sucursales
    Future.microtask(inicializar);

    return VentasAdminState();
  }

  Future<void> inicializar() async {
    await cargarSucursales();
    
    // Seleccionar sucursal principal o primera por defecto
    if (state.sucursales.isNotEmpty && state.selectedSucursal == null) {
      final principal = state.sucursales.firstWhere(
        (s) => s.nombre.toLowerCase().contains('principal'),
        orElse: () => state.sucursales.first,
      );
      await seleccionarSucursal(principal);
    }
  }

  Future<void> cargarSucursales() async {
    state = state.copyWith(isLoadingSucursales: true, clearError: true);
    try {
      final sucursales = await _sucursalRepository.getSucursales();
      state = state.copyWith(
        sucursales: sucursales..sort((a, b) => a.nombre.compareTo(b.nombre)),
        isLoadingSucursales: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al cargar sucursales: $e',
        isLoadingSucursales: false,
      );
    }
  }

  Future<void> seleccionarSucursal(Sucursal sucursal) async {
    if (state.selectedSucursal?.id != sucursal.id) {
      state = state.copyWith(
        selectedSucursal: sucursal,
        paginacion: state.paginacion.copyWith(currentPage: 1),
      );
      await cargarVentas();
    }
  }

  Future<void> cargarVentas({bool forceRefresh = true}) async {
    if (state.selectedSucursal == null) {
      return;
    }

    state = state.copyWith(isLoadingVentas: true, clearError: true, clearSuccess: true);
    try {
      // Usamos la preferencia guardada del usuario como base para la petición
      int requestPageSize = state.userPreferredPageSize;

      final response = await _ventaRepository.getVentas(
        sucursalId: state.selectedSucursal!.id,
        page: state.paginacion.currentPage,
        pageSize: requestPageSize,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        sortBy: state.sortBy,
        order: state.order,
        forceRefresh: forceRefresh,
      );
      
      List<Venta> ventasList = [];
      if (response.containsKey('data') && response['data'] is List) {
        ventasList = (response['data'] as List)
            .map((item) => item is Venta ? item : Venta.fromJson(item))
            .toList();
      }

      int totalItems = 0;
      if (response.containsKey('pagination')) {
        totalItems = response['pagination']['totalItems'] ?? ventasList.length;
      } else if (response.containsKey('total')) {
        totalItems = response['total'];
      } else {
        totalItems = ventasList.length;
      }
      
      // Ajuste inteligente del tamaño de página si hay pocos elementos
      int actualPageSize = requestPageSize;
      if (totalItems > 0 && totalItems < actualPageSize) {
        actualPageSize = totalItems;
      }

      state = state.copyWith(
        ventas: ventasList,
        itemsPerPage: actualPageSize,
        paginacion: Paginacion.fromParams(
          totalItems: totalItems,
          pageSize: actualPageSize,
          currentPage: state.paginacion.currentPage,
        ),
        isLoadingVentas: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al cargar ventas: $e',
        isLoadingVentas: false,
      );
    }
  }

  void actualizarBusqueda(String query) {
    state = state.copyWith(
      searchQuery: query, 
      paginacion: state.paginacion.copyWith(currentPage: 1)
    );
    cargarVentas();
  }

  void cambiarOrden(String sortBy, String order) {
    state = state.copyWith(
      sortBy: sortBy,
      order: order,
      paginacion: state.paginacion.copyWith(currentPage: 1)
    );
    cargarVentas();
  }

  void cambiarPagina(int pagina) {
    state = state.copyWith(
      paginacion: state.paginacion.copyWith(currentPage: pagina)
    );
    cargarVentas();
  }

  void cambiarTamanioPagina(int tamanio) {
    state = state.copyWith(
      userPreferredPageSize: tamanio,
      itemsPerPage: tamanio,
      paginacion: state.paginacion.copyWith(currentPage: 1)
    );
    cargarVentas();
  }

  Future<void> declararVenta(String ventaId, {bool enviarCliente = false}) async {
    if (state.selectedSucursal == null) {
      return;
    }

    state = state.copyWith(isActionLoading: true, clearError: true, clearSuccess: true);
    try {
      final result = await _ventaRepository.declararVenta(
        ventaId,
        sucursalId: state.selectedSucursal!.id,
        enviarCliente: enviarCliente,
      );

      if (result['status'] == 'success') {
        state = state.copyWith(
          successMessage: 'Venta declarada exitosamente',
          isActionLoading: false,
        );
        await cargarVentas();
      } else {
        state = state.copyWith(
          errorMessage: result['message'] ?? 'Error al declarar la venta',
          isActionLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al declarar venta: $e',
        isActionLoading: false,
      );
    }
  }
}
