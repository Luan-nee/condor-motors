import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'ventas_pendientes_utils.dart';

class PendingSalesWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onSaleSelected;
  final List<Map<String, dynamic>> ventasPendientes;
  final VoidCallback? onReload;

  const PendingSalesWidget({
    super.key,
    required this.onSaleSelected,
    required this.ventasPendientes,
    this.onReload,
  });

  @override
  State<PendingSalesWidget> createState() => _PendingSalesWidgetState();
}

class _PendingSalesWidgetState extends State<PendingSalesWidget> {
  bool _isLoading = false;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _cargarVentasPendientes();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarVentasPendientes() async {
    setState(() => _isLoading = true);
    try {
      // Llamar al callback externo si existe
      if (widget.onReload != null) {
        widget.onReload!();
      }
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
  
  // Filtrar ventas pendientes por el texto de búsqueda
  List<Map<String, dynamic>> get ventasFiltradas {
    if (_searchText.isEmpty) {
      return widget.ventasPendientes;
    }
    
    return widget.ventasPendientes.where((venta) {
      // Buscar en nombre de cliente
      final nombreCliente = venta['cliente']['nombre'].toString().toLowerCase();
      if (nombreCliente.contains(_searchText.toLowerCase())) return true;
      
      // Buscar en documento de cliente
      final documento = venta['cliente']['documento'].toString().toLowerCase();
      if (documento.contains(_searchText.toLowerCase())) return true;
      
      // Buscar en ID de venta
      final id = venta['id'].toString().toLowerCase();
      if (id.contains(_searchText.toLowerCase())) return true;
      
      // Buscar en productos
      final tieneProductoCoincidente = (venta['productos'] as List<dynamic>).any((producto) {
        final nombreProducto = producto['nombre'].toString().toLowerCase();
        return nombreProducto.contains(_searchText.toLowerCase());
      });
      
      return tieneProductoCoincidente;
    }).toList();
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
          
          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                hintText: 'Buscar por cliente, documento o producto...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
            ),
          ),
          
          // Lista de ventas pendientes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ventasFiltradas.isEmpty
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
                        itemCount: ventasFiltradas.length,
                        itemBuilder: (context, index) {
                          final venta = ventasFiltradas[index];
                          final esProforma = VentasPendientesUtils.esProforma(venta['id'].toString());
                          
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
                                            color: esProforma
                                                ? const Color(0xFF2196F3).withOpacity(0.1)
                                                : const Color(0xFFE31E24).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: FaIcon(
                                            esProforma
                                                ? FontAwesomeIcons.fileInvoiceDollar
                                                : FontAwesomeIcons.user,
                                            color: esProforma
                                                ? const Color(0xFF2196F3)
                                                : const Color(0xFFE31E24),
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
                                            color: esProforma
                                                ? const Color(0xFF2196F3).withOpacity(0.1)
                                                : const Color(0xFFE31E24).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'S/ ${venta['total'].toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: esProforma
                                                  ? const Color(0xFF2196F3)
                                                  : const Color(0xFFE31E24),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(color: Colors.white24),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${venta['productos'].length} productos',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (esProforma)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2196F3).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'PROFORMA',
                                              style: TextStyle(
                                                color: Color(0xFF2196F3),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                      ],
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