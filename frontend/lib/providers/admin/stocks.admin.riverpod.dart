import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/stock.repository.dart';
import 'package:condorsmotors/utils/stock_utils.dart'; // Import StockStatus from here
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stocks.admin.riverpod.g.dart';

class StocksAdminState {
  final bool isLoadingSucursales;
  final bool isLoadingProductos;
  final List<Sucursal> sucursales;
  final Sucursal? selectedSucursal;
  final PaginatedResponse<Producto>? paginatedProductos;
  final String? errorMessage;
  final String searchQuery;
  final int currentPage;
  final int pageSize;
  final String sortBy;
  final String order;
  final StockStatus? filtroEstadoStock;
  final int userPreferredPageSize;

  StocksAdminState({
    this.isLoadingSucursales = false,
    this.isLoadingProductos = false,
    this.sucursales = const [],
    this.selectedSucursal,
    this.paginatedProductos,
    this.errorMessage,
    this.searchQuery = '',
    this.currentPage = 1,
    this.pageSize = 25,
    this.sortBy = 'nombre',
    this.order = 'desc',
    this.filtroEstadoStock,
    this.userPreferredPageSize = 25,
  });

  StocksAdminState copyWith({
    bool? isLoadingSucursales,
    bool? isLoadingProductos,
    List<Sucursal>? sucursales,
    Sucursal? selectedSucursal,
    PaginatedResponse<Producto>? paginatedProductos,
    String? errorMessage,
    String? searchQuery,
    int? currentPage,
    int? pageSize,
    String? sortBy,
    String? order,
    StockStatus? filtroEstadoStock,
    int? userPreferredPageSize,
    bool clearSelectedSucursal = false,
    bool clearFiltroEstadoStock = false,
  }) {
    return StocksAdminState(
      isLoadingSucursales: isLoadingSucursales ?? this.isLoadingSucursales,
      isLoadingProductos: isLoadingProductos ?? this.isLoadingProductos,
      sucursales: sucursales ?? this.sucursales,
      selectedSucursal: clearSelectedSucursal ? null : (selectedSucursal ?? this.selectedSucursal),
      paginatedProductos: paginatedProductos ?? this.paginatedProductos,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
      order: order ?? this.order,
      filtroEstadoStock: clearFiltroEstadoStock ? null : (filtroEstadoStock ?? this.filtroEstadoStock),
      userPreferredPageSize: userPreferredPageSize ?? this.userPreferredPageSize,
    );
  }
}

@riverpod
class StocksAdmin extends _$StocksAdmin {
  late final StockRepository _stockRepository;

  @override
  StocksAdminState build() {
    _stockRepository = StockRepository.instance;
    Future.microtask(cargarSucursales);
    return StocksAdminState();
  }

  Future<void> cargarSucursales() async {
    state = state.copyWith(isLoadingSucursales: true);
    try {
      final sucursales = await _stockRepository.getSucursales();
      state = state.copyWith(
        sucursales: sucursales,
        isLoadingSucursales: false,
      );
      if (sucursales.isNotEmpty && state.selectedSucursal == null) {
        final principal = sucursales.firstWhere(
          (s) => s.nombre.toLowerCase().contains('principal'),
          orElse: () => sucursales.first,
        );
        seleccionarSucursal(principal);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al cargar sucursales: $e',
        isLoadingSucursales: false,
      );
    }
  }

  void seleccionarSucursal(Sucursal sucursal) {
    state = state.copyWith(
      selectedSucursal: sucursal,
      currentPage: 1,
    );
    cargarProductos();
  }

  Future<void> cargarProductos() async {
    final sucursalId = state.selectedSucursal?.id.toString();
    if (sucursalId == null) {
      return;
    }

    state = state.copyWith(isLoadingProductos: true);
    try {
      // Usamos la preferencia guardada del usuario como base para la petición
      int requestPageSize = state.userPreferredPageSize;

      dynamic stockFilter;
      bool? stockBajoFilter;

      if (state.filtroEstadoStock != null) {
        switch (state.filtroEstadoStock!) {
          case StockStatus.stockBajo:
            stockBajoFilter = true;
          case StockStatus.agotado:
            stockFilter = {'value': 0, 'filterType': 'eq'};
          case StockStatus.disponible:
            stockFilter = {'value': 1, 'filterType': 'gte'};
        }
      }

      final response = await _stockRepository.getProductos(
        sucursalId: sucursalId,
        page: state.currentPage,
        pageSize: requestPageSize,
        sortBy: state.sortBy,
        order: state.order,
        search: state.searchQuery.length >= 3 ? state.searchQuery : null,
        stock: stockFilter,
        stockBajo: stockBajoFilter,
      );

      // Ajuste inteligente visual del tamaño de página si hay pocos elementos
      int actualPageSize = requestPageSize;
      if (response.totalItems > 0 && response.totalItems < actualPageSize) {
        actualPageSize = response.totalItems;
      }

      state = state.copyWith(
        paginatedProductos: response.copyWithPaginacion(
          response.paginacion.copyWith(pageSize: actualPageSize),
        ),
        pageSize: actualPageSize,
        isLoadingProductos: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al cargar productos: $e',
        isLoadingProductos: false,
      );
    }
  }

  void cambiarPagina(int pagina) {
    state = state.copyWith(currentPage: pagina);
    cargarProductos();
  }

  void cambiarTamanioPagina(int tamanio) {
    state = state.copyWith(
      userPreferredPageSize: tamanio,
      pageSize: tamanio, 
      currentPage: 1
    );
    cargarProductos();
  }

  void ordenarPor(String campo) {
    if (state.sortBy == campo) {
      state = state.copyWith(order: state.order == 'asc' ? 'desc' : 'asc', currentPage: 1);
    } else {
      state = state.copyWith(sortBy: campo, order: 'desc', currentPage: 1);
    }
    cargarProductos();
  }

  void filtrarPorEstadoStock(StockStatus? estado) {
    if (state.filtroEstadoStock == estado) {
      state = state.copyWith(clearFiltroEstadoStock: true, currentPage: 1);
    } else {
      state = state.copyWith(filtroEstadoStock: estado, currentPage: 1);
    }
    cargarProductos();
  }

  void actualizarBusqueda(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
    if (query.length >= 3 || query.isEmpty) {
      cargarProductos();
    }
  }

  void limpiarFiltros() {
    state = state.copyWith(
      searchQuery: '',
      clearFiltroEstadoStock: true,
      currentPage: 1,
    );
    cargarProductos();
  }

  Future<void> recargarDatos() async {
    if (state.selectedSucursal != null) {
      _stockRepository.invalidateCache(state.selectedSucursal!.id.toString());
    }
    await cargarSucursales();
    await cargarProductos();
  }

  void limpiarError() {
    state = state.copyWith();
  }
}
