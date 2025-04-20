import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/providers/admin/stock.admin.provider.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_detalle_sucursal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class TableProducts extends StatelessWidget {
  final String selectedSucursalId;
  final List<Producto>? productos;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final Function(Producto)? onEditProducto;
  final Function(Producto)? onVerDetalles;
  final Function(Producto)? onVerStockDetalles;
  final Function(String)? onSort;
  final String? sortBy;
  final String? sortOrder;
  final bool filtrosActivos;

  const TableProducts({
    super.key,
    required this.selectedSucursalId,
    this.productos,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.onEditProducto,
    this.onVerDetalles,
    this.onVerStockDetalles,
    this.onSort,
    this.sortBy,
    this.sortOrder,
    this.filtrosActivos = false,
  });

  final List<String> _columnHeaders = const <String>[
    'Producto',
    'Categoría',
    'Marca',
    'Stock',
    'Mínimo',
    'Estado',
    'Acciones',
  ];

  @override
  Widget build(BuildContext context) {
    Provider.of<StockProvider>(context, listen: false);

    // Mostrar indicador de carga
    if (isLoading) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Encabezado de la tabla
            Container(
              color: const Color(0xFF2D2D2D),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: _buildStandardHeaders(),
              ),
            ),
            // Indicador de carga
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFE31E24),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mostrar mensaje de error si ocurrió alguno
    if (error != null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Encabezado de la tabla
            Container(
              color: const Color(0xFF2D2D2D),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: _buildStandardHeaders(),
              ),
            ),
            // Mensaje de error
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFE31E24),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar datos: $error',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    if (onRetry != null) ...<Widget>[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        onPressed: onRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE31E24),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Si no hay sucursal seleccionada, mostrar mensaje
    if (selectedSucursalId.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Encabezado de la tabla
            Container(
              color: const Color(0xFF2D2D2D),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: _buildStandardHeaders(),
              ),
            ),
            // Mensaje de selección de sucursal
            const Expanded(
              child: Center(
                child: Text(
                  'Seleccione una sucursal para ver su inventario',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mostrar los productos directamente sin agrupar
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Encabezado de la tabla
          Container(
            color: const Color(0xFF2D2D2D),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: _buildStandardHeaders(),
            ),
          ),

          // Lista de productos o mensaje de no productos
          Expanded(
            child: productos == null || productos!.isEmpty
                ? _buildNoProductosMessage(hayFiltrosAplicados: filtrosActivos)
                : ListView.builder(
                    itemCount: productos!.length,
                    itemBuilder: (context, index) {
                      final producto = productos![index];
                      return _buildProductRow(context, producto);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProductosMessage({required bool hayFiltrosAplicados}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            hayFiltrosAplicados
                ? FontAwesomeIcons.filter
                : FontAwesomeIcons.boxOpen,
            color: hayFiltrosAplicados ? Colors.amber : Colors.white54,
            size: 64,
          ),
          const SizedBox(height: 24),
          Text(
            hayFiltrosAplicados
                ? 'No se encontraron productos'
                : 'No hay productos en esta sucursal',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hayFiltrosAplicados
                ? 'Ningún producto coincide con los filtros o criterios de búsqueda aplicados'
                : 'Considera agregar productos a esta sucursal',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (hayFiltrosAplicados) ...<Widget>[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry ??
                  () {
                    debugPrint(
                        'No se configuró un manejador para reiniciar filtros');
                  },
              icon: const Icon(FontAwesomeIcons.arrowsRotate, size: 16),
              label: const Text('Reiniciar filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D2D2D),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Método para construir los encabezados en vista estándar
  List<Widget> _buildStandardHeaders() {
    return <Widget>[
      // Nombre del producto (30%)
      Expanded(
        flex: 30,
        child: Text(
          _columnHeaders[0],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Categoría (15%)
      Expanded(
        flex: 15,
        child: Text(
          _columnHeaders[1],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Marca (15%)
      Expanded(
        flex: 15,
        child: Text(
          _columnHeaders[2],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Stock actual (10%)
      Expanded(
        flex: 10,
        child: Text(
          _columnHeaders[3],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Stock mínimo (10%)
      Expanded(
        flex: 10,
        child: Text(
          _columnHeaders[4],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Estado (15%)
      Expanded(
        flex: 15,
        child: Text(
          _columnHeaders[5],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Acciones (15%)
      Expanded(
        flex: 15,
        child: Text(
          _columnHeaders[6],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];
  }

  Widget _buildProductRow(BuildContext context, Producto producto) {
    Provider.of<StockProvider>(context, listen: false);
    final int stockActual = producto.stock;
    final int stockMinimo = producto.stockMinimo ?? 0;

    // Obtener estado directamente del producto
    final Color statusColor = _getStatusColor(producto);
    final IconData statusIcon = _getStatusIcon(producto);
    final String statusText = _getStatusText(producto);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
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
                FaIcon(
                  FontAwesomeIcons.box,
                  size: 14,
                  color: statusColor.withOpacity(0.8),
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
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: Colors.orange.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const <Widget>[
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
                            color: Colors.white.withOpacity(0.7),
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
                            Text(
                              'Precio: ${producto.getPrecioActualFormateado()}',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              producto.getPrecioVentaFormateado(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
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
                    color: statusColor.withOpacity(0.2),
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
                    if (onVerStockDetalles != null) {
                      onVerStockDetalles!(producto);
                    }
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
                      // Si no hay un manejador personalizado, mostrar nuestro diálogo
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
      return const Color(0xFF4A4A4A); // Color gris oscuro para agotados
    }
    if (producto.stockBajo == true) {
      return const Color(0xFFE31E24); // Stock bajo
    }
    return Colors.green; // Disponible
  }

  IconData _getStatusIcon(Producto producto) {
    if (producto.stock <= 0) {
      return FontAwesomeIcons.ban; // Agotado
    }
    if (producto.stockBajo == true) {
      return FontAwesomeIcons.triangleExclamation; // Stock bajo
    }
    return FontAwesomeIcons.check; // Disponible
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
      ..add(StringProperty('selectedSucursalId', selectedSucursalId))
      ..add(IterableProperty<Producto>('productos', productos))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(StringProperty('error', error))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onRetry', onRetry))
      ..add(ObjectFlagProperty<Function(Producto)?>.has(
          'onEditProducto', onEditProducto))
      ..add(ObjectFlagProperty<Function(Producto)?>.has(
          'onVerDetalles', onVerDetalles))
      ..add(ObjectFlagProperty<Function(Producto)?>.has(
          'onVerStockDetalles', onVerStockDetalles))
      ..add(ObjectFlagProperty<Function(String)?>.has('onSort', onSort))
      ..add(StringProperty('sortBy', sortBy))
      ..add(StringProperty('sortOrder', sortOrder))
      ..add(DiagnosticsProperty<bool>('filtrosActivos', filtrosActivos));
  }
}

/// Widget para mostrar un resumen del inventario
class InventarioResumen extends StatefulWidget {
  final List<Producto> productos;
  final String? sucursalNombre;

  const InventarioResumen({
    super.key,
    required this.productos,
    this.sucursalNombre,
  });

  @override
  _InventarioResumenState createState() => _InventarioResumenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Producto>('productos', productos))
      ..add(StringProperty('sucursalNombre', sucursalNombre));
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

    // Agrupar productos por disponibilidad usando el StockProvider
    final Map<StockStatus, List<Producto>> agrupados =
        stockProvider.agruparProductosPorEstadoStock(widget.productos);

    // Obtener contadores
    final int agotadosCount = agrupados[StockStatus.agotado]!.length;
    final int stockBajoCount = agrupados[StockStatus.stockBajo]!.length;
    final int disponiblesCount = agrupados[StockStatus.disponible]!.length;

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
          title: Text(
            widget.sucursalNombre != null
                ? 'Resumen de ${widget.sucursalNombre}'
                : 'Resumen del Inventario',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
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
        color: highlight ? color.withOpacity(0.15) : const Color(0xFF333333),
        borderRadius: BorderRadius.circular(8),
        border: highlight ? Border.all(color: color.withOpacity(0.3)) : null,
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
                    color: Colors.white.withOpacity(0.9),
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
              color: Colors.white.withOpacity(0.6),
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
      ..add(IterableProperty<Producto>(
          'productos', widget.productos)) // Accede a productos desde widget
      ..add(StringProperty('sucursalNombre',
          widget.sucursalNombre)); // Accede a sucursalNombre desde widget
  }
}
