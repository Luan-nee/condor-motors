import 'package:condorsmotors/api/auth.api.dart';
import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/index.protected.dart';
import 'package:condorsmotors/services/token_service.dart';

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
  late final TokenService tokenService;
  
  /// Inicializa todas las APIs con la URL base
  CondorMotorsApi({required String baseUrl, required this.tokenService}) {
    // Crear el cliente API con el servicio de tokens
    _apiClient = ApiClient(
      baseUrl: baseUrl,
      tokenService: tokenService,
    );
    
    // Inicializar todas las APIs
    auth = AuthApi(_apiClient);
    empleados = EmpleadosApi(_apiClient);
    sucursales = SucursalesApi(_apiClient);
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
    
    // Inicializar el AuthService con las nuevas dependencias
    authService = AuthService(tokenService);
  }
  
  /// Inicializa el servicio de autenticación y de tokens
  Future<void> initAuthService() async {
    // No es necesario inicializar TokenService, ya que se pasa como parámetro
    // Mantenemos este método para compatibilidad con el código existente
  }
} 