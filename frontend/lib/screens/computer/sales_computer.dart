import 'package:flutter/material.dart';
import '../../api/api.service.dart';
import '../../api/pendientes.api.dart';

class SalesComputerScreen extends StatefulWidget {
  const SalesComputerScreen({super.key});

  @override
  State<SalesComputerScreen> createState() => _SalesComputerScreenState();
}

class _SalesComputerScreenState extends State<SalesComputerScreen> {
  final _ventasApi = VentasApi(ApiService());
  List<Map<String, dynamic>> _pendingSales = [];
  Map<String, dynamic>? _selectedSale;
  bool _isLoading = false;
  final String _computerId = '6'; // TODO: Obtener del login
  final String _localId = '1';

  @override
  void initState() {
    super.initState();
    _loadPendingSales();
  }

  Future<void> _loadPendingSales() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    try {
      final sales = await _ventasApi.getPendingOrders(
        _computerId,
        queryParams: {
          'local_id': _localId,
          'estado': 'PENDIENTE',
          'desde': DateTime.now().subtract(const Duration(days: 1)).toUtc().toIso8601String(),
          'hasta': DateTime.now().toUtc().toIso8601String(),
          'limit': '50',
        },
      );
      
      if (!mounted) return;
      setState(() {
        _pendingSales = sales;
        _selectedSale = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar ventas: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: _loadPendingSales,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmarVenta(Map<String, dynamic> venta) async {
    try {
      final response = await _ventasApi.confirmOrder(
        venta['id'].toString(),
        _computerId,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venta confirmada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Recargar ventas pendientes
      _loadPendingSales();
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

  Future<void> _rechazarVenta(Map<String, dynamic> venta) async {
    try {
      await _ventasApi.rejectOrder(venta['id'].toString());
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venta rechazada'),
          backgroundColor: Colors.orange,
        ),
      );

      // Recargar ventas pendientes
      _loadPendingSales();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al rechazar venta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Condors Motors',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            Text(
              'Ventas - ${_pendingSales.isNotEmpty ? _pendingSales[0]['local']['nombre'] : 'Cargando...'}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingSales,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Panel izquierdo - Lista de ventas pendientes
                Expanded(
                  flex: 2,
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Ventas Pendientes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _pendingSales.length,
                            itemBuilder: (context, index) {
                              final sale = _pendingSales[index];
                              final isSelected = _selectedSale == sale;
                              
                              return ListTile(
                                selected: isSelected,
                                title: Text('Venta #${sale['id']}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Vendedor: ${sale['vendedor']['nombre_completo']}'),
                                    Text('Estado: ${sale['estado']}'),
                                    Text('Total: S/ ${sale['total']}'),
                                  ],
                                ),
                                trailing: sale['estado'] == 'PENDIENTE'
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.check_circle_outline),
                                            color: Colors.green,
                                            onPressed: () => _confirmarVenta(sale),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.cancel_outlined),
                                            color: Colors.red,
                                            onPressed: () => _rechazarVenta(sale),
                                          ),
                                        ],
                                      )
                                    : null,
                                onTap: () {
                                  setState(() => _selectedSale = sale);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Panel derecho - Detalles de venta y opciones
                Expanded(
                  flex: 3,
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalles de Venta',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Información del cliente
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Información del Cliente',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'DNI/RUC',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Nombre/Razón Social',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Lista de productos
                          const Text(
                            'Productos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _pendingSales[0]['detalles'].length,
                              itemBuilder: (context, index) {
                                final detalle = _pendingSales[0]['detalles'][index];
                                return ListTile(
                                  title: Text(detalle['producto']['nombre']),
                                  subtitle: Text('Cantidad: ${detalle['cantidad']}'),
                                  trailing: Text(
                                    'S/ ${(detalle['precio_unitario'] * detalle['cantidad']).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Totales y botones
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total: S/ 51.98',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.receipt_long),
                                    label: const Text('Generar Boleta'),
                                    onPressed: () {
                                      // TODO: Implementar generación de boleta
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.receipt),
                                    label: const Text('Generar Factura'),
                                    onPressed: () {
                                      // TODO: Implementar generación de factura
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
} 