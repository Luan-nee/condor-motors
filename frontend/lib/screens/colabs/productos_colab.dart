import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:condorsmotors/screens/colabs/selector_colab.dart';
import 'package:condorsmotors/utils/busqueda_producto_utils.dart';
import 'package:condorsmotors/utils/stock_utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductosColabScreen extends StatefulWidget {
  const ProductosColabScreen({super.key});

  @override
  State<ProductosColabScreen> createState() => _ProductosColabScreenState();
}

class _ProductosColabScreenState extends State<ProductosColabScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  String _selectedBrand = 'Todas';
  String _selectedPromotion = 'Todas';
  bool _isLoading = true;
  String? _error;

  // Lista de productos
  List<Producto> _productos = <Producto>[];

  // Información de paginación
  late Paginacion _paginacion;

  // Categorías disponibles (se cargarán desde la API)
  List<String> _categorias = <String>['Todos'];

  // Marcas disponibles (se cargarán desde la API)
  List<String> _marcas = <String>['Todas'];

  // Promociones disponibles (se cargarán desde la API)
  final List<String> _promociones = <String>[
    'Todas',
    'Liquidación',
    'Descuento',
    'Promo Gratis'
  ];

  // Tamaño de página para la paginación
  static const int _pageSize = 20;

  // Repositorio de productos
  final ProductoRepository _productoRepository = ProductoRepository.instance;

  // Estados para filtros desplegables
  bool _isCategoriaExpanded = false;
  bool _isMarcaExpanded = false;
  bool _isPromocionExpanded = false;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  /// Carga los datos iniciales (productos y categorías)
  Future<void> _cargarDatos() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Obtener el ID de la sucursal del usuario actual
      final String? sucursalId =
          await _productoRepository.getCurrentSucursalId();

      if (sucursalId == null || sucursalId.isEmpty) {
        throw Exception('No se pudo determinar la sucursal del usuario');
      }

      // Cargar productos con su información usando el repositorio
      final response = await _productoRepository.getProductos(
        sucursalId: sucursalId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        filter: _selectedCategory != 'Todos' ? 'categoria' : null,
        filterValue: _selectedCategory != 'Todos' ? _selectedCategory : null,
        pageSize: _pageSize,
        sortBy: 'nombre',
        order: 'asc',
      );

      // Extraer categorías únicas y normalizadas usando BusquedaProductoUtils
      final List<Map<String, dynamic>> productosMap = response.items
          .map((p) => {
                'categoria': p.categoria,
                'marca': p.marca,
              })
          .toList();
      final List<String> categoriasProcesadas =
          BusquedaProductoUtils.extraerCategorias(productosMap);
      // Extraer marcas únicas y normalizadas
      final Set<String> marcasSet = response.items
          .map((p) => (p.marca).trim())
          .where((m) => m.isNotEmpty)
          .toSet();
      final List<String> marcasProcesadas = <String>[
        'Todas',
        ...marcasSet.toList()..sort()
      ];

      if (!mounted) {
        return;
      }

      setState(() {
        _productos = response.items;
        _paginacion = response.paginacion;
        _categorias = categoriasProcesadas;
        _marcas = marcasProcesadas;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      final String errorStr = e.toString().toLowerCase();
      final bool isAuthError =
          errorStr.contains('401') || errorStr.contains('authorization');
      final bool isRefreshFailed = errorStr.contains('refresh failed') ||
          errorStr.contains('invalid_grant') ||
          errorStr.contains('refresh_token');

      // Solo mostrar el mensaje si el refresh también falló
      if (isAuthError && !isRefreshFailed) {
        // No mostrar nada, el refresh token se encargará
        return;
      }

      // Si el refresh también falló, mostrar el mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Error de autorización. Por favor, inicia sesión de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Carga la siguiente página de productos
  Future<void> _cargarMasProductos() async {
    if (!_paginacion.hasNext) {
      return;
    }

    try {
      final String? sucursalId =
          await _productoRepository.getCurrentSucursalId();

      if (sucursalId == null || sucursalId.isEmpty) {
        throw Exception('No se pudo determinar la sucursal del usuario');
      }

      final response = await _productoRepository.getProductos(
        sucursalId: sucursalId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        filter: _selectedCategory != 'Todos' ? 'categoria' : null,
        filterValue: _selectedCategory != 'Todos' ? _selectedCategory : null,
        page: _paginacion.currentPage + 1,
        pageSize: _pageSize,
        sortBy: 'nombre',
        order: 'asc',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _productos.addAll(response.items);
        _paginacion = response.paginacion;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      final String errorStr = e.toString().toLowerCase();
      final bool isAuthError =
          errorStr.contains('401') || errorStr.contains('authorization');
      final bool isRefreshFailed = errorStr.contains('refresh failed') ||
          errorStr.contains('invalid_grant') ||
          errorStr.contains('refresh_token');

      // Solo mostrar el mensaje si el refresh también falló
      if (isAuthError && !isRefreshFailed) {
        // No mostrar nada, el refresh token se encargará
        return;
      }

      // Si el refresh también falló, mostrar el mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Error de autorización. Por favor, inicia sesión de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // NUEVO: Filtrado avanzado combinando todos los filtros
  List<Producto> _getProductosFiltrados() {
    return _productos.where((producto) {
      final bool coincideCategoria = _selectedCategory == 'Todos' ||
          (producto.categoria).trim().toLowerCase() ==
              _selectedCategory.toLowerCase();
      final bool coincideMarca = _selectedBrand == 'Todas' ||
          (producto.marca).trim().toLowerCase() == _selectedBrand.toLowerCase();
      final bool coincideTexto = _searchQuery.isEmpty ||
          producto.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          producto.sku.toLowerCase().contains(_searchQuery.toLowerCase());
      bool coincidePromocion = true;
      if (_selectedPromotion != 'Todas') {
        if (_selectedPromotion == 'Liquidación') {
          coincidePromocion = producto.liquidacion == true;
        } else if (_selectedPromotion == 'Descuento') {
          coincidePromocion = (producto.porcentajeDescuento ?? 0) > 0;
        } else if (_selectedPromotion == 'Promo Gratis') {
          coincidePromocion = (producto.cantidadGratisDescuento ?? 0) > 0;
        }
      }
      return coincideCategoria &&
          coincideMarca &&
          coincideTexto &&
          coincidePromocion;
    }).toList();
  }

  Color _getEstadoColor(StockStatus estado) {
    switch (estado) {
      case StockStatus.disponible:
        return Colors.green;
      case StockStatus.stockBajo:
        return Colors.orange;
      case StockStatus.agotado:
        return Colors.red;
    }
  }

  String _getEstadoText(StockStatus estado) {
    switch (estado) {
      case StockStatus.disponible:
        return 'Disponible';
      case StockStatus.stockBajo:
        return 'Stock Bajo';
      case StockStatus.agotado:
        return 'Agotado';
    }
  }

  // Métodos para alternar filtros desplegables
  void _toggleCategoria() {
    setState(() {
      _isCategoriaExpanded = !_isCategoriaExpanded;
      if (_isCategoriaExpanded) {
        _isMarcaExpanded = false;
        _isPromocionExpanded = false;
        _isSearchExpanded = false;
      }
    });
  }

  void _toggleMarca() {
    setState(() {
      _isMarcaExpanded = !_isMarcaExpanded;
      if (_isMarcaExpanded) {
        _isCategoriaExpanded = false;
        _isPromocionExpanded = false;
        _isSearchExpanded = false;
      }
    });
  }

  void _togglePromocion() {
    setState(() {
      _isPromocionExpanded = !_isPromocionExpanded;
      if (_isPromocionExpanded) {
        _isCategoriaExpanded = false;
        _isMarcaExpanded = false;
        _isSearchExpanded = false;
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (_isSearchExpanded) {
        _isCategoriaExpanded = false;
        _isMarcaExpanded = false;
        _isPromocionExpanded = false;
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'Todos';
      _selectedBrand = 'Todas';
      _selectedPromotion = 'Todas';
      _isCategoriaExpanded = false;
      _isMarcaExpanded = false;
      _isPromocionExpanded = false;
      _isSearchExpanded = false;
    });
    _cargarDatos();
  }

  // NUEVO: Barra de filtros móvil compacta y desplegable
  Widget _buildCompactFilterBar() {
    final bool hayFiltrosActivos = _selectedCategory != 'Todos' ||
        _selectedBrand != 'Todas' ||
        _selectedPromotion != 'Todas' ||
        _searchQuery.isNotEmpty;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double iconSize =
        screenWidth < 400 ? 22 : (screenWidth < 700 ? 26 : 32);
    final double chipFontSize =
        screenWidth < 400 ? 10 : (screenWidth < 700 ? 12 : 14);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            _buildFilterButton(
              icon: Icons.category,
              color: _isCategoriaExpanded || _selectedCategory != 'Todos'
                  ? Colors.blue
                  : Colors.white70,
              active: _isCategoriaExpanded || _selectedCategory != 'Todos',
              onTap: _toggleCategoria,
              selectedLabel: _selectedCategory,
              iconSize: iconSize,
              chipFontSize: chipFontSize,
            ),
            _buildFilterButton(
              icon: Icons.local_offer,
              color: _isMarcaExpanded || _selectedBrand != 'Todas'
                  ? Colors.green
                  : Colors.white70,
              active: _isMarcaExpanded || _selectedBrand != 'Todas',
              onTap: _toggleMarca,
              selectedLabel: _selectedBrand,
              iconSize: iconSize,
              chipFontSize: chipFontSize,
            ),
            _buildFilterButton(
              icon: Icons.percent,
              color: _isPromocionExpanded || _selectedPromotion != 'Todas'
                  ? Colors.purple
                  : Colors.white70,
              active: _isPromocionExpanded || _selectedPromotion != 'Todas',
              onTap: _togglePromocion,
              selectedLabel: _selectedPromotion,
              iconSize: iconSize,
              chipFontSize: chipFontSize,
            ),
            _buildFilterButton(
              icon: Icons.search,
              color: _isSearchExpanded || _searchQuery.isNotEmpty
                  ? Colors.orange
                  : Colors.white70,
              active: _isSearchExpanded || _searchQuery.isNotEmpty,
              onTap: _toggleSearch,
              selectedLabel: _searchQuery.isNotEmpty ? _searchQuery : null,
              iconSize: iconSize,
              chipFontSize: chipFontSize,
            ),
            _buildFilterButton(
              icon: Icons.filter_list_off,
              color: hayFiltrosActivos ? Colors.red : Colors.white38,
              active: hayFiltrosActivos,
              onTap: hayFiltrosActivos ? _clearAllFilters : null,
              iconSize: iconSize,
              chipFontSize: chipFontSize,
            ),
          ],
        ),
        if (_isCategoriaExpanded) _buildCategoriaDropdown(),
        if (_isMarcaExpanded) _buildMarcaDropdown(),
        if (_isPromocionExpanded) _buildPromocionDropdown(),
        if (_isSearchExpanded) _buildSearchField(),
        if (hayFiltrosActivos)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              children: <Widget>[
                if (_selectedCategory != 'Todos')
                  _buildActiveFilter(
                    icon: Icons.category,
                    label: 'Categoría: $_selectedCategory',
                    color: Colors.blue,
                    onClear: () {
                      setState(() {
                        _selectedCategory = 'Todos';
                      });
                      _cargarDatos();
                    },
                  ),
                if (_selectedBrand != 'Todas')
                  _buildActiveFilter(
                    icon: Icons.local_offer,
                    label: 'Marca: $_selectedBrand',
                    color: Colors.green,
                    onClear: () {
                      setState(() {
                        _selectedBrand = 'Todas';
                      });
                      _cargarDatos();
                    },
                  ),
                if (_selectedPromotion != 'Todas')
                  _buildActiveFilter(
                    icon: Icons.percent,
                    label: 'Promo: $_selectedPromotion',
                    color: Colors.purple,
                    onClear: () {
                      setState(() {
                        _selectedPromotion = 'Todas';
                      });
                      _cargarDatos();
                    },
                  ),
                if (_searchQuery.isNotEmpty)
                  _buildActiveFilter(
                    icon: Icons.search,
                    label: 'Búsqueda: "$_searchQuery"',
                    color: Colors.orange,
                    onClear: () {
                      setState(() {
                        _searchQuery = '';
                      });
                      _cargarDatos();
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required Color color,
    required bool active,
    required VoidCallback? onTap,
    String? selectedLabel,
    double? iconSize,
    double? chipFontSize,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(icon, color: color, size: iconSize ?? 24),
            onPressed: onTap,
            tooltip: selectedLabel ?? '',
          ),
          if (selectedLabel != null &&
              selectedLabel != 'Todos' &&
              selectedLabel != 'Todas')
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(
                label: Text(
                  selectedLabel,
                  style: TextStyle(fontSize: chipFontSize ?? 12, color: color),
                ),
                backgroundColor: color.withValues(alpha: 0.15),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriaDropdown() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          items: _categorias.map((String categoria) {
            final int count = categoria == 'Todos'
                ? _productos.length
                : _productos
                    .where((p) =>
                        (p.categoria).trim().toLowerCase() ==
                        categoria.toLowerCase())
                    .length;
            return DropdownMenuItem<String>(
              value: categoria,
              child: Row(
                children: [
                  Text(categoria),
                  if (count > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCategory = newValue;
                _isCategoriaExpanded = false;
              });
              _cargarDatos();
            }
          },
        ),
      ),
    );
  }

  Widget _buildMarcaDropdown() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBrand,
          isExpanded: true,
          items: _marcas.map((String marca) {
            final int count = marca == 'Todas'
                ? _productos.length
                : _productos
                    .where((p) =>
                        (p.marca).trim().toLowerCase() == marca.toLowerCase())
                    .length;
            return DropdownMenuItem<String>(
              value: marca,
              child: Row(
                children: [
                  Text(marca),
                  if (count > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedBrand = newValue;
                _isMarcaExpanded = false;
              });
              _cargarDatos();
            }
          },
        ),
      ),
    );
  }

  Widget _buildPromocionDropdown() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPromotion,
          isExpanded: true,
          items: _promociones.map((String promo) {
            final int count = promo == 'Todas'
                ? _productos.length
                : _productos.where((p) {
                    if (promo == 'Liquidación') {
                      return p.liquidacion == true;
                    }
                    if (promo == 'Descuento') {
                      return (p.porcentajeDescuento ?? 0) > 0;
                    }
                    if (promo == 'Promo Gratis') {
                      return (p.cantidadGratisDescuento ?? 0) > 0;
                    }
                    return true;
                  }).length;
            return DropdownMenuItem<String>(
              value: promo,
              child: Row(
                children: [
                  Text(promo),
                  if (count > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.purple,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedPromotion = newValue;
                _isPromocionExpanded = false;
              });
              _cargarDatos();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Buscar por código, nombre o marca...',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (String value) {
          setState(() {
            _searchQuery = value;
          });
          _cargarDatos();
        },
      ),
    );
  }

  // NUEVO: Cálculo de cuánto falta para stock mínimo
  String _getStockFaltanteText(Producto producto) {
    if (producto.stockMinimo != null &&
        producto.stock < producto.stockMinimo!) {
      final int faltan = producto.stockMinimo! - producto.stock;
      return 'Faltan $faltan para stock mínimo';
    }
    return '';
  }

  // NUEVO: Progreso de stock para barra de progreso
  double _getStockProgress(Producto producto) {
    if (producto.stockMinimo == null || producto.stockMinimo == 0) {
      return 1.0;
    }
    final progress = producto.stock / producto.stockMinimo!;
    return progress.clamp(0.0, 1.0);
  }

  Color _getStockProgressColor(Producto producto) {
    if (producto.stock == 0) {
      return Colors.red;
    }
    if (producto.stockMinimo != null &&
        producto.stock < producto.stockMinimo!) {
      return Colors.orange;
    }
    return Colors.green;
  }

  Widget _buildActiveFilter({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onClear,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(width: 4),
          InkWell(
            onTap: onClear,
            child: const Icon(Icons.close, size: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar la imagen del producto
  Widget _buildProductoImagen(Producto producto, {double size = 56}) {
    final String? url = ProductoRepository.getProductoImageUrl(producto);
    if (url == null || url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            const Icon(Icons.image_not_supported, color: Colors.grey, size: 32),
      );
    }
    return GestureDetector(
      onTap: () {
        // TODO: Mostrar imagen ampliada en un dialog
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: size,
            height: size,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey, size: 32),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }
            return Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(strokeWidth: 2),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Producto> productosFiltrados = _getProductosFiltrados();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(
            FontAwesomeIcons.arrowLeft,
            size: 20,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) =>
                      const SelectorColabScreen()),
            );
          },
          tooltip: 'Volver al Selector',
        ),
        title: const Row(
          children: <Widget>[
            FaIcon(
              FontAwesomeIcons.box,
              size: 20,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Text(
              'Productos',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Recargar datos',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildCompactFilterBar(),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar los productos:\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _cargarDatos,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.maxScrollExtent) {
                    _cargarMasProductos();
                  }
                  return true;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: productosFiltrados.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Producto producto = productosFiltrados[index];
                    final StockStatus estado = StockUtils.getStockStatus(
                      producto.stock,
                      producto.stockMinimo ?? 0,
                    );
                    final String stockFaltante =
                        _getStockFaltanteText(producto);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: <Widget>[
                                _buildProductoImagen(producto, size: 48),
                                const SizedBox(width: 12),
                                Text(
                                  producto.sku,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    producto.nombre,
                                    style: producto.liquidacion
                                        ? const TextStyle(
                                            color: Colors.amber,
                                            fontWeight: FontWeight.bold)
                                        : null,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Barra de progreso central
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: _getStockProgress(producto),
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        _getStockProgressColor(producto)),
                                    minHeight: 12,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Stock: ${producto.stock} / ${producto.stockMinimo ?? "-"}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _getStockProgressColor(producto),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    producto.categoria,
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    producto.marca,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (stockFaltante.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  stockFaltante,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            if (producto.liquidacion &&
                                producto.precioOferta != null)
                              Text(
                                'S/ ${producto.precioVenta.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            Text(
                              'S/ ${(producto.liquidacion && producto.precioOferta != null ? producto.precioOferta! : producto.precioVenta).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color:
                                    producto.liquidacion ? Colors.amber : null,
                              ),
                            ),
                            Text(
                              'Stock: ${producto.stock}',
                              style: TextStyle(
                                color: _getEstadoColor(estado),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'Detalles del Producto',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(producto.descripcion ??
                                      'Sin descripción'),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          if (producto.liquidacion &&
                                              producto.precioOferta !=
                                                  null) ...<Widget>[
                                            Text(
                                              'Precio Normal: S/ ${producto.precioVenta.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              'Precio Liquidación: S/ ${producto.precioOferta!.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.amber,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ] else
                                            Text(
                                              'Precio Normal: S/ ${producto.precioVenta.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          Text(
                                            'Precio Compra: S/ ${producto.precioCompra.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: <Widget>[
                                          Text(
                                            'Stock Actual: ${producto.stock}',
                                            style: TextStyle(
                                              color: _getEstadoColor(estado),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Stock Mínimo: ${producto.stockMinimo ?? 0}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Estado: ${_getEstadoText(estado)}',
                                            style: TextStyle(
                                              color: _getEstadoColor(estado),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (stockFaltante.isNotEmpty)
                                            Text(
                                              stockFaltante,
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (producto.cantidadGratisDescuento !=
                                          null ||
                                      producto.porcentajeDescuento != null)
                                    Container(
                                      margin: const EdgeInsets.only(top: 16),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blue.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          const Text(
                                            'Promociones Activas:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (producto
                                                  .cantidadGratisDescuento !=
                                              null)
                                            Text(
                                              '• Lleva ${producto.cantidadMinimaDescuento}, paga ${producto.cantidadMinimaDescuento! - producto.cantidadGratisDescuento!}',
                                              style: const TextStyle(
                                                  color: Colors.blue),
                                            ),
                                          if (producto.porcentajeDescuento !=
                                              null)
                                            Text(
                                              '• ${producto.porcentajeDescuento}% de descuento por ${producto.cantidadMinimaDescuento}+ unidades',
                                              style: const TextStyle(
                                                  color: Colors.blue),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
