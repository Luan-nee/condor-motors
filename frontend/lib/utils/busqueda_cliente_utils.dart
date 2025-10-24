import 'package:condorsmotors/models/cliente.model.dart';
import 'package:flutter/foundation.dart';

/// Tipos de documentos disponibles para filtrar clientes
enum TipoDocumento { todos, dni, cedula, ruc, pasaporte, otros }

/// Utilidades para el manejo de búsqueda y filtrado de clientes
class BusquedaClienteUtils {
  /// Obtiene el tipo de documento basado en el número
  static TipoDocumento detectarTipoDocumento(String numeroDocumento) {
    if (numeroDocumento.isEmpty) {
      return TipoDocumento.otros;
    }

    // Limpiar el número de documento
    final String numero = numeroDocumento.trim();

    // DNI: 8 dígitos
    if (numero.length == 8 && RegExp(r'^\d{8}$').hasMatch(numero)) {
      return TipoDocumento.dni;
    }

    // Cédula: 10 dígitos
    if (numero.length == 10 && RegExp(r'^\d{10}$').hasMatch(numero)) {
      return TipoDocumento.cedula;
    }

    // RUC: 11 dígitos comenzando con 10 o 20
    if (numero.length == 11 && RegExp(r'^[12][0]\d{9}$').hasMatch(numero)) {
      return TipoDocumento.ruc;
    }

    // Pasaporte: Alfanumérico
    if (RegExp(r'^[A-Z0-9]{6,12}$').hasMatch(numero)) {
      return TipoDocumento.pasaporte;
    }

    return TipoDocumento.otros;
  }

  /// Filtra clientes por texto y tipo de documento
  static List<Cliente> filtrarClientes({
    required List<Cliente> clientes,
    required String filtroTexto,
    TipoDocumento tipoDocumento = TipoDocumento.todos,
    bool debugMode = false,
  }) {
    if (debugMode) {
      debugPrint('Iniciando filtrado de clientes...');
      debugPrint('Total clientes antes de filtrar: ${clientes.length}');
    }

    final String filtro = filtroTexto.toLowerCase().trim();
    final List<Cliente> clientesFiltrados = clientes.where((Cliente cliente) {
      // Filtrar por tipo de documento si está seleccionado
      if (tipoDocumento != TipoDocumento.todos) {
        final TipoDocumento tipoActual =
            detectarTipoDocumento(cliente.numeroDocumento);
        if (tipoActual != tipoDocumento) {
          return false;
        }
      }

      // Filtrar por texto (nombre, denominación o número de documento)
      return filtro.isEmpty ||
          cliente.denominacion.toLowerCase().contains(filtro) ||
          cliente.numeroDocumento.toLowerCase().contains(filtro) ||
          cliente.nombre.toLowerCase().contains(filtro);
    }).toList()

      // Ordenar resultados
      ..sort((Cliente a, Cliente b) {
        // Primero por tipo de documento
        final int tipoComparacion = detectarTipoDocumento(a.numeroDocumento)
            .index
            .compareTo(detectarTipoDocumento(b.numeroDocumento).index);

        if (tipoComparacion != 0) {
          return tipoComparacion;
        }

        // Luego por denominación
        return a.denominacion
            .toLowerCase()
            .compareTo(b.denominacion.toLowerCase());
      });

    if (debugMode) {
      debugPrint('Clientes filtrados: ${clientesFiltrados.length}');
      debugPrint('- Filtro texto: "$filtroTexto"');
      debugPrint('- Tipo documento: $tipoDocumento');
    }

    return clientesFiltrados;
  }

  /// Obtiene el nombre amigable del tipo de documento
  static String getNombreTipoDocumento(TipoDocumento tipo) {
    switch (tipo) {
      case TipoDocumento.dni:
        return 'DNI';
      case TipoDocumento.cedula:
        return 'Cédula';
      case TipoDocumento.ruc:
        return 'RUC';
      case TipoDocumento.pasaporte:
        return 'Pasaporte';
      case TipoDocumento.otros:
        return 'Otros';
      case TipoDocumento.todos:
        return 'Todos';
    }
  }

  /// Obtiene el color asociado al tipo de documento
  static String getColorTipoDocumento(TipoDocumento tipo) {
    switch (tipo) {
      case TipoDocumento.dni:
        return '#2196F3'; // Azul
      case TipoDocumento.cedula:
        return '#4CAF50'; // Verde
      case TipoDocumento.ruc:
        return '#9C27B0'; // Morado
      case TipoDocumento.pasaporte:
        return '#FF9800'; // Naranja
      case TipoDocumento.otros:
        return '#757575'; // Gris
      case TipoDocumento.todos:
        return '#000000'; // Negro
    }
  }
}
