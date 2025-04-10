import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/providers/admin/producto.admin.provider.dart';
import 'package:condorsmotors/providers/paginacion.provider.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/producto_detalle_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/productos_form.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/productos_table.dart';
import 'package:condorsmotors/screens/admin/widgets/slide_sucursal.dart';
import 'package:condorsmotors/widgets/dialogs/confirm_dialog.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class ProductosAdminScreen extends StatefulWidget {
  const ProductosAdminScreen({super.key});

  @override
  State<ProductosAdminScreen> createState() => _ProductosAdminScreenState();
}

class _ProductosAdminScreenState extends State<ProductosAdminScreen> {
  // Clave para el valor de la tabla de productos
  final ValueNotifier<String> _productosKey =
      ValueNotifier<String>('productos_inicial');

  // Estado del drawer
  final bool _drawerOpen = true;

  // Provider para paginación
  final PaginacionProvider _paginacionProvider = PaginacionProvider();

  @override
  void initState() {
    super.initState();

    // Inicializar el provider al montar el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ProductoProvider productoProvider =
          Provider.of<ProductoProvider>(context, listen: false);
      productoProvider.inicializar();
    });
  }

  @override
  void dispose() {
    _productosKey.dispose();
    super.dispose();
  }

  void _showProductDialog(Producto? producto) {
    final bool esNuevo = producto == null;
    final ProductoProvider productoProvider =
        Provider.of<ProductoProvider>(context, listen: false);

    if (!mounted) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => ProductosFormDialogAdmin(
        producto: producto,
        sucursales: productoProvider.sucursales,
        sucursalSeleccionada: productoProvider.sucursalSeleccionada,
        onSave: (Map<String, dynamic> productoData) {
          _guardarProducto(productoData, esNuevo);
          return Future<void>.value();
        },
      ),
    );
  }

  void _showProductoDetalleDialog(Producto producto) {
    final ProductoProvider productoProvider =
        Provider.of<ProductoProvider>(context, listen: false);

    ProductoDetalleDialog.show(
      context: context,
      producto: producto,
      sucursales: productoProvider.sucursales,
      onSave: (Producto productoActualizado) {
        _guardarProducto(<String, dynamic>{
          'id': productoActualizado.id,
          'precioOferta': productoActualizado.precioOferta,
          'liquidacion': productoActualizado.liquidacion,
        }, false);
        return Future<void>.value();
      },
    );
  }

  Future<void> _guardarProducto(
      Map<String, dynamic> productoData, bool esNuevo) async {
    final ProductoProvider productoProvider =
        Provider.of<ProductoProvider>(context, listen: false);

    final bool resultado =
        await productoProvider.guardarProducto(productoData, esNuevo);

    if (mounted) {
      if (resultado) {
        // Forzar actualización de la vista después de guardar el producto
        setState(() {
          _productosKey.value =
              'productos_${productoProvider.sucursalSeleccionada?.id}_refresh_${DateTime.now().millisecondsSinceEpoch}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (productoProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productoProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarProducto(Producto producto) async {
    final ProductoProvider productoProvider =
        Provider.of<ProductoProvider>(context, listen: false);

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
      final bool eliminado = await productoProvider.eliminarProducto(producto);

      if (mounted) {
        if (eliminado) {
          // Forzar actualización de la vista después de eliminar el producto
          setState(() {
            _productosKey.value =
                'productos_${productoProvider.sucursalSeleccionada?.id}_refresh_${DateTime.now().millisecondsSinceEpoch}';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (productoProvider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(productoProvider.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _exportarProductos() async {
    final ProductoProvider productoProvider =
        Provider.of<ProductoProvider>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportando productos...'),
        backgroundColor: Colors.blue,
      ),
    );

    final bool resultado = await productoProvider.exportarProductos();

    if (mounted) {
      if (resultado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Productos exportados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (productoProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productoProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductoProvider>(
      builder: (context, productoProvider, child) {
        // Actualizar paginación desde el provider de productos
        if (productoProvider.paginatedProductos != null) {
          _paginacionProvider.actualizarPaginacion(
              productoProvider.paginatedProductos!.paginacion);
        }

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
                    _buildHeader(productoProvider),
                    // Barra de búsqueda y filtros
                    _buildSearchBar(productoProvider),
                    // Tabla de productos
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: productoProvider.sucursalSeleccionada == null
                            ? Center(
                                key: const ValueKey<String>(
                                    'no_branch_selected'),
                                child: Text(
                                  'Seleccione una sucursal para ver los productos',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              )
                            : productoProvider.isLoadingProductos
                                ? Center(
                                    key: const ValueKey<String>(
                                        'loading_products'),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        const CircularProgressIndicator(
                                          color: Color(0xFFE31E24),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Cargando productos...',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
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
                                              productos: productoProvider
                                                  .productosFiltrados,
                                              sucursales:
                                                  productoProvider.sucursales,
                                              onEdit: _showProductDialog,
                                              onDelete: _eliminarProducto,
                                              onViewDetails:
                                                  _showProductoDetalleDialog,
                                              onSort:
                                                  productoProvider.ordenarPor,
                                              sortBy: productoProvider.sortBy,
                                              sortOrder: productoProvider.order,
                                            );
                                          },
                                        ),
                                      ),

                                      // Paginador
                                      if (productoProvider.paginatedProductos !=
                                              null &&
                                          productoProvider.paginatedProductos!
                                                  .paginacion.totalPages >
                                              0)
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              // Paginador con provider
                                              ChangeNotifierProvider.value(
                                                value: _paginacionProvider,
                                                child: Paginador(
                                                  paginacion: productoProvider
                                                      .paginatedProductos!
                                                      .paginacion,
                                                  onPageChanged:
                                                      productoProvider
                                                          .cambiarPagina,
                                                  onPageSizeChanged:
                                                      productoProvider
                                                          .cambiarTamanioPagina,
                                                  backgroundColor:
                                                      const Color(0xFF2D2D2D),
                                                  textColor: Colors.white,
                                                  accentColor:
                                                      const Color(0xFFE31E24),
                                                ),
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
                width:
                    _drawerOpen ? MediaQuery.of(context).size.width * 0.25 : 0,
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
                        sucursales: productoProvider.sucursales,
                        sucursalSeleccionada:
                            productoProvider.sucursalSeleccionada,
                        onSucursalSelected:
                            productoProvider.seleccionarSucursal,
                        onRecargarSucursales: productoProvider.cargarSucursales,
                        isLoading: productoProvider.isLoadingSucursales,
                      )
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ProductoProvider productoProvider) {
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
                if (productoProvider.sucursalSeleccionada != null) ...<Widget>[
                  const Text(
                    ' / ',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white54,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      productoProvider.sucursalSeleccionada!.nombre,
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
              if (productoProvider.sucursalSeleccionada != null) ...<Widget>[
                ElevatedButton.icon(
                  icon: productoProvider.isLoadingProductos
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
                    productoProvider.isLoadingProductos
                        ? 'Recargando...'
                        : 'Recargar',
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
                  onPressed: productoProvider.isLoadingProductos
                      ? null
                      : () async {
                          await productoProvider.recargarDatos();
                          if (mounted) {
                            setState(() {
                              _productosKey.value =
                                  'productos_${productoProvider.sucursalSeleccionada?.id}_refresh_${DateTime.now().millisecondsSinceEpoch}';
                            });

                            // Mostrar mensaje de éxito o error
                            if (productoProvider.errorMessage != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(productoProvider.errorMessage!),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Datos recargados exitosamente'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                ),
                const SizedBox(width: 12),
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
                onPressed: productoProvider.sucursalSeleccionada == null
                    ? null
                    : () => _showProductDialog(null),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ProductoProvider productoProvider) {
    return AnimatedOpacity(
      opacity: productoProvider.sucursalSeleccionada == null ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF222222),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                enabled: productoProvider.sucursalSeleccionada != null,
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
                onChanged: productoProvider.actualizarBusqueda,
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
              child: productoProvider.isLoadingCategorias
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
                        value: productoProvider.selectedCategory,
                        items:
                            productoProvider.categorias.map((String category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(
                              category,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: productoProvider.sucursalSeleccionada == null
                            ? null
                            : (String? value) {
                                if (value != null) {
                                  productoProvider.actualizarCategoria(value);
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
