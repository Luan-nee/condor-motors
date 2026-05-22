import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_detalle_sucursal.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StockTableRow extends StatelessWidget {
  final Producto producto;
  final Function(Producto)? onVerStockDetalles;
  final Function(Producto)? onVerDetalles;
  final bool isLast;

  const StockTableRow({
    super.key,
    required this.producto,
    this.onVerStockDetalles,
    this.onVerDetalles,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final int stockActual = producto.stock;
    final int stockMinimo = producto.stockMinimo ?? 0;

    final Color statusColor = _getStatusColor(producto);
    final FaIconData statusIcon = _getStatusIcon(producto);
    final String statusText = _getStatusText(producto);
    final String? imageUrl = ProductoRepository.getProductoImageUrl(producto);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.deepSurface,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(8))
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: <Widget>[
          // Nombre del producto (35%)
          Expanded(
            flex: 35,
            child: Row(
              children: <Widget>[
                // Imagen del producto (36x36, compact y redonda como en productos)
                _buildProductImage(imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              producto.nombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Mostrar badge de liquidación si aplica
                          if (producto.liquidacion) ...<Widget>[
                            const SizedBox(width: 6),
                            const FaIcon(
                              FontAwesomeIcons.fire,
                              size: 10,
                              color: Colors.orange,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Mostrar precio de venta / liquidación
                      Text(
                        producto.liquidacion && producto.precioOferta != null
                            ? 'Precio: S/ ${producto.precioOferta!.toStringAsFixed(2)}'
                            : 'Precio: S/ ${producto.precioVenta.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: producto.liquidacion
                              ? const Color(0xFFFFC107)
                              : Colors.white54,
                          fontSize: 11,
                          fontWeight: producto.liquidacion
                              ? FontWeight.bold
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Categoría (15%)
          Expanded(
            flex: 15,
            child: Text(
              producto.categoria,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Marca (15%)
          Expanded(
            flex: 15,
            child: Text(
              producto.marca,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Stock actual (10%)
          Expanded(
            flex: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  stockActual.toString(),
                  style: TextStyle(
                    color: (producto.stock <= 0 || producto.stockBajo == true)
                        ? statusColor
                        : Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (producto.stock <= 0 ||
                    producto.stockBajo == true) ...<Widget>[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: statusText,
                    child: FaIcon(statusIcon, color: statusColor, size: 11),
                  ),
                ],
              ],
            ),
          ),
          // Stock mínimo (10%)
          Expanded(
            flex: 10,
            child: Text(
              stockMinimo > 0 ? stockMinimo.toString() : '-',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          // Acciones (15%)
          Expanded(
            flex: 15,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _ActionButton(
                  icon: FontAwesomeIcons.magnifyingGlass,
                  color: Colors.white54,
                  onPressed: () {
                    if (onVerDetalles != null) {
                      onVerDetalles!(producto);
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return StockDetalleSucursalDialog(producto: producto);
                        },
                      );
                    }
                  },
                  tooltip: 'Ver detalles del producto',
                ),
                _ActionButton(
                  icon: FontAwesomeIcons.penToSquare,
                  color: Colors.white54,
                  onPressed: () {
                    onVerStockDetalles?.call(producto);
                  },
                  tooltip: 'Gestionar stock e inventario',
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

  Color _getStatusColor(Producto producto) {
    if (producto.stock <= 0) {
      return const Color(0xFF4A4A4A);
    }
    if (producto.stockBajo == true) {
      return AppTheme.primaryColor;
    }
    return Colors.green;
  }

  FaIconData _getStatusIcon(Producto producto) {
    if (producto.stock <= 0) {
      return FontAwesomeIcons.ban;
    }
    if (producto.stockBajo == true) {
      return FontAwesomeIcons.triangleExclamation;
    }
    return FontAwesomeIcons.check;
  }

  String _getStatusText(Producto producto) {
    if (producto.stock <= 0) {
      return 'Agotado';
    }
    if (producto.stockBajo == true) {
      return 'Stock bajo';
    }
    return 'Disponible';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Producto>('producto', producto))
      ..add(DiagnosticsProperty<bool>('isLast', isLast))
      ..add(
        ObjectFlagProperty<Function(Producto)?>.has(
          'onVerStockDetalles',
          onVerStockDetalles,
        ),
      )
      ..add(
        ObjectFlagProperty<Function(Producto)?>.has(
          'onVerDetalles',
          onVerDetalles,
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
