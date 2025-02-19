import 'package:flutter/material.dart';
import '../../api/api.service.dart';
import '../../models/product.dart';
import '../../routes/routes.dart';
import 'inventory_colab.dart';
import 'reports_colab.dart';
import 'ventas_colab.dart';
import 'movements_colab.dart';
import 'widgets/movement_notifications.dart';

class DashboardColabScreen extends StatefulWidget {
  const DashboardColabScreen({super.key});

  @override
  State<DashboardColabScreen> createState() => _DashboardColabScreenState();
}

class _DashboardColabScreenState extends State<DashboardColabScreen> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> _teamMembers = [];
  final String _branchName = 'Sucursal 1'; // TODO: Obtener del login
  final String _branchAddress = 'Av. Principal 123';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadTeamMembers();
  }

  Future<void> _loadProducts() async {
    try {
      final productsData = await _apiService.getProducts();
      setState(() {
        _products = productsData
            .map((product) => Product.fromJson(product))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTeamMembers() async {
    // TODO: Cargar desde API
    setState(() {
      _teamMembers = [
        {
          'nombre': 'Juan Pérez',
          'rol': 'Colaborador',
          'avatar': 'JP',
          'activo': true,
        },
        {
          'nombre': 'María López',
          'rol': 'Vendedor',
          'avatar': 'ML',
          'activo': true,
        },
        {
          'nombre': 'Carlos Ruiz',
          'rol': 'Vendedor',
          'avatar': 'CR',
          'activo': false,
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Condors Motors - Colaborador'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: const [
          MovementNotifications(),
          SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE31E24),
            child: Text(
              'JP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Panel lateral con información del local
          Card(
            margin: const EdgeInsets.all(16),
            child: SizedBox(
              width: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información del local
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _branchName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _branchAddress,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Lista de integrantes
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'Integrantes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._teamMembers.map((member) => ListTile(
                          leading: CircleAvatar(
                            child: Text(member['avatar']),
                          ),
                          title: Text(member['nombre']),
                          subtitle: Text(member['rol']),
                          trailing: Icon(
                            Icons.circle,
                            size: 12,
                            color: member['activo'] ? Colors.green : Colors.grey,
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Contenido principal
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Movimientos',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Ventas',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const MovementsColabScreen();
      case 1:
        return const InventoryColabScreen();
      case 2:
        return const VentasColabScreen();
      case 3:
        return const ReportsColabScreen();
      default:
        return const Center(child: Text('Página no encontrada'));
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Panel de Control - Colaborador',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildStatCards(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    final totalStock = _products.fold<int>(0, (sum, product) => sum + product.stock);
    final totalValue = _products.fold<double>(
        0, (sum, product) => sum + (product.price * product.stock));

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Inventario Total',
          '$totalStock unidades',
          Icons.inventory_2,
          Colors.blue,
        ),
        _buildStatCard(
          'Valor del Inventario',
          'S/ ${totalValue.toStringAsFixed(2)}',
          Icons.monetization_on,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: color),
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actividad Reciente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text('No hay actividad reciente'),
          ],
        ),
      ),
    );
  }
}
