import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CategoriasAdminScreen extends StatefulWidget {
  const CategoriasAdminScreen({super.key});

  @override
  State<CategoriasAdminScreen> createState() => _CategoriasAdminScreenState();
}

class _CategoriasAdminScreenState extends State<CategoriasAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();

  // Datos de ejemplo para las categorías
  final List<Map<String, dynamic>> _categorias = [
    {
      'id': 1,
      'nombre': 'Cascos',
      'descripcion': 'Cascos de seguridad para motociclistas',
      'cantidadProductos': 45,
    },
    {
      'id': 2,
      'nombre': 'Lubricantes',
      'descripcion': 'Aceites y lubricantes para motocicletas',
      'cantidadProductos': 32,
    },
    {
      'id': 3,
      'nombre': 'Llantas',
      'descripcion': 'Llantas y neumáticos para motocicletas',
      'cantidadProductos': 28,
    },
    {
      'id': 4,
      'nombre': 'Repuestos',
      'descripcion': 'Repuestos y partes para motocicletas',
      'cantidadProductos': 156,
    },
  ];

  void _mostrarFormularioCategoria([Map<String, dynamic>? categoria]) {
    _nombreController.text = categoria?['nombre'] ?? '';
    _descripcionController.text = categoria?['descripcion'] ?? '';

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
                      FontAwesomeIcons.folderPlus,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      categoria == null
                          ? 'Crear nueva categoría'
                          : 'Editar categoría',
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
                    labelText: 'Nombre de la categoría',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFFE31E24), width: 2),
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
                      borderSide:
                          BorderSide(color: Color(0xFFE31E24), width: 2),
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
                          // TODO: Implementar guardado de categoría
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
                      FontAwesomeIcons.folderTree,
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
                          'categorías',
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
                  icon: const FaIcon(FontAwesomeIcons.plus,
                      size: 16, color: Colors.white),
                  label: const Text('Nueva Categoría'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31E24),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  onPressed: () => _mostrarFormularioCategoria(),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Tabla de categorías
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Encabezado de la tabla
                      Container(
                        color: const Color(0xFF2D2D2D),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        child: const Row(
                          children: [
                            // Categorías (30% del ancho)
                            Expanded(
                              flex: 30,
                              child: Text(
                                'Categorías',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Descripción (40% del ancho)
                            Expanded(
                              flex: 40,
                              child: Text(
                                'Descripción',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Cant. de productos (15% del ancho)
                            Expanded(
                              flex: 15,
                              child: Text(
                                'Cant. de productos',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Acciones (15% del ancho)
                            Expanded(
                              flex: 15,
                              child: Text(
                                'Acciones',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Filas de categorías
                      ..._categorias.map((categoria) => Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        child: Row(
                          children: [
                            // Categoría
                            Expanded(
                              flex: 30,
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D2D2D),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: FaIcon(
                                        FontAwesomeIcons.folder,
                                        color: Color(0xFFE31E24),
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    categoria['nombre'],
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            // Descripción
                            Expanded(
                              flex: 40,
                              child: Text(
                                categoria['descripcion'],
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                            // Cant. de productos
                            Expanded(
                              flex: 15,
                              child: Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE31E24).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    categoria['cantidadProductos'].toString(),
                                    style: const TextStyle(
                                      color: Color(0xFFE31E24),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Acciones
                            Expanded(
                              flex: 15,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const FaIcon(
                                      FontAwesomeIcons.penToSquare,
                                      color: Colors.white54,
                                      size: 16,
                                    ),
                                    onPressed: () => _mostrarFormularioCategoria(categoria),
                                    constraints: const BoxConstraints(
                                      minWidth: 30,
                                      minHeight: 30,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  IconButton(
                                    icon: const FaIcon(
                                      FontAwesomeIcons.trash,
                                      color: Color(0xFFE31E24),
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      // Implementar eliminación
                                    },
                                    constraints: const BoxConstraints(
                                      minWidth: 30,
                                      minHeight: 30,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
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
    super.dispose();
  }
}
