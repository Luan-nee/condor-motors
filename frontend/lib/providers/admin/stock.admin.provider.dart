import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Enumeración para el estado del stock de un producto
enum StockStatus {
  disponible,
  stockBajo,
  agotado,
}

/// Provider para gestionar el inventario y stock
class StockProvider extends ChangeNotifier {
  // Repositorio para gestión de stock
  final StockRepository _stockRepository = StockRepository.instance;

  // Estado
  String _selectedSucursalId = '';
  String _selectedSucursalNombre = '';
  List<Sucursal> _sucursales = <Sucursal>[];
  Sucursal? _selectedSucursal;
  PaginatedResponse<Producto>? _paginatedProductos;
  List<Producto> _productosFiltrados = <Producto>[];
  bool _isLoadingSucursales = true;
  bool _isLoadingProductos = false;
  String? _errorProductos;

  // Parámetros de paginación y filtrado
  String _searchQuery = '';
  int _currentPage = 1;
  int _pageSize = 10;
  String _sortBy = '';
  String _order = 'desc';

  // Filtro de estado de stock
  StockStatus? _filtroEstadoStock;

  // Getters
  String get selectedSucursalId => _selectedSucursalId;
  String get selectedSucursalNombre => _selectedSucursalNombre;
  List<Sucursal> get sucursales => _sucursales;
  Sucursal? get selectedSucursal => _selectedSucursal;
  PaginatedResponse<Producto>? get paginatedProductos => _paginatedProductos;
  List<Producto> get productosFiltrados => _productosFiltrados;
  bool get isLoadingSucursales => _isLoadingSucursales;
  bool get isLoadingProductos => _isLoadingProductos;
  String? get errorProductos => _errorProductos;

  String get searchQuery => _searchQuery;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  String get sortBy => _sortBy;
  String get order => _order;
  StockStatus? get filtroEstadoStock => _filtroEstadoStock;

  /// Inicializar el provider
  Future<void> inicializar() async {
    await cargarSucursales();
  }

  /// Recarga todos los datos forzando actualización desde el servidor
  Future<void> recargarDatos() async {
    _errorProductos = null;
    notifyListeners();

    try {
      await cargarSucursales();
      if (_selectedSucursalId.isNotEmpty) {
        _stockRepository.invalidateCache(_selectedSucursalId);
        await cargarProductos(_selectedSucursalId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error al recargar datos de stock: $e');
      _errorProductos = 'Error al recargar datos: $e';
      notifyListeners();
    }
  }

  /// Obtiene el estado del stock como enumeración
  StockStatus getStockStatus(int stockActual, int stockMinimo) {
    if (stockActual <= 0) {
      return StockStatus.agotado;
    } else if (stockActual < stockMinimo) {
      return StockStatus.stockBajo;
    } else {
      return StockStatus.disponible;
    }
  }

  /// Determina el color del indicador de stock basado en la cantidad actual vs mínima
  Color getStockStatusColor(int stockActual, int stockMinimo) {
    final StockStatus status = getStockStatus(stockActual, stockMinimo);
    switch (status) {
      case StockStatus.agotado:
        return Colors.red.shade800;
      case StockStatus.stockBajo:
        return const Color(0xFFE31E24);
      case StockStatus.disponible:
        return Colors.green;
    }
  }

  /// Determina el icono para el estado del stock
  IconData getStockStatusIcon(int stockActual, int stockMinimo) {
    final StockStatus status = getStockStatus(stockActual, stockMinimo);
    switch (status) {
      case StockStatus.agotado:
        return FontAwesomeIcons.ban;
      case StockStatus.stockBajo:
        return FontAwesomeIcons.triangleExclamation;
      case StockStatus.disponible:
        return FontAwesomeIcons.check;
    }
  }

  /// Obtiene el estado del stock como texto
  String getStockStatusText(int stockActual, int stockMinimo) {
    final StockStatus status = getStockStatus(stockActual, stockMinimo);
    switch (status) {
      case StockStatus.agotado:
        return 'Agotado';
      case StockStatus.stockBajo:
        return 'Stock bajo';
      case StockStatus.disponible:
        return 'Disponible';
    }
  }

  /// Cargar las sucursales disponibles
  Future<void> cargarSucursales() async {
    _isLoadingSucursales = true;
    notifyListeners();

    try {
      _sucursales = await _stockRepository.getSucursales();
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando sucursales: $e');
    } finally {
      _isLoadingSucursales = false;
      notifyListeners();
    }
  }

  /// Selecciona una sucursal y carga sus productos
  Future<void> seleccionarSucursal(Sucursal sucursal) async {
    if (_selectedSucursal?.id != sucursal.id) {
      _selectedSucursal = sucursal;
      _selectedSucursalId = sucursal.id.toString();
      _selectedSucursalNombre = sucursal.nombre;
      notifyListeners();
      await cargarProductos(_selectedSucursalId);
    }
  }

  /// Método para cargar productos de una sucursal específica
  Future<void> cargarProductos(String sucursalId) async {
    if (sucursalId.isEmpty) {
      return;
    }

    debugPrint('Iniciando carga de productos para sucursal: $sucursalId');
    debugPrint('Filtro actual: $_filtroEstadoStock');

    _isLoadingProductos = true;
    _errorProductos = null;
    notifyListeners();

    try {
      Map<String, dynamic> queryParams = {
        'sucursalId': sucursalId,
        'page': _currentPage,
        'pageSize': _pageSize,
        'sortBy': _sortBy.isNotEmpty ? _sortBy : 'nombre',
        'order': _order,
      };

      if (_filtroEstadoStock != null) {
        debugPrint(
            'Usando endpoint específico para filtro: $_filtroEstadoStock');
        switch (_filtroEstadoStock!) {
          case StockStatus.stockBajo:
            queryParams['stockBajo'] = true;
            break;
          case StockStatus.agotado:
            queryParams['stock'] = {'value': 0, 'filterType': 'eq'};
            break;
          case StockStatus.disponible:
            queryParams['stock'] = {'value': 1, 'filterType': 'gte'};
            break;
        }
      }

      if (_searchQuery.length >= 3) {
        queryParams['search'] = _searchQuery;
      }

      _paginatedProductos = await _stockRepository.getProductos(
        sucursalId: queryParams['sucursalId'],
        page: queryParams['page'],
        pageSize: queryParams['pageSize'],
        sortBy: queryParams['sortBy'],
        order: queryParams['order'],
        search: queryParams['search'],
        stock: queryParams['stock'],
        stockBajo: queryParams['stockBajo'],
      );

      debugPrint('Productos recibidos: ${_paginatedProductos?.items.length}');
      _productosFiltrados = _paginatedProductos?.items ?? [];

      _isLoadingProductos = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar productos: $e');
      _errorProductos = 'Error al cargar productos: $e';
      _isLoadingProductos = false;
      notifyListeners();
    }
  }

  /// Método para cambiar de página
  void cambiarPagina(int pagina) {
    if (_currentPage != pagina) {
      _currentPage = pagina;
      notifyListeners();
      cargarProductos(_selectedSucursalId);
    }
  }

  /// Método para cambiar tamaño de página
  void cambiarTamanioPagina(int tamanio) {
    if (_pageSize != tamanio) {
      _pageSize = tamanio;
      _currentPage = 1;
      notifyListeners();
      cargarProductos(_selectedSucursalId);
    }
  }

  /// Método para ordenar por un campo
  void ordenarPor(String campo) {
    if (_sortBy == campo) {
      _order = _order == 'asc' ? 'desc' : 'asc';
    } else {
      _sortBy = campo;
      _order = 'desc';
    }
    _currentPage = 1;
    notifyListeners();
    cargarProductos(_selectedSucursalId);
  }

  /// Método para filtrar por estado de stock
  Future<void> filtrarPorEstadoStock(StockStatus? estado) async {
    debugPrint('Iniciando filtrado por estado: $estado');

    if (_filtroEstadoStock == estado) {
      debugPrint('Desactivando filtro actual: $_filtroEstadoStock');
      _filtroEstadoStock = null;
    } else {
      debugPrint('Cambiando filtro de $_filtroEstadoStock a $estado');
      _filtroEstadoStock = estado;
    }
    _currentPage = 1;
    notifyListeners();

    if (_selectedSucursalId.isNotEmpty) {
      debugPrint(
          'Cargando productos con nuevo filtro para sucursal: $_selectedSucursalId');
      await cargarProductos(_selectedSucursalId);
    }
  }

  /// Actualizar término de búsqueda
  Future<void> actualizarBusqueda(String value) async {
    _searchQuery = value;
    _currentPage = 1;
    notifyListeners();

    if (_selectedSucursalId.isNotEmpty && value.length >= 3) {
      await cargarProductos(_selectedSucursalId);
    }
  }

  /// Limpiar todos los filtros aplicados
  Future<void> limpiarFiltros() async {
    _searchQuery = '';
    _filtroEstadoStock = null;
    _currentPage = 1;
    notifyListeners();

    if (_selectedSucursalId.isNotEmpty) {
      await cargarProductos(_selectedSucursalId);
    }
  }

  /// Agrupa los productos por su estado de stock
  Map<StockStatus, List<Producto>> agruparProductosPorEstadoStock(
      List<Producto> productos) {
    final Map<StockStatus, List<Producto>> agrupados = {
      StockStatus.agotado: [],
      StockStatus.stockBajo: [],
      StockStatus.disponible: [],
    };

    for (final Producto producto in productos) {
      final StockStatus status =
          getStockStatus(producto.stock, producto.stockMinimo ?? 0);
      agrupados[status]!.add(producto);
    }

    return agrupados;
  }

  /// Devuelve la URL completa de la imagen del producto usando el repositorio
  String getProductoImageUrl(Producto producto) {
    return ProductoRepository.getProductoImageUrl(producto) ??
        'https://via.placeholder.com/150';
  }
}
