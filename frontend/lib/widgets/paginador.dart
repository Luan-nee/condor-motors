import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/theme/apptheme.dart';
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
  static const List<int> opcionesTamanoPagina = [25, 50, 100, 200];

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
        _PaginadorNumeroCard(
          key: ValueKey<int>(i),
          page: i,
          isSelected: isCurrentPage,
          txtColor: txtColor,
          accentColor: accent,
          onTap: () {
            if (!isCurrentPage) {
              onPageChanged?.call(i);
              onPageChange?.call();
            }
          },
        ),
      );
    }

    return pageNumbers;
  }

  /// Construye los controles de ordenación
  List<Widget> _buildOrdenacionControls(Color txtColor, Color accent) {
    final List<Widget> controls = [
      Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.white.withValues(alpha: 0.2),
      )
    ]

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
    // Si la paginación ya trae el pageSize explícito, lo usamos
    if (paginacion.pageSize != null) {
      return paginacion.pageSize!;
    }

    if (paginacion.totalItems == 0) {
      return 25;
    }

    final int calculated = paginacion.totalItems ~/ paginacion.totalPages;
    // Encontrar la opción más cercana en baseOpciones
    const List<int> baseOpciones = [25, 50, 100, 200];
    int closest = baseOpciones.first;
    int minDifference = (calculated - closest).abs();

    for (final int option in baseOpciones) {
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
    final Color bgColor = backgroundColor ?? AppTheme.surfaceColor;
    final Color txtColor = textColor ?? Colors.white;
    final Color accent = accentColor ?? AppTheme.primaryColor;

    // Base de opciones estándar (sin el 10)
    const List<int> baseOpciones = [25, 50, 100, 200];
    
    // Filtrar opciones que sean menores al total
    final List<int> opcionesFiltradas = baseOpciones
        .where((opt) => opt < paginacion.totalItems)
        .toList();

    // Agregar el total exacto si es <= 200 y no está ya incluido
    if (paginacion.totalItems > 0 && paginacion.totalItems <= 200) {
      if (!opcionesFiltradas.contains(paginacion.totalItems)) {
        opcionesFiltradas.add(paginacion.totalItems);
      }
    } else if (paginacion.totalItems > 200) {
      // Si hay más de 200, aseguramos que 200 sea la opción máxima
      if (!opcionesFiltradas.contains(200)) {
        opcionesFiltradas.add(200);
      }
    }

    // Siempre garantizar que haya al menos la opción de 25
    if (!opcionesFiltradas.contains(25)) {
      opcionesFiltradas.add(25);
    }
    
    // Aseguramos que el valor actual esté en la lista para evitar errores de Dropdown
    final int itemsActuales = _calcularItemsPorPagina();
    if (!opcionesFiltradas.contains(itemsActuales)) {
      opcionesFiltradas.add(itemsActuales);
    }

    // Ordenar y limpiar duplicados
    final List<int> opcionesFinales = opcionesFiltradas.toSet().toList()..sort();

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
                        value: itemsActuales,
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
                        items: opcionesFinales.map((int value) {
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
                      itemBuilder: (context) => opcionesFinales
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

                // Botón Anterior
                IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: paginacion.hasPrev
                        ? txtColor
                        : txtColor.withValues(alpha: 0.1),
                  ),
                  onPressed: paginacion.hasPrev
                      ? () {
                          final prevPage = paginacion.currentPage - 1;
                          if (prevPage >= 1) {
                            onPageChanged?.call(prevPage);
                            onPageChange?.call();
                          }
                        }
                      : null,
                  tooltip: paginacion.hasPrev ? 'Página anterior' : null,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),

                // Números de página
                ..._buildPageNumbers(visiblePages, txtColor, accent),

                // Botón Siguiente
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: paginacion.hasNext
                        ? txtColor
                        : txtColor.withValues(alpha: 0.1),
                  ),
                  onPressed: paginacion.hasNext
                      ? () {
                          final nextPage = paginacion.currentPage + 1;
                          if (nextPage <= paginacion.totalPages) {
                            onPageChanged?.call(nextPage);
                            onPageChange?.call();
                          }
                        }
                      : null,
                  tooltip: paginacion.hasNext ? 'Página siguiente' : null,
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

class _PaginadorNumeroCard extends StatefulWidget {
  final int page;
  final bool isSelected;
  final Color txtColor;
  final Color accentColor;
  final VoidCallback onTap;

  const _PaginadorNumeroCard({
    super.key,
    required this.page,
    required this.isSelected,
    required this.txtColor,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_PaginadorNumeroCard> createState() => _PaginadorNumeroCardState();
}

class _PaginadorNumeroCardState extends State<_PaginadorNumeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // Animación de llenado de gota (0.0 a 1.4 de radio de gradiente)
    _fillAnimation = Tween<double>(begin: 0.0, end: 1.4).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _PaginadorNumeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward(from: 0.0);
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double fillValue = _fillAnimation.value;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: widget.isSelected
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.08),
                ),
                  gradient: widget.isSelected || _controller.value > 0.0
                      ? RadialGradient(
                          radius: fillValue,
                        colors: [
                          widget.accentColor,
                          widget.accentColor.withValues(alpha: 0.85),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.85, 1.0],
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  '${widget.page}',
                  style: TextStyle(
                    color: widget.isSelected
                        ? Colors.white
                        : widget.txtColor.withValues(
                            alpha: 1.0 - (0.4 * _controller.value),
                          ),
                    fontWeight: widget.isSelected || _controller.value > 0.5
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                    fontFamily: kFontFamily,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
