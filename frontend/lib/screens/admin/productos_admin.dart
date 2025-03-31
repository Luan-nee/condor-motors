import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/producto_detalle_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/productos_form.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/productos_table.dart';
import 'package:condorsmotors/screens/admin/widgets/slide_sucursal.dart';
import 'package:condorsmotors/utils/productos_utils.dart';
import 'package:condorsmotors/widgets/dialogs/confirm_dialog.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductosAdminScreen extends StatefulWidget {
  const ProductosAdminScreen({super.key});

  @override
  State<ProductosAdminScreen> createState() => _ProductosAdminScreenState();
}

class _ProductosAdminScreenState extends State<ProductosAdminScreen> {
  bool _isLoadingSucursales = false;
  bool _isLoadingProductos = false;
  bool _isLoadingCategorias = false;
  PaginatedResponse<Producto>? _paginatedProductos;
  List<Producto> _productosFiltrados = <Producto>[];
  List<Sucursal> _sucursales = <Sucursal>[];
  Sucursal? _sucursalSeleccionada;

  // Repositorio de productos
  final ProductoRepository _productoRepository = ProductoRepository.instance;

  // Parámetros de paginación y filtrado
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  int _currentPage = 1;
  int _pageSize = 10;
  String _sortBy = '';
  String _order = 'desc';

  bool _drawerOpen = true;

  // Controlador para la tabla de productos (permite refrescar sin reconstruir toda la pantalla)
  final ValueNotifier<String> _productosKey =
      ValueNotifier<String>('productos_inicial');

  // Lista de categorías para el filtro (incluye 'Todos')
  final List<String> _categories = <String>['Todos'];

  @override
  void initState() {
    super.initState();
    _cargarSucursales();
    _cargarCategorias();
  }

  @override
  void dispose() {
    _productosKey.dispose();
    super.dispose();
  }

  void _filtrarProductos() {
    if (_paginatedProductos == null) {
      setState(() {
        _productosFiltrados = <Producto>[];
      });
      return;
    }

    setState(() {
      _productosFiltrados = ProductosUtils.filtrarProductos(
        productos: _paginatedProductos!.items,
        searchQuery: _searchQuery,
        selectedCategory: _selectedCategory,
      );
    });
  }

  Future<void> _cargarCategorias() async {
    setState(() => _isLoadingCategorias = true);

    try {
      final List<String> categorias = await ProductosUtils.obtenerCategorias();

      if (mounted) {
        setState(() {
          // Actualizar la lista de categorías para el filtro, manteniendo 'Todos' al inicio
          _categories
            ..clear()
            ..add('Todos')
            ..addAll(categorias);
          _isLoadingCategorias = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar categorías: $e');

      if (mounted) {
        setState(() => _isLoadingCategorias = false);
      }
    }
  }

  Future<void> _cargarSucursales() async {
    setState(() => _isLoadingSucursales = true);
    try {
      final List<Sucursal> sucursalesList =
          await api.sucursales.getSucursales();

      if (!mounted) {
        return;
      }
      setState(() {
        _sucursales = sucursalesList;
        _isLoadingSucursales = false;

        if (_sucursales.isNotEmpty && _sucursalSeleccionada == null) {
          _sucursalSeleccionada = _sucursales.first;
          _cargarProductos();
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar sucursales: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoadingSucursales = false);
    }
  }

  Future<void> _cargarProductos() async {
    if (_sucursalSeleccionada == null) {
      return;
    }

    setState(() => _isLoadingProductos = true);
    try {
      final String sucursalId = _sucursalSeleccionada!.id.toString();

      // Aplicar la búsqueda del servidor sólo si la búsqueda es mayor a 3 caracteres
      final String? searchQuery =
          _searchQuery.length >= 3 ? _searchQuery : null;

      debugPrint(
          'ProductosAdmin: Cargando productos de sucursal $sucursalId (página $_currentPage)');

      // Forzar actualización desde servidor (sin caché) después de editar un producto
      final PaginatedResponse<Producto> paginatedProductos =
          await _productoRepository.getProductos(
        sucursalId: sucursalId,
        search: searchQuery,
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: _sortBy.isNotEmpty ? _sortBy : null,
        order: _order,
        // Forzar bypass de caché después de operaciones de escritura
        useCache: false,
        forceRefresh: true, // Forzar refresco ignorando completamente la caché
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _paginatedProductos = paginatedProductos;
        _productosFiltrados = paginatedProductos.items;

        // Si hay una búsqueda local (menos de 3 caracteres) o filtro por categoría, se aplica
        if (_searchQuery.isNotEmpty && _searchQuery.length < 3 ||
            _selectedCategory != 'Todos') {
          _filtrarProductos();
        }

        _isLoadingProductos = false;

        // Actualizar la key para forzar el redibujado solo de la tabla
        _productosKey.value =
            'productos_${_sucursalSeleccionada!.id}_${DateTime.now().millisecondsSinceEpoch}';

        debugPrint(
            'ProductosAdmin: Productos cargados desde servidor: ${_productosFiltrados.length} items');
      });
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
      setState(() => _isLoadingProductos = false);
    }
  }

  // Método para cambiar de página
  void _cambiarPagina(int pagina) {
    if (_currentPage != pagina) {
      setState(() {
        _currentPage = pagina;
      });
      _cargarProductos();
    }
  }

  // Método para cambiar tamaño de página
  void _cambiarTamanioPagina(int tamanio) {
    if (_pageSize != tamanio) {
      setState(() {
        _pageSize = tamanio;
        _currentPage = 1; // Volvemos a la primera página al cambiar el tamaño
      });
      _cargarProductos();
    }
  }

  // Método para ordenar por un campo
  void _ordenarPor(String campo) {
    setState(() {
      if (_sortBy == campo) {
        // Si ya estamos ordenando por este campo, cambiamos la dirección
        _order = _order == 'asc' ? 'desc' : 'asc';
      } else {
        _sortBy = campo;
        _order = 'desc'; // Por defecto ordenamos descendente
      }
      _currentPage = 1; // Volvemos a la primera página al cambiar el orden
    });
    _cargarProductos();
  }

  Future<void> _guardarProducto(
      Map<String, dynamic> productoData, bool esNuevo) async {
    if (_sucursalSeleccionada == null) {
      return;
    }

    final String sucursalId = _sucursalSeleccionada!.id.toString();

    try {
      // Añadir logging para diagnóstico
      debugPrint('ProductosAdmin: Guardando producto en sucursal $sucursalId');
      debugPrint('ProductosAdmin: Es nuevo producto: $esNuevo');
      debugPrint('ProductosAdmin: Datos del producto: $productoData');

      // Mostrar indicador de carga
      setState(() => _isLoadingProductos = true);

      Producto? resultado;
      if (esNuevo) {
        resultado = await _productoRepository.createProducto(
          sucursalId: sucursalId,
          productoData: productoData,
        );
        debugPrint('ProductosAdmin: Producto creado correctamente');
      } else {
        // Manejar correctamente el tipo de ID
        final dynamic rawId = productoData['id'];
        if (rawId == null) {
          throw Exception('ID de producto es null. No se puede actualizar.');
        }

        // Convertir ID a entero de forma segura
        final int productoId =
            rawId is int ? rawId : (rawId is String ? int.parse(rawId) : -1);

        if (productoId <= 0) {
          throw Exception('ID de producto inválido: $rawId');
        }

        debugPrint('ProductosAdmin: Actualizando producto ID $productoId');

        resultado = await _productoRepository.updateProducto(
          sucursalId: sucursalId,
          productoId: productoId,
          productoData: productoData,
        );

        debugPrint('ProductosAdmin: Producto actualizado correctamente');

        // Forzar limpieza de caché para este producto específico
        _productoRepository.invalidateCache(sucursalId);
      }

      if (!mounted) {
        return;
      }

      // Mostrar mensaje de error si no se pudo guardar el producto
      if (resultado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('No se pudo guardar el producto. Inténtelo de nuevo.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoadingProductos = false);
        return;
      }

      // Recargar productos forzando ignorar caché
      await _cargarProductos();

      // Forzar actualización de la vista después de guardar el producto
      setState(() {
        // Esta llamada a setState fuerza la reconstrucción del widget
        // y asegura que se refleje visualmente el cambio
        _productosKey.value =
            'productos_${_sucursalSeleccionada!.id}_refresh_${DateTime.now().millisecondsSinceEpoch}';
        _isLoadingProductos = false;
      });

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto guardado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('ProductosAdmin: ERROR al guardar producto: $e');
      if (!mounted) {
        return;
      }

      // Ocultar indicador de carga
      setState(() => _isLoadingProductos = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar producto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarProducto(Producto producto) async {
    if (_sucursalSeleccionada == null) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => ConfirmDialog(
        title: 'Eliminar Producto',
        message:
            '¿Está seguro que desea eliminar el producto "${producto.nombre}"?',
        confirmText: 'Eliminar',
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );

    if (confirmed ?? false) {
      setState(() => _isLoadingProductos = true);
      try {
        final String sucursalId = _sucursalSeleccionada!.id.toString();
        final bool eliminado = await _productoRepository.deleteProducto(
          sucursalId: sucursalId,
          productoId: producto.id,
        );

        if (!mounted) {
          return;
        }

        if (eliminado) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          await _cargarProductos();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo eliminar el producto'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isLoadingProductos = false);
        }
      } catch (e) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar producto: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoadingProductos = false);
      }
    }
  }

  void _showProductDialog(Producto? producto) {
    final bool esNuevo = producto == null;

    if (!mounted) {
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => ProductosFormDialogAdmin(
        producto: producto,
        sucursales: _sucursales,
        sucursalSeleccionada: _sucursalSeleccionada,
        onSave: (Map<String, dynamic> productoData) =>
            _guardarProducto(productoData, esNuevo),
      ),
    );
  }

  void _showProductoDetalleDialog(Producto producto) {
    ProductoDetalleDialog.show(
      context: context,
      producto: producto,
      sucursales: _sucursales,
      onSave: (Producto productoActualizado) =>
          _guardarProducto(<String, dynamic>{
        'id': productoActualizado.id,
        'precioOferta': productoActualizado.precioOferta,
        'liquidacion': productoActualizado.liquidacion,
      }, false),
    );
  }

  void _handleSucursalSelected(Sucursal sucursal) {
    // Solo actualizar si realmente se seleccionó una sucursal diferente
    if (_sucursalSeleccionada?.id != sucursal.id) {
      setState(() {
        _sucursalSeleccionada = sucursal;
        _currentPage = 1; // Volver a la primera página al cambiar de sucursal
      });
      _cargarProductos();
    }
  }

  Future<void> _exportarProductos() async {
    if (_sucursalSeleccionada == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportando productos...'),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      // Implementación de ejemplo (mostrar que la función fue ejecutada)
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Productos exportados exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar productos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          // Panel principal (75% del ancho)
          Expanded(
            flex: 75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Header con nombre y acciones
                _buildHeader(),
                // Barra de búsqueda y filtros
                _buildSearchBar(),
                // Tabla de productos
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _sucursalSeleccionada == null
                        ? Center(
                            key: const ValueKey<String>('no_branch_selected'),
                            child: Text(
                              'Seleccione una sucursal para ver los productos',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          )
                        : _isLoadingProductos
                            ? Center(
                                key: const ValueKey<String>('loading_products'),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const CircularProgressIndicator(
                                      color: Color(0xFFE31E24),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Cargando productos...',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: <Widget>[
                                  // Tabla de productos
                                  Expanded(
                                    child: ValueListenableBuilder<String>(
                                      valueListenable: _productosKey,
                                      builder: (BuildContext context,
                                          String key, Widget? child) {
                                        return ProductosTable(
                                          key: ValueKey<String>(key),
                                          productos: _productosFiltrados,
                                          sucursales: _sucursales,
                                          onEdit: _showProductDialog,
                                          onDelete: _eliminarProducto,
                                          onViewDetails:
                                              _showProductoDetalleDialog,
                                          onSort: _ordenarPor,
                                          sortBy: _sortBy,
                                          sortOrder: _order,
                                        );
                                      },
                                    ),
                                  ),

                                  // Paginador
                                  if (_paginatedProductos != null &&
                                      _paginatedProductos!
                                              .paginacion.totalPages >
                                          0)
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          // Info de cantidad
                                          Text(
                                            'Mostrando ${_productosFiltrados.length} de ${_paginatedProductos!.paginacion.totalItems} productos',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              fontSize: 14,
                                            ),
                                          ),

                                          // Paginador
                                          Paginador(
                                            paginacion:
                                                _paginatedProductos!.paginacion,
                                            onPageChanged: _cambiarPagina,
                                          ),

                                          // Selector de tamaño de página
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Text(
                                                'Mostrar:',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              _buildPageSizeDropdown(),
                                            ],
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

          // Panel lateral de sucursales
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _drawerOpen ? MediaQuery.of(context).size.width * 0.25 : 0,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                left: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
            child: _drawerOpen
                ? SlideSucursal(
                    sucursales: _sucursales,
                    sucursalSeleccionada: _sucursalSeleccionada,
                    onSucursalSelected: _handleSucursalSelected,
                    onRecargarSucursales: _cargarSucursales,
                    isLoading: _isLoadingSucursales,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPageSizeDropdown() {
    final List<int> options = <int>[10, 20, 50, 100];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _pageSize,
          items: options.map((int size) {
            return DropdownMenuItem<int>(
              value: size,
              child: Text(
                size.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (int? value) {
            if (value != null) {
              _cambiarTamanioPagina(value);
            }
          },
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white),
          dropdownColor: const Color(0xFF2D2D2D),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                const FaIcon(
                  FontAwesomeIcons.boxesStacked,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'PRODUCTOS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (_sucursalSeleccionada != null) ...<Widget>[
                  const Text(
                    ' / ',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white54,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      _sucursalSeleccionada!.nombre,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: <Widget>[
              // Botón para mostrar/ocultar el panel de sucursales
              IconButton(
                icon: Icon(
                  _drawerOpen
                      ? Icons.view_sidebar_outlined
                      : Icons.view_sidebar,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _drawerOpen = !_drawerOpen;
                  });
                },
                tooltip: 'Selector de sucursal',
              ),
              const SizedBox(width: 12),
              if (_sucursalSeleccionada != null) ...<Widget>[
                ElevatedButton.icon(
                  icon: const FaIcon(
                    FontAwesomeIcons.fileExport,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text('Exportar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2D2D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _exportarProductos,
                ),
                const SizedBox(width: 12),
              ],
              ElevatedButton.icon(
                icon: const FaIcon(
                  FontAwesomeIcons.plus,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text('Nuevo Producto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE31E24),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: _sucursalSeleccionada == null
                    ? null
                    : () => _showProductDialog(null),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedOpacity(
      opacity: _sucursalSeleccionada == null ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF222222),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                enabled: _sucursalSeleccionada != null,
                decoration: InputDecoration(
                  labelText: 'Buscar productos',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE31E24)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2D2D2D),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (String value) {
                  setState(() {
                    _searchQuery = value;

                    // Si la búsqueda es mayor a 3 caracteres, hacemos una nueva solicitud al servidor
                    if (value.length >= 3 || value.isEmpty) {
                      _currentPage = 1; // Reiniciar a la primera página
                      _cargarProductos();
                    } else {
                      // Para búsquedas cortas, filtramos localmente
                      _filtrarProductos();
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: _isLoadingCategorias
                  ? const SizedBox(
                      width: 100,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFFE31E24),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        items: _categories.map((String category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(
                              category,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: _sucursalSeleccionada == null
                            ? null
                            : (String? value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCategory = value;
                                    _filtrarProductos();
                                  });
                                }
                              },
                        dropdownColor: const Color(0xFF2D2D2D),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.white54),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
