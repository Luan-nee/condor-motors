import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/widgets/search_bar_admin.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PedidoSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String filtroEstado;
  final ValueChanged<String> onFiltroChanged;
  final List<String> estadosPedido;

  const PedidoSearchBar({
    super.key,
    required this.controller,
    required this.filtroEstado,
    required this.onFiltroChanged,
    required this.estadosPedido,
  });

  @override
  State<PedidoSearchBar> createState() => _PedidoSearchBarState();
}

class _PedidoSearchBarState extends State<PedidoSearchBar> {
  final GlobalKey<PopupMenuButtonState<String>> _filterMenuKey = GlobalKey();

  /// Estructura de datos interna inmutable para representar la estética de un estado.
  /// Mantiene la inmutabilidad declarativa del sistema de diseño.
  _EstadoVisual _obtenerEstadoVisual(String estado) {
    // La resolución mediante esta función de mapeo directo opera bajo una complejidad
    // computacional de tiempo constante O(1), evitando búsquedas lineales en colecciones.
    switch (estado.toLowerCase()) {
      case 'todos':
        return const _EstadoVisual(
          icon: FontAwesomeIcons.list,
          color: Colors.white70,
        );
      case 'pendiente':
        return const _EstadoVisual(
          icon: FontAwesomeIcons.clock,
          color: Color(0xFFFFB300), // Ámbar táctico
        );
      case 'procesando':
        return const _EstadoVisual(
          icon: FontAwesomeIcons.arrowsSpin,
          color: Color(0xFF29B6F6), // Azul de procesamiento activo
        );
      case 'completado':
        return const _EstadoVisual(
          icon: FontAwesomeIcons.circleCheck,
          color: Color(0xFF66BB6A), // Verde de sistema operativo exitoso
        );
      case 'cancelado':
        return const _EstadoVisual(
          icon: FontAwesomeIcons.circleXmark,
          color: Color(0xFFEF5350), // Rojo de terminación de proceso
        );
      default:
        return const _EstadoVisual(
          icon: FontAwesomeIcons.filter,
          color: Colors.white54,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoVisualActual = _obtenerEstadoVisual(widget.filtroEstado);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          // Campo de Búsqueda Modular HUD Reutilizable
          Expanded(
            child: SearchBarAdmin(
              controller: widget.controller,
              hintText: 'Buscar pedidos...',
            ),
          ),
          const SizedBox(width: 16),

          // Selector de Estado Premium (Dropdown de Control HUD)
          SizedBox(
            height: 40,
            width: 190,
            child: Tooltip(
              message: 'Filtrar por estado de pedido',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: widget.filtroEstado != 'Todos'
                      ? estadoVisualActual.color.withValues(alpha: 0.05)
                      : AppTheme.deepestSurface,
                  borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                  border: Border.all(
                    color: widget.filtroEstado != 'Todos'
                        ? estadoVisualActual.color
                        : Colors.white.withValues(alpha: 0.08),
                    width: widget.filtroEstado != 'Todos' ? 1.5 : 1.0,
                  ),
                  boxShadow: widget.filtroEstado != 'Todos'
                      ? [
                          BoxShadow(
                            color: estadoVisualActual.color.withValues(alpha: 0.1),
                            blurRadius: 6,
                            spreadRadius: 0.5,
                          )
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                    hoverColor: Colors.white.withValues(alpha: 0.04),
                    splashColor: Colors.white.withValues(alpha: 0.08),
                    onTap: () {
                      _filterMenuKey.currentState?.showButtonMenu();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                FaIcon(
                                  estadoVisualActual.icon,
                                  size: 13,
                                  color: estadoVisualActual.color,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    widget.filtroEstado,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      overflow: TextOverflow.ellipsis,
                                      fontFamily: kFontFamily,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // PopupMenuButton invisible para orquestar el menú flotante
                          SizedBox.shrink(
                            child: PopupMenuButton<String>(
                              key: _filterMenuKey,
                              initialValue: widget.filtroEstado,
                              tooltip: '',
                              onSelected: widget.onFiltroChanged,
                              offset: const Offset(-10, 40),
                              padding: EdgeInsets.zero,
                              itemBuilder: (context) => widget.estadosPedido.map(
                                (estado) {
                                  final visual = _obtenerEstadoVisual(estado);
                                  return PopupMenuItem<String>(
                                    value: estado,
                                    child: Row(
                                      children: [
                                        FaIcon(
                                          visual.icon,
                                          size: 12,
                                          color: visual.color,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          estado == 'Todos' ? 'Todos los estados' : estado,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontFamily: kFontFamily,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ).toList(),
                              child: const SizedBox.shrink(),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Contenedor de datos inmutable de soporte estético para mapear iconos y colores a estados.
class _EstadoVisual {
  final FaIconData icon;
  final Color color;

  const _EstadoVisual({
    required this.icon,
    required this.color,
  });
}
