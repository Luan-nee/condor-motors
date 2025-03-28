import 'package:flutter/material.dart';
import '../../../../models/sucursal.model.dart';

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
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
            itemBuilder: (context, index) {
              final sucursal = sucursales[index];
              final isSelected = sucursalSeleccionada?.id == sucursal.id;
              
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
                    children: [
                      Row(
                        children: [
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
                        sucursal.direccion,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
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
}
