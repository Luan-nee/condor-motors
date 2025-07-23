import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Modelo para representar colores en la aplicación
class ColorApp extends Equatable {
  final int id;
  final String nombre;
  final String? hex;

  const ColorApp({
    required this.id,
    required this.nombre,
    this.hex,
  });

  @override
  List<Object?> get props => [id, nombre, hex];

  /// Crea una instancia de [ColorApp] a partir de un mapa JSON
  factory ColorApp.fromJson(Map<String, dynamic> json) {
    return ColorApp(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      hex: json['hex'] as String?,
    );
  }

  /// Convierte el color a un objeto Color de Flutter
  Color toColor() {
    if (hex == null || hex!.isEmpty) {
      return Colors.grey; // Color por defecto si no hay hex
    }

    try {
      // Asegurarse de que el formato sea correcto
      String hexColor = hex!.startsWith('#') ? hex! : '#$hex';

      // Si es #RGB, convertirlo a #RRGGBB
      if (hexColor.length == 4) {
        final String r = hexColor[1];
        final String g = hexColor[2];
        final String b = hexColor[3];
        hexColor = '#$r$r$g$g$b$b';
      }

      // Quitar el # y convertir a entero con base 16
      int colorValue = int.parse(hexColor.substring(1), radix: 16);

      // Añadir canal alfa si no está presente
      if (hexColor.length == 7) {
        colorValue |= 0xFF000000; // Añadir alfa completo
      }

      return Color(colorValue);
    } catch (e) {
      return Colors.grey; // Color por defecto en caso de error
    }
  }

  /// Convierte este objeto a JSON
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nombre': nombre,
      'hex': hex,
    };
  }
}
