import 'package:condorsmotors/models/categoria.model.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/categoria.repository.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:condorsmotors/repositories/sucursal.repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'productos.admin.riverpod.g.dart';

class ProductosAdminState {
  final bool isLoading;
  final bool isLoadingSucursales;
  final bool isLoadingCategorias;
  final List<Sucursal> sucursales;
  final Sucursal? selectedSucursal;
  final List<Producto> productos;
  final List<Producto> productosFiltrados;
  final List<Categoria> categorias;
  final String? selectedCategoryId;
  final String? filtroEstadoStock;
  final String searchQuery;
  final String sortBy;
  final String order;
  final int currentPage;
  final int pageSize;
  final Paginacion paginacion;
  final String? errorMessage;

  ProductosAdminState({
    this.isLoading = false,
    this.isLoadingSucursales = true,
    this.isLoadingCategorias = false,
    this.sucursales = const [],
    this.selectedSucursal,
    this.productos = const [],
    this.productosFiltrados = const [],
    this.categorias = const [],
    this.selectedCategoryId,
    this.filtroEstadoStock,
    this.searchQuery = '',
    this.sortBy = 'nombre',
    this.order = 'asc',
    this.currentPage = 1,
    this.pageSize = 100,
    this.paginacion = Paginacion.emptyPagination,
    this.errorMessage,
  });

  ProductosAdminState copyWith({
    bool? isLoading,
    bool? isLoadingSucursales,
    bool? isLoadingCategorias,
    List<Sucursal>? sucursales,
    Sucursal? selectedSucursal,
    List<Producto>? productos,
    List<Producto>? productosFiltrados,
    List<Categoria>? categorias,
    String? selectedCategoryId,
    bool clearCategory = false,
    String? filtroEstadoStock,
    bool clearFiltroEstadoStock = false,
    String? searchQuery,
    String? sortBy,
    String? order,
    int? currentPage,
    int? pageSize,
    Paginacion? paginacion,
    String? errorMessage,
  }) {
    return ProductosAdminState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingSucursales: isLoadingSucursales ?? this.isLoadingSucursales,
      isLoadingCategorias: isLoadingCategorias ?? this.isLoadingCategorias,
      sucursales: sucursales ?? this.sucursales,
      selectedSucursal: selectedSucursal ?? this.selectedSucursal,
      productos: productos ?? this.productos,
      productosFiltrados: productosFiltrados ?? this.productosFiltrados,
      categorias: categorias ?? this.categorias,
      selectedCategoryId:
          clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      filtroEstadoStock: clearFiltroEstadoStock ? null : (filtroEstadoStock ?? this.filtroEstadoStock),
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      order: order ?? this.order,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      paginacion: paginacion ?? this.paginacion,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

@riverpod
class ProductosAdmin extends _$ProductosAdmin {
  late final ProductoRepository _productoRepository;
  late final CategoriaRepository _categoriaRepository;
  late final SucursalRepository _sucursalRepository;

  @override
  ProductosAdminState build() {
    _productoRepository = ProductoRepository.instance;
    _categoriaRepository = CategoriaRepository.instance;
    _sucursalRepository = SucursalRepository.instance;

    // Inicializar cargando sucursales y categorías
    Future.microtask(inicializar);

    return ProductosAdminState();
  }

  Future<void> inicializar() async {
    await Future.wait([
      cargarSucursales(),
      cargarCategorias(),
    ]);

    // Seleccionar sucursal principal por defecto
    if (state.sucursales.isNotEmpty) {
      final principal = state.sucursales.firstWhere(
        (s) => s.nombre.toLowerCase().contains('principal'),
        orElse: () => state.sucursales.first,
      );
      await seleccionarSucursal(principal);
    }
  }

  Future<void> cargarSucursales() async {
    state = state.copyWith(isLoadingSucursales: true);
    try {
      final sucursales = await _sucursalRepository.getSucursales();
      state = state.copyWith(
        sucursales: sucursales,
        isLoadingSucursales: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al cargar sucursales: $e',
        isLoadingSucursales: false,
      );
    }
  }

  Future<void> cargarCategorias() async {
    state = state.copyWith(isLoadingCategorias: true);
    try {
      final categorias = await _categoriaRepository.getCategorias();
      state = state.copyWith(
        categorias: categorias,
        isLoadingCategorias: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al cargar categorías: $e',
        isLoadingCategorias: false,
      );
    }
  }

  Future<void> seleccionarSucursal(Sucursal sucursal) async {
    if (state.selectedSucursal?.id != sucursal.id) {
      state = state.copyWith(
        selectedSucursal: sucursal,
        currentPage: 1,
      );
      await cargarProductos();
    }
  }

  Future<void> cargarProductos({bool forceRefresh = false}) async {
    if (state.selectedSucursal == null) {
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final response = await _productoRepository.getProductos(
        sucursalId: state.selectedSucursal!.id.toString(),
        page: state.currentPage,
        pageSize: state.pageSize,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        sortBy: state.sortBy,
        order: state.order,
        filter: state.selectedCategoryId != null ? 'categoriaId' : null,
        filterValue: state.selectedCategoryId,
        filterType: state.selectedCategoryId != null ? 'eq' : null,
        stockBajo: state.filtroEstadoStock == 'stockBajo' ? true : null,
        stock: state.filtroEstadoStock == 'agotados' 
            ? {'value': 0, 'filterType': 'eq'}
            : (state.filtroEstadoStock == 'disponibles' ? {'value': 1, 'filterType': 'gte'} : null),
        forceRefresh: forceRefresh,
      );

      state = state.copyWith(
        productos: response.items,
        productosFiltrados: response.items,
        paginacion: Paginacion.fromParams(
          totalItems: response.totalItems,
          pageSize: state.pageSize,
          currentPage: response.currentPage,
        ),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al cargar productos: $e',
        isLoading: false,
      );
    }
  }

  void actualizarBusqueda(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
    cargarProductos();
  }

  void actualizarCategoria(String? categoryId) {
    // Manejar el caso 'all' viniendo desde el componente UI
    final bool isAll = categoryId == null || categoryId == 'all';
    
    state = state.copyWith(
      selectedCategoryId: isAll ? null : categoryId,
      clearCategory: isAll,
      currentPage: 1,
    );
    cargarProductos(forceRefresh: true);
  }

  void filtrarPorEstadoStock(String? filtro) {
    state = state.copyWith(
      filtroEstadoStock: filtro,
      clearFiltroEstadoStock: filtro == null || filtro == 'todos',
      currentPage: 1,
    );
    cargarProductos(forceRefresh: true);
  }

  void cambiarPagina(int pagina) {
    state = state.copyWith(currentPage: pagina);
    cargarProductos();
  }

  void cambiarTamanioPagina(int tamanio) {
    state = state.copyWith(pageSize: tamanio, currentPage: 1);
    cargarProductos();
  }

  void ordenarPor(String campo) {
    state = state.copyWith(sortBy: campo);
    cargarProductos();
  }

  Future<void> habilitarProducto(int productoId, Map<String, dynamic> datos) async {
    if (state.selectedSucursal == null) {
      return;
    }
    
    try {
      await _productoRepository.addProducto(
        sucursalId: state.selectedSucursal!.id.toString(),
        productoId: productoId,
        productoData: datos,
      );
      _productoRepository.invalidateCache(state.selectedSucursal!.id.toString());
      await cargarProductos(forceRefresh: true);
    } catch (e) {
      rethrow;
    }
  }
}
