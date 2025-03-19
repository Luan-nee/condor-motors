import 'package:flutter/foundation.dart';
import '../routes/routes.dart';

/// Utilidad para normalizar y validar roles de usuario
class RoleUtils {

  static String normalizeRole(String rol) {
    // Asegurar que rol no sea null o vacío
    if (rol.isEmpty) {
      debugPrint('ADVERTENCIA: Intentando normalizar un rol vacío');
      return 'DESCONOCIDO';
    }
    
    debugPrint('Normalizando rol: "$rol"');
    
    // Normalizar a mayúsculas para comparación
    String rolNormalizado = rol.toUpperCase();
    
    // Verificar primero en el mapa de roles de la aplicación
    if (Routes.roles.containsKey(rol)) {
      rolNormalizado = Routes.roles[rol]!;
      debugPrint('Rol encontrado en el mapa de roles: $rol -> $rolNormalizado');
      return rolNormalizado;
    }
    
    // Verificar en mayúsculas en el mapa de roles 
    if (Routes.roles.containsKey(rolNormalizado)) {
      rolNormalizado = Routes.roles[rolNormalizado]!;
      debugPrint('Rol en mayúsculas encontrado en el mapa: $rolNormalizado');
      return rolNormalizado;
    }
    
    // Mapeo de roles específicos
    switch (rolNormalizado) {
      case 'ADM':
      case 'ADMIN':
      case 'ADMINSTRADOR': // Typo en el backend
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
    }
    
    // También verificar para versiones en minúsculas
    if (rol == 'adminstrador') {
      rolNormalizado = 'ADMINISTRADOR';
    } else if (rol == 'vendedor') {
      rolNormalizado = 'VENDEDOR';
    } else if (rol == 'computadora') {
      rolNormalizado = 'COMPUTADORA';
    }
    
    debugPrint('Rol normalizado de "$rol" a "$rolNormalizado"');
    return rolNormalizado;
  }
  
  /// Verifica si un rol puede acceder a una ruta específica
  static bool canAccessRoute(String rol, String route) {
    // Primero normalizar el rol
    String rolNormalizado = normalizeRole(rol);
    
    debugPrint('Verificando acceso para rol: $rol (normalizado: $rolNormalizado) a ruta: $route');
    
    // Verificar acceso según el rol normalizado
    switch (rolNormalizado) {
      case 'ADMINISTRADOR':
        return true; // Acceso total
      case 'VENDEDOR':
        return route == Routes.vendedorDashboard;
      case 'COMPUTADORA':
        return route == Routes.computerDashboard;
      default:
        debugPrint('Rol no manejado específicamente después de normalización: $rolNormalizado');
        return false;
    }
  }
  
  /// Obtiene la ruta inicial para un rol
  static String getInitialRoute(String rol) {
    // Normalizar el rol
    String rolNormalizado = normalizeRole(rol);
    
    // Determinar ruta según rol normalizado
    switch (rolNormalizado) {
      case 'ADMINISTRADOR':
        return Routes.adminDashboard;
      case 'VENDEDOR':
        return Routes.vendedorDashboard;
      case 'COMPUTADORA':
        return Routes.computerDashboard;
      default:
        return Routes.login;
    }
  }
} 