import 'dart:async';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductoVentaItemWidget extends StatefulWidget {
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
  State<ProductoVentaItemWidget> createState() => _ProductoVentaItemWidgetState();
}

class _ProductoVentaItemWidgetState extends State<ProductoVentaItemWidget> {
  int _clickCount = 0;
  DateTime? _lastClickTime;
  bool _mostrarAtajos = false;
  Timer? _inactivityTimer;

  void _detectSpam() {
    final now = DateTime.now();
    if (_lastClickTime == null) {
      _clickCount = 1;
    } else {
      final difference = now.difference(_lastClickTime!);
      if (difference.inMilliseconds < 600) {
        _clickCount++;
      } else {
        _clickCount = 1;
      }
    }
    _lastClickTime = now;

    if (_clickCount >= 5) {
      setState(() {
        _mostrarAtajos = true;
      });
      _resetSpamTimer();
    }
  }

  void _resetSpamTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _mostrarAtajos = false;
          _clickCount = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  Widget _buildShortcutButton(String text, int amount, int stockDisponible, bool stockLimitado) {
    final int nuevaCantidad = widget.cantidad + amount;
    final bool canAdd = nuevaCantidad <= stockDisponible;
    return GestureDetector(
      onTap: canAdd
          ? () {
              widget.onCambiarCantidad(nuevaCantidad);
              _resetSpamTimer();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: canAdd
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: canAdd
                ? AppTheme.primaryColor.withValues(alpha: 0.3)
                : Colors.white12,
          ),
          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: canAdd ? Colors.white : Colors.white30,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;
    final cantidad = widget.cantidad;
    final onEliminar = widget.onEliminar;
    final onCambiarCantidad = widget.onCambiarCantidad;
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
    final bool promocionCumplida = cantidadMinima != null && cantidad >= cantidadMinima;

    // Determinar el color del borde según el tipo de promoción
    Color? borderColor;
    Color? backgroundColor;

    if (promocionActivada) {
      if (tienePromocionGratis) {
        borderColor = AppTheme.successDark; // Verde oscuro
        backgroundColor = AppTheme.successDark.withValues(alpha: 0.1);
      } else if (tieneDescuentoPorcentual &&
          cantidad >= (cantidadMinima ?? 0)) {
        borderColor = Colors.purple;
        backgroundColor = Colors.purple.withValues(alpha: 0.1);
      }
    } else if (enLiquidacion) {
      borderColor = Colors.amber;
      backgroundColor = Colors.amber.withValues(alpha: 0.1);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
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
                    borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                    child: Image.network(
                      url,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image, color: Colors.grey, size: 32),
                    ),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                    ),
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.grey, size: 32),
                  ),

                Expanded(
                  child: Text(
                    producto.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
                      color: promocionCumplida ? borderColor : Colors.white38,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tienePromocionGratis &&
                                cantidadMinima != null &&
                                cantidadGratis != null
                            ? 'Por cada $cantidadMinima unidades, recibirás $cantidadGratis gratis'
                            : (tieneDescuentoPorcentual &&
                                    cantidadMinima != null
                                ? (promocionCumplida
                                    ? 'Descuento del $porcentajeDescuento% aplicado por comprar $cantidad o más unidades'
                                    : 'Descuento del $porcentajeDescuento% por comprar $cantidadMinima o más unidades')
                                : 'Promoción aplicada automáticamente por el servidor'),
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: promocionCumplida
                              ? borderColor?.withValues(alpha: 0.8)
                              : Colors.white38,
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
                                color: Colors.purple.withValues(alpha: 0.2),
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
                        Row(
                          children: [
                            Text(
                              'S/ ${precio.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStockBadge(stockDisponible, stockLimitado),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Subtotal: S/ ${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
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
                        Row(
                          children: [
                            Text(
                              'S/ ${precio.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    promocionActivada ? FontWeight.bold : null,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStockBadge(stockDisponible, stockLimitado),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Subtotal: S/ ${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),

                      ],
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (_mostrarAtajos) ...[
                      _buildShortcutButton('+5', 5, stockDisponible, stockLimitado),
                      const SizedBox(width: 6),
                      _buildShortcutButton('+10', 10, stockDisponible, stockLimitado),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: stockLimitado
                            ? Colors.orange.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                      ),
                      child: Row(
                        children: <Widget>[
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18, color: Colors.white70),
                            onPressed: () => onCambiarCantidad(cantidad - 1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '$cantidad',
                              style: TextStyle(
                                color: stockLimitado ? Colors.orange : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.add,
                              size: 18,
                              color: stockLimitado
                                  ? Colors.orange.withValues(alpha: 0.5)
                                  : Colors.white70,
                            ),
                            onPressed: stockLimitado
                                ? null
                                : () {
                                    onCambiarCantidad(cantidad + 1);
                                    _detectSpam();
                                  },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (tienePromocionGratis && productosGratis > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.successDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppTheme.successDark.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.card_giftcard,
                      size: 11,
                      color: AppTheme.successDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$productosGratis unidades gratis',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStockBadge(int stock, bool stockLimitado) {
    final Color color = stockLimitado ? Colors.orange : Colors.white70;
    return Tooltip(
      message: 'Disponible',
      preferBelow: false,
      triggerMode: TooltipTriggerMode.tap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            FontAwesomeIcons.cube,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$stock',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
