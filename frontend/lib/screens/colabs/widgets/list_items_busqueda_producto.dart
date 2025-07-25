import 'package:condorsmotors/models/color.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:condorsmotors/utils/busqueda_producto_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget que representa un ítem individual de producto en la lista de búsqueda
class ListItemBusquedaProducto extends StatelessWidget {
  /// El producto a mostrar
  final Producto producto;

  /// Callback cuando se selecciona el producto
  final Function(Producto) onProductoSeleccionado;

  /// Lista de colores disponibles para mostrar la información del color
  final List<ColorApp> colores;

  /// Colores para el tema oscuro
  final Color darkBackground;
  final Color darkSurface;

  /// Filtro de categoría actual (para resaltar si coincide)
  final String filtroCategoria;

  /// Si estamos en modo móvil
  final bool isMobile;

  const ListItemBusquedaProducto({
    super.key,
    required this.producto,
    required this.onProductoSeleccionado,
    required this.colores,
    required this.darkBackground,
    required this.darkSurface,
    required this.filtroCategoria,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    // Usar directamente el modelo Producto
    debugPrint('Producto \\${producto.id} pathFoto: \\${producto.pathFoto}');
    final bool enLiquidacion = producto.estaEnLiquidacion;
    final bool tienePromocionGratis = producto.tienePromocionGratis;
    final bool tieneDescuentoPorcentual = producto.tieneDescuentoPorcentual;
    final bool tieneStock = producto.stock > 0;
    final bool tienePromocion = producto.tienePromocion;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => onProductoSeleccionado(producto),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Row(
            children: <Widget>[
              _buildProductIcon(context, tienePromocion, tieneStock,
                  tienePromocionGratis, tieneDescuentoPorcentual, producto),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: _buildProductInfo(tienePromocion, enLiquidacion,
                    tienePromocionGratis, tieneDescuentoPorcentual),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductIcon(
      BuildContext context,
      bool tienePromocion,
      bool tieneStock,
      bool tienePromocionGratis,
      bool tieneDescuentoPorcentual,
      Producto producto) {
    final String url = ProductoRepository.getProductoImageUrl(producto) ?? '';
    debugPrint('URL imagen (repo) producto \\${producto.id}: \\$url');
    return Stack(
      alignment: Alignment.bottomRight,
      children: <Widget>[
        GestureDetector(
          onTap: () => _mostrarDetallesProducto(context),
          child: Hero(
            tag: 'producto_${producto.id}',
            child: Container(
              width: isMobile ? 50 : 60,
              height: isMobile ? 50 : 60,
              decoration: BoxDecoration(
                color: darkBackground,
                borderRadius: BorderRadius.circular(10),
                border: tienePromocion
                    ? Border.all(
                        color: BusquedaProductoUtils.getPromocionColor(
                          tienePromocionGratis: tienePromocionGratis,
                          tieneDescuentoPorcentual: tieneDescuentoPorcentual,
                        ),
                        width: 2,
                      )
                    : null,
              ),
              child: url.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey, size: 32),
                        ),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) {
                            return child;
                          }
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: FaIcon(
                        FontAwesomeIcons.box,
                        size: isMobile ? 22 : 26,
                        color: tieneStock
                            ? (tienePromocion ? Colors.amber : Colors.green)
                            : Colors.red,
                      ),
                    ),
            ),
          ),
        ),
        if (tienePromocionGratis || tieneDescuentoPorcentual)
          Container(
            padding: EdgeInsets.all(isMobile ? 4 : 5),
            decoration: BoxDecoration(
              color: tienePromocionGratis ? Colors.green : Colors.purple,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              tienePromocionGratis ? Icons.card_giftcard : Icons.percent,
              size: isMobile ? 12 : 14,
              color: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildProductInfo(bool tienePromocion, bool enLiquidacion,
      bool tienePromocionGratis, bool tieneDescuentoPorcentual) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Pasar flags de promoción a _buildProductHeader
        _buildProductHeader(
            enLiquidacion, tienePromocionGratis, tieneDescuentoPorcentual),
        const SizedBox(height: 8),
        _buildProductDetails(),
        const SizedBox(height: 8),
        _buildCategoryAndColor(),
        const SizedBox(height: 10),
        _buildPrice(enLiquidacion),
        if (tienePromocionGratis || tieneDescuentoPorcentual) ...<Widget>[
          const SizedBox(height: 10),
          _buildPromotionChips(tienePromocionGratis, tieneDescuentoPorcentual),
        ],
      ],
    );
  }

  Widget _buildProductHeader(bool enLiquidacion, bool tienePromocionGratis,
      bool tieneDescuentoPorcentual) {
    Color nombreColor = Colors.white;
    if (enLiquidacion) {
      nombreColor = Colors.amber;
    } else if (tienePromocionGratis) {
      nombreColor = Colors.green;
    } else if (tieneDescuentoPorcentual) {
      nombreColor = Colors.purple;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            producto.nombre,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 16 : 18,
              color: nombreColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _mostrarDetallesProducto(BuildContext context) {
    final bool enLiquidacion = producto.estaEnLiquidacion;
    final bool tienePromocionGratis = producto.tienePromocionGratis;
    final bool tieneDescuentoPorcentual = producto.tieneDescuentoPorcentual;
    final bool tieneStock = producto.stock > 0;
    final bool tienePromocion = producto.tienePromocion;
    final Color colorPromocion = BusquedaProductoUtils.getPromocionColor(
      tienePromocionGratis: tienePromocionGratis,
      tieneDescuentoPorcentual: tieneDescuentoPorcentual,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Encabezado con icono y nombre
              Row(
                children: <Widget>[
                  Hero(
                    tag: 'producto_${producto.id}',
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: darkBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorPromocion,
                          width: 2,
                        ),
                      ),
                      child: (() {
                        final String url =
                            ProductoRepository.getProductoImageUrl(producto) ??
                                '';
                        if (url.isNotEmpty) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              url,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image,
                                    color: Colors.grey, size: 32),
                              ),
                            ),
                          );
                        } else {
                          return Center(
                            child: FaIcon(
                              FontAwesomeIcons.box,
                              size: 28,
                              color: tieneStock
                                  ? (tienePromocion
                                      ? Colors.amber
                                      : Colors.green)
                                  : Colors.red,
                            ),
                          );
                        }
                      })(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          producto.nombre,
                          style: TextStyle(
                            color: colorPromocion,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Código: ${producto.sku}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Información de stock y precio
              _buildDetalleItem(
                icon: Icons.inventory_2,
                color: tieneStock ? Colors.green : Colors.red,
                titulo: 'Stock Disponible',
                subtitulo: '${producto.stock} unidades',
                small: true,
              ),
              const SizedBox(height: 16),

              _buildDetalleItem(
                icon: Icons.attach_money,
                color: Colors.green,
                titulo: 'Precio Regular',
                subtitulo: 'S/ ${producto.precioVenta}',
              ),

              if (enLiquidacion) ...[
                const SizedBox(height: 16),
                _buildDetalleItem(
                  icon: Icons.local_fire_department,
                  color: Colors.amber,
                  titulo: 'Precio Liquidación',
                  subtitulo: 'S/ ${producto.precioOferta ?? ''}',
                ),
              ],

              // Información de promociones
              if (tienePromocionGratis) ...[
                const SizedBox(height: 16),
                _buildDetalleItem(
                  icon: Icons.card_giftcard,
                  color: Colors.green,
                  titulo: 'Promoción "Lleva y Paga"',
                  subtitulo:
                      'Lleva ${producto.cantidadMinimaDescuento ?? ''} y paga ${(producto.cantidadMinimaDescuento ?? 0) - (producto.cantidadGratisDescuento ?? 0)}',
                ),
              ],

              if (tieneDescuentoPorcentual) ...[
                const SizedBox(height: 16),
                _buildDetalleItem(
                  icon: Icons.percent,
                  color: Colors.purple,
                  titulo: 'Descuento por Cantidad',
                  subtitulo:
                      '${producto.porcentajeDescuento ?? ''}% al llevar ${producto.cantidadMinimaDescuento ?? ''} o más',
                ),
              ],

              const SizedBox(height: 16),
              // Categoría y marca
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildDetalleItem(
                      icon: Icons.category,
                      color: Colors.blue,
                      titulo: 'Categoría',
                      subtitulo: producto.categoria,
                      small: true,
                    ),
                  ),
                  if (producto.marca.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetalleItem(
                        icon: Icons.business,
                        color: Colors.orange,
                        titulo: 'Marca',
                        subtitulo: producto.marca,
                        small: true,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),
              // Botón de seleccionar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onProductoSeleccionado(producto);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Seleccionar Producto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPromocion,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetalleItem({
    required IconData icon,
    required Color color,
    required String titulo,
    required String subtitulo,
    bool small = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: small ? 16 : 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                titulo,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: small ? 12 : 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitulo,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: small ? 13 : 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetails() {
    final bool tieneStock = producto.stock > 0;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Código: ${producto.sku}',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Stock: ${producto.stock}',
          style: TextStyle(
            fontSize: 13,
            color: tieneStock ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryAndColor() {
    return Row(
      children: <Widget>[
        if (producto.categoria.isNotEmpty)
          Expanded(
            child: Text(
              'Categoría: ${producto.categoria}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: _isCategoriaHighlighted()
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: _isCategoriaHighlighted() ? Colors.blue : Colors.white60,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const SizedBox(width: 8),
        if (producto.color != null) _buildColorInfo(producto.color),
      ],
    );
  }

  Widget _buildPrice(bool enLiquidacion) {
    return Row(
      children: <Widget>[
        if (enLiquidacion && producto.precioOferta != null) ...<Widget>[
          Text(
            'S/ ${producto.precioVenta.toStringAsFixed(2)}',
            style: const TextStyle(
              decoration: TextDecoration.lineThrough,
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          Row(
            children: <Widget>[
              Text(
                'S/ ${producto.precioOferta!.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 18 : 20,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '-${_calcularDescuentoPorcentaje(producto.precioVenta, producto.precioOferta!)}%',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ] else ...<Widget>[
          Text(
            'S/ ${producto.precioVenta.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 18 : 20,
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPromotionChips(
      bool tienePromocionGratis, bool tieneDescuentoPorcentual) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        if (tienePromocionGratis)
          _buildPromoChip(
              'Lleva ${producto.cantidadMinimaDescuento ?? ''}, paga ${(producto.cantidadMinimaDescuento ?? 0) - (producto.cantidadGratisDescuento ?? 0)}',
              Colors.green),
        if (tieneDescuentoPorcentual)
          _buildPromoChip(
              '${producto.porcentajeDescuento ?? ''}% x ${producto.cantidadMinimaDescuento ?? ''}+',
              Colors.purple),
      ],
    );
  }

  Widget _buildPromoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildColorInfo(String? colorNombre) {
    if (colorNombre == null || colorNombre.isEmpty) {
      return const SizedBox.shrink();
    }

    ColorApp? color;
    for (ColorApp c in colores) {
      if (c.nombre.toLowerCase() == colorNombre.toString().toLowerCase()) {
        color = c;
        break;
      }
    }

    if (color == null) {
      return Text(
        'Color: $colorNombre',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
        ),
      );
    }

    return Row(
      children: <Widget>[
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.toColor(),
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 2,
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          color.nombre,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// Calcula el porcentaje de descuento entre dos precios
  int _calcularDescuentoPorcentaje(
      double precioOriginal, double precioDescuento) {
    if (precioOriginal <= 0) {
      return 0;
    }
    final double descuento =
        ((precioOriginal - precioDescuento) / precioOriginal) * 100;
    return descuento.round();
  }

  bool _isCategoriaHighlighted() {
    return filtroCategoria != 'Todos' &&
        producto.categoria.toLowerCase() == filtroCategoria.toLowerCase();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Producto>('producto', producto))
      ..add(ObjectFlagProperty<Function(Producto)>.has(
          'onProductoSeleccionado', onProductoSeleccionado))
      ..add(IterableProperty<ColorApp>('colores', colores))
      ..add(ColorProperty('darkBackground', darkBackground))
      ..add(ColorProperty('darkSurface', darkSurface))
      ..add(StringProperty('filtroCategoria', filtroCategoria))
      ..add(DiagnosticsProperty<bool>('isMobile', isMobile));
  }
}
