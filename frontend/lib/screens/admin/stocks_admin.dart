import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/providers/admin/stocks.admin.riverpod.dart';
import 'package:condorsmotors/screens/admin/widgets/slide_sucursal.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_detalle_sucursal.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_detalles_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_list.dart';
import 'package:condorsmotors/utils/stock_utils.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class InventarioAdminScreen extends ConsumerStatefulWidget {
  const InventarioAdminScreen({super.key});

  @override
  ConsumerState<InventarioAdminScreen> createState() => _InventarioAdminScreenState();
}

class _InventarioAdminScreenState extends ConsumerState<InventarioAdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  final bool _drawerOpen = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stocksAdminProvider);
    final notifier = ref.read(stocksAdminProvider.notifier);

    // Sync search controller text with state (one way if needed, or controlled)
    if (_searchController.text != state.searchQuery && state.searchQuery.isEmpty) {
      _searchController.text = '';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Row(
        children: <Widget>[
          Expanded(
            flex: 75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (state.selectedSucursal != null) ...[
                          _buildSearchBar(state, notifier),
                          const SizedBox(height: 16),
                          _buildFilterChips(state, notifier),
                          const SizedBox(height: 16),
                        ],
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: TableProducts(
                                  selectedSucursalId: state.selectedSucursal?.id.toString() ?? '',
                                  productos: state.paginatedProductos?.items ?? [],
                                  isLoading: state.isLoadingProductos,
                                  error: state.errorMessage,
                                  onRetry: notifier.limpiarFiltros,
                                  onVerDetalles: (p) => _verDetallesProducto(p, notifier),
                                  onVerStockDetalles: (p) => _verStockDetalles(state.selectedSucursal, p, notifier),
                                  onSort: notifier.ordenarPor,
                                  sortBy: state.sortBy,
                                  sortOrder: state.order,
                                  filtrosActivos: state.searchQuery.isNotEmpty || state.filtroEstadoStock != null,
                                ),
                              ),
                              if (state.paginatedProductos != null && state.paginatedProductos!.paginacion.totalPages > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Center(
                                    child: Paginador(
                                      paginacion: state.paginatedProductos!.paginacion,
                                      onPageChanged: notifier.cambiarPagina,
                                      onPageSizeChanged: notifier.cambiarTamanioPagina,
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _drawerOpen ? 350 : 0,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(-2, 0)),
              ],
            ),
            child: _drawerOpen
                ? SlideSucursal(
                    sucursales: state.sucursales,
                    sucursalSeleccionada: state.selectedSucursal,
                    onSucursalSelected: notifier.seleccionarSucursal,
                    onRecargarSucursales: notifier.cargarSucursales,
                    isLoading: state.isLoadingSucursales,
                  )
                : null,
          ),
        ],
      ),
    );
  }


  Widget _buildSearchBar(StocksAdminState state, StocksAdmin notifier) {
    return Container(
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
                  color: state.searchQuery.isNotEmpty ? const Color(0xFFE31E24) : const Color(0xFF2D2D2D),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 46,
                    decoration: BoxDecoration(
                      color: state.searchQuery.isNotEmpty ? const Color(0xFFE31E24).withValues(alpha: 0.1) : const Color(0xFF2D2D2D),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), bottomLeft: Radius.circular(6)),
                    ),
                    child: Center(
                      child: state.isLoadingProductos
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31E24))))
                          : const FaIcon(FontAwesomeIcons.magnifyingGlass, color: Colors.white54, size: 14),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, SKU, categoría o marca...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: notifier.actualizarBusqueda,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        notifier.actualizarBusqueda('');
                      },
                    ),
                ],
              ),
            ),
          ),
          if (state.searchQuery.isNotEmpty || state.filtroEstadoStock != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const FaIcon(FontAwesomeIcons.filterCircleXmark, size: 14),
              label: const Text('Limpiar'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                backgroundColor: const Color(0xFF2D2D2D),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () {
                _searchController.clear();
                notifier.limpiarFiltros();
              },
            ),
          ],
          const SizedBox(width: 8),
          // Botón de recarga integrado en búsqueda (Estilo compacto y alineado)
          SizedBox(
            height: 46,
            width: 46,
            child: Tooltip(
              message: state.isLoadingProductos ? 'Recargando...' : 'Recargar datos',
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D2D2D),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: state.isLoadingProductos ? null : notifier.recargarDatos,
                child: state.isLoadingProductos
                    ? const SizedBox(
                        width: 18,
                        height: 18,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(StocksAdminState state, StocksAdmin notifier) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          const Text('Filtrar por: ', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(width: 8),
          _buildFilterChip('Disponibles', FontAwesomeIcons.check, Colors.green, state.filtroEstadoStock == StockStatus.disponible, () => notifier.filtrarPorEstadoStock(StockStatus.disponible)),
          const SizedBox(width: 8),
          _buildFilterChip('Stock bajo', FontAwesomeIcons.triangleExclamation, const Color(0xFFE31E24), state.filtroEstadoStock == StockStatus.stockBajo, () => notifier.filtrarPorEstadoStock(StockStatus.stockBajo)),
          const SizedBox(width: 8),
          _buildFilterChip('Agotados', FontAwesomeIcons.ban, Colors.red.shade800, state.filtroEstadoStock == StockStatus.agotado, () => notifier.filtrarPorEstadoStock(StockStatus.agotado)),
          if (state.filtroEstadoStock != null) ...[
            const SizedBox(width: 16),
            IconButton(icon: const FaIcon(FontAwesomeIcons.filterCircleXmark, color: Colors.white70, size: 16), onPressed: () => notifier.filtrarPorEstadoStock(null)),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, Color color, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.white.withValues(alpha: 0.3), width: selected ? 2 : 1),
          boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FaIcon(icon, color: selected ? color : Colors.white70, size: 12),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: selected ? color : Colors.white70, fontSize: 13, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  void _verDetallesProducto(Producto producto, StocksAdmin notifier) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StockDetalleSucursalDialog(producto: producto),
    ).then((_) => notifier.cargarProductos());
  }

  void _verStockDetalles(Sucursal? selectedSucursal, Producto producto, StocksAdmin notifier) {
    if (selectedSucursal == null) {
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StockDetallesDialog(
        producto: producto,
        sucursalId: selectedSucursal.id.toString(),
        sucursalNombre: selectedSucursal.nombre,
      ),
    ).then((_) => notifier.cargarProductos());
  }
}
