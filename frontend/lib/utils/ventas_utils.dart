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
} 