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
  @override
  void dispose() {
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
    // Escuchamos errores de forma aislada para mostrar Toasts sin reconstruir todo
    ref.listen(productosAdminProvider.select((s) => s.errorMessage), (previous, next) {
      if (next != null && next.isNotEmpty) {
        context.showErrorToast(next);
      }
    });

    final selectedSucursal = ref.watch(productosAdminProvider.select((s) => s.selectedSucursal));
    final isLoadingSucursales = ref.watch(productosAdminProvider.select((s) => s.isLoadingSucursales));
    final totalPages = ref.watch(productosAdminProvider.select((s) => s.paginacion.totalPages));
    final isLoading = ref.watch(productosAdminProvider.select((s) => s.isLoading));
    final productos = ref.watch(productosAdminProvider.select((s) => s.productosFiltrados));
    final errorMessage = ref.watch(productosAdminProvider.select((s) => s.errorMessage));

    final notifier = ref.read(productosAdminProvider.notifier);

    // Mantenemos una key estable para evitar destruir el estado interno de la tabla durante la navegación
    final String baseKey = 'productos_${selectedSucursal?.id}_page_${ref.read(productosAdminProvider).currentPage}';

    return Scaffold(
      body: Row(
        children: <Widget>[
          Expanded(
            flex: 75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _ProductosAdminHeader(),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (selectedSucursal == null && !isLoadingSucursales) {
                        return _buildEmptyState(isLoadingSucursales);
                      }

                      if (errorMessage != null && productos.isEmpty && !isLoading) {
                        return _buildErrorState(errorMessage, notifier);
                      }

                      return Column(
                        children: <Widget>[
                          Expanded(
                            child: RepaintBoundary(
                              child: ProductosTable(
                                key: ValueKey<String>(baseKey),
                                productos: productos,
                                sucursales: ref.read(productosAdminProvider).sucursales,
                                onEdit: _showProductDialog,
                                onViewDetails: _showProductoDetalleDialog,
                                onSort: notifier.ordenarPor,
                                sortBy: ref.read(productosAdminProvider).sortBy,
                                sortOrder: ref.read(productosAdminProvider).order,
                                isLoading: isLoading,
                                onEnable: (producto) async {
                                  final currentContext = context;
                                  await ProductoAgregarDialog.show(
                                    currentContext,
                                    producto: producto,
                                    sucursalNombre: selectedSucursal?.nombre,
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
                              ),
                            ),
                          ),
                          if (totalPages > 0)
                            const _ProductosAdminPagination(),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const _ProductosAdminSidebar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isLoadingSucursales) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoadingSucursales)
            const CircularProgressIndicator(color: Color(0xFFE31E24))
          else
            const FaIcon(FontAwesomeIcons.warehouse, color: Colors.white54, size: 48),
          const SizedBox(height: 16),
          Text(
            isLoadingSucursales
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

  Widget _buildErrorState(String message, ProductosAdmin notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.circleExclamation, color: Color(0xFFE31E24), size: 48),
            const SizedBox(height: 16),
            const Text(
              'Ocurrió un problema',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => notifier.cargarProductos(forceRefresh: true),
              icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 14),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31E24),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sub-widgets para optimizar re-renders
class _ProductosAdminHeader extends ConsumerWidget {
  const _ProductosAdminHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Solo se reconstruye si el buscador o las acciones cambian
    return ProductosAdminSearchBar(
      onExport: () => context.findAncestorStateOfType<_ProductosAdminScreenState>()?._exportarProductos(),
      onNew: () => context.findAncestorStateOfType<_ProductosAdminScreenState>()?._showProductDialog(null),
    );
  }
}

class _ProductosAdminPagination extends ConsumerWidget {
  const _ProductosAdminPagination();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paginacion = ref.watch(productosAdminProvider.select((s) => s.paginacion));
    final notifier = ref.read(productosAdminProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Paginador(
        paginacion: paginacion,
        onPageChanged: notifier.cambiarPagina,
        onPageSizeChanged: notifier.cambiarTamanioPagina,
      ),
    );
  }
}

class _ProductosAdminSidebar extends ConsumerWidget {
  const _ProductosAdminSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sucursales = ref.watch(productosAdminProvider.select((s) => s.sucursales));
    final selectedSucursal = ref.watch(productosAdminProvider.select((s) => s.selectedSucursal));
    final isLoadingSucursales = ref.watch(productosAdminProvider.select((s) => s.isLoadingSucursales));
    final notifier = ref.read(productosAdminProvider.notifier);

    return Container(
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
        sucursales: sucursales,
        sucursalSeleccionada: selectedSucursal,
        onSucursalSelected: notifier.seleccionarSucursal,
        onRecargarSucursales: notifier.cargarSucursales,
        isLoading: isLoadingSucursales,
      ),
    );
  }
}
