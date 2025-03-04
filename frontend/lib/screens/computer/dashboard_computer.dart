import 'package:flutter/material.dart';
import '../../api/ventas.api.dart' as ventas_api;
import '../../api/stocks.api.dart' as stocks_api;
import '../../api/main.api.dart';

class DashboardComputerScreen extends StatefulWidget {
  const DashboardComputerScreen({super.key});

  @override
  State<DashboardComputerScreen> createState() => _DashboardComputerScreenState();
}

class _DashboardComputerScreenState extends State<DashboardComputerScreen> {
  final _apiService = ApiService();
  late final ventas_api.VentasApi _ventasApi;
  late final stocks_api.StocksApi _stockApi;
  bool _isLoading = false;
  List<ventas_api.Venta> _ventas = [];
  List<stocks_api.Stock> _stocksBajos = [];
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 7));
  DateTime _fechaFin = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ventasApi = ventas_api.VentasApi(_apiService);
    _stockApi = stocks_api.StocksApi(_apiService);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final ventas = await _ventasApi.getVentas(
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );
      
      final stocksBajos = await _stockApi.getLowStockProducts(1); // TODO: Obtener localId del estado global
      
      if (!mounted) return;
      setState(() {
        _ventas = ventas;
        _stocksBajos = stocksBajos;
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

  double get _totalVentas => _ventas.fold(
    0, 
    (sum, venta) => sum + venta.total,
  );

  int get _cantidadVentas => _ventas.length;

  double get _promedioVentas => _cantidadVentas > 0 
    ? _totalVentas / _cantidadVentas 
    : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtros de fecha
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Fecha inicio',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          initialValue: _formatDate(_fechaInicio),
                          onTap: () async {
                            final fecha = await showDatePicker(
                              context: context,
                              initialDate: _fechaInicio,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (fecha != null) {
                              setState(() {
                                _fechaInicio = fecha;
                                _cargarDatos();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Fecha fin',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          initialValue: _formatDate(_fechaFin),
                          onTap: () async {
                            final fecha = await showDatePicker(
                              context: context,
                              initialDate: _fechaFin,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (fecha != null) {
                              setState(() {
                                _fechaFin = fecha;
                                _cargarDatos();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tarjetas de estadísticas
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Ventas',
                          'S/ ${_totalVentas.toStringAsFixed(2)}',
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Cantidad',
                          _cantidadVentas.toString(),
                          Icons.shopping_cart,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Promedio',
                          'S/ ${_promedioVentas.toStringAsFixed(2)}',
                          Icons.analytics,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Lista de ventas recientes
                  const Text(
                    'Ventas Recientes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _ventas.length,
                    itemBuilder: (context, index) {
                      final venta = _ventas[index];
                      return Card(
                        child: ListTile(
                          title: Text('Venta #${venta.id}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fecha: ${_formatDateTime(venta.fechaCreacion)}'),
                              Text('Método: ${venta.metodoPago}'),
                              Text('Estado: ${venta.estado}'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'S/ ${venta.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'IGV: S/ ${venta.igv.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),

                  if (_stocksBajos.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Productos con Stock Bajo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _stocksBajos.length,
                      itemBuilder: (context, index) {
                        final stock = _stocksBajos[index];
                        final producto = stock.producto;
                        if (producto == null) return const SizedBox.shrink();

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.warning, color: Colors.orange),
                            title: Text(producto.nombre),
                            subtitle: Text('Código: ${producto.codigo}'),
                            trailing: Text(
                              '${stock.cantidad} unidades',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'No disponible';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
