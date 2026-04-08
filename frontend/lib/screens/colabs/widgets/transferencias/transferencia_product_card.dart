import 'package:condorsmotors/models/producto.model.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TransferenciaProductCard extends StatelessWidget {
  final Producto producto;
  final bool isBajoStock;
  final int cantidadSeleccionada;
  final Function(int) onCantidadChanged;

  const TransferenciaProductCard({
    super.key,
    required this.producto,
    required this.isBajoStock,
    required this.cantidadSeleccionada,
    required this.onCantidadChanged,
  });

  @override
  Widget build(BuildContext context) {
    final stockMinimo = producto.stockMinimo ?? 0;
    final int stockDiferencia = stockMinimo - producto.stock;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
        border: isBajoStock
            ? Border.all(
                color: const Color(0xFFE31E24).withValues(alpha: 0.5),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE31E24).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.box,
                  color: Color(0xFFE31E24),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Stock: ${producto.stock}/$stockMinimo',
                          style: TextStyle(
                            color: isBajoStock
                                ? const Color(0xFFE31E24)
                                : Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        if (isBajoStock)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE31E24)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Faltan: $stockDiferencia',
                              style: const TextStyle(
                                color: Color(0xFFE31E24),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildQuantityControls(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControls() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 24),
            color: Colors.white70,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: cantidadSeleccionada > 0
                ? () => onCantidadChanged(cantidadSeleccionada - 1)
                : null,
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 45,
            height: 32,
            child: TextFormField(
              initialValue:
                  cantidadSeleccionada > 0 ? cantidadSeleccionada.toString() : '',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                isDense: true,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE31E24)),
                ),
              ),
              onFieldSubmitted: (value) {
                final newCantidad = int.tryParse(value) ?? 0;
                onCantidadChanged(newCantidad);
              },
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 24),
            color: const Color(0xFFE31E24),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: () => onCantidadChanged(cantidadSeleccionada + 1),
          ),
        ],
      ),
    );
  }
}
