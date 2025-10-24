import 'dart:io';

import 'package:condorsmotors/api/auth.api.dart';
import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/index.protected.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:condorsmotors/utils/secure_storage_utils.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'auth.api.dart';
export 'main.api.dart';
export 'protected/index.protected.dart';

// Instancia global de la API
late CondorMotorsApi api;

// Lista de servidores predefinidos para selección en la UI
final List<Map<String, dynamic>> serverConfigs = [
  {'url': 'http://192.168.1.42', 'port': 3000},
  {'url': 'http://localhost', 'port': 3000},
  {'url': 'http://127.0.0.1', 'port': 3000},
  {'url': 'http://10.0.2.2', 'port': 3000},
  {'url': 'https://fseh2hb1d1h2ra5822cdvo.top/api', 'port': null},
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
    serverConfigs.insert(0, lastConfig);
  }

  // Verificar conectividad con los servidores en orden
  String? workingUrl;
  for (final Map<String, dynamic> config in serverConfigs) {
    if (await _checkServerConnectivity(config['url'] as String)) {
      workingUrl = config['url'] as String;
      break;
    }
  }

  // Si no se encuentra ningún servidor disponible, usar el primero de la lista
  final Map<String, dynamic> baseConfig =
      workingUrl != null ? serverConfigs.first : serverConfigs.first;
  final String baseUrl = buildServerUrl(baseConfig['url'] as String,
      port: baseConfig['port'] as int?);
  logInfo('URL base de la API: $baseUrl');

  // Guardar la URL seleccionada para futuras sesiones
  if (workingUrl != null) {
    await _saveServerUrl(workingUrl, port: baseConfig['port'] as int?);
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

  /// Devuelve la baseUrl sin el sufijo /api para construir URLs absolutas de imágenes
  String getBaseUrlSinApi() {
    return _apiClient.baseUrl.replaceFirst(RegExp('/api/?'), '');
  }
}

/// Centraliza el manejo del refresh token y su ciclo de vida
class RefreshTokenManager {
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessTokenKey = 'access_token';
  static bool _isRefreshing = false;

  // Cache en memoria para el access token
  static String? _accessTokenInMemory;

  /// Lee el refresh token desde almacenamiento seguro
  static Future<String?> getRefreshToken() {
    return SecureStorageUtils.read(_refreshTokenKey);
  }

  /// Guarda o actualiza el refresh token en almacenamiento seguro
  static Future<void> setRefreshToken(String token) async {
    await SecureStorageUtils.write(_refreshTokenKey, token);
  }

  /// Elimina el refresh token del almacenamiento seguro
  static Future<void> clearRefreshToken() async {
    await SecureStorageUtils.delete(_refreshTokenKey);
    clearAccessTokenCache();
  }

  /// Lee el access token, priorizando el valor en memoria si existe
  static Future<String?> getAccessToken({String? baseUrl}) async {
    if (_accessTokenInMemory != null) {
      return _accessTokenInMemory;
    }
    final token = await SecureStorageUtils.read(_accessTokenKey);
    _accessTokenInMemory = token;
    return token;
  }

  /// Guarda o actualiza el access token en almacenamiento seguro y en memoria
  static Future<void> setAccessToken({required String token}) async {
    _accessTokenInMemory = token;
    await SecureStorageUtils.write(_accessTokenKey, token);
  }

  /// Refresca el access token usando el refresh token actual
  /// Devuelve true si el refresh fue exitoso, false si falló
  static Future<bool> refreshToken({required String baseUrl}) async {
    if (baseUrl.isEmpty) {
      logError(
          'RefreshTokenManager: baseUrl no puede estar vacío al refrescar el token.');
      return false;
    }
    if (_isRefreshing) {
      logInfo('RefreshTokenManager: Ya hay un refresh en curso.');
      return false;
    }
    _isRefreshing = true;
    try {
      final refreshTokenValue = await getRefreshToken();
      if (refreshTokenValue == null || refreshTokenValue.isEmpty) {
        logError('RefreshTokenManager: No hay refresh token disponible.');
        _isRefreshing = false;
        return false;
      }
      final Dio dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ));
      final response = await dio.post(
        '/auth/refresh',
        options: Options(
          headers: {
            'Cookie': '$_refreshTokenKey=$refreshTokenValue',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final authHeader = response.headers.value('authorization');
        if (authHeader != null && authHeader.startsWith('Bearer ')) {
          final newAccessToken = authHeader.substring(7);
          if (newAccessToken.isNotEmpty) {
            await setAccessToken(token: newAccessToken);
            logInfo(
                'RefreshTokenManager: Nuevo access token guardado (memoria y storage).');
            _isRefreshing = false;
            return true;
          }
        }
        logError(
            'RefreshTokenManager: No se pudo extraer el nuevo access token.');
        _isRefreshing = false;
        return false;
      } else {
        logError(
            'RefreshTokenManager: Error al refrescar token. Status: \\${response.statusCode}');
        _isRefreshing = false;
        return false;
      }
    } catch (e) {
      logError('RefreshTokenManager: Excepción durante el refresh', e);
      _isRefreshing = false;
      return false;
    }
  }

  /// Limpia la cache en memoria del access token
  static void clearAccessTokenCache() {
    _accessTokenInMemory = null;
  }
}

// Singleton para inicialización única de la API
class ApiInitializer {
  static final ApiInitializer instance = ApiInitializer._internal();
  bool _isInitialized = false;

  ApiInitializer._internal();

  bool get isInitialized => _isInitialized;

  /// Inicializa la API global con el baseUrl guardado o uno por defecto
  Future<void> initializeApi() async {
    // Recuperar la última URL guardada o usar valor por defecto
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? baseUrl = prefs.getString('server_url');
    if (baseUrl == null || baseUrl.isEmpty) {
      baseUrl = 'http://localhost:3000/api';
      await prefs.setString('server_url', baseUrl);
    }
    // Inicializar la instancia global de la API
    api = CondorMotorsApi(baseUrl: baseUrl);
    _isInitialized = true;
    logInfo('[ApiInitializer] API inicializada con baseUrl: $baseUrl');
  }

  Future<void> initializeApiIfNeeded() async {
    if (!_isInitialized) {
      await initializeApi();
    }
  }

  void reset() {
    _isInitialized = false;
  }
}

/// Devuelve la baseUrl actual de la API global
String getCurrentBaseUrl() => api._apiClient.baseUrl;

/// Actualiza la baseUrl, guarda la preferencia y reinicializa la API global
Future<void> updateBaseUrl(String url, {int? port}) async {
  final String fullUrl = buildServerUrl(url, port: port);
  await _saveServerUrl(fullUrl, port: port);
  ApiInitializer.instance.reset();
  await ApiInitializer.instance.initializeApiIfNeeded();
}

/// Devuelve la última URL guardada (o null si no hay)
Future<String?> getSavedServerUrl() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('server_url');
}
