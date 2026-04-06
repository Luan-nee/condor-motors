import 'package:condorsmotors/models/sucursal.model.dart' as sucursal_model;
import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/providers/admin/transferencias.admin.riverpod.dart';
import 'package:condorsmotors/screens/admin/widgets/movimiento/transferencia_comparar_admin.dart';
import 'package:condorsmotors/screens/admin/widgets/movimiento/transferencia_info_card.dart';
import 'package:condorsmotors/screens/admin/widgets/movimiento/transferencia_productos_table.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class TransferenciaDetailDialog extends ConsumerStatefulWidget {
  final TransferenciaInventario transferencia;

  const TransferenciaDetailDialog({
    super.key,
    required this.transferencia,
  });

  @override
  ConsumerState<TransferenciaDetailDialog> createState() =>
      _TransferenciaDetailDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TransferenciaInventario>(
        'transferencia', transferencia));
  }
}

class _TransferenciaDetailDialogState
    extends ConsumerState<TransferenciaDetailDialog> {
  int _retryCount = 0;
  sucursal_model.Sucursal? _sucursalSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarDetalles();
  }

  Future<void> _cargarDetalles() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(transferenciasAdminProvider.notifier)
          .cargarDetalleTransferencia(widget.transferencia.id.toString());
    });
  }

  Future<void> _cargarComparacion(int sucursalId) async {

    try {
      final notifier = ref.read(transferenciasAdminProvider.notifier);

      final comparacion = await notifier.obtenerComparacionTransferencia(
        widget.transferencia.id.toString(),
        sucursalId,
      );

      if (!mounted) {
        return;
      }

      final bool? resultado = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return TransferenciaCompararAdmin(
            comparacion: comparacion,
            onCancel: () => Navigator.of(context).pop(false),
            onConfirm: () async {
              try {
                await notifier.completarEnvioTransferencia(
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

      if (resultado == true && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar comparación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isWideScreen = screenSize.width > 1200;
    final bool isMediumScreen =
        screenSize.width > 800 && screenSize.width <= 1200;

    double dialogWidth = isWideScreen
        ? 1000
        : (isMediumScreen ? screenSize.width * 0.7 : screenSize.width * 0.85);
    dialogWidth = dialogWidth.clamp(350.0, 1000.0);

    final state = ref.watch(transferenciasAdminProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxWidth: 1000,
          maxHeight: screenSize.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        child: _buildBody(state, isWideScreen, isMediumScreen),
      ),
    );
  }

  Widget _buildBody(
      TransferenciasAdminState state, bool isWideScreen, bool isMediumScreen) {
    if (state.isLoading) {
      return _buildLoadingContent();
    }

    if (state.errorMessage != null && _retryCount < 2) {
      return _buildErrorContent(state.errorMessage!);
    }

    final transferencia = state.detalleTransferenciaActual ?? widget.transferencia;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildHeader(),
        const Divider(color: Colors.white24),
        Flexible(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainInfo(transferencia),
                  const SizedBox(height: 16),
                  _buildSucursalSelector(state),
                  const SizedBox(height: 16),
                  _buildProductosSection(transferencia),
                ],
              ),
            ),
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
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
          splashRadius: 24,
        ),
      ],
    );
  }

  Widget _buildMainInfo(TransferenciaInventario transferencia) {
    return Column(
      children: [
        TransferenciaInfoCard(
          items: [
            TransferenciaInfoItem(
              label: 'ID',
              value: '#${transferencia.id}',
              icon: FontAwesomeIcons.hashtag,
            ),
            TransferenciaInfoItem(
              label: 'Origen',
              value: transferencia.nombreSucursalOrigen,
              icon: FontAwesomeIcons.store,
            ),
            TransferenciaInfoItem(
              label: 'Fecha Solicitada',
              value: _formatFecha(transferencia.salidaOrigen),
              icon: FontAwesomeIcons.calendar,
            ),
          ],
        ),
        const SizedBox(height: 12),
        TransferenciaInfoCard(
          items: [
            TransferenciaInfoItem(
              label: 'Estado',
              value: transferencia.estado.nombre,
              icon: FontAwesomeIcons.circleInfo,
            ),
            TransferenciaInfoItem(
              label: 'Destino',
              value: transferencia.nombreSucursalDestino,
              icon: FontAwesomeIcons.locationDot,
            ),
            TransferenciaInfoItem(
              label: 'Fecha Recibida',
              value: _formatFecha(transferencia.llegadaDestino),
              icon: FontAwesomeIcons.calendarCheck,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSucursalSelector(TransferenciasAdminState state) {
    final notifier = ref.read(transferenciasAdminProvider.notifier);
    final String estadoCodigo = widget.transferencia.estado.codigo;
    final estiloEstado = notifier.obtenerEstiloEstado(estadoCodigo);
    final bool puedeComparar = notifier.puedeCompararTransferencia(estadoCodigo);

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
            Icon(estiloEstado['iconData'] as IconData,
                color: estiloEstado['textColor'] as Color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notifier.obtenerMensajeComparacion(estadoCodigo),
                style: TextStyle(color: estiloEstado['textColor'] as Color),
              ),
            ),
          ],
        ),
      );
    }

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
              const FaIcon(FontAwesomeIcons.scaleBalanced,
                  size: 16, color: Color(0xFFE31E24)),
              const SizedBox(width: 12),
              const Text('Comparar Stock',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              _buildStatusBadge(estiloEstado),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<sucursal_model.Sucursal>(
            initialValue: _sucursalSeleccionada,
            decoration: _getInputDecoration(),
            dropdownColor: const Color(0xFF2D2D2D),
            style: const TextStyle(color: Colors.white),
            items: _buildSucursalItems(state.sucursales),
            onChanged: (sucursal) async {
              if (sucursal != null) {
                setState(() => _sucursalSeleccionada = sucursal);
                await _cargarComparacion(int.parse(sucursal.id));
              }
            },
            hint: const Text('Seleccione una sucursal para comparar',
                style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> estiloEstado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: estiloEstado['backgroundColor'] as Color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(estiloEstado['iconData'] as IconData,
              color: estiloEstado['textColor'] as Color, size: 14),
          const SizedBox(width: 6),
          Text(estiloEstado['estadoDisplay'] as String,
              style: TextStyle(
                  color: estiloEstado['textColor'] as Color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  InputDecoration _getInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF2D2D2D),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  List<DropdownMenuItem<sucursal_model.Sucursal>> _buildSucursalItems(
      List<sucursal_model.Sucursal> sucursales) {
    return sucursales
        .where((s) => s.id != widget.transferencia.sucursalDestinoId.toString())
        .map((sucursal) => DropdownMenuItem(
              value: sucursal,
              child: Row(
                children: [
                  Text(sucursal.nombre),
                  if (sucursal.id ==
                      widget.transferencia.sucursalOrigenId?.toString())
                    _buildOrigenBadge(),
                ],
              ),
            ))
        .toList();
  }

  Widget _buildOrigenBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE31E24).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE31E24).withValues(alpha: 0.3)),
      ),
      child: const Text('Origen',
          style: TextStyle(
              color: Color(0xFFE31E24), fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildProductosSection(TransferenciaInventario transferencia) {
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
              const FaIcon(FontAwesomeIcons.boxesStacked,
                  size: 16, color: Color(0xFFE31E24)),
              const SizedBox(width: 12),
              Text('Productos (${transferencia.productos?.length ?? 0})',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          if (transferencia.productos?.isNotEmpty ?? false) ...[
            const SizedBox(height: 16),
            TransferenciaProductosTable(productos: transferencia.productos!),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white24))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        const CircularProgressIndicator(color: Color(0xFFE31E24)),
        const SizedBox(height: 32),
        Text('Cargando detalles de la transferencia #${widget.transferencia.id}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildErrorContent(String error) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 24),
        Text('Error: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            setState(() => _retryCount++);
            _cargarDetalles();
          },
          child: const Text('Reintentar'),
        ),
      ],
    );
  }

  String _formatFecha(DateTime? fecha) =>
      fecha == null ? 'N/A' : DateFormat('dd/MM/yyyy').format(fecha);
}
