import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../api/main.api.dart' show ApiException;
import '../../api/protected/marcas.api.dart';
import '../../main.dart' show api;

class MarcasAdminScreen extends StatefulWidget {
  const MarcasAdminScreen({super.key});

  @override
  State<MarcasAdminScreen> createState() => _MarcasAdminScreenState();
}

class _MarcasAdminScreenState extends State<MarcasAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  List<Marca> _marcas = [];
  Map<String, int> _productosPorMarca = {};

  @override
  void initState() {
    super.initState();
    _cargarMarcas();
  }

  Future<void> _cargarMarcas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final response = await api.marcas.getMarcas();
      
      final List<Marca> marcas = [];
      for (var item in response) {
        marcas.add(Marca.fromJson(item));
      }
      
      // TODO: Obtener cantidad de productos por marca desde el API cuando esté disponible
      // Por ahora usar datos de ejemplo
      final tempProductosPorMarca = <String, int>{};
      for (var marca in marcas) {
        tempProductosPorMarca[marca.id] = (marca.id.hashCode % 100) + 5; // Valor aleatorio de ejemplo
      }
      
      if (!mounted) return;
      setState(() {
        _marcas = marcas;
        _productosPorMarca = tempProductosPorMarca;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar marcas: $e';
      });
      
      // Manejar errores de autenticación
      if (e is ApiException && e.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión expirada. Por favor, inicie sesión nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
        await Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }
  
  Future<void> _guardarMarca([Marca? marca]) async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      setState(() => _isLoading = true);
      
      final marcaData = {
        'nombre': _nombreController.text,
        'descripcion': _descripcionController.text,
      };
      
      if (marca != null) {
        // Actualizar marca existente
        await api.marcas.updateMarca(marca.id, marcaData);
      } else {
        // Crear nueva marca
        await api.marcas.createMarca(marcaData);
      }
      
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(marca == null ? 'Marca creada correctamente' : 'Marca actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      await _cargarMarcas(); // Recargar la lista
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar marca: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _eliminarMarca(Marca marca) async {
    try {
      setState(() => _isLoading = true);
      
      await api.marcas.deleteMarca(marca.id);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marca eliminada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      await _cargarMarcas(); // Recargar la lista
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar marca: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarFormularioMarca([Marca? marca]) {
    _nombreController.text = marca?.nombre ?? '';
    _descripcionController.text = marca?.descripcion ?? '';

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
                      onPressed: _isLoading 
                          ? null 
                          : () => _guardarMarca(marca),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
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

  void _mostrarConfirmacion(Marca marca) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '¿Eliminar marca?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Está seguro que desea eliminar la marca "${marca.nombre}"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31E24),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _eliminarMarca(marca);
            },
            child: const Text('Eliminar'),
          ),
        ],
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
                  icon: const FaIcon(FontAwesomeIcons.plus,
                      size: 16, color: Colors.white),
                  label: const Text('Nueva Marca'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31E24),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  onPressed: _isLoading ? null : () => _mostrarFormularioMarca(),
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _errorMessage,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE31E24),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _cargarMarcas,
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          )
                        : _marcas.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay marcas registradas',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Encabezado de la tabla
                                    Container(
                                      color: const Color(0xFF2D2D2D),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 20),
                                      child: const Row(
                                        children: [
                                          // Marca (35% del ancho)
                                          Expanded(
                                            flex: 35,
                                            child: Text(
                                              'Marca',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // Descripción (45% del ancho)
                                          Expanded(
                                            flex: 45,
                                            child: Text(
                                              'Descripción',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // Cant. de productos (10% del ancho)
                                          Expanded(
                                            flex: 10,
                                            child: Text(
                                              'Productos',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // Acciones (10% del ancho)
                                          Expanded(
                                            flex: 10,
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

                                    // Filas de marcas
                                    ..._marcas.map((marca) => Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.white.withOpacity(0.1),
                                              ),
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 20),
                                          child: Row(
                                            children: [
                                              // Marca
                                              Expanded(
                                                flex: 35,
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF2D2D2D),
                                                        borderRadius:
                                                            BorderRadius.circular(8),
                                                      ),
                                                      child: const Center(
                                                        child: FaIcon(
                                                          FontAwesomeIcons.tag,
                                                          color: Color(0xFFE31E24),
                                                          size: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      marca.nombre,
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Descripción
                                              Expanded(
                                                flex: 45,
                                                child: Text(
                                                  marca.descripcion ?? 'Sin descripción',
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.7),
                                                  ),
                                                ),
                                              ),
                                              // Cant. de productos
                                              Expanded(
                                                flex: 10,
                                                child: Center(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFE31E24)
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      _productosPorMarca[marca.id]
                                                              ?.toString() ??
                                                          '0',
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
                                                flex: 10,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    IconButton(
                                                      icon: const FaIcon(
                                                        FontAwesomeIcons.penToSquare,
                                                        color: Colors.white54,
                                                        size: 16,
                                                      ),
                                                      onPressed: () =>
                                                          _mostrarFormularioMarca(marca),
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
                                                      onPressed: () =>
                                                          _mostrarConfirmacion(marca),
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
                                        )),
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
