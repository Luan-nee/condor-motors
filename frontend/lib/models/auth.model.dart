import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

// FIX: Para modelos complejos, considera usar el paquete `freezed`.
// `freezed` genera automáticamente `copyWith`, `fromJson`, `toJson`, `toString`
// y la igualdad de objetos, lo que reduce drásticamente el código repetitivo
// y previene errores comunes al añadir nuevos campos.

class AuthUser extends Equatable {
  final String id;
  final String usuario;
  final String rolCuentaEmpleadoId;
  final String rolCuentaEmpleadoCodigo;
  final String empleadoId;
  final Map<String, dynamic> empleado;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final String sucursal;
  final int sucursalId;

  const AuthUser({
    required this.id,
    required this.usuario,
    required this.rolCuentaEmpleadoId,
    required this.rolCuentaEmpleadoCodigo,
    required this.empleadoId,
    required this.empleado,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.sucursal,
    required this.sucursalId,
  });

  // Convertir a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario': usuario,
      'rol': {
        'codigo': rolCuentaEmpleadoCodigo.toLowerCase(),
        'nombre': rolCuentaEmpleadoCodigo
      },
      'rolId': rolCuentaEmpleadoId,
      'empleadoId': empleadoId,
      'empleado': empleado,
      'sucursal': sucursal,
      'sucursalId': sucursalId.toString(),
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  // Crear desde JSON
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    debugPrint('Procesando datos de usuario: ${json.toString()}');

    // Extraer sucursalId con manejo seguro de tipos
    int sucursalId;
    try {
      if (json['sucursalId'] is int) {
        sucursalId = json['sucursalId'];
      } else if (json['sucursalId'] is String) {
        sucursalId = int.tryParse(json['sucursalId']) ?? 0;
        debugPrint('Convertido sucursalId de String a int: $sucursalId');
      } else {
        sucursalId = 0;
        debugPrint(
            'ADVERTENCIA: sucursalId no es int ni String, usando valor por defecto 0');
      }
    } catch (e) {
      sucursalId = 0;
      debugPrint('ERROR al procesar sucursalId: $e');
    }

    // Procesar datos del empleado
    final Map<String, dynamic> empleadoData =
        json['empleado'] as Map<String, dynamic>? ??
            {'activo': true, 'nombres': '', 'apellidos': ''};

    return AuthUser(
      id: json['id']?.toString() ?? '',
      usuario: json['usuario'] ?? '',
      rolCuentaEmpleadoId: json['rolCuentaEmpleadoId']?.toString() ?? '',
      rolCuentaEmpleadoCodigo:
          json['rolCuentaEmpleadoCodigo']?.toString().toLowerCase() ?? '',
      empleadoId: json['empleadoId']?.toString() ?? '',
      empleado: empleadoData,
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'])
          : DateTime.now(),
      fechaActualizacion: json['fechaActualizacion'] != null
          ? DateTime.parse(json['fechaActualizacion'])
          : DateTime.now(),
      sucursal: json['sucursal'] ?? '',
      sucursalId: sucursalId,
    );
  }

  // Crear una copia con cambios
  AuthUser copyWith({
    String? id,
    String? usuario,
    String? rolCuentaEmpleadoId,
    String? rolCuentaEmpleadoCodigo,
    String? empleadoId,
    Map<String, dynamic>? empleado,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? sucursal,
    int? sucursalId,
  }) {
    return AuthUser(
      id: id ?? this.id,
      usuario: usuario ?? this.usuario,
      rolCuentaEmpleadoId: rolCuentaEmpleadoId ?? this.rolCuentaEmpleadoId,
      rolCuentaEmpleadoCodigo:
          rolCuentaEmpleadoCodigo ?? this.rolCuentaEmpleadoCodigo,
      empleadoId: empleadoId ?? this.empleadoId,
      empleado: empleado ?? Map<String, dynamic>.from(this.empleado),
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      sucursal: sucursal ?? this.sucursal,
      sucursalId: sucursalId ?? this.sucursalId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        usuario,
        rolCuentaEmpleadoId,
        rolCuentaEmpleadoCodigo,
        empleadoId,
        empleado,
        fechaCreacion,
        fechaActualizacion,
        sucursal,
        sucursalId
      ];
}

class AuthState extends Equatable {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final AuthUser? user;
  final String? token;
  final DateTime? tokenExpiry;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
    this.token,
    this.tokenExpiry,
  });

  // Crear una copia con cambios
  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    AuthUser? user,
    String? token,
    DateTime? tokenExpiry,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      token: token ?? this.token,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
    );
  }

  // Estado inicial
  factory AuthState.initial() {
    return const AuthState();
  }

  // Estado de carga
  factory AuthState.loading() {
    return const AuthState(
      isLoading: true,
    );
  }

  // Estado autenticado
  factory AuthState.authenticated(AuthUser user, String token,
      [DateTime? expiry]) {
    return AuthState(
      isAuthenticated: true,
      user: user,
      token: token,
      tokenExpiry: expiry,
    );
  }

  // Estado de error
  factory AuthState.error(String message) {
    return AuthState(
      error: message,
    );
  }

  @override
  List<Object?> get props =>
      [isAuthenticated, isLoading, error, user, token, tokenExpiry];
}
