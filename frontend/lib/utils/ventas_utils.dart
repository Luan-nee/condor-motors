import 'package:condorsmotors/models/ventas.model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utilidades para el manejo de ventas
class VentasUtils {
  /// Formatea un monto numérico como moneda
  static String formatearMonto(double monto) {
    final NumberFormat formatoMoneda = NumberFormat.currency(
      symbol: 'S/',
      decimalDigits: 2,
      locale: 'es_PE',
    );
    return formatoMoneda.format(monto);
  }

  /// Formatea un monto como texto para mostrar en la UI
  static String formatearMontoTexto(double monto) {
    final String montoFormateado = formatearMonto(monto);
    // Para montos negativos, mantener el signo
    if (monto < 0) {
      return montoFormateado;
    }
    return montoFormateado;
  }

  /// Calcula el vuelto a partir de un pago y un total
  static double calcularVuelto(double pagoRecibido, double totalVenta) {
    return pagoRecibido - totalVenta;
  }

  /// Verifica si un pago es suficiente para cubrir el total
  static bool esPagoSuficiente(double pagoRecibido, double totalVenta) {
    return pagoRecibido >= totalVenta;
  }

  /// Calcula el IGV (18%) a partir de un subtotal
  static double calcularIGV(double subtotal) {
    return subtotal * 0.18;
  }

  /// Calcula el subtotal a partir de un total con IGV
  static double calcularSubtotalDesdeTotal(double total) {
    return total / 1.18;
  }

  /// Formatea una fecha para mostrar en la UI
  static String formatearFecha(DateTime fecha) {
    final DateFormat formatoFecha = DateFormat('dd/MM/yyyy HH:mm');
    return formatoFecha.format(fecha);
  }

  /// Formatea solo la fecha (sin hora) para mostrar en la UI
  static String formatearSoloFecha(DateTime fecha) {
    final DateFormat formatoFecha = DateFormat('dd/MM/yyyy');
    return formatoFecha.format(fecha);
  }

  /// Formatea solo la hora para mostrar en la UI
  static String formatearSoloHora(DateTime fecha) {
    final DateFormat formatoHora = DateFormat('HH:mm');
    return formatoHora.format(fecha);
  }

  /// Obtiene el color según el estado de una venta
  static Color getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'COMPLETADA':
      case 'ACEPTADO-SUNAT':
      case 'ACEPTADO ANTE LA SUNAT':
        return Colors.green;
      case 'ANULADA':
        return Colors.red;
      case 'CANCELADA':
        return Colors.orange.shade900;
      case 'DECLARADA':
        return Colors.blue;
      case 'PENDIENTE':
      default:
        return Colors.orange;
    }
  }

  /// Obtiene el texto de estado formateado para mostrar en UI
  static String getEstadoTexto(String estado) {
    switch (estado.toUpperCase()) {
      case 'COMPLETADA':
        return 'Completada';
      case 'ANULADA':
        return 'Anulada';
      case 'CANCELADA':
        return 'Cancelada';
      case 'DECLARADA':
        return 'Declarada';
      case 'ACEPTADO-SUNAT':
      case 'ACEPTADO ANTE LA SUNAT':
        return 'Aceptado por SUNAT';
      case 'PENDIENTE':
        return 'Pendiente';
      default:
        return estado;
    }
  }

  /// Obtiene el ícono correspondiente al estado de la venta
  static IconData getEstadoIcono(String estado) {
    switch (estado.toUpperCase()) {
      case 'COMPLETADA':
      case 'ACEPTADO-SUNAT':
      case 'ACEPTADO ANTE LA SUNAT':
        return Icons.check_circle;
      case 'ANULADA':
        return Icons.cancel;
      case 'CANCELADA':
        return Icons.block;
      case 'DECLARADA':
        return Icons.verified;
      case 'PENDIENTE':
      default:
        return Icons.hourglass_empty;
    }
  }

  /// Formatea el número de documento de venta (serie-número)
  static String formatearNumeroDocumento(Venta venta) {
    if (venta.serieDocumento.isNotEmpty && venta.numeroDocumento.isNotEmpty) {
      return '${venta.serieDocumento}-${venta.numeroDocumento}';
    }
    return venta.id?.toString() ?? '';
  }

  /// Formatea el número de documento de venta desde un Map (para compatibilidad)
  static String formatearNumeroDocumentoDesdeMap(Map<String, dynamic> venta) {
    final String serie = (venta['serieDocumento'] ?? '').toString();
    final String numero = (venta['numeroDocumento'] ?? '').toString();

    if (serie.isNotEmpty && numero.isNotEmpty) {
      return '$serie-$numero';
    }
    return venta['id'].toString();
  }

  /// Verifica si una venta tiene PDF disponible
  static bool tienePdfDisponible(Venta venta) {
    return venta.documentoFacturacion != null &&
        venta.documentoFacturacion!.linkPdf != null;
  }

  /// Verifica si una venta tiene PDF en formato ticket disponible
  static bool tienePdfTicketDisponible(Venta venta) {
    return venta.documentoFacturacion != null &&
        venta.documentoFacturacion!.linkPdfTicket != null;
  }

  /// Obtiene la URL del PDF de una venta en el formato solicitado
  static String? obtenerUrlPdf(Venta venta, {bool formatoTicket = false}) {
    if (venta.documentoFacturacion == null) {
      return null;
    }

    if (formatoTicket) {
      return venta.documentoFacturacion!.linkPdfTicket ??
          venta.documentoFacturacion!.linkPdf;
    }
    return venta.documentoFacturacion!.linkPdfA4 ??
        venta.documentoFacturacion!.linkPdf;
  }

  /// Formatea el nombre del cliente para mostrar en UI
  static String formatearNombreCliente(Venta venta) {
    if (venta.clienteDetalle != null) {
      return venta.clienteDetalle!.denominacion;
    }
    return 'Cliente #${venta.clienteId}';
  }

  /// Formatea el nombre del vendedor para mostrar en UI
  static String formatearNombreVendedor(Venta venta) {
    if (venta.empleadoDetalle != null) {
      return venta.empleadoDetalle!.getNombreCompleto();
    }
    return 'Vendedor #${venta.empleadoId}';
  }

  /// Formatea el nombre de la sucursal para mostrar en UI
  static String formatearNombreSucursal(Venta venta) {
    if (venta.sucursalDetalle != null) {
      return venta.sucursalDetalle!.nombre;
    }
    return 'Sucursal #${venta.sucursalId}';
  }

  /// Formatea el total de la venta para mostrar en UI
  static String formatearTotalVenta(Venta venta) {
    return formatearMonto(venta.calcularTotal());
  }

  /// Genera un texto descriptivo del estado de declaración SUNAT
  static String getEstadoDeclaracionTexto(Venta venta) {
    if (!venta.declarada) {
      return 'No declarada';
    }

    if (venta.documentoFacturacion == null) {
      return 'Declarada (sin detalles)';
    }

    final doc = venta.documentoFacturacion!;
    if (doc.descripcionEstado != null && doc.descripcionEstado!.isNotEmpty) {
      return doc.descripcionEstado!;
    }

    if (doc.codigoEstadoSunat != null && doc.codigoEstadoSunat!.isNotEmpty) {
      return 'Estado SUNAT: ${doc.codigoEstadoSunat}';
    }

    return 'Declarada';
  }

  /// Determina si se debe mostrar el botón de declaración SUNAT
  static bool mostrarBotonDeclaracion(Venta venta) {
    // Mostrar botón solo si la venta está completada, no anulada, no cancelada y no declarada
    return !venta.anulada &&
        !venta.cancelada &&
        !venta.declarada &&
        venta.estado == EstadoVenta.completada;
  }

  /// Determina si se debe mostrar el botón de anulación
  static bool mostrarBotonAnulacion(Venta venta) {
    // Mostrar botón solo si la venta está completada, no anulada, no cancelada
    return !venta.anulada &&
        !venta.cancelada &&
        venta.estado == EstadoVenta.completada;
  }

  /// Determina si se debe mostrar el botón de cancelación
  static bool mostrarBotonCancelacion(Venta venta) {
    // Mostrar botón solo si la venta está pendiente, no anulada, no cancelada
    return !venta.anulada &&
        !venta.cancelada &&
        venta.estado == EstadoVenta.pendiente;
  }
}
