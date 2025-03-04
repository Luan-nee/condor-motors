import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class InventarioAdminScreen extends StatefulWidget {
  const InventarioAdminScreen({super.key});

  @override
  State<InventarioAdminScreen> createState() => _InventarioAdminScreenState();
}

class _InventarioAdminScreenState extends State<InventarioAdminScreen> {
  String _selectedLocal = 'Central Principal';
  bool _showCentrales = true;

  // Datos de ejemplo para el inventario
  final List<Map<String, dynamic>> _productos = [
    {
      'id': 1,
      'nombre': 'Casco MT Thunder',
      'categoria': 'Cascos',
      'icon': FontAwesomeIcons.helmetSafety,
      'stock': {
        'Central Principal': 15,
        'Sucursal San Miguel': 8,
        'Sucursal Los Olivos': 5,
      },
      'precio': 299.99,
      'marca': 'MT Helmets',
      'minimo': 10,
      'maximo': 50,
    },
    {
      'id': 2,
      'nombre': 'Aceite Motul 5100',
      'categoria': 'Lubricantes',
      'icon': FontAwesomeIcons.oilCan,
      'stock': {
        'Central Principal': 45,
        'Sucursal San Miguel': 20,
        'Sucursal Los Olivos': 15,
      },
      'precio': 89.99,
      'marca': 'Motul',
      'minimo': 30,
      'maximo': 100,
    },
    {
      'id': 3,
      'nombre': 'Llanta Michelin Pilot',
      'categoria': 'Llantas',
      'icon': FontAwesomeIcons.ring,
      'stock': {
        'Central Principal': 12,
        'Sucursal San Miguel': 6,
        'Sucursal Los Olivos': 4,
      },
      'precio': 459.99,
      'marca': 'Michelin',
      'minimo': 8,
      'maximo': 24,
    },
  ];

  // Datos de ejemplo para los locales
  final List<Map<String, dynamic>> _locales = [
    {
      'nombre': 'Central Principal',
      'direccion': 'Av. La Marina 123, San Miguel',
      'tipo': 'central',
      'icon': FontAwesomeIcons.warehouse,
      'estado': true,
      'productos': 458,
      'valorInventario': 125000.00,
    },
    {
      'nombre': 'Sucursal San Miguel',
      'direccion': 'Av. Universitaria 456, San Miguel',
      'tipo': 'sucursal',
      'icon': FontAwesomeIcons.store,
      'estado': true,
      'productos': 325,
      'valorInventario': 89000.00,
    },
    {
      'nombre': 'Sucursal Los Olivos',
      'direccion': 'Av. Antúnez de Mayolo 789, Los Olivos',
      'tipo': 'sucursal',
      'icon': FontAwesomeIcons.store,
      'estado': true,
      'productos': 289,
      'valorInventario': 76000.00,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Panel principal (75% del ancho)
          Expanded(
            flex: 75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header con nombre del local
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.boxesStacked,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'INVENTARIO',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            ' / ',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white54,
                            ),
                          ),
                          Text(
                            _selectedLocal,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                        label: const Text('Nuevo Producto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE31E24),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () {
                          // TODO: Implementar agregar producto
                        },
                      ),
                    ],
                  ),
                ),

                // Tabla de inventario
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          const Color(0xFF2D2D2D),
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Producto',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Categoría',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Stock Actual',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Stock Mínimo',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Stock Máximo',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Precio',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Acciones',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                        rows: _productos.map((producto) {
                          final stockActual = producto['stock'][_selectedLocal] as int;
                          final stockMinimo = producto['minimo'] as int;
                          
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2D2D2D),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: FaIcon(
                                          producto['icon'] as IconData,
                                          color: Colors.white54,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      producto['nombre'],
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE31E24).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    producto['categoria'],
                                    style: const TextStyle(
                                      color: Color(0xFFE31E24),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  stockActual.toString(),
                                  style: TextStyle(
                                    color: stockActual < stockMinimo
                                        ? const Color(0xFFE31E24)
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(Text(
                                stockMinimo.toString(),
                                style: const TextStyle(color: Colors.white),
                              )),
                              DataCell(Text(
                                producto['maximo'].toString(),
                                style: const TextStyle(color: Colors.white),
                              )),
                              DataCell(Text(
                                'S/ ${producto['precio']}',
                                style: const TextStyle(color: Colors.white),
                              )),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const FaIcon(
                                        FontAwesomeIcons.penToSquare,
                                        color: Colors.white54,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        // TODO: Implementar edición
                                      },
                                    ),
                                    IconButton(
                                      icon: const FaIcon(
                                        FontAwesomeIcons.rightLeft,
                                        color: Color(0xFFE31E24),
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        // TODO: Implementar transferencia
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Panel lateral derecho (25% del ancho)
          Container(
            width: MediaQuery.of(context).size.width * 0.25,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                left: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título del panel
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Control de Locales',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.circlePlus,
                          color: Color(0xFFE31E24),
                          size: 18,
                        ),
                        onPressed: () {
                          // TODO: Implementar agregar local
                        },
                      ),
                    ],
                  ),
                ),

                // Tabs de Centrales y Sucursales
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildTab(true, 'Centrales', () {
                        setState(() => _showCentrales = true);
                      }),
                      const SizedBox(width: 8),
                      _buildTab(false, 'Sucursales', () {
                        setState(() => _showCentrales = false);
                      }),
                    ],
                  ),
                ),

                // Lista de locales
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _locales.length,
                    itemBuilder: (context, index) {
                      final local = _locales[index];
                      if (_showCentrales && local['tipo'] != 'central') return const SizedBox.shrink();
                      if (!_showCentrales && local['tipo'] != 'sucursal') return const SizedBox.shrink();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedLocal == local['nombre']
                              ? const Color(0xFFE31E24).withOpacity(0.1)
                              : const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedLocal == local['nombre']
                                ? const Color(0xFFE31E24)
                                : Colors.transparent,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedLocal = local['nombre'];
                            });
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  FaIcon(
                                    local['icon'] as IconData,
                                    color: _selectedLocal == local['nombre']
                                        ? const Color(0xFFE31E24)
                                        : Colors.white54,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      local['nombre'],
                                      style: TextStyle(
                                        color: _selectedLocal == local['nombre']
                                            ? const Color(0xFFE31E24)
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                local['direccion'],
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStat(
                                    'Productos',
                                    local['productos'].toString(),
                                  ),
                                  _buildStat(
                                    'Valor',
                                    'S/ ${local['valorInventario']}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(bool isSelected, String text, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? const Color(0xFFE31E24)
                    : Colors.white.withOpacity(0.1),
                width: 2,
              ),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFFE31E24) : Colors.white54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
