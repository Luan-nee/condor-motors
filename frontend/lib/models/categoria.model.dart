import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Modelo para las categorías de productos
class Categoria extends Equatable {
  final int id;
  final String nombre;
  final String? descripcion;
  final bool activo;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;
  final int totalProductos;

  const Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
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
        activo,
        fechaCreacion,
        fechaActualizacion,
        totalProductos,
      ];

  /// Crea una instancia de [Categoria] a partir de un mapa JSON
  factory Categoria.fromJson(Map<String, dynamic> json) {
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
          'Categoria.fromJson: ID no válido: $rawId (${rawId?.runtimeType})');
    }

    return Categoria(
      id: id,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      activo: json['activo'] ?? true,
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'])
          : null,
      fechaActualizacion: json['fechaActualizacion'] != null
          ? DateTime.parse(json['fechaActualizacion'])
          : null,
      totalProductos: json['totalProductos'] is int
          ? json['totalProductos']
          : (json['totalProductos'] is String
              ? int.tryParse(json['totalProductos']) ?? 0
              : 0),
    );
  }

  /// Convierte esta categoría a un mapa JSON
  /// No incluye el ID para operaciones de creación o actualización
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nombre': nombre,
      'descripcion': descripcion,
      'activo': activo,
    };
  }

  /// Convierte esta categoría a un mapa JSON incluyendo el ID
  Map<String, dynamic> toFullJson() {
    return <String, dynamic>{
      'id': id,
      ...toJson(),
      if (fechaCreacion != null)
        'fechaCreacion': fechaCreacion!.toIso8601String(),
      if (fechaActualizacion != null)
        'fechaActualizacion': fechaActualizacion!.toIso8601String(),
      'totalProductos': totalProductos,
    };
  }
}
