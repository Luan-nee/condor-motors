import 'package:condorsmotors/main.dart' show navigatorKey;
import 'package:condorsmotors/screens/admin/slides_admin.dart';
import 'package:condorsmotors/screens/colabs/selector_colab.dart';  // Vista para vendedores
import 'package:condorsmotors/screens/computer/slides_computer.dart';
import 'package:condorsmotors/screens/login.dart';
import 'package:condorsmotors/utils/role_utils.dart' as role_utils;
import 'package:flutter/material.dart';

// Re-exportar las constantes de rutas desde role_utils para compatibilidad
// Esto permite que el código existente siga funcionando sin cambios
const String login = role_utils.login;
const String adminDashboard = role_utils.adminDashboard;
const String vendedorDashboard = role_utils.vendedorDashboard;
const String computerDashboard = role_utils.computerDashboard;

// Re-exportar la definición de roles
const Map<String, String> roles = role_utils.roles;

// Obtener la ruta inicial según el rol del usuario
String getInitialRoute(String rol) {
  return role_utils.getInitialRoute(rol);
}

Route<dynamic> generateRoute(
  RouteSettings settings, {
  String? initialRoute, 
  Map<String, dynamic>? userData,
}) {
  // Si tenemos una ruta inicial predeterminada y no es login,
  // usarla en lugar de la que viene en los settings
  final String effectiveRoute = (initialRoute != null && initialRoute != role_utils.login)
      ? initialRoute
      : (settings.name ?? role_utils.login);
  
  // Usar los datos de usuario proporcionados o extraerlos de los argumentos de la ruta
  final Map<String, dynamic>? effectiveUserData = userData ?? 
      (settings.arguments is Map<String, dynamic> ? settings.arguments as Map<String, dynamic> : null);

  // Verificar si el usuario está autenticado
  final bool isAuthenticated = effectiveRoute != role_utils.login && 
      effectiveUserData != null && 
      effectiveUserData['token'] != null;

  // Si no está autenticado y trata de acceder a una ruta protegida
  if (!isAuthenticated && effectiveRoute != role_utils.login) {
    debugPrint('Redirigiendo a login: Usuario no autenticado intentando acceder a $effectiveRoute');
    return MaterialPageRoute(builder: (_) => const LoginScreen());
  }

  // Verificar permisos según el rol
  if (isAuthenticated) {
    final String rol = effectiveUserData['rol']?.toString() ?? '';
    debugPrint('Verificando permisos para rol original: $rol');
    
    // Normalizar el rol usando nuestra utilidad
    final String rolNormalizado = role_utils.normalizeRole(rol);
    
    // Actualizar el rol normalizado en los datos de usuario para uso posterior
    if (rolNormalizado != rol) {
      effectiveUserData['rol'] = rolNormalizado;
      debugPrint('Rol actualizado de "$rol" a "$rolNormalizado" en datos de usuario');
    }
    
    // Verificar si el rol es válido después de la normalización
    if (rolNormalizado == 'DESCONOCIDO') {
      debugPrint('Rol no válido después de normalización: $rol');
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Rol no reconocido: $rol', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                const Text('Por favor contacte al administrador del sistema.'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(navigatorKey.currentContext!)
                        .pushReplacementNamed(role_utils.login);
                  },
                  child: const Text('Volver al inicio de sesión'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Verificar si tiene acceso a la ruta usando nuestra utilidad
    if (!role_utils.canAccessRoute(rolNormalizado, effectiveRoute)) {
      debugPrint('Acceso denegado: Rol $rolNormalizado no puede acceder a $effectiveRoute');
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Acceso denegado'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.lock, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('No tienes permiso para acceder a esta ruta: $effectiveRoute'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(navigatorKey.currentContext!)
                        .pushReplacementNamed(role_utils.getInitialRoute(rolNormalizado));
                  },
                  child: const Text('Volver a la pantalla principal'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  switch (effectiveRoute) {
    case role_utils.login:
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case role_utils.adminDashboard:
      return MaterialPageRoute(
        builder: (_) => const SlidesAdminScreen(),
        settings: settings,
      );
    case role_utils.vendedorDashboard:
      return MaterialPageRoute(
        builder: (_) => SelectorColabScreen(empleadoData: effectiveUserData),
        settings: settings,
      );
    case role_utils.computerDashboard:
      return MaterialPageRoute(
        builder: (_) => const SlidesComputerScreen(),
        settings: settings,
      );
    default:
      debugPrint('Ruta no encontrada: $effectiveRoute');
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Error de navegación'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 64, color: Colors.amber),
                const SizedBox(height: 16),
                Text('Ruta no encontrada: $effectiveRoute'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(navigatorKey.currentContext!)
                        .pushReplacementNamed(role_utils.login);
                  },
                  child: const Text('Volver al inicio de sesión'),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
