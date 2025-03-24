import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/producto.model.dart';
import '../../../models/sucursal.model.dart';
import '../utils/productos_utils.dart';

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
}

class _ProductosTableState extends State<ProductosTable>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<Producto>> _productosAgrupados = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _agruparProductos();
  }

  @override
  void didUpdateWidget(ProductosTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Verificar si realmente los productos han cambiado (por contenido, no solo por referencia)
    bool productosHanCambiado = oldWidget.productos.length != widget.productos.length;
    
    if (!productosHanCambiado && oldWidget.productos.isNotEmpty) {
      // Verificar algunos productos para detectar cambios
      final oldProducto = oldWidget.productos.first;
      final newProducto = widget.productos.firstWhere(
        (p) => p.id == oldProducto.id, 
        orElse: () => oldProducto
      );
      
      // Si algún campo importante cambió, consideramos que los productos cambiaron
      productosHanCambiado = 
          oldProducto.nombre != newProducto.nombre ||
          oldProducto.stock != newProducto.stock ||
          oldProducto.precioVenta != newProducto.precioVenta;
    }
    
    if (productosHanCambiado || oldWidget.key != widget.key) {
      debugPrint('ProductosTable: Productos actualizados, reagrupando (${widget.productos.length} items)');
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
          children: [
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
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.5),
          indicatorColor: const Color(0xFFE31E24),
          indicatorWeight: 3,
          tabs: [
            Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(FontAwesomeIcons.boxOpen, size: 16),
                  const SizedBox(width: 8),
                  const Text('Todos'),
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
                children: [
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
                children: [
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
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Todos los productos
              _buildProductosTabla(widget.productos),

              // Productos con stock bajo
              _buildProductosTabla(_productosAgrupados['stockBajo'] ?? []),

              // Productos agotados
              _buildProductosTabla(_productosAgrupados['agotados'] ?? []),
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
            boxShadow: [
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
      columns: const [
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
      rows: productosLista.map((producto) {
        final bool stockBajo = producto.tieneStockBajo();

        return DataRow(
          cells: [
            // Nombre
            DataCell(
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 32,
                    decoration: BoxDecoration(
                      color: stockBajo
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
                children: [
                  Text(
                    '${producto.stock}',
                    style: TextStyle(
                      color: stockBajo ? const Color(0xFFE31E24) : Colors.white,
                      fontWeight:
                          stockBajo ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (stockBajo) ...[
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
                children: [
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
                children: [
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

  Widget _buildTableHeader() {
    // Verificar si el ordenamiento está habilitado
    final canSort = widget.onSort != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('ID', field: 'id', canSort: canSort),
          _buildHeaderCell('Imagen'),
          _buildHeaderCell('Producto',
              flex: 3, field: 'nombre', canSort: canSort),
          _buildHeaderCell('SKU', flex: 2, field: 'sku', canSort: canSort),
          _buildHeaderCell('Categoría',
              flex: 2, field: 'categoria', canSort: canSort),
          _buildHeaderCell('Marca', flex: 2, field: 'marca', canSort: canSort),
          _buildHeaderCell('Precio Compra',
              flex: 2, field: 'precioCompra', canSort: canSort),
          _buildHeaderCell('Precio Venta',
              flex: 2, field: 'precioVenta', canSort: canSort),
          _buildHeaderCell('Stock', field: 'stock', canSort: canSort),
          _buildHeaderCell('Acciones', flex: 2, alignment: Alignment.center),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String text, {
    int flex = 1,
    String? field,
    bool canSort = false,
    Alignment alignment = Alignment.centerLeft,
  }) {
    final isCurrentSortField = field != null && widget.sortBy == field;

    return Expanded(
      flex: flex,
      child: canSort && field != null
          ? InkWell(
              onTap: () => widget.onSort?.call(field),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        color: isCurrentSortField
                            ? const Color(0xFFE31E24)
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isCurrentSortField)
                      Icon(
                        widget.sortOrder == 'asc'
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                        color: const Color(0xFFE31E24),
                      ),
                  ],
                ),
              ),
            )
          : Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: alignment == Alignment.center
                  ? TextAlign.center
                  : TextAlign.left,
            ),
    );
  }
}
