import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/providers/admin/stock.provider.dart'
    as stock_provider;
import 'package:condorsmotors/screens/admin/widgets/slide_sucursal.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_detalle_sucursal.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_detalles_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_list.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class InventarioAdminScreen extends StatefulWidget {
  const InventarioAdminScreen({super.key});

  @override
  State<InventarioAdminScreen> createState() => _InventarioAdminScreenState();
}

class _InventarioAdminScreenState extends State<InventarioAdminScreen> {
  // Controlador para el campo de búsqueda
  final TextEditingController _searchController = TextEditingController();
  late stock_provider.StockProvider _stockProvider;
  // Estado del drawer
  bool _drawerOpen = true;

  @override
  void initState() {
    super.initState();
    // Se moverá la inicialización al didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stockProvider =
        Provider.of<stock_provider.StockProvider>(context, listen: false);
    _stockProvider.inicializar();
  }

  @override
  void dispose() {
    // Liberar recursos
    _searchController.dispose();
    super.dispose();
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
      if (_stockProvider.mostrarVistaConsolidada) {
        _stockProvider.cargarProductosTodasSucursales();
      } else if (_stockProvider.selectedSucursalId.isNotEmpty) {
        _stockProvider.cargarProductos(_stockProvider.selectedSucursalId);
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
        sucursalId: _stockProvider.selectedSucursalId,
        sucursalNombre: _stockProvider.selectedSucursalNombre,
      ),
    ).then((_) {
      // Recargar productos al cerrar el diálogo para reflejar cambios
      if (_stockProvider.mostrarVistaConsolidada) {
        _stockProvider.cargarProductosTodasSucursales();
      } else if (_stockProvider.selectedSucursalId.isNotEmpty) {
        _stockProvider.cargarProductos(_stockProvider.selectedSucursalId);
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Consumer<stock_provider.StockProvider>(
        builder: (context, stockProvider, child) {
      // Determinar qué productos usar según la vista activa
      final List<Producto> productosAMostrar =
          stockProvider.mostrarVistaConsolidada
              ? stockProvider.productosBajoStock
              : stockProvider.productosFiltrados;

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
                stockProvider.mostrarVistaConsolidada
                    ? FontAwesomeIcons.tableList
                    : FontAwesomeIcons.tableColumns,
                size: 18,
                color: stockProvider.mostrarVistaConsolidada
                    ? const Color(0xFFE31E24)
                    : Colors.white,
              ),
              onPressed: stockProvider.toggleVistaConsolidada,
              tooltip: stockProvider.mostrarVistaConsolidada
                  ? 'Ver vista individual'
                  : 'Ver vista consolidada',
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 18),
              onPressed: () {
                if (stockProvider.mostrarVistaConsolidada) {
                  stockProvider.cargarProductosTodasSucursales();
                } else {
                  stockProvider.cargarSucursales();
                  if (stockProvider.selectedSucursalId.isNotEmpty) {
                    stockProvider
                        .cargarProductos(stockProvider.selectedSucursalId);
                  }
                }
              },
              tooltip: 'Actualizar',
            ),
          ],
        ),
        body: Row(
          children: <Widget>[
            // Panel principal (75% del ancho)
            Expanded(
              flex: 75,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                                    stockProvider.mostrarVistaConsolidada
                                        ? 'Inventario Consolidado - Todas las Sucursales'
                                        : (stockProvider
                                                .selectedSucursalId.isEmpty
                                            ? 'Inventario General'
                                            : 'Inventario de ${stockProvider.selectedSucursalNombre}'),
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
                                  stockProvider.mostrarVistaConsolidada
                                      ? 'Productos con problemas de stock en todas las sucursales'
                                      : (stockProvider
                                              .selectedSucursalId.isEmpty
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
                        if (stockProvider.selectedSucursalId.isNotEmpty &&
                            !stockProvider.mostrarVistaConsolidada)
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
                                contentPadding: const EdgeInsets.symmetric(),
                              ),
                              style: const TextStyle(color: Colors.white),
                              onChanged: stockProvider.actualizarBusqueda,
                            ),
                          ),

                        const SizedBox(width: 16),
                      ],
                    ),

                    // Filtros rápidos para el estado del stock (solo en vista individual)
                    if (stockProvider.selectedSucursalId.isNotEmpty &&
                        stockProvider.productosFiltrados.isNotEmpty &&
                        !stockProvider.mostrarVistaConsolidada) ...<Widget>[
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
                              stockProvider.filtroEstadoStock ==
                                  stock_provider.StockStatus.agotado,
                              () => stockProvider.filtrarPorEstadoStock(
                                  stock_provider.StockStatus.agotado),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'Stock bajo',
                              FontAwesomeIcons.triangleExclamation,
                              const Color(0xFFE31E24),
                              stockProvider.filtroEstadoStock ==
                                  stock_provider.StockStatus.stockBajo,
                              () => stockProvider.filtrarPorEstadoStock(
                                  stock_provider.StockStatus.stockBajo),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'Disponibles',
                              FontAwesomeIcons.check,
                              Colors.green,
                              stockProvider.filtroEstadoStock ==
                                  stock_provider.StockStatus.disponible,
                              () => stockProvider.filtrarPorEstadoStock(
                                  stock_provider.StockStatus.disponible),
                            ),
                            const SizedBox(width: 16),
                            if (stockProvider.filtroEstadoStock != null)
                              IconButton(
                                icon: const FaIcon(
                                  FontAwesomeIcons.filterCircleXmark,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                onPressed: () =>
                                    stockProvider.filtrarPorEstadoStock(null),
                                tooltip: 'Limpiar filtros',
                              ),
                          ],
                        ),
                      ),
                    ],

                    // Botones de acción rápida en vista consolidada
                    if (stockProvider.mostrarVistaConsolidada &&
                        stockProvider
                            .productosBajoStock.isNotEmpty) ...<Widget>[
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
                              () => stockProvider.filtrarConsolidadoPorEstado(
                                  stock_provider.StockStatus.agotado),
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              'Ver solo stock bajo',
                              FontAwesomeIcons.triangleExclamation,
                              const Color(0xFFE31E24),
                              () => stockProvider.filtrarConsolidadoPorEstado(
                                  stock_provider.StockStatus.stockBajo),
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              'Reiniciar filtros',
                              FontAwesomeIcons.arrowsRotate,
                              Colors.blue,
                              stockProvider.reiniciarFiltrosConsolidados,
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
                        sucursalNombre: stockProvider.mostrarVistaConsolidada
                            ? 'Todas las Sucursales'
                            : stockProvider.selectedSucursalNombre,
                      ),
                    ],

                    // Tabla de productos
                    const SizedBox(height: 16),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            child: stockProvider.mostrarVistaConsolidada
                                ? TableProducts(
                                    selectedSucursalId:
                                        'todas', // Valor especial para indicar vista consolidada
                                    productos: stockProvider.productosBajoStock,
                                    isLoading: stockProvider.isLoadingProductos,
                                    error: stockProvider.errorProductos,
                                    onRetry: stockProvider.limpiarFiltros,
                                    onVerDetalles: _verDetallesProducto,
                                    onVerStockDetalles: _verStockDetalles,
                                    // Datos adicionales para la vista consolidada
                                    stockPorSucursal:
                                        stockProvider.stockPorSucursal,
                                    sucursales: stockProvider.sucursales,
                                    esVistaGlobal: true,
                                    filtrosActivos:
                                        true, // La vista global siempre tiene filtros implícitos
                                  )
                                : TableProducts(
                                    selectedSucursalId:
                                        stockProvider.selectedSucursalId,
                                    productos: stockProvider.productosFiltrados,
                                    isLoading: stockProvider.isLoadingProductos,
                                    error: stockProvider.errorProductos,
                                    onRetry: stockProvider
                                            .selectedSucursalId.isNotEmpty
                                        ? stockProvider.limpiarFiltros
                                        : null,
                                    onEditProducto: _editarProducto,
                                    onVerDetalles: _verDetallesProducto,
                                    onVerStockDetalles: _verStockDetalles,
                                    onSort: stockProvider.ordenarPor,
                                    sortBy: stockProvider.sortBy,
                                    sortOrder: stockProvider.order,
                                    // Indicar si hay filtros aplicados en esta vista
                                    filtrosActivos: stockProvider
                                            .searchQuery.isNotEmpty ||
                                        stockProvider.filtroEstadoStock != null,
                                  ),
                          ),

                          // Paginador (solo vista individual)
                          if (!stockProvider.mostrarVistaConsolidada &&
                              stockProvider.paginatedProductos != null &&
                              stockProvider.paginatedProductos!.paginacion
                                      .totalPages >
                                  0)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                        'Mostrando ${stockProvider.productosFiltrados.length} de ${stockProvider.paginatedProductos!.paginacion.totalItems} productos',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Paginador
                                  Paginador(
                                    paginacion: stockProvider
                                        .paginatedProductos!.paginacion,
                                    onPageChanged: stockProvider.cambiarPagina,
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
                                      _buildPageSizeDropdown(stockProvider),
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
            ),

            // Panel lateral de sucursales
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _drawerOpen ? MediaQuery.of(context).size.width * 0.25 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border(
                  left: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              child: _drawerOpen
                  ? SlideSucursal(
                      sucursales: stockProvider.sucursales,
                      sucursalSeleccionada: stockProvider.selectedSucursal,
                      onSucursalSelected: stockProvider.seleccionarSucursal,
                      onRecargarSucursales: stockProvider.cargarSucursales,
                      isLoading: stockProvider.isLoadingSucursales,
                    )
                  : null,
            ),
          ],
        ),
      );
    });
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

  Widget _buildPageSizeDropdown(stock_provider.StockProvider stockProvider) {
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
          value: stockProvider.pageSize,
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
              stockProvider.cambiarTamanioPagina(value);
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
