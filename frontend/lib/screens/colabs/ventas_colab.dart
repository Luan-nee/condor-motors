import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../api/main.api.dart';
import '../../api/stocks.api.dart' as stocks_api;
import '../../api/ventas.api.dart' as ventas_api;
import '../../api/sucursales.api.dart';
import 'barcode_colab.dart';

class VentasColabScreen extends StatefulWidget {
  const VentasColabScreen({super.key});

  @override
  State<VentasColabScreen> createState() => _VentasColabScreenState();
}

class _VentasColabScreenState extends State<VentasColabScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  late final stocks_api.StocksApi _stockApi;
  late final ventas_api.VentasApi _ventasApi;
  late final SucursalesApi _sucursalesApi;
  final List<stocks_api.Producto> _scannedProducts = [];
  final TextEditingController _textSearchController = TextEditingController();
  final Map<stocks_api.Producto, int> _quantities = {};
  List<stocks_api.Stock> _stockProducts = [];
  bool _isLoading = false;
  String _selectedCategory = 'Todos';
  
  // TODO: Obtener estos valores del estado global de la aplicación
  final int _vendorId = 3;
  final int _sucursalId = 1;
  Sucursal? _currentBranch;
  bool _showTempList = false;

  // Datos de prueba para sucursales
  static final List<Sucursal> _sucursalesPrueba = [
    Sucursal.fromJson({
      'id': 1,
      'nombre': 'Sucursal Principal',
      'direccion': 'Av. Principal 123',
      'sucursalCentral': true,
      'activo': true,
    }),
    Sucursal.fromJson({
      'id': 2,
      'nombre': 'Sucursal Norte',
      'direccion': 'Calle Norte 456',
      'sucursalCentral': false,
      'activo': true,
    }),
  ];

  final List<String> _categories = [
    'Todos',
    'Lubricantes',    // ACE001, ACE002
    'Filtros',        // FIL001, FIL002
    'Frenos',         // PAS001, DIS001
    'Transmisión',    // CAD001, KIT001, EMB001
    'Eléctrico',      // BAT001, REG001
    'Encendido',      // BUJ001
  ];

  // Remover animaciones no utilizadas y mantener solo el controlador
  late AnimationController _animationController;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _stockApi = stocks_api.StocksApi(_apiService);
    _ventasApi = ventas_api.VentasApi(_apiService);
    _sucursalesApi = SucursalesApi(_apiService);
    _loadInitialData();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Intentar cargar datos de la sucursal actual
      try {
        _currentBranch = await _sucursalesApi.getSucursal(_sucursalId);
      } catch (e) {
        // Si falla, usar datos de prueba
        _currentBranch = _sucursalesPrueba.firstWhere(
          (s) => s.id == _sucursalId,
          orElse: () => _sucursalesPrueba.first,
        );
      }
      
      // Cargar stock del local
      final stocks = await _stockApi.getStocks(
        localId: _sucursalId,
        limit: 100,
      );
      
      if (!mounted) return;
      setState(() {
        _stockProducts = stocks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredProducts() {
    if (_selectedCategory == 'Todos') {
      return _stockProducts.map((stock) => stock.toJson()).toList();
    }
    return _stockProducts.where((stock) => 
      stock.producto?.categoria.toLowerCase() == _selectedCategory.toLowerCase()
    ).map((stock) => stock.toJson()).toList();
  }

  // Función para normalizar texto (remover tildes y convertir a minúsculas)
  String _normalizeText(String text) {
    return text.toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  Widget _buildBottomBar() {
    final total = _scannedProducts.fold<double>(
      0,
      (sum, product) => sum + (product.precio * (_quantities[product] ?? 1)),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'S/ ${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _scannedProducts.isEmpty
                ? null
                : () {
                    _enviarAComputer();
                  },
            icon: const FaIcon(FontAwesomeIcons.computer),
            label: const Text('Enviar a Computer'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Función para enviar productos a computer
  Future<void> _enviarAComputer() async {
    // TODO: Implementar la lógica para enviar productos a computer
    // Por ahora, mostraremos un diálogo de confirmación
    
    final total = _scannedProducts.fold<double>(
      0,
      (sum, product) => sum + (product.precio * (_quantities[product] ?? 1)),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar a Computer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Se enviarán los siguientes productos:'),
            const SizedBox(height: 16),
            ...List.generate(_scannedProducts.length, (index) {
              final producto = _scannedProducts[index];
              final cantidad = _quantities[producto] ?? 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        producto.nombre,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('$cantidad x S/ ${producto.precio.toStringAsFixed(2)}'),
                  ],
                ),
              );
            }),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'S/ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar la lógica para enviar a computer
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Productos enviados a Computer correctamente'),
                  backgroundColor: Colors.green,
                ),
              );
              // Limpiar la lista después de enviar
              setState(() {
                _scannedProducts.clear();
                _quantities.clear();
              });
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final producto = await Navigator.push<stocks_api.Producto>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeColabScreen(),
      ),
    );

    if (producto != null) {
      setState(() {
        if (!_scannedProducts.contains(producto)) {
          _scannedProducts.add(producto);
          _quantities[producto] = 1;
        } else {
          _quantities[producto] = (_quantities[producto] ?? 0) + 1;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas - Enviar a Computer'),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.house),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'Volver al selector',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _showTempList
                    ? _buildTempList()
                    : _buildProductList(),
          ),
          if (_scannedProducts.isNotEmpty) _buildBottomBar(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanBarcode,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          MdiIcons.barcodeScan,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Buscar Productos',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.arrowsRotate),
                onPressed: _loadInitialData,
                tooltip: 'Recargar datos',
              ),
              IconButton(
                icon: FaIcon(_showTempList ? FontAwesomeIcons.list : FontAwesomeIcons.cartShopping),
                onPressed: () {
                  setState(() {
                    _showTempList = !_showTempList;
                  });
                },
                tooltip: _showTempList ? 'Ver productos' : 'Ver carrito',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_showTempList) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textSearchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar producto...',
                      prefixIcon: const FaIcon(FontAwesomeIcons.magnifyingGlass),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductList() {
    final filteredProducts = _getFilteredProducts();
    final searchText = _textSearchController.text.trim();
    
    if (searchText.isNotEmpty) {
      final normalizedSearch = _normalizeText(searchText);
      filteredProducts.removeWhere((product) {
        final nombre = _normalizeText(product['producto']['nombre'] ?? '');
        final codigo = _normalizeText(product['producto']['codigo'] ?? '');
        return !nombre.contains(normalizedSearch) && !codigo.contains(normalizedSearch);
      });
    }

    if (filteredProducts.isEmpty) {
      return const Center(
        child: Text('No se encontraron productos'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        final producto = stocks_api.Producto.fromJson(product['producto']);
        final cantidad = product['cantidad'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              producto.nombre,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Código: ${producto.codigo}'),
                Text('Categoría: ${producto.categoria}'),
                Text('Stock: $cantidad'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'S/ ${producto.precio.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.cartPlus),
                  onPressed: () {
                    setState(() {
                      if (!_scannedProducts.contains(producto)) {
                        _scannedProducts.add(producto);
                        _quantities[producto] = 1;
                      } else {
                        _quantities[producto] = (_quantities[producto] ?? 0) + 1;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTempList() {
    if (_scannedProducts.isEmpty) {
      return const Center(
        child: Text('No hay productos en el carrito'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Productos seleccionados (${_scannedProducts.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _scannedProducts.clear();
                    _quantities.clear();
                  });
                },
                icon: const FaIcon(FontAwesomeIcons.trash),
                label: const Text('Limpiar'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _scannedProducts.length,
            itemBuilder: (context, index) {
              final producto = _scannedProducts[index];
              final cantidad = _quantities[producto] ?? 1;
              final subtotal = producto.precio * cantidad;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    producto.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Código: ${producto.codigo}'),
                      Text('Precio: S/ ${producto.precio.toStringAsFixed(2)}'),
                      Text('Subtotal: S/ ${subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.minus),
                        onPressed: () {
                          setState(() {
                            if (cantidad > 1) {
                              _quantities[producto] = cantidad - 1;
                            } else {
                              _scannedProducts.remove(producto);
                              _quantities.remove(producto);
                            }
                          });
                        },
                      ),
                      Text(
                        '$cantidad',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.plus),
                        onPressed: () {
                          setState(() {
                            _quantities[producto] = cantidad + 1;
                          });
                        },
                      ),
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.trashCan),
                        onPressed: () {
                          setState(() {
                            _scannedProducts.remove(producto);
                            _quantities.remove(producto);
                          });
                        },
                      ),
                    ],
                  ),
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
    _textSearchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
