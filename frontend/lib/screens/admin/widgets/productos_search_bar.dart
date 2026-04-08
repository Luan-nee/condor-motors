import 'package:condorsmotors/providers/admin/productos.admin.riverpod.dart';
import 'package:condorsmotors/utils/debouncer.util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductosAdminSearchBar extends ConsumerStatefulWidget {
  final VoidCallback? onExport;
  final VoidCallback? onNew;

  const ProductosAdminSearchBar({
    super.key,
    this.onExport,
    this.onNew,
  });

  @override
  ConsumerState<ProductosAdminSearchBar> createState() => _ProductosAdminSearchBarState();
}

class _ProductosAdminSearchBarState extends ConsumerState<ProductosAdminSearchBar> {
  late final TextEditingController _searchController;
  final Debouncer _searchDebouncer =
      Debouncer(delay: const Duration(milliseconds: 350));

  @override
  void initState() {
    super.initState();
    // Inicializar el controlador con el valor actual del buscador en el estado
    final initialQuery = ref.read(productosAdminProvider).searchQuery;
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
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
        // Buscador con Debounce
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: <Widget>[
                const SizedBox(width: 12),
                const FaIcon(FontAwesomeIcons.magnifyingGlass,
                    color: Colors.white54, size: 14),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    enabled: state.selectedSucursal != null,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar productos...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: Colors.white54),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      _onSearchChanged(value);
                      setState(() {}); // Actualizar para mostrar/ocultar el icono Clear
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Selector de Categoría (Icono compacto con Menú Popup)
        SizedBox(
          height: 46,
          width: 46,
          child: Tooltip(
            message: 'Filtrar por categoría',
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: state.selectedCategoryId != null
                    ? const Color(0xFFE31E24).withValues(alpha: 0.1)
                    : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: state.selectedCategoryId != null
                      ? const Color(0xFFE31E24)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: state.isLoadingCategorias
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : PopupMenuButton<String?>(
                      initialValue: state.selectedCategoryId,
                      tooltip: '',
                      icon: FaIcon(
                        FontAwesomeIcons.filter,
                        size: 14,
                        color: state.selectedCategoryId != null
                            ? const Color(0xFFE31E24)
                            : Colors.white54,
                      ),
                      onSelected: (value) {
                        debugPrint('[Filter] Categoría seleccionada: $value');
                        notifier.actualizarCategoria(value);
                      },
                      offset: const Offset(0, 46),
                      padding: EdgeInsets.zero,
                      itemBuilder: (context) => [
                        const PopupMenuItem<String?>(
                          value: 'all',
                          child: Text('Todas las categorías',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ),
                        ...state.categorias.map(
                          (c) => PopupMenuItem<String?>(
                            value: c.id.toString(),
                            child: Text(c.nombre,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Botón Recargar
        SizedBox(
          height: 46,
          width: 46,
          child: Tooltip(
            message: state.isLoading ? 'Recargando...' : 'Recargar datos',
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
              onPressed: state.isLoading
                  ? null
                  : () => notifier.cargarProductos(forceRefresh: true),
              child: state.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Botón Exportar
        SizedBox(
          height: 46,
          width: 46,
          child: Tooltip(
            message: 'Exportar a Excel',
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
              onPressed: state.selectedSucursal == null ? null : widget.onExport,
              child: const FaIcon(FontAwesomeIcons.fileExcel, size: 16),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Botón Nuevo Producto
        SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
            label: const Text('Nuevo',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31E24),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: state.selectedSucursal == null ? null : widget.onNew,
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
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
                const Text('Estado del stock: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Disponibles',
                  icon: FontAwesomeIcons.check,
                  color: Colors.green,
                  isSelected: state.filtroEstadoStock == 'disponibles',
                  onSelected: () => notifier.filtrarPorEstadoStock('disponibles'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Stock bajo',
                  icon: FontAwesomeIcons.triangleExclamation,
                  color: const Color(0xFFE31E24),
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
                if (state.filtroEstadoStock != null && state.filtroEstadoStock != 'todos') ...[
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.filterCircleXmark, color: Colors.white70, size: 14),
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
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      showCheckmark: false,
      avatar: FaIcon(
        icon,
        size: 14,
        color: isSelected ? Colors.white : color,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      onSelected: (_) => onSelected(),
    );
  }
}
