import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/providers/admin/producto.admin.provider.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:condorsmotors/utils/sucursal_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class ProductosList extends StatelessWidget {
  final List<Sucursal> sucursales;
  final Sucursal? sucursalSeleccionada;
  final Function(Sucursal) onSucursalSelected;
  final VoidCallback onRecargarSucursales;

  const ProductosList({
    super.key,
    required this.sucursales,
    required this.sucursalSeleccionada,
    required this.onSucursalSelected,
    required this.onRecargarSucursales,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductoProvider>(
      builder: (BuildContext context, ProductoProvider productoProvider,
          Widget? child) {
        // Obtener el primer producto para mostrar la imagen
        final productos = productoProvider.productosFiltrados;
        Producto? productoConImagen = productos.isNotEmpty
            ? productos.firstWhere(
                (p) =>
                    ProductoRepository.getProductoImageUrl(p) != null &&
                    ProductoRepository.getProductoImageUrl(p)!.isNotEmpty,
                orElse: () => productos.first,
              )
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header del panel
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF222222),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Row(
                        children: <Widget>[
                          FaIcon(
                            FontAwesomeIcons.buildingUser,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'SUCURSALES',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Tooltip(
                            message: '${sucursales.length} sucursales',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D2D2D),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                sucursales.length.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.arrowsRotate,
                              color: Colors.white,
                              size: 16,
                            ),
                            onPressed: onRecargarSucursales,
                            tooltip: 'Recargar sucursales',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Lista de sucursales
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: sucursales.length,
                itemBuilder: (BuildContext context, int index) {
                  final Sucursal sucursal = sucursales[index];
                  final bool isSelected =
                      sucursalSeleccionada?.id == sucursal.id;
                  final IconData icon =
                      SucursalUtils.getIconForSucursal(sucursal);
                  final Color iconColor =
                      SucursalUtils.getColorForSucursal(sucursal);
                  final Color iconBgColor =
                      SucursalUtils.getIconBackgroundColor(sucursal);

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onSucursalSelected(sucursal),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE31E24).withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFE31E24)
                                  : Colors.white.withValues(alpha: 0.1),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              // Miniatura de imagen de producto
                              if (productoConImagen != null &&
                                  ProductoRepository.getProductoImageUrl(
                                          productoConImagen) !=
                                      null &&
                                  ProductoRepository.getProductoImageUrl(
                                          productoConImagen)!
                                      .isNotEmpty)
                                Container(
                                  width: 32,
                                  height: 32,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: Colors.black26,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      ProductoRepository.getProductoImageUrl(
                                          productoConImagen)!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.image,
                                                  color: Colors.white24,
                                                  size: 18),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 32,
                                  height: 32,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: Colors.black26,
                                  ),
                                  child: const Icon(Icons.image,
                                      color: Colors.white24, size: 18),
                                ),
                              // Icono con animación de carga
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedScale(
                                    scale: isSelected ? 1.2 : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFE31E24)
                                            : iconBgColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: FaIcon(
                                        icon,
                                        color: isSelected
                                            ? Colors.white
                                            : iconColor,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  if (isSelected &&
                                      productoProvider.isLoadingProductos)
                                    SizedBox(
                                      width: 36,
                                      height: 36,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          const Color(0xFFE31E24)
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      sucursal.nombre,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white
                                                .withValues(alpha: 0.8),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (sucursal.codigoEstablecimiento !=
                                            null)
                                          SucursalUtils
                                              .buildCodigoEstablecimiento(
                                            sucursal.codigoEstablecimiento,
                                          ),
                                        if (sucursal.sucursalCentral) ...[
                                          const SizedBox(width: 8),
                                          SucursalUtils.buildTipoSucursalBadge(
                                              sucursal),
                                        ],
                                      ],
                                    ),
                                    if (sucursal.direccion != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        sucursal.direccion!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white
                                              .withValues(alpha: 0.5),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const FaIcon(
                                  FontAwesomeIcons.circleCheck,
                                  color: Color(0xFFE31E24),
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Sucursal>('sucursales', sucursales))
      ..add(DiagnosticsProperty<Sucursal?>(
          'sucursalSeleccionada', sucursalSeleccionada))
      ..add(ObjectFlagProperty<Function(Sucursal)>.has(
          'onSucursalSelected', onSucursalSelected))
      ..add(ObjectFlagProperty<VoidCallback>.has(
          'onRecargarSucursales', onRecargarSucursales));
  }
}
