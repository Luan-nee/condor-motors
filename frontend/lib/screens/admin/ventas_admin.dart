import 'package:flutter/material.dart';
import '../../api/ventas.api.dart' as ventas_api;
import '../../api/main.api.dart';

class VentasAdminScreen extends StatefulWidget {
  const VentasAdminScreen({super.key});

  @override
  State<VentasAdminScreen> createState() => _VentasAdminScreenState();
}

class _VentasAdminScreenState extends State<VentasAdminScreen> {
  final _apiService = ApiService();
  late final ventas_api.VentasApi _ventaApi;
  bool _isLoading = false;
  List<ventas_api.Venta> _ventas = [];

  @override
  void initState() {
    super.initState();
    _ventaApi = ventas_api.VentasApi(_apiService);
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final ventas = await _ventaApi.getVentas();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
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
                  child: ListTile(
                    title: Text('Venta #${venta.id}'),
                    subtitle: Text('Fecha: ${venta.fechaCreacion?.toLocal() ?? 'No disponible'}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total: S/ ${venta.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Subtotal: S/ ${venta.subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
} 