import 'package:condorsmotors/main.dart' show navigatorKey;
import 'package:condorsmotors/screens/admin/slides_admin.dart';
import 'package:condorsmotors/screens/colabs/selector_colab.dart'; // Vista para vendedores
import 'package:condorsmotors/screens/computer/slides_computer.dart';
import 'package:condorsmotors/screens/login.dart';
import 'package:condorsmotors/utils/role_utils.dart' as role_utils;
import 'package:flutter/material.dart';

// Re-exportar las constantes de rutas desde role_utils
const String login = role_utils.login;
const String admin = role_utils.admin;
const String vendedor = role_utils.vendedor;
const String computadora = role_utils.computadora;

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
  final String effectiveRoute = (initialRoute != null && initialRoute != login)
      ? initialRoute
      : (settings.name ?? login);

  // Usar los datos de usuario proporcionados o extraerlos de los argumentos de la ruta
  final Map<String, dynamic>? effectiveUserData = userData ??
      (settings.arguments is Map<String, dynamic>
          ? settings.arguments as Map<String, dynamic>
          : null);

  // Verificar si el usuario está autenticado
  final bool isAuthenticated =
      effectiveRoute != login && effectiveUserData != null;

  // Si no está autenticado y trata de acceder a una ruta protegida
  if (!isAuthenticated && effectiveRoute != login) {
    debugPrint(
        'Redirigiendo a login: Usuario no autenticado intentando acceder a $effectiveRoute');
    return MaterialPageRoute(builder: (_) => const LoginScreen());
  }

  // Verificar permisos según el rol
  if (isAuthenticated) {
    // Extraer el código del rol del formato correcto del backend
    String rolCodigo = '';
    if (effectiveUserData['rolCuentaEmpleadoCodigo'] != null) {
      rolCodigo = effectiveUserData['rolCuentaEmpleadoCodigo'].toString();
    } else if (effectiveUserData['rol'] is Map) {
      rolCodigo = (effectiveUserData['rol'] as Map)['codigo']?.toString() ?? '';
    } else {
      rolCodigo = effectiveUserData['rol']?.toString() ?? '';
    }

    rolCodigo = rolCodigo.toLowerCase();
    debugPrint('Verificando permisos para rol: $rolCodigo');

    // Verificar si tiene acceso a la ruta
    if (!role_utils.hasAccess(rolCodigo, effectiveRoute)) {
      debugPrint(
          'Acceso denegado: Rol $rolCodigo no puede acceder a $effectiveRoute');
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
                Text(
                    'No tienes permiso para acceder a esta ruta: $effectiveRoute'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(navigatorKey.currentContext!)
                        .pushReplacementNamed(
                            role_utils.getInitialRoute(rolCodigo));
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
    case admin:
      return MaterialPageRoute(
        builder: (_) => const SlidesAdminScreen(),
        settings: settings,
      );
    case vendedor:
      return MaterialPageRoute(
        builder: (_) => SelectorColabScreen(empleadoData: effectiveUserData),
        settings: settings,
      );
    case computadora:
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
