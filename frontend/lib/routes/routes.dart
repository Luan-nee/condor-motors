import 'package:flutter/material.dart';
import '../screens/admin/dashboard_admin.dart';
import '../screens/colabs/dashboard_colab.dart';
import '../screens/vendor/dashboard_vendor.dart';
import '../screens/computer/dashboard_computer.dart';
import '../screens/login.dart';

class Routes {
  static const String login = '/';
  static const String adminDashboard = '/admin';
  static const String colabDashboard = '/colab';
  static const String vendorDashboard = '/vendor';
  static const String computerDashboard = '/computer';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Obtener datos del empleado si existen
    final empleadoData = settings.arguments as Map<String, dynamic>?;

    // Verificar si el usuario está autenticado
    final bool isAuthenticated = settings.name != login && empleadoData != null;

    // Si no está autenticado y trata de acceder a una ruta protegida
    if (!isAuthenticated && settings.name != login) {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    }

    // Verificar permisos según el rol
    if (isAuthenticated) {
      final rol = empleadoData['rol'].toString().toUpperCase();
      final routeName = settings.name ?? '';

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
          builder: (_) => const DashboardAdminScreen(),
          settings: settings,
        );
      case colabDashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardColabScreen(),
          settings: settings,
        );
      case vendorDashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardVendorScreen(),
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
    switch (rol?.toUpperCase()) {
      case 'ADMINISTRADOR':
        return adminDashboard;
      case 'COLABORADOR':
        return colabDashboard;
      case 'VENDEDOR':
        return vendorDashboard;
      case 'COMPUTADORA':
        return computerDashboard;
      default:
        return login;
    }
  }

  // Verificar si el rol tiene acceso a la ruta
  static bool _canAccessRoute(String rol, String route) {
    final rolUpper = rol.toUpperCase();
    if (rolUpper == 'ADMINISTRADOR') return true; // Acceso total
    if (rolUpper == 'COLABORADOR') return route == colabDashboard;
    if (rolUpper == 'VENDEDOR') return route == vendorDashboard;
    if (rolUpper == 'COMPUTADORA') return route == computerDashboard;
    return false;
  }
}
