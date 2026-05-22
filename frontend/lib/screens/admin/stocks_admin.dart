import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/providers/admin/stocks.admin.riverpod.dart';
import 'package:condorsmotors/screens/admin/widgets/slide_sucursal.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_detalles_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_list.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/utils/stock_utils.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:condorsmotors/widgets/search_bar_admin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class InventarioAdminScreen extends ConsumerStatefulWidget {
  const InventarioAdminScreen({super.key});

  @override
  ConsumerState<InventarioAdminScreen> createState() =>
      _InventarioAdminScreenState();
}

class _InventarioAdminScreenState extends ConsumerState<InventarioAdminScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Row(
        children: <Widget>[
          Expanded(
            flex: 75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _StocksAdminHeader(),
                      _StocksAdminFilters(),
                      Expanded(
                        child: RepaintBoundary(child: _StocksAdminTable()),
                      ),
                      _StocksAdminPagination(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _StocksAdminSidebar(),
        ],
      ),
    );
  }
}

// ... (Header, Filters, Table widgets remain same)

class _StocksAdminPagination extends ConsumerWidget {
  const _StocksAdminPagination();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paginacion = ref.watch(
      stocksAdminProvider.select((s) => s.paginatedProductos?.paginacion),
    );
    final notifier = ref.read(stocksAdminProvider.notifier);

    if (paginacion == null || paginacion.totalPages == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Paginador(
          paginacion: paginacion,
          onPageChanged: notifier.cambiarPagina,
          onPageSizeChanged: notifier.cambiarTamanioPagina,
          backgroundColor: AppTheme.surfaceColor,
          textColor: Colors.white,
          accentColor: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

class _StocksAdminSidebar extends ConsumerWidget {
  const _StocksAdminSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sucursales = ref.watch(
      stocksAdminProvider.select((s) => s.sucursales),
    );
    final selected = ref.watch(
      stocksAdminProvider.select((s) => s.selectedSucursal),
    );
    final isLoading = ref.watch(
      stocksAdminProvider.select((s) => s.isLoadingSucursales),
    );
    final notifier = ref.read(stocksAdminProvider.notifier);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 350,
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(left: BorderSide(color: Colors.white.withAlpha(25))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: SlideSucursal(
        sucursales: sucursales,
        sucursalSeleccionada: selected,
        onSucursalSelected: notifier.seleccionarSucursal,
        onRecargarSucursales: notifier.cargarSucursales,
        isLoading: isLoading,
      ),
    );
  }
}

class _StocksAdminHeader extends ConsumerWidget {
  const _StocksAdminHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSucursal = ref.watch(
      stocksAdminProvider.select((s) => s.selectedSucursal != null),
    );

    if (!hasSucursal) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: const Row(
        children: <Widget>[
          Expanded(child: _StocksSearchBar()),
          SizedBox(width: 8),
          _StocksRecargarButton(),
        ],
      ),
    );
  }
}

class _StocksSearchBar extends ConsumerStatefulWidget {
  const _StocksSearchBar();

  @override
  ConsumerState<_StocksSearchBar> createState() => _StocksSearchBarState();
}

class _StocksSearchBarState extends ConsumerState<_StocksSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(stocksAdminProvider).searchQuery;
    _controller = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(stocksAdminProvider.notifier);

    return SearchBarAdmin(
      controller: _controller,
      hintText: 'Buscar por nombre, SKU, categoría o marca...',
      onChanged: notifier.actualizarBusqueda,
    );
  }
}

class _StocksRecargarButton extends ConsumerWidget {
  const _StocksRecargarButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      stocksAdminProvider.select((s) => s.isLoadingProductos),
    );
    final notifier = ref.read(stocksAdminProvider.notifier);

    return SizedBox(
      height: 40,
      width: 40,
      child: Tooltip(
        message: isLoading ? 'Recargando...' : 'Recargar datos',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppTheme.deepestSurface,
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
              hoverColor: Colors.white.withValues(alpha: 0.04),
              splashColor: Colors.white.withValues(alpha: 0.08),
              onTap: isLoading ? null : notifier.recargarDatos,
              child: Center(
                child: isLoading
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
        ),
      ),
    );
  }
}

class _StocksAdminFilters extends ConsumerWidget {
  const _StocksAdminFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(
      stocksAdminProvider.select((s) => s.filtroEstadoStock),
    );
    final hasSucursal = ref.watch(
      stocksAdminProvider.select((s) => s.selectedSucursal != null),
    );
    final notifier = ref.read(stocksAdminProvider.notifier);

    if (!hasSucursal) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            const Text(
              'Filtrar por: ',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(width: 8),
            _buildChip(
              ref,
              'Disponibles',
              FontAwesomeIcons.check,
              Colors.green,
              StockStatus.disponible,
              currentFilter,
              notifier,
            ),
            const SizedBox(width: 8),
            _buildChip(
              ref,
              'Stock bajo',
              FontAwesomeIcons.triangleExclamation,
              AppTheme.primaryColor,
              StockStatus.stockBajo,
              currentFilter,
              notifier,
            ),
            const SizedBox(width: 8),
            _buildChip(
              ref,
              'Agotados',
              FontAwesomeIcons.ban,
              Colors.red.shade800,
              StockStatus.agotado,
              currentFilter,
              notifier,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    WidgetRef ref,
    String label,
    FaIconData icon,
    Color color,
    StockStatus status,
    StockStatus? current,
    StocksAdmin notifier,
  ) {
    final isSelected = current == status;
    return InkWell(
      onTap: () => notifier.filtrarPorEstadoStock(status),
      borderRadius: BorderRadius.circular(20),
      hoverColor: isSelected
          ? color.withValues(alpha: 0.15)
          : Colors.white.withValues(alpha: 0.04),
      splashColor: isSelected
          ? color.withValues(alpha: 0.25)
          : Colors.white.withValues(alpha: 0.08),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(51) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white.withAlpha(77),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, color: isSelected ? color : Colors.white70, size: 12),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.white70,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StocksAdminTable extends ConsumerWidget {
  const _StocksAdminTable();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sucursalId = ref.watch(
      stocksAdminProvider.select(
        (s) => s.selectedSucursal?.id.toString() ?? '',
      ),
    );
    final productos = ref.watch(
      stocksAdminProvider.select((s) => s.paginatedProductos?.items ?? []),
    );
    final isLoading = ref.watch(
      stocksAdminProvider.select((s) => s.isLoadingProductos),
    );
    final error = ref.watch(stocksAdminProvider.select((s) => s.errorMessage));
    final sortBy = ref.watch(stocksAdminProvider.select((s) => s.sortBy));
    final order = ref.watch(stocksAdminProvider.select((s) => s.order));
    final filtrosActivos = ref.watch(
      stocksAdminProvider.select(
        (s) => s.searchQuery.isNotEmpty || s.filtroEstadoStock != null,
      ),
    );

    final notifier = ref.read(stocksAdminProvider.notifier);

    return TableProducts(
      selectedSucursalId: sucursalId,
      productos: productos,
      isLoading: isLoading,
      error: error,
      onRetry: notifier.limpiarFiltros,
      onSort: notifier.ordenarPor,
      sortBy: sortBy,
      sortOrder: order,
      filtrosActivos: filtrosActivos,
      onVerStockDetalles: (p) => _showStockDetails(context, ref, p),
    );
  }

  void _showStockDetails(BuildContext context, WidgetRef ref, Producto p) {
    final sucursal = ref.read(stocksAdminProvider).selectedSucursal;
    if (sucursal == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StockDetallesDialog(
        producto: p,
        sucursalId: sucursal.id.toString(),
        sucursalNombre: sucursal.nombre,
      ),
    ).then((_) => ref.read(stocksAdminProvider.notifier).cargarProductos());
  }
}
