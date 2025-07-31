import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Modelo para representar un cliente en el sistema
class Cliente extends Equatable {
  final int id;
  final int tipoDocumentoId;
  final String nombre; // Nombre del tipo de documento
  final String numeroDocumento;
  final String denominacion;
  final String? direccion;
  final String? correo;
  final String? telefono;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  const Cliente({
    required this.id,
    required this.tipoDocumentoId,
    required this.nombre,
    required this.numeroDocumento,
    required this.denominacion,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.direccion,
    this.correo,
    this.telefono,
  });

  @override
  List<Object?> get props => [
        id,
        tipoDocumentoId,
        nombre,
        numeroDocumento,
        denominacion,
        direccion,
        correo,
        telefono,
        fechaCreacion,
        fechaActualizacion,
      ];

  /// Crea una instancia de Cliente desde un mapa JSON
  factory Cliente.fromJson(Map<String, dynamic> json) {
    debugPrint('🔄 Procesando datos de cliente: ${json.keys.join(', ')}');

    // Función auxiliar para parsear fechas con manejo de errores
    DateTime parseDate(date) {
      if (date == null) {
        return DateTime.now();
      }

      try {
        if (date is String) {
          return DateTime.parse(date);
        } else if (date is int) {
          return DateTime.fromMillisecondsSinceEpoch(date);
        }
        return DateTime.now();
      } catch (e) {
        debugPrint('⚠️ Error al parsear fecha: $e');
        return DateTime.now();
      }
    }

    // Extraer y validar campos obligatorios
    final id =
        json['id'] is int ? json['id'] : int.parse(json['id'].toString());
    final tipoDocumentoId = json['tipoDocumentoId'] is int
        ? json['tipoDocumentoId']
        : int.parse((json['tipoDocumentoId'] ?? '1').toString());
    final String nombre = json['nombre']?.toString() ?? 'DOCUMENTO SIN TIPO';
    final String numeroDocumento = json['numeroDocumento']?.toString() ?? '';
    final String denominacion =
        json['denominacion']?.toString() ?? 'Cliente sin nombre';

    // Extraer campos opcionales
    final String? direccion = json['direccion']?.toString();
    final String? correo = json['correo']?.toString();
    final String? telefono = json['telefono']?.toString();

    // Parsear fechas usando los nuevos nombres de campos
    final DateTime fechaCreacion =
        parseDate(json['fechaCreacion'] ?? json['createdAt']);
    final DateTime fechaActualizacion =
        parseDate(json['fechaActualizacion'] ?? json['updatedAt']);

    return Cliente(
      id: id,
      tipoDocumentoId: tipoDocumentoId,
      nombre: nombre,
      numeroDocumento: numeroDocumento,
      denominacion: denominacion,
      direccion: direccion,
      correo: correo,
      telefono: telefono,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion,
    );
  }

  /// Convierte la instancia a un mapa JSON
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'tipoDocumentoId': tipoDocumentoId,
      'nombre': nombre,
      'numeroDocumento': numeroDocumento,
      'denominacion': denominacion,
      if (direccion != null) 'direccion': direccion,
      if (correo != null) 'correo': correo,
      if (telefono != null) 'telefono': telefono,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  /// Crea una copia de este Cliente con valores actualizados
  Cliente copyWith({
    int? id,
    int? tipoDocumentoId,
    String? nombre,
    String? numeroDocumento,
    String? denominacion,
    String? direccion,
    String? correo,
    String? telefono,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Cliente(
      id: id ?? this.id,
      tipoDocumentoId: tipoDocumentoId ?? this.tipoDocumentoId,
      nombre: nombre ?? this.nombre,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      denominacion: denominacion ?? this.denominacion,
      direccion: direccion ?? this.direccion,
      correo: correo ?? this.correo,
      telefono: telefono ?? this.telefono,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
