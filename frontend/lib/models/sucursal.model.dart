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
  });

  /// Crea una instancia de Sucursal a partir de un mapa JSON
  factory Sucursal.fromJson(Map<String, dynamic> json) {
    return Sucursal(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      direccion: json['direccion'],
      sucursalCentral: json['sucursalCentral'] ?? false,
      serieFactura: json['serieFactura'],
      numeroFacturaInicial: json['numeroFacturaInicial'],
      serieBoleta: json['serieBoleta'],
      numeroBoletaInicial: json['numeroBoletaInicial'],
      codigoEstablecimiento: json['codigoEstablecimiento'],
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
      if (numeroFacturaInicial != null) 'numeroFacturaInicial': numeroFacturaInicial,
      if (serieBoleta != null) 'serieBoleta': serieBoleta,
      if (numeroBoletaInicial != null) 'numeroBoletaInicial': numeroBoletaInicial,
      if (codigoEstablecimiento != null) 'codigoEstablecimiento': codigoEstablecimiento,
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
      codigoEstablecimiento: codigoEstablecimiento ?? this.codigoEstablecimiento,
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
}
