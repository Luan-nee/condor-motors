import 'package:condorsmotors/models/ventas.model.dart';
import 'package:condorsmotors/utils/ventas_utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class VentaInfoCard extends StatelessWidget {
  final Venta venta;
  final bool isLoadingFullData;

  const VentaInfoCard({
    super.key,
    required this.venta,
    this.isLoadingFullData = false,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat formatoMoneda = NumberFormat.currency(
      symbol: 'S/ ',
      decimalDigits: 2,
    );

    final String idVenta = venta.id.toString();
    final String estadoText = venta.estado.toText();
    final double total = venta.calcularTotal();
    final String tipoDocumento = venta.tipoDocumento ?? 'No especificado';
    final String serie = venta.serieDocumento;
    final String numero = venta.numeroDocumento;
    final String clienteNombre =
        venta.clienteDetalle?.denominacion ?? 'Cliente no especificado';
    final String horaEmision = venta.horaEmision;
    final String empleado =
        venta.empleadoDetalle?.getNombreCompleto() ?? 'No especificado';
    final String sucursal =
        venta.sucursalDetalle?.nombre ?? 'No especificada';

    final Color estadoColor = VentasUtils.getEstadoColor(estadoText);
    final String estadoFormateado = VentasUtils.getEstadoTexto(estadoText);
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Información General',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _buildInfoItem('ID de Venta', idVenta, isSmallScreen),
              _buildInfoItem(
                'Estado',
                '',
                isSmallScreen,
                customValue: _buildEstadoBadge(estadoColor, estadoFormateado, venta),
              ),
              _buildInfoItem('Total', formatoMoneda.format(total), isSmallScreen, isPrice: true),
              _buildInfoItem('Tipo Documento', tipoDocumento, isSmallScreen),
              _buildInfoItem('Serie-Número', serie.isNotEmpty ? '$serie-$numero' : '---', isSmallScreen),
              _buildInfoItem('Hora Emisión', horaEmision.isNotEmpty ? horaEmision : '---', isSmallScreen),
              _buildInfoItem('Cliente', clienteNombre, isSmallScreen),
              _buildInfoItem('Empleado', empleado, isSmallScreen),
              _buildInfoItem('Sucursal', sucursal, isSmallScreen),
            ],
          ),
          
          if (venta.anulada || venta.cancelada || venta.declarada)
            _buildSpecialStatusBanner(venta),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isSmallScreen, {Widget? customValue, bool isPrice = false}) {
    return SizedBox(
      width: isSmallScreen ? double.infinity : 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          customValue ??
              Text(
                value,
                style: TextStyle(
                  color: isPrice ? const Color(0xFFE31E24) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
        ],
      ),
    );
  }

  Widget _buildEstadoBadge(Color color, String text, Venta venta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
          ),
          if (venta.anulada || venta.declarada || venta.cancelada) ...[
            const SizedBox(width: 4),
            Icon(
              venta.anulada ? Icons.error_outline : Icons.check_circle_outline,
              size: 12,
              color: color,
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSpecialStatusBanner(Venta venta) {
    final bool isAnulada = venta.anulada;
    final bool isCancelada = venta.cancelada;
    final Color bannerColor = isAnulada ? Colors.red : (isCancelada ? Colors.orange : Colors.green);
    
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bannerColor.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: bannerColor.withAlpha(77)),
        ),
        child: Row(
          children: [
            FaIcon(
              isAnulada ? FontAwesomeIcons.ban : (isCancelada ? FontAwesomeIcons.stop : FontAwesomeIcons.circleCheck),
              color: bannerColor,
              size: 14,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isAnulada 
                  ? 'VENTA ANULADA: Este documento no tiene validez legal.' 
                  : isCancelada 
                      ? 'VENTA CANCELADA.' 
                      : 'TRANSACCIÓN COMPLETADA Y DECLARADA.',
                style: TextStyle(color: bannerColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
