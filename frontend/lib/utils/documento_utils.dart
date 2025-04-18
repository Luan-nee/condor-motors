/// Clase de utilidades para manejo de documentos de identidad
/// y validación de tipos de documentos para emisión de comprobantes
class DocumentoUtils {
  /// Verifica si el número de documento es un RUC
  static bool esRuc(String? numeroDocumento) {
    if (numeroDocumento == null || numeroDocumento.isEmpty) {
      return false;
    }

    // RUC debe tener 11 dígitos y empezar con 10 o 20
    return numeroDocumento.length == 11 &&
        RegExp(r'^[12][0]\d{9}$').hasMatch(numeroDocumento);
  }

  /// Verifica si el número de documento es un RUC de empresa (20)
  static bool esRucEmpresa(String? numeroDocumento) {
    if (numeroDocumento == null || numeroDocumento.isEmpty) {
      return false;
    }

    // RUC de empresa debe tener 11 dígitos y empezar con 20
    return numeroDocumento.length == 11 && numeroDocumento.startsWith('20');
  }

  /// Verifica si el número de documento es un RUC de persona natural (10)
  static bool esRucPersonaNatural(String? numeroDocumento) {
    if (numeroDocumento == null || numeroDocumento.isEmpty) {
      return false;
    }

    // RUC de persona natural debe tener 11 dígitos y empezar con 10
    return numeroDocumento.length == 11 && numeroDocumento.startsWith('10');
  }

  /// Verifica si el número de documento es un DNI
  static bool esDni(String? numeroDocumento) {
    if (numeroDocumento == null || numeroDocumento.isEmpty) {
      return false;
    }

    // DNI debe tener 8 dígitos numéricos
    return numeroDocumento.length == 8 &&
        RegExp(r'^\d{8}$').hasMatch(numeroDocumento);
  }

  /// Verifica si un cliente con el documento dado puede recibir facturas
  ///
  /// Según reglas de negocio:
  /// - RUC 20: Siempre recibe facturas
  /// - RUC 10: Puede recibir facturas
  /// - Otros documentos: No pueden recibir facturas
  static bool puedeRecibirFactura(String? numeroDocumento) {
    if (numeroDocumento == null || numeroDocumento.isEmpty) {
      return false;
    }

    // Reglas para RUC 20 y RUC 10
    if (numeroDocumento.length == 11) {
      return numeroDocumento.startsWith('10') ||
          numeroDocumento.startsWith('20');
    }

    return false;
  }

  /// Verifica si un cliente con el documento dado puede recibir boletas
  ///
  /// Según reglas de negocio:
  /// - RUC 20: No recibe boletas, solo facturas
  /// - RUC 10: Puede recibir boletas
  /// - Otros documentos: Siempre reciben boletas
  static bool puedeRecibirBoleta(String? numeroDocumento) {
    if (numeroDocumento == null || numeroDocumento.isEmpty) {
      return true; // Sin documento siempre puede recibir boleta
    }

    // RUC 20 no puede recibir boletas
    if (numeroDocumento.length == 11 && numeroDocumento.startsWith('20')) {
      return false;
    }

    return true;
  }

  /// Determina el tipo de documento en base al número
  ///
  /// Retorna 'RUC20', 'RUC10', 'DNI' u 'OTRO' según el formato
  static String determinarTipoDocumento(String? numeroDocumento) {
    if (numeroDocumento == null || numeroDocumento.isEmpty) {
      return 'OTRO';
    }

    if (numeroDocumento.length == 11) {
      if (numeroDocumento.startsWith('20')) {
        return 'RUC20';
      } else if (numeroDocumento.startsWith('10')) {
        return 'RUC10';
      }
      return 'RUC';
    } else if (numeroDocumento.length == 8) {
      return 'DNI';
    }

    return 'OTRO';
  }

  /// Verifica si un tipo de comprobante es válido para un cliente con un número de documento específico
  ///
  /// [numeroDocumento] El número de documento del cliente
  /// [tipoComprobante] El tipo de comprobante 'BOLETA' o 'FACTURA'
  static bool esComprobanteValidoParaCliente(
      String? numeroDocumento, String tipoComprobante) {
    if (tipoComprobante == 'FACTURA') {
      return puedeRecibirFactura(numeroDocumento);
    } else if (tipoComprobante == 'BOLETA') {
      return puedeRecibirBoleta(numeroDocumento);
    }
    return false;
  }

  /// Obtiene un mensaje descriptivo sobre la validación del comprobante para el tipo de documento
  ///
  /// Mensaje para informar al usuario qué tipos de comprobantes puede emitir
  static String getMensajeValidacionComprobante(String? numeroDocumento) {
    final String tipoDocumento = determinarTipoDocumento(numeroDocumento);

    switch (tipoDocumento) {
      case 'RUC20':
        return 'Este cliente con RUC 20 solo puede recibir facturas.';
      case 'RUC10':
        return 'Este cliente con RUC 10 puede recibir facturas o boletas.';
      case 'DNI':
        return 'Este cliente con DNI solo puede recibir boletas.';
      default:
        if (numeroDocumento == null || numeroDocumento.isEmpty) {
          return 'Sin documento, solo puede emitir boleta.';
        }
        return 'Este tipo de documento solo permite recibir boletas.';
    }
  }

  /// Sugiere el tipo de comprobante recomendado para un cliente con un documento específico
  static String getTipoComprobanteRecomendado(String? numeroDocumento) {
    final String tipoDocumento = determinarTipoDocumento(numeroDocumento);

    if (tipoDocumento == 'RUC20') {
      return 'FACTURA';
    }

    return 'BOLETA';
  }

  /// Obtiene un objeto de validación con toda la información necesaria para validar un documento
  ///
  /// Retorna un mapa con:
  /// - puedeEmitirBoleta: Si puede emitir boleta
  /// - puedeEmitirFactura: Si puede emitir factura
  /// - tipoDocumento: Tipo de documento detectado
  /// - mensajeValidacion: Mensaje descriptivo
  /// - tipoComprobanteRecomendado: Tipo de comprobante recomendado
  static Map<String, dynamic> obtenerValidacionCompleta(
      String? numeroDocumento) {
    final String tipoDocumento = determinarTipoDocumento(numeroDocumento);
    final bool puedeBoleta = puedeRecibirBoleta(numeroDocumento);
    final bool puedeFactura = puedeRecibirFactura(numeroDocumento);
    final String mensaje = getMensajeValidacionComprobante(numeroDocumento);
    final String tipoRecomendado =
        getTipoComprobanteRecomendado(numeroDocumento);

    return {
      'puedeEmitirBoleta': puedeBoleta,
      'puedeEmitirFactura': puedeFactura,
      'tipoDocumento': tipoDocumento,
      'mensajeValidacion': mensaje,
      'tipoComprobanteRecomendado': tipoRecomendado,
    };
  }
}
