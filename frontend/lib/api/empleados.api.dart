import 'package:flutter/foundation.dart';
import 'main.api.dart';

class Empleado {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String rol;
  final int localId;
  final bool activo;
  final DateTime? fechaCreacion;
  final DateTime? ultimoAcceso;

  Empleado.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      nombre = json['nombre'],
      apellido = json['apellido'],
      email = json['email'],
      rol = json['rol'],
      localId = json['local_id'],
      activo = json['activo'] ?? true,
      fechaCreacion = json['fecha_creacion'] != null 
        ? DateTime.parse(json['fecha_creacion'])
        : null,
      ultimoAcceso = json['ultimo_acceso'] != null
        ? DateTime.parse(json['ultimo_acceso'])
        : null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'apellido': apellido,
    'email': email,
    'rol': rol,
    'local_id': localId,
    'activo': activo,
  };
}

class EmpleadoApi {
  final ApiService _api;
  final String _endpoint = '/empleados';
  
  EmpleadoApi(this._api);

  // Roles válidos según documentación
  static const roles = {
    'ADMINISTRADOR': 'ADMINISTRADOR',
    'COLABORADOR': 'COLABORADOR', 
    'VENDEDOR': 'VENDEDOR',
    'COMPUTADORA': 'COMPUTADORA',
  };

  // Login usando Supabase
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?usuario=eq.$username&clave=eq.$password&activo=eq.true',
        method: 'GET',
      );

      if (response == null || (response as List).isEmpty) {
        throw Exception('Credenciales inválidas');
      }

      final empleado = Map<String, dynamic>.from(response[0]);

      // Validar que el empleado existe y está activo
      if (!empleado.containsKey('id') || empleado['activo'] != true) {
        throw Exception('Cuenta inactiva o inválida');
      }

      return empleado;
    } catch (e) {
      debugPrint('Error en login: $e');
      rethrow;
    }
  }

  // Obtener todos los empleados
  Future<List<Empleado>> getEmpleados() async {
    try {
      final response = await _api.request(
        endpoint: _endpoint,
        method: 'GET',
      );

      if (response == null) return [];
      return (response as List)
        .map((json) => Empleado.fromJson(json))
        .toList();
    } catch (e) {
      debugPrint('Error al obtener empleados: $e');
      return [];
    }
  }

  // Obtener un empleado por ID
  Future<Empleado?> getEmpleado(String id) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'GET',
      );

      if (response == null || (response as List).isEmpty) return null;
      return Empleado.fromJson(response[0]);
    } catch (e) {
      debugPrint('Error al obtener empleado: $e');
      return null;
    }
  }

  // Crear un nuevo empleado
  Future<Map<String, dynamic>> createEmpleado(Map<String, dynamic> empleado) async {
    try {
      // Validaciones básicas
      if (!empleado.containsKey('nombre_completo') ||
          !empleado.containsKey('rol') ||
          !empleado.containsKey('usuario') ||
          !empleado.containsKey('clave') ||
          !empleado.containsKey('local_id')) {
        throw Exception('Faltan campos requeridos');
      }

      // Validar rol
      if (!roles.containsKey(empleado['rol'].toString().toUpperCase())) {
        throw Exception('Rol inválido');
      }

      final response = await _api.request(
        endpoint: _endpoint,
        method: 'POST',
        body: empleado,
      );

      return response ?? {};
    } catch (e) {
      debugPrint('Error al crear empleado: $e');
      rethrow;
    }
  }

  // Validar formato UUID
  bool _isValidUUID(String uuid) {
    final RegExp uuidRegExp = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegExp.hasMatch(uuid);
  }

  // Actualizar un empleado
  Future<bool> updateEmpleado(String id, Map<String, dynamic> data) async {
    try {
      if (!_isValidUUID(id)) {
        throw Exception('ID de empleado inválido');
      }
      
      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'PATCH',
        body: data,
      );
      return true;
    } catch (e) {
      debugPrint('Error al actualizar empleado: $e');
      return false;
    }
  }

  // Eliminar un empleado (desactivar)
  Future<void> deleteEmpleado(String id) async {
    try {
      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'PUT',
        body: {'activo': false},
      );
    } catch (e) {
      debugPrint('Error al desactivar empleado: $e');
      rethrow;
    }
  }

  // Buscar empleados
  Future<List<Empleado>> searchEmpleados({
    String? nombre,
    String? dni,
    String? rol,
    int? localId,
    bool? activo,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (nombre != null) queryParams['nombre_completo'] = 'ilike.*$nombre*';
      if (dni != null) queryParams['dni'] = 'eq.$dni';
      if (rol != null) queryParams['rol'] = 'eq.$rol';
      if (localId != null) queryParams['local_id'] = 'eq.$localId';
      if (activo != null) queryParams['activo'] = 'eq.$activo';

      final response = await _api.request(
        endpoint: _endpoint,
        method: 'GET',
        queryParams: queryParams,
      );

      if (response == null) return [];
      return (response as List)
        .map((json) => Empleado.fromJson(json))
        .toList();
    } catch (e) {
      debugPrint('Error al buscar empleados: $e');
      return [];
    }
  }

  // Actualizar contraseña
  Future<void> updatePassword(String id, String newPassword) async {
    try {
      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'PUT',
        body: {'clave': newPassword},
      );
    } catch (e) {
      debugPrint('Error al actualizar contraseña: $e');
      rethrow;
    }
  }

  // Obtener empleados por rol
  Future<List<Empleado>> getEmpleadosPorRol(String rol) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?rol=eq.$rol&activo=eq.true',
        method: 'GET',
      );

      if (response == null) return [];
      return (response as List)
        .map((json) => Empleado.fromJson(json))
        .toList();
    } catch (e) {
      debugPrint('Error al obtener empleados por rol: $e');
      return [];
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _api.clearToken();
  }

  // Verificar permisos según rol
  bool canAccessEmpleados(String rol) {
    switch (rol.toUpperCase()) {
      case 'ADMINISTRADOR':
        return true;
      case 'COLABORADOR':
        return true;
      case 'VENDEDOR':
        return false;
      case 'COMPUTADORA':
        return false;
      default:
        return false;
    }
  }

  bool canModifyEmpleados(String rol) {
    return rol.toUpperCase() == 'ADMINISTRADOR';
  }

  bool canViewEmpleado(String rol, int empleadoId, int currentEmpleadoId) {
    switch (rol.toUpperCase()) {
      case 'ADMINISTRADOR':
      case 'COLABORADOR':
        return true;
      case 'VENDEDOR':
        return empleadoId == currentEmpleadoId;
      default:
        return false;
    }
  }

  // Verificar si existe un usuario
  Future<bool> existeUsuario(String usuario) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?usuario=eq.$usuario',
        method: 'GET',
      );

      return response != null && (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('Error al verificar usuario: $e');
      return false;
    }
  }
}
