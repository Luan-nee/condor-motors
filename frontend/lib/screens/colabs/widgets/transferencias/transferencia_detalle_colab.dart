import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/providers/colabs/transferencias.colab.provider.dart';
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
                        color: _getEstadoColor(transferencia.estado)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        transferencia.estado.nombre,
                        style: TextStyle(
                          color: _getEstadoColor(transferencia.estado),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(TransferenciaInventario transferencia, bool isMobile) {
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
          _buildInfoRow(
            'Sucursal Origen',
            transferencia.nombreSucursalOrigen,
            FontAwesomeIcons.store,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Sucursal Destino',
            transferencia.nombreSucursalDestino,
            FontAwesomeIcons.locationDot,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Fecha de Creación',
            transferencia.salidaOrigen?.toString() ?? 'No registrada',
            FontAwesomeIcons.calendar,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Fecha de Llegada',
            transferencia.llegadaDestino?.toString() ?? 'Pendiente',
            FontAwesomeIcons.clock,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Total de Productos',
            '${transferencia.getCantidadTotal()} items',
            FontAwesomeIcons.boxOpen,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, IconData icon) {
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
                value ?? 'No especificado',
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

  Widget _buildProductList(
      TransferenciaInventario transferencia, bool isMobile) {
    if (transferencia.productos == null || transferencia.productos!.isEmpty) {
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
                decoration: BoxDecoration(
                  color: const Color(0xFFE31E24).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${transferencia.getCantidadTotal()} items',
                  style: const TextStyle(
                    color: Color(0xFFE31E24),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transferencia.productos!.length,
            itemBuilder: (context, index) {
              final producto = transferencia.productos![index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFE31E24).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
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
    switch (estado) {
      case EstadoTransferencia.pedido:
        return Colors.orange;
      case EstadoTransferencia.enviado:
        return Colors.blue;
      case EstadoTransferencia.recibido:
        return const Color(0xFF43A047);
    }
  }
}
