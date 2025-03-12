import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/main.api.dart';
import '../../api/productos.api.dart' as productos;
import '../../api/stocks.api.dart' hide Producto;

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  final ApiService _apiService = ApiService();
  late final productos.ProductosApi _productosApi;
  late final StocksApi _stocksApi;
  List<productos.Producto> _productos = [];
  Map<int, int> _existencias = {};
  bool _isLoading = false;
  double _totalVentas = 0;
  double _totalGanancias = 0;

  @override
  void initState() {
    super.initState();
    _productosApi = productos.ProductosApi(_apiService);
    _stocksApi = StocksApi(_apiService);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final productos = await _productosApi.getProductos();
      final ventas = await _productosApi.getVentas();
      
      final stocks = await _stocksApi.getStocks(localId: 1);
      final existencias = <int, int>{};
      for (var stock in stocks) {
        existencias[stock.productoId] = stock.cantidad;
      }
      
      if (!mounted) return;
      setState(() {
        _productos = productos;
        _existencias = existencias;
        _totalVentas = (ventas['total'] as num).toDouble();
        _totalGanancias = (ventas['ganancia'] as num).toDouble();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cargar datos'),
          backgroundColor: Colors.red,
        ),
      );
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _DashboardContent(
      productosList: _productos,
      totalVentas: _totalVentas,
      totalGanancias: _totalGanancias,
      existencias: _existencias,
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final List<productos.Producto> productosList;
  final double totalVentas;
  final double totalGanancias;
  final Map<int, int> existencias;

  const _DashboardContent({
    required this.productosList,
    required this.totalVentas,
    required this.totalGanancias,
    required this.existencias,
  });

  int getExistencias(productos.Producto producto) {
    return existencias[producto.id] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Panel principal (ocupa el 75% del ancho)
        Expanded(
          flex: 75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header con nombre del local
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'INVENTARIO',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      ' / ',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white54,
                      ),
                    ),
                    Text(
                      'Central Principal',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Sección de productos con bajo stock
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF1A1A1A),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Productos con bajo stock',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE31E24),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tabla de productos
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFF2D2D2D),
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Foto',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Producto',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Stock',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Cantidad máxima',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Cantidad mínima',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                          rows: productosList
                              .where((producto) =>
                                  getExistencias(producto) < 10) // Ejemplo de umbral
                              .map(
                                (producto) => DataRow(
                                  cells: [
                                    DataCell(
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2D2D2D),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const FaIcon(
                                          FontAwesomeIcons.motorcycle,
                                          color: Colors.white54,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(
                                      producto.nombre,
                                      style: const TextStyle(color: Colors.white),
                                    )),
                                    DataCell(Text(
                                      getExistencias(producto).toString(),
                                      style: TextStyle(
                                        color: getExistencias(producto) < 5
                                            ? const Color(0xFFE31E24)
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )),
                                    const DataCell(Text(
                                      '50', // Ejemplo de cantidad máxima
                                      style: TextStyle(color: Colors.white),
                                    )),
                                    const DataCell(Text(
                                      '10', // Ejemplo de cantidad mínima
                                      style: TextStyle(color: Colors.white),
                                    )),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Panel lateral derecho (ocupa el 25% del ancho)
        Container(
          width: MediaQuery.of(context).size.width * 0.25,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            border: Border(
              left: BorderSide(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título del panel
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Administrar Locales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.circlePlus,
                        color: Color(0xFFE31E24),
                      ),
                      onPressed: () {
                        // TODO: Implementar agregar local
                      },
                    ),
                  ],
                ),
              ),

              // Tabs de Centrales y Sucursales
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildTab(true, 'Centrales'),
                    const SizedBox(width: 8),
                    _buildTab(false, 'Sucursales'),
                  ],
                ),
              ),

              // Lista de locales
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5, // Ejemplo de cantidad de locales
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                              const FaIcon(
                                FontAwesomeIcons.store,
                                color: Color(0xFFE31E24),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Local ${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Describe la dirección en donde queda el local',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
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
        ),
      ],
    );
  }

  Widget _buildTab(bool isSelected, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? const Color(0xFFE31E24)
                  : Colors.white.withOpacity(0.1),
              width: 2,
            ),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? const Color(0xFFE31E24) : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
