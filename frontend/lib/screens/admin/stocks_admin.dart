import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:condorsmotors/screens/admin/widgets/slide_sucursal.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_detalle_sucursal.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_detalles_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_list.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Enumeración para el estado del stock de un producto
enum StockStatus {
  disponible,
  stockBajo,
  agotado,
}

class InventarioAdminScreen extends StatefulWidget {
  const InventarioAdminScreen({super.key});

  @override
  State<InventarioAdminScreen> createState() => _InventarioAdminScreenState();
}

class _InventarioAdminScreenState extends State<InventarioAdminScreen> {
  // Controlador para el campo de búsqueda
  final TextEditingController _searchController = TextEditingController();

  // Estado del drawer
  final bool _drawerOpen = true;

  // Clave para el valor de la tabla de productos
  final ValueNotifier<Object> _stocksKey = ValueNotifier<Object>(Object());

  // Estado local para sucursales
  List<Sucursal> _sucursales = [];
  Sucursal? _selectedSucursal;
  String _selectedSucursalId = '';
  String _selectedSucursalNombre = '';
  bool _isLoadingSucursales = true;

  // Estado local para productos
  PaginatedResponse<Producto>? _paginatedProductos;
  List<Producto> _productosFiltrados = [];
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

  // Repositorios
  final StockRepository _stockRepository = StockRepository.instance;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    // Liberar recursos
    _searchController.dispose();
    _stocksKey.dispose();
    super.dispose();
  }

  /// Inicializar el estado
  Future<void> _inicializar() async {
    await _cargarSucursales();
    // Después de inicializar, seleccionar la primera sucursal
    if (_sucursales.isNotEmpty && _selectedSucursalId.isEmpty) {
      // Intentar encontrar la sucursal principal primero
      final sucursalPrincipal = _sucursales.firstWhere(
        (sucursal) => sucursal.nombre.toLowerCase().contains('principal'),
        orElse: () => _sucursales.first,
      );
      await _seleccionarSucursal(sucursalPrincipal);
    }
  }

  /// Cargar las sucursales disponibles
  Future<void> _cargarSucursales() async {
    setState(() {
      _isLoadingSucursales = true;
    });

    try {
      final sucursales = await _stockRepository.getSucursales();
      setState(() {
        _sucursales = sucursales;
        _isLoadingSucursales = false;
      });
    } catch (e) {
      debugPrint('Error cargando sucursales: $e');
      setState(() {
        _isLoadingSucursales = false;
      });
    }
  }

  /// Selecciona una sucursal y carga sus productos
  Future<void> _seleccionarSucursal(Sucursal sucursal) async {
    if (_selectedSucursal?.id != sucursal.id) {
      setState(() {
        _selectedSucursal = sucursal;
        _selectedSucursalId = sucursal.id.toString();
        _selectedSucursalNombre = sucursal.nombre;
      });
      await _cargarProductos(_selectedSucursalId);
    }
  }

  /// Método para cargar productos de una sucursal específica
  Future<void> _cargarProductos(String sucursalId) async {
    if (sucursalId.isEmpty) {
      return;
    }

    debugPrint('Iniciando carga de productos para sucursal: $sucursalId');
    debugPrint('Filtro actual: $_filtroEstadoStock');

    setState(() {
      _isLoadingProductos = true;
      _errorProductos = null;
    });

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
          case StockStatus.agotado:
            queryParams['stock'] = {'value': 0, 'filterType': 'eq'};
          case StockStatus.disponible:
            queryParams['stock'] = {'value': 1, 'filterType': 'gte'};
        }
      }

      if (_searchQuery.length >= 3) {
        queryParams['search'] = _searchQuery;
      }

      final paginatedProductos = await _stockRepository.getProductos(
        sucursalId: queryParams['sucursalId']!,
        page: queryParams['page']!,
        pageSize: queryParams['pageSize']!,
        sortBy: queryParams['sortBy']!,
        order: queryParams['order']!,
        search: queryParams['search'],
        stock: queryParams['stock'],
        stockBajo: queryParams['stockBajo'],
      );

      debugPrint('Productos recibidos: ${paginatedProductos.items.length}');

      setState(() {
        _paginatedProductos = paginatedProductos;
        _productosFiltrados = paginatedProductos.items;
        _isLoadingProductos = false;
      });
    } catch (e) {
      debugPrint('Error al cargar productos: $e');
      setState(() {
        _errorProductos = 'Error al cargar productos: $e';
        _isLoadingProductos = false;
      });
    }
  }

  /// Método para cambiar de página
  void _cambiarPagina(int pagina) {
    if (_currentPage != pagina) {
      setState(() {
        _currentPage = pagina;
      });
      _cargarProductos(_selectedSucursalId);
    }
  }

  /// Método para cambiar tamaño de página
  void _cambiarTamanioPagina(int tamanio) {
    if (_pageSize != tamanio) {
      setState(() {
        _pageSize = tamanio;
        _currentPage = 1;
      });
      _cargarProductos(_selectedSucursalId);
    }
  }

  /// Método para ordenar por un campo
  void _ordenarPor(String campo) {
    if (_sortBy == campo) {
      setState(() {
        _order = _order == 'asc' ? 'desc' : 'asc';
      });
    } else {
      setState(() {
        _sortBy = campo;
        _order = 'desc';
      });
    }
    _currentPage = 1;
    _cargarProductos(_selectedSucursalId);
  }

  /// Método para filtrar por estado de stock
  Future<void> _filtrarPorEstadoStock(StockStatus? estado) async {
    debugPrint('Iniciando filtrado por estado: $estado');

    if (_filtroEstadoStock == estado) {
      debugPrint('Desactivando filtro actual: $_filtroEstadoStock');
      setState(() {
        _filtroEstadoStock = null;
      });
    } else {
      debugPrint('Cambiando filtro de $_filtroEstadoStock a $estado');
      setState(() {
        _filtroEstadoStock = estado;
      });
    }
    _currentPage = 1;

    if (_selectedSucursalId.isNotEmpty) {
      debugPrint(
          'Cargando productos con nuevo filtro para sucursal: $_selectedSucursalId');
      await _cargarProductos(_selectedSucursalId);
    }
  }

  /// Actualizar término de búsqueda
  Future<void> _actualizarBusqueda(String value) async {
    setState(() {
      _searchQuery = value;
      _currentPage = 1;
    });

    if (_selectedSucursalId.isNotEmpty && value.length >= 3) {
      await _cargarProductos(_selectedSucursalId);
    }
  }

  /// Limpiar todos los filtros aplicados
  Future<void> _limpiarFiltros() async {
    setState(() {
      _searchQuery = '';
      _filtroEstadoStock = null;
      _currentPage = 1;
    });

    if (_selectedSucursalId.isNotEmpty) {
      await _cargarProductos(_selectedSucursalId);
    }
  }

  /// Recarga todos los datos forzando actualización desde el servidor
  Future<void> _recargarDatos() async {
    setState(() {
      _errorProductos = null;
    });

    try {
      await _cargarSucursales();
      if (_selectedSucursalId.isNotEmpty) {
        _stockRepository.invalidateCache(_selectedSucursalId);
        await _cargarProductos(_selectedSucursalId);
      }
    } catch (e) {
      debugPrint('Error al recargar datos de stock: $e');
      setState(() {
        _errorProductos = 'Error al recargar datos: $e';
      });
    }
  }

  // Método para mostrar un snackbar con mensaje cuando no hay productos

  void _verDetallesProducto(Producto producto) {
    showDialog(
      context: context,
      builder: (BuildContext context) => StockDetalleSucursalDialog(
        producto: producto,
      ),
    ).then((_) {
      // Recargar productos al cerrar el diálogo para reflejar posibles cambios
      if (_selectedSucursalId.isNotEmpty) {
        _cargarProductos(_selectedSucursalId);
      }
    });
  }

  void _verStockDetalles(Producto producto) {
    showDialog(
      context: context,
      builder: (BuildContext context) => StockDetallesDialog(
        producto: producto,
        sucursalId: _selectedSucursalId,
        sucursalNombre: _selectedSucursalNombre,
      ),
    ).then((_) {
      // Recargar productos al cerrar el diálogo para reflejar cambios
      if (_selectedSucursalId.isNotEmpty) {
        _cargarProductos(_selectedSucursalId);
      }
    });
  }

  // Widget para botones de acción rápida

  @override
  Widget build(BuildContext context) {
    // Actualizar la clave del stock cuando cambian datos relevantes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentPage = _currentPage;
        final pageSize = _pageSize;
        final filtroEstado = _filtroEstadoStock?.toString() ?? '';
        final searchQuery = _searchQuery;
        final sortBy = _sortBy;
        final order = _order;

        _stocksKey.value = Object.hash(
            _selectedSucursalId,
            currentPage,
            pageSize,
            filtroEstado,
            searchQuery,
            sortBy,
            order,
            _productosFiltrados.length,
            DateTime.now().millisecondsSinceEpoch);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Row(
        children: <Widget>[
          // Panel principal (75% del ancho)
          Expanded(
            flex: 75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Header con título y acciones
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            const FaIcon(
                              FontAwesomeIcons.warehouse,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'INVENTARIO',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (_selectedSucursal != null) ...<Widget>[
                              const Text(
                                ' / ',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white54,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  _selectedSucursal!.nombre,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Botón de recarga
                      if (_selectedSucursal != null)
                        Row(
                          children: <Widget>[
                            ElevatedButton.icon(
                              icon: _isLoadingProductos
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const FaIcon(
                                      FontAwesomeIcons.arrowsRotate,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                _isLoadingProductos
                                    ? 'Recargando...'
                                    : 'Recargar',
                                style: const TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2D2D2D),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: _isLoadingProductos
                                  ? null
                                  : () async {
                                      // Definir funciones para mostrar SnackBars
                                      void showErrorSnackBar() {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(_errorProductos ??
                                                'Error desconocido'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }

                                      void showSuccessSnackBar() {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Datos recargados exitosamente'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }

                                      // Recargar todos los datos
                                      await _recargarDatos();

                                      // Verificar si el widget aún está montado
                                      if (!mounted) {
                                        return;
                                      }

                                      // Mostrar mensaje de éxito o error
                                      if (_errorProductos != null) {
                                        showErrorSnackBar();
                                      } else {
                                        showSuccessSnackBar();
                                      }
                                    },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Contenido principal
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Barra de búsqueda mejorada
                        if (_selectedSucursalId.isNotEmpty) ...<Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Container(
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _searchQuery.isNotEmpty
                                            ? const Color(0xFFE31E24)
                                            : const Color(0xFF2D2D2D),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          width: 40,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            color: _searchQuery.isNotEmpty
                                                ? const Color(0xFFE31E24)
                                                    .withValues(alpha: 0.1)
                                                : const Color(0xFF2D2D2D),
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(6),
                                              bottomLeft: Radius.circular(6),
                                            ),
                                          ),
                                          child: Center(
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              child: _isLoadingProductos
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                Color>(
                                                          Color(0xFFE31E24),
                                                        ),
                                                      ),
                                                    )
                                                  : const FaIcon(
                                                      FontAwesomeIcons
                                                          .magnifyingGlass,
                                                      color: Colors.white54,
                                                      size: 14,
                                                    ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _searchController,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Buscar por nombre, SKU, categoría o marca...',
                                              hintStyle: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.3),
                                                fontSize: 14,
                                              ),
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 14,
                                              ),
                                            ),
                                            onChanged: _actualizarBusqueda,
                                            onFieldSubmitted: (String value) {
                                              if (value.length >= 3) {
                                                _actualizarBusqueda(value);
                                              }
                                            },
                                          ),
                                        ),
                                        if (_searchController.text.isNotEmpty)
                                          Container(
                                            width: 40,
                                            height: 46,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF2D2D2D),
                                              borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(6),
                                                bottomRight: Radius.circular(6),
                                              ),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.white54,
                                                size: 16,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                                _actualizarBusqueda('');
                                              },
                                              tooltip: 'Limpiar búsqueda',
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Contador de resultados
                                if (_searchQuery.isNotEmpty &&
                                    _paginatedProductos != null) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D2D2D),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFE31E24)
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${_paginatedProductos!.totalItems}',
                                          style: const TextStyle(
                                            color: Color(0xFFE31E24),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'resultados',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.7),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (_searchQuery.isNotEmpty ||
                                    _filtroEstadoStock != null) ...[
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    icon: const FaIcon(
                                      FontAwesomeIcons.filterCircleXmark,
                                      size: 14,
                                    ),
                                    label: const Text('Limpiar'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      backgroundColor: const Color(0xFF2D2D2D),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _limpiarFiltros();
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Mostrar mensaje de ayuda
                          if (_searchQuery.isNotEmpty &&
                              _searchQuery.length < 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.amber,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ingresa al menos 3 caracteres para buscar',
                                    style: TextStyle(
                                      color:
                                          Colors.amber.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],

                        // Filtros rápidos para el estado del stock
                        if (_selectedSucursalId.isNotEmpty) ...<Widget>[
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: <Widget>[
                                const Text(
                                  'Filtrar por: ',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  'Disponibles',
                                  FontAwesomeIcons.check,
                                  Colors.green,
                                  _filtroEstadoStock == StockStatus.disponible,
                                  () => _filtrarPorEstadoStock(
                                      StockStatus.disponible),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  'Stock bajo',
                                  FontAwesomeIcons.triangleExclamation,
                                  const Color(0xFFE31E24),
                                  _filtroEstadoStock == StockStatus.stockBajo,
                                  () {
                                    debugPrint('Presionado filtro: Stock Bajo');
                                    debugPrint(
                                        'Estado actual del filtro: $_filtroEstadoStock');
                                    _filtrarPorEstadoStock(
                                        StockStatus.stockBajo);
                                  },
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  'Agotados',
                                  FontAwesomeIcons.ban,
                                  Colors.red.shade800,
                                  _filtroEstadoStock == StockStatus.agotado,
                                  () {
                                    debugPrint('Presionado filtro: Agotados');
                                    debugPrint(
                                        'Estado actual del filtro: $_filtroEstadoStock');
                                    _filtrarPorEstadoStock(StockStatus.agotado);
                                  },
                                ),
                                const SizedBox(width: 16),
                                if (_filtroEstadoStock != null)
                                  IconButton(
                                    icon: const FaIcon(
                                      FontAwesomeIcons.filterCircleXmark,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      _filtrarPorEstadoStock(null);
                                    },
                                    tooltip: 'Limpiar filtros',
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Tabla de productos
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: ValueListenableBuilder<Object>(
                                    valueListenable: _stocksKey,
                                    builder: (context, key, _) {
                                      return TableProducts(
                                        key: ValueKey<Object>(key),
                                        selectedSucursalId: _selectedSucursalId,
                                        productos: _productosFiltrados,
                                        isLoading: _isLoadingProductos,
                                        error: _errorProductos,
                                        onRetry: _limpiarFiltros,
                                        onVerDetalles: _verDetallesProducto,
                                        onVerStockDetalles: _verStockDetalles,
                                        onSort: _ordenarPor,
                                        sortBy: _sortBy,
                                        sortOrder: _order,
                                        filtrosActivos:
                                            _searchQuery.isNotEmpty ||
                                                _filtroEstadoStock != null,
                                      );
                                    }),
                              ),

                              // Paginador
                              if (_paginatedProductos != null &&
                                  _paginatedProductos!.paginacion.totalPages >
                                      0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Center(
                                    child: Paginador(
                                      paginacion:
                                          _paginatedProductos!.paginacion,
                                      onPageChanged: _cambiarPagina,
                                      onPageSizeChanged: _cambiarTamanioPagina,
                                      backgroundColor: const Color(0xFF2D2D2D),
                                      textColor: Colors.white,
                                      accentColor: const Color(0xFFE31E24),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Panel lateral de sucursales
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _drawerOpen ? 350 : 0,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                left: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
            child: _drawerOpen
                ? SlideSucursal(
                    sucursales: _sucursales,
                    sucursalSeleccionada: _selectedSucursal,
                    onSucursalSelected: _seleccionarSucursal,
                    onRecargarSucursales: _cargarSucursales,
                    isLoading: _isLoadingSucursales,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  // Widget para mostrar filtros de stock
  Widget _buildFilterChip(String label, IconData icon, Color color,
      bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        debugPrint('Iniciando tap en filtro: $label');
        debugPrint('Estado de selección actual: $selected');
        onTap();
        debugPrint('Tap completado en filtro: $label');
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              selected ? color.withValues(alpha: 0.2) : const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.3),
            width:
                selected ? 2 : 1, // Borde más grueso cuando está seleccionado
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FaIcon(
              icon,
              color: selected ? color : Colors.white70,
              size: 12,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.white70,
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
