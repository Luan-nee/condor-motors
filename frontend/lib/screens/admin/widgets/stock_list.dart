import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'stock_utils.dart';
import '../../../api/protected/stocks.api.dart';

Future<List<Map<String, dynamic>>> loadJsonData() async {
  try {
    String jsonString = await rootBundle
        .loadString('assets/json/inventario_admin/stockProducts.json');
    List<dynamic> jsonData = json.decode(jsonString);
    return jsonData.map((e) => e as Map<String, dynamic>).toList();
  } catch (e) {
    debugPrint('Error cargando datos JSON: $e');
    // Devolver una lista vacía en caso de error
    return [];
  }
}

class TableProducts extends StatelessWidget {
  final String selectedSucursalId;
  final StocksApi? stocksApi;
  
  TableProducts({
    super.key, 
    required this.selectedSucursalId,
    this.stocksApi,
  });

  final List<String> _columnHeaders = [
    'nombre de producto',
    'stock actual',
    'stock mínimo',
    'stock máximo',
    'estado',
    'acciones',
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: loadJsonData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFE31E24),
            ),
          );
        } else if (snapshot.hasError) {
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
                  'Error al cargar datos: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No hay datos disponibles',
              style: TextStyle(color: Colors.white),
            ),
          );
        } else {
          // Obtener todos los productos
          List<Map<String, dynamic>> allProducts = [];
          
          // Si no hay sucursal seleccionada, mostrar mensaje
          if (selectedSucursalId.isEmpty) {
            return const Center(
              child: Text(
                'Seleccione una sucursal para ver su inventario',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }
          
          // Extraer productos de la sucursal seleccionada
          for (var sucursal in snapshot.data!) {
            if (sucursal["id"] == selectedSucursalId) {
              final productos = (sucursal["productos"] as List<dynamic>).map((producto) {
                return producto as Map<String, dynamic>;
              }).toList();
              
              allProducts.addAll(productos);
              break;
            }
          }
          
          // Si no hay productos para esta sucursal
          if (allProducts.isEmpty) {
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
            width: MediaQuery.of(context).size.width * 0.7,
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
                      // Nombre de producto (35% del ancho)
                      Expanded(
                        flex: 35,
                        child: Text(
                          _columnHeaders[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Stock actual (12% del ancho)
                      Expanded(
                        flex: 12,
                        child: Text(
                          _columnHeaders[1],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Stock mínimo (12% del ancho)
                      Expanded(
                        flex: 12,
                        child: Text(
                          _columnHeaders[2],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Stock máximo (12% del ancho)
                      Expanded(
                        flex: 12,
                        child: Text(
                          _columnHeaders[3],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Estado (14% del ancho)
                      Expanded(
                        flex: 14,
                        child: Text(
                          _columnHeaders[4],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Acciones (15% del ancho)
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
                    ],
                  ),
                ),
                
                // Filas de productos
                ...allProducts.map((product) {
                  final stockActual = product["stock_actual"] as int? ?? 0;
                  final stockMinimo = product["stock_minimo"] as int? ?? 0;
                  final stockMaximo = product["stock_maximo"] as int? ?? 0;
                  
                  final statusColor = StockUtils.getStockStatusColor(stockActual, stockMinimo);
                  final statusIcon = StockUtils.getStockStatusIcon(stockActual, stockMinimo);
                  final statusText = StockUtils.getStockStatusText(stockActual, stockMinimo);
                  
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        // Nombre del producto
                        Expanded(
                          flex: 35,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product["nombre"].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (product["descripcion"] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  product["descripcion"].toString(),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Stock actual
                        Expanded(
                          flex: 12,
                          child: Text(
                            stockActual.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Stock mínimo
                        Expanded(
                          flex: 12,
                          child: Text(
                            stockMinimo.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        // Stock máximo
                        Expanded(
                          flex: 12,
                          child: Text(
                            stockMaximo.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        // Estado
                        Expanded(
                          flex: 14,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(
                                statusIcon,
                                color: statusColor,
                                size: 14,
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
                        // Acciones
                        Expanded(
                          flex: 15,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const FaIcon(
                                  FontAwesomeIcons.penToSquare,
                                  color: Colors.white54,
                                  size: 16,
                                ),
                                onPressed: () {
                                  // TODO: Implementar edición de producto
                                },
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                padding: EdgeInsets.zero,
                                tooltip: 'Editar producto',
                              ),
                              IconButton(
                                icon: const FaIcon(
                                  FontAwesomeIcons.rightLeft,
                                  color: Color(0xFFE31E24),
                                  size: 16,
                                ),
                                onPressed: () {
                                  // TODO: Implementar transferencia de stock
                                },
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                padding: EdgeInsets.zero,
                                tooltip: 'Transferir stock',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }
      },
    );
  }
}

/// Widget para mostrar un resumen del inventario
class InventarioResumen extends StatelessWidget {
  final String sucursalId;
  final String sucursalNombre;
  
  const InventarioResumen({
    super.key,
    required this.sucursalId,
    required this.sucursalNombre,
  });
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: loadJsonData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        // Buscar la sucursal en los datos
        Map<String, dynamic>? sucursalData;
        for (var data in snapshot.data!) {
          if (data['id'] == sucursalId) {
            sucursalData = data;
            break;
          }
        }
        
        if (sucursalData == null) {
          return const SizedBox.shrink();
        }
        
        final productos = (sucursalData['productos'] as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
        
        // Calcular estadísticas
        int totalProductos = productos.length;
        int productosStockBajo = productos.where((p) => StockUtils.tieneStockBajo(p)).length;
        int productosSinStock = productos.where((p) => StockUtils.sinStock(p)).length;
        
        // Calcular valor total del inventario
        double valorTotal = 0;
        for (var producto in productos) {
          final stockActual = producto['stock_actual'] as int? ?? 0;
          final precioVenta = producto['precio_venta'] as double? ?? 0;
          valorTotal += stockActual * precioVenta;
        }
        
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
                'Resumen de $sucursalNombre',
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
                      totalProductos.toString(),
                      FontAwesomeIcons.boxesStacked,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildStatRow(
                      'Valor del inventario', 
                      StockUtils.formatCurrency(valorTotal),
                      FontAwesomeIcons.moneyBill,
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
                      productosStockBajo.toString(),
                      FontAwesomeIcons.triangleExclamation,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildStatRow(
                      'Productos sin stock', 
                      productosSinStock.toString(),
                      FontAwesomeIcons.circleXmark,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
