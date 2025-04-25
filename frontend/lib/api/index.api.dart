import 'dart:io';

import 'package:condorsmotors/api/auth.api.dart';
import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/index.protected.dart';
import 'package:condorsmotors/models/auth.model.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'auth.api.dart';
export 'main.api.dart';
export 'protected/index.protected.dart';

// Instancia global de la API
late CondorMotorsApi api;

// Lista de servidores posibles para intentar conectarse
final List<String> _serverUrls = <String>[
  'http://192.168.1.66:3000/api', // IP de tu PC en la red WiFi local
];

/// Función para construir URL completa del servidor
String buildServerUrl(String host, {int? port}) {
  if (host.startsWith('http://') || host.startsWith('https://')) {
    final Uri uri = Uri.parse(host);
    // Si ya tiene puerto y path, retornar como está
    if (uri.hasPort && uri.path.isNotEmpty) {
      return host;
    }
    // Si ya tiene puerto pero no path
    if (uri.hasPort) {
      return '${host.trimRight()}/api';
    }
    // Si no tiene puerto pero es HTTPS o tiene path
    if (uri.scheme == 'https' || uri.path.isNotEmpty) {
      return host;
    }
    // Si es HTTP y no tiene puerto ni path
    return '${host.trimRight()}:${port ?? 3000}/api';
  }
  // Si es solo un host sin protocolo
  return 'http://$host:${port ?? 3000}/api';
}

/// Comprobar conectividad con un servidor
Future<bool> _checkServerConnectivity(String url) async {
  try {
    logInfo('Comprobando conectividad con: $url');
    final Uri uri = Uri.parse(url);
    final Socket socket = await Socket.connect(
        uri.host, uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 3000),
        timeout: const Duration(seconds: 3));
    socket.destroy();
    logInfo('Conexión exitosa con: $url');
    return true;
  } catch (e) {
    logError('No se pudo conectar a: $url', e);
    return false;
  }
}

/// Guardar la URL del servidor en preferencias
Future<void> _saveServerUrl(String url, {int? port}) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String fullUrl = buildServerUrl(url, port: port);
  await prefs.setString('server_url', fullUrl);
  if (port != null) {
    await prefs.setInt('server_port', port);
  }
}

/// Obtener la última URL y puerto del servidor usados
Future<Map<String, dynamic>> _getLastServerConfig() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? url = prefs.getString('server_url');
  final int? port = prefs.getInt('server_port');
  return {
    'url': url,
    'port': port,
  };
}

/// Inicializa la instancia global de la API
Future<void> initializeApi() async {
  logInfo('Inicializando API...');

  // Obtener la última configuración usada
  final Map<String, dynamic> lastConfig = await _getLastServerConfig();
  if (lastConfig['url'] != null) {
    _serverUrls.insert(0, lastConfig['url'] as String);
  }

  // Verificar conectividad con los servidores en orden
  String? workingUrl;
  for (final String url in _serverUrls) {
    if (await _checkServerConnectivity(url)) {
      workingUrl = url;
      break;
    }
  }

  // Si no se encuentra ningún servidor disponible, usar el primero de la lista
  final String baseUrl = workingUrl ?? _serverUrls.first;
  logInfo('URL base de la API: $baseUrl');

  // Guardar la URL seleccionada para futuras sesiones
  if (workingUrl != null) {
    await _saveServerUrl(workingUrl, port: lastConfig['port']);
  }

  // Inicializar la API global
  api = CondorMotorsApi(baseUrl: baseUrl);
  logInfo('API inicializada correctamente');
}

/// Clase principal para acceder a todas las APIs
class CondorMotorsApi {
  late final ApiClient _apiClient;
  late final AuthApi auth;
  late final AuthService authService;
  late final SucursalesApi sucursales;
  late final EmpleadosApi empleados;
  late final MarcasApi marcas;
  late final VentasApi ventas;
  late final TransferenciasInventarioApi transferencias;
  late final ProductosApi productos;
  late final StocksApi stocks;
  late final CategoriasApi categorias;
  late final CuentasEmpleadosApi cuentasEmpleados;
  late final ProformaVentaApi proformas;
  late final ColoresApi colores;
  late final ClientesApi clientes;
  late final DocumentoApi documentos;
  late final EstadisticasApi estadisticas;
  late final FacturacionApi facturacion;
  late final PedidosApi pedidos;

  /// Inicializa todas las APIs con la URL base
  CondorMotorsApi({required String baseUrl}) {
    logInfo('Inicializando CondorMotorsApi con URL base: $baseUrl');

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
      transferencias = TransferenciasInventarioApi(_apiClient);
      productos = ProductosApi(_apiClient);
      stocks = StocksApi(_apiClient);
      categorias = CategoriasApi(_apiClient);
      cuentasEmpleados = CuentasEmpleadosApi(_apiClient);
      proformas = ProformaVentaApi(_apiClient);
      colores = ColoresApi(_apiClient);
      clientes = ClientesApi(_apiClient);
      documentos = DocumentoApi(_apiClient);
      estadisticas = EstadisticasApi(_apiClient);
      facturacion = FacturacionApi(_apiClient);
      pedidos = PedidosApi(_apiClient);
      logInfo('APIs inicializadas correctamente');
    } catch (e) {
      logError('Error al inicializar APIs', e);
      rethrow;
    }
  }

  /// Obtiene los datos del usuario almacenados localmente
  ///
  /// Este método delega al método getUserData de AuthApi para evitar duplicidad
  Future<Map<String, dynamic>?> getUserData() async {
    return auth.getUserData();
  }

  /// Guarda los datos del usuario localmente
  ///
  /// Delega a saveUserData de AuthApi para evitar duplicidad
  Future<void> saveUserData(userData) async {
    try {
      if (userData is AuthUser) {
        await authService.saveUserData(userData);
      } else if (userData is Map<String, dynamic>) {
        await auth.saveUserData(userData);
      } else {
        throw ArgumentError('Tipo de datos no soportado para saveUserData');
      }
    } catch (e) {
      logError('Error en CondorMotorsApi.saveUserData', e);
      rethrow;
    }
  }

  /// Verifica la conectividad con el servidor
  Future<bool> checkConnectivity() async {
    try {
      await auth.verificarToken();
      logInfo('Conectividad verificada correctamente');
      return true;
    } catch (e) {
      logError('Error al verificar conectividad', e);
      return false;
    }
  }

  /// Verifica si hay una sesión activa
  Future<bool> hasActiveSession() async {
    try {
      final bool isAuthenticated = await auth.isAuthenticated();
      logInfo('Estado de sesión: ${isAuthenticated ? 'activa' : 'inactiva'}');
      return isAuthenticated;
    } catch (e) {
      logError('Error al verificar sesión', e);
      return false;
    }
  }

  /// Cierra la sesión y limpia todos los datos
  Future<void> logout() async {
    try {
      await auth.logout();
      logInfo('Sesión cerrada correctamente');
    } catch (e) {
      logError('Error al cerrar sesión', e);
      rethrow;
    }
  }

  /// Devuelve la baseUrl sin el sufijo /api para construir URLs absolutas de imágenes
  String getBaseUrlSinApi() {
    return _apiClient.baseUrl.replaceFirst(RegExp(r'/api/?'), '');
  }
}
