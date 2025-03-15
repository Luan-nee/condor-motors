import 'package:flutter/material.dart';
import '../../main.dart' show api;
import '../../models/producto.model.dart';
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
  bool _isLoading = false;
  List<Producto> _productos = [];
  List<Producto> _productosFiltrados = [];
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
  final _precioController = TextEditingController();
  final _precioCompraController = TextEditingController();
  final _existenciasController = TextEditingController();
  final _localController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _descripcionController.dispose();
    _marcaController.dispose();
    _categoriaController.dispose();
    _precioController.dispose();
    _precioCompraController.dispose();
    _existenciasController.dispose();
    _localController.dispose();
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
      final productosResponse = await api.productos.getProductos();
      
      final List<Producto> productosList = [];
      for (var item in productosResponse) {
        productosList.add(Producto.fromJson(item));
      }
      
      if (!mounted) return;
      setState(() {
        _sucursales = _sucursalesPrueba;
        _productos = productosList;
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

  Future<void> _guardarProducto(Producto producto) async {
    try {
      if (producto.id == 0) {
        await api.productos.createProducto(producto.toJson());
      } else {
        await api.productos.updateProducto(producto.id.toString(), producto.toJson());
      }
      if (!mounted) return;
      await _cargarDatos();
      if (!mounted) return;
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

  Future<void> _eliminarProducto(Producto producto) async {
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
        await api.productos.deleteProducto(producto.id.toString());
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

  void _showProductDialog(Producto? producto) {
    if (producto != null) {
      // Inicializar controladores con datos del producto
      _nombreController.text = producto.nombre;
      _codigoController.text = producto.codigo;
      _descripcionController.text = producto.descripcion;
      _marcaController.text = producto.marca;
      _categoriaController.text = producto.categoria;
      _precioController.text = producto.precio.toString();
      _precioCompraController.text = producto.precioCompra.toString();
      _existenciasController.text = producto.existencias.toString();
      _localController.text = producto.local;
    } else {
      // Limpiar controladores para nuevo producto
      _nombreController.clear();
      _codigoController.clear();
      _descripcionController.clear();
      _marcaController.clear();
      _categoriaController.text = _categories.length > 1 ? _categories[1] : '';
      _precioController.clear();
      _precioCompraController.clear();
      _existenciasController.text = '0';
      _localController.text = _sucursalSeleccionada?.nombre ?? '';
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Container(
          width: 500, // Ancho fijo para el diálogo
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto == null ? 'Nuevo Producto' : 'Editar Producto',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _codigoController,
                          decoration: const InputDecoration(labelText: 'Código'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese el código';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _categoriaController,
                          decoration: const InputDecoration(labelText: 'Categoría'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese la categoría';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
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
                  TextFormField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese la descripción';
                      }
                      return null;
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _marcaController,
                          decoration: const InputDecoration(labelText: 'Marca'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese la marca';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _localController,
                          decoration: const InputDecoration(labelText: 'Local'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese el local';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _precioController,
                          decoration: const InputDecoration(labelText: 'Precio'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese el precio';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Ingrese un número válido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _precioCompraController,
                          decoration: const InputDecoration(labelText: 'Precio de compra'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese el precio de compra';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Ingrese un número válido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _existenciasController,
                    decoration: const InputDecoration(labelText: 'Existencias'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese las existencias';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Ingrese un número entero válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Crear un nuevo objeto Producto con los valores del formulario
                            final now = DateTime.now();
                            final editedProducto = Producto(
                              id: producto?.id ?? 0,
                              nombre: _nombreController.text,
                              codigo: _codigoController.text,
                              precio: double.parse(_precioController.text),
                              precioCompra: double.parse(_precioCompraController.text),
                              existencias: int.parse(_existenciasController.text),
                              descripcion: _descripcionController.text,
                              categoria: _categoriaController.text,
                              marca: _marcaController.text,
                              esLiquidacion: producto?.esLiquidacion ?? false,
                              local: _localController.text,
                              reglasDescuento: producto?.reglasDescuento ?? [],
                              fechaCreacion: producto?.fechaCreacion ?? now,
                              fechaActualizacion: now,
                              tieneDescuento: producto?.tieneDescuento ?? false,
                            );
                            
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
                  child: _productosFiltrados.isEmpty
                      ? const Center(
                          child: Text('No se encontraron productos'),
                        )
                      : ListView.builder(
                          itemCount: _productosFiltrados.length,
                          itemBuilder: (context, index) {
                            final producto = _productosFiltrados[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                title: Text(producto.nombre),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Código: ${producto.codigo}'),
                                    Text('Precio: S/ ${producto.precio.toStringAsFixed(2)} | Stock: ${producto.existencias}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _showProductDialog(producto),
                                      tooltip: 'Editar',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _eliminarProducto(producto),
                                      tooltip: 'Eliminar',
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(null),
        child: const Icon(Icons.add),
        tooltip: 'Agregar producto',
      ),
    );
  }
} 