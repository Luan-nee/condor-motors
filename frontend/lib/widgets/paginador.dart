import 'package:condorsmotors/providers/paginacion.provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Paginador extends StatelessWidget {
  /// Provider opcional para paginación (si no se proporciona, se buscará en el árbol)
  final PaginacionProvider? paginacionProvider;

  /// Callback al cambiar de página
  final Function()? onPageChange;

  /// Color de fondo del paginador
  final Color? backgroundColor;

  /// Color del texto
  final Color? textColor;

  /// Color de acento (selección)
  final Color? accentColor;

  /// Radio de bordes
  final double radius;

  /// Máximo de páginas visibles en el paginador
  final int maxVisiblePages;

  /// Forzar modo compacto (móvil)
  final bool forceCompactMode;

  /// Mostrar controles de ordenación
  final bool mostrarOrdenacion;

  /// Campos disponibles para ordenar (si no se proporciona, se tomarán de los metadatos)
  final List<Map<String, String>>? camposParaOrdenar;

  /// Objeto de paginación (alternativa a usar el provider)
  final dynamic paginacion;

  /// Callback cuando cambia el número de página
  final Function(int)? onPageChanged;

  /// Callback cuando cambia el orden
  final Function(String?)? onSortByChanged;

  /// Callback cuando cambia la dirección del orden
  final Function(String)? onOrderChanged;

  /// Callback cuando cambia el tamaño de página
  final Function(int)? onPageSizeChanged;

  /// Construye un paginador con opciones avanzadas
  const Paginador({
    super.key,
    this.paginacionProvider,
    this.onPageChange,
    this.backgroundColor,
    this.textColor,
    this.accentColor,
    this.radius = 4.0,
    this.maxVisiblePages = 5,
    this.forceCompactMode = false,
    this.mostrarOrdenacion = false,
    this.camposParaOrdenar,
    this.paginacion,
    this.onPageChanged,
    this.onSortByChanged,
    this.onOrderChanged,
    this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final PaginacionProvider tempProvider = paginacion != null
        ? PaginacionProvider.fromPaginacion(paginacion)
        : PaginacionProvider();

    final provider =
        paginacionProvider ?? Provider.of<PaginacionProvider>(context);

    final paginacionData =
        paginacion != null ? tempProvider.paginacion : provider.paginacion;

    final Color bgColor = backgroundColor ?? const Color(0xFF2D2D2D);
    final Color txtColor = textColor ?? Colors.white;
    final Color accent = accentColor ?? const Color(0xFFE31E24);

    return IntrinsicHeight(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Selector de items por página
            if (!forceCompactMode)
              Container(
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: provider.itemsPerPage,
                    isDense: true,
                    style: TextStyle(
                      color: txtColor,
                      fontSize: 14,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: txtColor.withOpacity(0.8),
                      size: 16,
                    ),
                    items: PaginacionProvider.opcionesTamanoPagina
                        .map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value / pág'),
                      );
                    }).toList(),
                    onChanged: (int? value) {
                      if (value != null) {
                        provider.cambiarItemsPorPagina(value);
                        if (onPageSizeChanged != null)
                          onPageSizeChanged!(value);
                        if (onPageChange != null) onPageChange!();
                      }
                    },
                  ),
                ),
              ),

            if (!forceCompactMode) const SizedBox(width: 8),

            // Controles de paginación
            _buildPageButton(
              icon: Icons.first_page,
              onPressed:
                  paginacionData.hasPrev && paginacionData.currentPage > 1
                      ? () => _cambiarPagina(provider, 1)
                      : null,
              bgColor: bgColor,
              txtColor: txtColor,
              accentColor: accent,
            ),
            _buildPageButton(
              icon: Icons.chevron_left,
              onPressed: paginacionData.hasPrev
                  ? () =>
                      _cambiarPagina(provider, paginacionData.currentPage - 1)
                  : null,
              bgColor: bgColor,
              txtColor: txtColor,
              accentColor: accent,
            ),

            // Números de página
            ...paginacionData
                .getVisiblePages(maxVisiblePages: maxVisiblePages)
                .map(
                  (pageNum) => _buildNumberButton(
                    pageNum: pageNum,
                    isSelected: pageNum == paginacionData.currentPage,
                    onPressed: () => _cambiarPagina(provider, pageNum),
                    bgColor: bgColor,
                    txtColor: txtColor,
                    accentColor: accent,
                  ),
                ),

            _buildPageButton(
              icon: Icons.chevron_right,
              onPressed: paginacionData.hasNext
                  ? () =>
                      _cambiarPagina(provider, paginacionData.currentPage + 1)
                  : null,
              bgColor: bgColor,
              txtColor: txtColor,
              accentColor: accent,
            ),
            _buildPageButton(
              icon: Icons.last_page,
              onPressed: paginacionData.hasNext &&
                      paginacionData.currentPage < paginacionData.totalPages
                  ? () => _cambiarPagina(provider, paginacionData.totalPages)
                  : null,
              bgColor: bgColor,
              txtColor: txtColor,
              accentColor: accent,
            ),

            if (!forceCompactMode) ...[
              const SizedBox(width: 8),
              // Total de elementos
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '${paginacionData.totalItems} elementos',
                    style: TextStyle(
                      color: txtColor.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _cambiarPagina(PaginacionProvider provider, int pagina) {
    provider.cambiarPagina(pagina);

    if (onPageChange != null) {
      onPageChange!();
    }

    if (onPageChanged != null) {
      onPageChanged!(pagina);
    }
  }

  Widget _buildPageButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color bgColor,
    required Color txtColor,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      child: IconButton(
        icon: Icon(
          icon,
          size: 18,
          color: onPressed == null ? txtColor.withOpacity(0.3) : txtColor,
        ),
        onPressed: onPressed,
        splashRadius: 18,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(
          minWidth: 28,
          minHeight: 28,
        ),
      ),
    );
  }

  Widget _buildNumberButton({
    required int pageNum,
    required bool isSelected,
    required VoidCallback onPressed,
    required Color bgColor,
    required Color txtColor,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: isSelected ? accentColor : bgColor,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: isSelected ? null : onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            child: Text(
              pageNum.toString(),
              style: TextStyle(
                color: isSelected ? Colors.white : txtColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<PaginacionProvider?>(
          'paginacionProvider', paginacionProvider))
      ..add(ObjectFlagProperty<Function()?>.has('onPageChange', onPageChange))
      ..add(ColorProperty('backgroundColor', backgroundColor))
      ..add(ColorProperty('textColor', textColor))
      ..add(ColorProperty('accentColor', accentColor))
      ..add(DoubleProperty('radius', radius))
      ..add(IntProperty('maxVisiblePages', maxVisiblePages))
      ..add(DiagnosticsProperty<bool>('forceCompactMode', forceCompactMode))
      ..add(DiagnosticsProperty<bool>('mostrarOrdenacion', mostrarOrdenacion))
      ..add(IterableProperty<Map<String, String>>(
          'camposParaOrdenar', camposParaOrdenar))
      ..add(DiagnosticsProperty<dynamic>('paginacion', paginacion))
      ..add(ObjectFlagProperty<Function(int)?>.has(
          'onPageChanged', onPageChanged))
      ..add(ObjectFlagProperty<Function(String?)?>.has(
          'onSortByChanged', onSortByChanged))
      ..add(ObjectFlagProperty<Function(String)?>.has(
          'onOrderChanged', onOrderChanged))
      ..add(ObjectFlagProperty<Function(int)?>.has(
          'onPageSizeChanged', onPageSizeChanged));
  }
}
