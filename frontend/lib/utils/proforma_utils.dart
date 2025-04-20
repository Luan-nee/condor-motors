import 'package:condorsmotors/models/proforma.model.dart';
import 'package:condorsmotors/utils/ventas_utils.dart';
import 'package:flutter/material.dart';

class ProformaUtils {
  /// Verifica si un detalle tiene descuento
  static bool tieneDescuento(DetalleProforma detalle) {
    return detalle.descuento != null && detalle.descuento! > 0;
  }

  /// Obtiene el valor del descuento formateado
  static String getDescuento(DetalleProforma detalle) {
    return detalle.descuento?.toString() ?? '0';
  }

  /// Obtiene el precio original antes del descuento
  static double? getPrecioOriginal(DetalleProforma detalle) {
    return detalle.precioOriginal;
  }

  /// Verifica si hay unidades gratis
  static bool tieneUnidadesGratis(DetalleProforma detalle) {
    return detalle.cantidadGratis != null && detalle.cantidadGratis! > 0;
  }

  /// Obtiene cantidad de unidades gratis
  static int getCantidadGratis(DetalleProforma detalle) {
    return detalle.cantidadGratis ?? 0;
  }

  /// Obtiene cantidad de unidades pagadas
  static int getCantidadPagada(DetalleProforma detalle) {
    return detalle.cantidadPagada ?? detalle.cantidad;
  }

  /// Extrae el número de documento del cliente
  static String? extraerNumeroDocumentoCliente(Map<String, dynamic>? cliente) {
    return cliente?['numeroDocumento'];
  }

  /// Widget reutilizable para mostrar diálogo de procesamiento
  static Widget buildProcessingDialog(String documentType) {
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

  /// Widget reutilizable para mostrar información de precio con descuento
  static Widget buildPrecioColumn(DetalleProforma detalle) {
    final bool hasDescuento = tieneDescuento(detalle);
    final String descuento = getDescuento(detalle);
    final double? precioOriginal = getPrecioOriginal(detalle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (hasDescuento && precioOriginal != null)
          Text(
            VentasUtils.formatearMontoTexto(precioOriginal),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        Text(
          VentasUtils.formatearMontoTexto(detalle.precioUnitario),
          style: TextStyle(
            color: hasDescuento ? Colors.green : Colors.white,
            fontWeight: hasDescuento ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (hasDescuento)
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

  /// Widget reutilizable para mostrar información de cantidad
  static Widget buildCantidadColumn(DetalleProforma detalle) {
    final bool hasUnidadesGratis = tieneUnidadesGratis(detalle);
    final int cantidadGratis = getCantidadGratis(detalle);
    final int cantidadPagada = getCantidadPagada(detalle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${detalle.cantidad}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (hasUnidadesGratis)
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
}
