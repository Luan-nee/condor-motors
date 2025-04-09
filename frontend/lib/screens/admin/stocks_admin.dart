import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/providers/admin/stock.admin.provider.dart'
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
  final bool _drawerOpen = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // No inicializamos aquí, lo haremos en didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _stockProvider =
          Provider.of<stock_provider.StockProvider>(context, listen: false);
      // Inicializar de manera asíncrona
      Future<void>.microtask(() async {
        await _stockProvider.inicializar();
      });
      _isInitialized = true;
    }
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
                          color: Colors.white.withOpacity(0.1),
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
                              if (stockProvider.selectedSucursal !=
                                  null) ...<Widget>[
                                const Text(
                                  ' / ',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white54,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    stockProvider.selectedSucursal!.nombre,
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
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
                          // Filtros rápidos para el estado del stock
                          if (stockProvider.selectedSucursalId.isNotEmpty &&
                              stockProvider.productosFiltrados.isNotEmpty &&
                              !stockProvider
                                  .mostrarVistaConsolidada) ...<Widget>[
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
                                    stockProvider.filtroEstadoStock ==
                                        stock_provider.StockStatus.disponible,
                                    () => stockProvider.filtrarPorEstadoStock(
                                        stock_provider.StockStatus.disponible),
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
                                    'Agotados',
                                    FontAwesomeIcons.ban,
                                    Colors.red.shade800,
                                    stockProvider.filtroEstadoStock ==
                                        stock_provider.StockStatus.agotado,
                                    () => stockProvider.filtrarPorEstadoStock(
                                        stock_provider.StockStatus.agotado),
                                  ),
                                  const SizedBox(width: 16),
                                  if (stockProvider.filtroEstadoStock != null)
                                    IconButton(
                                      icon: const FaIcon(
                                        FontAwesomeIcons.filterCircleXmark,
                                        color: Colors.white70,
                                        size: 16,
                                      ),
                                      onPressed: () => stockProvider
                                          .filtrarPorEstadoStock(null),
                                      tooltip: 'Limpiar filtros',
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Resumen del inventario
                          if (productosAMostrar.isNotEmpty) ...<Widget>[
                            InventarioResumen(
                              productos: productosAMostrar,
                              sucursalNombre:
                                  stockProvider.mostrarVistaConsolidada
                                      ? 'Todas las Sucursales'
                                      : stockProvider.selectedSucursalNombre,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Tabla de productos
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                Expanded(
                                  child: stockProvider.mostrarVistaConsolidada
                                      ? TableProducts(
                                          selectedSucursalId: 'todas',
                                          productos:
                                              stockProvider.productosBajoStock,
                                          isLoading:
                                              stockProvider.isLoadingProductos,
                                          error: stockProvider.errorProductos,
                                          onRetry: stockProvider.limpiarFiltros,
                                          onVerDetalles: _verDetallesProducto,
                                          onVerStockDetalles: _verStockDetalles,
                                          stockPorSucursal:
                                              stockProvider.stockPorSucursal,
                                          sucursales: stockProvider.sucursales,
                                          esVistaGlobal: true,
                                          filtrosActivos: true,
                                        )
                                      : TableProducts(
                                          selectedSucursalId:
                                              stockProvider.selectedSucursalId,
                                          productos:
                                              stockProvider.productosFiltrados,
                                          isLoading:
                                              stockProvider.isLoadingProductos,
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
                                          filtrosActivos: stockProvider
                                                  .searchQuery.isNotEmpty ||
                                              stockProvider.filtroEstadoStock !=
                                                  null,
                                        ),
                                ),

                                // Paginador
                                if (!stockProvider.mostrarVistaConsolidada &&
                                    stockProvider.paginatedProductos != null &&
                                    stockProvider.paginatedProductos!.paginacion
                                            .totalPages >
                                        0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: Center(
                                      child: Paginador(
                                        paginacion: stockProvider
                                            .paginatedProductos!.paginacion,
                                        onPageChanged:
                                            stockProvider.cambiarPagina,
                                        onPageSizeChanged:
                                            stockProvider.cambiarTamanioPagina,
                                        backgroundColor:
                                            const Color(0xFF2D2D2D),
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
}
