import 'dart:convert';
import 'dart:io';

import 'package:condorsmotors/api/auth.api.dart';
import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/index.protected.dart';
import 'package:flutter/foundation.dart';
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
    debugPrint('Comprobando conectividad con: $url');
    final Uri uri = Uri.parse(url);
    final Socket socket = await Socket.connect(
        uri.host, uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 3000),
        timeout: const Duration(seconds: 3));
    socket.destroy();
    debugPrint('Conexión exitosa con: $url');
    return true;
  } catch (e) {
    debugPrint('No se pudo conectar a: $url - Error: $e');
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
  debugPrint('Inicializando API...');

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
  debugPrint('URL base de la API: $baseUrl');

  // Guardar la URL seleccionada para futuras sesiones
  if (workingUrl != null) {
    await _saveServerUrl(workingUrl, port: lastConfig['port']);
  }

  // Inicializar la API global
  api = CondorMotorsApi(baseUrl: baseUrl);
  debugPrint('API inicializada correctamente');
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
  // Clave para almacenar datos de usuario
  static const String _userDataKey = 'user_data';

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

      debugPrint('APIs inicializadas correctamente');
    } catch (e) {
      debugPrint('Error al inicializar APIs: $e');
      rethrow;
    }
  }

  /// Obtiene los datos del usuario almacenados localmente
  ///
  /// Este método permite acceder a los datos del usuario autenticado desde cualquier parte
  /// de la aplicación de manera centralizada.
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString(_userDataKey);
      if (userData == null || userData.isEmpty) {
        return null;
      }
      return json.decode(userData) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error en CondorMotorsApi.getUserData: $e');
      return null;
    }
  }

  /// Guarda los datos del usuario localmente
  ///
  /// Método de utilidad para almacenar datos del usuario desde cualquier componente
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, json.encode(userData));
      debugPrint('CondorMotorsApi: Datos del usuario guardados correctamente');
    } catch (e) {
      debugPrint('Error en CondorMotorsApi.saveUserData: $e');
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
