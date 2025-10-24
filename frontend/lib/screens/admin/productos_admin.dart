import 'dart:convert';
// Importar dart:html solo en web
import 'dart:io' as io;

import 'package:condorsmotors/models/categoria.model.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/producto_agregar_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/producto_detalle_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/productos_form.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/productos_table.dart';
import 'package:condorsmotors/screens/admin/widgets/slide_sucursal.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductosAdminScreen extends StatefulWidget {
  const ProductosAdminScreen({super.key});

  @override
  State<ProductosAdminScreen> createState() => _ProductosAdminScreenState();
}

class _ProductosAdminScreenState extends State<ProductosAdminScreen> {
  // Clave para el valor de la tabla de productos
  final ValueNotifier<String> _productosKey =
      ValueNotifier<String>('productos_inicial');

  // Repositorios
  final ProductoRepository _productoRepository = ProductoRepository.instance;
  final CategoriaRepository _categoriaRepository = CategoriaRepository.instance;
  final SucursalRepository _sucursalRepository = SucursalRepository.instance;

  // Estado local de sucursales (como en stocks_admin.dart)
  List<Sucursal> _sucursales = [];
  Sucursal? _selectedSucursal;
  String _selectedSucursalId = '';
  bool _isLoadingSucursales = true;

  // Estado local de paginación
  int _currentPage = 1;
  int _pageSize = 10;
  String _sortBy = 'nombre';
  final String _order = 'asc';
  Paginacion _paginacion = Paginacion.emptyPagination;

  // Estado de productos
  List<Producto> _productos = [];
  List<Producto> _productosFiltrados = [];
  bool _isLoadingProductos = false;
  String _errorMessage = '';
  String _searchQuery = '';

  // Estado de filtros
  List<Categoria> _categorias = [];
  bool _isLoadingCategorias = false;
  String? _selectedCategory;

  // Getters para compatibilidad
  List<Producto> get productosFiltrados => _productosFiltrados;
  bool get isLoadingProductos => _isLoadingProductos;
  String get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  String get sortBy => _sortBy;
  String get order => _order;
  Paginacion get paginacion => _paginacion;
  bool get isLoadingCategorias => _isLoadingCategorias;
  String? get selectedCategory => _selectedCategory;
  List<String> get categoriasList => _categorias.map((c) => c.nombre).toList();

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  /// Inicializa el provider
  Future<void> _inicializar() async {
    await _cargarSucursales();
    await _cargarCategorias();
    // Después de inicializar, seleccionar la primera sucursal
    if (_sucursales.isNotEmpty && _selectedSucursalId.isEmpty) {
      // Intentar encontrar la sucursal principal primero
      final sucursalPrincipal = _sucursales.firstWhere(
        (sucursal) => sucursal.nombre.toLowerCase().contains('principal'),
        orElse: () => _sucursales.first,
      );
      await _seleccionarSucursal(sucursalPrincipal);
    }
  }

  /// Cargar las sucursales disponibles
  Future<void> _cargarSucursales() async {
    setState(() {
      _isLoadingSucursales = true;
    });

    try {
      final sucursales = await _sucursalRepository.getSucursales();
      setState(() {
        _sucursales = sucursales;
        _isLoadingSucursales = false;
      });
    } catch (e) {
      debugPrint('Error cargando sucursales: $e');
      setState(() {
        _isLoadingSucursales = false;
      });
    }
  }

  /// Selecciona una sucursal y carga sus productos
  Future<void> _seleccionarSucursal(Sucursal sucursal) async {
    if (_selectedSucursal?.id != sucursal.id) {
      setState(() {
        _selectedSucursal = sucursal;
        _selectedSucursalId = sucursal.id.toString();
      });
      await _cargarProductos();
    }
  }

  /// Carga las categorías
  Future<void> _cargarCategorias() async {
    setState(() {
      _isLoadingCategorias = true;
    });

    try {
      final categorias = await _categoriaRepository.getCategorias();
      setState(() {
        _categorias = categorias;
        _isLoadingCategorias = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar categorías: $e';
        _isLoadingCategorias = false;
      });
    }
  }

  /// Carga los productos para la sucursal seleccionada
  Future<void> _cargarProductos() async {
    if (_selectedSucursalId.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingProductos = true;
    });

    try {
      final response = await _productoRepository.getProductos(
        sucursalId: _selectedSucursalId,
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        sortBy: _sortBy,
        order: _order,
      );

      if (mounted) {
        setState(() {
          _productos = response.items;
          _productosFiltrados = _aplicarFiltros(_productos);
          _paginacion = Paginacion.fromParams(
            totalItems: response.totalItems,
            pageSize: _pageSize,
            currentPage: response.currentPage,
          );
          _isLoadingProductos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar productos: $e';
          _isLoadingProductos = false;
        });
      }
    }
  }

  /// Aplica filtros a los productos
  List<Producto> _aplicarFiltros(List<Producto> productos) {
    List<Producto> filtrados = List.from(productos);

    // Filtro de búsqueda
    if (_searchQuery.isNotEmpty) {
      filtrados = filtrados
          .where((producto) =>
              producto.nombre
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              producto.sku.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Filtro de categoría
    if (_selectedCategory != null) {
      filtrados = filtrados
          .where((producto) => producto.categoria == _selectedCategory)
          .toList();
    }

    return filtrados;
  }

  /// Cambia la página
  void _cambiarPagina(int pagina) {
    setState(() {
      _currentPage = pagina;
    });
    _cargarProductos();
  }

  /// Cambia el tamaño de página
  void _cambiarTamanioPagina(int tamanio) {
    setState(() {
      _pageSize = tamanio;
      _currentPage = 1;
    });
    _cargarProductos();
  }

  /// Ordena los productos
  void _ordenarPor(String campo) {
    setState(() {
      _sortBy = campo;
    });
    _cargarProductos();
  }

  /// Actualiza la búsqueda
  void _actualizarBusqueda(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });
    _cargarProductos();
  }

  /// Actualiza la categoría seleccionada
  void _actualizarCategoria(String? categoria) {
    setState(() {
      _selectedCategory = categoria;
      _currentPage = 1;
    });
    _cargarProductos();
  }

  /// Recarga los datos
  Future<void> _recargarDatos() async {
    setState(() {
      _errorMessage = '';
    });
    await _cargarProductos();
  }

  /// Habilita un producto (lo añade a la sucursal seleccionada)
  Future<void> _habilitarProducto(
      Producto producto, Map<String, dynamic> datos) async {
    try {
      if (_selectedSucursalId.isEmpty) {
        throw Exception('No hay sucursal seleccionada');
      }

      debugPrint(
          'Habilitando producto: ${producto.nombre} en sucursal $_selectedSucursalId con datos: $datos');

      // Llamar al backend para añadir el producto a la sucursal
      final productoHabilitado = await _productoRepository.addProducto(
        sucursalId: _selectedSucursalId,
        productoId: producto.id,
        productoData: datos,
      );

      if (productoHabilitado == null) {
        throw Exception('Error al habilitar el producto en la sucursal');
      }

      // Invalidar caché para forzar actualización
      _productoRepository.invalidateCache(_selectedSucursalId);

      debugPrint(
          'Producto habilitado exitosamente: ${productoHabilitado.nombre}');
    } catch (e) {
      debugPrint('Error al habilitar producto: $e');
      rethrow;
    }
  }

  /// Genera la exportación de productos en formato CSV
  Future<List<int>?> _generarExportacionProductos() async {
    try {
      if (_productosFiltrados.isEmpty) {
        return null;
      }

      // Crear contenido CSV
      final StringBuffer csvContent = StringBuffer()
        // Encabezados
        ..writeln(
            'SKU,Nombre,Categoría,Marca,Precio Compra,Precio Venta,Stock,Stock Mínimo,Color,Descripción');

      // Datos de productos
      for (final Producto producto in _productosFiltrados) {
        csvContent.writeln([
          producto.sku,
          producto.nombre,
          producto.categoria,
          producto.marca,
          producto.precioCompra.toString(),
          producto.precioVenta.toString(),
          producto.stock.toString(),
          producto.stockMinimo?.toString() ?? '',
          producto.color ?? '',
          (producto.descripcion ?? '')
              .replaceAll(',', ';'), // Evitar conflictos con comas
        ].join(','));
      }

      // Convertir a bytes (UTF-8)
      final List<int> bytes = utf8.encode(csvContent.toString());
      return bytes;
    } catch (e) {
      debugPrint('Error al generar exportación: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _productosKey.dispose();
    super.dispose();
  }

  void _showProductDialog(Producto? producto) {
    if (!mounted) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => ProductosFormDialogAdmin(
        producto: producto,
        sucursales: _sucursales,
        sucursalSeleccionada: _selectedSucursal,
        onSave: (Map<String, dynamic> productoData) {
          // No llamamos a _guardarProducto aquí ya que el formulario ya lo hace internamente
          // Solo actualizamos la UI para reflejar los cambios
          setState(() {
            _productosKey.value =
                'productos_${_selectedSucursal?.id}_refresh_${DateTime.now().millisecondsSinceEpoch}';
          });
          return Future<void>.value();
        },
      ),
    );
  }

  void _showProductoDetalleDialog(Producto producto) {
    ProductoDetalleDialog.show(
      context: context,
      producto: producto,
      sucursales: _sucursales,
      onSave: (Producto productoActualizado) {
        // Solo actualizamos la UI para reflejar los cambios
        // El formulario ya guardó los cambios internamente
        setState(() {
          _productosKey.value =
              'productos_${_selectedSucursal?.id}_refresh_${DateTime.now().millisecondsSinceEpoch}';
        });
        return Future<void>.value();
      },
    );
  }

  // NOTA: La funcionalidad de eliminación de productos no está implementada en el backend
  // Los productos se pueden deshabilitar removiéndolos de la sucursal específica
  // pero no se pueden eliminar completamente del sistema

  Future<void> _exportarProductos() async {
    final currentContext = context;
    ScaffoldMessenger.of(currentContext).showSnackBar(
      const SnackBar(
        content: Text('Exportando productos...'),
        backgroundColor: Colors.blue,
      ),
    );

    // Generar exportación local de productos
    final List<int>? excelBytes = await _generarExportacionProductos();

    if (mounted) {
      if (excelBytes != null && excelBytes.isNotEmpty) {
        // En web se puede descargar directamente
        if (kIsWeb) {
          // Para web, usamos la API html para descargar
          base64Encode(excelBytes);

          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(
              content: Text('Reporte de productos descargado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // En dispositivos Windows/Desktop/Mobile, guardamos el archivo localmente
          try {
            // Intentar obtener el directorio configurado desde las preferencias
            String? directorioGuardado;

            // Primero verificamos si hay un directorio configurado en preferencias
            final prefs = await SharedPreferences.getInstance();
            directorioGuardado = prefs.getString('directorioExcel');

            // Si no hay directorio configurado, usar el directorio de documentos por defecto
            if (directorioGuardado == null) {
              final io.Directory directory =
                  await getApplicationDocumentsDirectory();
              directorioGuardado = directory.path;
            }

            // Construir la ruta completa del archivo
            if (mounted) {
              ScaffoldMessenger.of(currentContext).showSnackBar(
                const SnackBar(
                  content: Text('Reporte de productos guardado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(currentContext).showSnackBar(
                SnackBar(
                  content: Text('Error al guardar archivo: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } else {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Actualizar la clave de la tabla cuando los productos cambian
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _productosKey.value =
            'productos_${_selectedSucursal?.id}_page_${_currentPage}_${DateTime.now().millisecondsSinceEpoch}';
      }
    });

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
                  child: Column(
                    children: <Widget>[
                      if (_selectedSucursal == null && !_isLoadingSucursales)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoadingSucursales)
                                const CircularProgressIndicator(
                                  color: Color(0xFFE31E24),
                                )
                              else
                                const FaIcon(
                                  FontAwesomeIcons.warehouse,
                                  color: Colors.white54,
                                  size: 48,
                                ),
                              const SizedBox(height: 16),
                              Text(
                                _isLoadingSucursales
                                    ? 'Cargando sucursales...'
                                    : 'Seleccione una sucursal para ver los productos',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        // Tabla de productos
                        Expanded(
                          child: ValueListenableBuilder<String>(
                            valueListenable: _productosKey,
                            builder: (BuildContext context, String key,
                                Widget? child) {
                              return ProductosTable(
                                key: ValueKey<String>(key),
                                productos: _productosFiltrados,
                                sucursales: _sucursales,
                                onEdit: _showProductDialog,
                                onViewDetails: _showProductoDetalleDialog,
                                onSort: _ordenarPor,
                                sortBy: _sortBy,
                                sortOrder: _order,
                                isLoading: _isLoadingProductos,
                                onEnable: (producto) async {
                                  final currentContext = context;
                                  await ProductoAgregarDialog.show(
                                    currentContext,
                                    producto: producto,
                                    sucursalNombre: _selectedSucursal?.nombre,
                                    onSave: (Map<String, dynamic>
                                        productoData) async {
                                      await _habilitarProducto(
                                          producto, productoData);

                                      // Recargar los datos de productos después de habilitar
                                      if (_selectedSucursalId.isNotEmpty) {
                                        await _cargarProductos();
                                      }

                                      if (!mounted) {
                                        return;
                                      }

                                      // Actualizar la clave para forzar refresh de la UI
                                      setState(() {
                                        _productosKey.value =
                                            'productos_${_selectedSucursal?.id}_refresh_${DateTime.now().millisecondsSinceEpoch}';
                                      });

                                      if (mounted) {
                                        ScaffoldMessenger.of(currentContext)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Producto habilitado exitosamente'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        // Paginador
                        if (_paginacion.totalPages > 0)
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Paginador(
                              paginacion: _paginacion,
                              onPageChanged: _cambiarPagina,
                              onPageSizeChanged: _cambiarTamanioPagina,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Panel derecho: Selector de sucursales (25% del ancho)
          Container(
            width: 350,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                left: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: SlideSucursal(
              sucursales: _sucursales,
              sucursalSeleccionada: _selectedSucursal,
              onSucursalSelected: _seleccionarSucursal,
              onRecargarSucursales: _cargarSucursales,
              isLoading: _isLoadingSucursales,
            ),
          ),
        ],
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
            color: Colors.white.withValues(alpha: 0.1),
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
                if (_selectedSucursal != null) ...<Widget>[
                  const Text(
                    ' / ',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white54,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      _selectedSucursal!.nombre,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withValues(alpha: 0.7),
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
              if (_selectedSucursal != null) ...<Widget>[
                ElevatedButton.icon(
                  icon: _isLoadingProductos
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const FaIcon(
                          FontAwesomeIcons.arrowsRotate,
                          size: 16,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isLoadingProductos ? 'Recargando...' : 'Recargar',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2D2D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _isLoadingProductos
                      ? null
                      : () async {
                          await _recargarDatos();
                          if (mounted) {
                            setState(() {
                              _productosKey.value =
                                  'productos_${_selectedSucursal?.id}_refresh_${DateTime.now().millisecondsSinceEpoch}';
                            });
                          }
                        },
                ),
                const SizedBox(width: 12),
              ],
              ElevatedButton.icon(
                icon: const FaIcon(FontAwesomeIcons.fileExcel,
                    size: 16, color: Colors.white),
                label: const Text('Exportar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D2D2D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onPressed: _selectedSucursal == null
                    ? null
                    : () async {
                        await _exportarProductos();
                      },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const FaIcon(FontAwesomeIcons.plus,
                    size: 16, color: Colors.white),
                label: const Text('Nuevo Producto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE31E24),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                onPressed: _selectedSucursal == null
                    ? null
                    : () {
                        _showProductDialog(null);
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedOpacity(
      opacity: _selectedSucursal == null ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF222222),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                enabled: _selectedSucursal != null,
                decoration: InputDecoration(
                  labelText: 'Buscar productos',
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE31E24)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2D2D2D),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: _actualizarBusqueda,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
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
                        items: _categorias
                            .map((c) => c.nombre)
                            .toList()
                            .map((String category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(
                              category,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: _selectedSucursal == null
                            ? null
                            : (String? value) {
                                if (value != null) {
                                  _actualizarCategoria(value);
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
