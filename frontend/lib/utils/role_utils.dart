import 'package:flutter/foundation.dart';

/// Rutas de navegación de la aplicación
const String login = '/';
const String adminDashboard = '/admin';
const String vendedorDashboard = '/vendedor';
const String computerDashboard = '/computer';

/// Definición de roles disponibles en la aplicación
const Map<String, String> roles = {
  'ADMINISTRADOR': 'ADMINISTRADOR',
  'ADMINSTRADOR': 'ADMINISTRADOR', // Typo en el backend
  'VENDEDOR': 'VENDEDOR',
  'COMPUTADORA': 'COMPUTADORA',
  'computadora': 'COMPUTADORA', // Versión en minúsculas del backend
  'adminstrador': 'ADMINISTRADOR', // Versión en minúsculas con typo del backend
  'administrador': 'ADMINISTRADOR', // Versión en minúsculas del backend
  'vendedor': 'VENDEDOR', // Versión en minúsculas del backend
};

/// Normaliza un rol de usuario a un formato estándar
String normalizeRole(String rol) {
  // Asegurar que rol no sea null o vacío
  if (rol.isEmpty) {
    debugPrint('ADVERTENCIA: Intentando normalizar un rol vacío');
    return 'DESCONOCIDO';
  }
  
  debugPrint('Normalizando rol: "$rol"');
  
  // Normalizar a mayúsculas para comparación
  String rolNormalizado = rol.toUpperCase();
  
  // Verificar primero en el mapa de roles de la aplicación
  if (roles.containsKey(rol)) {
    rolNormalizado = roles[rol]!;
    debugPrint('Rol encontrado en el mapa de roles: $rol -> $rolNormalizado');
    return rolNormalizado;
  }
  
  // Verificar en mayúsculas en el mapa de roles 
  if (roles.containsKey(rolNormalizado)) {
    rolNormalizado = roles[rolNormalizado]!;
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
bool canAccessRoute(String rol, String route) {
  // Primero normalizar el rol
  final String rolNormalizado = normalizeRole(rol);
  
  debugPrint('Verificando acceso para rol: $rol (normalizado: $rolNormalizado) a ruta: $route');
  
  // Verificar acceso según el rol normalizado
  switch (rolNormalizado) {
    case 'ADMINISTRADOR':
      return true; // Acceso total
    case 'VENDEDOR':
      return route == vendedorDashboard;
    case 'COMPUTADORA':
      return route == computerDashboard;
    default:
      debugPrint('Rol no manejado específicamente después de normalización: $rolNormalizado');
      return false;
  }
}

/// Obtiene la ruta inicial para un rol
String getInitialRoute(String rol) {
  // Normalizar el rol
  final String rolNormalizado = normalizeRole(rol);
  
  // Determinar ruta según rol normalizado
  switch (rolNormalizado) {
    case 'ADMINISTRADOR':
      return adminDashboard;
    case 'VENDEDOR':
      return vendedorDashboard;
    case 'COMPUTADORA':
      return computerDashboard;
    default:
      return login;
  }
} 