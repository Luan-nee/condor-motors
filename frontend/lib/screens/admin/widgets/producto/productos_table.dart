import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/widgets/common/smooth_scroll.widget.dart';
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
}

class _ProductosTableState extends State<ProductosTable> {
  late final ScrollController _scrollController;

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

    if (widget.productos.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _TableHeader(
            sortBy: widget.sortBy,
            sortOrder: widget.sortOrder,
            onSort: widget.onSort,
          ),
          Expanded(
            child: Center(
              child: widget.isLoading
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Cargando inventario...',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    )
                  : Column(
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
                          style: TextStyle(color: Colors.white.withAlpha(178)),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _TableHeader(
          sortBy: widget.sortBy,
          sortOrder: widget.sortOrder,
          onSort: widget.onSort,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 2,
            child: widget.isLoading
                ? const LinearProgressIndicator(
                    backgroundColor: Colors.white12,
                    color: AppTheme.primaryColor,
                    minHeight: 2,
                  )
                : const SizedBox(height: 2),
          ),
        ),
        Expanded(
          child: AnimatedOpacity(
            opacity: widget.isLoading ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: SmoothScroll(
              controller: _scrollController,
              child: ListView.builder(
                controller: _scrollController,
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
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: _buildHeaderCell('Producto', 'nombre')),
          Expanded(flex: 2, child: _buildHeaderCell('SKU', 'sku')),
          Expanded(flex: 2, child: _buildHeaderCell('Categoría', 'categoria')),
          Expanded(
            flex: 2,
            child: _buildHeaderCell(
              'Stock',
              'stock',
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildHeaderCell(
              'Precio',
              'precioVenta',
              textAlign: TextAlign.right,
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Acciones',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String label,
    String field, {
    TextAlign textAlign = TextAlign.left,
  }) {
    final isSorted = sortBy == field;
    return InkWell(
      onTap: onSort != null ? () => onSort!(field) : null,
      child: Row(
        mainAxisAlignment: textAlign == TextAlign.right
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
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
              sortOrder == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: AppTheme.primaryColor,
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
        color: AppTheme.deepSurface,
        border: Border(bottom: BorderSide(color: Colors.white.withAlpha(25))),
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
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
                color: Colors.white70,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
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
                        ? AppTheme.primaryColor
                        : Colors.white,
                    fontWeight: (stockBajo || agotado) ? FontWeight.bold : null,
                  ),
                ),
                if (stockBajo || agotado) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: agotado
                        ? 'Agotado'
                        : 'Mínimo: ${producto.stockMinimo ?? 0}',
                    child: Icon(
                      agotado
                          ? FontAwesomeIcons.ban.data
                          : Icons.warning_amber_rounded,
                      size: 14,
                      color: agotado ? Colors.white24 : AppTheme.primaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Precio
          Expanded(flex: 2, child: _buildPriceCell()),

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
                    onPressed: onEnable != null
                        ? () => onEnable!(producto)
                        : null,
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
                errorBuilder: (_, _, _) =>
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
      message:
          'Ganancia: S/ ${ganancia.toStringAsFixed(2)}\nMargen: ${margen.toStringAsFixed(2)}%',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (producto.liquidacion && producto.precioOferta != null) ...[
            Text(
              producto.getPrecioOfertaFormateado()!,
              style: const TextStyle(
                color: Color(
                  0xFFFFC107,
                ), // Ámbar brillante para el precio activo
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
  final FaIconData icon;
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
