import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/providers/admin/stock.admin.provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

// Export InventarioResumen from stock_table.dart
export 'stock_table.dart' show TableProducts, InventarioResumen;

/// Widget para mostrar un resumen del inventario
class InventarioResumen extends StatefulWidget {
  final List<Producto> productos;
  final String? sucursalNombre;
  final VoidCallback? onRefresh;

  const InventarioResumen({
    super.key,
    required this.productos,
    this.sucursalNombre,
    this.onRefresh,
  });

  @override
  _InventarioResumenState createState() => _InventarioResumenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Producto>('productos', productos))
      ..add(StringProperty('sucursalNombre', sucursalNombre))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onRefresh', onRefresh));
  }
}

class _InventarioResumenState extends State<InventarioResumen> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final StockProvider stockProvider =
        Provider.of<StockProvider>(context, listen: false);

    if (widget.productos.isEmpty) {
      return const SizedBox.shrink();
    }

    // Usar el método optimizado para agrupar productos
    final Map<StockStatus, List<Producto>> agrupados =
        stockProvider.agruparProductosPorEstadoStock(widget.productos);

    // Obtener contadores
    final int disponiblesCount = agrupados[StockStatus.disponible]!.length;
    final int stockBajoCount = agrupados[StockStatus.stockBajo]!.length;
    final int agotadosCount = agrupados[StockStatus.agotado]!.length;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // Elimina las líneas divisoras
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero, // Elimina el padding interno
          title: Row(
            children: [
              Expanded(
                child: Text(
                  widget.sucursalNombre != null
                      ? 'Resumen de ${widget.sucursalNombre}'
                      : 'Resumen del Inventario',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (widget.onRefresh != null)
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white70,
                    size: 18,
                  ),
                  tooltip: 'Actualizar resumen',
                  onPressed: widget.onRefresh,
                ),
            ],
          ),
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (bool expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          children: <Widget>[
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildStatCard(
                    'Disponibles',
                    disponiblesCount.toString(),
                    FontAwesomeIcons.check,
                    Colors.green,
                    'Productos con stock suficiente',
                    false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Stock bajo',
                    stockBajoCount.toString(),
                    FontAwesomeIcons.triangleExclamation,
                    const Color(0xFFE31E24),
                    'Necesitan reabastecimiento',
                    stockBajoCount > 0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Productos agotados',
                    agotadosCount.toString(),
                    FontAwesomeIcons.ban,
                    Colors.red.shade800,
                    'Requieren atención urgente',
                    agotadosCount > 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      String subtitle, bool highlight) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: highlight ? color.withValues(alpha: 0.15) : const Color(0xFF333333),
        borderRadius: BorderRadius.circular(8),
        border: highlight ? Border.all(color: color.withValues(alpha: 0.3)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              FaIcon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Producto>('productos', widget.productos))
      ..add(StringProperty('sucursalNombre', widget.sucursalNombre));
  }
}
