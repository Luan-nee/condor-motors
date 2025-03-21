class Sucursal {
  final String id;
  final String nombre;
  final String direccion;
  final bool sucursalCentral;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final bool activo;

  Sucursal({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.sucursalCentral,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.activo = true,
  });

  /// Crea una instancia de Sucursal a partir de un mapa JSON
  factory Sucursal.fromJson(Map<String, dynamic> json) {
    return Sucursal(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      direccion: json['direccion'] ?? '',
      sucursalCentral: json['sucursalCentral'] ?? false,
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
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'sucursalCentral': sucursalCentral,
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
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    bool? activo,
  }) {
    return Sucursal(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      sucursalCentral: sucursalCentral ?? this.sucursalCentral,
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
