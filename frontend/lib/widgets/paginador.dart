import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Paginador extends StatelessWidget {
  /// Construye un paginador con opciones avanzadas
  const Paginador({
    super.key,
    required this.paginacion,
    this.onPageChange,
    this.backgroundColor,
    this.textColor,
    this.accentColor,
    this.radius = 4.0,
    this.maxVisiblePages = 5,
    this.forceCompactMode = false,
    this.mostrarOrdenacion = false,
    this.camposParaOrdenar,
    this.onPageChanged,
    this.onSortByChanged,
    this.onOrderChanged,
    this.onPageSizeChanged,
  });

  /// Opciones de tamaño de página disponibles
  static const List<int> opcionesTamanoPagina = [10, 25, 50, 100, 200];

  /// Callback al cambiar de página
  final Function()? onPageChange;

  /// Callback cuando cambia el número de página
  final Function(int)? onPageChanged;

  /// Callback cuando cambia el orden
  final Function(String?)? onSortByChanged;

  /// Callback cuando cambia la dirección del orden
  final Function(String)? onOrderChanged;

  /// Callback cuando cambia el tamaño de página
  final Function(int)? onPageSizeChanged;

  /// Color de acento (selección)
  final Color? accentColor;

  /// Color de fondo del paginador
  final Color? backgroundColor;

  /// Campos disponibles para ordenar
  final List<Map<String, String>>? camposParaOrdenar;

  /// Forzar modo compacto (móvil)
  final bool forceCompactMode;

  /// Máximo de páginas visibles en el paginador
  final int maxVisiblePages;

  /// Mostrar controles de ordenación
  final bool mostrarOrdenacion;

  /// Objeto de paginación (requerido)
  final Paginacion paginacion;

  /// Radio de bordes
  final double radius;

  /// Color del texto
  final Color? textColor;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Paginacion>('paginacion', paginacion));
  }

  /// Construye los números de página visibles
  List<Widget> _buildPageNumbers(
      int visiblePages, Color txtColor, Color accent) {
    final List<Widget> pageNumbers = [];
    final int totalPages = paginacion.totalPages;
    final int currentPage = paginacion.currentPage;

    if (totalPages <= 1) {
      return pageNumbers;
    }

    int startPage = 1;
    int endPage = totalPages;

    if (totalPages > visiblePages) {
      final int halfVisible = visiblePages ~/ 2;
      startPage =
          (currentPage - halfVisible).clamp(1, totalPages - visiblePages + 1);
      endPage = startPage + visiblePages - 1;
    }

    for (int i = startPage; i <= endPage; i++) {
      final bool isCurrentPage = i == currentPage;
      pageNumbers.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            onTap: () {
              if (!isCurrentPage) {
                onPageChanged?.call(i);
                onPageChange?.call();
              }
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCurrentPage ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: isCurrentPage
                    ? null
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
              ),
              child: Center(
                child: Text(
                  '$i',
                  style: TextStyle(
                    color: isCurrentPage ? Colors.white : txtColor,
                    fontWeight:
                        isCurrentPage ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return pageNumbers;
  }

  /// Construye los controles de ordenación
  List<Widget> _buildOrdenacionControls(Color txtColor, Color accent) {
    final List<Widget> controls = [Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.white.withValues(alpha: 0.2),
      )]

    // Separador
    ;

    // Selector de campo de ordenación
    if (camposParaOrdenar != null && camposParaOrdenar!.isNotEmpty) {
      controls.add(
        Container(
          height: 28,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: camposParaOrdenar!.first['value'],
              isDense: true,
              style: TextStyle(
                color: txtColor,
                fontSize: 12,
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: txtColor.withValues(alpha: 0.8),
                size: 16,
              ),
              items: camposParaOrdenar!.map((Map<String, String> campo) {
                return DropdownMenuItem<String>(
                  value: campo['value'],
                  child: Text(
                    campo['label'] ?? campo['value']!,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  onSortByChanged?.call(value);
                  onPageChange?.call();
                }
              },
            ),
          ),
        ),
      );
    }

    // Botón de cambio de dirección de ordenación
    controls.add(
      Container(
        margin: const EdgeInsets.only(left: 4),
        child: IconButton(
          icon: Icon(
            Icons.swap_vert,
            color: txtColor,
            size: 18,
          ),
          onPressed: () {
            // Cambiar entre asc/desc
            onOrderChanged?.call('asc'); // Esto debería alternar
            onPageChange?.call();
          },
          tooltip: 'Cambiar orden',
          constraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
    );

    return controls;
  }

  /// Calcula el número de items por página basado en la paginación
  int _calcularItemsPorPagina() {
    if (paginacion.totalItems == 0) {
      return 10;
    }

    final int calculated = paginacion.totalItems ~/ paginacion.totalPages;
    // Encontrar la opción más cercana en opcionesTamanoPagina
    int closest = opcionesTamanoPagina.first;
    int minDifference = (calculated - closest).abs();

    for (int option in opcionesTamanoPagina) {
      final difference = (calculated - option).abs();
      if (difference < minDifference) {
        minDifference = difference;
        closest = option;
      }
    }

    return closest;
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = backgroundColor ?? const Color(0xFF2D2D2D);
    final Color txtColor = textColor ?? Colors.white;
    final Color accent = accentColor ?? const Color(0xFFE31E24);

    final int visiblePages = forceCompactMode ? 3 : maxVisiblePages;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ancho mínimo estimado para mostrar el total de elementos (ajustable)
        const double minWidthForTotal = 340;
        final bool showTotal = constraints.maxWidth > minWidthForTotal;
        return Container(
          padding: forceCompactMode
              ? const EdgeInsets.symmetric(vertical: 2, horizontal: 2)
              : const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Selector de items por página
                if (!forceCompactMode)
                  Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _calcularItemsPorPagina(),
                        isDense: true,
                        style: TextStyle(
                          color: txtColor,
                          fontSize: 14,
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: txtColor.withValues(alpha: 0.8),
                          size: 16,
                        ),
                        items: opcionesTamanoPagina.map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value / pág'),
                          );
                        }).toList(),
                        onChanged: (int? value) {
                          if (value != null) {
                            onPageSizeChanged?.call(value);
                            onPageChange?.call();
                          }
                        },
                      ),
                    ),
                  ),
                if (forceCompactMode)
                  Container(
                    height: 28,
                    width: 36,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: PopupMenuButton<int>(
                      icon: Icon(Icons.more_vert, color: txtColor, size: 18),
                      tooltip: 'Tamaño de página',
                      onSelected: (int value) {
                        onPageSizeChanged?.call(value);
                        onPageChange?.call();
                      },
                      itemBuilder: (context) => opcionesTamanoPagina
                          .map((int value) => PopupMenuItem<int>(
                                value: value,
                                child: Text('$value / pág'),
                              ))
                          .toList(),
                    ),
                  ),

                // Separador
                if (!forceCompactMode)
                  Container(
                    width: 1,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: Colors.white.withValues(alpha: 0.2),
                  ),

                // Información de paginación
                if (showTotal && !forceCompactMode)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${paginacion.totalItems} elementos',
                      style: TextStyle(
                        color: txtColor.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),

                // Botones de navegación
                if (paginacion.hasPrev)
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: txtColor),
                    onPressed: () {
                      final prevPage = paginacion.currentPage - 1;
                      if (prevPage >= 1) {
                        onPageChanged?.call(prevPage);
                        onPageChange?.call();
                      }
                    },
                    tooltip: 'Página anterior',
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),

                // Números de página
                ..._buildPageNumbers(visiblePages, txtColor, accent),

                if (paginacion.hasNext)
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: txtColor),
                    onPressed: () {
                      final nextPage = paginacion.currentPage + 1;
                      if (nextPage <= paginacion.totalPages) {
                        onPageChanged?.call(nextPage);
                        onPageChange?.call();
                      }
                    },
                    tooltip: 'Página siguiente',
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),

                // Controles de ordenación
                if (mostrarOrdenacion && camposParaOrdenar != null)
                  ..._buildOrdenacionControls(txtColor, accent),
              ],
            ),
          ),
        );
      },
    );
  }
}
