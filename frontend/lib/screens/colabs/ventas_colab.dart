import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'barcode_colab.dart';

class VentasColabScreen extends StatefulWidget {
  const VentasColabScreen({super.key});

  @override
  State<VentasColabScreen> createState() => _VentasColabScreenState();
}

class _VentasColabScreenState extends State<VentasColabScreen> {
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedFilter = 'Todos';

  // Datos de ejemplo para ventas
  final List<Map<String, dynamic>> _ventas = [
    {
      'id': 1,
      'codigo': 'V001',
      'fecha': '2024-03-12 10:00:00',
      'cliente': 'Juan Pérez',
      'total': 460.18,
      'estado': 'COMPLETADA',
      'metodoPago': 'EFECTIVO',
      'productos': [
        {
          'nombre': 'Casco MT Thunder',
          'cantidad': 1,
          'precio': 299.99,
          'subtotal': 299.99
        },
        {
          'nombre': 'Aceite Motul 5100',
          'cantidad': 1,
          'precio': 89.99,
          'subtotal': 89.99
        }
      ]
    },
    {
      'id': 2,
      'codigo': 'V002',
      'fecha': '2024-03-12 11:30:00',
      'cliente': 'María García',
      'total': 850.00,
      'estado': 'PENDIENTE',
      'metodoPago': 'TARJETA',
      'productos': [
        {
          'nombre': 'Kit de Frenos Brembo',
          'cantidad': 1,
          'precio': 850.00,
          'subtotal': 850.00
        }
      ]
    },
    {
      'id': 3,
      'codigo': 'V003',
      'fecha': '2024-03-12 12:15:00',
      'cliente': 'Carlos López',
      'total': 599.99,
      'estado': 'ANULADA',
      'metodoPago': 'EFECTIVO',
      'productos': [
        {
          'nombre': 'Amortiguador YSS',
          'cantidad': 1,
          'precio': 599.99,
          'subtotal': 599.99
        }
      ]
    }
  ];

  // Filtros disponibles
  final List<String> _filters = [
    'Todos',
    'Completadas',
    'Pendientes',
    'Anuladas'
  ];

  List<Map<String, dynamic>> _getVentasFiltradas() {
    if (_searchQuery.isEmpty && _selectedFilter == 'Todos') {
      return _ventas;
    }

    return _ventas.where((venta) {
      final matchesSearch = 
          venta['codigo'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          venta['cliente'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesFilter = _selectedFilter == 'Todos' || 
          venta['estado'] == _selectedFilter.toUpperCase().replaceAll('S', '');
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _escanearProducto() async {
    final producto = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeColabScreen()),
    );

    if (producto != null) {
      // TODO: Agregar producto a la venta actual
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto escaneado: ${producto['nombre']}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ventasFiltradas = _getVentasFiltradas();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [
          // Header con título y botón de nueva venta
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.cashRegister,
                        size: 24,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VENTAS',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'gestión de ventas',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const FaIcon(
                        FontAwesomeIcons.barcode,
                        size: 16,
                      ),
                      label: const Text('Escanear'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C27B0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _escanearProducto,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const FaIcon(
                        FontAwesomeIcons.plus,
                        size: 16,
                      ),
                      label: const Text('Nueva Venta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        // TODO: Implementar nueva venta
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Barra de búsqueda y filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Buscador
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar por código o cliente...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2D2D2D),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Filtros
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      dropdownColor: const Color(0xFF2D2D2D),
                      style: const TextStyle(color: Colors.white),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      items: _filters.map((String filter) {
                        return DropdownMenuItem<String>(
                          value: filter,
                          child: Text(filter),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedFilter = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de ventas
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                    ),
                  )
                : ventasFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.receipt,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay ventas ${_selectedFilter != 'Todos' ? _selectedFilter.toLowerCase() : ''}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(isMobile ? 8 : 16),
                        itemCount: ventasFiltradas.length,
                        itemBuilder: (context, index) {
                          final venta = ventasFiltradas[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D2D),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ExpansionTile(
                              leading: _buildEstadoIcon(venta['estado']),
                              title: Row(
                                children: [
                                  Text(
                                    venta['codigo'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    venta['cliente'],
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    venta['fecha'],
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      venta['metodoPago'],
                                      style: const TextStyle(
                                        color: Color(0xFF4CAF50),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                'S/ ${venta['total'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              children: [
                                // Detalles de la venta
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Productos',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...venta['productos'].map<Widget>((producto) {
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1A1A1A),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const FaIcon(
                                                  FontAwesomeIcons.box,
                                                  color: Color(0xFF4CAF50),
                                                  size: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      producto['nombre'],
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${producto['cantidad']} x S/ ${producto['precio'].toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        color: Colors.grey[400],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                'S/ ${producto['subtotal'].toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFF4CAF50),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Total:',
                                              style: TextStyle(
                                                color: Color(0xFF4CAF50),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'S/ ${venta['total'].toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Color(0xFF4CAF50),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
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
      ),
    );
  }

  Widget _buildEstadoIcon(String estado) {
    IconData icon;
    Color color;
    
    switch (estado) {
      case 'COMPLETADA':
        icon = FontAwesomeIcons.check;
        color = const Color(0xFF4CAF50);
        break;
      case 'PENDIENTE':
        icon = FontAwesomeIcons.clock;
        color = Colors.orange;
        break;
      case 'ANULADA':
        icon = FontAwesomeIcons.xmark;
        color = const Color(0xFFE31E24);
        break;
      default:
        icon = FontAwesomeIcons.question;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FaIcon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }
}
