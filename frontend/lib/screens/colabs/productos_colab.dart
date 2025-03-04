import 'package:flutter/material.dart';
import '../../api/productos.api.dart' as productos_api;
import '../../api/main.api.dart';

class ProductosColabScreen extends StatefulWidget {
  const ProductosColabScreen({super.key});

  @override
  State<ProductosColabScreen> createState() => _ProductosColabScreenState();
}

class _ProductosColabScreenState extends State<ProductosColabScreen> {
  final _apiService = ApiService();
  late final productos_api.ProductosApi _productosApi;
  bool _isLoading = false;
  List<productos_api.Producto> _productos = [];
  List<productos_api.Producto> _productosFiltrados = [];
  String _searchQuery = '';
  String _selectedCategory = 'Todos';

  final List<String> _categories = [
    'Todos',
    'Motor',
    'Frenos',
    'Suspensión',
    'Eléctrico',
    'Carrocería',
    'Accesorios'
  ];

  @override
  void initState() {
    super.initState();
    _productosApi = productos_api.ProductosApi(_apiService);
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() => _isLoading = true);
    try {
      final productos = await _productosApi.getProductos();
      
      if (!mounted) return;
      setState(() {
        _productos = productos;
        _filtrarProductos();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar productos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Buscador
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Buscar productos',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _filtrarProductos();
              });
            },
          ),
        ),

        // Categorías
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = category;
                        _filtrarProductos();
                      });
                    }
                  },
                ),
              );
            },
          ),
        ),

        // Lista de productos
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _productosFiltrados.length,
                  itemBuilder: (context, index) {
                    final producto = _productosFiltrados[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.inventory),
                        title: Text(producto.nombre),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Código: ${producto.codigo}'),
                            Text('Marca: ${producto.marca}'),
                            Text('Categoría: ${producto.categoria}'),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'S/ ${producto.precioNormal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (producto.precioMayorista != null)
                              Text(
                                'Mayor: S/ ${producto.precioMayorista!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
