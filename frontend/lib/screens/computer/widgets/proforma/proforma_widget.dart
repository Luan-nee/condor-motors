import 'dart:math' show min;

import 'package:condorsmotors/models/proforma.model.dart';
import 'package:condorsmotors/providers/computer/proforma.computer.provider.dart';
import 'package:condorsmotors/screens/computer/widgets/proforma/form_proforma_keynum.dart';
import 'package:condorsmotors/screens/computer/widgets/proforma/proforma_utils.dart';
import 'package:condorsmotors/utils/documento_utils.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:condorsmotors/utils/ventas_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Widget para mostrar los detalles de una proforma individual
class ProformaWidget extends StatelessWidget {
  final Proforma proforma;
  final Function(Proforma)? onConvert;
  final Function(Proforma)? onUpdate;
  final VoidCallback? onDelete;

  const ProformaWidget({
    super.key,
    required this.proforma,
    this.onConvert,
    this.onUpdate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool puedeConvertirse = proforma.puedeConvertirseEnVenta();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado con información general
        _buildHeader(context),

        const SizedBox(height: 24),

        // Información del cliente
        _buildClientInfo(),

        const SizedBox(height: 24),

        // Lista de productos
        Expanded(
          child: _buildProductList(context),
        ),

        const SizedBox(height: 16),

        // Resumen y acciones
        _buildSummary(context, puedeConvertirse),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                proforma.nombre ?? 'Proforma #${proforma.id}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.white54,
              ),
              const SizedBox(width: 8),
              Text(
                'Creado: ${VentasPendientesUtils.formatearFecha(proforma.fechaCreacion)}',
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          if (proforma.fechaExpiracion != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: proforma.haExpirado() ? Colors.red : Colors.white54,
                ),
                const SizedBox(width: 8),
                Text(
                  'Expira: ${VentasPendientesUtils.formatearFecha(proforma.fechaExpiracion!)}',
                  style: TextStyle(
                    color: proforma.haExpirado() ? Colors.red : Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;
    IconData icon;

    switch (proforma.estado) {
      case EstadoProforma.pendiente:
        if (proforma.haExpirado()) {
          color = Colors.orange;
          text = 'Expirada';
          icon = Icons.timer_off;
        } else {
          color = Colors.blue;
          text = 'Pendiente';
          icon = Icons.pending;
        }
        break;
      case EstadoProforma.convertida:
        color = Colors.green;
        text = 'Convertida';
        icon = Icons.check_circle;
        break;
      case EstadoProforma.cancelada:
        color = Colors.red;
        text = 'Cancelada';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = 'Desconocido';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfo() {
    final Map<String, dynamic>? cliente = proforma.cliente;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.person,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                'Información del Cliente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (cliente != null && cliente.isNotEmpty) ...[
            _buildClientField('Nombre', cliente['nombre'] ?? 'Sin nombre'),
            _buildClientField(
                'Documento', cliente['numeroDocumento'] ?? 'Sin documento'),
            if (cliente['telefono'] != null)
              _buildClientField('Teléfono', cliente['telefono']),
            if (cliente['email'] != null)
              _buildClientField('Email', cliente['email']),
            if (cliente['direccion'] != null)
              _buildClientField('Dirección', cliente['direccion']),
          ] else ...[
            const Text(
              'Sin información de cliente',
              style: TextStyle(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClientField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Productos (${proforma.detalles.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.white.withOpacity(0.1),
            height: 1,
          ),

          // Encabezados de la tabla
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  flex: 5,
                  child: Text(
                    'Descripción',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Cantidad',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Precio Unit.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Subtotal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade200,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Lista de productos
          Expanded(
            child: proforma.detalles.isEmpty
                ? const Center(
                    child: Text(
                      'No hay productos en esta proforma',
                      style: TextStyle(
                        color: Colors.white54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: proforma.detalles.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.white.withOpacity(0.05),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final detalle = proforma.detalles[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Descripción del producto
                            Expanded(
                              flex: 5,
                              child: Text(
                                detalle.nombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            // Información de cantidad
                            Expanded(
                              child: _buildCantidadColumn(detalle),
                            ),

                            // Información de precio
                            Expanded(
                              flex: 2,
                              child: _buildPrecioColumn(detalle),
                            ),

                            // Subtotal
                            Expanded(
                              flex: 2,
                              child: Text(
                                VentasUtils.formatearMontoTexto(
                                    detalle.subtotal),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, bool puedeConvertirse) {
    // Calcular impuestos
    final double subtotal =
        VentasUtils.calcularSubtotalDesdeTotal(proforma.total);
    final double igv = VentasUtils.calcularIGV(subtotal);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Resumen de totales
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Subtotal:',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 120,
                child: Text(
                  VentasUtils.formatearMontoTexto(subtotal),
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'IGV (18%):',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 120,
                child: Text(
                  VentasUtils.formatearMontoTexto(igv),
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 120,
                child: Text(
                  VentasUtils.formatearMontoTexto(proforma.total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onDelete != null)
                OutlinedButton.icon(
                  onPressed: () => _handleDelete(context),
                  icon: const Icon(Icons.delete),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              const SizedBox(width: 16),
              if (onConvert != null && puedeConvertirse)
                ElevatedButton.icon(
                  onPressed: () => _handleConvert(context),
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Convertir a Venta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Maneja la eliminación de una proforma utilizando el provider
  void _handleDelete(BuildContext context) async {
    try {
      final proformaProvider = Provider.of<ProformaComputerProvider>(
        context,
        listen: false,
      );

      // Mostrar diálogo de confirmación
      bool? confirmar = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          title: const Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 10),
              Text(
                'Confirmar eliminación',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar la proforma #${proforma.id}? Esta acción no se puede deshacer.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                backgroundColor: Colors.red.withOpacity(0.1),
              ),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );

      // Si el usuario confirmó, eliminar la proforma
      if (confirmar == true) {
        // Mostrar diálogo de carga
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => const Dialog(
            backgroundColor: Color(0xFF2D2D2D),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text(
                    'Eliminando...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        );

        // Eliminar proforma usando el provider
        final success = await proformaProvider.deleteProforma(proforma, null);

        // Cerrar diálogo de carga
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // Mostrar resultado
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Proforma #${proforma.id} eliminada con éxito'
                    : 'Error al eliminar la proforma',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }

        // Ejecutar callback si existe
        if (success && onDelete != null) {
          onDelete!();
        }
      }
    } catch (e) {
      Logger.error('Error al eliminar proforma: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar la proforma: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleConvert(BuildContext context) async {
    // Guardamos el contexto de construcción antes de operaciones asíncronas
    final BuildContext originalContext = context;

    try {
      // Obtener el provider de proformas
      final proformaProvider = Provider.of<ProformaComputerProvider>(
        context,
        listen: false,
      );

      // Registrar inicio del proceso
      Logger.debug(
          'INICIO CONVERSIÓN UI: Iniciando conversión de proforma #${proforma.id}');

      // Mostrar diálogo para confirmar conversión
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) => ProformaSaleDialog(
          proforma: proforma,
          onConfirm: (Map<String, dynamic> ventaData) async {
            Logger.debug(
                'Confirmación recibida con datos: ${ventaData.toString().substring(0, min(100, ventaData.toString().length))}...');
            Navigator.of(dialogContext).pop();

            // Verificar si el widget sigue montado antes de mostrar diálogo
            if (!originalContext.mounted) {
              Logger.debug(
                  'Widget desmontado antes de mostrar diálogo de procesamiento');
              return;
            }

            // Mostrar diálogo de procesamiento
            BuildContext? processingDialogContext;
            showDialog(
              context: originalContext,
              barrierDismissible: false,
              builder: (BuildContext context) {
                processingDialogContext = context;
                return _buildProcessingDialog(
                    ventaData['tipoDocumento'].toLowerCase());
              },
            );

            try {
              // Usar provider para convertir proforma a venta
              final success = await proformaProvider.handleConvertToSale(
                proforma,
                null, // Dejar que el provider obtenga el ID de sucursal
                onSuccess: () {
                  Logger.debug('Callback de éxito ejecutado desde provider');
                  if (onConvert != null) {
                    onConvert!(proforma);
                  }
                },
              );

              // Cerrar el diálogo de procesamiento si aún está abierto
              if (processingDialogContext != null &&
                  processingDialogContext!.mounted &&
                  Navigator.of(processingDialogContext!).canPop()) {
                Navigator.of(processingDialogContext!).pop();
              }

              // Verificar si el widget sigue montado antes de mostrar el resultado
              if (originalContext.mounted) {
                ScaffoldMessenger.of(originalContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Proforma #${proforma.id} convertida a venta con éxito'
                          : 'Error al convertir la proforma a venta',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            } catch (e) {
              // Cerrar el diálogo de procesamiento en caso de error
              if (processingDialogContext != null &&
                  processingDialogContext!.mounted &&
                  Navigator.of(processingDialogContext!).canPop()) {
                Navigator.of(processingDialogContext!).pop();
              }

              // Mostrar error si el widget sigue montado
              if (originalContext.mounted) {
                ScaffoldMessenger.of(originalContext).showSnackBar(
                  SnackBar(
                    content: Text('Error al procesar la venta: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          onCancel: () {
            Logger.debug('Usuario canceló la conversión');
            Navigator.of(dialogContext).pop();
          },
        ),
      );
    } catch (e) {
      Logger.error('ERROR en _handleConvert: $e');
      if (originalContext.mounted) {
        showDialog(
          context: originalContext,
          builder: (BuildContext context) => AlertDialog(
            backgroundColor: const Color(0xFF2D2D2D),
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 10),
                Text(
                  'Error en conversión',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: Text(
              'Ocurrió un error al procesar la conversión: ${e.toString()}',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildProcessingDialog(String tipoDocumento) {
    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Procesando $tipoDocumento...',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Por favor espere',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Verificar si el detalle de la proforma tiene descuento aplicado
  bool _tieneDescuento(DetalleProforma detalle) {
    return ProformaUtils.tieneDescuento(detalle);
  }

  /// Obtener el valor del descuento formateado
  String _getDescuento(DetalleProforma detalle) {
    return ProformaUtils.getDescuento(detalle);
  }

  /// Obtener el precio original antes del descuento
  double? _getPrecioOriginal(DetalleProforma detalle) {
    return ProformaUtils.getPrecioOriginal(detalle);
  }

  /// Verificar si hay unidades gratis
  bool _tieneUnidadesGratis(DetalleProforma detalle) {
    return ProformaUtils.tieneUnidadesGratis(detalle);
  }

  /// Obtener cantidad de unidades gratis
  int _getCantidadGratis(DetalleProforma detalle) {
    return ProformaUtils.getCantidadGratis(detalle);
  }

  /// Obtener cantidad de unidades pagadas
  int _getCantidadPagada(DetalleProforma detalle) {
    return ProformaUtils.getCantidadPagada(detalle);
  }

  /// Construye la columna de información de cantidad
  Widget _buildCantidadColumn(DetalleProforma detalle) {
    final bool tieneGratis = _tieneUnidadesGratis(detalle);
    final cantidadGratis = _getCantidadGratis(detalle);
    final cantidadPagada = _getCantidadPagada(detalle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Cantidad total
        Text(
          '${detalle.cantidad}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Si hay unidades gratis, mostrar el desglose
        if (tieneGratis)
          Tooltip(
            message: 'Esta promoción incluye $cantidadGratis unidades gratis',
            child: Text(
              '($cantidadPagada + $cantidadGratis)',
              style: TextStyle(
                color: Colors.green.shade300,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  /// Construye la columna de información de precio
  Widget _buildPrecioColumn(DetalleProforma detalle) {
    final bool tieneDescuento = _tieneDescuento(detalle);
    final String descuento = _getDescuento(detalle);
    final double? precioOriginal = _getPrecioOriginal(detalle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Si tiene descuento, mostrar precio original tachado
        if (tieneDescuento && precioOriginal != null)
          Text(
            VentasUtils.formatearMontoTexto(precioOriginal),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              decoration: TextDecoration.lineThrough,
            ),
          ),

        // Precio unitario actual
        Text(
          VentasUtils.formatearMontoTexto(detalle.precioUnitario),
          style: TextStyle(
            color: tieneDescuento ? Colors.green : Colors.white,
            fontWeight: tieneDescuento ? FontWeight.bold : FontWeight.normal,
          ),
        ),

        // Información del descuento
        if (tieneDescuento)
          Tooltip(
            message: 'Descuento aplicado: $descuento%',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.discount_outlined,
                  size: 10,
                  color: Colors.orange.shade300,
                ),
                const SizedBox(width: 2),
                Text(
                  '$descuento% OFF',
                  style: TextStyle(
                    color: Colors.orange.shade300,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Proforma>('proforma', proforma))
      ..add(ObjectFlagProperty<Function(Proforma)?>.has('onConvert', onConvert))
      ..add(ObjectFlagProperty<Function(Proforma)?>.has('onUpdate', onUpdate))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onDelete', onDelete));
  }
}

/// Diálogo para confirmar la conversión de proforma a venta
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
  String _tipoDocumento = 'BOLETA';
  String _customerName = '';
  String _paymentAmount = '';
  bool _isProcessing = false;
  bool _documentoValidado = false;
  String? _numeroDocumentoCliente;
  bool _puedeEmitirBoleta = true;
  bool _puedeEmitirFactura = false;
  String _mensajeValidacion = '';

  @override
  void initState() {
    super.initState();
    // Inicializar con el nombre del cliente de la proforma
    _customerName = widget.proforma.getNombreCliente();
    // Obtener número de documento del cliente si está disponible
    _extraerNumeroDocumentoCliente();
  }

  /// Extrae el número de documento del cliente de la proforma
  void _extraerNumeroDocumentoCliente() {
    // Usar el método utilitario para extraer el número de documento
    final numeroDocumento =
        ProformaUtils.extraerNumeroDocumentoCliente(widget.proforma.cliente);
    _actualizarValidacionDocumento(numeroDocumento);
  }

  /// Actualiza el estado de validación según el número de documento
  void _actualizarValidacionDocumento(String? numeroDocumento) {
    // Obtener la validación completa desde la clase utilitaria
    final validacion =
        DocumentoUtils.obtenerValidacionCompleta(numeroDocumento);

    setState(() {
      _numeroDocumentoCliente = numeroDocumento;
      _documentoValidado =
          numeroDocumento != null && numeroDocumento.isNotEmpty;

      // Usar los datos de validación
      _puedeEmitirBoleta = validacion['puedeEmitirBoleta'];
      _puedeEmitirFactura = validacion['puedeEmitirFactura'];
      _mensajeValidacion = validacion['mensajeValidacion'];

      // Ajustar el tipo de documento seleccionado si es necesario
      if (_documentoValidado) {
        if (_tipoDocumento == 'BOLETA' && !_puedeEmitirBoleta) {
          _tipoDocumento = 'FACTURA';
        } else if (_tipoDocumento == 'FACTURA' && !_puedeEmitirFactura) {
          _tipoDocumento = 'BOLETA';
        }
      }
    });
  }

  /// Verificar si el detalle de la proforma tiene descuento aplicado
  bool _tieneDescuento(DetalleProforma detalle) {
    return ProformaUtils.tieneDescuento(detalle);
  }

  /// Obtener el valor del descuento formateado
  String _getDescuento(DetalleProforma detalle) {
    return ProformaUtils.getDescuento(detalle);
  }

  /// Obtener el precio original antes del descuento
  double? _getPrecioOriginal(DetalleProforma detalle) {
    return ProformaUtils.getPrecioOriginal(detalle);
  }

  /// Verificar si hay unidades gratis
  bool _tieneUnidadesGratis(DetalleProforma detalle) {
    return ProformaUtils.tieneUnidadesGratis(detalle);
  }

  /// Obtener cantidad de unidades gratis
  int _getCantidadGratis(DetalleProforma detalle) {
    return ProformaUtils.getCantidadGratis(detalle);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isLargeScreen = screenSize.width > 1200;

    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: isLargeScreen ? 1400 : 1100,
          maxHeight: isLargeScreen ? 900 : 700,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detalles de la proforma (lado izquierdo)
            Flexible(
              flex: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: [
                          const Icon(
                            Icons.shopping_cart,
                            color: Color(0xFF4CAF50),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Convertir Proforma #${widget.proforma.id}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: widget.onCancel,
                        tooltip: 'Cancelar',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Resumen de la proforma
                  SizedBox(
                    height: isLargeScreen ? 700 : 500,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Text(
                                'Cliente:',
                                style: TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.proforma.getNombreCliente(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Detalles:',
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Lista de productos (con scroll)
                          Flexible(
                            child: ListView.builder(
                                itemCount: widget.proforma.detalles.length,
                                itemBuilder: (context, index) {
                                  final detalle =
                                      widget.proforma.detalles[index];

                                  // Verificar si tiene descuentos o unidades gratis
                                  final bool tieneDescuento =
                                      _tieneDescuento(detalle);
                                  final bool tieneUnidadesGratis =
                                      _tieneUnidadesGratis(detalle);
                                  final double? precioOriginal =
                                      _getPrecioOriginal(detalle);
                                  final String descuento =
                                      _getDescuento(detalle);
                                  final int cantidadGratis =
                                      _getCantidadGratis(detalle);

                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              flex: 5,
                                              child: Row(
                                                children: [
                                                  Text(
                                                    detalle.nombre,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  if (tieneDescuento ||
                                                      tieneUnidadesGratis) ...[
                                                    const SizedBox(width: 8),
                                                    Icon(
                                                      tieneDescuento
                                                          ? Icons.discount
                                                          : Icons.card_giftcard,
                                                      size: 14,
                                                      color: tieneDescuento
                                                          ? Colors.orange
                                                          : Colors.green,
                                                    ),
                                                  ],
                                                ],
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
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  if (tieneDescuento &&
                                                      precioOriginal != null)
                                                    Text(
                                                      VentasUtils
                                                          .formatearMontoTexto(
                                                              precioOriginal),
                                                      style: const TextStyle(
                                                        color: Colors.white38,
                                                        fontSize: 10,
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                      ),
                                                    ),
                                                  Text(
                                                    VentasUtils
                                                        .formatearMontoTexto(
                                                            detalle
                                                                .precioUnitario),
                                                    style: TextStyle(
                                                      color: tieneDescuento
                                                          ? Colors
                                                              .orange.shade200
                                                          : Colors.white70,
                                                      fontWeight: tieneDescuento
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                VentasUtils.formatearMontoTexto(
                                                    detalle.subtotal),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Mostrar información de promociones
                                        if (tieneDescuento ||
                                            tieneUnidadesGratis)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 16, top: 2, bottom: 4),
                                            child: Row(
                                              children: [
                                                if (tieneDescuento)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      border: Border.all(
                                                          color: Colors.orange
                                                              .withOpacity(
                                                                  0.3)),
                                                    ),
                                                    child: Text(
                                                      'Descuento $descuento%',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors
                                                            .orange.shade300,
                                                      ),
                                                    ),
                                                  ),
                                                if (tieneDescuento &&
                                                    tieneUnidadesGratis)
                                                  const SizedBox(width: 8),
                                                if (tieneUnidadesGratis)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      border: Border.all(
                                                          color: Colors.green
                                                              .withOpacity(
                                                                  0.3)),
                                                    ),
                                                    child: Text(
                                                      '$cantidadGratis unidades gratis',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors
                                                            .green.shade300,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),

                                        if (index <
                                            widget.proforma.detalles.length - 1)
                                          const Divider(
                                              height: 8, color: Colors.white12),
                                      ],
                                    ),
                                  );
                                }),
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
                                VentasUtils.formatearMontoTexto(
                                    widget.proforma.total),
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
                  ),
                ],
              ),
            ),
            // Separador vertical
            const SizedBox(width: 20),
            Container(width: 1, height: double.infinity, color: Colors.white24),
            const SizedBox(width: 20),

            // Teclado numérico para cálculo de vuelto (lado derecho)
            Flexible(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_documentoValidado)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: const Color(0xFF4CAF50),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _mensajeValidacion,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: NumericKeypad(
                            onKeyPressed: (value) {
                              setState(() {
                                _paymentAmount = value;
                              });
                            },
                            onClear: () {
                              setState(() {
                                _paymentAmount = '';
                              });
                            },
                            onSubmit: () {},
                            currentAmount: widget.proforma.total.toString(),
                            paymentAmount: _paymentAmount,
                            customerName: _customerName,
                            documentType: _tipoDocumento == 'BOLETA'
                                ? 'Boleta'
                                : 'Factura',
                            onCustomerNameChanged: (String value) {
                              setState(() {
                                _customerName = value;
                              });
                            },
                            onDocumentTypeChanged: (String value) {
                              final String nuevoTipo =
                                  value == 'Boleta' ? 'BOLETA' : 'FACTURA';
                              if (nuevoTipo == 'BOLETA' &&
                                  !_puedeEmitirBoleta) {
                                return;
                              }
                              if (nuevoTipo == 'FACTURA' &&
                                  !_puedeEmitirFactura) {
                                return;
                              }
                              setState(() {
                                _tipoDocumento = nuevoTipo;
                              });
                            },
                            isProcessing: _isProcessing,
                            minAmount: widget.proforma.total,
                            puedeEmitirBoleta: _puedeEmitirBoleta,
                            puedeEmitirFactura: _puedeEmitirFactura,
                            onCharge: (_) {},
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton.icon(
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.payment, size: 28),
                            label: Text(
                              _isProcessing ? 'Procesando...' : 'Cobrar',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: (_paymentAmount.isNotEmpty &&
                                    (double.tryParse(_paymentAmount) ?? 0) >=
                                        widget.proforma.total &&
                                    !_isProcessing)
                                ? () {
                                    if (_documentoValidado &&
                                        !DocumentoUtils
                                            .esComprobanteValidoParaCliente(
                                                _numeroDocumentoCliente,
                                                _tipoDocumento)) {
                                      return;
                                    }
                                    final double montoRecibido =
                                        double.tryParse(_paymentAmount) ?? 0;
                                    final Map<String, dynamic> ventaData = {
                                      'tipoDocumento': _tipoDocumento,
                                      'productos': widget.proforma.detalles
                                          .map((detalle) => {
                                                'productoId':
                                                    detalle.productoId,
                                                'cantidad': detalle.cantidad,
                                                'precio':
                                                    detalle.precioUnitario,
                                                'subtotal': detalle.subtotal,
                                              })
                                          .toList(),
                                      'cliente': widget.proforma.cliente ??
                                          {'nombre': _customerName},
                                      'metodoPago': 'EFECTIVO',
                                      'total': widget.proforma.total,
                                      'montoRecibido': montoRecibido,
                                      'vuelto':
                                          montoRecibido - widget.proforma.total,
                                    };
                                    setState(() {
                                      _isProcessing = true;
                                    });
                                    widget.onConfirm(ventaData);
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
    properties
      ..add(StringProperty('_tipoDocumento', _tipoDocumento))
      ..add(StringProperty('_customerName', _customerName))
      ..add(StringProperty('_paymentAmount', _paymentAmount))
      ..add(DiagnosticsProperty<bool>('_isProcessing', _isProcessing))
      ..add(StringProperty('_numeroDocumentoCliente', _numeroDocumentoCliente))
      ..add(DiagnosticsProperty<bool>('_puedeEmitirBoleta', _puedeEmitirBoleta))
      ..add(
          DiagnosticsProperty<bool>('_puedeEmitirFactura', _puedeEmitirFactura))
      ..add(StringProperty('_mensajeValidacion', _mensajeValidacion));
  }
}
