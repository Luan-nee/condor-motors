import 'package:condorsmotors/api/auth.api.dart';
import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/index.protected.dart';
import 'package:flutter/foundation.dart';

export 'auth.api.dart';
export 'main.api.dart';
export 'protected/index.protected.dart';

/// Clase principal para acceder a todas las APIs
class CondorMotorsApi {
  late final ApiClient _apiClient;
  late final AuthApi auth;
  late final AuthService authService;
  late final SucursalesApi sucursales;
  late final EmpleadosApi empleados;
  late final MarcasApi marcas;
  late final VentasApi ventas;
  late final MovimientosApi movimientos;
  late final ProductosApi productos;
  late final StocksApi stocks;
  late final CategoriasApi categorias;
  late final CuentasEmpleadosApi cuentasEmpleados;
  late final ProformaVentaApi proformas;
  late final ColoresApi colores;
  late final ClientesApi clientes;
  late final DocumentoApi documentos;

  /// Inicializa todas las APIs con la URL base
  CondorMotorsApi({required String baseUrl}) {
    debugPrint('Inicializando CondorMotorsApi con URL base: $baseUrl');

    try {
      // Crear el cliente API
      _apiClient = ApiClient(baseUrl: baseUrl);

      // Inicializar APIs de autenticación
      auth = AuthApi(_apiClient);
      authService = AuthService(auth);

      // Inicializar APIs protegidas
      sucursales = SucursalesApi(_apiClient);
      empleados = EmpleadosApi(_apiClient);
      marcas = MarcasApi(_apiClient);
      ventas = VentasApi(_apiClient);
      movimientos = MovimientosApi(_apiClient);
      productos = ProductosApi(_apiClient);
      stocks = StocksApi(_apiClient);
      categorias = CategoriasApi(_apiClient);
      cuentasEmpleados = CuentasEmpleadosApi(_apiClient);
      proformas = ProformaVentaApi(_apiClient);
      colores = ColoresApi(apiClient: _apiClient);
      clientes = ClientesApi(_apiClient);
      documentos = DocumentoApi(_apiClient);

      debugPrint('APIs inicializadas correctamente');
    } catch (e) {
      debugPrint('Error al inicializar APIs: $e');
      rethrow;
    }
  }

  /// Verifica la conectividad con el servidor
  Future<bool> checkConnectivity() async {
    try {
      await auth.verificarToken();
      debugPrint('Conectividad verificada correctamente');
      return true;
    } catch (e) {
      debugPrint('Error al verificar conectividad: $e');
      return false;
    }
  }

  /// Verifica si hay una sesión activa
  Future<bool> hasActiveSession() async {
    try {
      final bool isAuthenticated = await auth.isAuthenticated();
      debugPrint(
          'Estado de sesión: ${isAuthenticated ? 'activa' : 'inactiva'}');
      return isAuthenticated;
    } catch (e) {
      debugPrint('Error al verificar sesión: $e');
      return false;
    }
  }

  /// Cierra la sesión y limpia todos los datos
  Future<void> logout() async {
    try {
      await auth.logout();
      debugPrint('Sesión cerrada correctamente');
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
      rethrow;
    }
  }
}
