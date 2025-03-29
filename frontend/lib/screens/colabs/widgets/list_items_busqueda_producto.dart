import 'package:condorsmotors/models/color.model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget que representa un ítem individual de producto en la lista de búsqueda
class ListItemBusquedaProducto extends StatelessWidget {
  /// El producto a mostrar
  final Map<String, dynamic> producto;
  
  /// Callback cuando se selecciona el producto
  final Function(Map<String, dynamic>) onProductoSeleccionado;
  
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
    // Verificar las promociones del producto
    final bool enLiquidacion = producto['enLiquidacion'] ?? false;
    final bool tienePromocionGratis = producto['tienePromocionGratis'] ?? false;
    final bool tieneDescuentoPorcentual = producto['tieneDescuentoPorcentual'] ?? false;
    final bool tieneStock = producto['stock'] > 0;
    
    // Verificar si el producto tiene alguna promoción
    final bool tienePromocion = enLiquidacion || tienePromocionGratis || tieneDescuentoPorcentual;

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
              _buildProductIcon(tienePromocion, tieneStock, tienePromocionGratis, tieneDescuentoPorcentual),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: _buildProductInfo(tienePromocion, enLiquidacion, tienePromocionGratis, tieneDescuentoPorcentual),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductIcon(bool tienePromocion, bool tieneStock, bool tienePromocionGratis, bool tieneDescuentoPorcentual) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: <Widget>[
        Container(
          width: isMobile ? 50 : 60,
          height: isMobile ? 50 : 60,
          decoration: BoxDecoration(
            color: darkBackground,
            borderRadius: BorderRadius.circular(10),
            border: tienePromocion 
                ? Border.all(
                    color: _getPromocionColor(tienePromocionGratis, tieneDescuentoPorcentual),
                    width: 2,
                  )
                : null,
          ),
          child: Center(
            child: FaIcon(
              FontAwesomeIcons.box,
              size: isMobile ? 22 : 26,
              color: tieneStock
                  ? (tienePromocion ? Colors.amber : Colors.green)
                  : Colors.red,
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
                  color: Colors.black.withOpacity(0.3),
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

  Widget _buildProductInfo(bool tienePromocion, bool enLiquidacion, bool tienePromocionGratis, bool tieneDescuentoPorcentual) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Pasar flags de promoción a _buildProductHeader
        _buildProductHeader(enLiquidacion, tienePromocionGratis, tieneDescuentoPorcentual),
        const SizedBox(height: 8),
        _buildProductDetails(),
        const SizedBox(height: 8),
        _buildCategoryAndColor(),
        const SizedBox(height: 10),
        _buildPrice(enLiquidacion),
        if (tienePromocionGratis || tieneDescuentoPorcentual) ...<Widget>[ // Ya no incluye enLiquidacion aquí porque se indica en el nombre
          const SizedBox(height: 10),
          _buildPromotionChips(tienePromocionGratis, tieneDescuentoPorcentual), // Ya no necesita enLiquidacion
        ],
      ],
    );
  }

  // Modificar firma y lógica de estilo
  Widget _buildProductHeader(bool enLiquidacion, bool tienePromocionGratis, bool tieneDescuentoPorcentual) {
    Color nombreColor = Colors.white; // Color por defecto
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
            producto['nombre'],
            // Aplicar estilo condicional para cualquier promoción
            style: TextStyle(
              fontWeight: FontWeight.bold, // Mantener negrita siempre
              fontSize: isMobile ? 16 : 18,
              color: nombreColor, // Usar el color determinado
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildDetailsButton(),
      ],
    );
  }

  Widget _buildDetailsButton() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      width: isMobile ? 38 : 42,
      height: isMobile ? 38 : 42,
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(
          Icons.search,
          color: Colors.white,
          size: 22,
        ),
        padding: EdgeInsets.zero,
        onPressed: () => onProductoSeleccionado(producto),
        tooltip: 'Ver detalle',
      ),
    );
  }

  Widget _buildProductDetails() {
    final bool tieneStock = producto['stock'] > 0;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Código: ${producto['codigo']}',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Stock: ${producto['stock']}',
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
        if (producto['categoria'] != null)
          Expanded(
            child: Text(
              'Categoría: ${producto['categoria']}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: _isCategoriaHighlighted() ? FontWeight.bold : FontWeight.w500,
                color: _isCategoriaHighlighted() ? Colors.blue : Colors.white60,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const SizedBox(width: 8),
        if (producto['color'] != null)
          _buildColorInfo(producto['color']),
      ],
    );
  }

  Widget _buildPrice(bool enLiquidacion) {
    return Row(
      children: <Widget>[
        if (enLiquidacion && producto['precioLiquidacion'] != null) ...<Widget>[
          Text(
            'S/ ${producto['precio'].toStringAsFixed(2)}',
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
                'S/ ${producto['precioLiquidacion'].toStringAsFixed(2)}',
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
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '-${_calcularDescuentoPorcentaje(producto['precio'], producto['precioLiquidacion'])}%',
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
            'S/ ${producto['precio'].toStringAsFixed(2)}',
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

  // Corregir firma: eliminar el parámetro enLiquidacion que ya no se usa aquí
  Widget _buildPromotionChips(bool tienePromocionGratis, bool tieneDescuentoPorcentual) {
    // Chip de liquidación eliminado de aquí
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        if (tienePromocionGratis)
          _buildPromoChip(
            'Lleva ${producto['cantidadMinima']}, paga ${producto['cantidadMinima'] - producto['cantidadGratis']}',
            Colors.green
          ),
        if (tieneDescuentoPorcentual)
          _buildPromoChip(
            '${producto['descuentoPorcentaje']}% x ${producto['cantidadMinima']}+',
            Colors.purple
          ),
        // El chip de liquidación ya no se muestra aquí
      ],
    );
  }

  Widget _buildPromoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
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
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 2,
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.5)),
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
  int _calcularDescuentoPorcentaje(double precioOriginal, double precioDescuento) {
    if (precioOriginal <= 0) {
      return 0;
    }
    final double descuento = ((precioOriginal - precioDescuento) / precioOriginal) * 100;
    return descuento.round();
  }

  Color _getPromocionColor(bool tienePromocionGratis, bool tieneDescuentoPorcentual) {
    if (tienePromocionGratis) {
      return Colors.green;
    }
    if (tieneDescuentoPorcentual) {
      return Colors.purple;
    }
    return Colors.amber;
  }

  bool _isCategoriaHighlighted() {
    return filtroCategoria != 'Todos' && 
           producto['categoria'].toString().toLowerCase() == filtroCategoria.toLowerCase();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Map<String, dynamic>>('producto', producto))
      ..add(ObjectFlagProperty<Function(Map<String, dynamic>)>.has('onProductoSeleccionado', onProductoSeleccionado))
      ..add(IterableProperty<ColorApp>('colores', colores))
      ..add(ColorProperty('darkBackground', darkBackground))
      ..add(ColorProperty('darkSurface', darkSurface))
      ..add(StringProperty('filtroCategoria', filtroCategoria))
      ..add(DiagnosticsProperty<bool>('isMobile', isMobile));
  }
}
