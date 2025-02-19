import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../api/api.service.dart';
import 'product_form_dialog.dart';
import '../../models/branch.dart';

class ProductosAdminScreen extends StatefulWidget {
  const ProductosAdminScreen({super.key});

  @override
  State<ProductosAdminScreen> createState() => _ProductosAdminScreenState();
}

class _ProductosAdminScreenState extends State<ProductosAdminScreen> {
  final ApiService _apiService = ApiService();
  String _selectedCategory = 'Todos';
  String _selectedLocal = 'Todos';
  String _selectedView = 'todos'; // todos, escasos, masVendidos, menosVendidos
  bool _isLoading = false;
  List<Product> _products = [];
  List<Branch> _branches = []; // Agregada lista de sucursales
  Branch? _selectedBranch; // Agregada sucursal seleccionada
  String _searchQuery = '';

  final List<String> _categories = [
    'Todos',
    'Cascos',
    'Sliders',
    'Trajes',
    'Repuestos',
    'Stickers',
    'llantas'
  ];

  List<Product> get _filteredProducts {
    var filtered = _products.where((product) {
      final matchesCategory = _selectedCategory == 'Todos' || 
                            product.category == _selectedCategory;
      final matchesLocal = _selectedLocal == 'Todos' ||
                          product.local == _selectedLocal;
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.codigo.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesLocal && matchesSearch;
    }).toList();

    // Aplicar filtros adicionales
    switch (_selectedView) {
      case 'escasos':
        filtered.sort((a, b) => a.stock.compareTo(b.stock));
        return filtered.take(20).toList();
      case 'masVendidos':
        filtered.sort((a, b) => b.profit.compareTo(a.profit));
        return filtered.take(20).toList();
      case 'menosVendidos':
        filtered.sort((a, b) => a.profit.compareTo(b.profit));
        return filtered.take(20).toList();
      default:
        return filtered;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadProducts(),
        _loadBranches(),
      ]);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadBranches() async {
    try {
      // TODO: Implementar carga desde API
      setState(() {
        _branches = [
          Branch(
            id: 1,
            name: 'Central Lima',
            address: 'Av. La Marina 123',
            type: 'central',
            phone: '(01) 123-4567',
            manager: 'Juan Pérez',
          ),
          Branch(
            id: 2,
            name: 'Sucursal Miraflores',
            address: 'Av. Larco 456',
            type: 'sucursal',
            phone: '(01) 987-6543',
            manager: 'Ana García',
          ),
        ];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar sucursales'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _apiService.getProducts();
      if (mounted) {
        setState(() {
          _products = products.map((p) => Product.fromJson(p)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar productos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddEditProductDialog([Product? product]) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => ProductFormDialog(
        product: product,
        onSave: (editedProduct) async {
          setState(() => _isLoading = true);
          try {
            await _apiService.saveProduct(editedProduct);
            if (mounted) {
              await _loadProducts();
              Navigator.pop(dialogContext);
            }
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Error al guardar el producto'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
          if (mounted) {
            setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    if (isSmallScreen) {
      // Vista móvil - Layout vertical
      return Column(
        children: [
          // Barra superior con título y búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Productos - $_selectedCategory',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showAddEditProductDialog(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ],
            ),
          ),

          // Filtros en modo compacto
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Botón de locales
                PopupMenuButton<String>(
                  initialValue: _selectedLocal,
                  child: Chip(
                    label: Text('Local: $_selectedLocal'),
                    deleteIcon: const Icon(Icons.arrow_drop_down),
                    onDeleted: () {},
                  ),
                  onSelected: (String value) {
                    setState(() {
                      _selectedLocal = value;
                    });
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'Todos',
                      child: Text('Todos'),
                    ),
                    const PopupMenuItem(
                      value: 'central',
                      child: Text('Centrales'),
                    ),
                    const PopupMenuItem(
                      value: 'sucursal',
                      child: Text('Sucursales'),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Filtros de vista en chips
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _selectedView == 'todos',
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        _selectedView = 'todos';
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Stock Bajo'),
                  selected: _selectedView == 'escasos',
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        _selectedView = 'escasos';
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Más Vendidos'),
                  selected: _selectedView == 'masVendidos',
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        _selectedView = 'masVendidos';
                      });
                    }
                  },
                ),
              ],
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
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Grid de productos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 columnas en móvil
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return _buildProductCard(product);
                    },
                  ),
          ),
        ],
      );
    } else {
      // Vista desktop - Layout horizontal (código existente)
      return Row(
        children: [
          // Contenido principal
          Expanded(
            child: Column(
              children: [
                // Barra superior con título, filtros y búsqueda
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Productos - $_selectedCategory',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // Campo de búsqueda
                          Container(
                            width: 300,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Buscar productos...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _showAddEditProductDialog(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Filtros de vista
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'todos',
                            label: Text('Todos'),
                            icon: Icon(Icons.grid_view),
                          ),
                          ButtonSegment(
                            value: 'escasos',
                            label: Text('Stock Bajo'),
                            icon: Icon(Icons.warning_outlined),
                          ),
                          ButtonSegment(
                            value: 'masVendidos',
                            label: Text('Más Vendidos'),
                            icon: Icon(Icons.trending_up),
                          ),
                          ButtonSegment(
                            value: 'menosVendidos',
                            label: Text('Menos Vendidos'),
                            icon: Icon(Icons.trending_down),
                          ),
                        ],
                        selected: {_selectedView},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _selectedView = newSelection.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Categorías en chips horizontales
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),

                // Grid de productos
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredProducts.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _buildAddProductCard();
                            }
                            final product = _filteredProducts[index - 1];
                            return _buildProductCard(product);
                          },
                        ),
                ),
              ],
            ),
          ),

          // Sidebar derecho - Locales
          Container(
            width: 250,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'Locales',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Tabs de Centrales/Sucursales
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'Todos',
                              label: Text('Todos'),
                            ),
                            ButtonSegment(
                              value: 'central',
                              label: Text('Centrales'),
                            ),
                            ButtonSegment(
                              value: 'sucursal',
                              label: Text('Sucursales'),
                            ),
                          ],
                          selected: {_selectedLocal},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              _selectedLocal = newSelection.first;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Lista de locales
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _branches.length,
                    itemBuilder: (context, index) {
                      final branch = _branches[index];
                      if (_selectedLocal != 'Todos' && branch.type != _selectedLocal) {
                        return const SizedBox.shrink();
                      }
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            branch.type == 'central'
                                ? Icons.store
                                : Icons.store_mall_directory,
                          ),
                          title: Text(branch.name),
                          subtitle: Text(branch.address),
                          selected: _selectedBranch?.id == branch.id,
                          onTap: () {
                            setState(() {
                              _selectedBranch = branch;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildAddProductCard() {
    return Card(
      child: InkWell(
        onTap: () => _showAddEditProductDialog(),
        child: const Center(
          child: Icon(Icons.add, size: 48),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      child: InkWell(
        onTap: () => _showAddEditProductDialog(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: product.imageUrl != null
                    ? Image.network(product.imageUrl)
                    : const Icon(Icons.image, size: 64),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Stock: ${product.stock}'),
                  Text(
                    'S/ ${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (product.hasDiscount)
                    Text(
                      'Descuento disponible',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 