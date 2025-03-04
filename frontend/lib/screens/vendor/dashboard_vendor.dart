import 'package:flutter/material.dart';
import '../../api/main.api.dart';
import '../../api/stocks.api.dart' as stocks_api;
import '../../api/ventas.api.dart' as ventas_api;
import '../../api/sucursales.api.dart';
import 'barcode_vendor.dart';

class DashboardVendorScreen extends StatefulWidget {
  const DashboardVendorScreen({super.key});

  @override
  State<DashboardVendorScreen> createState() => _DashboardVendorScreenState();
}

class _DashboardVendorScreenState extends State<DashboardVendorScreen> with SingleTickerProviderStateMixin {
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
                Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
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
            onPressed: _scannedProducts.isEmpty ? null : _sendToComputer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
            icon: const Icon(Icons.send),
            label: const Text('Enviar a Computadora'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _getFilteredProducts();
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Condors Motors',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            Text(
              'Ventas - ${_currentBranch?.nombre ?? 'Sucursal'}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.barcode_reader),
            onPressed: _scanBarcode,
            tooltip: 'Leer código de barras',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFFE31E24)),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final stock = filteredProducts[index];
                      final product = stock['producto'];
                      
                      if (_textSearchController.text.isNotEmpty) {
                        final searchNormalized = _normalizeText(_textSearchController.text);
                        final productNameNormalized = _normalizeText(product['nombre'].toString());
                        final productCodeNormalized = _normalizeText(product['codigo'].toString());
                        
                        if (!productNameNormalized.contains(searchNormalized) &&
                            !productCodeNormalized.contains(searchNormalized)) {
                          return const SizedBox.shrink();
                        }
                      }

                      return _buildProductCard(stocks_api.Stock.fromJson(stock));
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _scannedProducts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _showTempList = !_showTempList),
              backgroundColor: const Color(0xFFE31E24),
              elevation: 4,
              highlightElevation: 8,
              icon: Badge(
                label: Text(
                  _scannedProducts.length.toString(),
                  style: const TextStyle(
                    color: Color(0xFFE31E24),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                ),
              ),
              label: Text(
                _showTempList ? 'Ocultar' : 'Ver Carrito',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      bottomSheet: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _showTempList && _scannedProducts.isNotEmpty ? MediaQuery.of(context).size.height * 0.6 : 0,
        child: _showTempList && _scannedProducts.isNotEmpty
            ? Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Barra de arrastre
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header con altura fija
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shopping_cart,
                            color: Color(0xFFE31E24),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Productos Seleccionados (${_scannedProducts.length})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Lista de productos
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _scannedProducts.length,
                        itemBuilder: (context, index) {
                          final product = _scannedProducts[index];
                          final quantity = _quantities[product] ?? 1;
                          return Card(
                            color: const Color(0xFF3D3D3D),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                product.nombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Cantidad: $quantity - Total: S/ ${(product.precio * quantity).toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.white70,
                                ),
                                onPressed: () => _updateQuantity(product, 0),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de búsqueda con animación
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: _isSearchExpanded
                        ? const Icon(
                            Icons.close,
                            key: ValueKey('close'),
                            color: Color(0xFFE31E24),
                          )
                        : const Icon(
                            Icons.search,
                            key: ValueKey('search'),
                            color: Color(0xFFE31E24),
                          ),
                  ),
                  tooltip: _isSearchExpanded ? 'Cerrar búsqueda' : 'Buscar productos',
                  onPressed: _toggleSearch,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(-1, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: _isSearchExpanded
                        ? TextField(
                            key: const ValueKey('search_field'),
                            controller: _textSearchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Buscar productos...',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onChanged: (value) => setState(() {}),
                            autofocus: true,
                          )
                        : Row(
                            key: const ValueKey('category_text'),
                            children: [
                              Text(
                                _selectedCategory,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          // Categorías
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFFE31E24),
                    backgroundColor: const Color(0xFF3D3D3D),
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(stocks_api.Stock stock) {
    final producto = stock.producto;
    if (producto == null) return const SizedBox.shrink();

    final cantidad = stock.cantidad;
    final precio = producto.precio;
    final isLowStock = cantidad <= 10;
    final isInList = _scannedProducts.any((p) => p.id == producto.id);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          producto.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código: ${producto.codigo}'),
            Row(
              children: [
                Text(
                  'Stock: $cantidad unidades',
                  style: TextStyle(
                    color: isLowStock ? Theme.of(context).colorScheme.error : null,
                    fontWeight: isLowStock ? FontWeight.bold : null,
                  ),
                ),
                if (isLowStock)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.warning,
                      color: Theme.of(context).colorScheme.error,
                      size: 16,
                    ),
                  ),
              ],
            ),
            Text(
              'Precio: S/ ${precio.toStringAsFixed(2)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: isInList 
          ? Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _updateQuantity(
                      producto,
                      (_quantities[producto] ?? 0) - 1,
                    ),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Text(
                    '${_quantities[producto] ?? 0}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: cantidad > (_quantities[producto] ?? 0)
                      ? () => _updateQuantity(
                          producto,
                          (_quantities[producto] ?? 0) + 1,
                        )
                      : null,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            )
          : ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Agregar'),
              onPressed: cantidad > 0 
                ? () => _addProduct(producto)
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
        isThreeLine: true,
      ),
    );
  }

  Future<void> _addProduct(stocks_api.Producto producto) async {
    try {
      final isAvailable = await _verificarStock(producto, 1);

      if (isAvailable) {
        setState(() {
          if (!_scannedProducts.contains(producto)) {
            _scannedProducts.add(producto);
            _quantities[producto] = 1;
          }
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto sin stock disponible'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al verificar stock: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateQuantity(stocks_api.Producto producto, int quantity) {
    setState(() {
      if (quantity > 0) {
        _quantities[producto] = quantity;
      } else {
        _quantities.remove(producto);
        _scannedProducts.remove(producto);
      }
    });
  }

  Future<void> _sendToComputer() async {
    if (_scannedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay productos en la lista'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final ventaData = {
        'vendedor_id': _vendorId,
        'local_id': _sucursalId,
        'estado': ventas_api.VentasApi.estados['PENDIENTE'],
        'observaciones': 'Cliente espera en tienda',
        'detalles': _scannedProducts.map((p) => {
          'producto_id': p.id,
          'cantidad': _quantities[p] ?? 1,
          'precio_unitario': p.precio,
        }).toList(),
      };

      await _ventasApi.createVenta(ventaData);
      
      setState(() {
        _scannedProducts.clear();
        _quantities.clear();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venta enviada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar venta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _scanBarcode() async {
    final stocks_api.Producto? scannedProduct = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeVendorScreen(),
      ),
    );

    if (scannedProduct != null && mounted) {
      setState(() {
        if (!_scannedProducts.contains(scannedProduct)) {
          _scannedProducts.add(scannedProduct);
          _quantities[scannedProduct] = 1;
        }
      });
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Color(0xFFE31E24)),
            SizedBox(width: 8),
            Text('Cerrar Sesión'),
          ],
        ),
        content: const Text('¿Está seguro que desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31E24),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (_isSearchExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _textSearchController.clear();
      }
    });
  }

  Future<bool> _verificarStock(stocks_api.Producto producto, int cantidad) async {
    try {
      return await _stockApi.checkStockAvailability(
        localId: _sucursalId,
        productoId: producto.id,
        cantidad: cantidad,
      );
    } catch (e) {
      debugPrint('Error al verificar stock: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _textSearchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
