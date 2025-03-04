import 'package:flutter/material.dart';
import '../../api/stocks.api.dart';
import '../../api/main.api.dart';

class InventarioColabScreen extends StatefulWidget {
  const InventarioColabScreen({super.key});

  @override
  State<InventarioColabScreen> createState() => _InventarioColabScreenState();
}

class _InventarioColabScreenState extends State<InventarioColabScreen> {
  final _apiService = ApiService();
  late final StocksApi _stockApi;
  bool _isLoading = false;
  List<Stock> _stocks = [];
  String _selectedCategory = 'Todos';
  final TextEditingController _searchController = TextEditingController();

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
    _initializeServices();
    _cargarInventario();
  }

  void _initializeServices() {
    _stockApi = StocksApi(_apiService);
  }

  Future<void> _cargarInventario() async {
    setState(() => _isLoading = true);
    try {
      final stocks = await _stockApi.getStocks(
        localId: 1, // TODO: Obtener del estado global
      );
      
      if (!mounted) return;
      setState(() {
        _stocks = stocks;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar inventario: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Stock> get stocksFiltrados {
    return _stocks.where((stock) {
      final producto = stock.producto;
      if (producto == null) return false;

      final matchesCategoria = _selectedCategory == 'Todos' || 
                            producto.categoria == _selectedCategory;
      final searchText = _searchController.text.toLowerCase();
      final matchesBusqueda = producto.nombre.toLowerCase().contains(searchText) ||
                           producto.codigo.toLowerCase().contains(searchText);
      return matchesCategoria && matchesBusqueda;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Buscador
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            onChanged: (value) => setState(() {}),
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
                      setState(() => _selectedCategory = category);
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
                  itemCount: stocksFiltrados.length,
                  itemBuilder: (context, index) {
                    final stock = stocksFiltrados[index];
                    final producto = stock.producto;
                    if (producto == null) return const SizedBox.shrink();

                    final isLowStock = stock.cantidad < 10;

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.inventory),
                        title: Text(producto.nombre),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Código: ${producto.codigo}'),
                            Row(
                              children: [
                                Text(
                                  'Stock: ${stock.cantidad} unidades',
                                  style: TextStyle(
                                    color: isLowStock ? Colors.red : null,
                                    fontWeight: isLowStock ? FontWeight.bold : null,
                                  ),
                                ),
                                if (isLowStock)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Icon(
                                      Icons.warning,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                            Text('Precio: S/ ${producto.precio.toStringAsFixed(2)}'),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
