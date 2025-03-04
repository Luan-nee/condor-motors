import 'package:flutter/material.dart';
import '../../api/main.api.dart';
import '../../api/productos.api.dart' as productos_api;
import '../../widgets/dialogs/confirm_dialog.dart';

// Modelo temporal para desarrollo
class Sucursal {
  final int id;
  final String nombre;
  final String direccion;
  final bool sucursalCentral;
  final bool activo;

  Sucursal({
    required this.id,
    required this.nombre,
    required this.direccion,
    this.sucursalCentral = false,
    this.activo = true,
  });
}

class ProductosAdminScreen extends StatefulWidget {
  const ProductosAdminScreen({super.key});

  @override
  State<ProductosAdminScreen> createState() => _ProductosAdminScreenState();
}

class _ProductosAdminScreenState extends State<ProductosAdminScreen> {
  final _apiService = ApiService();
  late final productos_api.ProductosApi _productosApi;
  bool _isLoading = false;
  List<productos_api.Producto> _productos = [];
  List<productos_api.Producto> _productosFiltrados = [];
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  List<Sucursal> _sucursales = [];
  Sucursal? _sucursalSeleccionada;

  // Datos de prueba para sucursales
  static final List<Sucursal> _sucursalesPrueba = [
    Sucursal(
      id: 1,
      nombre: 'Sucursal Principal',
      direccion: 'Av. Principal 123',
      sucursalCentral: true,
    ),
    Sucursal(
      id: 2,
      nombre: 'Sucursal Norte',
      direccion: 'Calle Norte 456',
    ),
    Sucursal(
      id: 3,
      nombre: 'Sucursal Sur',
      direccion: 'Av. Sur 789',
    ),
  ];

  final List<String> _categories = [
    'Todos',
    'Cascos',
    'Sliders',
    'Trajes',
    'Repuestos',
    'Stickers',
    'llantas'
  ];

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _marcaController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _precioNormalController = TextEditingController();
  final _precioCompraController = TextEditingController();
  final _precioMayoristaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _productosApi = productos_api.ProductosApi(_apiService);
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _descripcionController.dispose();
    _marcaController.dispose();
    _categoriaController.dispose();
    _precioNormalController.dispose();
    _precioCompraController.dispose();
    _precioMayoristaController.dispose();
    super.dispose();
  }

  void _filtrarProductos() {
    setState(() {
      _productosFiltrados = _productos.where((producto) {
        final matchesSearch = producto.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            producto.codigo.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCategory = _selectedCategory == 'Todos' || 
            producto.categoria == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      // Simulamos carga de sucursales
      await Future.delayed(const Duration(milliseconds: 500));
      final productos = await _productosApi.getProductos();
      
      if (!mounted) return;
      setState(() {
        _sucursales = _sucursalesPrueba;
        _productos = productos;
        _filtrarProductos();
        if (_sucursales.isNotEmpty && _sucursalSeleccionada == null) {
          _sucursalSeleccionada = _sucursales.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _guardarProducto(productos_api.Producto producto) async {
    try {
      if (producto.id == 0) {
        await _productosApi.createProducto(producto.toJson());
      } else {
        await _productosApi.updateProducto(producto.id, producto.toJson());
      }
      if (!mounted) return;
      await _cargarDatos();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto guardado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar producto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarProducto(productos_api.Producto producto) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Eliminar Producto',
        message: '¿Está seguro que desea eliminar el producto "${producto.nombre}"?',
        confirmText: 'Eliminar',
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );

    if (confirmed ?? false) {
      setState(() => _isLoading = true);
      try {
        await _productosApi.deleteProducto(producto.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _cargarDatos();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar producto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showProductDialog(productos_api.Producto? producto) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  producto == null ? 'Nuevo Producto' : 'Editar Producto',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codigoController,
                  decoration: const InputDecoration(labelText: 'Código'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el código';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el nombre';
                    }
                    return null;
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final editedProducto = productos_api.Producto.fromJson({
                            'id': producto?.id ?? 0,
                            'codigo': _codigoController.text,
                            'nombre': _nombreController.text,
                            'descripcion': _descripcionController.text,
                            'marca': _marcaController.text,
                            'categoria': _categoriaController.text,
                            'precio_normal': double.parse(_precioNormalController.text),
                            'precio_compra': double.parse(_precioCompraController.text),
                            'precio_mayorista': _precioMayoristaController.text.isNotEmpty 
                              ? double.parse(_precioMayoristaController.text)
                              : null,
                          });
                          _guardarProducto(editedProducto);
                          Navigator.of(dialogContext).pop();
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
      appBar: AppBar(
        title: const Text('Administración de Productos'),
        actions: [
          if (_sucursales.isNotEmpty)
            DropdownButton<Sucursal>(
              value: _sucursalSeleccionada,
              items: _sucursales.map((sucursal) {
                return DropdownMenuItem(
                  value: sucursal,
                  child: Text(sucursal.nombre),
                );
              }).toList(),
              onChanged: (sucursal) {
                if (sucursal != null) {
                  setState(() => _sucursalSeleccionada = sucursal);
                  _cargarDatos();
                }
              },
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barra de búsqueda y filtros
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Buscar productos',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _filtrarProductos();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _selectedCategory,
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                              _filtrarProductos();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // Lista de productos
                Expanded(
                  child: ListView.builder(
                    itemCount: _productosFiltrados.length,
                    itemBuilder: (context, index) {
                      final producto = _productosFiltrados[index];
                      return ListTile(
                        title: Text(producto.nombre),
                        subtitle: Text('Código: ${producto.codigo}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showProductDialog(producto),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _eliminarProducto(producto),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(null),
        child: const Icon(Icons.add),
      ),
    );
  }
} 