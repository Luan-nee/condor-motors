import 'dart:async';

import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/providers/paginacion.provider.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TransferenciaFormListColab extends StatefulWidget {
  final String sucursalId;
  final List<DetalleProducto> productosSeleccionados;

  const TransferenciaFormListColab({
    super.key,
    required this.sucursalId,
    required this.productosSeleccionados,
  });

  @override
  State<TransferenciaFormListColab> createState() =>
      _TransferenciaFormListColabState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('sucursalId', sucursalId))
      ..add(IterableProperty<DetalleProducto>(
          'productosSeleccionados', productosSeleccionados));
  }
}

class _TransferenciaFormListColabState
    extends State<TransferenciaFormListColab> {
  final ProductoRepository _productoRepository = ProductoRepository.instance;
  final TextEditingController _searchController = TextEditingController();
  final List<DetalleProducto> _selectedProducts = [];
  List<Producto> _productosBajoStock = [];
  List<Producto> _productosNormales = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Timer? _debounce;
  bool _isStockBajoExpanded = true;

  // Nuevos estados para los filtros desplegables
  bool _isSearchExpanded = false;
  bool _isCategoriaExpanded = false;
  bool _isOrdenamientoExpanded = false;
  String _filtroCategoria = 'Todos';
  String _ordenarPor = 'nombre';
  String _orden = 'asc';

  final PaginacionProvider _paginacionProvider = PaginacionProvider();

  @override
  void initState() {
    super.initState();
    _selectedProducts.addAll(widget.productosSeleccionados);
    _paginacionProvider
      ..cambiarItemsPorPagina(10)
      ..cambiarOrdenarPor(_ordenarPor)
      ..cambiarOrden(_orden);
    _loadProductos();
    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) {
        _debounce!.cancel();
      }
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (_searchQuery != _searchController.text) {
          setState(() => _searchQuery = _searchController.text);
          _loadProductos();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: size.width * 0.95,
        height: size.height * 0.95,
        constraints: const BoxConstraints(
          minWidth: 300,
          minHeight: 400,
          maxWidth: 900,
          maxHeight: 900,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF2D2D2D),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.box,
                    size: 20,
                    color: Color(0xFFE31E24),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Seleccionar Productos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Barra de filtros
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildFilterButton(
                        isExpanded: _isSearchExpanded,
                        icon: Icons.search,
                        activeIcon: Icons.search,
                        label: 'Buscar',
                        color: Colors.orange,
                        hasValue: _searchController.text.isNotEmpty,
                        onPressed: _toggleSearch,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterButton(
                        isExpanded: _isCategoriaExpanded,
                        icon: Icons.category_outlined,
                        activeIcon: Icons.category,
                        label: 'Categoría',
                        color: Colors.blue,
                        hasValue: _filtroCategoria != 'Todos',
                        onPressed: _toggleCategoria,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterButton(
                        isExpanded: _isOrdenamientoExpanded,
                        icon: Icons.sort,
                        activeIcon: Icons.sort,
                        label: 'Ordenar',
                        color: Colors.purple,
                        hasValue: _ordenarPor != 'nombre' || _orden != 'asc',
                        onPressed: _toggleOrdenamiento,
                      ),
                      const Spacer(),
                      if (_tieneAlgunFiltroActivo())
                        _buildFilterButton(
                          isExpanded: false,
                          icon: Icons.filter_list_off,
                          activeIcon: Icons.filter_list_off,
                          label: 'Limpiar',
                          color: Colors.red,
                          hasValue: false,
                          onPressed: _restablecerFiltros,
                        ),
                    ],
                  ),
                  if (_isSearchExpanded) _buildSearchExpandido(),
                  if (_isCategoriaExpanded) _buildCategoriaExpandida(),
                  if (_isOrdenamientoExpanded) _buildOrdenamientoExpandido(),
                ],
              ),
            ),
            if (_tieneAlgunFiltroActivo())
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildFilterSummary(),
              ),
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              if (_productosBajoStock.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2D2D2D),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFE31E24)
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: ExpansionTile(
                                    initiallyExpanded: _isStockBajoExpanded,
                                    onExpansionChanged: (expanded) {
                                      setState(() =>
                                          _isStockBajoExpanded = expanded);
                                    },
                                    title: Row(
                                      children: [
                                        const Text(
                                          'Productos con Stock Bajo',
                                          style: TextStyle(
                                            color: Color(0xFFE31E24),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE31E24)
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${_productosBajoStock.length}',
                                            style: const TextStyle(
                                              color: Color(0xFFE31E24),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    iconColor: const Color(0xFFE31E24),
                                    collapsedIconColor: const Color(0xFFE31E24),
                                    children: _productosBajoStock
                                        .map((producto) =>
                                            _buildProductItem(producto, true))
                                        .toList(),
                                  ),
                                ),
                              if (_productosNormales.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Otros Productos',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                ..._productosNormales.map((producto) =>
                                    _buildProductItem(producto, false)),
                              ],
                            ],
                          ),
                        ),
                        if (_productosNormales.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Paginador(
                              paginacionProvider: _paginacionProvider,
                              onPageChange: _loadProductos,
                              backgroundColor: const Color(0xFF2D2D2D),
                              textColor: Colors.white,
                              accentColor: const Color(0xFFE31E24),
                              forceCompactMode: true,
                            ),
                          ),
                      ],
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF2D2D2D),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _selectedProducts.isEmpty
                        ? null
                        : () => Navigator.pop(context, _selectedProducts),
                    icon: const FaIcon(FontAwesomeIcons.check, size: 16),
                    label: const Text('Confirmar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
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

  Widget _buildFilterButton({
    required bool isExpanded,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color color,
    required bool hasValue,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isExpanded ? color.withValues(alpha: 0.2) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isExpanded ? activeIcon : icon,
              color: isExpanded || hasValue ? color : Colors.white70,
              size: 20,
            ),
            if (!isExpanded && hasValue) ...[
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        onPressed: onPressed,
        tooltip: label,
      ),
    );
  }

  Widget _buildSearchExpandido() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  color: Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Buscar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _toggleSearch,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código...',
                hintStyle: const TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        color: Colors.white60,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          _searchController.clear();
                          _loadProductos();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _loadProductos(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaExpandida() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.category,
                  color: Colors.blue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Categoría',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _toggleCategoria,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filtroCategoria,
                isExpanded: true,
                dropdownColor: const Color(0xFF2D2D2D),
                style: const TextStyle(color: Colors.white),
                items: ['Todos', 'Repuestos', 'Accesorios', 'Lubricantes']
                    .map((String categoria) {
                  return DropdownMenuItem<String>(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _filtroCategoria = newValue;
                    });
                    _loadProductos();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdenamientoExpandido() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.sort,
                  color: Colors.purple,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ordenar por',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _toggleOrdenamiento,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _ordenarPor,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2D2D2D),
                    style: const TextStyle(color: Colors.white),
                    items: [
                      {'value': 'nombre', 'label': 'Nombre'},
                      {'value': 'stock', 'label': 'Stock'},
                      {'value': 'sku', 'label': 'Código'},
                    ].map((Map<String, String> item) {
                      return DropdownMenuItem<String>(
                        value: item['value'],
                        child: Text(item['label']!),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _ordenarPor = newValue;
                        });
                        _loadProductos();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _orden,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2D2D2D),
                    style: const TextStyle(color: Colors.white),
                    items: [
                      {'value': 'asc', 'label': 'Ascendente'},
                      {'value': 'desc', 'label': 'Descendente'},
                    ].map((Map<String, String> item) {
                      return DropdownMenuItem<String>(
                        value: item['value'],
                        child: Text(item['label']!),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _orden = newValue;
                        });
                        _loadProductos();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSummary() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (_filtroCategoria != 'Todos')
            _buildFilterChip(
              icon: Icons.category,
              label: 'Categoría: $_filtroCategoria',
              color: Colors.blue,
              onClear: () {
                setState(() {
                  _filtroCategoria = 'Todos';
                });
                _loadProductos();
              },
            ),
          if (_searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildFilterChip(
                icon: Icons.search,
                label: 'Búsqueda: "${_searchController.text}"',
                color: Colors.orange,
                onClear: () {
                  _searchController.clear();
                  _loadProductos();
                },
              ),
            ),
          if (_ordenarPor != 'nombre' || _orden != 'asc')
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildFilterChip(
                icon: Icons.sort,
                label: 'Orden: ${_getOrdenLabel()}',
                color: Colors.purple,
                onClear: () {
                  setState(() {
                    _ordenarPor = 'nombre';
                    _orden = 'asc';
                  });
                  _loadProductos();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onClear,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onClear,
            child: Icon(Icons.close, size: 14, color: color),
          ),
        ],
      ),
    );
  }

  String _getOrdenLabel() {
    final String campo = {
          'nombre': 'Nombre',
          'stock': 'Stock',
          'sku': 'Código',
        }[_ordenarPor] ??
        'Nombre';

    final String direccion = _orden == 'asc' ? '↑' : '↓';
    return '$campo $direccion';
  }

  bool _tieneAlgunFiltroActivo() {
    return _filtroCategoria != 'Todos' ||
        _searchController.text.isNotEmpty ||
        _ordenarPor != 'nombre' ||
        _orden != 'asc';
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (!_isSearchExpanded && _searchController.text.isNotEmpty) {
        _searchController.clear();
        _loadProductos();
      }
      // Cerrar otros filtros
      _isCategoriaExpanded = false;
      _isOrdenamientoExpanded = false;
    });
  }

  void _toggleCategoria() {
    setState(() {
      _isCategoriaExpanded = !_isCategoriaExpanded;
      // Cerrar otros filtros
      _isSearchExpanded = false;
      _isOrdenamientoExpanded = false;
    });
  }

  void _toggleOrdenamiento() {
    setState(() {
      _isOrdenamientoExpanded = !_isOrdenamientoExpanded;
      // Cerrar otros filtros
      _isSearchExpanded = false;
      _isCategoriaExpanded = false;
    });
  }

  void _restablecerFiltros() {
    setState(() {
      _searchController.clear();
      _filtroCategoria = 'Todos';
      _ordenarPor = 'nombre';
      _orden = 'asc';
      // Cerrar todos los filtros expandidos
      _isSearchExpanded = false;
      _isCategoriaExpanded = false;
      _isOrdenamientoExpanded = false;
    });
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    setState(() => _isLoading = true);

    try {
      // Aplicar filtros de búsqueda y ordenamiento
      final Map<String, dynamic> filtros = {
        'search': _searchController.text,
        'categoria': _filtroCategoria,
        'ordenarPor': _ordenarPor,
        'orden': _orden,
      };

      // Cargar productos con stock bajo
      final responseStockBajo =
          await _productoRepository.getProductosConStockBajo(
        sucursalId: widget.sucursalId,
        pageSize: 100,
        sortBy: 'stock',
        useCache: false,
      );

      // Cargar productos normales con filtros
      final responseNormales = await _productoRepository.getProductosPorFiltros(
        sucursalId: widget.sucursalId,
        categoria: _filtroCategoria != 'Todos' ? _filtroCategoria : null,
        page: _paginacionProvider.paginacion.currentPage,
        pageSize: _paginacionProvider.itemsPerPage,
        stockPositivo: true,
        useCache: false,
      );

      // Si hay término de búsqueda, filtrar resultados
      if (_searchController.text.isNotEmpty) {
        final String searchTerm = _searchController.text.toLowerCase();
        _productosBajoStock = responseStockBajo.items.where((producto) {
          return producto.nombre.toLowerCase().contains(searchTerm) ||
              (producto.sku.toLowerCase().contains(searchTerm));
        }).toList();

        _productosNormales = responseNormales.items.where((producto) {
          return producto.nombre.toLowerCase().contains(searchTerm) ||
              (producto.sku.toLowerCase().contains(searchTerm));
        }).toList();
      } else {
        _productosBajoStock = responseStockBajo.items;
        _productosNormales = responseNormales.items;
      }

      // Aplicar ordenamiento
      if (_ordenarPor != 'nombre' || _orden != 'asc') {
        int comparador(a, b) {
          int resultado = 0;
          switch (_ordenarPor) {
            case 'nombre':
              resultado = a.nombre.compareTo(b.nombre);
              break;
            case 'stock':
              resultado = a.stock.compareTo(b.stock);
              break;
            case 'sku':
              resultado = (a.sku).compareTo(b.sku);
              break;
          }
          return _orden == 'asc' ? resultado : -resultado;
        }

        _productosBajoStock.sort(comparador);
        _productosNormales.sort(comparador);
      }

      setState(() {
        // Actualizar paginación con los datos de productos normales
        _paginacionProvider.actualizarPaginacion(
          Paginacion(
            currentPage: responseNormales.paginacion.currentPage,
            totalPages: responseNormales.paginacion.totalPages,
            totalItems: responseNormales.paginacion.totalItems,
            hasNext: responseNormales.paginacion.hasNext,
            hasPrev: responseNormales.paginacion.hasPrev,
          ),
        );
      });

      debugPrint('📦 Productos cargados:');
      debugPrint('- Stock bajo: ${_productosBajoStock.length}');
      debugPrint('- Normales: ${_productosNormales.length}');
      debugPrint('- Filtros aplicados: $filtros');
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar productos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildProductItem(Producto producto, bool isBajoStock) {
    final stockMinimo = producto.stockMinimo ?? 0;
    final int stockDiferencia = stockMinimo - producto.stock;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
        border: isBajoStock
            ? Border.all(
                color: const Color(0xFFE31E24).withValues(alpha: 0.5),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE31E24).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.box,
                  color: Color(0xFFE31E24),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Stock: ${producto.stock}/$stockMinimo',
                          style: TextStyle(
                            color: isBajoStock
                                ? const Color(0xFFE31E24)
                                : Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        if (isBajoStock)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE31E24).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Faltan: $stockDiferencia',
                              style: const TextStyle(
                                color: Color(0xFFE31E24),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildQuantityControls(producto),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControls(Producto producto) {
    final selectedProduct = _selectedProducts.firstWhere(
      (p) => p.id == producto.id,
      orElse: () => DetalleProducto(
        id: producto.id,
        nombre: producto.nombre,
        codigo: producto.sku,
        cantidad: 0,
      ),
    );

    final cantidad = selectedProduct.cantidad;
    final TextEditingController cantidadController = TextEditingController(
      text: cantidad > 0 ? cantidad.toString() : '',
    );

    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 24),
            color: Colors.white70,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: cantidad > 0
                ? () => _updateProductQuantity(producto, cantidad - 1)
                : null,
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 45,
            height: 32,
            child: TextField(
              controller: cantidadController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                isDense: true,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE31E24)),
                ),
              ),
              onSubmitted: (value) {
                final newCantidad = int.tryParse(value) ?? 0;
                _updateProductQuantity(producto, newCantidad);
              },
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 24),
            color: const Color(0xFFE31E24),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: () => _updateProductQuantity(producto, cantidad + 1),
          ),
        ],
      ),
    );
  }

  void _updateProductQuantity(Producto producto, int newCantidad) {
    if (newCantidad <= 0) {
      setState(() {
        _selectedProducts.removeWhere((p) => p.id == producto.id);
      });
      return;
    }

    setState(() {
      final existingIndex =
          _selectedProducts.indexWhere((p) => p.id == producto.id);
      if (existingIndex >= 0) {
        _selectedProducts[existingIndex] = DetalleProducto(
          id: producto.id,
          nombre: producto.nombre,
          codigo: producto.sku,
          cantidad: newCantidad,
        );
      } else {
        _selectedProducts.add(DetalleProducto(
          id: producto.id,
          nombre: producto.nombre,
          codigo: producto.sku,
          cantidad: newCantidad,
        ));
      }
    });
  }
}
