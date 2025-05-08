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

  String? roleString;

  // Extraer el string del rol dependiendo del tipo
  if (rol is Map && rol.containsKey('codigo')) {
    roleString = rol['codigo']?.toString().toLowerCase();
  } else if (rol is String) {
    roleString = rol.toLowerCase();
  }

  if (roleString == null) {
    return 'desconocido';
  }

  // FIX: (anterior) Lógica duplicada para normalizar 'administrador'
  // Ahora se comprueba una sola vez
  if (roleString == 'administrador') {
    return 'admin';
  }

  // Verificar si el rol normalizado existe en nuestro mapa de roles
  if (roles.containsKey(roleString)) {
    return roleString;
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

/// Centraliza la obtención del rol normalizado y la ruta inicial a partir de los datos de usuario
Map<String, String> getRoleAndInitialRoute(userData) {
  String rolCodigo = '';
  if (userData == null) {
    return {'rol': '', 'route': login};
  }
  if (userData['rol'] is Map) {
    rolCodigo = userData['rol']['codigo']?.toString() ?? '';
  } else {
    rolCodigo = userData['rol']?.toString() ?? '';
  }
  final String rolNormalizado = normalizeRole(rolCodigo);
  final String initialRoute = getInitialRoute(rolNormalizado);
  return {'rol': rolNormalizado, 'route': initialRoute};
}
