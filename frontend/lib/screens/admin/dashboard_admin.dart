import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'productos_admin.dart';
import 'ventas_admin.dart';
import 'settings_admin.dart';
import '../../routes/routes.dart';
import '../../api/main.api.dart';
import '../../api/productos.api.dart' as productos;
import '../../api/stocks.api.dart' hide Producto;

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  late final productos.ProductosApi _productosApi;
  late final StocksApi _stocksApi;
  List<productos.Producto> _productos = [];
  Map<int, int> _existencias = {};
  bool _isLoading = false;
  double _totalVentas = 0;
  double _totalGanancias = 0;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _productosApi = productos.ProductosApi(_apiService);
    _stocksApi = StocksApi(_apiService);
    _screens.addAll([
      _DashboardContent(
        productosList: _productos,
        totalVentas: _totalVentas,
        totalGanancias: _totalGanancias,
        onNavigateToProductos: () => setState(() => _selectedIndex = 1),
        existencias: _existencias,
      ),
      const ProductosAdminScreen(),
      const VentasAdminScreen(),
      const SettingsScreen(),
    ]);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Condors Motors - Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person_outline, size: 35, color: Color(0xFFE31E24)),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Administrador',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'Central Principal',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cerrar Sesión'),
                    content: const Text('¿Estás seguro que deseas cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Cerrar diálogo
                          Navigator.pushReplacementNamed(context, Routes.login);
                        },
                        child: const Text('Cerrar Sesión'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _screens[_selectedIndex],
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final List<productos.Producto> productosList;
  final double totalVentas;
  final double totalGanancias;
  final VoidCallback onNavigateToProductos;
  final Map<int, int> existencias;

  const _DashboardContent({
    required this.productosList,
    required this.totalVentas,
    required this.totalGanancias,
    required this.onNavigateToProductos,
    required this.existencias,
  });

  int getExistencias(productos.Producto producto) {
    return existencias[producto.id] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 800;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWideScreen ? screenWidth * 0.1 : 24.0,
        vertical: 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Panel de Control',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  context,
                  'Ventas Totales',
                  'S/ ${totalVentas.toStringAsFixed(2)}',
                  Icons.point_of_sale,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatsCard(
                  context,
                  'Ganancias',
                  'S/ ${totalGanancias.toStringAsFixed(2)}',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSalesChart(context, isWideScreen),
          const SizedBox(height: 32),
          _buildRecentProducts(context, isMediumScreen),
          const SizedBox(height: 32),
          _buildTopProducts(),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart(BuildContext context, bool isWideScreen) {
    return Container(
      height: isWideScreen ? 400 : 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ventas Mensuales',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('S/ ${value.toInt()}K');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const titles = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun'];
                        if (value.toInt() < titles.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(titles[value.toInt()]),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 4),
                      FlSpot(2, 3.5),
                      FlSpot(3, 5),
                      FlSpot(4, 4),
                      FlSpot(5, 6),
                    ],
                    isCurved: true,
                    color: const Color(0xFFE31E24),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFE31E24).withOpacity(0.1),
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

  Widget _buildRecentProducts(BuildContext context, bool isMediumScreen) {
    if (productosList.isEmpty) {
      return const Center(child: Text('No hay productos disponibles'));
    }

    final recentProducts = productosList.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Productos Recientes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onNavigateToProductos,
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentProducts.length,
            itemBuilder: (context, index) {
              final product = recentProducts[index];
              return Container(
                width: isMediumScreen ? 280 : 220,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.motorcycle, size: 48),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE31E24),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                product.codigo,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stock: ${getExistencias(product)} unidades',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'S/ ${product.precioNormal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFFE31E24),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
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
    );
  }

  Widget _buildTopProducts() {
    final topProducts = List<productos.Producto>.from(productosList)
      ..sort((a, b) => (b.precioNormal).compareTo(a.precioNormal));
    final top5Products = topProducts.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top 5 Productos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...top5Products.map((product) => ListTile(
          title: Text(product.nombre),
          subtitle: Text(
            '${getExistencias(product)} unidades disponibles',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          trailing: Text(
            'S/ ${(product.precioNormal).toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFFE31E24),
              fontWeight: FontWeight.bold,
            ),
          ),
        )),
      ],
    );
  }
}
