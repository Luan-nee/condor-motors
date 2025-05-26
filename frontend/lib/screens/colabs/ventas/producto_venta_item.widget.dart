import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProductoVentaItemWidget extends StatelessWidget {
  final Producto producto;
  final int cantidad;
  final VoidCallback onEliminar;
  final void Function(int nuevaCantidad) onCambiarCantidad;

  const ProductoVentaItemWidget({
    super.key,
    required this.producto,
    required this.cantidad,
    required this.onEliminar,
    required this.onCambiarCantidad,
  });

  @override
  Widget build(BuildContext context) {
    final int stockDisponible = producto.stock;
    final bool stockLimitado = cantidad >= stockDisponible;
    final bool promocionActivada = producto.tienePromocion && cantidad > 0;

    // Usar getters del modelo
    final double precio = producto.getPrecioConDescuento(cantidad);
    final int productosGratis = producto.getProductosGratis(cantidad);
    final bool tienePromocionGratis = producto.tienePromocionGratis;
    final bool tieneDescuentoPorcentual = producto.tieneDescuentoPorcentual;
    final bool enLiquidacion = producto.estaEnLiquidacion;
    final String url = ProductoRepository.getProductoImageUrl(producto) ?? '';
    final int? porcentajeDescuento = producto.porcentajeDescuento;
    final int? cantidadMinima = producto.cantidadMinimaDescuento;
    final int? cantidadGratis = producto.cantidadGratisDescuento;
    final double precioOriginal = producto.precioVenta;

    // Calcular el subtotal
    final double subtotal = precio * cantidad;

    // Determinar el color del borde según el tipo de promoción
    Color? borderColor;
    Color? backgroundColor;
    IconData? promocionIcon;
    String? promocionTooltip;

    if (promocionActivada) {
      if (tienePromocionGratis) {
        borderColor = const Color(0xFF2E7D32); // Verde oscuro
        backgroundColor = const Color(0xFF2E7D32).withOpacity(0.1);
        promocionIcon = Icons.card_giftcard;
        promocionTooltip = 'Promoción "Lleva y Paga" activada';
      } else if (tieneDescuentoPorcentual &&
          cantidad >= (cantidadMinima ?? 0)) {
        borderColor = Colors.purple;
        backgroundColor = Colors.purple.withOpacity(0.1);
        promocionIcon = Icons.percent;
        promocionTooltip = 'Descuento del $porcentajeDescuento% aplicado';
      }
    } else if (enLiquidacion) {
      borderColor = Colors.amber;
      backgroundColor = Colors.amber.withOpacity(0.1);
      promocionIcon = Icons.local_offer;
      promocionTooltip = 'Producto en liquidación';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: borderColor != null
            ? BorderSide(color: borderColor, width: 1.5)
            : (stockLimitado
                ? const BorderSide(color: Colors.orange)
                : BorderSide.none),
      ),
      color: backgroundColor ?? Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                // Imagen del producto
                if (url.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image, color: Colors.grey, size: 32),
                    ),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.image_not_supported,
                        color: Colors.grey, size: 32),
                  ),
                // Icono de promoción
                if (promocionIcon != null)
                  Tooltip(
                    message: promocionTooltip ?? '',
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: borderColor?.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          promocionIcon,
                          size: 14,
                          color: borderColor,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    producto.nombre,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: borderColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onEliminar,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (promocionActivada)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.info_outline,
                      size: 12,
                      color: borderColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tienePromocionGratis &&
                                cantidadMinima != null &&
                                cantidadGratis != null
                            ? 'Por cada $cantidadMinima unidades, recibirás $cantidadGratis gratis'
                            : (tieneDescuentoPorcentual &&
                                    cantidad >= (cantidadMinima ?? 0)
                                ? 'Descuento del $porcentajeDescuento% aplicado por comprar $cantidad o más unidades'
                                : 'Promoción aplicada automáticamente por el servidor'),
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: borderColor?.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                // Mostrar precios con descuento si aplica
                if (tieneDescuentoPorcentual &&
                    porcentajeDescuento != null &&
                    cantidad >= (cantidadMinima ?? 0))
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'S/ ${precioOriginal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-$porcentajeDescuento%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'S/ ${precio.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: borderColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Subtotal: S/ ${subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: borderColor?.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'S/ ${precio.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                promocionActivada ? FontWeight.bold : null,
                            color: borderColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Subtotal: S/ ${subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: borderColor?.withOpacity(0.8),
                          ),
                        ),
                        if (tienePromocionGratis && productosGratis > 0) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF2E7D32).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.card_giftcard,
                                  size: 12,
                                  color: Color(0xFF2E7D32),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Recibirás $productosGratis unidades gratis',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: stockLimitado
                        ? Colors.orange.withOpacity(0.2)
                        : (borderColor?.withOpacity(0.1) ??
                            Colors.blue.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: () => onCambiarCantidad(cantidad - 1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '$cantidad',
                          style: TextStyle(
                            color: stockLimitado ? Colors.orange : borderColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.add,
                          size: 16,
                          color: stockLimitado
                              ? Colors.orange.withOpacity(0.5)
                              : null,
                        ),
                        onPressed: stockLimitado
                            ? null
                            : () => onCambiarCantidad(cantidad + 1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Disponible: $stockDisponible',
              style: TextStyle(
                fontSize: 12,
                color: stockLimitado ? Colors.orange : Colors.green,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Producto>('producto', producto))
      ..add(IntProperty('cantidad', cantidad))
      ..add(ObjectFlagProperty<VoidCallback>.has('onEliminar', onEliminar))
      ..add(ObjectFlagProperty<void Function(int nuevaCantidad)>.has(
          'onCambiarCantidad', onCambiarCantidad));
  }
}
