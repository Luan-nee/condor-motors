import 'dart:convert';
import 'dart:io' as io;

import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/providers/admin/productos.admin.riverpod.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/producto_agregar_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/producto_detalle_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/productos_form.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/productos_table.dart';
import 'package:condorsmotors/screens/admin/widgets/productos_search_bar.dart';
import 'package:condorsmotors/theme/apptheme.dart';
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
  ConsumerState<ProductosAdminScreen> createState() =>
      _ProductosAdminScreenState();
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
          await ref
              .read(productosAdminProvider.notifier)
              .cargarProductos(forceRefresh: true);
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
        await ref
            .read(productosAdminProvider.notifier)
            .cargarProductos(forceRefresh: true);
      },
    );
  }

  Future<void> _exportarProductos() async {
    final state = ref.read(productosAdminProvider);
    if (!mounted) {
      return;
    }

    context.showInfoToast('Exportando productos...');

    final List<int>? excelBytes = await _generarExportacionProductos(
      state.productosFiltrados,
    );

    if (mounted) {
      if (excelBytes != null && excelBytes.isNotEmpty) {
        if (kIsWeb) {
          context.showSuccessToast(
            'Reporte de productos descargado exitosamente',
          );
        } else {
          try {
            String? directorioGuardado;
            final prefs = await SharedPreferences.getInstance();
            directorioGuardado = prefs.getString('directorioExcel');

            if (directorioGuardado == null) {
              final io.Directory directory =
                  await getApplicationDocumentsDirectory();
              directorioGuardado = directory.path;
            }

            if (mounted) {
              context.showSuccessToast(
                'Reporte de productos guardado exitosamente',
              );
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

  Future<List<int>?> _generarExportacionProductos(
    List<Producto> productos,
  ) async {
    try {
      if (productos.isEmpty) {
        return null;
      }

      final StringBuffer csvContent = StringBuffer()
        ..writeln(
          'SKU,Nombre,Categoría,Marca,Precio Compra,Precio Venta,Stock,Stock Mínimo,Color,Descripción',
        );

      for (final Producto producto in productos) {
        csvContent.writeln(
          [
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
          ].join(','),
        );
      }

      return utf8.encode(csvContent.toString());
    } catch (e) {
      debugPrint('Error al generar exportación: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ProductosAdminHeader(),
          Expanded(
            child: RepaintBoundary(
              child: _ProductosAdminTable(),
            ),
          ),
          _ProductosAdminPagination(),
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
            const FaIcon(
              FontAwesomeIcons.circleExclamation,
              color: AppTheme.primaryColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ocurrió un problema',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                backgroundColor: AppTheme.primaryColor,
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
    return ProductosAdminSearchBar(
      onExport: () => context
          .findAncestorStateOfType<_ProductosAdminScreenState>()
          ?._exportarProductos(),
      onNew: () => context
          .findAncestorStateOfType<_ProductosAdminScreenState>()
          ?._showProductDialog(null),
    );
  }
}

class _ProductosAdminTable extends ConsumerWidget {
  const _ProductosAdminTable();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(productosAdminProvider.select((s) => s.errorMessage), (
      previous,
      next,
    ) {
      if (next != null && next.isNotEmpty) {
        context.showErrorToast(next);
      }
    });

    final selectedSucursal = ref.watch(
      productosAdminProvider.select((s) => s.selectedSucursal),
    );
    final isLoading = ref.watch(
      productosAdminProvider.select((s) => s.isLoading),
    );
    final productos = ref.watch(
      productosAdminProvider.select((s) => s.productosFiltrados),
    );
    final errorMessage = ref.watch(
      productosAdminProvider.select((s) => s.errorMessage),
    );
    final sortBy = ref.watch(productosAdminProvider.select((s) => s.sortBy));
    final sortOrder = ref.watch(productosAdminProvider.select((s) => s.order));

    final notifier = ref.read(productosAdminProvider.notifier);
    final parentState =
        context.findAncestorStateOfType<_ProductosAdminScreenState>();

    if (errorMessage != null && productos.isEmpty && !isLoading) {
      return parentState?._buildErrorState(errorMessage, notifier) ??
          const SizedBox.shrink();
    }

    final String baseKey =
        'productos_${(isLoading || selectedSucursal == null) ? "loading" : selectedSucursal.id}_page_${ref.read(productosAdminProvider).currentPage}';

    return ProductosTable(
      key: ValueKey<String>(baseKey),
      productos: productos,
      sucursales: ref.read(productosAdminProvider).sucursales,
      onEdit: (p) => parentState?._showProductDialog(p),
      onViewDetails: (p) => parentState?._showProductoDetalleDialog(p),
      onSort: notifier.ordenarPor,
      sortBy: sortBy,
      sortOrder: sortOrder,
      isLoading: isLoading || selectedSucursal == null,
      onEnable: (producto) async {
        final currentContext = context;
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        await ProductoAgregarDialog.show(
          currentContext,
          producto: producto,
          sucursalNombre: selectedSucursal?.nombre ?? '',
          onSave: (Map<String, dynamic> productoData) async {
            await notifier.habilitarProducto(
              producto.id,
              productoData,
            );
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text(
                  'Producto habilitado exitosamente',
                ),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductosAdminPagination extends ConsumerWidget {
  const _ProductosAdminPagination();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paginacion = ref.watch(
      productosAdminProvider.select((s) => s.paginacion),
    );
    final notifier = ref.read(productosAdminProvider.notifier);

    if (paginacion.totalPages == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Paginador(
          paginacion: paginacion,
          onPageChanged: notifier.cambiarPagina,
          onPageSizeChanged: notifier.cambiarTamanioPagina,
          backgroundColor: AppTheme.surfaceColor,
          textColor: Colors.white,
          accentColor: AppTheme.primaryColor,
        ),
      ),
    );
  }
}


