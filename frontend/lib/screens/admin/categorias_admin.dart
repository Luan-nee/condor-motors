import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../main.dart' show api;

class CategoriasAdminScreen extends StatefulWidget {
  const CategoriasAdminScreen({super.key});

  @override
  State<CategoriasAdminScreen> createState() => _CategoriasAdminScreenState();
}

class _CategoriasAdminScreenState extends State<CategoriasAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  bool _isLoading = false;
  bool _isCreating = false;
  String _errorMessage = '';

  // Lista de categorías obtenidas de la API
  List<Map<String, dynamic>> _categorias = [];

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  // Método para cargar las categorías desde la API
  Future<void> _cargarCategorias() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      debugPrint('Cargando categorías desde la API...');
      final categoriasList = await api.categorias.getCategorias();
      
      if (!mounted) return;
      
      // Convertir la lista de categorías a un formato más manejable
      final List<Map<String, dynamic>> categoriasFormateadas = [];
      
      for (var categoria in categoriasList) {
        categoriasFormateadas.add({
          'id': categoria['id'],
          'nombre': categoria['nombre'] ?? 'Sin nombre',
          'descripcion': categoria['descripcion'] ?? 'Sin descripción',
          'cantidadProductos': categoria['cantidadProductos'] ?? 0,
        });
      }
      
      setState(() {
        _categorias = categoriasFormateadas;
        _isLoading = false;
      });
      
      debugPrint('${_categorias.length} categorías cargadas correctamente');
    } catch (e) {
      if (!mounted) return;
      
      debugPrint('Error al cargar categorías: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar categorías: $e';
        
        // En caso de error, usar datos de ejemplo para desarrollo
        _categorias = [
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
      });
    }
  }

  // Método para crear o actualizar una categoría
  Future<void> _guardarCategoria([Map<String, dynamic>? categoriaExistente]) async {
    if (!_formKey.currentState!.validate()) return;
    
    final nombre = _nombreController.text.trim();
    final descripcion = _descripcionController.text.trim();
    
    setState(() {
      _isCreating = true;
      _errorMessage = '';
    });
    
    try {
      if (categoriaExistente == null) {
        // Crear nueva categoría
        debugPrint('Creando nueva categoría: $nombre');
        final nuevaCategoria = await api.categorias.createCategoria(
          nombre: nombre,
          descripcion: descripcion.isNotEmpty ? descripcion : null,
        );
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Categoría creada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recargar las categorías para mostrar la nueva
        await _cargarCategorias();
      } else {
        // Actualizar categoría existente
        debugPrint('Actualizando categoría: ${categoriaExistente['id']}');
        final categoriaActualizada = await api.categorias.updateCategoria(
          id: categoriaExistente['id'].toString(),
          nombre: nombre,
          descripcion: descripcion.isNotEmpty ? descripcion : null,
        );
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Categoría actualizada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recargar las categorías para mostrar los cambios
        await _cargarCategorias();
      }
    } catch (e) {
      if (!mounted) return;
      
      debugPrint('Error al guardar categoría: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar categoría: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        Navigator.pop(context);
      }
    }
  }

  // Método para eliminar una categoría
  Future<void> _eliminarCategoria(Map<String, dynamic> categoria) async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '¿Eliminar categoría?',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta acción eliminará la categoría "${categoria['nombre']}" y no se puede deshacer.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            if (categoria['cantidadProductos'] > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta categoría tiene ${categoria['cantidadProductos']} productos asociados. Al eliminarla, estos productos quedarán sin categoría.',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31E24),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    
    if (confirmar != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await api.categorias.deleteCategoria(categoria['id'].toString());
      
      if (!mounted) return;
      
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Categoría eliminada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recargar las categorías
        await _cargarCategorias();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo eliminar la categoría'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      debugPrint('Error al eliminar categoría: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar categoría: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
                      onPressed: _isCreating ? null : () => Navigator.pop(context),
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
                      onPressed: _isCreating 
                        ? null 
                        : () => _guardarCategoria(categoria),
                      child: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Guardar'),
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
                Row(
                  children: [
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cargando...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.arrowsRotate,
                        color: Colors.white,
                        size: 16,
                      ),
                      onPressed: _isLoading ? null : _cargarCategorias,
                      tooltip: 'Recargar categorías',
                    ),
                    const SizedBox(width: 16),
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
              ],
            ),
            const SizedBox(height: 32),

            // Mensaje de error si existe
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _errorMessage = '';
                        });
                      },
                    ),
                  ],
                ),
              ),

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
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _categorias.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.folderOpen,
                                  color: Colors.grey,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay categorías disponibles',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  icon: const FaIcon(
                                    FontAwesomeIcons.plus,
                                    size: 14,
                                  ),
                                  label: const Text('Crear categoría'),
                                  onPressed: () => _mostrarFormularioCategoria(),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
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
                                              onPressed: () => _eliminarCategoria(categoria),
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
