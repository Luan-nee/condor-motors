import 'package:condorsmotors/models/color.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/screens/colabs/widgets/list_items_busqueda_producto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget que muestra una lista de productos con su información detallada
///
/// Este widget es parte de la refactorización de BusquedaProductoWidget
/// y se encarga específicamente de la visualización de los productos.
class ListBusquedaProducto extends StatelessWidget {
  /// Lista de productos a mostrar (ya filtrados)
  final List<Producto> productos;

  /// Callback que se llama cuando un producto es seleccionado
  final Function(Producto) onProductoSeleccionado;

  /// Indica si los productos están cargando
  final bool isLoading;

  /// Filtro de categoría actual (para mostrar mensaje apropiado cuando no hay resultados)
  final String filtroCategoria;

  /// Lista de colores disponibles para mostrar la información del color
  final List<ColorApp> colores;

  /// Colores para el tema oscuro
  final Color darkBackground;
  final Color darkSurface;

  /// Mensaje personalizado cuando no hay productos
  final String? mensajeVacio;

  /// Callback opcional para cuando se quiere restablecer el filtro
  final VoidCallback? onRestablecerFiltro;

  /// Indica si hay algún filtro activo (categoría, búsqueda o promoción)
  final bool tieneAlgunFiltroActivo;

  const ListBusquedaProducto({
    super.key,
    required this.productos,
    required this.onProductoSeleccionado,
    required this.isLoading,
    required this.filtroCategoria,
    required this.colores,
    required this.darkBackground,
    required this.darkSurface,
    this.mensajeVacio,
    this.onRestablecerFiltro,
    this.tieneAlgunFiltroActivo = false,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    // Si está cargando, mostrar un indicador de progreso
    if (isLoading) {
      return _buildLoadingIndicator();
    }

    // Si no hay productos filtrados, mostrar un mensaje con detalles
    if (productos.isEmpty) {
      return _buildEmptyState();
    }

    // Mostrar la lista de productos con todos los detalles
    return ListView.builder(
      itemCount: productos.length,
      itemBuilder: (BuildContext context, int index) {
        final Producto producto = productos[index];

        // Depuración: Mostrar la categoría del producto si estamos filtrando
        if (filtroCategoria != 'Todos') {
          final String categoriaProducto = producto.categoria;
          debugPrint(
              '�� Producto #$index - Categoría: "$categoriaProducto" (Filtro: "$filtroCategoria")');
        }

        return RepaintBoundary(
          key: ValueKey('producto_${producto.id}'),
          child: ListItemBusquedaProducto(
            producto: producto,
            onProductoSeleccionado: onProductoSeleccionado,
            colores: colores,
            darkBackground: darkBackground,
            darkSurface: darkSurface,
            filtroCategoria: filtroCategoria,
            isMobile: isMobile,
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Cargando productos...',
            style: TextStyle(color: Colors.white70),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    // Depuración: Mostrar el filtro de categoría actual en la consola
    debugPrint('No hay productos para mostrar con filtro: "$filtroCategoria"');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            filtroCategoria == 'Todos'
                ? Icons.search_off
                : Icons.category_outlined,
            size: 48,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 16),
          const Text(
            'No se encontraron productos',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            filtroCategoria != 'Todos'
                ? 'No hay productos en la categoría "$filtroCategoria"'
                : mensajeVacio ?? 'Intenta con otra búsqueda o filtro',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (tieneAlgunFiltroActivo) _buildResetFiltersButton(),
        ],
      ),
    );
  }

  Widget _buildResetFiltersButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.restart_alt, size: 20),
        label: const Text(
          'Restablecer todos los filtros',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onRestablecerFiltro,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Producto>('productos', productos))
      ..add(ObjectFlagProperty<Function(Producto)>.has(
          'onProductoSeleccionado', onProductoSeleccionado))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(StringProperty('filtroCategoria', filtroCategoria))
      ..add(IterableProperty<ColorApp>('colores', colores))
      ..add(ColorProperty('darkBackground', darkBackground))
      ..add(ColorProperty('darkSurface', darkSurface))
      ..add(StringProperty('mensajeVacio', mensajeVacio))
      ..add(ObjectFlagProperty<VoidCallback?>.has(
          'onRestablecerFiltro', onRestablecerFiltro))
      ..add(DiagnosticsProperty<bool>(
          'tieneAlgunFiltroActivo', tieneAlgunFiltroActivo));
  }
}
