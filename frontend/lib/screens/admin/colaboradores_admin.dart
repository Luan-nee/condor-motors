import 'package:flutter/material.dart';

class ColaboradoresAdminScreen extends StatefulWidget {
  const ColaboradoresAdminScreen({super.key});

  @override
  State<ColaboradoresAdminScreen> createState() => _ColaboradoresAdminScreenState();
}

class _ColaboradoresAdminScreenState extends State<ColaboradoresAdminScreen> {
  final List<Map<String, dynamic>> _colaboradores = [
    {
      'nombre': 'Juan Pérez',
      'rol': 'Vendedor',
      'local': 'Central Principal',
      'estado': true,
    },
    {
      'nombre': 'María García',
      'rol': 'Administrador',
      'local': 'Central Principal',
      'estado': true,
    },
    {
      'nombre': 'Carlos López',
      'rol': 'Vendedor',
      'local': 'Sucursal 1',
      'estado': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Colaboradores',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Colaborador'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31E24),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  onPressed: () {
                    // TODO: Implementar agregar colaborador
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
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
                          'Nombre',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Rol',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Local',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Estado',
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
                    rows: _colaboradores.map((colaborador) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              colaborador['nombre'],
                              style: const TextStyle(color: Colors.white),
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
                                colaborador['rol'],
                                style: const TextStyle(
                                  color: Color(0xFFE31E24),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              colaborador['local'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          DataCell(
                            Switch(
                              value: colaborador['estado'],
                              onChanged: (value) {
                                // TODO: Implementar cambio de estado
                              },
                              activeColor: const Color(0xFFE31E24),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.white54,
                                  ),
                                  onPressed: () {
                                    // TODO: Implementar edición
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFE31E24),
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
} 