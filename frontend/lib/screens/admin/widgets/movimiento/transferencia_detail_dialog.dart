import 'package:condorsmotors/models/sucursal.model.dart' as sucursal_model;
import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/providers/admin/transferencias.admin.provider.dart';
import 'package:condorsmotors/screens/admin/widgets/movimiento/transferencia_comparar_admin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Widget para mostrar el detalle de un movimiento de inventario
/// Este widget maneja internamente los estados de carga, error y visualización
class TransferenciaDetailDialog extends StatefulWidget {
  final TransferenciaInventario transferencia;

  const TransferenciaDetailDialog({
    super.key,
    required this.transferencia,
  });

  @override
  State<TransferenciaDetailDialog> createState() =>
      _TransferenciaDetailDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TransferenciaInventario>(
        'transferencia', transferencia));
  }
}

class _TransferenciaDetailDialogState extends State<TransferenciaDetailDialog> {
  String? _errorMessage;
  int _retryCount = 0;
  sucursal_model.Sucursal? _sucursalSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarDetalles();
  }

  Future<void> _cargarDetalles() async {
    if (!mounted) {
      return;
    }

    final TransferenciasProvider transferenciasProvider =
        Provider.of<TransferenciasProvider>(context, listen: false);

    try {
      debugPrint(
          '⏳ [TransferenciaDetailDialog] Cargando detalles de la transferencia #${widget.transferencia.id}');

      transferenciasProvider.cargarDetalleTransferencia(
        widget.transferencia.id.toString(),
      );
    } catch (e) {
      debugPrint('[TransferenciaDetailDialog] Error al cargar detalles: $e');
    }
  }

  Future<void> _cargarComparacion(int sucursalId) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      final TransferenciasProvider transferenciasProvider =
          Provider.of<TransferenciasProvider>(context, listen: false);

      final comparacion =
          await transferenciasProvider.obtenerComparacionTransferencia(
        widget.transferencia.id.toString(),
        sucursalId,
      );

      if (!mounted) {
        return;
      }

      setState(() {});

      if (mounted) {
        final bool? resultado = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return TransferenciaCompararAdmin(
              comparacion: comparacion,
              onCancel: () {
                Navigator.of(context).pop(false);
              },
              onConfirm: () async {
                try {
                  await transferenciasProvider.completarEnvioTransferencia(
                    widget.transferencia.id.toString(),
                    sucursalId,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transferencia enviada exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pop(true);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al enviar: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    Navigator.of(context).pop(false);
                  }
                }
              },
            );
          },
        );

        // Si la transferencia se envió exitosamente, cerramos el diálogo de detalles
        if (resultado == true && mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('[TransferenciaDetailDialog] Error al cargar comparación: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Error al cargar comparación: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener tamaño de pantalla
    final Size screenSize = MediaQuery.of(context).size;
    final bool isWideScreen = screenSize.width > 1200;
    final bool isMediumScreen =
        screenSize.width > 800 && screenSize.width <= 1200;

    // Calcular ancho apropiado basado en el tamaño de pantalla
    double dialogWidth;
    if (isWideScreen) {
      dialogWidth = 1000; // Ancho fijo para pantallas grandes
    } else if (isMediumScreen) {
      dialogWidth = screenSize.width * 0.7;
    } else {
      dialogWidth = screenSize.width * 0.85;
    }

    // Asegurar que el diálogo nunca sea demasiado pequeño
    dialogWidth = dialogWidth.clamp(350.0, 1000.0);

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxWidth: 1000,
          maxHeight: screenSize.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        child: _buildContent(context, isWideScreen, isMediumScreen),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, bool isWideScreen, bool isMediumScreen) {
    // En lugar de usar variables de estado locales, usamos Consumer para
    // acceder a los datos del provider
    return Consumer<TransferenciasProvider>(
      builder: (context, provider, child) {
        // Estado de carga
        if (provider.isLoading) {
          return _buildLoadingContent();
        }

        // Estado de error
        if (provider.errorMessage != null && _retryCount < 2) {
          return _buildErrorContent(provider.errorMessage!);
        }

        // Estado normal - muestra los detalles usando la transferencia del provider
        // o la transferencia original como fallback
        final transferencia =
            provider.detalleTransferenciaActual ?? widget.transferencia;
        return _buildDetailContent(
            context, isWideScreen, isMediumScreen, transferencia);
      },
    );
  }

  // Widget para mostrar estado de carga
  Widget _buildLoadingContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 24),
          const CircularProgressIndicator(
            color: Color(0xFFE31E24),
            strokeWidth: 3,
          ),
          const SizedBox(height: 32),
          Text(
            'Cargando detalles de la transferencia #${widget.transferencia.id}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Esto puede tomar unos segundos',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Widget para mostrar estado de error
  Widget _buildErrorContent(String errorMessage) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 24),
            const Text(
              'Error al cargar los detalles',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Text(
                'No se pudieron cargar los detalles completos de la transferencia #${widget.transferencia.id}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Text(
                    'Error: $_errorMessage',
                    style: TextStyle(color: Colors.red.shade200, fontSize: 14),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Color(0xFFE31E24))),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _retryCount++;
                    });
                    _cargarDetalles();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31E24),
                  ),
                  child: const Text('Reintentar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // Usar los datos básicos del movimiento sin productos detallados
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2D2D),
                  ),
                  child: const Text('Ver datos básicos'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar los detalles del movimiento
  Widget _buildDetailContent(BuildContext context, bool isWideScreen,
      bool isMediumScreen, TransferenciaInventario transferencia) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildHeader(context),
        const Divider(color: Colors.white24),
        Flexible(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información General y Sucursales en una sola fila
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoItem(
                                    'ID',
                                    '#${transferencia.id}',
                                    FontAwesomeIcons.hashtag,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoItem(
                                    'Estado',
                                    transferencia.estado.nombre,
                                    FontAwesomeIcons.circleInfo,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoItem(
                                    'Origen',
                                    transferencia.nombreSucursalOrigen,
                                    FontAwesomeIcons.store,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoItem(
                                    'Destino',
                                    transferencia.nombreSucursalDestino,
                                    FontAwesomeIcons.locationDot,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoItem(
                                    'Fecha Solicitada',
                                    _formatFecha(transferencia.salidaOrigen),
                                    FontAwesomeIcons.calendar,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoItem(
                                    'Fecha Recibida',
                                    _formatFecha(transferencia.llegadaDestino),
                                    FontAwesomeIcons.calendarCheck,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selector de Sucursal para Comparación
                  _buildSucursalSelector(),
                  const SizedBox(height: 16),

                  // Lista de Productos
                  _buildProductosSectionCard(transferencia),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white24),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check),
                label: const Text('Aceptar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE31E24),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Encabezado del diálogo
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE31E24).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.truck,
                color: Color(0xFFE31E24),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Detalle de Transferencia',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          iconSize: 24,
          splashRadius: 24,
        ),
      ],
    );
  }

  // Información general del movimiento
  Widget _buildInfoItem(String label, String? value, IconData icon) {
    return Row(
      children: [
        FaIcon(
          icon,
          size: 14,
          color: const Color(0xFFE31E24),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                value ?? 'N/A',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Formato de fecha
  String _formatFecha(DateTime? fecha) {
    if (fecha == null) {
      return 'N/A';
    }
    try {
      return DateFormat('dd/MM/yyyy').format(fecha);
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  // Simplificar el selector de sucursal
  Widget _buildSucursalSelector() {
    final TransferenciasProvider transferenciasProvider =
        Provider.of<TransferenciasProvider>(context);

    // Obtener el estado actual y su estilo
    final String estadoCodigo = widget.transferencia.estado.codigo;
    final estiloEstado =
        transferenciasProvider.obtenerEstiloEstado(estadoCodigo);
    final bool puedeComparar =
        transferenciasProvider.puedeCompararTransferencia(estadoCodigo);

    // Si no se puede comparar, mostrar mensaje informativo
    if (!puedeComparar) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: estiloEstado['backgroundColor'] as Color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (estiloEstado['textColor'] as Color).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              estiloEstado['iconData'] as IconData,
              color: estiloEstado['textColor'] as Color,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                transferenciasProvider.obtenerMensajeComparacion(estadoCodigo),
                style: TextStyle(
                  color: estiloEstado['textColor'] as Color,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Si está en PEDIDO, mostramos el selector con mensaje informativo
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.scaleBalanced,
                size: 16,
                color: Color(0xFFE31E24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Comparar Stock',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Mostrar el estado actual como badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: estiloEstado['backgroundColor'] as Color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      estiloEstado['iconData'] as IconData,
                      color: estiloEstado['textColor'] as Color,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      estiloEstado['estadoDisplay'] as String,
                      style: TextStyle(
                        color: estiloEstado['textColor'] as Color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Mensaje informativo
          Text(
            transferenciasProvider.obtenerMensajeComparacion(estadoCodigo),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<sucursal_model.Sucursal>(
            initialValue: _sucursalSeleccionada,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF2D2D2D),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            dropdownColor: const Color(0xFF2D2D2D),
            style: const TextStyle(color: Colors.white),
            items: [
              for (var sucursal in transferenciasProvider.sucursales)
                if (sucursal.id !=
                    widget.transferencia.sucursalDestinoId.toString())
                  DropdownMenuItem<sucursal_model.Sucursal>(
                    value: sucursal,
                    child: Row(
                      children: [
                        Text(sucursal.nombre),
                        if (sucursal.id ==
                            widget.transferencia.sucursalOrigenId?.toString())
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE31E24)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE31E24)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'Origen',
                              style: TextStyle(
                                color: Color(0xFFE31E24),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
            ],
            onChanged: (sucursal_model.Sucursal? sucursal) async {
              if (sucursal != null) {
                try {
                  setState(() {
                    _sucursalSeleccionada = sucursal;
                  });

                  await _cargarComparacion(int.parse(sucursal.id));
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {});
                  }
                }
              }
            },
            hint: const Text(
              'Seleccione una sucursal para comparar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  // Simplificar el widget de productos
  Widget _buildProductosSectionCard(TransferenciaInventario transferencia) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.boxesStacked,
                size: 16,
                color: Color(0xFFE31E24),
              ),
              const SizedBox(width: 12),
              Text(
                'Productos (${transferencia.productos?.length ?? 0})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (transferencia.productos != null &&
              transferencia.productos!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: transferencia.productos!.length,
                separatorBuilder: (context, index) =>
                    const Divider(color: Colors.white24, height: 1),
                itemBuilder: (context, index) {
                  final producto = transferencia.productos![index];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      producto.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: producto.codigo != null
                        ? Text(
                            'Código: ${producto.codigo}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          )
                        : null,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE31E24).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE31E24).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Cantidad: ${producto.cantidad}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No hay productos disponibles',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
