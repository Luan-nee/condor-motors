import 'package:flutter/foundation.dart';

/// Rutas de navegación de la aplicación
const String login = '/login';
const String admin = '/admin/dashboard';
const String vendedor = '/vendedor/dashboard';
const String computadora = '/computadora/dashboard';
const String gerente = '/gerente/dashboard';

/// Definición de roles disponibles en la aplicación
const Map<String, String> roles = {
  'admin': admin,
  'administrador': admin, // Agregar alias para administrador
  'vendedor': vendedor,
  'computadora': computadora,
  'gerente': gerente,
};

/// Normaliza un rol de usuario a un formato estándar
String normalizeRole(rol) {
  if (rol == null) {
    return 'desconocido';
  }

  // Si es un Map, extraer el código
  if (rol is Map) {
    final codigo = rol['codigo']?.toString().toLowerCase();
    if (codigo != null) {
      // Normalizar administrador a admin
      if (codigo == 'administrador') {
        return 'admin';
      }
      if (roles.containsKey(codigo)) {
        return codigo;
      }
    }
  }

  // Si es String, normalizar directamente
  if (rol is String) {
    final normalizedRole = rol.toLowerCase();
    // Normalizar administrador a admin
    if (normalizedRole == 'administrador') {
      return 'admin';
    }
    if (roles.containsKey(normalizedRole)) {
      return normalizedRole;
    }
  }

  return 'desconocido';
}

/// Verifica si un rol puede acceder a una ruta específica
bool hasAccess(String rol, String route) {
  // Primero normalizar el rol
  final String rolNormalizado = normalizeRole(rol);

  debugPrint(
      'Verificando acceso para rol: $rol (normalizado: $rolNormalizado) a ruta: $route');

  // Verificar acceso según el rol normalizado
  switch (rolNormalizado) {
    case 'admin':
      return true; // Acceso total para administrador
    case 'vendedor':
      return route.startsWith('/vendedor') || route == login;
    case 'computadora':
      return route.startsWith('/computadora') || route == login;
    default:
      debugPrint('Rol no reconocido: $rolNormalizado');
      return route == login;
  }
}

/// Obtiene la ruta inicial para un rol
String getInitialRoute(rol) {
  final normalizedRole = normalizeRole(rol);
  return roles[normalizedRole] ?? login;
}
