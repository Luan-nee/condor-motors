import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white54,
                ),
                onPressed: onRecargarSucursales,
                tooltip: 'Recargar sucursales',
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
              final bool isSelected = sucursalSeleccionada?.id == sucursal.id;
              
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
                  onTap: () => onSucursalSelected(sucursal),
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
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Sucursal>('sucursales', sucursales))
      ..add(DiagnosticsProperty<Sucursal?>('sucursalSeleccionada', sucursalSeleccionada))
      ..add(ObjectFlagProperty<Function(Sucursal)>.has('onSucursalSelected', onSucursalSelected))
      ..add(ObjectFlagProperty<VoidCallback>.has('onRecargarSucursales', onRecargarSucursales));
  }
}
