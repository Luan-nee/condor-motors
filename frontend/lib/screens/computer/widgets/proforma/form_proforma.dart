import 'package:condorsmotors/models/proforma.model.dart';
import 'package:condorsmotors/providers/computer/proforma.computer.provider.dart';
import 'package:condorsmotors/screens/computer/widgets/proforma/proforma_utils.dart';
import 'package:condorsmotors/utils/ventas_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class ProcessingDialog extends StatelessWidget {
  final String documentType;

  const ProcessingDialog({
    super.key,
    required this.documentType,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Procesando pago...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Imprimiendo ${documentType.toLowerCase()}...',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('documentType', documentType));
  }
}

class ProformaSaleDialog extends StatefulWidget {
  final Proforma proforma;
  final Function(Map<String, dynamic>) onConfirm;
  final VoidCallback onCancel;

  const ProformaSaleDialog({
    super.key,
    required this.proforma,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<ProformaSaleDialog> createState() => _ProformaSaleDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Proforma>('proforma', proforma))
      ..add(ObjectFlagProperty<Function(Map<String, dynamic>)>.has(
          'onConfirm', onConfirm))
      ..add(ObjectFlagProperty<VoidCallback>.has('onCancel', onCancel));
  }
}

class _ProformaSaleDialogState extends State<ProformaSaleDialog> {
  late final ProformaComputerProvider proformaProvider;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    proformaProvider = Provider.of<ProformaComputerProvider>(
      context,
      listen: false,
    );
  }

  Future<void> _convertirProformaAVenta() async {
    if (_procesando) {
      return;
    }

    // Indicar que estamos procesando para evitar múltiples intentos
    setState(() {
      _procesando = true;
    });

    // Preparar la venta desde la proforma
    final Map<String, dynamic> ventaData =
        VentasPendientesUtils.convertirProformaAVentaPendiente(widget.proforma);

    // Mostrar diálogo de procesamiento
    if (!mounted) {
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext processingContext) {
        return const ProcessingDialog(
          documentType: 'venta',
        );
      },
    );

    try {
      // Intentar convertir la proforma a venta usando el provider
      final sucursalId = await VentasPendientesUtils.obtenerSucursalId();
      if (sucursalId == null) {
        throw Exception('No se pudo determinar la sucursal');
      }

      final bool exito = await proformaProvider.handleConvertToSale(
        widget.proforma,
        sucursalId,
      );

      // Verificar si el widget sigue montado antes de actualizar la UI
      if (!mounted) {
        return;
      }

      // Cerrar el diálogo de procesamiento
      Navigator.of(context).pop();

      if (exito) {
        // Si la conversión fue exitosa, cerrar este diálogo y notificar
        Navigator.of(context).pop();
        widget.onConfirm(ventaData);

        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Proforma convertida a venta correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Si hubo un error, mostrar diálogo de error
        if (!mounted) {
          return;
        }

        showDialog(
          context: context,
          builder: (BuildContext errorContext) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2D2D2D),
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 10),
                  Text(
                    'Error al convertir proforma',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ocurrió un error al intentar convertir la proforma a venta. La serie utilizada puede no estar registrada o puede haber problemas con la conexión.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nota: La proforma NO ha sido eliminada y puede intentar convertirla nuevamente.',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(errorContext).pop();
                  },
                  child: const Text('Cerrar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                  onPressed: () {
                    Navigator.of(errorContext).pop();
                    // Cerrar también el diálogo principal
                    Navigator.of(context).pop();
                  },
                  child: const Text('Entendido'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Verificar si el widget sigue montado antes de actualizar la UI
      if (!mounted) {
        return;
      }

      // Cerrar el diálogo de procesamiento
      Navigator.of(context).pop();

      // Mostrar diálogo de error
      showDialog(
        context: context,
        builder: (BuildContext errorContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2D2D2D),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 10),
                Text(
                  'Error inesperado',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error: ${e.toString()}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                const Text(
                  'La proforma NO ha sido eliminada y puede intentar convertirla nuevamente más tarde.',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(errorContext).pop();
                },
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    } finally {
      // Asegurarnos de resetear el estado de procesamiento
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.fileInvoiceDollar,
                    size: 20,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Convertir Proforma a Venta',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),

            // Detalles de la proforma
            Text(
              'Proforma #${widget.proforma.id} - ${VentasPendientesUtils.formatearFecha(widget.proforma.fechaCreacion)}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cliente: ${widget.proforma.cliente?['nombre'] ?? 'Sin nombre'}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            Text(
              'Fecha: ${VentasPendientesUtils.formatearFecha(widget.proforma.fechaCreacion)}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),

            // Lista de productos
            const Text(
              'Productos:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: <Widget>[
                  for (DetalleProforma detalle in widget.proforma.detalles)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            flex: 5,
                            child: Text(
                              detalle.nombre,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${detalle.cantidad}x',
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              VentasUtils.formatearMontoTexto(
                                  detalle.precioUnitario),
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              VentasUtils.formatearMontoTexto(detalle.subtotal),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(color: Colors.white24),
                  Row(
                    children: <Widget>[
                      const Spacer(),
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        VentasUtils.formatearMontoTexto(widget.proforma.total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _procesando ? null : _convertirProformaAVenta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    // Mostrar visual de deshabilitado cuando está procesando
                    disabledBackgroundColor:
                        const Color(0xFF4CAF50).withValues(alpha: 0.5),
                  ),
                  icon: _procesando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check),
                  label:
                      Text(_procesando ? 'Procesando...' : 'Convertir a Venta'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ProformaComputerProvider>(
        'proformaProvider', proformaProvider));
  }
}
