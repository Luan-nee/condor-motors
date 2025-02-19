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
    // Verificar si el usuario está autenticado
    final bool isAuthenticated = settings.name != login;

    // Si no está autenticado y trata de acceder a una ruta protegida
    if (!isAuthenticated && settings.name != login) {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    }

    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const DashboardAdminScreen());
      case colabDashboard:
        return MaterialPageRoute(builder: (_) => const DashboardColabScreen());
      case vendorDashboard:
        return MaterialPageRoute(builder: (_) => const DashboardVendorScreen());
      case computerDashboard:
        return MaterialPageRoute(builder: (_) => const DashboardComputerScreen());
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

  static String getInitialRoute(String? userRole) {
    switch (userRole?.toUpperCase()) {
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
}
