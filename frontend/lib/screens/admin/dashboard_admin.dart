import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/index.dart';
import '../../main.dart' show api;
import '../../models/producto.model.dart';
import '../../models/sucursal.model.dart';

// Un modelo básico para el widget de estadísticas del Dashboard
class DashboardItemInfo {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  
  DashboardItemInfo({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
}

// Definición de la clase Stock para manejar los datos
class Stock {
  final int productoId;
  final int cantidad;

  Stock({
    required this.productoId,
    required this.cantidad,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      productoId: json['producto_id'] ?? 0,
      cantidad: json['cantidad'] ?? 0,
    );
  }
}

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  bool _isLoading = true;
  String _sucursalSeleccionadaId = "";

  // Datos para mostrar en el dashboard
  List<Sucursal> _sucursales = [];
  List<Sucursal> _centrales = [];
  List<Producto> _productos = [];
  Map<int, int> _stockPorProducto = {};
  double _totalVentas = 0;
  double _totalGanancias = 0;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      // Cargar sucursales primero
      final sucursalesResponse = await api.sucursales.getSucursales();
      
      List<Sucursal> sucursalesList = [];
      List<Sucursal> centralesList = [];
      
      for (var sucursal in sucursalesResponse) {
        sucursalesList.add(sucursal);
        if (sucursal.sucursalCentral) {
          centralesList.add(sucursal);
        }
      }
      
      // Establecer la sucursal seleccionada: central si existe, o la primera disponible
      String sucursalId = "";
      if (centralesList.isNotEmpty) {
        sucursalId = centralesList.first.id.toString();
      } else if (sucursalesList.isNotEmpty) {
        sucursalId = sucursalesList.first.id.toString();
      }
      
      if (sucursalId.isNotEmpty) {
        _sucursalSeleccionadaId = sucursalId;
        await _loadProductos();
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _sucursales = sucursalesList;
          _centrales = centralesList;
        });
      }
    } catch (e) {
      print('Error cargando datos iniciales: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadProductos() async {
    try {
      // Usar la nueva API de productos
      final productos = await api.productos.getProductos(
        sucursalId: _sucursalSeleccionadaId,
      );
      
      Map<int, int> newExistencias = {};
      
      // Procesar los datos de productos
      for (var producto in productos) {
        newExistencias[producto.id] = producto.stock;
      }
      
      if (mounted) {
        setState(() {
          _productos = productos;
          _stockPorProducto = newExistencias;
        });
      }
    } catch (e) {
      print('Error cargando productos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard de Administración',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await _loadData();
            },
            tooltip: 'Recargar datos',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _DashboardContent(
              productos: _productos,
              totalVentas: _totalVentas,
              totalGanancias: _totalGanancias,
              existencias: _stockPorProducto,
              sucursales: _sucursales,
              centrales: _centrales,
            ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final List<Producto> productos;
  final double totalVentas;
  final double totalGanancias;
  final Map<int, int> existencias;
  final List<Sucursal> sucursales;
  final List<Sucursal> centrales;

  const _DashboardContent({
    required this.productos,
    required this.totalVentas,
    required this.totalGanancias,
    required this.existencias,
    required this.sucursales,
    required this.centrales,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          // Encabezado con tarjetas de resumen
          if (!isMobile)
            Row(
              children: [
                Expanded(child: _buildSummaryCard(
                  title: 'Productos',
                  value: productos.length.toString(),
                  icon: FontAwesomeIcons.boxes,
                  color: Colors.blue,
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryCard(
                  title: 'Ventas',
                  value: 'S/ ${totalVentas.toStringAsFixed(2)}',
                  icon: FontAwesomeIcons.moneyBillWave,
                  color: Colors.green,
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryCard(
                  title: 'Ganancias',
                  value: 'S/ ${totalGanancias.toStringAsFixed(2)}',
                  icon: FontAwesomeIcons.chartLine,
                  color: Colors.purple,
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryCard(
                  title: 'Sucursales',
                  value: sucursales.length.toString(),
                  icon: FontAwesomeIcons.store,
                  color: Colors.orange,
                )),
              ],
            )
          else
            Column(
              children: [
                _buildSummaryCard(
                  title: 'Productos',
                  value: productos.length.toString(),
                  icon: FontAwesomeIcons.boxes,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(
                  title: 'Ventas',
                  value: 'S/ ${totalVentas.toStringAsFixed(2)}',
                  icon: FontAwesomeIcons.moneyBillWave,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(
                  title: 'Ganancias',
                  value: 'S/ ${totalGanancias.toStringAsFixed(2)}',
                  icon: FontAwesomeIcons.chartLine,
                  color: Colors.purple,
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(
                  title: 'Sucursales',
                  value: sucursales.length.toString(),
                  icon: FontAwesomeIcons.store,
                  color: Colors.orange,
                ),
              ],
            ),
          const SizedBox(height: 32),
          
          // Sección de productos con bajo stock
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Productos con stock bajo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE31E24),
                  ),
                ),
                const SizedBox(height: 16),
                // Tabla de productos con stock bajo
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      const Color(0xFF2D2D2D),
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Producto',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'SKU',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Stock Actual',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Stock Mínimo',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Precio',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    rows: productos
                        .where((producto) => producto.stockBajo)
                        .map(
                          (producto) => DataRow(
                            cells: [
                              DataCell(Text(
                                producto.nombre,
                                style: const TextStyle(color: Colors.white),
                              )),
                              DataCell(Text(
                                producto.sku,
                                style: const TextStyle(color: Colors.white70),
                              )),
                              DataCell(Text(
                                producto.stock.toString(),
                                style: TextStyle(
                                  color: producto.stock < (producto.stockMinimo ?? 5)
                                      ? const Color(0xFFE31E24)
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                              DataCell(Text(
                                producto.stockMinimo?.toString() ?? 'N/A',
                                style: const TextStyle(color: Colors.white),
                              )),
                              DataCell(Text(
                                'S/ ${producto.precioVenta.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white),
                              )),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Sección de sucursales
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sucursales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 1 : 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: sucursales.length,
                  itemBuilder: (context, index) {
                    final sucursal = sucursales[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                sucursal.sucursalCentral ? Icons.star : Icons.store,
                                color: sucursal.sucursalCentral ? Colors.amber : Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  sucursal.nombre,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            sucursal.direccion,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      color: const Color(0xFF1A1A1A),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Icon(
              icon,
              color: color,
              size: 48,
            ),
          ],
        ),
      ),
    );
  }
}

