import 'package:flutter/foundation.dart';

/// Modelo para representar un cliente en el sistema
class Cliente {
  final int id;
  final int tipoDocumentoId;
  final String numeroDocumento;
  final String denominacion;
  final String? direccion;
  final String? correo;
  final String? telefono;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cliente({
    required this.id,
    required this.tipoDocumentoId,
    required this.numeroDocumento,
    required this.denominacion,
    this.direccion,
    this.correo,
    this.telefono,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crea una instancia de Cliente desde un mapa JSON
  factory Cliente.fromJson(Map<String, dynamic> json) {
    debugPrint('🔄 Procesando datos de cliente: ${json.keys.join(', ')}');
    
    // Función auxiliar para parsear fechas con manejo de errores
    DateTime parseDate(dynamic date) {
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
    final id = json['id'] is int ? json['id'] : int.parse(json['id'].toString());
    final tipoDocumentoId = json['tipoDocumentoId'] is int 
        ? json['tipoDocumentoId'] 
        : int.parse((json['tipoDocumentoId'] ?? '1').toString());
    final numeroDocumento = json['numeroDocumento']?.toString() ?? '';
    final denominacion = json['denominacion']?.toString() ?? 'Cliente sin nombre';
    
    // Extraer campos opcionales
    final direccion = json['direccion']?.toString();
    final correo = json['correo']?.toString();
    final telefono = json['telefono']?.toString();
    
    // Parsear fechas
    final createdAt = parseDate(json['createdAt']);
    final updatedAt = parseDate(json['updatedAt']);
    
    return Cliente(
      id: id,
      tipoDocumentoId: tipoDocumentoId,
      numeroDocumento: numeroDocumento,
      denominacion: denominacion,
      direccion: direccion,
      correo: correo,
      telefono: telefono,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convierte la instancia a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipoDocumentoId': tipoDocumentoId,
      'numeroDocumento': numeroDocumento,
      'denominacion': denominacion,
      if (direccion != null) 'direccion': direccion,
      if (correo != null) 'correo': correo,
      if (telefono != null) 'telefono': telefono,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Crea una copia de este Cliente con valores actualizados
  Cliente copyWith({
    int? id,
    int? tipoDocumentoId,
    String? numeroDocumento,
    String? denominacion,
    String? direccion,
    String? correo,
    String? telefono,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cliente(
      id: id ?? this.id,
      tipoDocumentoId: tipoDocumentoId ?? this.tipoDocumentoId,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      denominacion: denominacion ?? this.denominacion,
      direccion: direccion ?? this.direccion,
      correo: correo ?? this.correo,
      telefono: telefono ?? this.telefono,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Cliente(id: $id, denominacion: $denominacion, documento: $numeroDocumento)';
  }
} 