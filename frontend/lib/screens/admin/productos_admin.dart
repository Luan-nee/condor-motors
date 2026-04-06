import 'dart:convert';
import 'dart:io' as io;

import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/providers/admin/productos.admin.riverpod.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/producto_agregar_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/producto_detalle_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/productos_form.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/productos_table.dart';
import 'package:condorsmotors/screens/admin/widgets/productos_search_bar.dart';
import 'package:condorsmotors/screens/admin/widgets/slide_sucursal.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:condorsmotors/widgets/toast_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductosAdminScreen extends ConsumerStatefulWidget {
  const ProductosAdminScreen({super.key});

  @override
  ConsumerState<ProductosAdminScreen> createState() => _ProductosAdminScreenState();
}

class _ProductosAdminScreenState extends ConsumerState<ProductosAdminScreen> {
  final ValueNotifier<String> _productosKey =
      ValueNotifier<String>('productos_inicial');

  @override
  void dispose() {
    _productosKey.dispose();
    super.dispose();
  }

  void _showProductDialog(Producto? producto) {
    if (!mounted) {
      return;
    }

    final state = ref.read(productosAdminProvider);
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => ProductosFormDialogAdmin(
        producto: producto,
        sucursales: state.sucursales,
        sucursalSeleccionada: state.selectedSucursal,
        onSave: (Map<String, dynamic> productoData) async {
          setState(() {
            _productosKey.value =
                'productos_${state.selectedSucursal?.id}_refresh_${DateTime.now().millisecondsSinceEpoch}';
          });
          await ref.read(productosAdminProvider.notifier).cargarProductos(forceRefresh: true);
        },
      ),
    );
  }

  void _showProductoDetalleDialog(Producto producto) {
    final state = ref.read(productosAdminProvider);
    
    ProductoDetalleDialog.show(
      context: context,
      producto: producto,
      sucursales: state.sucursales,
      onSave: (Producto productoActualizado) async {
        setState(() {
          _productosKey.value =
              'productos_${state.selectedSucursal?.id}_refresh_${DateTime.now().millisecondsSinceEpoch}';
        });
        await ref.read(productosAdminProvider.notifier).cargarProductos(forceRefresh: true);
      },
    );
  }

  Future<void> _exportarProductos() async {
    final state = ref.read(productosAdminProvider);
    if (!mounted) {
      return;
    }

    context.showInfoToast('Exportando productos...');

    final List<int>? excelBytes = await _generarExportacionProductos(state.productosFiltrados);

    if (mounted) {
      if (excelBytes != null && excelBytes.isNotEmpty) {
        if (kIsWeb) {
          context.showSuccessToast('Reporte de productos descargado exitosamente');
        } else {
          try {
            String? directorioGuardado;
            final prefs = await SharedPreferences.getInstance();
            directorioGuardado = prefs.getString('directorioExcel');

            if (directorioGuardado == null) {
              final io.Directory directory = await getApplicationDocumentsDirectory();
              directorioGuardado = directory.path;
            }

            if (mounted) {
              context.showSuccessToast('Reporte de productos guardado exitosamente');
            }
          } catch (e) {
            if (mounted) {
              context.showErrorToast('Error al guardar archivo: $e');
            }
          }
        }
      } else {
        if (mounted) {
          context.showErrorToast(state.errorMessage ?? 'Error desconocido');
        }
      }
    }
  }

  Future<List<int>?> _generarExportacionProductos(List<Producto> productos) async {
    try {
      if (productos.isEmpty) {
        return null;
      }

      final StringBuffer csvContent = StringBuffer()
        ..writeln('SKU,Nombre,Categoría,Marca,Precio Compra,Precio Venta,Stock,Stock Mínimo,Color,Descripción');

      for (final Producto producto in productos) {
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
          (producto.descripcion ?? '').replaceAll(',', ';'),
        ].join(','));
      }

      return utf8.encode(csvContent.toString());
    } catch (e) {
      debugPrint('Error al generar exportación: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productosAdminProvider);
    final notifier = ref.read(productosAdminProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _productosKey.value =
            'productos_${state.selectedSucursal?.id}_page_${state.currentPage}_${DateTime.now().millisecondsSinceEpoch}';
      }
    });

    return Scaffold(
      body: Row(
        children: <Widget>[
          Expanded(
            flex: 75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildSearchBar(state, notifier),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      if (state.selectedSucursal == null && !state.isLoadingSucursales)
                        _buildEmptyState(state)
                      else ...[
                        Expanded(
                          child: ValueListenableBuilder<String>(
                            valueListenable: _productosKey,
                            builder: (BuildContext context, String key, Widget? child) {
                              return ProductosTable(
                                key: ValueKey<String>(key),
                                productos: state.productosFiltrados,
                                sucursales: state.sucursales,
                                onEdit: _showProductDialog,
                                onViewDetails: _showProductoDetalleDialog,
                                onSort: notifier.ordenarPor,
                                sortBy: state.sortBy,
                                sortOrder: state.order,
                                isLoading: state.isLoading,
                                onEnable: (producto) async {
                                  final currentContext = context;
                                  await ProductoAgregarDialog.show(
                                    currentContext,
                                    producto: producto,
                                    sucursalNombre: state.selectedSucursal?.nombre,
                                    onSave: (Map<String, dynamic> productoData) async {
                                      await notifier.habilitarProducto(producto.id, productoData);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Producto habilitado exitosamente'),
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
                        if (state.paginacion.totalPages > 0)
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Paginador(
                              paginacion: state.paginacion,
                              onPageChanged: notifier.cambiarPagina,
                              onPageSizeChanged: notifier.cambiarTamanioPagina,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
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
              sucursales: state.sucursales,
              sucursalSeleccionada: state.selectedSucursal,
              onSucursalSelected: notifier.seleccionarSucursal,
              onRecargarSucursales: notifier.cargarSucursales,
              isLoading: state.isLoadingSucursales,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ProductosAdminState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.isLoadingSucursales)
            const CircularProgressIndicator(color: Color(0xFFE31E24))
          else
            const FaIcon(FontAwesomeIcons.warehouse, color: Colors.white54, size: 48),
          const SizedBox(height: 16),
          Text(
            state.isLoadingSucursales
                ? 'Cargando sucursales...'
                : 'Seleccione una sucursal para ver los productos',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSearchBar(ProductosAdminState state, ProductosAdmin notifier) {
    return ProductosAdminSearchBar(
      onExport: _exportarProductos,
      onNew: () => _showProductDialog(null),
    );
  }
}
