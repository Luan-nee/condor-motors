import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MarcasAdminScreen extends StatefulWidget {
  const MarcasAdminScreen({super.key});

  @override
  State<MarcasAdminScreen> createState() => _MarcasAdminScreenState();
}

class _MarcasAdminScreenState extends State<MarcasAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _paisController = TextEditingController();

  // Datos de ejemplo para las marcas
  final List<Map<String, dynamic>> _marcas = [
    {
      'id': 1,
      'nombre': 'MT Helmets',
      'descripcion': 'Fabricante líder de cascos de motocicleta',
      'pais': 'España',
      'cantidadProductos': 45,
      'logo': FontAwesomeIcons.helmetSafety,
    },
    {
      'id': 2,
      'nombre': 'Motul',
      'descripcion': 'Aceites y lubricantes de alta calidad',
      'pais': 'Francia',
      'cantidadProductos': 32,
      'logo': FontAwesomeIcons.oilCan,
    },
    {
      'id': 3,
      'nombre': 'Michelin',
      'descripcion': 'Llantas y neumáticos premium',
      'pais': 'Francia',
      'cantidadProductos': 28,
      'logo': FontAwesomeIcons.ring,
    },
    {
      'id': 4,
      'nombre': 'Honda',
      'descripcion': 'Repuestos originales para motocicletas',
      'pais': 'Japón',
      'cantidadProductos': 156,
      'logo': FontAwesomeIcons.motorcycle,
    },
  ];

  void _mostrarFormularioMarca([Map<String, dynamic>? marca]) {
    _nombreController.text = marca?['nombre'] ?? '';
    _descripcionController.text = marca?['descripcion'] ?? '';
    _paisController.text = marca?['pais'] ?? '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.trademark,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      marca == null ? 'Crear nueva marca' : 'Editar marca',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nombreController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la marca',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE31E24), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese un nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE31E24), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _paisController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'País de origen',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE31E24), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31E24),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // TODO: Implementar guardado de marca
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.tags,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INVENTARIO',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'marcas',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                  label: const Text('Nueva Marca'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31E24),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  onPressed: () => _mostrarFormularioMarca(),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Tabla de marcas
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      const Color(0xFF2D2D2D),
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Marca',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'País',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Descripción',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Cant. de productos',
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
                    rows: _marcas.map((marca) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2D2D2D),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: FaIcon(
                                      marca['logo'] as IconData,
                                      color: const Color(0xFFE31E24),
                                      size: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  marca['nombre'],
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
                                color: const Color(0xFF2D2D2D),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                marca['pais'],
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              marca['descripcion'],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
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
                                marca['cantidadProductos'].toString(),
                                style: const TextStyle(
                                  color: Color(0xFFE31E24),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
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
                                  onPressed: () => _mostrarFormularioMarca(marca),
                                ),
                                IconButton(
                                  icon: const FaIcon(
                                    FontAwesomeIcons.trash,
                                    color: Color(0xFFE31E24),
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    // TODO: Implementar eliminación
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
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _paisController.dispose();
    super.dispose();
  }
}
