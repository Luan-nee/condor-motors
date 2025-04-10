import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/providers/admin/producto.admin.provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    // Escuchar cambios en el provider
    return Consumer<ProductoProvider>(
      builder: (BuildContext context, ProductoProvider productoProvider,
          Widget? child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Sucursales',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      if (productoProvider.isLoadingProductos)
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 20,
                          height: 20,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFE31E24)),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          // Recargar tanto sucursales como productos
                          onRecargarSucursales();
                          if (sucursalSeleccionada != null) {
                            productoProvider.recargarDatos();
                          }
                        },
                        tooltip: 'Recargar datos',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sucursales.length,
                itemBuilder: (BuildContext context, int index) {
                  final Sucursal sucursal = sucursales[index];
                  final bool isSelected =
                      sucursalSeleccionada?.id == sucursal.id;

                  // Obtener conteo de productos para esta sucursal si está seleccionada
                  final String productCount = isSelected &&
                          productoProvider.paginatedProductos != null
                      ? '${productoProvider.paginatedProductos!.totalItems} productos'
                      : '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE31E24).withOpacity(0.1)
                          : const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFE31E24)
                            : Colors.transparent,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        onSucursalSelected(sucursal);
                        // Actualizar productos al cambiar de sucursal
                        productoProvider.seleccionarSucursal(sucursal);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(
                                sucursal.sucursalCentral
                                    ? Icons.star
                                    : Icons.store,
                                color: isSelected
                                    ? const Color(0xFFE31E24)
                                    : Colors.white54,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  sucursal.nombre,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFFE31E24)
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              if (isSelected && productCount.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE31E24)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    productCount,
                                    style: const TextStyle(
                                      color: Color(0xFFE31E24),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            sucursal.direccion ?? 'Sin dirección registrada',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontStyle: sucursal.direccion != null
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
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
