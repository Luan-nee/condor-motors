import 'package:condorsmotors/providers/paginacion.provider.dart';
import 'package:condorsmotors/utils/logger.dart';
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

    logDebug(
        'Paginador: Constructor - Provider actual: $provider, itemsPerPage: ${provider.itemsPerPage}');

    final paginacionData =
        paginacion != null ? tempProvider.paginacion : provider.paginacion;

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isCompactScreen = screenWidth < 600 || forceCompactMode;

    final Color bgColor = backgroundColor ?? const Color(0xFF2D2D2D);
    final Color txtColor = textColor ?? Colors.white;
    final Color accent = accentColor ?? const Color(0xFFE31E24);

    if (paginacionData.totalPages <= 1) {
      // Si solo hay una página pero hay elementos, mostramos solo el selector de tamaño de página
      if (paginacionData.totalItems > 0) {
        return Container(
          padding: EdgeInsets.symmetric(
              vertical: 8, horizontal: isCompactScreen ? 8 : 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mostrando ${paginacionData.totalItems} elementos',
                style: TextStyle(
                  color: txtColor.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _buildPageSizeSelector(context, provider, txtColor),
              ),
            ],
          ),
        );
      }
      return const SizedBox();
    }

    final List<int> visiblePages = paginacionData.getVisiblePages(
        maxVisiblePages: isCompactScreen ? 3 : maxVisiblePages);

    return Container(
      padding: EdgeInsets.symmetric(
          vertical: 8, horizontal: isCompactScreen ? 8 : 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: isCompactScreen
          ? _buildCompactLayout(
              context,
              paginacion != null ? tempProvider : provider,
              visiblePages,
              bgColor,
              txtColor,
              accent)
          : _buildFullLayout(
              context,
              paginacion != null ? tempProvider : provider,
              visiblePages,
              bgColor,
              txtColor,
              accent),
    );
  }

  Widget _buildCompactLayout(
    BuildContext context,
    PaginacionProvider provider,
    List<int> visiblePages,
    Color bgColor,
    Color txtColor,
    Color accentColor,
  ) {
    final paginacionData = provider.paginacion;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildPageButton(
          icon: Icons.chevron_left,
          onPressed: paginacionData.hasPrevPage
              ? () => _cambiarPagina(provider, paginacionData.currentPage - 1)
              : null,
          bgColor: bgColor,
          txtColor: txtColor,
          accentColor: accentColor,
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${paginacionData.currentPage}/${paginacionData.totalPages}',
            style: TextStyle(
              color: txtColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 4),
        _buildPageButton(
          icon: Icons.chevron_right,
          onPressed: paginacionData.hasNextPage
              ? () => _cambiarPagina(provider, paginacionData.currentPage + 1)
              : null,
          bgColor: bgColor,
          txtColor: txtColor,
          accentColor: accentColor,
        ),
      ],
    );
  }

  Widget _buildFullLayout(
    BuildContext context,
    PaginacionProvider provider,
    List<int> visiblePages,
    Color bgColor,
    Color txtColor,
    Color accentColor,
  ) {
    final paginacionData = provider.paginacion;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Página ${paginacionData.currentPage} de ${paginacionData.totalPages}',
              style: TextStyle(
                color: txtColor.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 16),
            _buildPageButton(
              icon: Icons.first_page,
              onPressed: paginacionData.hasPrevPage
                  ? () => _cambiarPagina(provider, 1)
                  : null,
              bgColor: bgColor,
              txtColor: txtColor,
              accentColor: accentColor,
            ),
            _buildPageButton(
              icon: Icons.chevron_left,
              onPressed: paginacionData.hasPrevPage
                  ? () =>
                      _cambiarPagina(provider, paginacionData.currentPage - 1)
                  : null,
              bgColor: bgColor,
              txtColor: txtColor,
              accentColor: accentColor,
            ),
            ...visiblePages.map(
              (int pageNum) => _buildNumberButton(
                pageNum: pageNum,
                isSelected: pageNum == paginacionData.currentPage,
                onPressed: () => _cambiarPagina(provider, pageNum),
                bgColor: bgColor,
                txtColor: txtColor,
                accentColor: accentColor,
              ),
            ),
            _buildPageButton(
              icon: Icons.chevron_right,
              onPressed: paginacionData.hasNextPage
                  ? () =>
                      _cambiarPagina(provider, paginacionData.currentPage + 1)
                  : null,
              bgColor: bgColor,
              txtColor: txtColor,
              accentColor: accentColor,
            ),
            _buildPageButton(
              icon: Icons.last_page,
              onPressed: paginacionData.hasNextPage
                  ? () => _cambiarPagina(provider, paginacionData.totalPages)
                  : null,
              bgColor: bgColor,
              txtColor: txtColor,
              accentColor: accentColor,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: _buildPageSizeSelector(context, provider, txtColor),
            ),
          ],
        ),
        if (mostrarOrdenacion)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildSortControls(
                context, provider, bgColor, txtColor, accentColor),
          ),
      ],
    );
  }

  Widget _buildSortControls(BuildContext context, PaginacionProvider provider,
      Color bgColor, Color txtColor, Color accentColor) {
    // Obtener opciones de ordenación, primero desde los campos proporcionados,
    // luego desde los metadatos del provider
    List<Map<String, String>> opcionesOrdenacion = [];

    if (camposParaOrdenar != null && camposParaOrdenar!.isNotEmpty) {
      opcionesOrdenacion = camposParaOrdenar!;
    } else {
      // Convertir lista de strings desde metadata a Map<String, String>
      final opciones = provider.opcionesSortBy;
      logDebug('Paginador: Opciones de ordenación desde metadatos: $opciones');
      opcionesOrdenacion = opciones
          .map((campo) => {
                'value': campo,
                'label': _formatearEtiquetaCampo(campo),
              })
          .toList();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ordenar por: ',
          style: TextStyle(
            color: txtColor.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: provider.ordenarPor,
              isDense: true,
              hint: Text(
                'Seleccionar campo',
                style:
                    TextStyle(color: txtColor.withOpacity(0.6), fontSize: 14),
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: txtColor.withOpacity(0.8),
              ),
              style: TextStyle(
                color: txtColor,
                fontSize: 14,
              ),
              dropdownColor: bgColor,
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('Sin ordenar'),
                ),
                ...opcionesOrdenacion.map((campo) {
                  return DropdownMenuItem<String>(
                    value: campo['value'],
                    child: Text(campo['label'] ?? campo['value'] ?? ''),
                  );
                }),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  logInfo('Paginador: Cambiando ordenación a: $newValue');
                  provider
                      .cambiarOrdenarPor(newValue.isEmpty ? null : newValue);

                  if (onSortByChanged != null) {
                    onSortByChanged!(newValue.isEmpty ? null : newValue);
                  }

                  if (onPageChange != null) {
                    onPageChange!();
                  }
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (provider.ordenarPor != null && provider.ordenarPor!.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: provider.orden,
                isDense: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: txtColor.withOpacity(0.8),
                ),
                style: TextStyle(
                  color: txtColor,
                  fontSize: 14,
                ),
                dropdownColor: bgColor,
                items: PaginacionProvider.opcionesOrden.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            entry.key == 'asc'
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 16,
                            color: txtColor),
                        const SizedBox(width: 4),
                        Text(entry.value),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    logInfo(
                        'Paginador: Cambiando dirección de orden a: $newValue');
                    provider.cambiarOrden(newValue);

                    if (onOrderChanged != null) {
                      onOrderChanged!(newValue);
                    }

                    if (onPageChange != null) {
                      onPageChange!();
                    }
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPageSizeSelector(
    BuildContext context,
    PaginacionProvider provider,
    Color txtColor,
  ) {
    // Capturar el valor actual para debugging
    int currentValue = provider.itemsPerPage;
    logDebug(
        'Paginador: Construyendo selector de tamaño - Valor actual: $currentValue, Opciones: ${PaginacionProvider.opcionesTamanoPagina}');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Items: ',
          style: TextStyle(
            color: txtColor.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        StatefulBuilder(
          builder: (context, setState) => DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: currentValue,
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
              items: PaginacionProvider.opcionesTamanoPagina.map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
              onChanged: (int? value) {
                if (value != null) {
                  logInfo(
                      'Paginador: Usuario seleccionó tamaño de página: $value');

                  // Actualizar el estado local para ver el cambio inmediatamente
                  // Verificar si el widget está montado antes de actualizar el estado
                  if (context.mounted) {
                    setState(() {
                      currentValue = value;
                    });
                  }

                  // Llamar al método del provider
                  provider.cambiarItemsPorPagina(value);

                  // Llamar a los callbacks si existen
                  if (onPageSizeChanged != null) {
                    logDebug(
                        'Paginador: Ejecutando callback onPageSizeChanged con valor: $value');
                    onPageSizeChanged!(value);
                  }

                  if (onPageChange != null) {
                    logDebug('Paginador: Ejecutando callback onPageChange');
                    onPageChange!();
                  }

                  // Verificar si el cambio se aplicó correctamente
                  Future.delayed(const Duration(milliseconds: 100), () {
                    // Verificar que el contexto sigue montado antes de acceder a él
                    if (context.mounted) {
                      logDebug(
                          'Paginador: Verificando cambio - Nuevo valor en provider: ${provider.itemsPerPage}');
                    }
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  void _cambiarPagina(PaginacionProvider provider, int pagina) {
    logInfo('Paginador: Cambiando página a: $pagina');
    provider.cambiarPagina(pagina);

    if (onPageChange != null) {
      logDebug('Paginador: Ejecutando callback onPageChange');
      onPageChange!();
    }

    if (onPageChanged != null) {
      logDebug(
          'Paginador: Ejecutando callback onPageChanged con página: $pagina');
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
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: onPressed == null ? txtColor.withOpacity(0.3) : txtColor,
        ),
        onPressed: onPressed,
        splashRadius: 20,
        tooltip: onPressed == null ? null : 'Ir a la página',
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
        padding: EdgeInsets.zero,
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
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: isSelected ? accentColor : bgColor,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: isSelected ? null : onPressed,
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: Text(
                pageNum.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : txtColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Formatea un nombre de campo para mostrarlo como etiqueta
  String _formatearEtiquetaCampo(String campo) {
    if (campo.isEmpty) {
      return '';
    }

    // Convertir camelCase o snake_case a palabras separadas
    String resultado = campo.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (Match match) => ' ${match.group(0)!.toLowerCase()}',
    );

    resultado = resultado.replaceAll('_', ' ');

    // Capitalizar primera letra
    if (resultado.isNotEmpty) {
      resultado = resultado[0].toUpperCase() + resultado.substring(1);
    }

    return resultado;
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
