import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../models/producto.model.dart';
import '../utils/productos_utils.dart';
import '../utils/stock_utils.dart';
import 'stock_detalle_sucursal.dart';

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
  });

  final List<String> _columnHeaders = const [
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
          children: [
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
            if (onRetry != null) ...[
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
    
    // Si no hay sucursal seleccionada, mostrar mensaje
    if (selectedSucursalId.isEmpty) {
      return const Center(
        child: Text(
          'Seleccione una sucursal para ver su inventario',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }
    
    // Si no hay productos para esta sucursal
    if (productos == null || productos!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              FontAwesomeIcons.boxOpen,
              color: Colors.white54,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos en esta sucursal',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado de la tabla
          Container(
            color: const Color(0xFF2D2D2D),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
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
              ],
            ),
          ),
          
          // Filas de productos
          Expanded(
            child: ListView.builder(
              itemCount: productos!.length,
              itemBuilder: (context, index) {
                final producto = productos![index];
                final stockActual = producto.stock;
                final stockMinimo = producto.stockMinimo ?? 0;
                
                // Determinar color e icono según el estado
                final statusColor = StockUtils.getStockStatusColor(stockActual, stockMinimo);
                final statusIcon = StockUtils.getStockStatusIcon(stockActual, stockMinimo);
                final statusText = StockUtils.getStockStatusText(stockActual, stockMinimo);
                
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
                    children: [
                      // Nombre del producto (30%)
                      Expanded(
                        flex: 30,
                        child: Row(
                          children: [
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
                                children: [
                                  Text(
                                    producto.nombre,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (producto.descripcion != null && producto.descripcion!.isNotEmpty) ...[
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
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
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
                          children: [
                            IconButton(
                              icon: const FaIcon(
                                FontAwesomeIcons.chartLine,
                                color: Colors.teal,
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
                              tooltip: 'Ver stock',
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
                              tooltip: 'Ver stock por sucursal',
                              splashRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar un resumen del inventario
class InventarioResumen extends StatelessWidget {
  final List<Producto> productos;
  final String? sucursalNombre;
  
  const InventarioResumen({
    super.key,
    required this.productos,
    this.sucursalNombre,
  });
  
  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Agrupar productos por disponibilidad
    final agrupados = ProductosUtils.agruparProductosPorDisponibilidad(productos);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sucursalNombre != null ? 'Resumen de $sucursalNombre' : 'Resumen del Inventario',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatRow(
                  'Total de productos', 
                  productos.length.toString(),
                  FontAwesomeIcons.boxesStacked,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildStatRow(
                  'Productos disponibles', 
                  agrupados['disponibles']!.length.toString(),
                  FontAwesomeIcons.check,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatRow(
                  'Productos con stock bajo', 
                  agrupados['stockBajo']!.length.toString(),
                  FontAwesomeIcons.triangleExclamation,
                  const Color(0xFFE31E24),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildStatRow(
                  'Productos sin stock', 
                  agrupados['agotados']!.length.toString(),
                  FontAwesomeIcons.ban,
                  Colors.red.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        FaIcon(
          icon,
          color: color,
          size: 14,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const Spacer(),
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
}
