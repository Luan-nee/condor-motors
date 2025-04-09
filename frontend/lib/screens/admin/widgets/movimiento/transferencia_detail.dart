import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/providers/admin/transferencias.admin.provider.dart';
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
  bool _isLoading = true;
  String? _errorMessage;
  TransferenciaInventario? _detalleTransferencia;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    // Cargar detalles al inicializar el widget
    _cargarDetalles();
  }

  Future<void> _cargarDetalles() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint(
          '⏳ [TransferenciaDetailDialog] Cargando detalles de la transferencia #${widget.transferencia.id}');

      // Cargar detalles usando el provider
      final TransferenciasProvider transferenciasProvider =
          Provider.of<TransferenciasProvider>(context, listen: false);
      final String id = widget.transferencia.id.toString();

      // Obtener detalle del movimiento usando el provider
      final TransferenciaInventario detalleTransferencia =
          await transferenciasProvider.obtenerDetalleTransferencia(
        id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _detalleTransferencia = detalleTransferencia;
        _isLoading = false;
      });

      debugPrint(
          '✅ [TransferenciaDetailDialog] Detalles cargados correctamente');
      debugPrint(
          '📦 [TransferenciaDetailDialog] Productos: ${_detalleTransferencia?.productos?.length ?? 0}');
    } catch (e, stackTrace) {
      debugPrint('❌ [TransferenciaDetailDialog] Error al cargar detalles: $e');
      debugPrint('📋 [TransferenciaDetailDialog] StackTrace: $stackTrace');

      if (!mounted) {
        return;
      }

      // Si hay un error, usamos los datos que ya tenemos
      setState(() {
        _detalleTransferencia = widget.transferencia;
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        padding: const EdgeInsets.all(24),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // Estado de carga
    if (_isLoading) {
      return _buildLoadingContent();
    }

    // Estado de error
    if (_errorMessage != null && _retryCount < 2) {
      return _buildErrorContent();
    }

    // Estado normal - muestra los detalles usando el movimiento actual
    // (ya sea el cargado exitosamente o el original como fallback)
    return _buildDetailContent();
  }

  // Widget para mostrar estado de carga
  Widget _buildLoadingContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const CircularProgressIndicator(
          color: Color(0xFFE31E24),
          strokeWidth: 3,
        ),
        const SizedBox(height: 24),
        Text(
          'Cargando detalles de la transferencia #${widget.transferencia.id}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Esto puede tomar unos segundos',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // Widget para mostrar estado de error
  Widget _buildErrorContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text(
          'Error al cargar los detalles',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'No se pudieron cargar los detalles completos de la transferencia #${widget.transferencia.id}.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Error: $_errorMessage',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
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
                  _detalleTransferencia = widget.transferencia;
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
    );
  }

  // Widget para mostrar los detalles del movimiento
  Widget _buildDetailContent() {
    // Movimiento a mostrar (ya sea el detallado o el original)
    final TransferenciaInventario transferencia =
        _detalleTransferencia ?? widget.transferencia;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildHeader(context),
        const Divider(color: Colors.white24),
        const SizedBox(height: 16),

        // Mensaje de error si hubo problemas cargando detalles pero seguimos adelante
        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.5)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mostrando información parcial. Algunos detalles podrían no estar disponibles.',
                    style:
                        TextStyle(color: Colors.orange.shade200, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        // Información general
        _buildGeneralInfo(transferencia),
        const SizedBox(height: 16),

        _buildSucursalesInfo(transferencia),
        const SizedBox(height: 24),

        // Productos
        _buildProductosSection(transferencia),
        const SizedBox(height: 24),

        // Observaciones
        _buildObservacionesSection(transferencia),

        const SizedBox(height: 24),

        // Botón para cerrar
        Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31E24),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Cerrar'),
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
        const Text(
          'Detalle de Transferencia',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // Información general del movimiento
  Widget _buildGeneralInfo(TransferenciaInventario transferencia) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _buildInfoItem(
            'ID',
            transferencia.id.toString(),
            FontAwesomeIcons.hashtag,
          ),
        ),
        Expanded(
          child: _buildInfoItem(
            'Fecha Creación',
            _formatFecha(transferencia.salidaOrigen),
            FontAwesomeIcons.calendar,
          ),
        ),
        Expanded(
          child: _buildInfoItem(
            'Estado',
            transferencia.estado.nombre,
            FontAwesomeIcons.circleInfo,
          ),
        ),
      ],
    );
  }

  // Información de sucursales
  Widget _buildSucursalesInfo(TransferenciaInventario transferencia) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _buildInfoItem(
            'Sucursal Origen',
            transferencia.nombreSucursalOrigen ?? 'Sin información',
            FontAwesomeIcons.building,
          ),
        ),
        Expanded(
          child: _buildInfoItem(
            'Sucursal Destino',
            transferencia.nombreSucursalDestino,
            FontAwesomeIcons.building,
          ),
        ),
      ],
    );
  }

  // Sección de productos
  Widget _buildProductosSection(TransferenciaInventario transferencia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Productos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (transferencia.productos != null &&
            transferencia.productos!.isNotEmpty)
          _buildProductosList(transferencia)
        else
          const Text(
            'No hay productos disponibles para mostrar en esta transferencia',
            style: TextStyle(color: Colors.white70),
          ),
      ],
    );
  }

  // Lista de productos
  Widget _buildProductosList(TransferenciaInventario transferencia) {
    // Debug para verificar qué contiene productos
    debugPrint(
        '📦 Productos en el movimiento: ${transferencia.productos?.length ?? 0}');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      // Usamos ConstrainedBox para evitar problemas de altura con ListView
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 300, // Altura máxima para evitar desbordamientos
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: transferencia.productos!.length,
          itemBuilder: (BuildContext context, int index) {
            final DetalleProducto producto = transferencia.productos![index];
            return ListTile(
              title: Text(
                producto.nombre,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: producto.codigo != null
                  ? Text(
                      'Código: ${producto.codigo}',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    )
                  : null,
              trailing: Text(
                'Cantidad: ${producto.cantidad}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Sección de observaciones
  Widget _buildObservacionesSection(TransferenciaInventario transferencia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Observaciones',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            transferencia.observaciones ?? 'Sin observaciones',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  // Widget para mostrar un elemento de información
  Widget _buildInfoItem(String titulo, String valor, IconData icono) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            FaIcon(
              icono,
              size: 12,
              color: const Color(0xFFE31E24),
            ),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
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
}
