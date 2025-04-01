import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/providers/admin/ventas.provider.dart';
import 'package:condorsmotors/screens/admin/widgets/venta/venta_detalle_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/venta/venta_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class VentaTable extends StatefulWidget {
  final Sucursal? sucursalSeleccionada;
  final VoidCallback onRecargarVentas;

  const VentaTable({
    super.key,
    required this.sucursalSeleccionada,
    required this.onRecargarVentas,
  });

  @override
  State<VentaTable> createState() => _VentaTableState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Sucursal?>(
          'sucursalSeleccionada', sucursalSeleccionada))
      ..add(ObjectFlagProperty<VoidCallback>.has(
          'onRecargarVentas', onRecargarVentas));
  }
}

class _VentaTableState extends State<VentaTable> {
  late VentasProvider _ventasProvider;

  @override
  void initState() {
    super.initState();
    _ventasProvider = Provider.of<VentasProvider>(context, listen: false);
  }

  @override
  void didUpdateWidget(VentaTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sucursalSeleccionada?.id != widget.sucursalSeleccionada?.id) {
      _ventasProvider.cargarVentas();
    }
  }

  // Abre el diálogo de detalle de venta
  void _mostrarDetalleVenta(venta) {
    showDialog(
      context: context,
      builder: (context) => VentaDetalleDialog(venta: venta),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VentasProvider>(builder: (context, provider, child) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VENTAS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (widget.sucursalSeleccionada != null)
                      Text(
                        'Sucursal: ${widget.sucursalSeleccionada!.nombre}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    if (provider.isVentasLoading)
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cargando...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.arrowsRotate,
                        color: Colors.white,
                        size: 16,
                      ),
                      onPressed: provider.isVentasLoading
                          ? null
                          : () {
                              provider.cargarVentas();
                              widget.onRecargarVentas();
                            },
                      tooltip: 'Recargar ventas',
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const FaIcon(
                        FontAwesomeIcons.plus,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text('Nueva Venta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31E24),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: provider.isVentasLoading ||
                              widget.sucursalSeleccionada == null
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Función en desarrollo'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Mensaje de error
            if (provider.ventasErrorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        provider.ventasErrorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        // Usar el método del provider para limpiar errores
                        provider.limpiarErrores();
                      },
                    ),
                  ],
                ),
              ),

            // Tabla de ventas
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: VentaList(
                  ventas: provider.ventas,
                  isLoading: provider.isVentasLoading,
                  onVerDetalle: _mostrarDetalleVenta,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
