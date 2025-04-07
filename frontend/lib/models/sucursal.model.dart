class Sucursal {
  final String id;
  final String nombre;
  final String? direccion;
  final bool sucursalCentral;
  final String? serieFactura;
  final int? numeroFacturaInicial;
  final String? serieBoleta;
  final int? numeroBoletaInicial;
  final String? codigoEstablecimiento;
  final bool tieneNotificaciones;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final bool activo;

  Sucursal({
    required this.id,
    required this.nombre,
    this.direccion,
    required this.sucursalCentral,
    this.serieFactura,
    this.numeroFacturaInicial,
    this.serieBoleta,
    this.numeroBoletaInicial,
    this.codigoEstablecimiento,
    this.tieneNotificaciones = false,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.activo = true,
  }) {
    // Validar formato de serie de factura
    if (serieFactura != null) {
      if (serieFactura!.length != 4 || !serieFactura!.startsWith('F')) {
        throw FormatException(
          'Serie de factura debe tener 4 caracteres y empezar con F',
          serieFactura,
        );
      }
    }

    // Validar número inicial de factura
    if (numeroFacturaInicial != null && numeroFacturaInicial! <= 0) {
      throw FormatException(
        'Número inicial de factura debe ser positivo',
        numeroFacturaInicial.toString(),
      );
    }

    // Validar formato de serie de boleta
    if (serieBoleta != null) {
      if (serieBoleta!.length != 4 || !serieBoleta!.startsWith('B')) {
        throw FormatException(
          'Serie de boleta debe tener 4 caracteres y empezar con B',
          serieBoleta,
        );
      }
    }

    // Validar número inicial de boleta
    if (numeroBoletaInicial != null && numeroBoletaInicial! <= 0) {
      throw FormatException(
        'Número inicial de boleta debe ser positivo',
        numeroBoletaInicial.toString(),
      );
    }

    // Validar código de establecimiento
    if (codigoEstablecimiento != null && codigoEstablecimiento!.length != 4) {
      throw FormatException(
        'Código de establecimiento debe tener 4 caracteres',
        codigoEstablecimiento,
      );
    }
  }

  /// Crea una instancia de Sucursal a partir de un mapa JSON
  factory Sucursal.fromJson(Map<String, dynamic> json) {
    // Validar y convertir serie de factura
    final String? serieFactura = json['serieFactura']?.toString();
    if (serieFactura != null) {
      if (serieFactura.length != 4 || !serieFactura.startsWith('F')) {
        throw FormatException(
          'Serie de factura debe tener 4 caracteres y empezar con F',
          serieFactura,
        );
      }
    }

    // Validar y convertir número inicial de factura
    final int? numeroFacturaInicial = json['numeroFacturaInicial'] != null
        ? int.parse(json['numeroFacturaInicial'].toString())
        : null;
    if (numeroFacturaInicial != null && numeroFacturaInicial <= 0) {
      throw FormatException(
        'Número inicial de factura debe ser positivo',
        numeroFacturaInicial.toString(),
      );
    }

    // Validar y convertir serie de boleta
    final String? serieBoleta = json['serieBoleta']?.toString();
    if (serieBoleta != null) {
      if (serieBoleta.length != 4 || !serieBoleta.startsWith('B')) {
        throw FormatException(
          'Serie de boleta debe tener 4 caracteres y empezar con B',
          serieBoleta,
        );
      }
    }

    // Validar y convertir número inicial de boleta
    final int? numeroBoletaInicial = json['numeroBoletaInicial'] != null
        ? int.parse(json['numeroBoletaInicial'].toString())
        : null;
    if (numeroBoletaInicial != null && numeroBoletaInicial <= 0) {
      throw FormatException(
        'Número inicial de boleta debe ser positivo',
        numeroBoletaInicial.toString(),
      );
    }

    // Validar y convertir código de establecimiento
    final String? codigoEstablecimiento =
        json['codigoEstablecimiento']?.toString();
    if (codigoEstablecimiento != null && codigoEstablecimiento.length != 4) {
      throw FormatException(
        'Código de establecimiento debe tener 4 caracteres',
        codigoEstablecimiento,
      );
    }

    return Sucursal(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      direccion: json['direccion'],
      sucursalCentral: json['sucursalCentral'] ?? false,
      serieFactura: serieFactura,
      numeroFacturaInicial: numeroFacturaInicial,
      serieBoleta: serieBoleta,
      numeroBoletaInicial: numeroBoletaInicial,
      codigoEstablecimiento: codigoEstablecimiento,
      tieneNotificaciones: json['tieneNotificaciones'] ?? false,
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'])
          : DateTime.now(),
      fechaActualizacion: json['fechaActualizacion'] != null
          ? DateTime.parse(json['fechaActualizacion'])
          : DateTime.now(),
      activo: json['activo'] ?? true,
    );
  }

  /// Convierte la instancia de Sucursal a un mapa JSON
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nombre': nombre,
      if (direccion != null) 'direccion': direccion,
      'sucursalCentral': sucursalCentral,
      if (serieFactura != null) 'serieFactura': serieFactura,
      if (numeroFacturaInicial != null)
        'numeroFacturaInicial': numeroFacturaInicial,
      if (serieBoleta != null) 'serieBoleta': serieBoleta,
      if (numeroBoletaInicial != null)
        'numeroBoletaInicial': numeroBoletaInicial,
      if (codigoEstablecimiento != null)
        'codigoEstablecimiento': codigoEstablecimiento,
      'tieneNotificaciones': tieneNotificaciones,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion.toIso8601String(),
      'activo': activo,
    };
  }

  /// Crea una copia de la sucursal con algunos campos actualizados
  Sucursal copyWith({
    String? id,
    String? nombre,
    String? direccion,
    bool? sucursalCentral,
    String? serieFactura,
    int? numeroFacturaInicial,
    String? serieBoleta,
    int? numeroBoletaInicial,
    String? codigoEstablecimiento,
    bool? tieneNotificaciones,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    bool? activo,
  }) {
    return Sucursal(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      sucursalCentral: sucursalCentral ?? this.sucursalCentral,
      serieFactura: serieFactura ?? this.serieFactura,
      numeroFacturaInicial: numeroFacturaInicial ?? this.numeroFacturaInicial,
      serieBoleta: serieBoleta ?? this.serieBoleta,
      numeroBoletaInicial: numeroBoletaInicial ?? this.numeroBoletaInicial,
      codigoEstablecimiento:
          codigoEstablecimiento ?? this.codigoEstablecimiento,
      tieneNotificaciones: tieneNotificaciones ?? this.tieneNotificaciones,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      activo: activo ?? this.activo,
    );
  }

  @override
  String toString() {
    return 'Sucursal(id: $id, nombre: $nombre, central: $sucursalCentral)';
  }

  /// Valida si una serie de factura es válida
  static bool isValidSerieFactura(String? serie) {
    if (serie == null) {
      return true;
    }
    return serie.length == 4 && serie.startsWith('F');
  }

  /// Valida si una serie de boleta es válida
  static bool isValidSerieBoleta(String? serie) {
    if (serie == null) {
      return true;
    }
    return serie.length == 4 && serie.startsWith('B');
  }

  /// Valida si un código de establecimiento es válido
  static bool isValidCodigoEstablecimiento(String? codigo) {
    if (codigo == null) {
      return true;
    }
    return codigo.length == 4;
  }

  /// Valida si un número inicial es válido
  static bool isValidNumeroInicial(int? numero) {
    if (numero == null) {
      return true;
    }
    return numero > 0;
  }
}
