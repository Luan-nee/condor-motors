import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/providers/colabs/transferencias.colab.provider.dart';
import 'package:condorsmotors/utils/transferencias_utils.dart';
import 'package:condorsmotors/screens/colabs/transferencias_colab.dart';
import 'package:condorsmotors/screens/colabs/widgets/transferencias/transferencia_comparar_colab.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class TransferenciaDetalleColab extends StatefulWidget {
  final String transferenciaid;

  const TransferenciaDetalleColab({
    super.key,
    required this.transferenciaid,
  });

  @override
  State<TransferenciaDetalleColab> createState() =>
      _TransferenciaDetalleColabState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('transferenciaid', transferenciaid));
  }
}

class _TransferenciaDetalleColabState extends State<TransferenciaDetalleColab> {
  late Future<TransferenciaInventario> _futureTransferencia;
  late final TransferenciasColabProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<TransferenciasColabProvider>();
    _cargarTransferencia();
  }

  void _cargarTransferencia() {
    _futureTransferencia =
        _provider.obtenerDetalleTransferencia(widget.transferenciaid);
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Detalle de Transferencia',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowsRotate),
            onPressed: () {
              setState(() {
                _cargarTransferencia();
              });
            },
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: FutureBuilder<TransferenciaInventario>(
        future: _futureTransferencia,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.circleExclamation,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar la transferencia: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _cargarTransferencia();
                      });
                    },
                    icon: const FaIcon(FontAwesomeIcons.arrowsRotate),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                'No se encontró la transferencia',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final TransferenciaInventario transferencia = snapshot.data!;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(transferencia, isMobile),
                const SizedBox(height: 24),
                _buildInfoCard(transferencia, isMobile),
                const SizedBox(height: 24),
                _buildProductList(transferencia, isMobile),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(TransferenciaInventario transferencia, bool isMobile) {
    final estadoEstilo =
        TransferenciasUtils.getEstadoEstilo(transferencia.estado);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE31E24).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.truck,
                  color: Color(0xFFE31E24),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRF${transferencia.id}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: estadoEstilo['backgroundColor'],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        estadoEstilo['estadoDisplay'],
                        style: TextStyle(
                          color: estadoEstilo['textColor'],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (transferencia.estado == EstadoTransferencia.pedido)
                ElevatedButton.icon(
                  onPressed: () => _procesarEnvio(transferencia),
                  icon: const FaIcon(
                    FontAwesomeIcons.paperPlane,
                    size: 16,
                  ),
                  label: const Text('Enviar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31E24),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _procesarEnvio(TransferenciaInventario transferencia) async {
    final provider = context.read<TransferenciasColabProvider>();

    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
        ),
      ),
    );

    try {
      // Obtener datos de comparación usando el nuevo endpoint
      if (provider.sucursalId == null) {
        throw Exception('No se pudo obtener el ID de la sucursal del usuario');
      }

      debugPrint(
          'Obteniendo comparación para transferencia ${transferencia.id}');
      final comparacion = await provider.obtenerComparacionTransferencia(
        transferencia.id.toString(),
      );

      // Cerrar diálogo de carga
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar diálogo de comparación
      if (mounted) {
        final bool? confirmarEnvio =
            await _mostrarDialogoComparacion(comparacion);

        // Si el usuario confirmó, proceder con el envío
        if (confirmarEnvio == true) {
          await _enviarTransferencia(transferencia);
        }
      }
    } catch (e) {
      // Cerrar diálogo de carga si hay error
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar stocks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _mostrarDialogoComparacion(
      ComparacionTransferencia comparacion) {
    return showDialog<bool>(
      context: context,
      builder: (context) => TransferenciaCompararColab(
        comparacion: comparacion,
        onCancel: () => Navigator.of(context).pop(false),
        onConfirm: () async {
          // Si hay productos con stock bajo, mostrar diálogo de confirmación
          if (comparacion.productosConStockBajo.isNotEmpty) {
            final confirmar = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF2D2D2D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: const Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.triangleExclamation,
                      color: Colors.orange,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Precaución',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Hay ${comparacion.productosConStockBajo.length} ${comparacion.productosConStockBajo.length == 1 ? 'producto' : 'productos'} que quedarán con stock bajo después de la transferencia. ¿Está seguro que desea continuar?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const FaIcon(
                      FontAwesomeIcons.check,
                      size: 16,
                    ),
                    label: const Text('Confirmar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            );

            if (confirmar == true) {
              Navigator.of(context).pop(true);
            }
          } else {
            Navigator.of(context).pop(true);
          }
        },
      ),
    );
  }

  Future<void> _enviarTransferencia(
      TransferenciaInventario transferencia) async {
    try {
      await context
          .read<TransferenciasColabProvider>()
          .enviarTransferencia(transferencia);

      // Mostrar mensaje de éxito y redirigir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transferencia enviada correctamente'),
            backgroundColor: Color(0xFF43A047),
          ),
        );

        // Redirigir a la pantalla de transferencias
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const TransferenciasColabScreen(),
          ),
        );
      }
    } catch (e) {
      // Mostrar mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar transferencia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoCard(TransferenciaInventario transferencia, bool isMobile) {
    // Lista de campos de información que no son nulos
    final List<({String label, String value, IconData icon})> infoFields = [
      (
        label: 'Sucursal Origen',
        value: transferencia.nombreSucursalOrigen ?? 'No asignada',
        icon: FontAwesomeIcons.store
      ),
      (
        label: 'Sucursal Destino',
        value: transferencia.nombreSucursalDestino,
        icon: FontAwesomeIcons.locationDot
      ),
      if (transferencia.salidaOrigen != null)
        (
          label: 'Fecha de Creación',
          value: _formatDateTime(transferencia.salidaOrigen!),
          icon: FontAwesomeIcons.calendar
        ),
      if (transferencia.llegadaDestino != null)
        (
          label: 'Fecha de Llegada',
          value: _formatDateTime(transferencia.llegadaDestino!),
          icon: FontAwesomeIcons.clock
        ),
      (
        label: 'Total de Productos',
        value: '${transferencia.productos?.length ?? 0} items',
        icon: FontAwesomeIcons.boxOpen
      ),
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de la Transferencia',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...infoFields.map((field) => Column(
                children: [
                  _buildInfoRow(
                    label: field.label,
                    value: field.value,
                    icon: field.icon,
                  ),
                  const SizedBox(height: 12),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE31E24).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(
            icon,
            color: const Color(0xFFE31E24),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final date = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  Widget _buildProductList(
      TransferenciaInventario transferencia, bool isMobile) {
    final productos = transferencia.productos ?? [];
    debugPrint('Productos en transferencia: ${productos.length}');

    if (productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.boxOpen,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos en esta transferencia',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Productos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: TransferenciasUtils.getProductCountBadgeStyle(),
                child: Text(
                  '${productos.length} productos',
                  style: const TextStyle(
                    color: Color(0xFFE31E24),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: productos.length,
            separatorBuilder: (context, index) => const Divider(
              color: Colors.grey,
              height: 1,
            ),
            itemBuilder: (context, index) {
              final producto = productos[index];
              debugPrint(
                  'Construyendo producto: ${producto.nombre} - Cantidad: ${producto.cantidad}');
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE31E24).withOpacity(0.1),
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
                          ),
                          if (producto.codigo != null)
                            Text(
                              'Código: ${producto.codigo}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration:
                          TransferenciasUtils.getProductCountBadgeStyle(),
                      child: Text(
                        '${producto.cantidad} unidades',
                        style: const TextStyle(
                          color: Color(0xFFE31E24),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(EstadoTransferencia estado) {
    return TransferenciasUtils.getEstadoColor(estado);
  }
}
