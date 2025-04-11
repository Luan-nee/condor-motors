import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:condorsmotors/utils/stock_utils.dart' as stock_utils;
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

  // Nuevo: Productos consolidados de todas las sucursales
  final Map<int, Map<String, int>> _stockPorSucursal =
      <int, Map<String, int>>{}; // productoId -> {sucursalId -> stock}
  List<Producto> _productosBajoStock =
      <Producto>[]; // Productos con problemas en cualquier sucursal

  // Parámetros de paginación y filtrado
  String _searchQuery = '';
  int _currentPage = 1;
  int _pageSize = 10;
  String _sortBy = '';
  String _order = 'desc';

  // Filtro de estado de stock
  StockStatus? _filtroEstadoStock;

  // Flag para mostrar vista consolidada de todas las sucursales
  bool _mostrarVistaConsolidada = false;

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

  Map<int, Map<String, int>> get stockPorSucursal => _stockPorSucursal;
  List<Producto> get productosBajoStock => _productosBajoStock;

  String get searchQuery => _searchQuery;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  String get sortBy => _sortBy;
  String get order => _order;

  StockStatus? get filtroEstadoStock => _filtroEstadoStock;
  bool get mostrarVistaConsolidada => _mostrarVistaConsolidada;

  /// Inicializar el provider
  Future<void> inicializar() async {
    // Establecer stock bajo como filtro predeterminado
    _filtroEstadoStock = StockStatus.stockBajo;
    await Future.wait([
      cargarSucursales(),
    ]);
  }

  /// Recarga todos los datos forzando actualización desde el servidor
  Future<void> recargarDatos() async {
    _errorProductos = null;
    notifyListeners();

    try {
      // Forzar recarga de sucursales
      await cargarSucursales();

      // Si estamos en vista consolidada, recargar todos los productos
      if (_mostrarVistaConsolidada) {
        await cargarProductosTodasSucursales();
      }
      // Si hay una sucursal seleccionada, recargar sus productos
      else if (_selectedSucursalId.isNotEmpty) {
        // Invalidar caché antes de recargar
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

  /// Convertir entre StockStatus del provider y StockStatus de utils
  stock_utils.StockStatus convertToUtilsStockStatus(StockStatus status) {
    switch (status) {
      case StockStatus.agotado:
        return stock_utils.StockStatus.agotado;
      case StockStatus.stockBajo:
        return stock_utils.StockStatus.stockBajo;
      case StockStatus.disponible:
        return stock_utils.StockStatus.disponible;
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

      // Cargar productos de la sucursal seleccionada
      await cargarProductos(_selectedSucursalId);
    }
  }

  /// Método para cargar productos de la sucursal seleccionada (vista individual)
  Future<void> cargarProductos(String sucursalId) async {
    if (sucursalId.isEmpty) {
      _paginatedProductos = null;
      _productosFiltrados = <Producto>[];
      notifyListeners();
      return;
    }

    _isLoadingProductos = true;
    _errorProductos = null;
    notifyListeners();

    try {
      // Aplicar la búsqueda del servidor sólo si la búsqueda es mayor a 3 caracteres
      final String? searchQuery =
          _searchQuery.length >= 3 ? _searchQuery : null;

      // Si está seleccionado el filtro de stock bajo, usar el método específico
      if (_filtroEstadoStock == StockStatus.stockBajo) {
        final PaginatedResponse<Producto> paginatedProductos =
            await _stockRepository.getProductosConStockBajo(
          sucursalId: sucursalId,
          page: _currentPage,
          pageSize: _pageSize,
          sortBy: _sortBy.isNotEmpty ? _sortBy : 'nombre',
        );

        _paginatedProductos = paginatedProductos;
        _productosFiltrados = paginatedProductos.items;
        _isLoadingProductos = false;
        notifyListeners();
        return;
      }

      // Si está seleccionado el filtro de agotados, usamos el método específico
      if (_filtroEstadoStock == StockStatus.agotado) {
        final PaginatedResponse<Producto> paginatedProductos =
            await _stockRepository.getProductosAgotados(
          sucursalId: sucursalId,
          page: _currentPage,
          pageSize: _pageSize,
          sortBy: _sortBy.isNotEmpty ? _sortBy : 'nombre',
        );

        _paginatedProductos = paginatedProductos;
        _productosFiltrados = paginatedProductos.items;
        _isLoadingProductos = false;
        notifyListeners();
        return;
      }

      // Si está seleccionado el filtro de disponible, usamos el método específico
      if (_filtroEstadoStock == StockStatus.disponible) {
        final PaginatedResponse<Producto> paginatedProductos =
            await _stockRepository.getProductosDisponibles(
          sucursalId: sucursalId,
          page: _currentPage,
          pageSize: _pageSize,
          sortBy: _sortBy.isNotEmpty ? _sortBy : 'nombre',
        );

        _paginatedProductos = paginatedProductos;
        _productosFiltrados = paginatedProductos.items;
        _isLoadingProductos = false;
        notifyListeners();
        return;
      }

      // Para otros casos, usar el método general
      final PaginatedResponse<Producto> paginatedProductos =
          await _stockRepository.getProductos(
        sucursalId: sucursalId,
        search: searchQuery,
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: _sortBy.isNotEmpty ? _sortBy : null,
        order: _order,
        // Si filtro es disponible, enviamos stockBajo=false
        stockBajo: _filtroEstadoStock == null,
      );

      // Reorganizar los productos según la prioridad de stock
      final List<Producto> productosReorganizados =
          stock_utils.StockUtils.reorganizarProductosPorPrioridad(
              paginatedProductos.items);

      _paginatedProductos = paginatedProductos;
      // Actualizamos los productos filtrados con la nueva organización
      _productosFiltrados = productosReorganizados;
      _isLoadingProductos = false;
      notifyListeners();
    } catch (e) {
      _errorProductos = e.toString();
      _isLoadingProductos = false;
      notifyListeners();
    }
  }

  /// Método para cargar productos con problemas de stock de todas las sucursales
  Future<void> cargarProductosTodasSucursales() async {
    if (_sucursales.isEmpty) {
      _productosBajoStock = <Producto>[];
      notifyListeners();
      return;
    }

    _isLoadingProductos = true;
    _errorProductos = null;
    _stockPorSucursal.clear(); // Reiniciar el mapa para evitar datos antiguos
    notifyListeners();

    try {
      final List<Producto> todosProductos = <Producto>[];

      // Cargar productos de cada sucursal utilizando el nuevo método getProductosConStockBajo
      final List<Future> futures = <Future>[];

      for (final Sucursal sucursal in _sucursales) {
        futures.add(
            _cargarProductosConBajoStockDeSucursal(sucursal, todosProductos));
      }

      // Esperar a que todas las peticiones terminen
      await Future.wait(futures);

      // Consolidar productos para evitar duplicados
      final List<Producto> productosUnicos =
          stock_utils.StockUtils.consolidarProductosUnicos(todosProductos);

      // Priorizar productos con problemas más graves
      final List<Producto> productosPrioritarios =
          stock_utils.StockUtils.reorganizarProductosPorPrioridad(
        productosUnicos,
        stockPorSucursal: _stockPorSucursal,
        sucursales: _sucursales,
      );

      _productosBajoStock = productosPrioritarios;
      _isLoadingProductos = false;
      notifyListeners();
    } catch (e) {
      _errorProductos = e.toString();
      _isLoadingProductos = false;
      notifyListeners();
    }
  }

  /// Método auxiliar para cargar productos con stock bajo de una sucursal
  Future<void> _cargarProductosConBajoStockDeSucursal(
      Sucursal sucursal, List<Producto> todosProductos) async {
    try {
      // Cargar productos con stock bajo usando paginación completa
      await _cargarTodosProductosConCondicion(
          sucursal: sucursal,
          todosProductos: todosProductos,
          condicion: 'stockBajo',
          mensaje: 'con stock bajo');

      // Cargar productos agotados (pueden solaparse con los de stock bajo)
      await _cargarTodosProductosConCondicion(
          sucursal: sucursal,
          todosProductos: todosProductos,
          condicion: 'agotados',
          mensaje: 'agotados');
    } catch (e) {
      debugPrint(
          'Error al cargar productos de sucursal ${sucursal.nombre}: $e');
    }
  }

  /// Método para cargar todos los productos de una sucursal que cumplan una condición específica
  Future<void> _cargarTodosProductosConCondicion({
    required Sucursal sucursal,
    required List<Producto> todosProductos,
    required String condicion,
    required String mensaje,
  }) async {
    // Configuración inicial de paginación
    int paginaActual = 1;
    const int tamanioPagina = 100;
    bool hayMasPaginas = true;
    final List<Producto> productosObtenidos = <Producto>[];

    try {
      // Iteramos mientras haya más páginas
      while (hayMasPaginas) {
        PaginatedResponse<Producto> respuesta;

        // Según la condición, usamos el método API correspondiente
        if (condicion == 'stockBajo') {
          respuesta = await _stockRepository.getProductosConStockBajo(
            sucursalId: sucursal.id,
            page: paginaActual,
            pageSize: tamanioPagina,
          );
        } else if (condicion == 'agotados') {
          // Para los agotados ahora usamos el método específico
          respuesta = await _stockRepository.getProductosAgotados(
            sucursalId: sucursal.id,
            page: paginaActual,
            pageSize: tamanioPagina,
          );
        } else {
          // Por defecto, traemos todos los productos
          respuesta = await _stockRepository.getProductos(
            sucursalId: sucursal.id,
            page: paginaActual,
            pageSize: tamanioPagina,
          );
        }

        // Guardamos los productos obtenidos
        productosObtenidos.addAll(respuesta.items);

        // Procesamos los productos de esta página
        if (respuesta.items.isNotEmpty) {
          _procesarProductosPorSucursal(respuesta.items, sucursal);
          todosProductos.addAll(respuesta.items);
        }

        // Verificamos si hay más páginas
        hayMasPaginas = paginaActual < respuesta.paginacion.totalPages;

        // Si hay más páginas, incrementamos la página actual
        if (hayMasPaginas) {
          paginaActual++;
        } else {
          break;
        }
      }

      debugPrint(
          'Cargados ${productosObtenidos.length} productos $mensaje de ${sucursal.nombre}');
    } catch (e) {
      debugPrint(
          'Error al cargar productos $mensaje de sucursal ${sucursal.nombre}: $e');
    }
  }

  /// Procesar productos por sucursal y almacenar en mapa consolidado
  void _procesarProductosPorSucursal(
      List<Producto> productos, Sucursal sucursal) {
    for (final Producto producto in productos) {
      // Si es la primera vez que vemos este producto, inicializamos su mapa
      if (!_stockPorSucursal.containsKey(producto.id)) {
        _stockPorSucursal[producto.id] = <String, int>{};
      }

      // Guardamos el stock de este producto en esta sucursal
      _stockPorSucursal[producto.id]![sucursal.id] = producto.stock;
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
      _currentPage = 1; // Volvemos a la primera página al cambiar el tamaño
      notifyListeners();
      cargarProductos(_selectedSucursalId);
    }
  }

  /// Método para ordenar por un campo
  void ordenarPor(String campo) {
    if (_sortBy == campo) {
      // Si ya estamos ordenando por este campo, cambiamos la dirección
      _order = _order == 'asc' ? 'desc' : 'asc';
    } else {
      _sortBy = campo;
      _order = 'desc'; // Por defecto ordenamos descendente
    }
    _currentPage = 1; // Volvemos a la primera página al cambiar el orden
    notifyListeners();
    cargarProductos(_selectedSucursalId);
  }

  /// Método para filtrar por estado de stock
  void filtrarPorEstadoStock(StockStatus? estado) {
    if (_filtroEstadoStock == estado) {
      // Si hacemos clic en el mismo filtro, lo quitamos
      _filtroEstadoStock = null;
    } else {
      _filtroEstadoStock = estado;
    }
    _currentPage = 1; // Volvemos a la primera página al cambiar el filtro
    notifyListeners();
    cargarProductos(_selectedSucursalId);
  }

  /// Activar/desactivar vista consolidada
  void toggleVistaConsolidada() {
    _mostrarVistaConsolidada = !_mostrarVistaConsolidada;
    notifyListeners();

    if (_mostrarVistaConsolidada) {
      cargarProductosTodasSucursales();
    } else {
      cargarSucursales();
      if (_selectedSucursalId.isNotEmpty) {
        cargarProductos(_selectedSucursalId);
      }
    }
  }

  /// Filtrar los productos en la vista consolidada por estado
  void filtrarConsolidadoPorEstado(StockStatus estado) {
    // Si ya tenemos todos los productos cargados, convertimos nuestro StockStatus al de StockUtils
    final stock_utils.StockStatus estadoUtils =
        convertToUtilsStockStatus(estado);
    _productosBajoStock = stock_utils.StockUtils.filtrarPorEstadoStock(
        _productosBajoStock, estadoUtils);
    notifyListeners();
  }

  /// Reiniciar filtros en la vista consolidada
  void reiniciarFiltrosConsolidados() {
    cargarProductosTodasSucursales(); // Volver a cargar todos los productos
  }

  /// Actualizar término de búsqueda
  void actualizarBusqueda(String value) async {
    _searchQuery = value;
    _isLoadingProductos = true;
    notifyListeners();

    try {
      if (value.isEmpty) {
        // Si la búsqueda está vacía, cargar productos normales
        await cargarProductos(_selectedSucursalId);
      } else if (value.length >= 3) {
        // Si tenemos 3 o más caracteres, realizar búsqueda
        final PaginatedResponse<Producto> resultados =
            await _stockRepository.buscarProductosPorNombre(
          sucursalId: _selectedSucursalId,
          nombre: value,
          page: _currentPage,
          pageSize: _pageSize,
        );

        _paginatedProductos = resultados;
        _productosFiltrados = resultados.items;

        // Si hay un filtro de estado activo, aplicarlo a los resultados
        if (_filtroEstadoStock != null) {
          _productosFiltrados = _productosFiltrados.where((Producto p) {
            final StockStatus status =
                getStockStatus(p.stock, p.stockMinimo ?? 0);
            return status == _filtroEstadoStock;
          }).toList();
        }

        // Reorganizar por prioridad si es necesario
        _productosFiltrados =
            stock_utils.StockUtils.reorganizarProductosPorPrioridad(
          _productosFiltrados,
          stockPorSucursal: _stockPorSucursal,
          sucursales: _sucursales,
        );
      }
    } catch (e) {
      _errorProductos = 'Error al buscar productos: $e';
      debugPrint(_errorProductos);
    } finally {
      _isLoadingProductos = false;
      notifyListeners();
    }
  }

  /// Limpiar todos los filtros aplicados
  void limpiarFiltros() async {
    _searchQuery = '';
    _filtroEstadoStock = null;
    _currentPage = 1;
    _isLoadingProductos = true;
    notifyListeners();

    try {
      // Recargar productos sin filtros
      if (_mostrarVistaConsolidada) {
        await cargarProductosTodasSucursales();
      } else if (_selectedSucursalId.isNotEmpty) {
        // Forzar recarga desde el servidor
        _stockRepository.invalidateCache(_selectedSucursalId);
        await cargarProductos(_selectedSucursalId);
      }
    } catch (e) {
      _errorProductos = 'Error al limpiar filtros: $e';
      debugPrint(_errorProductos);
    } finally {
      _isLoadingProductos = false;
      notifyListeners();
    }
  }

  /// Agrupa los productos por su estado de stock (agotado, stock bajo, disponible)
  Map<StockStatus, List<Producto>> agruparProductosPorEstadoStock(
      List<Producto> productos) {
    // Inicializar mapa con listas vacías
    final Map<StockStatus, List<Producto>> agrupados = {
      StockStatus.agotado: [],
      StockStatus.stockBajo: [],
      StockStatus.disponible: [],
    };

    // Clasificar cada producto según su estado
    for (final Producto producto in productos) {
      final int stockActual = producto.stock;
      final int stockMinimo = producto.stockMinimo ?? 0;
      final StockStatus status = getStockStatus(stockActual, stockMinimo);
      agrupados[status]!.add(producto);
    }

    return agrupados;
  }
}
