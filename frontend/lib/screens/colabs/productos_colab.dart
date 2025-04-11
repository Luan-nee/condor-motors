import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:condorsmotors/screens/colabs/selector_colab.dart';
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
  bool _isLoading = true;
  String? _error;

  // Lista de productos
  List<Producto> _productos = <Producto>[];

  // Información de paginación
  late Paginacion _paginacion;

  // Categorías disponibles (se cargarán desde la API)
  List<String> _categorias = <String>['Todos'];

  // Tamaño de página para la paginación
  static const int _pageSize = 20;

  // Repositorio de productos
  final ProductoRepository _productoRepository = ProductoRepository.instance;

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

      // Extraer categorías únicas de los productos
      final Set<String> categoriasSet = response.items
          .map((Producto p) => p.categoria)
          .where((String c) => c.isNotEmpty)
          .toSet();

      if (!mounted) {
        return;
      }

      setState(() {
        _productos = response.items;
        _paginacion = response.paginacion;
        _categorias = <String>['Todos', ...categoriasSet];
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

      // Mostrar error al cargar más productos
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar más productos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Producto> _getProductosFiltrados() {
    return _productos;
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

  IconData _getEstadoIcon(StockStatus estado) {
    switch (estado) {
      case StockStatus.disponible:
        return FontAwesomeIcons.check;
      case StockStatus.stockBajo:
        return FontAwesomeIcons.exclamation;
      case StockStatus.agotado:
        return FontAwesomeIcons.xmark;
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
          // Botón para recargar datos
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Recargar datos',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // Barra de búsqueda y filtros
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                // Buscador
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por código, nombre o marca...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (String value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      // Recargar datos con el nuevo filtro
                      _cargarDatos();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Filtro de categorías
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: _categorias.map((String categoria) {
                    return DropdownMenuItem<String>(
                      value: categoria,
                      child: Text(categoria),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                      // Recargar datos con el nuevo filtro
                      _cargarDatos();
                    }
                  },
                ),
              ],
            ),
          ),

          // Indicador de carga o error
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
            // Lista de productos
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

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(estado).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: FaIcon(
                            _getEstadoIcon(estado),
                            color: _getEstadoColor(estado),
                            size: 24,
                          ),
                        ),
                        title: Row(
                          children: <Widget>[
                            Text(
                              producto.sku,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                producto.nombre,
                                // Aplicar estilo condicional para liquidación
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
                        subtitle: Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
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
                            // Envolver el texto de la marca con Flexible para evitar overflow
                            Flexible(
                              child: Text(
                                producto.marca,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow
                                    .ellipsis, // Añadir ellipsis si es muy largo
                              ),
                            ),
                            // Chip de liquidación eliminado de aquí
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
                          // Detalles del producto
                          Container(
                            padding: const EdgeInsets.all(16),
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
                                Text(producto.descripcion ?? 'Sin descripción'),
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
                                      ],
                                    ),
                                  ],
                                ),
                                if (producto.cantidadGratisDescuento != null ||
                                    producto.porcentajeDescuento != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.3),
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
                                        if (producto.cantidadGratisDescuento !=
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
