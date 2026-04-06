import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductosTable extends StatefulWidget {
  final List<Producto> productos;
  final List<Sucursal> sucursales;
  final Function(Producto) onEdit;
  final Function(Producto)? onDelete;
  final Function(Producto) onViewDetails;
  final Function(String)? onSort;
  final String? sortBy;
  final String? sortOrder;
  final bool isLoading;
  final Function(Producto)? onEnable;

  const ProductosTable({
    super.key,
    required this.productos,
    required this.sucursales,
    required this.onEdit,
    this.onDelete,
    required this.onViewDetails,
    this.onSort,
    this.sortBy,
    this.sortOrder,
    this.isLoading = false,
    this.onEnable,
  });

  @override
  State<ProductosTable> createState() => _ProductosTableState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Producto>('productos', productos))
      ..add(IterableProperty<Sucursal>('sucursales', sucursales))
      ..add(ObjectFlagProperty<Function(Producto)>.has('onEdit', onEdit))
      ..add(ObjectFlagProperty<Function(Producto)>.has('onDelete', onDelete))
      ..add(ObjectFlagProperty<Function(Producto)>.has(
          'onViewDetails', onViewDetails))
      ..add(ObjectFlagProperty<Function(String)?>.has('onSort', onSort))
      ..add(StringProperty('sortBy', sortBy))
      ..add(StringProperty('sortOrder', sortOrder))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(
          ObjectFlagProperty<Function(Producto p1)?>.has('onEnable', onEnable));
  }
}

class _ProductosTableState extends State<ProductosTable>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _loadingAnimation = CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProductosTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      if (widget.isLoading) {
        _loadingController.repeat();
      } else {
        _loadingController.stop();
      }
    }
    // Verificar si realmente los productos han cambiado (por contenido, no solo por referencia)
    bool productosHanCambiado =
        oldWidget.productos.length != widget.productos.length;

    if (!productosHanCambiado && widget.productos.isNotEmpty) {
      // Verificar más profundamente comparando varios productos
      // Tomar una muestra de productos para comparar (hasta 5)
      final int sampleSize =
          widget.productos.length > 5 ? 5 : widget.productos.length;

      for (int i = 0; i < sampleSize; i++) {
        final Producto oldProducto = oldWidget.productos[i];
        final Producto newProducto = widget.productos.firstWhere(
            (Producto p) => p.id == oldProducto.id,
            orElse: () => oldProducto);

        // Si algún campo importante cambió, consideramos que los productos cambiaron
        if (oldProducto.nombre != newProducto.nombre ||
            oldProducto.stock != newProducto.stock ||
            oldProducto.precioVenta != newProducto.precioVenta ||
            oldProducto.precioCompra != newProducto.precioCompra ||
            oldProducto.precioOferta != newProducto.precioOferta ||
            oldProducto.marca != newProducto.marca ||
            oldProducto.categoria != newProducto.categoria) {
          productosHanCambiado = true;
          break;
        }
      }
    }

    // Si la key cambió significa que hubo una operación que requiere reconstrucción
    final bool keyDiferente = oldWidget.key != widget.key;

    if (productosHanCambiado || keyDiferente) {
      debugPrint(
          'ProductosTable: Actualización detectada. Productos cambiados: $productosHanCambiado, Key diferente: $keyDiferente');

      // Forzar reconstrucción del widget
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.productos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(
              color: Color(0xFFE31E24),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando productos...',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    if (widget.productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const FaIcon(
              FontAwesomeIcons.boxOpen,
              color: Colors.white24,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos para mostrar',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _buildProductosTabla(widget.productos),
            ),
          ],
        ),
        if (widget.isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black54,
              child: AnimatedBuilder(
                animation: _loadingAnimation,
                builder: (context, child) {
                  return Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFFE31E24).withValues(
                              alpha: 0.8 + (0.2 * _loadingAnimation.value)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductosTabla(List<Producto> productosLista) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.circular(8),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.white.withValues(alpha: 0.1),
              ),
              child: _buildDataTable(context, productosLista),
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildDataTable(BuildContext context, List<Producto> productosLista) {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFF1A1A1A)),
      dataRowColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFE31E24).withValues(alpha: 0.1);
          }
          return const Color(0xFF222222);
        },
      ),
      dividerThickness: 1,
      columnSpacing: 16,
      horizontalMargin: 16,
      headingTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      dataTextStyle: const TextStyle(
        color: Colors.white70,
      ),
      columns: <DataColumn>[
        DataColumn(
          label: Row(
            children: <Widget>[
              const Text('Producto'),
              const SizedBox(width: 4),
              if (widget.sortBy == 'nombre')
                Icon(
                  widget.sortOrder == 'asc'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 16,
                  color: Colors.white,
                ),
            ],
          ),
          tooltip: 'Nombre del producto',
          onSort: widget.onSort != null
              ? (_, __) => widget.onSort!('nombre')
              : null,
        ),
        DataColumn(
          label: Row(
            children: <Widget>[
              const Text('SKU'),
              const SizedBox(width: 4),
              if (widget.sortBy == 'sku')
                Icon(
                  widget.sortOrder == 'asc'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 16,
                  color: Colors.white,
                ),
            ],
          ),
          tooltip: 'Código único del producto',
          onSort:
              widget.onSort != null ? (_, __) => widget.onSort!('sku') : null,
        ),
        DataColumn(
          label: Row(
            children: <Widget>[
              const Text('Categoría'),
              const SizedBox(width: 4),
              if (widget.sortBy == 'categoria')
                Icon(
                  widget.sortOrder == 'asc'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 16,
                  color: Colors.white,
                ),
            ],
          ),
          tooltip: 'Categoría del producto',
          onSort: widget.onSort != null
              ? (_, __) => widget.onSort!('categoria')
              : null,
        ),
        DataColumn(
          label: Row(
            children: <Widget>[
              const Text('Stock'),
              const SizedBox(width: 4),
              if (widget.sortBy == 'stock')
                Icon(
                  widget.sortOrder == 'asc'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 16,
                  color: Colors.white,
                ),
            ],
          ),
          tooltip: 'Cantidad disponible',
          numeric: true,
          onSort:
              widget.onSort != null ? (_, __) => widget.onSort!('stock') : null,
        ),
        DataColumn(
          label: Row(
            children: <Widget>[
              const Text('Precio'),
              const SizedBox(width: 4),
              if (widget.sortBy == 'precioVenta')
                Icon(
                  widget.sortOrder == 'asc'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 16,
                  color: Colors.white,
                ),
            ],
          ),
          tooltip: 'Precio de venta',
          numeric: true,
          onSort: widget.onSort != null
              ? (_, __) => widget.onSort!('precioVenta')
              : null,
        ),
        const DataColumn(
          label: Text('Acciones'),
          tooltip: 'Acciones disponibles',
        ),
      ],
      rows: productosLista.map((Producto producto) {
        final bool stockBajo = producto.tieneStockBajo();
        final bool agotado = producto.stock == 0;

        return DataRow(
          cells: <DataCell>[
            // Nombre
            DataCell(
              Row(
                children: <Widget>[
                  // Miniatura de imagen de producto
                  if (ProductoRepository.getProductoImageUrl(producto) !=
                          null &&
                      ProductoRepository.getProductoImageUrl(producto)!
                          .isNotEmpty)
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.black26,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          ProductoRepository.getProductoImageUrl(producto)!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image,
                                  color: Colors.white24, size: 18),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.black26,
                      ),
                      child: const Icon(Icons.image,
                          color: Colors.white24, size: 18),
                    ),
                  // Indicador de estado
                  Container(
                    width: 8,
                    height: 32,
                    decoration: BoxDecoration(
                      color: agotado
                          ? const Color(0xFF4A4A4A) // Gris oscuro para agotados
                          : stockBajo
                              ? const Color(0xFFE31E24) // Rojo para stock bajo
                              : const Color(
                                  0xFF4CAF50), // Verde para disponibles
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      producto.nombre,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // SKU
            DataCell(
              Text(
                producto.sku,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  letterSpacing: 1.0,
                ),
              ),
            ),

            // Categoría
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  producto.categoria,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Stock
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '${producto.stock}',
                    style: TextStyle(
                      color: agotado
                          ? const Color(0xFF4A4A4A) // Gris oscuro para agotados
                          : stockBajo
                              ? const Color(0xFFE31E24) // Rojo para stock bajo
                              : Colors.white, // Normal para disponibles
                      fontWeight: (stockBajo || agotado)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (stockBajo) ...<Widget>[
                    const SizedBox(width: 4),
                    Tooltip(
                      message:
                          'Stock bajo: Mínimo ${producto.stockMinimo ?? 0}',
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFE31E24),
                        size: 16,
                      ),
                    ),
                  ],
                  if (agotado) ...<Widget>[
                    const SizedBox(width: 4),
                    const Tooltip(
                      message: 'Producto agotado',
                      child: Icon(
                        FontAwesomeIcons.ban,
                        color: Color(0xFF4A4A4A),
                        size: 16,
                      ),
                    ),
                  ]
                ],
              ),
            ),

            // Precio
            DataCell(
              Builder(
                builder: (context) {
                  final double precioActivo = producto.getPrecioActual();
                  final double ganancia = precioActivo - producto.precioCompra;
                  final double margen = producto.precioCompra > 0 
                      ? (ganancia / producto.precioCompra) * 100 
                      : 0;
                  
                  return Tooltip(
                    message:
                        'Ganancia: S/ ${ganancia.toStringAsFixed(2)}\n'
                        'Margen: ${margen.toStringAsFixed(2)}%',
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        if (producto.liquidacion && producto.precioOferta != null) ...[
                          Text(
                            producto.getPrecioOfertaFormateado() ?? '',
                            style: TextStyle(
                              color: Colors.amber[400],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            producto.getPrecioVentaFormateado(),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ] else ...[
                          Text(
                            producto.getPrecioVentaFormateado(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (producto.estaEnOferta())
                            Text(
                              producto.getPrecioOfertaFormateado() ?? '',
                              style: TextStyle(
                                color: Colors.amber[400],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Acciones
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (producto.stock == 0 &&
                      (producto.precioVenta == 0 ||
                          producto.precioVenta == 0.0))
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.boxOpen,
                          color: Color.fromARGB(255, 235, 151, 41), size: 22),
                      tooltip: 'Habilitar producto',
                      onPressed: widget.onEnable != null
                          ? () => widget.onEnable!(producto)
                          : null,
                    ),
                  IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: Colors.blue,
                      size: 20,
                    ),
                    tooltip: 'Ver detalles',
                    onPressed: () => widget.onViewDetails(producto),
                  ),
                  IconButton(
                    icon: const Icon(
                      FontAwesomeIcons.penToSquare,
                      color: Colors.white70,
                      size: 20,
                    ),
                    tooltip: 'Editar producto',
                    onPressed: () => widget.onEdit(producto),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
