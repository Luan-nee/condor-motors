export 'main.api.dart';
export 'auth.api.dart';
export 'protected/index.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'main.api.dart';
import 'auth.api.dart';
import 'protected/sucursales.api.dart';
import 'protected/empleados.api.dart';
import 'protected/marcas.api.dart';
import 'protected/sucursal.admin.api.dart';
import 'protected/ventas.api.dart';
import 'protected/movimientos.api.dart';
import 'protected/productos.api.dart';
import 'protected/stocks.api.dart';

/// Clase principal para acceder a todas las APIs
class CondorMotorsApi {
  late final ApiClient _apiClient;
  late final AuthApi auth;
  late final AuthService authService;
  late final SucursalesApi sucursales;
  late final EmpleadosApi empleados;
  late final MarcasApi marcas;
  late final SucursalAdminApi sucursalAdmin;
  late final VentasApi ventas;
  late final MovimientosApi movimientos;
  late final ProductosApi productos;
  late final StocksApi stocks;
  
  /// Inicializa todas las APIs con la URL base
  CondorMotorsApi({required String baseUrl}) {
    _apiClient = ApiClient(baseUrl: baseUrl);
    auth = AuthApi(_apiClient);
    empleados = EmpleadosApi(_apiClient);
    sucursales = SucursalesApi(_apiClient);
    marcas = MarcasApi(_apiClient);
    sucursalAdmin = SucursalAdminApi(_apiClient);
    ventas = VentasApi(_apiClient);
    movimientos = MovimientosApi(_apiClient);
    productos = ProductosApi(_apiClient);
    stocks = StocksApi(_apiClient);
  }
  
  /// Inicializa el servicio de autenticación
  Future<void> initAuthService() async {
    final prefs = await SharedPreferences.getInstance();
    authService = AuthService(_apiClient, prefs);
    
    // Cargar tokens almacenados
    await authService.loadTokens();
  }
} 