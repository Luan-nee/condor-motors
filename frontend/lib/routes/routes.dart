import 'package:flutter/material.dart';
import '../screens/admin/slides_admin.dart';
import '../screens/computer/dashboard_computer.dart';
import '../screens/colabs/selector_colab.dart';  // Vista para vendedores
import '../screens/login.dart';
import '../api/empleados.api.dart';

class Routes {
  static const String login = '/';
  static const String adminDashboard = '/admin';
  static const String vendedorDashboard = '/vendedor';
  static const String computerDashboard = '/computer';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Obtener datos del empleado si existen
    final empleadoData = settings.arguments as Map<String, dynamic>?;

    // Verificar si el usuario está autenticado
    final bool isAuthenticated = settings.name != login && 
        empleadoData != null && 
        empleadoData['token'] != null;

    // Si no está autenticado y trata de acceder a una ruta protegida
    if (!isAuthenticated && settings.name != login) {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    }

    // Verificar permisos según el rol
    if (isAuthenticated) {
      final rol = empleadoData['rol'].toString().toUpperCase();
      final routeName = settings.name ?? '';

      // Verificar si el rol es válido usando los roles definidos en EmpleadoApi
      if (!EmpleadoApi.roles.containsKey(rol)) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Rol no válido: $rol'),
            ),
          ),
        );
      }

      // Verificar si tiene acceso a la ruta
      if (!_canAccessRoute(rol, routeName)) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No tienes permiso para acceder a esta ruta: $routeName'),
            ),
          ),
        );
      }
    }

    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case adminDashboard:
        return MaterialPageRoute(
          builder: (_) => const SlidesAdminScreen(),
          settings: settings,
        );
      case vendedorDashboard:
        return MaterialPageRoute(
          builder: (_) => const SelectorColabScreen(), // Usando la vista de colaborador para vendedores
          settings: settings,
        );
      case computerDashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardComputerScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Ruta no encontrada: ${settings.name}'),
            ),
          ),
        );
    }
  }

  static String getInitialRoute(String? rol) {
    if (rol == null || !EmpleadoApi.roles.containsKey(rol.toUpperCase())) {
      return login;
    }

    switch (rol.toUpperCase()) {
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

  // Verificar si el rol tiene acceso a la ruta
  static bool _canAccessRoute(String rol, String route) {
    if (!EmpleadoApi.roles.containsKey(rol)) return false;
    
    final rolUpper = rol.toUpperCase();
    switch (rolUpper) {
      case 'ADMINISTRADOR':
        return true; // Acceso total
      case 'VENDEDOR':
        return route == vendedorDashboard;
      case 'COMPUTADORA':
        return route == computerDashboard;
      default:
        return false;
    }
  }
}
