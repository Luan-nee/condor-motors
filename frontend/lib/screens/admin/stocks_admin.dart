import 'package:condorsmotors/main.dart' show api; // API global
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/screens/admin/widgets/slide_sucursal.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_detalle_sucursal.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_detalles_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_list.dart';
import 'package:condorsmotors/utils/stock_utils.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class InventarioAdminScreen extends StatefulWidget {
  const InventarioAdminScreen({super.key});

  @override
  State<InventarioAdminScreen> createState() => _InventarioAdminScreenState();
}

class _InventarioAdminScreenState extends State<InventarioAdminScreen> {
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

  // Controlador para el campo de búsqueda
  final TextEditingController _searchController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _cargarSucursales();
  }

  @override
  void dispose() {
    // Liberar recursos
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarSucursales() async {
    setState(() {
      _isLoadingSucursales = true;
    });

    try {
      final List<Sucursal> sucursales = await api.sucursales.getSucursales();
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
        _productosFiltrados = <Producto>[];
      });
      return;
    }

    setState(() {
      _isLoadingProductos = true;
      _errorProductos = null;
    });

    try {
      // Aplicar la búsqueda del servidor sólo si la búsqueda es mayor a 3 caracteres
      final String? searchQuery =
          _searchQuery.length >= 3 ? _searchQuery : null;

      // Si está seleccionado el filtro de stock bajo, usar el método específico
      if (_filtroEstadoStock == StockStatus.stockBajo) {
        final PaginatedResponse<Producto> paginatedProductos =
            await api.productos.getProductosConStockBajo(
          sucursalId: sucursalId,
          page: _currentPage,
          pageSize: _pageSize,
          sortBy: _sortBy.isNotEmpty ? _sortBy : 'nombre',
        );

        setState(() {
          _paginatedProductos = paginatedProductos;
          _productosFiltrados = paginatedProductos.items;
          _isLoadingProductos = false;
        });

        // Mostrar mensaje si no hay productos
        if (paginatedProductos.items.isEmpty) {
          _mostrarMensajeNoProductos(
              'No se encontraron productos con stock bajo');
        }

        return;
      }

      // Si está seleccionado el filtro de agotados, usamos el método específico
      if (_filtroEstadoStock == StockStatus.agotado) {
        final PaginatedResponse<Producto> paginatedProductos =
            await api.productos.getProductosAgotados(
          sucursalId: sucursalId,
          page: _currentPage,
          pageSize: _pageSize,
          sortBy: _sortBy.isNotEmpty ? _sortBy : 'nombre',
        );

        setState(() {
          _paginatedProductos = paginatedProductos;
          _productosFiltrados = paginatedProductos.items;
          _isLoadingProductos = false;
        });

        // Mostrar mensaje si no hay productos
        if (paginatedProductos.items.isEmpty) {
          _mostrarMensajeNoProductos('No se encontraron productos agotados');
        }

        return;
      }

      // Para otros casos, usar el método general
      final PaginatedResponse<Producto> paginatedProductos =
          await api.productos.getProductos(
        sucursalId: sucursalId,
        search: searchQuery,
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: _sortBy.isNotEmpty ? _sortBy : null,
        order: _order,
        // Si filtro es disponible, enviamos stockBajo=false
        stockBajo: _filtroEstadoStock == StockStatus.disponible ? false : null,
      );

      // Reorganizar los productos según la prioridad de stock
      final List<Producto> productosReorganizados =
          StockUtils.reorganizarProductosPorPrioridad(paginatedProductos.items);

      setState(() {
        _paginatedProductos = paginatedProductos;
        // Actualizamos los productos filtrados con la nueva organización
        _productosFiltrados = productosReorganizados;
        _isLoadingProductos = false;
      });

      // Mostrar mensaje si no hay productos y hay filtros aplicados
      if (productosReorganizados.isEmpty &&
          (_searchQuery.isNotEmpty || _filtroEstadoStock != null)) {
        _mostrarMensajeNoProductos(
            'No se encontraron productos que coincidan con los filtros aplicados');
      }
    } catch (e) {
      setState(() {
        _errorProductos = e.toString();
        _isLoadingProductos = false;
      });
    }
  }

  // Método para mostrar un snackbar con mensaje cuando no hay productos
  void _mostrarMensajeNoProductos(String mensaje) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mensaje,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF444444),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Limpiar filtros',
            textColor: const Color(0xFFE31E24),
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _filtroEstadoStock = null;
                _currentPage = 1;
              });
              _cargarProductos(_selectedSucursalId);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    });
  }

  // Método para cargar productos con problemas de stock de todas las sucursales
  Future<void> _cargarProductosTodasSucursales() async {
    if (_sucursales.isEmpty) {
      setState(() {
        _productosBajoStock = <Producto>[];
      });
      return;
    }

    setState(() {
      _isLoadingProductos = true;
      _errorProductos = null;
      _stockPorSucursal.clear(); // Reiniciar el mapa para evitar datos antiguos
    });

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
          StockUtils.consolidarProductosUnicos(todosProductos);

      // Priorizar productos con problemas más graves
      final List<Producto> productosPrioritarios =
          StockUtils.reorganizarProductosPorPrioridad(
        productosUnicos,
        stockPorSucursal: _stockPorSucursal,
        sucursales: _sucursales,
      );

      setState(() {
        _productosBajoStock = productosPrioritarios;
        _isLoadingProductos = false;
      });
    } catch (e) {
      setState(() {
        _errorProductos = e.toString();
        _isLoadingProductos = false;
      });
    }
  }

  // Método auxiliar para cargar productos con stock bajo de una sucursal
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

  // Método para cargar todos los productos de una sucursal que cumplan una condición específica
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
          respuesta = await api.productos.getProductosConStockBajo(
            sucursalId: sucursal.id,
            page: paginaActual,
            pageSize: tamanioPagina,
          );
        } else if (condicion == 'agotados') {
          // Para los agotados ahora usamos el método específico
          respuesta = await api.productos.getProductosAgotados(
            sucursalId: sucursal.id,
            page: paginaActual,
            pageSize: tamanioPagina,
          );
        } else {
          // Por defecto, traemos todos los productos
          respuesta = await api.productos.getProductos(
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

  // Procesar productos por sucursal y almacenar en mapa consolidado
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
      builder: (BuildContext context) => StockDetalleSucursalDialog(
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
      builder: (BuildContext context) => StockDetallesDialog(
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

  void _toggleVistaConsolidada() {
    setState(() {
      _mostrarVistaConsolidada = !_mostrarVistaConsolidada;
    });
    if (_mostrarVistaConsolidada) {
      _cargarProductosTodasSucursales();
    } else {
      _cargarSucursales();
      if (_selectedSucursalId.isNotEmpty) {
        _cargarProductos(_selectedSucursalId);
      }
    }
  }

  // Filtrar los productos en la vista consolidada por estado
  void _filtrarConsolidadoPorEstado(StockStatus estado) {
    setState(() {
      // Si ya tenemos todos los productos cargados, simplemente filtramos
      _productosBajoStock =
          StockUtils.filtrarPorEstadoStock(_productosBajoStock, estado);
    });

    // Mostrar mensaje si no hay productos de este tipo
    if (_productosBajoStock.isEmpty) {
      _mostrarMensajeNoProductos(
          'No se encontraron productos ${estado == StockStatus.agotado ? 'agotados' : 'con stock bajo'} en ninguna sucursal');
      _reiniciarFiltrosConsolidados(); // Reiniciar si no hay productos
    }
  }

  // Reiniciar filtros en la vista consolidada
  void _reiniciarFiltrosConsolidados() {
    _cargarProductosTodasSucursales(); // Volver a cargar todos los productos
  }

  // Widget para botones de acción rápida
  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      icon: FaIcon(
        icon,
        color: Colors.white,
        size: 14,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
      ),
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // Método para limpiar todos los filtros aplicados
  void _limpiarFiltros() {
    debugPrint(
        'Ejecutando _limpiarFiltros() - Limpiando todos los filtros aplicados');

    // Limpiar campo de búsqueda físicamente si existe un controlador de texto
    _searchController.clear();

    setState(() {
      _searchQuery = '';
      _filtroEstadoStock = null;
      _currentPage = 1;
    });

    debugPrint('Filtros limpiados. Recargando productos...');

    // Recargar productos sin filtros
    if (_mostrarVistaConsolidada) {
      _cargarProductosTodasSucursales();
    } else if (_selectedSucursalId.isNotEmpty) {
      _cargarProductos(_selectedSucursalId);
    }

    // Mostrar mensaje confirmando que los filtros fueron limpiados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Filtros restablecidos'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Organizar productos por estado para el resumen

    // Determinar qué productos usar según la vista activa
    final List<Producto> productosAMostrar =
        _mostrarVistaConsolidada ? _productosBajoStock : _productosFiltrados;

    if (productosAMostrar.isNotEmpty) {}

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Inventario'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: <Widget>[
          // Botón para activar/desactivar vista consolidada
          IconButton(
            icon: Icon(
              _mostrarVistaConsolidada
                  ? FontAwesomeIcons.tableList
                  : FontAwesomeIcons.tableColumns,
              size: 18,
              color: _mostrarVistaConsolidada
                  ? const Color(0xFFE31E24)
                  : Colors.white,
            ),
            onPressed: _toggleVistaConsolidada,
            tooltip: _mostrarVistaConsolidada
                ? 'Ver vista individual'
                : 'Ver vista consolidada',
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
          children: <Widget>[
            // Área principal (75% del ancho)
            Expanded(
              flex: 75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Título y estadísticas
                  Row(
                    children: <Widget>[
                      // Título
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
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
                            controller: _searchController,
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
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0, // Espaciado horizontal
                                vertical: 12.0, // Espaciado vertical
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (String value) {
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
                      !_mostrarVistaConsolidada) ...<Widget>[
                    const SizedBox(height: 16),
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

                  // Botones de acción rápida en vista consolidada
                  if (_mostrarVistaConsolidada &&
                      _productosBajoStock.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <Widget>[
                          const Text(
                            'Acciones rápidas: ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            'Ver solo agotados',
                            FontAwesomeIcons.ban,
                            Colors.red.shade800,
                            () => _filtrarConsolidadoPorEstado(
                                StockStatus.agotado),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            'Ver solo stock bajo',
                            FontAwesomeIcons.triangleExclamation,
                            const Color(0xFFE31E24),
                            () => _filtrarConsolidadoPorEstado(
                                StockStatus.stockBajo),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            'Reiniciar filtros',
                            FontAwesomeIcons.arrowsRotate,
                            Colors.blue,
                            _reiniciarFiltrosConsolidados,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Resumen del inventario
                  if (productosAMostrar.isNotEmpty) ...<Widget>[
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
                      children: <Widget>[
                        Expanded(
                          child: _mostrarVistaConsolidada
                              ? TableProducts(
                                  selectedSucursalId:
                                      'todas', // Valor especial para indicar vista consolidada
                                  productos: _productosBajoStock,
                                  isLoading: _isLoadingProductos,
                                  error: _errorProductos,
                                  onRetry: _limpiarFiltros,
                                  onVerDetalles: _verDetallesProducto,
                                  onVerStockDetalles: _verStockDetalles,
                                  // Datos adicionales para la vista consolidada
                                  stockPorSucursal: _stockPorSucursal,
                                  sucursales: _sucursales,
                                  esVistaGlobal: true,
                                  filtrosActivos:
                                      true, // La vista global siempre tiene filtros implícitos
                                )
                              : TableProducts(
                                  selectedSucursalId: _selectedSucursalId,
                                  productos: _productosFiltrados,
                                  isLoading: _isLoadingProductos,
                                  error: _errorProductos,
                                  onRetry: _selectedSucursalId.isNotEmpty
                                      ? _limpiarFiltros
                                      : null,
                                  onEditProducto: _editarProducto,
                                  onVerDetalles: _verDetallesProducto,
                                  onVerStockDetalles: _verStockDetalles,
                                  onSort: _ordenarPor,
                                  sortBy: _sortBy,
                                  sortOrder: _order,
                                  // Indicar si hay filtros aplicados en esta vista
                                  filtrosActivos: _searchQuery.isNotEmpty ||
                                      _filtroEstadoStock != null,
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
                              children: <Widget>[
                                // Info de cantidad
                                Row(
                                  children: <Widget>[
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
                                  children: <Widget>[
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

            // SlideSucursal a la derecha (25% del ancho)
            Expanded(
              flex: 25,
              child: _mostrarVistaConsolidada
                  ? SlideSucursal(
                      sucursales: _sucursales,
                      sucursalSeleccionada: null,
                      onSucursalSelected: _onSucursalSeleccionada,
                      onRecargarSucursales: _cargarSucursales,
                      isLoading: _isLoadingSucursales,
                    )
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

  // Widget para mostrar filtros de stock
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

  Widget _buildPageSizeDropdown() {
    final List<int> options = <int>[10, 20, 50, 100];

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
          items: options.map((int size) {
            return DropdownMenuItem<int>(
              value: size,
              child: Text(
                size.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (int? value) {
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
