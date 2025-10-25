import 'package:equatable/equatable.dart';

/// Modelo para las marcas
class Marca extends Equatable {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? logo;
  final bool activo;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;
  final int totalProductos;

  const Marca({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.logo,
    this.activo = true,
    this.fechaCreacion,
    this.fechaActualizacion,
    this.totalProductos = 0,
  });

  @override
  List<Object?> get props => [
        id,
        nombre,
        descripcion,
        logo,
        activo,
        fechaCreacion,
        fechaActualizacion,
        totalProductos,
      ];

  /// Crea una instancia de [Marca] a partir de un mapa JSON
  factory Marca.fromJson(Map<String, dynamic> json) {
    // Parsear ID de forma segura
    final int id = _parseInt(json['id']);

    // Parsear totalProductos de forma segura
    final int totalProductos =
        _parseInt(json['totalProductos']);

    return Marca(
      id: id,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      logo: json['logo'],
      activo: json['activo'] ?? true,
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'])
          : null,
      fechaActualizacion: json['fechaActualizacion'] != null
          ? DateTime.parse(json['fechaActualizacion'])
          : null,
      totalProductos: totalProductos,
    );
  }

  /// Convierte esta marca a un mapa JSON
  /// No incluye el ID para operaciones de creación o actualización
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nombre': nombre,
      'descripcion': descripcion,
      'logo': logo,
      'activo': activo,
    };
  }

  /// Convierte esta marca a un mapa JSON incluyendo el ID
  Map<String, dynamic> toFullJson() {
    return <String, dynamic>{
      'id': id,
      ...toJson(),
      'totalProductos': totalProductos,
      if (fechaCreacion != null)
        'fechaCreacion': fechaCreacion!.toIso8601String(),
      if (fechaActualizacion != null)
        'fechaActualizacion': fechaActualizacion!.toIso8601String(),
    };
  }

  /// Helper para parsear enteros de forma segura
  static int _parseInt(value, {int defaultValue = 0}) {
    if (value == null) {
      return defaultValue;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }
}
