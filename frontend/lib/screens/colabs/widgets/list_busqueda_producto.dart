import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/color.model.dart';

/// Widget que muestra una lista de productos con su información detallada
/// 
/// Este widget es parte de la refactorización de BusquedaProductoWidget
/// y se encarga específicamente de la visualización de los productos.
class ListBusquedaProducto extends StatelessWidget {
  /// Lista de productos a mostrar (ya filtrados)
  final List<Map<String, dynamic>> productos;
  
  /// Callback que se llama cuando un producto es seleccionado
  final Function(Map<String, dynamic>) onProductoSeleccionado;
  
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    // Si está cargando, mostrar un indicador de progreso
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
    
    // Si no hay productos filtrados, mostrar un mensaje con detalles
    if (productos.isEmpty) {
      // Depuración: Mostrar el filtro de categoría actual en la consola
      debugPrint('🔍 No hay productos para mostrar con filtro: "$filtroCategoria"');
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filtroCategoria == 'Todos' ? Icons.search_off : Icons.category_outlined,
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
            // Añadir botón para restablecer los filtros cuando tenemos un filtro aplicado
            if (tieneAlgunFiltroActivo)
              Padding(
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
                    shadowColor: Colors.black.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onRestablecerFiltro,
                ),
              ),
          ],
        ),
      );
    }
    
    // Mostrar la lista de productos con todos los detalles
    return ListView.builder(
      itemCount: productos.length,
      itemBuilder: (context, index) {
        final producto = productos[index];
        
        // Verificar las promociones del producto
        final bool enLiquidacion = producto['enLiquidacion'] ?? false;
        final bool tienePromocionGratis = producto['tienePromocionGratis'] ?? false;
        final bool tieneDescuentoPorcentual = producto['tieneDescuentoPorcentual'] ?? false;
        final bool tieneStock = producto['stock'] > 0;
        
        // Verificar si el producto tiene alguna promoción
        final bool tienePromocion = enLiquidacion || tienePromocionGratis || tieneDescuentoPorcentual;
        
        // Depuración: Mostrar la categoría del producto si estamos filtrando
        if (filtroCategoria != 'Todos') {
          final categoriaProducto = producto['categoria']?.toString() ?? 'sin categoría';
          debugPrint('📦 Producto #$index - Categoría: "$categoriaProducto" (Filtro: "$filtroCategoria")');
        }
        
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icono con indicador de stock
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: isMobile ? 50 : 60,
                        height: isMobile ? 50 : 60,
                        decoration: BoxDecoration(
                          color: darkBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: tienePromocion 
                              ? Border.all(
                                  color: enLiquidacion 
                                      ? Colors.amber 
                                      : (tienePromocionGratis 
                                          ? Colors.green 
                                          : Colors.purple),
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
                            color: tienePromocionGratis
                              ? Colors.green
                              : Colors.purple,
                            shape: BoxShape.circle,
                            boxShadow: [
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
                  ),
                  
                  SizedBox(width: isMobile ? 12 : 16),
                  
                  // Información del producto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre del producto con botón de detalles a la derecha
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nombre del producto (ocupando espacio disponible)
                            Expanded(
                              child: Text(
                                producto['nombre'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 16 : 18,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            
                            // Botón de detalles (ahora alineado con el nombre)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              width: isMobile ? 38 : 42,
                              height: isMobile ? 38 : 42,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade700,
                                shape: BoxShape.circle,
                                boxShadow: [
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
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Código y stock
                        Row(
                          children: [
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
                                color: tieneStock
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Categoría y color (información adicional)
                        Row(
                          children: [
                            if (producto['categoria'] != null) 
                              Expanded(
                                child: Text(
                                  'Categoría: ${producto['categoria']}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: filtroCategoria != 'Todos' && 
                                        producto['categoria'].toString().toLowerCase() == filtroCategoria.toLowerCase()
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: filtroCategoria != 'Todos' && 
                                        producto['categoria'].toString().toLowerCase() == filtroCategoria.toLowerCase()
                                        ? Colors.blue
                                        : Colors.white60,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            
                            const SizedBox(width: 8),
                            
                            // Mostrar información del color
                            if (producto['color'] != null)
                              _buildColorInfo(producto['color']),
                          ],
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // Precio con descuentos
                        Row(
                          children: [
                            if (enLiquidacion && producto['precioLiquidacion'] != null) ...[
                              Text(
                                'S/ ${producto['precio'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'S/ ${producto['precioLiquidacion'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 18 : 20,
                                ),
                              ),
                            ] else ...[
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
                        ),
                        
                        // Chips de promociones
                        if (tienePromocionGratis || tieneDescuentoPorcentual) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
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
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Construye un chip para mostrar promociones
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
  
  /// Construye la visualización de la información del color
  Widget _buildColorInfo(String? colorNombre) {
    if (colorNombre == null || colorNombre.isEmpty) {
      return const SizedBox.shrink(); // Sin color
    }
    
    // Buscar el color por nombre
    ColorApp? color;
    for (var c in colores) {
      if (c.nombre.toLowerCase() == colorNombre.toString().toLowerCase()) {
        color = c;
        break;
      }
    }
    
    if (color == null) {
      // Si no encontramos una coincidencia exacta, mostramos solo el nombre
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
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.toColor(),
            shape: BoxShape.circle,
            boxShadow: [
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
}
