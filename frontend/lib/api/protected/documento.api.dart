import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/cache/fast_cache.dart';
import 'package:condorsmotors/utils/logger.dart';

/// Clase para tipos de documentos de facturación
class TipoDocumento {
  final int id;
  final String nombre;
  final String codigo;
  
  const TipoDocumento({
    required this.id,
    required this.nombre,
    required this.codigo,
  });
  
  factory TipoDocumento.fromJson(Map<String, dynamic> json) {
    return TipoDocumento(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String,
    );
  }
  
  @override
  String toString() => 'TipoDocumento(id: $id, nombre: $nombre, codigo: $codigo)';
}

/// Clase para tipos de impuestos (Tax)
class TipoTax {
  final int id;
  final String nombre;
  final String codigo;
  
  const TipoTax({
    required this.id,
    required this.nombre,
    required this.codigo,
  });
  
  factory TipoTax.fromJson(Map<String, dynamic> json) {
    return TipoTax(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String,
    );
  }
  
  @override
  String toString() => 'TipoTax(id: $id, nombre: $nombre, codigo: $codigo)';
}

/// API para manejar tipos de documentos
class DocumentoApi {
  final ApiClient _api;
  final FastCache _cache = FastCache(maxSize: 10);
  
  // Clave de caché para la información de documentos
  static const String _prefixInformacion = 'documentos_informacion_';
  
  // Constantes para códigos de documentos
  static const String codigoFactura = 'factura';
  static const String codigoBoleta = 'boleta';
  static const String codigoGravado = 'gravado';
  static const String codigoExonerado = 'exonerado';
  static const String codigoGratuito = 'gratuito';
  
  // Variables estáticas para almacenar IDs más usados
  static int? _boletaId;
  static int? _facturaId;
  static int? _gravadoId;
  
  /// Constructor que recibe una instancia de ApiClient
  DocumentoApi(this._api);
  
  /// Invalida el caché de documentos
  void invalidateCache() {
    _cache.invalidateByPattern(_prefixInformacion);
    logCache('Caché de tipos de documentos invalidado');
    
    // Reiniciar IDs en memoria
    _boletaId = null;
    _facturaId = null;
    _gravadoId = null;
  }
  
  /// Obtiene información de tipos de documentos y tax
  /// 
  /// [sucursalId] - ID de la sucursal
  /// [useCache] - Si se debe usar el caché (por defecto true)
  /// [forceRefresh] - Si se debe forzar una actualización desde el servidor (por defecto false)
  Future<Map<String, dynamic>> getInformacion({
    required String sucursalId,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      final String cacheKey = '$_prefixInformacion$sucursalId';
      
      // Intentar obtener del caché si corresponde
      if (useCache && !forceRefresh) {
        final Map<String, dynamic>? cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          logCache('Usando información de documentos en caché');
          return cachedData;
        }
      }
      
      // Realizar petición al endpoint de información
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/ventas/informacion',
        method: 'GET',
      );
      
      // Guardar en caché
      if (useCache) {
        _cache.set(cacheKey, response);
        logCache('Guardada información de documentos en caché');
      }
      
      // Procesar y guardar IDs importantes
      _procesarInformacion(response['data']);
      
      return response;
    } catch (e) {
      Logger.error('Error al obtener información de documentos: $e');
      rethrow;
    }
  }
  
  /// Procesa la información de la respuesta y guarda IDs importantes
  void _procesarInformacion(Map<String, dynamic> data) {
    try {
      // Procesar tipos de documentos de facturación
      if (data.containsKey('tiposDocFacturacion') && data['tiposDocFacturacion'] is List) {
        final List<dynamic> tiposDoc = data['tiposDocFacturacion'] as List;
        
        for (final tipo in tiposDoc) {
          if (tipo is Map<String, dynamic>) {
            if (tipo['codigo'] == codigoBoleta) {
              _boletaId = tipo['id'] as int;
              Logger.debug('ID de Boleta encontrado: $_boletaId');
            } else if (tipo['codigo'] == codigoFactura) {
              _facturaId = tipo['id'] as int;
              Logger.debug('ID de Factura encontrado: $_facturaId');
            }
          }
        }
      }
      
      // Procesar tipos de tax
      if (data.containsKey('tiposTax') && data['tiposTax'] is List) {
        final List<dynamic> tiposTax = data['tiposTax'] as List;
        
        for (final tipo in tiposTax) {
          if (tipo is Map<String, dynamic>) {
            if (tipo['codigo'] == codigoGravado) {
              _gravadoId = tipo['id'] as int;
              Logger.debug('ID de Tax Gravado encontrado: $_gravadoId');
            }
          }
        }
      }
    } catch (e) {
      Logger.error('Error al procesar información de documentos: $e');
    }
  }
  
  /// Obtiene el ID para el tipo de documento Boleta
  /// Si no está disponible, intenta obtenerlo del servidor
  Future<int> getBoletaId(String sucursalId) async {
    if (_boletaId != null) {
      return _boletaId!;
    }
    
    // Si no tenemos el ID en caché, obtener información fresca
    await getInformacion(
      sucursalId: sucursalId,
      useCache: false,
      forceRefresh: true,
    );
    
    // Si aún no tenemos el ID, usar valor por defecto con advertencia
    if (_boletaId == null) {
      Logger.warn('No se pudo obtener ID para Boleta, usando valor por defecto (4)');
      return 4; // Valor por defecto basado en la respuesta API
    }
    
    return _boletaId!;
  }
  
  /// Obtiene el ID para el tipo de documento Factura
  /// Si no está disponible, intenta obtenerlo del servidor
  Future<int> getFacturaId(String sucursalId) async {
    if (_facturaId != null) {
      return _facturaId!;
    }
    
    // Si no tenemos el ID en caché, obtener información fresca
    await getInformacion(
      sucursalId: sucursalId,
      useCache: false,
      forceRefresh: true,
    );
    
    // Si aún no tenemos el ID, usar valor por defecto con advertencia
    if (_facturaId == null) {
      Logger.warn('No se pudo obtener ID para Factura, usando valor por defecto (3)');
      return 3; // Valor por defecto basado en la respuesta API
    }
    
    return _facturaId!;
  }
  
  /// Obtiene el ID para el tipo Tax Gravado (IGV 18%)
  /// Si no está disponible, intenta obtenerlo del servidor
  Future<int> getGravadoTaxId(String sucursalId) async {
    if (_gravadoId != null) {
      return _gravadoId!;
    }
    
    // Si no tenemos el ID en caché, obtener información fresca
    await getInformacion(
      sucursalId: sucursalId,
      useCache: false,
      forceRefresh: true,
    );
    
    // Si aún no tenemos el ID, usar valor por defecto con advertencia
    if (_gravadoId == null) {
      Logger.warn('No se pudo obtener ID para Tax Gravado, usando valor por defecto (4)');
      return 4; // Valor por defecto basado en la respuesta API
    }
    
    return _gravadoId!;
  }
  
  /// Obtiene el ID para el tipo de documento según su nombre
  /// [tipoDocumento] - Nombre del tipo de documento ('BOLETA' o 'FACTURA')
  Future<int> getTipoDocumentoId(String sucursalId, String tipoDocumento) async {
    if (tipoDocumento.toUpperCase() == 'BOLETA') {
      return await getBoletaId(sucursalId);
    } else if (tipoDocumento.toUpperCase() == 'FACTURA') {
      return await getFacturaId(sucursalId);
    } else {
      Logger.warn('Tipo de documento desconocido: $tipoDocumento, usando Boleta por defecto');
      return await getBoletaId(sucursalId);
    }
  }
}
