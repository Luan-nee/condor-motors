import 'package:equatable/equatable.dart';

class Sucursal extends Equatable {
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
  final int totalEmpleados;

  const Sucursal({
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
    this.totalEmpleados = 0,
  });

  @override
  List<Object?> get props => [
        id,
        nombre,
        direccion,
        sucursalCentral,
        serieFactura,
        numeroFacturaInicial,
        serieBoleta,
        numeroBoletaInicial,
        codigoEstablecimiento,
        tieneNotificaciones,
        fechaCreacion,
        fechaActualizacion,
        activo,
        totalEmpleados,
      ];

  /// Crea una instancia de Sucursal a partir de un mapa JSON
  factory Sucursal.fromJson(Map<String, dynamic> json) {
    // Validar y convertir serie de factura
    final String? serieFactura = json['serieFactura']?.toString();
    validarSerieFactura(serieFactura);

    // Validar y convertir número inicial de factura
    final int? numeroFacturaInicial = json['numeroFacturaInicial'] != null
        ? int.parse(json['numeroFacturaInicial'].toString())
        : null;
    validarNumeroInicial(numeroFacturaInicial, 'factura');

    // Validar y convertir serie de boleta
    final String? serieBoleta = json['serieBoleta']?.toString();
    validarSerieBoleta(serieBoleta);

    // Validar y convertir número inicial de boleta
    final int? numeroBoletaInicial = json['numeroBoletaInicial'] != null
        ? int.parse(json['numeroBoletaInicial'].toString())
        : null;
    validarNumeroInicial(numeroBoletaInicial, 'boleta');

    // Validar y convertir código de establecimiento
    final String? codigoEstablecimiento =
        json['codigoEstablecimiento']?.toString();
    validarCodigoEstablecimiento(codigoEstablecimiento);

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
      totalEmpleados: json['totalEmpleados'] ?? 0,
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
      'totalEmpleados': totalEmpleados,
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
    int? totalEmpleados,
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
      totalEmpleados: totalEmpleados ?? this.totalEmpleados,
    );
  }

  @override
  String toString() {
    return 'Sucursal(id: $id, nombre: $nombre, central: $sucursalCentral)';
  }

  /// Valida los datos de la sucursal antes de crear/actualizar
  static String? validateSucursalData(Map<String, dynamic> data) {
    // Validar nombre
    if (data['nombre']?.toString().trim().isEmpty ?? true) {
      return 'El nombre de la sucursal es requerido';
    }

    // Validar serie de factura si se proporciona
    if (data['serieFactura'] != null &&
        data['serieFactura'].toString().isNotEmpty) {
      final String? error = validarSerieFactura(data['serieFactura']);
      if (error != null) {
        return error;
      }
    }

    // Validar serie de boleta si se proporciona
    if (data['serieBoleta'] != null &&
        data['serieBoleta'].toString().isNotEmpty) {
      final String? error = validarSerieBoleta(data['serieBoleta']);
      if (error != null) {
        return error;
      }
    }

    // Validar código de establecimiento si se proporciona
    if (data['codigoEstablecimiento'] != null &&
        data['codigoEstablecimiento'].toString().isNotEmpty) {
      final String? error =
          validarCodigoEstablecimiento(data['codigoEstablecimiento']);
      if (error != null) {
        return error;
      }
    }

    return null; // Sin errores
  }

  /// Valida si una serie de factura es válida (retorna String de error o null)
  static String? validarSerieFactura(String? serie) {
    if (serie != null) {
      if (serie.length != 4 || !serie.startsWith('F')) {
        return 'Serie de factura debe tener 4 caracteres y empezar con F';
      }
    }
    return null;
  }

  /// Valida si una serie de boleta es válida (retorna String de error o null)
  static String? validarSerieBoleta(String? serie) {
    if (serie != null) {
      if (serie.length != 4 || !serie.startsWith('B')) {
        return 'Serie de boleta debe tener 4 caracteres y empezar con B';
      }
    }
    return null;
  }

  /// Valida si un código de establecimiento es válido (retorna String de error o null)
  static String? validarCodigoEstablecimiento(String? codigo) {
    if (codigo != null && codigo.length != 4) {
      return 'Código de establecimiento debe tener 4 caracteres';
    }
    return null;
  }

  /// Valida si un número inicial es válido (retorna String de error o null)
  static String? validarNumeroInicial(int? numero, String tipo) {
    if (numero != null && numero <= 0) {
      return 'Número inicial de $tipo debe ser positivo';
    }
    return null;
  }

  /// Valida si una serie de factura está disponible (para uso en providers)
  static bool isSerieFacturaDisponible(String serie, List<Sucursal> sucursales,
      {String? excludeId}) {
    return !sucursales.any((s) =>
        s.serieFactura == serie && (excludeId == null || s.id != excludeId));
  }

  /// Valida si una serie de boleta está disponible (para uso en providers)
  static bool isSerieBoletaDisponible(String serie, List<Sucursal> sucursales,
      {String? excludeId}) {
    return !sucursales.any((s) =>
        s.serieBoleta == serie && (excludeId == null || s.id != excludeId));
  }

  /// Valida si un código de establecimiento está disponible (para uso en providers)
  static bool isCodigoEstablecimientoDisponible(
      String codigo, List<Sucursal> sucursales,
      {String? excludeId}) {
    return !sucursales.any((s) =>
        s.codigoEstablecimiento == codigo &&
        (excludeId == null || s.id != excludeId));
  }
}
