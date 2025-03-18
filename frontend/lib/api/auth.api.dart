import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'main.api.dart';

// Clase para representar los datos del usuario autenticado
class UsuarioAutenticado {
  final String id;
  final String usuario;
  final String rolCuentaEmpleadoId;
  final String rolCuentaEmpleadoCodigo;
  final String empleadoId;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final String sucursal;
  final int sucursalId;
  final String token;

  UsuarioAutenticado({
    required this.id,
    required this.usuario,
    required this.rolCuentaEmpleadoId,
    required this.rolCuentaEmpleadoCodigo,
    required this.empleadoId,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.sucursal,
    required this.sucursalId,
    required this.token,
  });

  // Convertir a Map para almacenamiento o navegación
  Map<String, dynamic> toMap() {
    // Convertir el código de rol a un formato reconocido por la aplicación
    String rolNormalizado = rolCuentaEmpleadoCodigo.toUpperCase();
    
    // Mapeo de roles específicos
    switch (rolNormalizado) {
      case 'ADM':
      case 'ADMIN':
      case 'ADMINSTRADOR':
        rolNormalizado = 'ADMINISTRADOR';
        break;
      case 'VEN':
        rolNormalizado = 'VENDEDOR';
        break;
      case 'COMP':
      case 'COMPUTER':
      case 'COMPUTADORA':
        rolNormalizado = 'COMPUTADORA';
        break;
      // Mantener el rol como está si no coincide con ninguno de los anteriores
    }
    
    debugPrint('Convirtiendo rol de "$rolCuentaEmpleadoCodigo" a "$rolNormalizado" para toMap');
    
    return {
      'id': id,
      'usuario': usuario,
      'rol': rolNormalizado,
      'rolId': rolCuentaEmpleadoId,
      'empleadoId': empleadoId,
      'sucursal': sucursal,
      'sucursalId': sucursalId,
      'token': token,
    };
  }

  // Crear desde respuesta JSON
  factory UsuarioAutenticado.fromJson(Map<String, dynamic> json, String token) {
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
        debugPrint('ADVERTENCIA: sucursalId no es int ni String, usando valor por defecto 0');
      }
    } catch (e) {
      sucursalId = 0;
      debugPrint('ERROR al procesar sucursalId: $e');
    }
    
    return UsuarioAutenticado(
      id: json['id']?.toString() ?? '',
      usuario: json['usuario'] ?? '',
      rolCuentaEmpleadoId: json['rolCuentaEmpleadoId']?.toString() ?? '',
      rolCuentaEmpleadoCodigo: json['rolCuentaEmpleadoCodigo'] ?? '',
      empleadoId: json['empleadoId']?.toString() ?? '',
      fechaCreacion: json['fechaCreacion'] != null 
          ? DateTime.parse(json['fechaCreacion']) 
          : DateTime.now(),
      fechaActualizacion: json['fechaActualizacion'] != null 
          ? DateTime.parse(json['fechaActualizacion']) 
          : DateTime.now(),
      sucursal: json['sucursal'] ?? '',
      sucursalId: sucursalId,
      token: token,
    );
  }
  
  @override
  String toString() {
    return 'UsuarioAutenticado{id: $id, usuario: $usuario, rol: $rolCuentaEmpleadoCodigo, sucursal: $sucursal, sucursalId: $sucursalId}';
  }
}

class AuthApi {
  final ApiClient _api;
  
  AuthApi(this._api);
  
  /// Inicia sesión con usuario y contraseña
  /// 
  /// Retorna los datos del usuario y configura los tokens de autenticación
  Future<UsuarioAutenticado> login(String usuario, String clave) async {
    debugPrint('Intentando login para usuario: $usuario');
    try {
      final response = await _api.request(
        endpoint: '/auth/login',
        method: 'POST',
        body: {
          'usuario': usuario,
          'clave': clave,
        },
      );
      
      debugPrint('Respuesta de login recibida: ${response.toString()}');
      
      // Verificar que data existe y es un Map
      if (response['data'] == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Error: Datos de usuario no encontrados en la respuesta',
        );
      }
      
      if (response['data'] is! Map<String, dynamic>) {
        debugPrint('ERROR: data no es un Map<String, dynamic>. Tipo actual: ${response['data'].runtimeType}');
        debugPrint('Contenido de data: ${response['data']}');
        throw ApiException(
          statusCode: 500,
          message: 'Error: Formato de datos de usuario inválido',
        );
      }
      
      // Obtener el token guardado en SharedPreferences (ya debería estar guardado desde el request)
      final prefs = await SharedPreferences.getInstance();
      String? tokenFromPrefs = prefs.getString('access_token');
      
      if (tokenFromPrefs == null || tokenFromPrefs.isEmpty) {
        debugPrint('ADVERTENCIA: No se encontró token en SharedPreferences después del login');
        throw ApiException(
          statusCode: 401,
          message: 'Error: No se pudo obtener el token de autenticación',
          errorCode: ApiException.errorUnauthorized,
        );
      }
      
      debugPrint('Token encontrado en SharedPreferences: ${tokenFromPrefs.substring(0, min(10, tokenFromPrefs.length))}...');
      
      // Crear y retornar el objeto de usuario autenticado
      final usuarioAutenticado = UsuarioAutenticado.fromJson(response['data'], tokenFromPrefs);
      
      debugPrint('Usuario autenticado creado: $usuarioAutenticado');
      return usuarioAutenticado;
    } catch (e) {
      debugPrint('ERROR durante login: $e');
      rethrow;
    }
  }
  
  
  /// Registra un nuevo usuario
  /// 
  /// Retorna los datos del usuario registrado y configura los tokens de autenticación
  Future<UsuarioAutenticado> register(Map<String, dynamic> userData) async {
    debugPrint('Intentando registrar nuevo usuario: ${userData['usuario']}');
    try {
      final response = await _api.request(
        endpoint: '/auth/register',
        method: 'POST',
        body: userData,
      );
      
      debugPrint('Respuesta de registro recibida: ${response.toString()}');
      
      // Extraer el token de autenticación
      final String token = response['token'] ?? '';
      if (token.isEmpty) {
        debugPrint('ADVERTENCIA: Token vacío en la respuesta de registro');
      }
      
      // Configurar el token en el cliente API
      _api.setTokens(token: token, refreshToken: null);
      
      // Crear y retornar el objeto de usuario autenticado
      final usuarioAutenticado = UsuarioAutenticado.fromJson(response['data'], token);
      debugPrint('Usuario registrado creado: $usuarioAutenticado');
      return usuarioAutenticado;
    } catch (e) {
      debugPrint('ERROR durante registro: $e');
      rethrow;
    }
  }
  
  /// Refresca el token de acceso usando el token de refresco
  /// 
  /// Retorna un nuevo token de acceso
  Future<String> refreshToken() async {
    debugPrint('Intentando refrescar token');
    try {
      final response = await _api.request(
        endpoint: '/auth/refresh',
        method: 'POST',
      );
      
      debugPrint('Respuesta de refresh token recibida: ${response.toString()}');
      
      // El token ya debería estar almacenado en SharedPreferences desde la extracción en _api.request
      final prefs = await SharedPreferences.getInstance();
      String? tokenFromPrefs = prefs.getString('access_token');
      
      if (tokenFromPrefs == null || tokenFromPrefs.isEmpty) {
        debugPrint('ADVERTENCIA: No se encontró token en SharedPreferences después del refresh');
        throw ApiException(
          statusCode: 401,
          message: 'No se pudo obtener un token válido al refrescar',
          errorCode: ApiException.errorUnauthorized,
        );
      }
      
      debugPrint('Token refrescado correctamente: ${tokenFromPrefs.substring(0, min(10, tokenFromPrefs.length))}...');
      return tokenFromPrefs;
    } catch (e) {
      debugPrint('ERROR durante refresh token: $e');
      rethrow;
    }
  }
}

class AuthService {
  final ApiClient _api;
  final SharedPreferences _prefs;
  
  AuthService(this._api, this._prefs);
  
  // Guardar tokens después del login
  Future<void> saveTokens(String accessToken, String? refreshToken) async {
    debugPrint('Guardando tokens - accessToken: ${accessToken.isNotEmpty ? 'presente' : 'vacío'}');
    try {
      await _prefs.setString('access_token', accessToken);
      if (refreshToken != null) {
        await _prefs.setString('refresh_token', refreshToken);
      }
      _api.setTokens(token: accessToken, refreshToken: refreshToken);
    } catch (e) {
      debugPrint('ERROR al guardar tokens: $e');
      rethrow;
    }
  }
  
  // Guardar datos del usuario
  Future<void> saveUserData(UsuarioAutenticado usuario) async {
    debugPrint('Guardando datos de usuario: $usuario');
    try {
      usuario.toMap();
      await _prefs.setString('user_id', usuario.id);
      await _prefs.setString('username', usuario.usuario);
      await _prefs.setString('user_role', usuario.rolCuentaEmpleadoCodigo);
      await _prefs.setString('user_sucursal', usuario.sucursal);
      await _prefs.setInt('user_sucursal_id', usuario.sucursalId);
      
      // Guardar el token
      await saveTokens(usuario.token, null);
      debugPrint('Datos de usuario guardados correctamente');
    } catch (e) {
      debugPrint('ERROR al guardar datos de usuario: $e');
      rethrow;
    }
  }
  
  // Cargar tokens al iniciar la app
  Future<bool> loadTokens() async {
    debugPrint('Cargando tokens guardados');
    try {
      final accessToken = _prefs.getString('access_token');
      final refreshToken = _prefs.getString('refresh_token');
      
      if (accessToken != null) {
        debugPrint('Token encontrado, configurando en API');
        _api.setTokens(token: accessToken, refreshToken: refreshToken);
        return true;
      }
      debugPrint('No se encontró token guardado');
      return false;
    } catch (e) {
      debugPrint('ERROR al cargar tokens: $e');
      return false;
    }
  }
  
  // Obtener datos del usuario guardados
  Map<String, dynamic>? getUserData() {
    debugPrint('Obteniendo datos de usuario guardados');
    try {
      final userId = _prefs.getString('user_id');
      final username = _prefs.getString('username');
      final userRole = _prefs.getString('user_role');
      final token = _prefs.getString('access_token');
      
      if (userId != null && username != null && userRole != null && token != null) {
        // Normalizar el rol para que coincida con los roles de la aplicación
        String rolNormalizado = userRole.toUpperCase();
        
        // Mapeo de roles específicos
        switch (rolNormalizado) {
          case 'ADM':
          case 'ADMIN':
          case 'ADMINSTRADOR':
            rolNormalizado = 'ADMINISTRADOR';
            break;
          case 'VEN':
            rolNormalizado = 'VENDEDOR';
            break;
          case 'COMP':
          case 'COMPUTER':
          case 'COMPUTADORA':
            rolNormalizado = 'COMPUTADORA';
            break;
          // Mantener el rol como está si no coincide con ninguno de los anteriores
        }
        
        debugPrint('Rol normalizado de "$userRole" a "$rolNormalizado" en getUserData');
        
        final userData = {
          'id': userId,
          'usuario': username,
          'rol': rolNormalizado,
          'token': token,
          'sucursal': _prefs.getString('user_sucursal') ?? '',
          'sucursalId': _prefs.getInt('user_sucursal_id') ?? 0,
        };
        debugPrint('Datos de usuario recuperados: $userData');
        return userData;
      }
      
      debugPrint('No se encontraron datos de usuario completos');
      return null;
    } catch (e) {
      debugPrint('ERROR al obtener datos de usuario: $e');
      return null;
    }
  }
  
  // Limpiar tokens y datos de usuario al cerrar sesión
  Future<void> logout() async {
    debugPrint('Cerrando sesión, limpiando datos');
    try {
      await _prefs.remove('access_token');
      await _prefs.remove('refresh_token');
      await _prefs.remove('user_id');
      await _prefs.remove('username');
      await _prefs.remove('user_role');
      await _prefs.remove('user_sucursal');
      await _prefs.remove('user_sucursal_id');
      _api.setTokens(token: null, refreshToken: null);
      debugPrint('Sesión cerrada correctamente');
    } catch (e) {
      debugPrint('ERROR al cerrar sesión: $e');
      rethrow;
    }
  }
}

/// Clase para manejar operaciones relacionadas con cuentas de empleados
/// 
/// Esta clase proporciona métodos para interactuar con el endpoint /api/cuentasempleados
class CuentasEmpleadosApi {
  final ApiClient _api;
  
  CuentasEmpleadosApi(this._api);
  
  /// Obtiene todas las cuentas de empleados con información detallada
  /// 
  /// Retorna una lista con todas las cuentas de empleados incluyendo información
  /// sobre el empleado, rol y sucursal asociados
  Future<List<Map<String, dynamic>>> getCuentasEmpleados() async {
    try {
      debugPrint('CuentasEmpleadosApi: Obteniendo lista de cuentas de empleados');
      
      final response = await _api.authenticatedRequest(
        endpoint: '/cuentasempleados',
        method: 'GET',
      );
      
      // Procesar la respuesta
      List<dynamic> data;
      if (response['data'] is List) {
        data = response['data'];
      } else if (response['data'] is Map && response['data']['data'] is List) {
        data = response['data']['data'];
      } else {
        data = [];
      }
      
      debugPrint('CuentasEmpleadosApi: Total de cuentas encontradas: ${data.length}');
      return data.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('CuentasEmpleadosApi: ERROR al obtener cuentas de empleados: $e');
      rethrow;
    }
  }
  
  /// Obtiene una cuenta de empleado por su ID
  /// 
  /// Retorna la información completa de una cuenta específica
  Future<Map<String, dynamic>?> getCuentaEmpleadoById(int id) async {
    try {
      debugPrint('CuentasEmpleadosApi: Obteniendo cuenta de empleado con ID $id');
      
      final response = await _api.authenticatedRequest(
        endpoint: '/cuentasempleados/$id',
        method: 'GET',
      );
      
      if (response['data'] is Map<String, dynamic>) {
        return response['data'];
      }
      
      return null;
    } catch (e) {
      // Si el error es 404, simplemente retornar null
      if (e is ApiException && e.statusCode == 404) {
        debugPrint('CuentasEmpleadosApi: No se encontró la cuenta con ID $id');
        return null;
      }
      
      debugPrint('CuentasEmpleadosApi: ERROR al obtener cuenta de empleado: $e');
      rethrow;
    }
  }
  
  /// Actualiza la información de una cuenta de empleado
  /// 
  /// Permite modificar el usuario o el rol de una cuenta existente
  Future<Map<String, dynamic>> updateCuentaEmpleado({
    required int id,
    String? usuario,
    String? clave,
    int? rolCuentaEmpleadoId,
  }) async {
    try {
      debugPrint('CuentasEmpleadosApi: Actualizando cuenta de empleado con ID $id');
      
      // Verificar que se haya proporcionado al menos un campo
      if (usuario == null && clave == null && rolCuentaEmpleadoId == null) {
        throw ApiException(
          statusCode: 400,
          message: 'Debe proporcionar al menos un campo para actualizar',
        );
      }
      
      // Construir cuerpo de la solicitud
      final Map<String, dynamic> body = {};
      if (usuario != null) body['usuario'] = usuario;
      if (clave != null) body['clave'] = clave;
      if (rolCuentaEmpleadoId != null) body['rolCuentaEmpleadoId'] = rolCuentaEmpleadoId;
      
      final response = await _api.authenticatedRequest(
        endpoint: '/cuentasempleados/$id',
        method: 'PATCH',
        body: body,
      );
      
      if (response['data'] is Map<String, dynamic>) {
        return response['data'];
      }
      
      throw ApiException(
        statusCode: 500,
        message: 'Formato de respuesta inesperado',
      );
    } catch (e) {
      debugPrint('CuentasEmpleadosApi: ERROR al actualizar cuenta de empleado: $e');
      rethrow;
    }
  }
  
  /// Elimina una cuenta de empleado
  /// 
  /// Elimina permanentemente una cuenta de usuario
  Future<bool> deleteCuentaEmpleado(int id) async {
    try {
      debugPrint('CuentasEmpleadosApi: Eliminando cuenta de empleado con ID $id');
      
      await _api.authenticatedRequest(
        endpoint: '/cuentasempleados/$id',
        method: 'DELETE',
      );
      
      debugPrint('CuentasEmpleadosApi: Cuenta de empleado eliminada correctamente');
      return true;
    } catch (e) {
      debugPrint('CuentasEmpleadosApi: ERROR al eliminar cuenta de empleado: $e');
      return false;
    }
  }
  
  /// Obtiene la cuenta de un empleado por su ID de empleado
  /// 
  /// Útil para verificar si un empleado ya tiene una cuenta asociada
  Future<Map<String, dynamic>?> getCuentaByEmpleadoId(String empleadoId) async {
    try {
      debugPrint('CuentasEmpleadosApi: Obteniendo cuenta para empleado con ID $empleadoId');
      
      final response = await _api.authenticatedRequest(
        endpoint: '/cuentasempleados/empleado/$empleadoId',
        method: 'GET',
      );
      
      if (response['data'] is Map<String, dynamic>) {
        return response['data'];
      }
      
      return null;
    } catch (e) {
      // Si el error es 404, simplemente retornar null (el empleado no tiene cuenta)
      if (e is ApiException && e.statusCode == 404) {
        debugPrint('CuentasEmpleadosApi: El empleado $empleadoId no tiene cuenta asociada');
        return null;
      }
      
      debugPrint('CuentasEmpleadosApi: ERROR al obtener cuenta por empleado: $e');
      rethrow;
    }
  }
  
  /// Obtiene los roles disponibles para cuentas de empleados
  /// 
  /// Retorna una lista de todos los roles que pueden asignarse a una cuenta
  Future<List<Map<String, dynamic>>> getRolesCuentas() async {
    try {
      debugPrint('CuentasEmpleadosApi: Obteniendo roles para cuentas');
      
      final response = await _api.authenticatedRequest(
        endpoint: '/rolescuentas',
        method: 'GET',
      );
      
      if (response['data'] is List) {
        return (response['data'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('CuentasEmpleadosApi: ERROR al obtener roles de cuentas: $e');
      return [];
    }
  }
  
  /// Registra una cuenta para un empleado
  /// 
  /// Crea una nueva cuenta de usuario asociada a un empleado existente
  Future<Map<String, dynamic>> registerEmpleadoAccount({
    required String empleadoId,
    required String usuario,
    required String clave,
    required int rolCuentaEmpleadoId,
  }) async {
    try {
      debugPrint('CuentasEmpleadosApi: Registrando cuenta para empleado $empleadoId');
      
      final response = await _api.authenticatedRequest(
        endpoint: '/auth/register',
        method: 'POST',
        body: {
          'empleadoId': empleadoId,
          'usuario': usuario,
          'clave': clave,
          'rolCuentaEmpleadoId': rolCuentaEmpleadoId,
        },
      );
      
      // Procesar la respuesta
      if (response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw ApiException(
          statusCode: 500,
          message: 'Formato de respuesta inesperado al registrar cuenta',
        );
      }
      
    } catch (e) {
      debugPrint('CuentasEmpleadosApi: ERROR al registrar cuenta de empleado: $e');
      rethrow;
    }
  }
}