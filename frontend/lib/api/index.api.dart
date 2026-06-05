import 'dart:convert';

import 'package:condorsmotors/api/auth.api.dart';
import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/categorias.api.dart';
import 'package:condorsmotors/api/protected/clientes.api.dart';
import 'package:condorsmotors/api/protected/colores.api.dart';
import 'package:condorsmotors/api/protected/documento.api.dart';
import 'package:condorsmotors/api/protected/empleados.api.dart';
import 'package:condorsmotors/api/protected/estadisticas.api.dart';
import 'package:condorsmotors/api/protected/facturacion.api.dart';
import 'package:condorsmotors/api/protected/marcas.api.dart';
import 'package:condorsmotors/api/protected/pedidos.api.dart';
import 'package:condorsmotors/api/protected/productos.api.dart';
import 'package:condorsmotors/api/protected/proforma.api.dart';
import 'package:condorsmotors/api/protected/stocks.api.dart';
import 'package:condorsmotors/api/protected/sucursales.api.dart';
import 'package:condorsmotors/api/protected/transferencias.api.dart';
import 'package:condorsmotors/api/protected/ventas.api.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:condorsmotors/utils/secure_storage_utils.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'auth.api.dart';
export 'main.api.dart';

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

/// Función para construir URL completa del servidor.
String buildServerUrl(String host, {int? port}) {
  if (host.startsWith('http://') || host.startsWith('https://')) {
    final Uri uri = Uri.parse(host);
    if (uri.hasPort && uri.path.isNotEmpty) {
      return host;
    }
    if (uri.hasPort) {
      return '${host.trimRight()}/api';
    }
    if (uri.scheme == 'https' || uri.path.isNotEmpty) {
      return host;
    }
    return '${host.trimRight()}:${port ?? 3000}/api';
  }
  return 'http://$host:${port ?? 3000}/api';
}

/// Guardar la URL del servidor en preferencias.
Future<void> _saveServerUrl(String url, {int? port}) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String fullUrl = buildServerUrl(url, port: port);
  await prefs.setString('server_url', fullUrl);
  if (port != null) {
    await prefs.setInt('server_port', port);
  }
}

/// Inicializa la instancia global de la API (Redirige a ApiInitializer).
Future<void> initializeApi() => ApiInitializer.instance.initializeApiIfNeeded();

/// Clase principal para acceder a todas las APIs.
class CondorMotorsApi {
  late final ApiClient _apiClient;
  late final AuthApi auth;
  late final SucursalesApi sucursales;
  late final EmpleadosApi empleados;
  late final MarcasApi marcas;
  late final VentasApi ventas;
  late final TransferenciasInventarioApi transferencias;
  late final ProductosApi productos;
  late final StocksApi stocks;
  late final CategoriasApi categorias;
  late final ProformaVentaApi proformas;
  late final ColoresApi colores;
  late final ClientesApi clientes;
  late final DocumentoApi documentos;
  late final EstadisticasApi estadisticas;
  late final FacturacionApi facturacion;
  late final PedidosApi pedidos;

  /// Inicializa todas las APIs con la URL base.
  CondorMotorsApi({required String baseUrl}) {
    logInfo('Inicializando CondorMotorsApi con URL base: $baseUrl');

    try {
      _apiClient = ApiClient(baseUrl: baseUrl);
      _globalApiClient = _apiClient;

      auth = const AuthApi();
      sucursales = SucursalesApi(_apiClient);
      empleados = EmpleadosApi(_apiClient);
      marcas = MarcasApi(_apiClient);
      ventas = VentasApi(_apiClient);
      transferencias = TransferenciasInventarioApi(_apiClient);
      productos = ProductosApi(_apiClient);
      stocks = StocksApi(_apiClient);
      categorias = CategoriasApi(_apiClient);
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

  /// Devuelve la baseUrl sin el sufijo /api para construir URLs absolutas de imágenes.
  String getBaseUrlSinApi() =>
      _apiClient.baseUrl.replaceFirst(RegExp('/api/?'), '');
}

// Instancia global del cliente API
late ApiClient _globalApiClient;

/// Centraliza el manejo de autenticación y tokens.
class AuthManager {
  static const String _accessTokenKey = 'access_token';
  static const String _userDataKey = 'user_data';
  static const String _sucursalKey = 'current_sucursal';
  static const String _sucursalIdKey = 'current_sucursal_id';
  static const String _usernameAutoKey = 'username_auto';
  static const String _passwordAutoKey = 'password_auto';

  /// Inicia sesión con usuario y contraseña.
  static Future<Map<String, dynamic>?> login(String username, String password,
      {bool saveAutoLogin = false}) async {
    try {
      final Map<String, dynamic> response = await _globalApiClient.request(
        endpoint: '/auth/login',
        method: 'POST',
        body: <String, String>{
          'usuario': username,
          'clave': password,
        },
      );

      if (response['status'] != 'success' || response['data'] == null) {
        return null;
      }

      final Map<String, dynamic> userData = response['data'] as Map<String, dynamic>;
      await saveUserData(userData);

      if (saveAutoLogin) {
        await saveAutoLoginCredentials(username, password);
      }

      return userData;
    } catch (e) {
      logError('Error durante login: $e');
      return null;
    }
  }

  /// Cierra la sesión del usuario.
  static Future<void> logout() async {
    try {
      await _globalApiClient.request(
        endpoint: '/auth/logout',
        method: 'POST',
        requiresAuth: true,
        queryParams: const {'x-no-retry-on-401': 'true'},
      );
    } catch (e) {
      logWarning('Error al hacer logout en servidor: $e');
    }
    await clearTokens();
  }

  /// Verifica si el token actual es válido.
  static Future<bool> verificarToken() async {
    try {
      final Map<String, dynamic> response = await _globalApiClient.request(
        endpoint: '/auth/testsession',
        method: 'POST',
        requiresAuth: true,
      );

      if (response['status'] != 'success' || response['data'] == null) {
        await clearTokens();
        return false;
      }

      final Map<String, dynamic> userData = response['data'] as Map<String, dynamic>;
      await saveUserData(userData);
      return true;
    } catch (e) {
      logError('Error verificando token: $e');
      await clearTokens();
      return false;
    }
  }

  /// Obtiene los datos del usuario almacenados.
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final String? userData = await SecureStorageUtils.read(_userDataKey);
      if (userData == null) {
        return null;
      }
      return json.decode(userData) as Map<String, dynamic>;
    } catch (e) {
      logError('Error obteniendo datos del usuario: $e');
      return null;
    }
  }

  /// Guarda los datos del usuario.
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      await SecureStorageUtils.write(_userDataKey, json.encode(userData));

      if (userData['id'] != null) {
        await SecureStorageUtils.write('user_id', userData['id'].toString());
      }
      if (userData['usuario'] != null) {
        await SecureStorageUtils.write('username', userData['usuario'].toString());
      }
      if (userData['rolCuentaEmpleadoCodigo'] != null) {
        await SecureStorageUtils.write('user_role',
            userData['rolCuentaEmpleadoCodigo'].toString().toLowerCase());
      }
      if (userData['sucursal'] != null) {
        await SecureStorageUtils.write(_sucursalKey, userData['sucursal'].toString());
      }
      if (userData['sucursalId'] != null) {
        await SecureStorageUtils.write(_sucursalIdKey, userData['sucursalId'].toString());
      }
    } catch (e) {
      logError('Error al guardar datos del usuario: $e');
      rethrow;
    }
  }

  /// Guarda credenciales para auto-login.
  static Future<void> saveAutoLoginCredentials(
          String username, String password) =>
      Future.wait([
        SecureStorageUtils.write(_usernameAutoKey, username),
        SecureStorageUtils.write(_passwordAutoKey, password),
      ]);

  /// Limpia todos los tokens y datos de usuario.
  static Future<void> clearTokens() async {
    try {
      await SecureStorageUtils.deleteAll();
      logInfo('AuthManager: Todos los tokens y datos limpiados');
    } catch (e) {
      logError('Error al limpiar tokens: $e');
    }
  }

  /// Verifica si hay un token válido almacenado.
  static Future<bool> isAuthenticated() async {
    try {
      final String? token = await SecureStorageUtils.read(_accessTokenKey);
      if (token == null || token.isEmpty) {
        return false;
      }
      return await verificarToken();
    } catch (e) {
      logError('Error verificando autenticación: $e');
      return false;
    }
  }

  /// Obtiene el ID de la sucursal actual.
  static Future<String?> getCurrentSucursalId() =>
      SecureStorageUtils.read(_sucursalIdKey);
}

/// Centraliza el manejo del refresh token y su ciclo de vida.
class RefreshTokenManager {
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessTokenKey = 'access_token';
  static bool _isRefreshing = false;

  // Cache en memoria para el access token
  static String? _accessTokenInMemory;

  /// Lee el refresh token desde almacenamiento seguro.
  static Future<String?> getRefreshToken() =>
      SecureStorageUtils.read(_refreshTokenKey);

  /// Guarda o actualiza el refresh token en almacenamiento seguro.
  static Future<void> setRefreshToken(String token) =>
      SecureStorageUtils.write(_refreshTokenKey, token);

  /// Elimina el refresh token del almacenamiento seguro.
  static Future<void> clearRefreshToken() async {
    await SecureStorageUtils.delete(_refreshTokenKey);
    clearAccessTokenCache();
  }

  /// Elimina el access token del almacenamiento seguro.
  static Future<void> clearAccessToken() async {
    await SecureStorageUtils.delete(_accessTokenKey);
    clearAccessTokenCache();
  }

  /// Lee el access token, priorizando el valor en memoria si existe.
  static Future<String?> getAccessToken({String? baseUrl}) async {
    if (_accessTokenInMemory != null) {
      return _accessTokenInMemory;
    }
    final token = await SecureStorageUtils.read(_accessTokenKey);
    _accessTokenInMemory = token;
    return token;
  }

  /// Guarda o actualiza el access token en almacenamiento seguro y en memoria.
  static Future<void> setAccessToken({required String token}) async {
    _accessTokenInMemory = token;
    await SecureStorageUtils.write(_accessTokenKey, token);
  }

  /// Refresca el access token usando el refresh token actual.
  static Future<bool> refreshToken({required String baseUrl}) async {
    if (baseUrl.isEmpty) {
      logError('RefreshTokenManager: baseUrl no puede estar vacío.');
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
            logInfo('RefreshTokenManager: Nuevo access token guardado.');
            _isRefreshing = false;
            return true;
          }
        }
        logError('RefreshTokenManager: No se pudo extraer el nuevo access token.');
        _isRefreshing = false;
        return false;
      } else {
        logError('RefreshTokenManager: Error refresh token. Status: ${response.statusCode}');
        _isRefreshing = false;
        return false;
      }
    } catch (e) {
      logError('RefreshTokenManager: Excepción durante el refresh', e);
      _isRefreshing = false;
      return false;
    }
  }

  /// Limpia la cache en memoria del access token.
  static void clearAccessTokenCache() {
    _accessTokenInMemory = null;
  }
}

/// Singleton para inicialización única de la API.
class ApiInitializer {
  static final ApiInitializer instance = ApiInitializer._internal();
  bool _isInitialized = false;

  ApiInitializer._internal();

  bool get isInitialized => _isInitialized;

  /// Inicializa la API global con el baseUrl guardado o uno por defecto.
  Future<void> initializeApi() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? baseUrl = prefs.getString('server_url');
    if (baseUrl == null || baseUrl.isEmpty) {
      baseUrl = 'http://localhost:3000/api';
      await prefs.setString('server_url', baseUrl);
    }
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

/// Devuelve la baseUrl actual de la API global.
String getCurrentBaseUrl() => api._apiClient.baseUrl;

/// Actualiza la baseUrl, guarda la preferencia y reinicializa la API global.
Future<void> updateBaseUrl(String url, {int? port}) async {
  final String fullUrl = buildServerUrl(url, port: port);
  await _saveServerUrl(fullUrl, port: port);
  ApiInitializer.instance.reset();
  await ApiInitializer.instance.initializeApiIfNeeded();
}

/// Devuelve la última URL guardada.
Future<String?> getSavedServerUrl() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('server_url');
}
