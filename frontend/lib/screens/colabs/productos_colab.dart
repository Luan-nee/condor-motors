import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:condorsmotors/screens/colabs/selector_colab.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/utils/busqueda_producto_utils.dart';
import 'package:condorsmotors/utils/stock_utils.dart';
import 'package:condorsmotors/widgets/paginador.dart';
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

  // Sistema de paginación optimizado
  final Map<int, List<Producto>> _productosCache = <int, List<Producto>>{};
  final Map<int, Paginacion> _paginacionCache = <int, Paginacion>{};
  List<Producto> _productos = <Producto>[];
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
  int _pageSize = 20;

  // Repositorio de productos
  final ProductoRepository _productoRepository = ProductoRepository.instance;

  // Variables para ordenación (orden predeterminado por nombre)
  final String _sortBy = 'nombre';
  final String _order = 'asc';

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

  /// Verifica si necesita recargar la página (filtros o parámetros cambiaron)
  bool _necesitaRecargar(int page, int pageSize, String sortBy, String order) {
    // Si cambió el tamaño de página, ordenación o filtros, recargar
    return _pageSize != pageSize ||
        _sortBy != sortBy ||
        _order != order ||
        _searchQuery.isNotEmpty ||
        _selectedCategory != 'Todos' ||
        _selectedBrand != 'Todas' ||
        _selectedPromotion != 'Todas';
  }

  /// Carga datos desde el caché
  void _cargarDesdeCache(int page) {
    if (_productosCache.containsKey(page) &&
        _paginacionCache.containsKey(page)) {
      setState(() {
        _productos = _productosCache[page]!;
        _paginacion = _paginacionCache[page]!;
        _isLoading = false;
      });
    }
  }

  /// Limpia el caché cuando cambian los filtros
  void _limpiarCache() {
    _productosCache.clear();
    _paginacionCache.clear();
  }

  /// Recarga los datos limpiando la caché y forzando refresh
  Future<void> _recargarDatos() async {
    // Limpiar caché local
    _limpiarCache();

    // Limpiar caché del repositorio
    _productoRepository.invalidateCache();

    // Recargar datos forzando refresh
    await _cargarDatos(forceRefresh: true);
  }

  /// Carga los datos iniciales (productos y categorías)
  Future<void> _cargarDatos(
      {int? page,
      int? pageSize,
      String? sortBy,
      String? order,
      bool forceRefresh = false}) async {
    if (!mounted) {
      return;
    }

    final int targetPage = page ?? 1;
    final int targetPageSize = pageSize ?? _pageSize;
    final String targetSortBy = sortBy ?? _sortBy;
    final String targetOrder = order ?? _order;

    // Verificar si ya tenemos la página en caché (solo si no se fuerza refresh)
    if (!forceRefresh &&
        _productosCache.containsKey(targetPage) &&
        _paginacionCache.containsKey(targetPage) &&
        !_necesitaRecargar(
            targetPage, targetPageSize, targetSortBy, targetOrder)) {
      _cargarDesdeCache(targetPage);
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
        page: page ?? 1,
        pageSize: pageSize ?? _pageSize,
        sortBy: sortBy ?? _sortBy,
        order: order ?? _order,
        forceRefresh: forceRefresh, // ← Pasar el parámetro forceRefresh
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
          .map((p) => p.marca.trim())
          .where((m) => m.isNotEmpty)
          .toSet();
      final List<String> marcasProcesadas = <String>[
        'Todas',
        ...marcasSet.toList()..sort()
      ];

      if (!mounted) {
        return;
      }

      // Guardar en caché
      _productosCache[targetPage] = response.items;
      _paginacionCache[targetPage] = response.paginacion;

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

  // NUEVO: Filtrado avanzado combinando todos los filtros
  List<Producto> _getProductosFiltrados() {
    return _productos.where((producto) {
      final bool coincideCategoria = _selectedCategory == 'Todos' ||
          producto.categoria.trim().toLowerCase() ==
              _selectedCategory.toLowerCase();
      final bool coincideMarca = _selectedBrand == 'Todas' ||
          producto.marca.trim().toLowerCase() == _selectedBrand.toLowerCase();
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
    _limpiarCache(); // Limpiar caché antes de recargar
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
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.2) : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(
          color: active ? color : Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: active ? AppTheme.commonShadows : null,
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
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                ),
                child: Text(
                  selectedLabel,
                  style: TextStyle(
                    fontSize: chipFontSize ?? 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        boxShadow: AppTheme.commonShadows,
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
                        p.categoria.trim().toLowerCase() ==
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
                        p.marca.trim().toLowerCase() == marca.toLowerCase())
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
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        boxShadow: AppTheme.commonShadows,
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar por código, nombre o marca...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          prefixIcon: const Icon(Icons.search, color: Colors.orange),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildActiveFilter({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onClear,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: AppTheme.commonShadows,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.close,
                size: 12,
                color: color,
              ),
            ),
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
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_not_supported,
              color: Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              'Sin imagen',
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.7),
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: () {
        _mostrarImagenAmpliada(context, producto);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        child: _buildOptimizedImage(
          url: url,
          size: size,
        ),
      ),
    );
  }

  /// Widget optimizado para cargar imágenes sin gestión de estados innecesaria
  Widget _buildOptimizedImage({required String url, required double size}) {
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      // Optimizaciones de rendimiento
      cacheWidth: (size * MediaQuery.of(context).devicePixelRatio).round(),
      cacheHeight: (size * MediaQuery.of(context).devicePixelRatio).round(),
      // Animación suave
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, color: Colors.grey, size: 24),
            const SizedBox(height: 2),
            Text(
              'Error',
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.7),
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
                value: null, // Indeterminado
              ),
              const SizedBox(height: 4),
              Text(
                'Cargando...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Producto> productosFiltrados = _getProductosFiltrados();
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
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
        title: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.smallRadius),
              ),
              child: const FaIcon(
                FontAwesomeIcons.box,
                size: 20,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Productos',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle, // ← Forma circular
              // Sin sombra para evitar el color fuerte
            ),
            child: IconButton(
              icon: const Icon(
                Icons.refresh,
                color: AppTheme.primaryColor,
              ),
              onPressed: _recargarDatos,
              tooltip: 'Recargar datos',
              // Eliminar efectos de click cuadrados
              style: IconButton.styleFrom(
                shape: const CircleBorder(), // ← Hover circular
                splashFactory: NoSplash.splashFactory, // ← Sin splash
                highlightColor: Colors.transparent, // ← Sin highlight
                hoverColor: Colors.transparent, // ← Sin hover
              ),
            ),
          ),
        ],
      ),
      body: Column(children: <Widget>[
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
            child: Column(
              children: [
                // Lista de productos
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: productosFiltrados.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Producto producto = productosFiltrados[index];
                      final StockStatus estado = StockUtils.getStockStatus(
                        producto.stock,
                        producto.stockMinimo ?? 0,
                      );
                      return RepaintBoundary(
                        key: ValueKey('producto_colab_${producto.id}'),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius:
                                BorderRadius.circular(AppTheme.mediumRadius),
                            border: Border.all(
                              color: Colors.transparent, // Sin borde visible
                              width: 0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              dividerColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.only(
                                left:
                                    24.0, // Aumentado para separar imagen del texto
                                right: 16.0,
                                top: 8.0,
                                bottom: 8.0,
                              ),
                              // Eliminar iluminación blanca al hacer click
                              collapsedShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.mediumRadius),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.mediumRadius),
                              ),
                              // Eliminar splash color y highlight color
                              // splashColor, highlightColor y hoverColor se manejan en el Theme
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      _buildProductoImagen(producto, size: 48),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              producto.nombre,
                                              style: producto.liquidacion
                                                  ? const TextStyle(
                                                      color: Colors.amber,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    )
                                                  : const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              producto.sku,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                      height:
                                          12), // Espaciado vertical entre imagen y categoría
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
                                          color: Colors.blue
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.blue
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Text(
                                          producto.categoria,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
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
                                  // Stock en formato actual/óptimo
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Stock: ${producto.stock}/${producto.stockMinimo ?? producto.stock}',
                                      style: TextStyle(
                                        color: _getEstadoColor(estado),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: SizedBox(
                                width: 90,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    if (producto.liquidacion &&
                                        producto.precioOferta != null)
                                      Text(
                                        'S/ ${producto.precioVenta.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.grey,
                                          fontSize: 9,
                                        ),
                                      ),
                                    Text(
                                      'S/ ${(producto.liquidacion && producto.precioOferta != null ? producto.precioOferta! : producto.precioVenta).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: producto.liquidacion
                                            ? Colors.amber
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(producto.descripcion ??
                                            'Sin descripción'),
                                        if (producto.cantidadGratisDescuento !=
                                                null ||
                                            producto.porcentajeDescuento !=
                                                null)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 16),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.blue
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.blue
                                                    .withValues(alpha: 0.3),
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
                                                if (producto
                                                        .porcentajeDescuento !=
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
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Controles de paginación usando el widget Paginador (sin ordenación)
                if (_paginacion.totalPages > 1)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Paginador(
                      paginacion: _paginacion,
                      onPageChanged: _cambiarPagina,
                      onPageSizeChanged: (int newPageSize) {
                        _cambiarTamanioPagina(newPageSize);
                      },
                      // Sin controles de ordenación - orden predeterminado por nombre
                      // Configuración específica para colaboradores
                      backgroundColor: AppTheme.appBarColor,
                      accentColor: AppTheme.primaryColor,
                      textColor: Colors.white,
                      forceCompactMode: MediaQuery.of(context).size.width < 600,
                    ),
                  ),
              ],
            ),
          ),
      ]),
    );
  }

  /// Muestra la imagen del producto en un dialog ampliado
  void _mostrarImagenAmpliada(BuildContext context, Producto producto) {
    final String? url = ProductoRepository.getProductoImageUrl(producto);
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay imagen disponible para este producto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Imagen ampliada
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 300,
                      height: 300,
                      color: Colors.grey[200],
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image,
                              color: Colors.grey, size: 64),
                          SizedBox(height: 16),
                          Text('Error al cargar la imagen'),
                        ],
                      ),
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) {
                        return child;
                      }
                      return Container(
                        width: 300,
                        height: 300,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Botón de cerrar
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    shape: const CircleBorder(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Cambia a una página específica
  Future<void> _cambiarPagina(int pagina) async {
    if (pagina < 1 || pagina > _paginacion.totalPages) {
      return;
    }

    await _cargarDatos(page: pagina);

    // Precargar páginas adyacentes para mejor UX
    _precargarPaginasAdyacentes(pagina);
  }

  /// Precarga páginas adyacentes para navegación fluida
  void _precargarPaginasAdyacentes(int paginaActual) {
    final int totalPages = _paginacion.totalPages;

    // Precargar página anterior si existe
    if (paginaActual > 1) {
      _precargarPagina(paginaActual - 1);
    }

    // Precargar página siguiente si existe
    if (paginaActual < totalPages) {
      _precargarPagina(paginaActual + 1);
    }
  }

  /// Precarga una página específica en segundo plano
  Future<void> _precargarPagina(int pagina) async {
    // Solo precargar si no está en caché
    if (_productosCache.containsKey(pagina)) {
      return;
    }

    try {
      final String? sucursalId =
          await _productoRepository.getCurrentSucursalId();
      if (sucursalId == null || sucursalId.isEmpty) {
        return;
      }

      final response = await _productoRepository.getProductos(
        sucursalId: sucursalId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        filter: _selectedCategory != 'Todos' ? 'categoria' : null,
        filterValue: _selectedCategory != 'Todos' ? _selectedCategory : null,
        page: pagina,
        pageSize: _pageSize,
        sortBy: _sortBy,
        order: _order,
      );

      // Guardar en caché sin actualizar la UI
      if (mounted) {
        _productosCache[pagina] = response.items;
        _paginacionCache[pagina] = response.paginacion;
      }
    } catch (e) {
      // Silenciar errores de precarga
      debugPrint('Error precargando página $pagina: $e');
    }
  }

  /// Cambia el tamaño de página
  Future<void> _cambiarTamanioPagina(int nuevoTamanio) async {
    setState(() {
      _pageSize = nuevoTamanio;
    });
    _limpiarCache(); // Limpiar caché al cambiar tamaño de página
    await _cargarDatos(page: 1); // Volver a la primera página
  }
}
