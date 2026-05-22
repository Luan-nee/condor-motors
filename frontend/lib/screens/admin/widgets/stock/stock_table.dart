import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_table_row.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/widgets/common/smooth_scroll.widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TableProducts extends StatefulWidget {
  final String selectedSucursalId;
  final List<Producto>? productos;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final Function(Producto)? onEditProducto;
  final Function(Producto)? onVerDetalles;
  final Function(Producto)? onVerStockDetalles;
  final Function(String)? onSort;
  final String? sortBy;
  final String? sortOrder;
  final bool filtrosActivos;

  const TableProducts({
    super.key,
    required this.selectedSucursalId,
    this.productos,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.onEditProducto,
    this.onVerDetalles,
    this.onVerStockDetalles,
    this.onSort,
    this.sortBy,
    this.sortOrder,
    this.filtrosActivos = false,
  });

  @override
  State<TableProducts> createState() => _TableProductsState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('selectedSucursalId', selectedSucursalId))
      ..add(IterableProperty<Producto>('productos', productos))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(StringProperty('error', error))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onRetry', onRetry))
      ..add(
        ObjectFlagProperty<Function(Producto)?>.has(
          'onEditProducto',
          onEditProducto,
        ),
      )
      ..add(
        ObjectFlagProperty<Function(Producto)?>.has(
          'onVerDetalles',
          onVerDetalles,
        ),
      )
      ..add(
        ObjectFlagProperty<Function(Producto)?>.has(
          'onVerStockDetalles',
          onVerStockDetalles,
        ),
      )
      ..add(ObjectFlagProperty<Function(String)?>.has('onSort', onSort))
      ..add(StringProperty('sortBy', sortBy))
      ..add(StringProperty('sortOrder', sortOrder))
      ..add(DiagnosticsProperty<bool>('filtrosActivos', filtrosActivos));
  }
}

class _TableProductsState extends State<TableProducts> {
  late final ScrollController _scrollController;

  final List<String> _columnHeaders = const <String>[
    'Producto',
    'Categoría',
    'Marca',
    'Stock',
    'Mínimo',
    'Acciones',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasProducts =
        widget.productos != null && widget.productos!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Encabezado de la tabla (Diseño flotante premium con top border radius)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: const BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(children: _buildStandardHeaders()),
        ),

        // Barra de progreso lineal roja de 2px cuando está cargando pero ya hay datos en pantalla
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 2,
            child: (widget.isLoading && hasProducts)
                ? const LinearProgressIndicator(
                    backgroundColor: Colors.white12,
                    color: AppTheme.primaryColor,
                    minHeight: 2,
                  )
                : const SizedBox(height: 2),
          ),
        ),

        // Cuerpo dinámico condicional
        Expanded(child: _buildTableBody(context, hasProducts)),
      ],
    );
  }

  Widget _buildTableBody(BuildContext context, bool hasProducts) {
    // 1. Si está cargando y no hay datos previos
    if (widget.isLoading && !hasProducts) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text(
              'Cargando inventario...',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    // 2. Si ocurrió un error
    if (widget.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              color: AppTheme.primaryColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar datos: ${widget.error}',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            if (widget.onRetry != null) ...<Widget>[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                onPressed: widget.onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // 3. Si no hay sucursal seleccionada
    if (widget.selectedSucursalId.isEmpty) {
      return const Center(
        child: Text(
          'Seleccione una sucursal para ver su inventario',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    // 4. Si la lista está vacía
    if (!hasProducts) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppTheme.deepSurface,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
          ),
          child: _buildNoProductosMessage(
            hayFiltrosAplicados: widget.filtrosActivos,
          ),
        ),
      );
    }

    // 5. Renderizado normal de la lista con micro-animación de opacidad y scroll suave
    return AnimatedOpacity(
      opacity: widget.isLoading ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: SmoothScroll(
        controller: _scrollController,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: widget.productos!.length,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final producto = widget.productos![index];
            return StockTableRow(
              producto: producto,
              onVerStockDetalles: widget.onVerStockDetalles,
              onVerDetalles: widget.onVerDetalles,
              isLast: index == widget.productos!.length - 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoProductosMessage({required bool hayFiltrosAplicados}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FaIcon(
            hayFiltrosAplicados
                ? FontAwesomeIcons.filter
                : FontAwesomeIcons.boxOpen,
            color: hayFiltrosAplicados ? Colors.amber : Colors.white24,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            hayFiltrosAplicados
                ? 'No se encontraron productos'
                : 'No hay productos en esta sucursal',
            style: TextStyle(
              color: Colors.white.withAlpha(178),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hayFiltrosAplicados
                ? 'Ningún producto coincide con los filtros o criterios de búsqueda aplicados'
                : 'Considera agregar productos a esta sucursal',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          if (hayFiltrosAplicados) ...<Widget>[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed:
                  widget.onRetry ??
                  () {
                    debugPrint(
                      'No se configuró un manejador para reiniciar filtros',
                    );
                  },
              icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 14),
              label: const Text('Reiniciar filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String label,
    String field, {
    TextAlign textAlign = TextAlign.left,
    required int flex,
  }) {
    final isSorted = widget.sortBy == field;
    final isCenter = textAlign == TextAlign.center;
    final isRight = textAlign == TextAlign.right;

    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: widget.onSort != null ? () => widget.onSort!(field) : null,
        child: Row(
          mainAxisAlignment: isRight
              ? MainAxisAlignment.end
              : (isCenter ? MainAxisAlignment.center : MainAxisAlignment.start),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isSorted) ...[
              const SizedBox(width: 4),
              Icon(
                widget.sortOrder == 'asc'
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 14,
                color: AppTheme.primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStandardHeaders() {
    return <Widget>[
      _buildHeaderCell(_columnHeaders[0], 'nombre', flex: 35),
      _buildHeaderCell(
        _columnHeaders[1],
        'categoria',
        textAlign: TextAlign.center,
        flex: 15,
      ),
      _buildHeaderCell(
        _columnHeaders[2],
        'marca',
        textAlign: TextAlign.center,
        flex: 15,
      ),
      _buildHeaderCell(
        _columnHeaders[3],
        'stock',
        textAlign: TextAlign.center,
        flex: 10,
      ),
      _buildHeaderCell(
        _columnHeaders[4],
        'stockMinimo',
        textAlign: TextAlign.center,
        flex: 10,
      ),
      Expanded(
        flex: 15,
        child: Text(
          _columnHeaders[5],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];
  }
}
