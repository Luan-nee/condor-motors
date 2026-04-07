import 'package:condorsmotors/models/ventas.model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VentaProductosTable extends StatelessWidget {
  final List<DetalleVenta> detalles;
  final bool isLoading;

  const VentaProductosTable({
    super.key,
    required this.detalles,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat formatoMoneda = NumberFormat.currency(
      symbol: 'S/ ',
      decimalDigits: 2,
    );

    final double maxTableHeight = MediaQuery.of(context).size.height * 0.35;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Líneas de Productos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        
        // Cabecera estática
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF2D2D2D),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('Producto', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(child: Text('Cant.', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
              Expanded(child: Text('Precio', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
              Expanded(child: Text('Total', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
            ],
          ),
        ),

        // Cuerpo de la tabla con RepaintBoundary para optimizar scroll y animaciones
        RepaintBoundary(
          child: Container(
            constraints: BoxConstraints(maxHeight: maxTableHeight),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              border: Border.all(color: const Color(0xFF2D2D2D)),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: detalles.length,
              physics: const ClampingScrollPhysics(),
              separatorBuilder: (_, __) => const Divider(color: Color(0xFF2D2D2D), height: 1),
              itemBuilder: (context, index) {
                final detalle = detalles[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          detalle.nombre,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          detalle.cantidad.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          formatoMoneda.format(detalle.precioConIgv),
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          formatoMoneda.format(detalle.total),
                          style: const TextStyle(
                            color: Color(0xFFE31E24),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
