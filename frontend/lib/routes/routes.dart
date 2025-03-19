import 'package:flutter/material.dart';
import '../screens/admin/slides_admin.dart';
import '../screens/computer/slides_computer.dart';
import '../screens/colabs/selector_colab.dart';  // Vista para vendedores
import '../screens/login.dart';
import '../main.dart' show navigatorKey;
import '../utils/role_utils.dart';

class Routes {
  static const String login = '/';
  static const String adminDashboard = '/admin';
  static const String vendedorDashboard = '/vendedor';
  static const String computerDashboard = '/computer';
  
  // Definición de roles disponibles en la aplicación
  static const Map<String, String> roles = {
    'ADMINISTRADOR': 'ADMINISTRADOR',
    'ADMINSTRADOR': 'ADMINISTRADOR', // Typo en el backend
    'VENDEDOR': 'VENDEDOR',
    'COMPUTADORA': 'COMPUTADORA',
    'computadora': 'COMPUTADORA', // Versión en minúsculas del backend
    'adminstrador': 'ADMINISTRADOR', // Versión en minúsculas con typo del backend
    'administrador': 'ADMINISTRADOR', // Versión en minúsculas del backend
    'vendedor': 'VENDEDOR', // Versión en minúsculas del backend
  };

  // Obtener la ruta inicial según el rol del usuario
  static String getInitialRoute(String rol) {
    return RoleUtils.getInitialRoute(rol);
  }

  static Route<dynamic> generateRoute(
    RouteSettings settings, {
    String? initialRoute, 
    Map<String, dynamic>? userData,
  }) {
    // Si tenemos una ruta inicial predeterminada y no es login,
    // usarla en lugar de la que viene en los settings
    final String effectiveRoute = (initialRoute != null && initialRoute != login)
        ? initialRoute
        : (settings.name ?? login);
    
    // Usar los datos de usuario proporcionados o extraerlos de los argumentos de la ruta
    final Map<String, dynamic>? effectiveUserData = userData ?? 
        (settings.arguments is Map<String, dynamic> ? settings.arguments as Map<String, dynamic> : null);

    // Verificar si el usuario está autenticado
    final bool isAuthenticated = effectiveRoute != login && 
        effectiveUserData != null && 
        effectiveUserData['token'] != null;

    // Si no está autenticado y trata de acceder a una ruta protegida
    if (!isAuthenticated && effectiveRoute != login) {
      debugPrint('Redirigiendo a login: Usuario no autenticado intentando acceder a $effectiveRoute');
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    }

    // Verificar permisos según el rol
    if (isAuthenticated) {
      String rol = effectiveUserData['rol']?.toString() ?? '';
      debugPrint('Verificando permisos para rol original: $rol');
      
      // Normalizar el rol usando nuestra utilidad
      String rolNormalizado = RoleUtils.normalizeRole(rol);
      
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
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Rol no reconocido: $rol', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Por favor contacte al administrador del sistema.'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(navigatorKey.currentContext!)
                          .pushReplacementNamed(login);
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
      if (!RoleUtils.canAccessRoute(rolNormalizado, effectiveRoute)) {
        debugPrint('Acceso denegado: Rol $rolNormalizado no puede acceder a $effectiveRoute');
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('Acceso denegado'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('No tienes permiso para acceder a esta ruta: $effectiveRoute'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(navigatorKey.currentContext!)
                          .pushReplacementNamed(getInitialRoute(rolNormalizado));
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
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case adminDashboard:
        return MaterialPageRoute(
          builder: (_) => const SlidesAdminScreen(),
          settings: settings,
        );
      case vendedorDashboard:
        return MaterialPageRoute(
          builder: (_) => SelectorColabScreen(empleadoData: effectiveUserData),
          settings: settings,
        );
      case computerDashboard:
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
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.amber),
                  const SizedBox(height: 16),
                  Text('Ruta no encontrada: $effectiveRoute'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(navigatorKey.currentContext!)
                          .pushReplacementNamed(login);
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
}
