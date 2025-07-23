import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

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
    // Asegurar que siempre tengamos un ID numérico
    int id;
    final rawId = json['id'];
    if (rawId is int) {
      id = rawId;
    } else if (rawId is String) {
      id = int.tryParse(rawId) ?? 0; // Usar 0 como fallback
    } else {
      id = 0; // Valor por defecto si no hay ID o no se puede parsear
      debugPrint(
          'Marca.fromJson: ID no válido: $rawId (${rawId?.runtimeType})');
    }

    // Parseamos totalProductos de manera segura
    int totalProductos = 0;
    if (json['totalProductos'] != null) {
      if (json['totalProductos'] is int) {
        totalProductos = json['totalProductos'];
      } else if (json['totalProductos'] is String) {
        totalProductos = int.tryParse(json['totalProductos']) ?? 0;
      }
    }

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
}
