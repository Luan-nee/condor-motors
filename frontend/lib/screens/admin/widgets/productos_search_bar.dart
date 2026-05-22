import 'package:condorsmotors/providers/admin/productos.admin.riverpod.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/utils/debouncer.util.dart';
import 'package:condorsmotors/widgets/search_bar_admin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductosAdminSearchBar extends ConsumerStatefulWidget {
  final VoidCallback? onExport;
  final VoidCallback? onNew;

  const ProductosAdminSearchBar({super.key, this.onExport, this.onNew});

  @override
  ConsumerState<ProductosAdminSearchBar> createState() =>
      _ProductosAdminSearchBarState();
}

class _ProductosAdminSearchBarState
    extends ConsumerState<ProductosAdminSearchBar> {
  late final TextEditingController _searchController;
  final Debouncer _searchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 350),
  );
  final GlobalKey<PopupMenuButtonState<String?>> _menuKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(productosAdminProvider).searchQuery;
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebouncer.run(() {
      if (mounted) {
        ref.read(productosAdminProvider.notifier).actualizarBusqueda(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productosAdminProvider);
    final notifier = ref.read(productosAdminProvider.notifier);

    final searchRow = Row(
      children: <Widget>[
        // Buscador con Debounce Reactivo de Foco (HUD Style) Reutilizable
        Expanded(
          child: SearchBarAdmin(
            controller: _searchController,
            hintText: 'Buscar productos...',
            enabled: state.selectedSucursal != null,
            onChanged: _onSearchChanged,
          ),
        ),
        const SizedBox(width: 8),

        // Selector de Categoría (Icono compacto con Menú Popup Premium)
        SizedBox(
          height: 40,
          width: 40,
          child: Tooltip(
            message: 'Filtrar por categoría',
            child: state.isLoadingCategorias
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.deepestSurface,
                      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  )
                : AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: state.selectedCategoryId != null
                          ? AppTheme.primaryColor.withValues(alpha: 0.05)
                          : AppTheme.deepestSurface,
                      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                      border: Border.all(
                        color: state.selectedCategoryId != null
                            ? AppTheme.primaryColor
                            : Colors.white.withValues(alpha: 0.08),
                        width: state.selectedCategoryId != null ? 1.5 : 1.0,
                      ),
                      boxShadow: state.selectedCategoryId != null
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                blurRadius: 6,
                                spreadRadius: 0.5,
                              ),
                            ]
                          : [],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          AppTheme.smallRadius,
                        ),
                        hoverColor: Colors.white.withValues(alpha: 0.04),
                        splashColor: Colors.white.withValues(alpha: 0.08),
                        onTap: () {
                          _menuKey.currentState?.showButtonMenu();
                        },
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(
                                FontAwesomeIcons.filter,
                                size: 14,
                                color: state.selectedCategoryId != null
                                    ? AppTheme.primaryColor
                                    : Colors.white54,
                              ),
                              SizedBox.shrink(
                                child: PopupMenuButton<String?>(
                                  key: _menuKey,
                                  initialValue: state.selectedCategoryId,
                                  tooltip: '',
                                  onSelected: (value) {
                                    debugPrint(
                                      '[Filter] Categoría seleccionada: $value',
                                    );
                                    notifier.actualizarCategoria(value);
                                  },
                                  offset: const Offset(0, 40),
                                  padding: EdgeInsets.zero,
                                  itemBuilder: (context) => [
                                    const PopupMenuItem<String?>(
                                      value: 'all',
                                      child: Text(
                                        'Todas las categorías',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontFamily: kFontFamily,
                                        ),
                                      ),
                                    ),
                                    ...state.categorias.map(
                                      (c) => PopupMenuItem<String?>(
                                        value: c.id.toString(),
                                        child: Text(
                                          c.nombre,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontFamily: kFontFamily,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  child: const SizedBox.shrink(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),

        // Botón Recargar
        SizedBox(
          height: 40,
          width: 40,
          child: Tooltip(
            message: state.isLoading ? 'Recargando...' : 'Recargar datos',
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
                  onTap: state.isLoading
                      ? null
                      : () => notifier.cargarProductos(forceRefresh: true),
                  child: Center(
                    child: state.isLoading
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
        ),
        const SizedBox(width: 8),

        // Botón Exportar
        SizedBox(
          height: 40,
          width: 40,
          child: Tooltip(
            message: 'Exportar a Excel',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: state.selectedSucursal == null
                    ? AppTheme.deepestSurface.withValues(alpha: 0.5)
                    : AppTheme.deepestSurface,
                borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                  hoverColor: Colors.white.withValues(alpha: 0.04),
                  splashColor: Colors.white.withValues(alpha: 0.08),
                  onTap: state.selectedSucursal == null
                      ? null
                      : widget.onExport,
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.fileExcel,
                      size: 16,
                      color: state.selectedSucursal == null
                          ? Colors.white30
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Botón Nuevo Producto
        SizedBox(
          height: 40,
          child: ElevatedButton.icon(
            icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
            label: const Text(
              'Nuevo',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.smallRadius),
              ),
              elevation: 0,
            ),
            onPressed: state.selectedSucursal == null ? null : widget.onNew,
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          searchRow,
          const SizedBox(height: 16),
          // Chips de Filtro Estado Stock
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                const Text(
                  'Filtrar por: ',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Disponibles',
                  icon: FontAwesomeIcons.check,
                  color: Colors.green,
                  isSelected: state.filtroEstadoStock == 'disponibles',
                  onSelected: () =>
                      notifier.filtrarPorEstadoStock('disponibles'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Stock bajo',
                  icon: FontAwesomeIcons.triangleExclamation,
                  color: AppTheme.primaryColor,
                  isSelected: state.filtroEstadoStock == 'stockBajo',
                  onSelected: () => notifier.filtrarPorEstadoStock('stockBajo'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Agotados',
                  icon: FontAwesomeIcons.ban,
                  color: Colors.red.shade800,
                  isSelected: state.filtroEstadoStock == 'agotados',
                  onSelected: () => notifier.filtrarPorEstadoStock('agotados'),
                ),
                if (state.filtroEstadoStock != null &&
                    state.filtroEstadoStock != 'todos') ...[
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.filterCircleXmark,
                      color: Colors.white70,
                      size: 14,
                    ),
                    tooltip: 'Limpiar filtro',
                    onPressed: () => notifier.filtrarPorEstadoStock('todos'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required FaIconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
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
                fontFamily: kFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
