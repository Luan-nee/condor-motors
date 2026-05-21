import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_detalle_sucursal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StockTableRow extends StatelessWidget {
  final Producto producto;
  final Function(Producto)? onVerStockDetalles;
  final Function(Producto)? onVerDetalles;

  const StockTableRow({
    super.key,
    required this.producto,
    this.onVerStockDetalles,
    this.onVerDetalles,
  });

  @override
  Widget build(BuildContext context) {
    final int stockActual = producto.stock;
    final int stockMinimo = producto.stockMinimo ?? 0;

    final Color statusColor = _getStatusColor(producto);
    final FaIconData statusIcon = _getStatusIcon(producto);
    final String statusText = _getStatusText(producto);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: <Widget>[
          // Nombre del producto (30%)
          Expanded(
            flex: 30,
            child: Row(
              children: <Widget>[
                // Imagen del producto
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ProductoRepository.getProductoImageUrl(producto) ?? '',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[800],
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.white38, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
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
                          // Mostrar badge de liquidación si aplica
                          if (producto.liquidacion)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color:
                                        Colors.orange.withValues(alpha: 0.5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  FaIcon(
                                    FontAwesomeIcons.fire,
                                    size: 10,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Liquidación',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (producto.descripcion != null &&
                          producto.descripcion!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          producto.descripcion!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Mostrar precio de liquidación si aplica
                      if (producto.liquidacion &&
                          producto.precioOferta != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                'Precio: ${producto.getPrecioActualFormateado()}',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                producto.getPrecioVentaFormateado(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
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
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Marca (15%)
          Expanded(
            flex: 15,
            child: Text(
              producto.marca,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Stock actual (10%)
          Expanded(
            flex: 10,
            child: Text(
              stockActual.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Stock mínimo (10%)
          Expanded(
            flex: 10,
            child: Text(
              stockMinimo > 0 ? stockMinimo.toString() : '-',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          // Estado (15%)
          Expanded(
            flex: 15,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FaIcon(
                        statusIcon,
                        color: statusColor,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Acciones (15%)
          Expanded(
            flex: 15,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.boxesStacked,
                    color: Colors.blue,
                    size: 16,
                  ),
                  onPressed: () {
                    onVerStockDetalles?.call(producto);
                  },
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  padding: EdgeInsets.zero,
                  tooltip: 'Ver detalles del inventario',
                  splashRadius: 20,
                ),
                IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.eye,
                    color: Colors.white70,
                    size: 16,
                  ),
                  onPressed: () {
                    if (onVerDetalles != null) {
                      onVerDetalles!(producto);
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return StockDetalleSucursalDialog(
                            producto: producto,
                          );
                        },
                      );
                    }
                  },
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  padding: EdgeInsets.zero,
                  tooltip: 'Ver detalles del producto',
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(Producto producto) {
    if (producto.stock <= 0) {
      return const Color(0xFF4A4A4A);
    }
    if (producto.stockBajo == true) {
      return const Color(0xFFE31E24);
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
      ..add(ObjectFlagProperty<Function(Producto)?>.has('onVerStockDetalles', onVerStockDetalles))
      ..add(ObjectFlagProperty<Function(Producto)?>.has('onVerDetalles', onVerDetalles));
  }
}
