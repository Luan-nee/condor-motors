import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../services/ventas_transfer_service.dart';

class PendingSalesWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onSaleSelected;
  final List<Map<String, dynamic>> ventasPendientes;

  const PendingSalesWidget({
    super.key,
    required this.onSaleSelected,
    required this.ventasPendientes,
  });

  @override
  State<PendingSalesWidget> createState() => _PendingSalesWidgetState();
}

class _PendingSalesWidgetState extends State<PendingSalesWidget> {
  bool _isLoading = false;
  final _ventasTransferService = VentasTransferService();

  @override
  void initState() {
    super.initState();
    _cargarVentasPendientes();
  }

  Future<void> _cargarVentasPendientes() async {
    setState(() => _isLoading = true);
    try {
      // Usar los datos de prueba proporcionados
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar ventas pendientes: $e'),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE31E24).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.clock,
                    color: Color(0xFFE31E24),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Ventas Pendientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _cargarVentasPendientes,
                ),
              ],
            ),
          ),
          
          // Lista de ventas pendientes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : widget.ventasPendientes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const FaIcon(
                                FontAwesomeIcons.check,
                                color: Color(0xFF4CAF50),
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay ventas pendientes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: widget.ventasPendientes.length,
                        itemBuilder: (context, index) {
                          final venta = widget.ventasPendientes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: const Color(0xFF1A1A1A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => widget.onSaleSelected(venta),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE31E24).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const FaIcon(
                                            FontAwesomeIcons.user,
                                            color: Color(0xFFE31E24),
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                venta['cliente']['nombre'],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'Doc: ${venta['cliente']['documento']}',
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE31E24).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'S/ ${venta['total'].toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Color(0xFFE31E24),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(color: Colors.white24),
                                    const SizedBox(height: 12),
                                    Text(
                                      '${venta['productos'].length} productos',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Fecha: ${DateTime.parse(venta['fecha']).toString().substring(0, 16)}',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
} 