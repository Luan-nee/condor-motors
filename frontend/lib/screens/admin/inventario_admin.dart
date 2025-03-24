import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../main.dart' show api; // API global
import '../../models/paginacion.model.dart';
import '../../models/producto.model.dart';
import '../../models/sucursal.model.dart';
import '../../widgets/paginador.dart';
import 'utils/stock_utils.dart';
import 'widgets/slide_sucursal.dart';
import 'widgets/stock_detalle_sucursal.dart';
import 'widgets/stock_detalles_dialog.dart';
import 'widgets/stock_list.dart';

class InventarioAdminScreen extends StatefulWidget {
  const InventarioAdminScreen({super.key});

  @override
  State<InventarioAdminScreen> createState() => _InventarioAdminScreenState();
}

class _InventarioAdminScreenState extends State<InventarioAdminScreen> {
  // Estado
  String _selectedSucursalId = '';
  String _selectedSucursalNombre = '';
  List<Sucursal> _sucursales = [];
  Sucursal? _selectedSucursal;
  PaginatedResponse<Producto>? _paginatedProductos;
  List<Producto> _productosFiltrados = [];
  bool _isLoadingSucursales = true;
  bool _isLoadingProductos = false;
  String? _errorProductos;

  // Nuevo: Productos consolidados de todas las sucursales
  Map<int, Map<String, int>> _stockPorSucursal =
      {}; // productoId -> {sucursalId -> stock}
  List<Producto> _productosBajoStock =
      []; // Productos con problemas en cualquier sucursal
  bool _isLoadingConsolidado = false;

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

  @override
  void initState() {
    super.initState();
    _cargarSucursales();
  }

  Future<void> _cargarSucursales() async {
    setState(() {
      _isLoadingSucursales = true;
    });

    try {
      final sucursales = await api.sucursales.getSucursales();
      setState(() {
        _sucursales = sucursales;
        _isLoadingSucursales = false;
      });

      // Seleccionar automáticamente la primera sucursal si hay sucursales disponibles
      if (sucursales.isNotEmpty && _selectedSucursalId.isEmpty) {
        _onSucursalSeleccionada(sucursales.first);
      }
    } catch (e) {
      setState(() {
        _isLoadingSucursales = false;
      });
    }
  }

  // Método para cargar productos de la sucursal seleccionada (vista individual)
  Future<void> _cargarProductos(String sucursalId) async {
    if (sucursalId.isEmpty) {
      setState(() {
        _paginatedProductos = null;
        _productosFiltrados = [];
      });
      return;
    }

    setState(() {
      _isLoadingProductos = true;
      _errorProductos = null;
    });

    try {
      // Aplicar la búsqueda del servidor sólo si la búsqueda es mayor a 3 caracteres
      final searchQuery = _searchQuery.length >= 3 ? _searchQuery : null;

      final paginatedProductos = await api.productos.getProductos(
        sucursalId: sucursalId,
        search: searchQuery,
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: _sortBy.isNotEmpty ? _sortBy : null,
        order: _order,
      );

      // Reorganizar los productos según la prioridad de stock
      List<Producto> productosReorganizados =
          StockUtils.reorganizarProductosPorPrioridad(paginatedProductos.items);

      // Aplicar filtro por estado de stock si está seleccionado
      if (_filtroEstadoStock != null) {
        final grupos =
            StockUtils.agruparProductosPorEstadoStock(productosReorganizados);
        productosReorganizados = grupos[_filtroEstadoStock]!;
      }

      setState(() {
        _paginatedProductos = paginatedProductos;
        // Actualizamos los productos filtrados con la nueva organización
        _productosFiltrados = productosReorganizados;
        _isLoadingProductos = false;
      });
    } catch (e) {
      setState(() {
        _errorProductos = e.toString();
        _isLoadingProductos = false;
      });
    }
  }

  // NUEVO: Método para cargar productos de todas las sucursales y consolidar información
  Future<void> _cargarProductosTodasSucursales() async {
    if (_sucursales.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingConsolidado = true;
      _errorProductos = null;
      _stockPorSucursal = {};
      _productosBajoStock = [];
    });

    try {
      // Lista para almacenar todos los productos encontrados
      final List<Producto> todosProductos = [];

      // Para cada sucursal, cargar todos los productos (todas las páginas)
      final sucursalesFutures = <Future>[];
      for (final sucursal in _sucursales) {
        sucursalesFutures
            .add(_cargarTodosProductosSucursal(sucursal, todosProductos));
      }

      // Esperamos a que se completen todas las cargas de sucursales
      await Future.wait(sucursalesFutures);

      // Filtrar productos con problemas y eliminar duplicados
      _productosBajoStock =
          StockUtils.filtrarProductosConProblemasStock(todosProductos);
      _productosBajoStock =
          StockUtils.consolidarProductosUnicos(_productosBajoStock);

      // Ordenar por prioridad (agotados primero, luego stock bajo)
      _productosBajoStock =
          StockUtils.reorganizarProductosPorPrioridad(_productosBajoStock);

      setState(() {
        _isLoadingConsolidado = false;
      });
    } catch (e) {
      setState(() {
        _errorProductos = e.toString();
        _isLoadingConsolidado = false;
      });
    }
  }

  // Método auxiliar para cargar todos los productos de una sucursal (todas las páginas)
  Future<void> _cargarTodosProductosSucursal(
      Sucursal sucursal, List<Producto> todosProductos) async {
    try {
      // Primero obtenemos la primera página para saber cuántas páginas hay en total
      final primeraPagina = await api.productos.getProductos(
        sucursalId: sucursal.id,
        page: 1,
        pageSize:
            50, // Usamos un tamaño grande para reducir el número de peticiones
      );

      // Procesamos la primera página
      _procesarProductosPorSucursal(primeraPagina.items, sucursal);

      // Añadimos los productos a la lista general
      todosProductos.addAll(primeraPagina.items);

      // Calculamos cuántas páginas hay en total
      final totalPages = primeraPagina.paginacion.totalPages;

      // Si hay más de una página, cargamos el resto
      if (totalPages > 1) {
        final futures = <Future>[];

        // Empezamos desde la página 2 ya que la 1 ya la cargamos
        for (int pagina = 2; pagina <= totalPages; pagina++) {
          futures.add(_cargarPaginaSucursal(pagina, sucursal, todosProductos));
        }

        // Esperamos a que todas las peticiones terminen
        await Future.wait(futures);
      }
    } catch (e) {
      debugPrint(
          'Error al cargar productos de sucursal ${sucursal.nombre}: $e');
    }
  }

  // Método para cargar una página específica de una sucursal
  Future<void> _cargarPaginaSucursal(
      int pagina, Sucursal sucursal, List<Producto> todosProductos) async {
    try {
      final paginaProductos = await api.productos.getProductos(
        sucursalId: sucursal.id,
        page: pagina,
        pageSize: 50,
      );

      _procesarProductosPorSucursal(paginaProductos.items, sucursal);

      // Añadimos los productos a la lista general
      todosProductos.addAll(paginaProductos.items);
    } catch (e) {
      debugPrint(
          'Error al cargar página $pagina de sucursal ${sucursal.nombre}: $e');
    }
  }

  // Procesar productos por sucursal y almacenar en mapa consolidado
  void _procesarProductosPorSucursal(
      List<Producto> productos, Sucursal sucursal) {
    for (final producto in productos) {
      // Si es la primera vez que vemos este producto, inicializamos su mapa
      if (!_stockPorSucursal.containsKey(producto.id)) {
        _stockPorSucursal[producto.id] = {};
      }

      // Guardamos el stock de este producto en esta sucursal
      _stockPorSucursal[producto.id]![sucursal.id] = producto.stock;
    }
  }

  // Método para activar/desactivar la vista consolidada
  void _toggleVistaConsolidada() {
    setState(() {
      _mostrarVistaConsolidada = !_mostrarVistaConsolidada;
    });

    if (_mostrarVistaConsolidada) {
      _cargarProductosTodasSucursales();
    } else {
      // Volver a la vista individual
      if (_selectedSucursalId.isNotEmpty) {
        _cargarProductos(_selectedSucursalId);
      }
    }
  }

  // Método para cambiar de página
  void _cambiarPagina(int pagina) {
    if (_currentPage != pagina) {
      setState(() {
        _currentPage = pagina;
      });
      _cargarProductos(_selectedSucursalId);
    }
  }

  // Método para cambiar tamaño de página
  void _cambiarTamanioPagina(int tamanio) {
    if (_pageSize != tamanio) {
      setState(() {
        _pageSize = tamanio;
        _currentPage = 1; // Volvemos a la primera página al cambiar el tamaño
      });
      _cargarProductos(_selectedSucursalId);
    }
  }

  // Método para ordenar por un campo
  void _ordenarPor(String campo) {
    setState(() {
      if (_sortBy == campo) {
        // Si ya estamos ordenando por este campo, cambiamos la dirección
        _order = _order == 'asc' ? 'desc' : 'asc';
      } else {
        _sortBy = campo;
        _order = 'desc'; // Por defecto ordenamos descendente
      }
      _currentPage = 1; // Volvemos a la primera página al cambiar el orden
    });
    _cargarProductos(_selectedSucursalId);
  }

  // Método para filtrar por estado de stock
  void _filtrarPorEstadoStock(StockStatus? estado) {
    setState(() {
      if (_filtroEstadoStock == estado) {
        // Si hacemos clic en el mismo filtro, lo quitamos
        _filtroEstadoStock = null;
      } else {
        _filtroEstadoStock = estado;
      }
      _currentPage = 1; // Volvemos a la primera página al cambiar el filtro
    });
    _cargarProductos(_selectedSucursalId);
  }

  void _onSucursalSeleccionada(Sucursal sucursal) {
    setState(() {
      _selectedSucursalId = sucursal.id;
      _selectedSucursalNombre = sucursal.nombre;
      _selectedSucursal = sucursal;
      _currentPage = 1; // Volver a la primera página al cambiar de sucursal
      _filtroEstadoStock = null; // Resetear filtro al cambiar de sucursal
      _mostrarVistaConsolidada =
          false; // Desactivar vista consolidada al cambiar de sucursal
    });
    _cargarProductos(sucursal.id);
  }

  void _verDetallesProducto(Producto producto) {
    showDialog(
      context: context,
      builder: (context) => StockDetalleSucursalDialog(
        producto: producto,
      ),
    ).then((_) {
      // Recargar productos al cerrar el diálogo para reflejar posibles cambios
      if (_mostrarVistaConsolidada) {
        _cargarProductosTodasSucursales();
      } else if (_selectedSucursalId.isNotEmpty) {
        _cargarProductos(_selectedSucursalId);
      }
    });
  }

  void _editarProducto(Producto producto) {
    debugPrint('Editar producto: ${producto.nombre}');
  }

  void _verStockDetalles(Producto producto) {
    showDialog(
      context: context,
      builder: (context) => StockDetallesDialog(
        producto: producto,
        sucursalId: _selectedSucursalId,
        sucursalNombre: _selectedSucursalNombre,
      ),
    ).then((_) {
      // Recargar productos al cerrar el diálogo para reflejar cambios
      if (_mostrarVistaConsolidada) {
        _cargarProductosTodasSucursales();
      } else if (_selectedSucursalId.isNotEmpty) {
        _cargarProductos(_selectedSucursalId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Organizar productos por estado para el resumen
    Map<StockStatus, List<Producto>> productosAgrupados = {};

    // Determinar qué productos usar según la vista activa
    final List<Producto> productosAMostrar =
        _mostrarVistaConsolidada ? _productosBajoStock : _productosFiltrados;

    if (productosAMostrar.isNotEmpty) {
      productosAgrupados =
          StockUtils.agruparProductosPorEstadoStock(productosAMostrar);
    }

    // Contar productos por estado
    final agotadosCount = productosAgrupados[StockStatus.agotado]?.length ?? 0;
    final stockBajoCount =
        productosAgrupados[StockStatus.stockBajo]?.length ?? 0;

    // Determinar si hay problemas críticos en el inventario
    final hayProblemasInventario = agotadosCount > 0 || stockBajoCount > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Inventario'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          // Botón para alternar entre vista individual y consolidada
          IconButton(
            icon: FaIcon(
              _mostrarVistaConsolidada
                  ? FontAwesomeIcons.building
                  : FontAwesomeIcons.buildingColumns,
              size: 18,
            ),
            onPressed: _toggleVistaConsolidada,
            tooltip: _mostrarVistaConsolidada
                ? 'Ver sucursal individual'
                : 'Ver todas las sucursales',
          ),

          // Mostrar badge si hay problemas de inventario
          if (hayProblemasInventario)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.bell, size: 18),
                  onPressed: () {
                    // Mostrar notificación de problemas de inventario
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Hay $agotadosCount productos agotados y $stockBajoCount con stock bajo'),
                        backgroundColor: const Color(0xFFE31E24),
                        duration: const Duration(seconds: 5),
                        action: SnackBarAction(
                          label: 'Ver',
                          textColor: Colors.white,
                          onPressed: () {
                            // Filtrar para mostrar solo los problemáticos
                            if (!_mostrarVistaConsolidada) {
                              _filtrarPorEstadoStock(StockStatus.agotado);
                            }
                          },
                        ),
                      ),
                    );
                  },
                  tooltip: 'Problemas de inventario',
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE31E24),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      (agotadosCount + stockBajoCount).toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 18),
            onPressed: () {
              if (_mostrarVistaConsolidada) {
                _cargarProductosTodasSucursales();
              } else {
                _cargarSucursales();
                if (_selectedSucursalId.isNotEmpty) {
                  _cargarProductos(_selectedSucursalId);
                }
              }
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Área principal (75% del ancho)
            Expanded(
              flex: 75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y estadísticas
                  Row(
                    children: [
                      // Título
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.warehouse,
                                  size: 18,
                                  color: Color(0xFFE31E24),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _mostrarVistaConsolidada
                                      ? 'Inventario Consolidado - Todas las Sucursales'
                                      : (_selectedSucursalId.isEmpty
                                          ? 'Inventario General'
                                          : 'Inventario de $_selectedSucursalNombre'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 28),
                              child: Text(
                                _mostrarVistaConsolidada
                                    ? 'Productos con problemas de stock en todas las sucursales'
                                    : (_selectedSucursalId.isEmpty
                                        ? 'Seleccione una sucursal para ver su inventario'
                                        : 'Gestión de stock y productos'),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Barra de búsqueda (solo en vista individual)
                      if (_selectedSucursalId.isNotEmpty &&
                          !_mostrarVistaConsolidada)
                        SizedBox(
                          width: 300,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar productos...',
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.4)),
                              filled: true,
                              fillColor: const Color(0xFF232323),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(),
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;

                                // Si la búsqueda es mayor a 3 caracteres o está vacía, hacer solicitud al servidor
                                if (value.length >= 3 || value.isEmpty) {
                                  _currentPage =
                                      1; // Reiniciar a la primera página
                                  _cargarProductos(_selectedSucursalId);
                                }
                              });
                            },
                          ),
                        ),

                      const SizedBox(width: 16),
                    ],
                  ),

                  // Filtros rápidos para el estado del stock (solo en vista individual)
                  if (_selectedSucursalId.isNotEmpty &&
                      _productosFiltrados.isNotEmpty &&
                      !_mostrarVistaConsolidada) ...[
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text(
                            'Filtrar por: ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Agotados',
                            FontAwesomeIcons.ban,
                            Colors.red.shade800,
                            _filtroEstadoStock == StockStatus.agotado,
                            () => _filtrarPorEstadoStock(StockStatus.agotado),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Stock bajo',
                            FontAwesomeIcons.triangleExclamation,
                            const Color(0xFFE31E24),
                            _filtroEstadoStock == StockStatus.stockBajo,
                            () => _filtrarPorEstadoStock(StockStatus.stockBajo),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Disponibles',
                            FontAwesomeIcons.check,
                            Colors.green,
                            _filtroEstadoStock == StockStatus.disponible,
                            () =>
                                _filtrarPorEstadoStock(StockStatus.disponible),
                          ),
                          const SizedBox(width: 16),
                          if (_filtroEstadoStock != null)
                            IconButton(
                              icon: const FaIcon(
                                FontAwesomeIcons.filterCircleXmark,
                                color: Colors.white70,
                                size: 16,
                              ),
                              onPressed: () => _filtrarPorEstadoStock(null),
                              tooltip: 'Limpiar filtros',
                            ),
                        ],
                      ),
                    ),
                  ],

                  // Resumen del inventario
                  if (productosAMostrar.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    InventarioResumen(
                      productos: productosAMostrar,
                      sucursalNombre: _mostrarVistaConsolidada
                          ? 'Todas las Sucursales'
                          : _selectedSucursalNombre,
                    ),
                  ],

                  // Tabla de productos
                  const SizedBox(height: 16),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: _mostrarVistaConsolidada
                              ? TableProducts(
                                  selectedSucursalId:
                                      'todas', // Valor especial para indicar vista consolidada
                                  productos: _productosBajoStock,
                                  isLoading: _isLoadingConsolidado,
                                  error: _errorProductos,
                                  onRetry: () =>
                                      _cargarProductosTodasSucursales(),
                                  onVerDetalles: _verDetallesProducto,
                                  onVerStockDetalles: _verStockDetalles,
                                  // Datos adicionales para la vista consolidada
                                  stockPorSucursal: _stockPorSucursal,
                                  sucursales: _sucursales,
                                  esVistaGlobal: true,
                                )
                              : TableProducts(
                                  selectedSucursalId: _selectedSucursalId,
                                  productos: _productosFiltrados,
                                  isLoading: _isLoadingProductos,
                                  error: _errorProductos,
                                  onRetry: _selectedSucursalId.isNotEmpty
                                      ? () =>
                                          _cargarProductos(_selectedSucursalId)
                                      : null,
                                  onEditProducto: _editarProducto,
                                  onVerDetalles: _verDetallesProducto,
                                  onVerStockDetalles: _verStockDetalles,
                                  onSort: _ordenarPor,
                                  sortBy: _sortBy,
                                  sortOrder: _order,
                                ),
                        ),

                        // Paginador (solo vista individual)
                        if (!_mostrarVistaConsolidada &&
                            _paginatedProductos != null &&
                            _paginatedProductos!.paginacion.totalPages > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Info de cantidad
                                Row(
                                  children: [
                                    const FaIcon(
                                      FontAwesomeIcons.layerGroup,
                                      size: 14,
                                      color: Colors.white54,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Mostrando ${_productosFiltrados.length} de ${_paginatedProductos!.paginacion.totalItems} productos',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),

                                // Paginador
                                Paginador(
                                  paginacion: _paginatedProductos!.paginacion,
                                  onPageChanged: _cambiarPagina,
                                ),

                                // Selector de tamaño de página
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const FaIcon(
                                      FontAwesomeIcons.tableList,
                                      size: 14,
                                      color: Colors.white54,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Mostrar:',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildPageSizeDropdown(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // SlideSucursal a la derecha (25% del ancho) - solo en vista individual
            Expanded(
              flex: 25,
              child: _mostrarVistaConsolidada
                  ? _buildConsolidatedSidebar()
                  : SlideSucursal(
                      sucursales: _sucursales,
                      sucursalSeleccionada: _selectedSucursal,
                      onSucursalSelected: _onSucursalSeleccionada,
                      onRecargarSucursales: _cargarSucursales,
                      isLoading: _isLoadingSucursales,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar la barra lateral en vista consolidada
  Widget _buildConsolidatedSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.buildingColumns,
                    size: 16,
                    color: Color(0xFFE31E24),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Sucursales',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_sucursales.length} sucursales',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Estás viendo la información consolidada de stock de todas las sucursales, con foco en los productos que requieren atención.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const FaIcon(
                  FontAwesomeIcons.rotate,
                  size: 14,
                ),
                label: const Text('Actualizar datos'),
                onPressed: _cargarProductosTodasSucursales,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE31E24),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const FaIcon(
                  FontAwesomeIcons.building,
                  size: 14,
                ),
                label: const Text('Volver a vista individual'),
                onPressed: _toggleVistaConsolidada,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: _sucursales.length,
              itemBuilder: (context, index) {
                final sucursal = _sucursales[index];
                return ListTile(
                  title: Text(
                    sucursal.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    sucursal.direccion,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF1A1A1A),
                    child: FaIcon(
                      FontAwesomeIcons.store,
                      color: Color(0xFFE31E24),
                      size: 16,
                    ),
                  ),
                  onTap: () => _onSucursalSeleccionada(sucursal),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, IconData icon, Color color,
      bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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

  Widget _buildPageSizeDropdown() {
    final options = [10, 20, 50, 100];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _pageSize,
          items: options.map((size) {
            return DropdownMenuItem<int>(
              value: size,
              child: Text(
                size.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _cambiarTamanioPagina(value);
            }
          },
          icon: const FaIcon(
            FontAwesomeIcons.chevronDown,
            color: Colors.white,
            size: 14,
          ),
          style: const TextStyle(color: Colors.white),
          dropdownColor: const Color(0xFF2D2D2D),
        ),
      ),
    );
  }
}
