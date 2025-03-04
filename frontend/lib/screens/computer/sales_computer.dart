import 'package:flutter/material.dart';
import '../../api/ventas.api.dart' as ventas_api;
import '../../api/main.api.dart';

class SalesComputerScreen extends StatefulWidget {
  const SalesComputerScreen({super.key});

  @override
  State<SalesComputerScreen> createState() => _SalesComputerScreenState();
}

class _SalesComputerScreenState extends State<SalesComputerScreen> {
  final _apiService = ApiService();
  late final ventas_api.VentasApi _ventasApi;
  bool _isLoading = false;
  List<ventas_api.Venta> _ventas = [];
// TODO: Obtener del login

  @override
  void initState() {
    super.initState();
    _ventasApi = ventas_api.VentasApi(_apiService);
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    setState(() => _isLoading = true);
    try {
      final ventas = await _ventasApi.getVentas();
      if (!mounted) return;
      setState(() {
        _ventas = ventas;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar ventas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _anularVenta(ventas_api.Venta venta) async {
    try {
      await _ventasApi.anularVenta(
        venta.id,
        'Anulado por el usuario',
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venta anulada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      await _cargarVentas();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al anular venta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarVentas,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _ventas.length,
              itemBuilder: (context, index) {
                final venta = _ventas[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ExpansionTile(
                    title: Text('Venta #${venta.id}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fecha: ${_formatDateTime(venta.fechaCreacion)}'),
                        Text('Estado: ${venta.estado}'),
                        Text('Total: S/ ${venta.total.toStringAsFixed(2)}'),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detalles de la Venta',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...venta.detalles.map((detalle) => ListTile(
                              title: Text('Producto #${detalle.productoId}'),
                              subtitle: Text('Cantidad: ${detalle.cantidad}'),
                              trailing: Text(
                                'S/ ${detalle.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Subtotal:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('S/ ${venta.subtotal.toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'IGV:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('S/ ${venta.igv.toStringAsFixed(2)}'),
                              ],
                            ),
                            if (venta.descuentoTotal != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Descuento:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('S/ ${venta.descuentoTotal!.toStringAsFixed(2)}'),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'S/ ${venta.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: Implementar generación de boleta
                                  },
                                  icon: const Icon(Icons.receipt),
                                  label: const Text('Generar Boleta'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: Implementar generación de factura
                                  },
                                  icon: const Icon(Icons.description),
                                  label: const Text('Generar Factura'),
                                ),
                                if (venta.estado != ventas_api.VentasApi.estados['ANULADA'])
                                  ElevatedButton.icon(
                                    onPressed: () => _anularVenta(venta),
                                    icon: const Icon(Icons.cancel),
                                    label: const Text('Anular'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'No disponible';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
} 