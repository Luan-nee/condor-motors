import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/utils/productos_utils.dart';
import 'package:condorsmotors/utils/sucursal_utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductosFormSucursales extends StatelessWidget {
  final bool isLoadingSucursalesCompartidas;
  final List<ProductoEnSucursal> sucursalesCompartidas;
  final Sucursal? sucursalSeleccionada;

  const ProductosFormSucursales({
    super.key,
    required this.isLoadingSucursalesCompartidas,
    required this.sucursalesCompartidas,
    required this.sucursalSeleccionada,
  });

  Widget _buildSectionTitle(String title, FaIconData icon) {
    return Row(
      children: <Widget>[
        FaIcon(icon, color: AppTheme.primaryColor, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfoRow(String label, String value, FaIconData icon) {
    return Row(
      children: <Widget>[
        FaIcon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSucursalItem(ProductoEnSucursal item) {
    final bool isCurrentBranch = sucursalSeleccionada?.id == item.sucursal.id;
    final bool isNotAvailable = !item.disponible;
    final bool isOutOfStock = item.disponible && item.producto.stock <= 0;
    final bool isLowStock = item.disponible && item.producto.tieneStockBajo();
    final bool hasWarning = isNotAvailable || isOutOfStock || isLowStock;

    Widget? warningBadge;
    if (hasWarning) {
      final Color warningColor;
      final FaIconData warningIcon;
      final String warningText;
      final String tooltipMessage;

      if (isNotAvailable) {
        warningColor = Colors.redAccent;
        warningIcon = FontAwesomeIcons.ban;
        warningText = 'N/D';
        tooltipMessage = 'Producto no disponible en esta sucursal';
      } else if (isOutOfStock) {
        warningColor = Colors.redAccent;
        warningIcon = FontAwesomeIcons.circleExclamation;
        warningText = '0';
        tooltipMessage = '¡Sin stock! Producto agotado';
      } else {
        warningColor = Colors.amber;
        warningIcon = FontAwesomeIcons.triangleExclamation;
        warningText = '${item.producto.stock}';
        tooltipMessage = 'Stock bajo: ${item.producto.stock} unidades (Mínimo: ${item.producto.stockMinimo})';
      }

      warningBadge = Tooltip(
        message: tooltipMessage,
        preferBelow: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: warningColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            border: Border.all(color: warningColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FaIcon(warningIcon, color: warningColor, size: 12),
              const SizedBox(width: 6),
              Text(
                warningText,
                style: TextStyle(
                  color: warningColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isCurrentBranch
            ? const Color.fromARGB(255, 30, 155, 227).withValues(alpha: 0.1)
            : AppTheme.deepSurface,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(
          color: isCurrentBranch
              ? const Color.fromARGB(255, 30, 197, 227).withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.1),
          width: isCurrentBranch ? 2 : 1,
        ),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: SucursalUtils.getIconBackgroundColor(item.sucursal),
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          ),
          child: Icon(
            SucursalUtils.getIconForSucursal(item.sucursal),
            color: SucursalUtils.getColorForSucursal(item.sucursal),
            size: 16,
          ),
        ),
        title: Text(
          item.sucursal.nombre,
          style: TextStyle(
            color: isCurrentBranch
                ? const Color.fromARGB(255, 139, 207, 230)
                : Colors.white,
            fontWeight: isCurrentBranch ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          item.sucursal.direccion ?? 'Sin dirección registrada',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            fontStyle: item.sucursal.direccion != null
                ? FontStyle.normal
                : FontStyle.italic,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (warningBadge != null) ...[
              warningBadge,
              const SizedBox(width: 12),
            ],
            const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          ],
        ),
        children: <Widget>[
          if (item.disponible)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  _buildProductInfoRow(
                    'Stock',
                    '${item.producto.stock} unidades',
                    FontAwesomeIcons.boxOpen,
                  ),
                  const SizedBox(height: 8),
                  _buildProductInfoRow(
                    'Stock mínimo',
                    '${item.producto.stockMinimo} unidades',
                    FontAwesomeIcons.arrowDown,
                  ),
                  const SizedBox(height: 8),
                  _buildProductInfoRow(
                    'Precio compra',
                    item.producto.getPrecioCompraFormateado(),
                    FontAwesomeIcons.tag,
                  ),
                  const SizedBox(height: 8),
                  _buildProductInfoRow(
                    'Precio venta',
                    item.producto.getPrecioVentaFormateado(),
                    FontAwesomeIcons.tag,
                  ),
                  if (item.producto.estaEnOferta()) ...<Widget>[
                    const SizedBox(height: 8),
                    _buildProductInfoRow(
                      'Precio de liquidación',
                      item.producto.getPrecioOfertaFormateado() ?? '',
                      FontAwesomeIcons.percent,
                    ),
                  ],
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade800.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                  border: Border.all(
                    color: Colors.red.shade800.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: <Widget>[
                    FaIcon(
                      FontAwesomeIcons.triangleExclamation,
                      color: Colors.red,
                      size: 16,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Este producto no está disponible en esta sucursal. Puede añadirlo desde la gestión de inventario.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<ProductoEnSucursal> otrasSucursales = sucursalSeleccionada != null
        ? sucursalesCompartidas
            .where((ProductoEnSucursal s) => s.sucursal.id != sucursalSeleccionada!.id)
            .toList()
        : sucursalesCompartidas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionTitle(
          'Otras Sucursales que Comparten este Producto',
          FontAwesomeIcons.sitemap,
        ),
        const SizedBox(height: 16),
        if (isLoadingSucursalesCompartidas)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: <Widget>[
                  CircularProgressIndicator(
                    color: Color(0xFF1C7AC7),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Consultando disponibilidad en otras sucursales...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          )
        else if (otrasSucursales.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            ),
            child: const Row(
              children: <Widget>[
                Icon(Icons.info_outline, color: Colors.white54),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Este producto no se comparte con otras sucursales',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sucursalSeleccionada != null ? otrasSucursales.length : 0,
              itemBuilder: (BuildContext context, int index) {
                final ProductoEnSucursal productoEnSucursal =
                    otrasSucursales[index];
                return _buildSucursalItem(productoEnSucursal);
              },
            ),
          ),
      ],
    );
  }
}
