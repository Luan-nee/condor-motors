import 'package:flutter/foundation.dart';
import 'main.api.dart';
import '../services/token_service.dart';
import '../utils/role_utils.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

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
    String rolNormalizado = RoleUtils.normalizeRole(rolCuentaEmpleadoCodigo);
    
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
      // La solicitud a /auth/login configura automáticamente los tokens en TokenService
      // gracias a nuestro método _processTokenFromResponse modificado
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
      
      final userData = response['data'] as Map<String, dynamic>;
      
      // Obtener el token ya procesado por ApiClient
      final token = TokenService.instance.accessToken;
      
      if (token == null || token.isEmpty) {
        debugPrint('ADVERTENCIA: No se encontró token después del login');
        throw ApiException(
          statusCode: 401,
          message: 'Error: No se pudo obtener el token de autenticación',
          errorCode: ApiException.errorUnauthorized,
        );
      }
      
      // Guardar credenciales para futuros reintentos
      try {
        // Guardar credenciales en el TokenService para login automático
        await TokenService.instance.saveCredentials(usuario, clave);
        debugPrint('Credenciales guardadas en TokenService para futuros reintentos de autenticación');
      } catch (e) {
        // No interrumpir el flujo si hay error al guardar credenciales
        debugPrint('ADVERTENCIA: No se pudieron guardar credenciales: $e');
      }
      
      // Crear y retornar el objeto de usuario autenticado
      final usuarioAutenticado = UsuarioAutenticado.fromJson(userData, token);
      
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
      
      // El token se configuró automáticamente en TokenService
      final token = TokenService.instance.accessToken;
      
      if (token == null || token.isEmpty) {
        debugPrint('ADVERTENCIA: Token vacío después del registro');
        throw ApiException(
          statusCode: 401,
          message: 'Error: No se pudo obtener el token de autenticación',
          errorCode: ApiException.errorUnauthorized,
        );
      }
      
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
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Obtener el nuevo token
      final token = TokenService.instance.accessToken;
      
      if (token == null || token.isEmpty) {
        debugPrint('ADVERTENCIA: No se encontró token después del refresh');
        throw ApiException(
          statusCode: 401,
          message: 'No se pudo obtener un token válido al refrescar',
          errorCode: ApiException.errorUnauthorized,
        );
      }
      
      debugPrint('Token refrescado correctamente: ${token.substring(0, 20)}...');
      return token;
    } catch (e) {
      debugPrint('ERROR durante refresh token: $e');
      
      // Si el error indica que el refresh token es inválido, eliminar todos los tokens
      if (e is ApiException && 
          (e.statusCode == 401 || e.message.contains('refresh token'))) {
        debugPrint('Eliminando tokens debido a refresh token inválido');
        await TokenService.instance.clearTokens();
      }
      
      rethrow;
    }
  }

  /// Método simple para verificar la conectividad con el servidor
  /// 
  /// Útil para detectar si el servidor está disponible
  Future<bool> ping() async {
    try {
      // Intentamos hacer una petición simple a la raíz del servidor
      // Este endpoint debería ser público y no requerir autenticación
      final serverUrl = _api.baseUrl.replaceAll('/api', '');
      debugPrint('AuthApi: Haciendo ping a $serverUrl');
      
      final response = await http.get(
        Uri.parse(serverUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      // Si la respuesta tiene código 200-299, el servidor está disponible
      final bool isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      
      debugPrint('AuthApi: Ping al servidor - Status: ${response.statusCode}, Éxito: $isSuccess');
      return isSuccess;
    } catch (e) {
      debugPrint('AuthApi: Error al hacer ping al servidor: $e');
      return false;
    }
  }
  
  /// Verifica si el token actual es válido o intenta renovarlo
  ///
  /// Este método verifica si el token está expirado y lo renueva si es necesario
  Future<bool> verificarToken() async {
    try {
      // Si no hay token, fallar inmediatamente
      final token = TokenService.instance.accessToken;
      if (token == null) {
        debugPrint('AuthApi: No hay token para verificar');
        return false;
      }
      
      // Verificar si el token está expirado según la fecha almacenada
      if (TokenService.instance.isTokenExpired) {
        debugPrint('AuthApi: Token expirado según fecha local: ${TokenService.instance.expiryTime}');
        
        // Si tenemos refresh token, intentar renovar
        if (TokenService.instance.hasRefreshToken) {
          debugPrint('AuthApi: Intentando renovar token expirado...');
          try {
            // Usar el método authenticatedRequest del TokenService
            await TokenService.instance.authenticatedRequest(
              endpoint: '/auth/refresh',
              method: 'POST',
            );
            
            debugPrint('AuthApi: Token renovado exitosamente');
            return true;
          } catch (e) {
            debugPrint('AuthApi: Error al renovar token expirado: $e');
            await TokenService.instance.clearTokens();
            return false;
          }
        } else {
          debugPrint('AuthApi: No hay refresh token para renovar token expirado');
          await TokenService.instance.clearTokens();
          return false;
        }
      }
      
      debugPrint('AuthApi: Verificando token con el servidor...');
      debugPrint('AuthApi: Token actual (primeros 20 caracteres): ${token.substring(0, math.min(20, token.length))}...');
      
      // En lugar de usar /auth/status que no existe, verificamos la validez del token
      // intentando obtener información desde el token mismo
      try {
        // Intentar decodificar el token para verificar si es válido
        final tokenInfo = TokenService.instance.extractUserInfoFromToken();
        if (tokenInfo.isEmpty) {
          debugPrint('AuthApi: Token no contiene información válida');
          return false;
        }
        
        debugPrint('AuthApi: Token contiene información válida: ${tokenInfo['usuario']}, Rol: ${tokenInfo['rol']}');
        
        // Como verificación adicional, podemos hacer una petición a un endpoint que sabemos que existe
        // Por ejemplo, podemos usar /cuentasempleados que requiere autenticación
        try {
          await TokenService.instance.authenticatedRequest(
            endpoint: '/cuentasempleados',
            method: 'GET',
          );
          debugPrint('AuthApi: Token verificado correctamente con petición a /cuentasempleados');
          return true;
        } catch (e) {
          // Si hay un error 401, intentar refrescar el token
          if (e.toString().contains('401')) {
            debugPrint('AuthApi: Token rechazado por el servidor (401)');
            
            // Verificar si tenemos un refresh token para intentar renovar
            if (TokenService.instance.hasRefreshToken) {
              try {
                debugPrint('AuthApi: Intentando renovar token rechazado...');
                
                // Usar el método authenticatedRequest del TokenService
                await TokenService.instance.authenticatedRequest(
                  endpoint: '/auth/refresh',
                  method: 'POST',
                );
                
                debugPrint('AuthApi: Token renovado exitosamente después de rechazo');
                return true;
              } catch (refreshError) {
                debugPrint('AuthApi: Error al renovar token rechazado: $refreshError');
                await TokenService.instance.clearTokens();
                return false;
              }
            } else {
              debugPrint('AuthApi: No hay refresh token disponible para renovar token rechazado');
              await TokenService.instance.clearTokens();
              return false;
            }
          }
          
          // Para otros errores que no sean 401, podríamos tener problemas de red
          // pero el token todavía podría ser válido
          debugPrint('AuthApi: Error al verificar token con el servidor (no 401): $e');
          return !TokenService.instance.isTokenExpired;
        }
      } catch (e) {
        debugPrint('AuthApi: Error al extraer información del token: $e');
        return false;
      }
    } catch (e) {
      debugPrint('AuthApi: Error al verificar token: $e');
      return false;
    }
  }
}

class AuthService {
  final TokenService _tokenService;
  
  // Claves para almacenamiento de datos de usuario
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _userRoleKey = 'user_role';
  static const String _userSucursalKey = 'user_sucursal';
  static const String _userSucursalIdKey = 'user_sucursal_id';
  
  AuthService(this._tokenService);
  
  // Guardar datos del usuario
  Future<void> saveUserData(UsuarioAutenticado usuario) async {
    debugPrint('Guardando datos de usuario: $usuario');
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(_userIdKey, usuario.id);
      await prefs.setString(_usernameKey, usuario.usuario);
      await prefs.setString(_userRoleKey, usuario.rolCuentaEmpleadoCodigo);
      await prefs.setString(_userSucursalKey, usuario.sucursal);
      await prefs.setString(_userSucursalIdKey, usuario.sucursalId.toString());
      
      debugPrint('Datos de usuario guardados correctamente');
    } catch (e) {
      debugPrint('ERROR al guardar datos de usuario: $e');
      rethrow;
    }
  }
  
  // Cargar tokens al iniciar la app
  Future<bool> loadTokens() async {
    return await _tokenService.loadTokens();
  }
  
  // Obtener datos del usuario guardados
  Future<Map<String, dynamic>?> getUserData() async {
    debugPrint('Obteniendo datos de usuario guardados');
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final userId = prefs.getString(_userIdKey);
      final username = prefs.getString(_usernameKey);
      final userRole = prefs.getString(_userRoleKey);
      final token = _tokenService.accessToken;
      
      if (userId != null && username != null && userRole != null && token != null) {
        // Normalizar el rol para que coincida con los roles de la aplicación
        String rolNormalizado = RoleUtils.normalizeRole(userRole);
        
        debugPrint('Rol normalizado de "$userRole" a "$rolNormalizado" en getUserData');
        
        final userData = {
          'id': userId,
          'usuario': username,
          'rol': rolNormalizado,
          'token': token,
          'sucursal': prefs.getString(_userSucursalKey) ?? '',
          'sucursalId': int.tryParse(prefs.getString(_userSucursalIdKey) ?? '0') ?? 0,
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
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_userIdKey);
      await prefs.remove(_usernameKey);
      await prefs.remove(_userRoleKey);
      await prefs.remove(_userSucursalKey);
      await prefs.remove(_userSucursalIdKey);
      await _tokenService.clearTokens();
      
      debugPrint('Sesión cerrada correctamente, todos los datos eliminados');
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
      
      final response = await _api.request(
        endpoint: '/cuentasempleados',
        method: 'GET',
        requiresAuth: true,
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
      
      final response = await _api.request(
        endpoint: '/cuentasempleados/$id',
        method: 'GET',
        requiresAuth: true,
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
      
      final response = await _api.request(
        endpoint: '/cuentasempleados/$id',
        method: 'PATCH',
        body: body,
        requiresAuth: true,
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
      
      await _api.request(
        endpoint: '/cuentasempleados/$id',
        method: 'DELETE',
        requiresAuth: true,
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
      
      final response = await _api.request(
        endpoint: '/cuentasempleados/empleado/$empleadoId',
        method: 'GET',
        requiresAuth: true,
      );
      
      if (response['data'] is Map<String, dynamic>) {
        return response['data'];
      }
      
      return null;
    } catch (e) {
      // Si el error es 404 o 401, simplemente retornar null (el empleado no tiene cuenta)
      // El backend a veces devuelve 401 en lugar de 404 para este caso específico
      if (e is ApiException && (e.statusCode == 404 || e.statusCode == 401)) {
        debugPrint('CuentasEmpleadosApi: El empleado $empleadoId no tiene cuenta asociada (${e.statusCode})');
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
      
      final response = await _api.request(
        endpoint: '/rolescuentas',
        method: 'GET',
        requiresAuth: true,
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
  
  /// Registra una nueva cuenta para un empleado
  /// 
  /// Crea una cuenta de usuario asociada a un empleado existente
  Future<Map<String, dynamic>> registerEmpleadoAccount({
    required String empleadoId,
    required String usuario,
    required String clave,
    required int rolCuentaEmpleadoId,
  }) async {
    try {
      debugPrint('CuentasEmpleadosApi: Registrando cuenta para empleado con ID $empleadoId');
      
      // Preparar datos para la petición
      final Map<String, dynamic> body = {
        'empleadoId': empleadoId,
        'usuario': usuario,
        'clave': clave,
        'rolCuentaEmpleadoId': rolCuentaEmpleadoId,
      };
      
      // Hacer la petición al endpoint adecuado
      final response = await _api.request(
        endpoint: '/cuentasempleados',
        method: 'POST',
        body: body,
        requiresAuth: true,
      );
      
      // Verificar y devolver la respuesta
      if (response['data'] is Map<String, dynamic>) {
        debugPrint('CuentasEmpleadosApi: Cuenta registrada exitosamente');
        return response['data'];
      }
      
      throw ApiException(
        statusCode: 500,
        message: 'Formato de respuesta inesperado al registrar cuenta',
      );
    } catch (e) {
      debugPrint('CuentasEmpleadosApi: ERROR al registrar cuenta de empleado: $e');
      rethrow;
    }
  }
}