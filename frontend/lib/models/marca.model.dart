import 'package:flutter/foundation.dart';

/// Modelo para las marcas
class Marca {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? logo;
  final bool activo;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  Marca({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.logo,
    this.activo = true,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

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
      debugPrint('Marca.fromJson: ID no válido: $rawId (${rawId?.runtimeType})');
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
    );
  }

  /// Convierte esta marca a un mapa JSON
  /// No incluye el ID para operaciones de creación o actualización
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'logo': logo,
      'activo': activo,
    };
  }
  
  /// Convierte esta marca a un mapa JSON incluyendo el ID
  Map<String, dynamic> toFullJson() {
    return {
      'id': id,
      ...toJson(),
      if (fechaCreacion != null) 'fechaCreacion': fechaCreacion!.toIso8601String(),
      if (fechaActualizacion != null) 'fechaActualizacion': fechaActualizacion!.toIso8601String(),
    };
  }
  
  @override
  String toString() {
    return 'Marca{id: $id, nombre: $nombre, activo: $activo}';
  }
} 