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
    // Solo actualizar el controlador de carga si el estado de carga realmente cambió
    if (oldWidget.isLoading != widget.isLoading) {
      if (widget.isLoading) {
        _loadingController.repeat();
      } else {
        _loadingController.stop();
      }
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
                color: Colors.white.withAlpha(178),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _TableHeader(
              sortBy: widget.sortBy,
              sortOrder: widget.sortOrder,
              onSort: widget.onSort,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.productos.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  return _ProductoTableRow(
                    producto: widget.productos[index],
                    onEdit: widget.onEdit,
                    onViewDetails: widget.onViewDetails,
                    onEnable: widget.onEnable,
                    isLast: index == widget.productos.length - 1,
                  );
                },
              ),
            ),
          ],
        ),
        if (widget.isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black26,
              child: Center(
                child: AnimatedBuilder(
                  animation: _loadingAnimation,
                  builder: (context, child) {
                    return SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFFE31E24).withAlpha(
                              (204 + (51 * _loadingAnimation.value)).toInt()),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String? sortBy;
  final String? sortOrder;
  final Function(String)? onSort;

  const _TableHeader({this.sortBy, this.sortOrder, this.onSort});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: _buildHeaderCell('Producto', 'nombre')),
          Expanded(flex: 2, child: _buildHeaderCell('SKU', 'sku')),
          Expanded(flex: 2, child: _buildHeaderCell('Categoría', 'categoria')),
          Expanded(
              flex: 2,
              child: _buildHeaderCell('Stock', 'stock', textAlign: TextAlign.right)),
          Expanded(
              flex: 2,
              child: _buildHeaderCell('Precio', 'precioVenta',
                  textAlign: TextAlign.right)),
          const Expanded(
            flex: 2,
            child: Text(
              'Acciones',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, String field,
      {TextAlign textAlign = TextAlign.left}) {
    final isSorted = sortBy == field;
    return InkWell(
      onTap: onSort != null ? () => onSort!(field) : null,
      child: Row(
        mainAxisAlignment: textAlign == TextAlign.right
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          if (isSorted) ...[
            const SizedBox(width: 4),
            Icon(
              sortOrder == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: const Color(0xFFE31E24),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductoTableRow extends StatelessWidget {
  final Producto producto;
  final Function(Producto) onEdit;
  final Function(Producto) onViewDetails;
  final Function(Producto)? onEnable;
  final bool isLast;

  const _ProductoTableRow({
    required this.producto,
    required this.onEdit,
    required this.onViewDetails,
    this.onEnable,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final bool stockBajo = producto.tieneStockBajo();
    final bool agotado = producto.stock == 0;
    final String? imageUrl = ProductoRepository.getProductoImageUrl(producto);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        border: Border(
          bottom: BorderSide(color: Colors.white.withAlpha(25)),
        ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(8))
            : null,
      ),
      child: Row(
        children: [
          // Producto
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _buildProductImage(imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    producto.nombre,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // SKU
          Expanded(
            flex: 2,
            child: Text(
              producto.sku,
              style: const TextStyle(
                  color: Colors.white70, fontFamily: 'monospace', fontSize: 12),
            ),
          ),

          // Categoría
          Expanded(
            flex: 2,
            child: Text(
              producto.categoria,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Stock
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${producto.stock}',
                  style: TextStyle(
                    color: agotado
                        ? Colors.white24
                        : stockBajo
                            ? const Color(0xFFE31E24)
                            : Colors.white,
                    fontWeight: (stockBajo || agotado) ? FontWeight.bold : null,
                  ),
                ),
                if (stockBajo || agotado) ...[
                  const SizedBox(width: 4),
                  Icon(
                    agotado ? FontAwesomeIcons.ban : Icons.warning_amber_rounded,
                    size: 14,
                    color: agotado ? Colors.white24 : const Color(0xFFE31E24),
                  ),
                ],
              ],
            ),
          ),

          // Precio
          Expanded(
            flex: 2,
            child: _buildPriceCell(),
          ),

          // Acciones
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (producto.stock == 0 && producto.precioVenta == 0)
                  _ActionButton(
                    icon: FontAwesomeIcons.boxOpen,
                    color: Colors.orange,
                    onPressed: onEnable != null ? () => onEnable!(producto) : null,
                    tooltip: 'Habilitar',
                  ),
                _ActionButton(
                  icon: FontAwesomeIcons.magnifyingGlass,
                  color: Colors.white54,
                  onPressed: () => onViewDetails(producto),
                  tooltip: 'Detalles',
                ),
                _ActionButton(
                  icon: FontAwesomeIcons.penToSquare,
                  color: Colors.white54,
                  onPressed: () => onEdit(producto),
                  tooltip: 'Editar',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String? url) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.black26,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: 72,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image, color: Colors.white12, size: 18),
              )
            : const Icon(Icons.image, color: Colors.white12, size: 18),
      ),
    );
  }

  Widget _buildPriceCell() {
    final double precioActivo = producto.getPrecioActual();
    final double ganancia = precioActivo - producto.precioCompra;
    final double margen = producto.precioCompra > 0 
        ? (ganancia / producto.precioCompra) * 100 
        : 0;

    return Tooltip(
      message: 'Ganancia: S/ ${ganancia.toStringAsFixed(2)}\nMargen: ${margen.toStringAsFixed(2)}%',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (producto.liquidacion && producto.precioOferta != null) ...[
            Text(
              producto.getPrecioOfertaFormateado()!,
              style: const TextStyle(
                color: Color(0xFFFFC107), // Ámbar brillante para el precio activo
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              producto.getPrecioVentaFormateado(),
              style: TextStyle(
                color: Colors.white.withAlpha(102), // 40% opacidad (oscurito)
                fontSize: 11,
              ),
            ),
          ] else ...[
            Text(
              producto.getPrecioVentaFormateado(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (producto.estaEnOferta())
              Text(
                producto.getPrecioOfertaFormateado()!,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: FaIcon(icon, color: color, size: 16),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 20,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(8),
    );
  }
}
