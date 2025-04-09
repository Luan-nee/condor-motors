import 'package:condorsmotors/models/sucursal.model.dart' as sucursal_model;
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
  ComparacionTransferencia? _comparacionTransferencia;
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint(
          '⏳ [TransferenciaDetailDialog] Cargando detalles de la transferencia #${widget.transferencia.id}');

      final TransferenciasProvider transferenciasProvider =
          Provider.of<TransferenciasProvider>(context, listen: false);

      // Obtener detalle de la transferencia
      final TransferenciaInventario detalleTransferencia =
          await transferenciasProvider.obtenerDetalleTransferencia(
        widget.transferencia.id.toString(),
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

      setState(() {
        _detalleTransferencia = widget.transferencia;
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _cargarComparacion(int sucursalId) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
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

      setState(() {
        _comparacionTransferencia = comparacion;
        _isLoading = false;
      });

      debugPrint(
          '✅ [TransferenciaDetailDialog] Comparación cargada correctamente');
    } catch (e) {
      debugPrint(
          '❌ [TransferenciaDetailDialog] Error al cargar comparación: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _comparacionTransferencia = null;
        _isLoading = false;
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
    return _buildDetailContent(context, isWideScreen, isMediumScreen);
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
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Widget para mostrar estado de error
  Widget _buildErrorContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 24),
            Text(
              'Error al cargar los detalles',
              style: const TextStyle(
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
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
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
        ),
      ),
    );
  }

  // Widget para mostrar los detalles del movimiento
  Widget _buildDetailContent(
      BuildContext context, bool isWideScreen, bool isMediumScreen) {
    // Movimiento a mostrar (ya sea el detallado o el original)
    final TransferenciaInventario transferencia =
        _detalleTransferencia ?? widget.transferencia;

    return SingleChildScrollView(
      child: Column(
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mostrando información parcial. Algunos detalles podrían no estar disponibles.',
                      style: TextStyle(
                          color: Colors.orange.shade200, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

          // Layout adaptativo para información general y sucursales
          if (isWideScreen)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Información General',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildGeneralInfoRow(transferencia),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Sucursales',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSucursalesInfoRow(transferencia),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Información General',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGeneralInfoRow(transferencia),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Sucursales',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSucursalesInfoRow(transferencia),
                    ],
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Selector de sucursal para comparación
          _buildSucursalSelector(),

          const SizedBox(height: 24),

          // Productos y Observaciones
          if (isWideScreen)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildProductosSectionCard(transferencia),
                      if (_comparacionTransferencia != null) ...[
                        const SizedBox(height: 16),
                        _buildComparacionSectionCard(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: _buildObservacionesSectionCard(transferencia),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildProductosSectionCard(transferencia),
                if (_comparacionTransferencia != null) ...[
                  const SizedBox(height: 16),
                  _buildComparacionSectionCard(),
                ],
                const SizedBox(height: 16),
                _buildObservacionesSectionCard(transferencia),
              ],
            ),

          const SizedBox(height: 24),

          Center(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Cerrar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31E24),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ),
        ],
      ),
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
                color: const Color(0xFFE31E24).withOpacity(0.2),
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
  Widget _buildGeneralInfoRow(TransferenciaInventario transferencia) {
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
  Widget _buildSucursalesInfoRow(TransferenciaInventario transferencia) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _buildInfoItem(
            'Sucursal Origen',
            transferencia.nombreSucursalOrigen,
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

  // Sección de productos en tarjeta
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
            children: <Widget>[
              const FaIcon(
                FontAwesomeIcons.box,
                size: 16,
                color: Color(0xFFE31E24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Productos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              if (transferencia.productos != null &&
                  transferencia.productos!.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE31E24).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${transferencia.productos!.length} productos',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (transferencia.productos != null &&
              transferencia.productos!.isNotEmpty)
            _buildProductosList(transferencia)
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No hay productos disponibles para mostrar en esta transferencia',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Sección de observaciones en tarjeta
  Widget _buildObservacionesSectionCard(TransferenciaInventario transferencia) {
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
            children: const <Widget>[
              FaIcon(
                FontAwesomeIcons.fileLines,
                size: 16,
                color: Color(0xFFE31E24),
              ),
              SizedBox(width: 12),
              Text(
                'Observaciones',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              transferencia.observaciones ?? 'Sin observaciones',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
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
          maxHeight: 350, // Altura máxima ajustada
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: transferencia.productos!.length,
          separatorBuilder: (BuildContext context, int index) => const Divider(
            color: Colors.white10,
            height: 1,
          ),
          itemBuilder: (BuildContext context, int index) {
            final DetalleProducto producto = transferencia.productos![index];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.boxOpen,
                  color: Color(0xFFE31E24),
                  size: 16,
                ),
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
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    )
                  : null,
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE31E24).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE31E24).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Cantidad: ${producto.cantidad}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Widget para mostrar un elemento de información
  Widget _buildInfoItem(String titulo, String? valor, IconData icono) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            FaIcon(
              icono,
              size: 14,
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
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 22),
          child: Text(
            valor ?? 'N/A',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
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

  // Nuevo widget para mostrar la comparación de stocks
  Widget _buildComparacionSectionCard() {
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
            children: const <Widget>[
              FaIcon(
                FontAwesomeIcons.scaleBalanced,
                size: 16,
                color: Color(0xFFE31E24),
              ),
              SizedBox(width: 12),
              Text(
                'Comparación de Stock',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_comparacionTransferencia?.productos != null)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _comparacionTransferencia!.productos.length,
                separatorBuilder: (context, index) => const Divider(
                  color: Colors.white10,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final producto = _comparacionTransferencia!.productos[index];
                  return ListTile(
                    title: Text(
                      producto.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock Origen: ${producto.stockOrigenActual} → ${producto.stockOrigenResultante}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          'Stock Destino: ${producto.stockDestinoActual} → ${producto.stockDestinoActual + producto.cantidadSolicitada}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE31E24).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE31E24).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Cant: ${producto.cantidadSolicitada}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            const Center(
              child: Text(
                'No hay datos de comparación disponibles',
                style: TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }

  // Widget para seleccionar sucursal
  Widget _buildSucursalSelector() {
    final TransferenciasProvider transferenciasProvider =
        Provider.of<TransferenciasProvider>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seleccionar Sucursal para Comparación',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<sucursal_model.Sucursal>(
            value: _sucursalSeleccionada,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF2D2D2D),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            dropdownColor: const Color(0xFF2D2D2D),
            style: const TextStyle(color: Colors.white),
            items: [
              for (var sucursal in transferenciasProvider.sucursales)
                DropdownMenuItem<sucursal_model.Sucursal>(
                  value: sucursal,
                  child: Text(sucursal.nombre),
                ),
            ],
            onChanged: (sucursal_model.Sucursal? sucursal) {
              if (sucursal != null) {
                setState(() {
                  _sucursalSeleccionada = sucursal;
                });
                _cargarComparacion(int.parse(sucursal.id));
              }
            },
            hint: const Text(
              'Seleccione una sucursal',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
