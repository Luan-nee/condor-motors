import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/productos.api.dart' as productos_api;
import '../../api/ventas.api.dart' as ventas_api;
import '../../api/main.api.dart';
import 'inventario_colab.dart';
import 'reports_colab.dart';
import 'ventas_colab.dart';
import 'movimiento_colab.dart';
import 'widgets/notificacion_movimiento.dart';

class SlidesColabScreen extends StatefulWidget {
  const SlidesColabScreen({super.key});

  @override
  State<SlidesColabScreen> createState() => _SlidesColabScreenState();
}

class _SlidesColabScreenState extends State<SlidesColabScreen> {
  late final ApiService _apiService;
  late final productos_api.ProductosApi _productosApi;
  late final ventas_api.VentasApi _ventaApi;
  bool _isLoading = false;
  List<productos_api.Producto> _productos = [];
  List<ventas_api.Venta> _ventasRecientes = [];
  final String _sucursalActual = 'Central'; // TODO: Obtener del login
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _teamMembers = [];
  final String _branchName = 'Sucursal 1'; // TODO: Obtener del login
  final String _branchAddress = 'Av. Principal 123';

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _cargarDatos();
    _loadTeamMembers();
  }

  void _initializeServices() {
    _apiService = ApiService();
    _productosApi = productos_api.ProductosApi(_apiService);
    _ventaApi = ventas_api.VentasApi(_apiService);
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final productos = await _productosApi.getProductos();
      final ventas = await _ventaApi.getVentas(
        sucursal: _sucursalActual,
      );

      if (!mounted) return;
      setState(() {
        _productos = productos;
        _ventasRecientes = ventas;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Condors Motors',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            Text(
              'Reabastecimiento - $_branchName',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          const NotificacionMovimiento(),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Text(
              'JD',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.house),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'Volver al selector',
          ),
          const SizedBox(width: 8),
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
            icon: FaIcon(FontAwesomeIcons.truck),
            selectedIcon: FaIcon(FontAwesomeIcons.truck, color: Colors.blue),
            label: 'Movimientos',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.boxesStacked),
            selectedIcon: FaIcon(FontAwesomeIcons.boxesStacked, color: Colors.blue),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.cashRegister),
            selectedIcon: FaIcon(FontAwesomeIcons.cashRegister, color: Colors.blue),
            label: 'Ventas',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.chartLine),
            selectedIcon: FaIcon(FontAwesomeIcons.chartLine, color: Colors.blue),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const MovimientosColabScreen();
      case 1:
        return const InventarioColabScreen();
      case 2:
        return const VentasColabScreen();
      case 3:
        return const ReportsColabScreen();
      default:
        return const Center(child: Text('Página no encontrada'));
    }
  }

  Widget _buildStatsCards() {
    final productosEscasos = _productos.where((p) => p.activo).length;
    final ventasHoy = _ventasRecientes
        .where((v) => v.fechaCreacion?.day == DateTime.now().day)
        .length;
    final gananciaHoy = _ventasRecientes
        .where((v) => v.fechaCreacion?.day == DateTime.now().day)
        .fold(0.0, (sum, v) => sum + (v.total - v.subtotal));

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Productos Activos',
          productosEscasos.toString(),
          FontAwesomeIcons.triangleExclamation,
          Colors.orange,
        ),
        _buildStatCard(
          'Ventas Hoy',
          ventasHoy.toString(),
          FontAwesomeIcons.cartShopping,
          Colors.blue,
        ),
        _buildStatCard(
          'Ganancia Hoy',
          'S/ ${gananciaHoy.toStringAsFixed(2)}',
          FontAwesomeIcons.moneyBill,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
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
      ),
    );
  }

  Widget _buildProductosEscasos() {
    final productosEscasos = _productos
        .where((p) => p.activo)
        .toList()
      ..sort((a, b) => a.precioNormal.compareTo(b.precioNormal));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Productos Activos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: productosEscasos.length,
          itemBuilder: (context, index) {
            final producto = productosEscasos[index];
            return ListTile(
              title: Text(producto.nombre),
              subtitle: Text('Código: ${producto.codigo}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Categoría: ${producto.categoria}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('S/ ${producto.precioNormal.toStringAsFixed(2)}'),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVentasRecientes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ventas Recientes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _ventasRecientes.length,
          itemBuilder: (context, index) {
            final venta = _ventasRecientes[index];
            return ListTile(
              title: Text('Venta #${venta.id}'),
              subtitle: Text('Fecha: ${venta.fechaCreacion?.toLocal() ?? 'No disponible'}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'S/ ${venta.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'IGV: S/ ${venta.igv.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
