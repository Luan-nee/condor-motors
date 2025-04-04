import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
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

  // Nuevos parámetros para la vista consolidada
  final Map<int, Map<String, int>>? stockPorSucursal;
  final List<Sucursal>? sucursales;
  final bool esVistaGlobal;

  // Nuevo parámetro para indicar si hay filtros activos
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
    this.stockPorSucursal,
    this.sucursales,
    this.esVistaGlobal = false,
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

  // Encabezados para la vista global
  final List<String> _globalColumnHeaders = const <String>[
    'Producto',
    'Categoría',
    'Marca',
    'Estado',
    'Detalles por Sucursal',
    'Acciones',
  ];

  // Método auxiliar para convertir entre los enums de StockStatus

  @override
  Widget build(BuildContext context) {
    final StockProvider stockProvider =
        Provider.of<StockProvider>(context, listen: false);

    // Mostrar indicador de carga
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE31E24),
        ),
      );
    }

    // Mostrar mensaje de error si ocurrió alguno
    if (error != null) {
      return Center(
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
      );
    }

    // Si no hay sucursal seleccionada y no estamos en vista global, mostrar mensaje
    if (selectedSucursalId.isEmpty && !esVistaGlobal) {
      return const Center(
        child: Text(
          'Seleccione una sucursal para ver su inventario',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    // Si no hay productos para esta sucursal o vista
    if (productos == null || productos!.isEmpty) {
      // Determinar si es probable que haya filtros aplicados
      final bool hayFiltrosAplicados = filtrosActivos ||
          esVistaGlobal; // La vista global o cuando hay filtros explícitos

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Usar un icono diferente cuando no hay productos por filtros
            Icon(
              hayFiltrosAplicados
                  ? FontAwesomeIcons
                      .filter // Icono de filtro cuando hay filtros aplicados
                  : FontAwesomeIcons
                      .boxOpen, // Icono de caja vacía para otros casos
              color: hayFiltrosAplicados ? Colors.amber : Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              hayFiltrosAplicados
                  ? 'No se encontraron productos'
                  : (esVistaGlobal
                      ? 'No hay productos con problemas de stock'
                      : 'No hay productos en esta sucursal'),
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
                  : (esVistaGlobal
                      ? 'Todos los productos tienen niveles de stock adecuados en las sucursales'
                      : 'Considera agregar productos a esta sucursal'),
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
              const SizedBox(height: 12),
              Text(
                'Al reiniciar, se mostrarán todos los productos disponibles',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    // Agrupar productos por estado utilizando el StockProvider
    final Map<StockStatus, List<Producto>> productosAgrupados =
        stockProvider.agruparProductosPorEstadoStock(productos!);

    // Contadores para cada grupo
    final int agotadosCount = productosAgrupados[StockStatus.agotado]!.length;
    final int stockBajoCount =
        productosAgrupados[StockStatus.stockBajo]!.length;
    final int disponiblesCount =
        productosAgrupados[StockStatus.disponible]!.length;

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
              children: esVistaGlobal
                  ? _buildGlobalHeaders()
                  : _buildStandardHeaders(),
            ),
          ),

          // Lista de productos agrupados por estado
          Expanded(
            child: ListView(
              children: <Widget>[
                // Grupo 1: Productos agotados (muestro primero los más críticos)
                if (agotadosCount > 0) ...<Widget>[
                  _buildGroupHeader('Productos agotados', agotadosCount,
                      Colors.red.shade800, FontAwesomeIcons.ban),
                  ...productosAgrupados[StockStatus.agotado]!.map(
                      (Producto producto) => esVistaGlobal
                          ? _buildGlobalProductRow(context, producto)
                          : _buildProductRow(context, producto)),
                ],

                // Grupo 2: Productos con stock bajo
                if (stockBajoCount > 0) ...<Widget>[
                  _buildGroupHeader(
                      'Productos con stock bajo',
                      stockBajoCount,
                      const Color(0xFFE31E24),
                      FontAwesomeIcons.triangleExclamation),
                  ...productosAgrupados[StockStatus.stockBajo]!.map(
                      (Producto producto) => esVistaGlobal
                          ? _buildGlobalProductRow(context, producto)
                          : _buildProductRow(context, producto)),
                ],

                // Grupo 3: Productos disponibles (solo si no estamos en vista global)
                if (disponiblesCount > 0 && !esVistaGlobal) ...<Widget>[
                  _buildGroupHeader('Productos disponibles', disponiblesCount,
                      Colors.green, FontAwesomeIcons.check),
                  ...productosAgrupados[StockStatus.disponible]!.map(
                      (Producto producto) =>
                          _buildProductRow(context, producto)),
                ],
              ],
            ),
          ),
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

  // Método para construir los encabezados en vista global
  List<Widget> _buildGlobalHeaders() {
    return <Widget>[
      // Nombre del producto (25%)
      Expanded(
        flex: 25,
        child: Text(
          _globalColumnHeaders[0],
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
          _globalColumnHeaders[1],
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
          _globalColumnHeaders[2],
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
          _globalColumnHeaders[3],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Detalles por Sucursal (20%)
      Expanded(
        flex: 20,
        child: Text(
          _globalColumnHeaders[4],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Acciones (10%)
      Expanded(
        flex: 10,
        child: Text(
          _globalColumnHeaders[5],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];
  }

  Widget _buildGroupHeader(
      String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withOpacity(0.15),
      child: Row(
        children: <Widget>[
          FaIcon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método para construir una fila de producto en vista estándar (por sucursal)
  Widget _buildProductRow(BuildContext context, Producto producto) {
    final StockProvider stockProvider =
        Provider.of<StockProvider>(context, listen: false);
    final int stockActual = producto.stock;
    final int stockMinimo = producto.stockMinimo ?? 0;

    // Determinar color e icono según el estado
    final Color statusColor =
        stockProvider.getStockStatusColor(stockActual, stockMinimo);
    final IconData statusIcon =
        stockProvider.getStockStatusIcon(stockActual, stockMinimo);
    final String statusText =
        stockProvider.getStockStatusText(stockActual, stockMinimo);

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

  // Método para construir una fila de producto en vista global (todas las sucursales)
  Widget _buildGlobalProductRow(BuildContext context, Producto producto) {
    final StockProvider stockProvider =
        Provider.of<StockProvider>(context, listen: false);
    final int stockActual = producto.stock;
    final int stockMinimo = producto.stockMinimo ?? 0;

    // Determinar color e icono según el estado
    final Color statusColor =
        stockProvider.getStockStatusColor(stockActual, stockMinimo);
    final IconData statusIcon =
        stockProvider.getStockStatusIcon(stockActual, stockMinimo);
    final String statusText =
        stockProvider.getStockStatusText(stockActual, stockMinimo);

    // Obtener datos de stock por sucursal
    final Map<String, int> stocks =
        stockPorSucursal?[producto.id] ?? <String, int>{};

    // Calcular cuántas sucursales tienen stock bajo o agotado para este producto
    final int sucursalesConProblemas = stocks.entries
        .where((MapEntry<String, int> entry) =>
            entry.value <= 0 || // Agotado
            (entry.value < (producto.stockMinimo ?? 0))) // Stock bajo
        .length;

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
          // Nombre del producto (25%)
          Expanded(
            flex: 25,
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
                      // Mostrar indicador de sucursales con problemas
                      if (sucursalesConProblemas > 0) ...<Widget>[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE31E24).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Problemas en $sucursalesConProblemas ${sucursalesConProblemas == 1 ? 'sucursal' : 'sucursales'}',
                            style: const TextStyle(
                              color: Color(0xFFE31E24),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
          // Stocks por sucursal (20%)
          Expanded(
            flex: 20,
            child: _buildSucursalesStockIndicators(stocks),
          ),
          // Acciones (10%)
          Expanded(
            flex: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
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

  // Widget para mostrar indicadores de stock para cada sucursal
  Widget _buildSucursalesStockIndicators(Map<String, int> stocks) {
    if (sucursales == null || sucursales!.isEmpty || stocks.isEmpty) {
      return const Center(
        child: Text(
          'Sin datos',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }

    // Determinar qué sucursales tienen problemas de stock para este producto
    final List<Sucursal> sucursalesConProblemas = <Sucursal>[];
    final List<Sucursal> sucursalesNormales = <Sucursal>[];
    final List<Sucursal> sucursalesAgotadas = <Sucursal>[];

    for (final Sucursal sucursal in sucursales!) {
      final int stock = stocks[sucursal.id] ?? 0;
      if (stock <= 0) {
        // Si el stock es nulo o cero (agotado)
        sucursalesAgotadas.add(sucursal);
      } else if (stock < 5) {
        // Si el stock es bajo (usar producto.stockMinimo sería mejor)
        sucursalesConProblemas.add(sucursal);
      } else {
        sucursalesNormales.add(sucursal);
      }
    }

    // Calcular porcentajes para mostrar estadística
    final int totalSucursales = sucursales!.length;
    final int porcentajeAgotadas =
        (sucursalesAgotadas.length / totalSucursales * 100).round();
    final int porcentajeBajo =
        (sucursalesConProblemas.length / totalSucursales * 100).round();

    // Si hay más de 50% de sucursales con problemas, mostrar un indicador de alerta global
    final bool mostrarAlertaGlobal = (porcentajeAgotadas + porcentajeBajo) > 50;

    // Mostrar primero las sucursales con problemas y luego otras (si hay espacio)
    final List<Sucursal> sucursalesMostradas = <Sucursal>[];

    // Priorizar mostrar las sucursales agotadas primero
    if (sucursalesAgotadas.isNotEmpty) {
      sucursalesMostradas.addAll(sucursalesAgotadas.length > 2
          ? sucursalesAgotadas.sublist(0, 2)
          : sucursalesAgotadas);
    }

    // Luego las que tienen stock bajo
    if (sucursalesMostradas.length < 3 && sucursalesConProblemas.isNotEmpty) {
      final int espacioRestante = 3 - sucursalesMostradas.length;
      sucursalesMostradas.addAll(sucursalesConProblemas.length > espacioRestante
          ? sucursalesConProblemas.sublist(0, espacioRestante)
          : sucursalesConProblemas);
    }

    // Por último, si queda espacio, mostrar alguna sucursal normal
    if (sucursalesMostradas.length < 3 && sucursalesNormales.isNotEmpty) {
      final int espacioRestante = 3 - sucursalesMostradas.length;
      sucursalesMostradas.addAll(sucursalesNormales.length > espacioRestante
          ? sucursalesNormales.sublist(0, espacioRestante)
          : sucursalesNormales);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Mostrar indicador de alerta global si es necesario
        if (mostrarAlertaGlobal) ...<Widget>[
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.shade800.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red.shade800.withOpacity(0.3)),
            ),
            child: Text(
              '${porcentajeAgotadas + porcentajeBajo}% sucursales con problemas',
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],

        // Mostrar los indicadores de sucursales
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ...sucursalesMostradas.map((Sucursal sucursal) {
              final int stock = stocks[sucursal.id] ?? 0;
              final Color color = stock <= 0
                  ? Colors.red.shade800
                  : (stock < 5 ? const Color(0xFFE31E24) : Colors.green);

              return Tooltip(
                message: '${sucursal.nombre}: $stock unidades',
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        sucursal.nombre.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        stock.toString(),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Mostrar cuántas sucursales con problemas hay si no pudimos mostrarlas todas
            if (sucursalesAgotadas.length + sucursalesConProblemas.length > 3)
              Tooltip(
                message:
                    'Hay ${(sucursalesAgotadas.length + sucursalesConProblemas.length) - sucursalesMostradas.length} sucursales más con problemas de stock',
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE31E24).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: const Color(0xFFE31E24).withOpacity(0.3)),
                  ),
                  child: Text(
                    '+${(sucursalesAgotadas.length + sucursalesConProblemas.length) - sucursalesMostradas.length}',
                    style: const TextStyle(
                      color: Color(0xFFE31E24),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
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
      ..add(DiagnosticsProperty<Map<int, Map<String, int>>?>(
          'stockPorSucursal', stockPorSucursal))
      ..add(IterableProperty<Sucursal>('sucursales', sucursales))
      ..add(DiagnosticsProperty<bool>('esVistaGlobal', esVistaGlobal))
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
