import 'package:flutter/material.dart';
import '../../api/api.service.dart';
import '../../api/pendientes.api.dart';
import '../../api/productos.api.dart';
import '../../api/stock.api.dart';
import '../../routes/routes.dart';

class DashboardComputerScreen extends StatefulWidget {
  const DashboardComputerScreen({super.key});

  @override
  State<DashboardComputerScreen> createState() => _DashboardComputerScreenState();
}

class _DashboardComputerScreenState extends State<DashboardComputerScreen> {
  final _ventasApi = VentasApi(ApiService());
  final _stockApi = StockApi(ApiService());
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Stock> _lowStockProducts = [];
  bool _isLoading = false;
  String _currentBranch = 'Sucursal 1';
  final String _computerId = '6';
  final String _localId = '1';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadPendingOrders(),
        _loadLowStockProducts(),
      ]);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPendingOrders() async {
    try {
      final orders = await _ventasApi.getPendingOrders(
        _computerId,
        queryParams: {
          'local_id': _localId,
          'estado': 'PENDIENTE',
          'limit': '10',
        },
      );
      
      if (!mounted) return;
      setState(() {
        _pendingOrders = orders;
        // Actualizar nombre de sucursal si hay ventas
        if (orders.isNotEmpty && orders[0]['local'] != null) {
          _currentBranch = orders[0]['local']['nombre'];
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar ventas pendientes: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: _loadPendingOrders,
          ),
        ),
      );
    }
  }

  Future<void> _loadLowStockProducts() async {
    try {
      final lowStock = await _stockApi.getLowStockProducts(_localId);
      if (!mounted) return;
      setState(() => _lowStockProducts = lowStock);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar productos con bajo stock: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: _loadLowStockProducts,
          ),
        ),
      );
    }
  }

  Future<bool> _verificarStockVenta(Map<String, dynamic> venta) async {
    for (final detalle in (venta['detalles'] as List)) {
      final producto = detalle['producto'] as Map<String, dynamic>;
      final cantidad = detalle['cantidad'] as int;
      
      final tieneStock = await _stockApi.checkStockAvailability(
        localId: _localId,
        productId: producto['id'].toString(),
        cantidad: cantidad,
      );

      if (!tieneStock) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock insuficiente para ${producto['nombre']}'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _confirmarVenta(Map<String, dynamic> venta) async {
    try {
      // Verificar stock antes de confirmar
      final stockSuficiente = await _verificarStockVenta(venta);
      if (!stockSuficiente) return;

      await _ventasApi.confirmOrder(
        venta['id'].toString(),
        _computerId,
      );
      
      // Recargar datos
      _loadPendingOrders();
      _loadLowStockProducts(); // Recargar también el stock

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venta confirmada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al confirmar venta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelarVenta(Map<String, dynamic> venta) async {
    try {
      await _ventasApi.cancelOrder(
        venta['id'].toString(),
        _computerId,
      );
      
      // Recargar datos
      _loadPendingOrders();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venta cancelada'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cancelar venta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Punto de Venta - $_currentBranch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadInitialData();
            },
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, Routes.login),
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Row(
        children: [
          // Panel lateral de ventas
          Container(
            width: 250,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surface,
                  child: const Text(
                    'Ventas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _pendingOrders.length,
                    itemBuilder: (context, index) {
                      final order = _pendingOrders[index];
                      return ListTile(
                        title: Text('Venta #${order['id']}'),
                        subtitle: Text(
                          'Total: S/ ${order['total']}',
                        ),
                        onTap: () {
                          // TODO: Mostrar detalles de la venta
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: Column(
              children: [
                // Barra de búsqueda
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lista de las listas de productos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar productos...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        onChanged: (value) {
                          // TODO: Implementar búsqueda
                        },
                      ),
                    ],
                  ),
                ),

                // Lista de órdenes pendientes
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _pendingOrders.length,
                          itemBuilder: (context, index) {
                            final order = _pendingOrders[index];
                            return _buildPendingOrderCard(order);
                          },
                        ),
                ),

                // Agregar sección de productos con bajo stock
                _buildLowStockWarning(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingOrderCard(Map<String, dynamic> order) {
    final detalles = List<Map<String, dynamic>>.from(order['detalles'] ?? []);
    final vendedor = order['vendedor'] as Map<String, dynamic>? ?? {};
    final total = (order['total'] ?? 0.0) as double;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Venta #${order['id']?.toString() ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                Text(
                  'Total: S/ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFFE31E24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Vendedor: ${vendedor['nombre_completo']?.toString() ?? 'No especificado'}',
            ),
            const SizedBox(height: 16),
            ...detalles.map((detalle) {
              final producto = detalle['producto'] as Map<String, dynamic>? ?? {};
              final cantidad = (detalle['cantidad'] ?? 0) as int;
              final precioUnitario = (detalle['precio_unitario'] ?? 0.0) as double;

              return ListTile(
                dense: true,
                title: Text(producto['nombre']?.toString() ?? ''),
                subtitle: Text(
                  'Código: ${producto['codigo']?.toString() ?? ''}',
                ),
                trailing: Text(
                  '$cantidad x S/ ${precioUnitario.toStringAsFixed(2)}',
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _cancelarVenta(order),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _confirmarVenta(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31E24),
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockWarning() {
    if (_lowStockProducts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Productos con Bajo Stock',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _lowStockProducts.map((stock) {
              final producto = stock.producto;
              if (producto == null) return const SizedBox.shrink();
              
              return Chip(
                label: Text(
                  '${producto.nombre} (${stock.cantidad} unid.)',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.orange,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
