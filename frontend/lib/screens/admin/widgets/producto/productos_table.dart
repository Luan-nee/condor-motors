import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/utils/productos_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductosTable extends StatefulWidget {
  final List<Producto> productos;
  final List<Sucursal> sucursales;
  final Function(Producto) onEdit;
  final Function(Producto) onDelete;
  final Function(Producto) onViewDetails;
  final Function(String)? onSort;
  final String? sortBy;
  final String? sortOrder;

  const ProductosTable({
    super.key,
    required this.productos,
    required this.onEdit,
    required this.onDelete,
    required this.sucursales,
    required this.onViewDetails,
    this.onSort,
    this.sortBy,
    this.sortOrder,
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
      ..add(StringProperty('sortOrder', sortOrder));
  }
}

class _ProductosTableState extends State<ProductosTable>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<Producto>> _productosAgrupados = <String, List<Producto>>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _agruparProductos();
  }

  @override
  void didUpdateWidget(ProductosTable oldWidget) {
    super.didUpdateWidget(oldWidget);

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
      _agruparProductos();

      // Forzar reconstrucción del widget
      setState(() {});
    }
  }

  void _agruparProductos() {
    _productosAgrupados =
        ProductosUtils.agruparProductosPorDisponibilidad(widget.productos);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const FaIcon(
              FontAwesomeIcons.boxOpen,
              size: 48,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos disponibles',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega productos utilizando el botón "Nuevo Producto"',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.5),
          indicatorColor: const Color(0xFFE31E24),
          indicatorWeight: 4,
          tabs: <Widget>[
            Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const FaIcon(FontAwesomeIcons.boxOpen, size: 16),
                  const SizedBox(width: 8),
                  const Text('Disponibles'),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.productos.length}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const FaIcon(FontAwesomeIcons.triangleExclamation,
                      size: 16, color: Color(0xFFE31E24)),
                  const SizedBox(width: 8),
                  const Text('Stock Bajo'),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_productosAgrupados['stockBajo']?.length ?? 0}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FaIcon(FontAwesomeIcons.ban,
                      size: 16, color: Colors.red.shade800),
                  const SizedBox(width: 8),
                  const Text('Agotados'),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_productosAgrupados['agotados']?.length ?? 0}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FaIcon(FontAwesomeIcons.ban,
                      size: 16, color: Colors.red.shade800),
                  const SizedBox(width: 8),
                  const Text('inhabilitados'),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_productosAgrupados['inhabilitados']?.length ?? 0}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              // Todos los disponibles
              _buildProductosTabla(
                  _productosAgrupados['disponibles'] ?? <Producto>[]),

              // Productos con stock bajo
              _buildProductosTabla(
                  _productosAgrupados['stockBajo'] ?? <Producto>[]),

              // Productos agotados
              _buildProductosTabla(
                  _productosAgrupados['agotados'] ?? <Producto>[]),

              // Productos inhalitados
              _buildProductosTabla(
                  _productosAgrupados['inhabilitados'] ?? <Producto>[]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductosTabla(List<Producto> productosLista) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.circular(8),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.white.withOpacity(0.1),
              ),
              child: _buildDataTable(context, productosLista),
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
            return const Color(0xFFE31E24).withOpacity(0.1);
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
      columns: const <DataColumn>[
        DataColumn(
          label: Text('Producto'),
          tooltip: 'Nombre del producto',
        ),
        DataColumn(
          label: Text('SKU'),
          tooltip: 'Código único del producto',
        ),
        DataColumn(
          label: Text('Categoría'),
          tooltip: 'Categoría del producto',
        ),
        DataColumn(
          label: Text('Stock'),
          tooltip: 'Cantidad disponible',
          numeric: true,
        ),
        DataColumn(
          label: Text('Precio'),
          tooltip: 'Precio de venta',
          numeric: true,
        ),
        DataColumn(
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
                  Container(
                    width: 8,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (stockBajo || agotado)
                          ? const Color(0xFFE31E24)
                          : const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      producto.nombre,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: stockBajo
                            ? TextDecoration.none
                            : TextDecoration.none,
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
                    color: Colors.white.withOpacity(0.1),
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
                      color: stockBajo ? const Color(0xFFE31E24) : Colors.white,
                      fontWeight:
                          stockBajo ? FontWeight.bold : FontWeight.normal,
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
                  ]
                ],
              ),
            ),

            // Precio
            DataCell(
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
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
              ),
            ),

            // Acciones
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(
                      FontAwesomeIcons.eye,
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
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Color(0xFFE31E24),
                      size: 20,
                    ),
                    tooltip: 'Eliminar producto',
                    onPressed: () => widget.onDelete(producto),
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
