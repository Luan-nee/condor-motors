import 'dart:convert';
// Importar dart:html solo en web
// ignore: avoid_web_libraries_in_flutter
import 'dart:io' as io;

import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/providers/admin/producto.admin.provider.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/producto_agregar_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/producto_detalle_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/productos_form.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/productos_table.dart';
import 'package:condorsmotors/screens/admin/widgets/slide_sucursal.dart';
import 'package:condorsmotors/widgets/dialogs/confirm_dialog.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importar dart:html solo en web
// ignore: avoid_web_libraries_in_flutter

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

  @override
  void initState() {
    super.initState();

    // Inicializar el provider al montar el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductoProvider>(context, listen: false).inicializar();
    });
  }

  @override
  void dispose() {
    _productosKey.dispose();
    super.dispose();
  }

  void _showProductDialog(Producto? producto) {
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
        onSave: (Map<String, dynamic> productoData) async {
          // No llamamos a _guardarProducto aquí ya que el formulario ya lo hace internamente
          // Solo actualizamos la UI para reflejar los cambios
          setState(() {
            _productosKey.value =
                'productos_${productoProvider.sucursalSeleccionada?.id}_refresh_${DateTime.now().millisecondsSinceEpoch}';
          });
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
        // Solo actualizamos la UI para reflejar los cambios
        // El formulario ya guardó los cambios internamente
        setState(() {
          _productosKey.value =
              'productos_${productoProvider.sucursalSeleccionada?.id}_refresh_${DateTime.now().millisecondsSinceEpoch}';
        });
        return Future<void>.value();
      },
    );
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

    final List<int>? excelBytes = await productoProvider.exportarProductos();

    if (mounted) {
      if (excelBytes != null && excelBytes.isNotEmpty) {
        // En web se puede descargar directamente
        if (kIsWeb) {
          // Para web, usamos la API html para descargar
          // ignore: avoid_web_libraries_in_flutter
          base64Encode(excelBytes);

          ScaffoldMessenger.of(context).showSnackBar(
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
            final String filePath =
                '$directorioGuardado/reporte_productos.xlsx';
            final io.File file = io.File(filePath);
            await file.writeAsBytes(excelBytes);

            // Abrir el archivo con la aplicación predeterminada
            // Para Windows se usa Process.run
            if (io.Platform.isWindows) {
              await io.Process.run('explorer.exe', [filePath]);
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Reporte guardado en: $filePath'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al guardar archivo: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
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
        // Actualizar la clave de la tabla cuando los productos cambian
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _productosKey.value =
                'productos_${productoProvider.sucursalSeleccionada?.id}_page_${productoProvider.currentPage}_${DateTime.now().millisecondsSinceEpoch}';
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
                    _buildHeader(productoProvider),
                    // Barra de búsqueda y filtros
                    _buildSearchBar(productoProvider),
                    // Tabla de productos
                    Expanded(
                      child: productoProvider.sucursalSeleccionada == null
                          ? Center(
                              child: Text(
                                'Seleccione una sucursal para ver los productos',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            )
                          : Column(
                              children: <Widget>[
                                // Tabla de productos
                                Expanded(
                                  child: ValueListenableBuilder<String>(
                                    valueListenable: _productosKey,
                                    builder: (BuildContext context, String key,
                                        Widget? child) {
                                      return ProductosTable(
                                        key: ValueKey<String>(key),
                                        productos:
                                            productoProvider.productosFiltrados,
                                        sucursales: productoProvider.sucursales,
                                        onEdit: _showProductDialog,
                                        onDelete: _eliminarProducto,
                                        onViewDetails:
                                            _showProductoDetalleDialog,
                                        onSort: productoProvider.ordenarPor,
                                        sortBy: productoProvider.sortBy,
                                        sortOrder: productoProvider.order,
                                        isLoading:
                                            productoProvider.isLoadingProductos,
                                        onEnable: (producto) async {
                                          await ProductoAgregarDialog.show(
                                            context,
                                            producto: producto,
                                            onSave: (Map<String, dynamic>
                                                productoData) async {
                                              await productoProvider
                                                  .habilitarProducto(
                                                      producto, productoData);
                                              // Limpiar caché de productos para la sucursal actual
                                              final sucursalId =
                                                  productoProvider
                                                      .sucursalSeleccionada?.id
                                                      .toString();
                                              if (sucursalId != null) {
                                                productoProvider
                                                    .invalidateCacheSucursal(
                                                        sucursalId);
                                              }
                                              if (!mounted) return;
                                              setState(() {
                                                _productosKey.value =
                                                    'productos_${productoProvider.sucursalSeleccionada?.id}_refresh_${DateTime.now().millisecondsSinceEpoch}';
                                              });
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Producto habilitado exitosamente'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),

                                // Paginador
                                if (productoProvider.paginacion.totalPages > 0)
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Paginador(
                                      paginacion: productoProvider.paginacion,
                                      onPageChanged:
                                          productoProvider.cambiarPagina,
                                      onPageSizeChanged:
                                          productoProvider.cambiarTamanioPagina,
                                      backgroundColor: const Color(0xFF2D2D2D),
                                      textColor: Colors.white,
                                      accentColor: const Color(0xFFE31E24),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),

              // Panel lateral de sucursales
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _drawerOpen ? 350 : 0,
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
