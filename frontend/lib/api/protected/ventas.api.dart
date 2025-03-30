import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/cache/fast_cache.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/ventas.model.dart';
import 'package:condorsmotors/utils/logger.dart';

class VentasApi {
  final ApiClient _api;
  final String _endpoint = '/ventas';
  final FastCache _cache = FastCache(maxSize: 75);
  
  // Prefijos para las claves de caché
  static const String _prefixListaVentas = 'ventas_lista_';
  static const String _prefixVenta = 'venta_detalle_';
  static const String _prefixEstadisticas = 'ventas_estadisticas_';
  
  VentasApi(this._api);
  
  /// Invalida el caché para una sucursal específica o para todas las sucursales
  /// 
  /// [sucursalId] - ID de la sucursal (opcional, si no se especifica invalida para todas las sucursales)
  void invalidateCache([sucursalId]) {
    if (sucursalId != null) {
      // Convertir a String en caso de recibir un entero
      final String sucursalIdStr = sucursalId.toString();
      
      // Invalidar sólo las ventas de esta sucursal
      _cache..invalidateByPattern('$_prefixListaVentas$sucursalIdStr')
      ..invalidateByPattern('$_prefixVenta$sucursalIdStr')
      ..invalidateByPattern('$_prefixEstadisticas$sucursalIdStr');
      logCache('Caché de ventas invalidado para sucursal $sucursalIdStr');
    } else {
      // Invalidar todas las ventas en caché
      _cache..invalidateByPattern(_prefixListaVentas)
      ..invalidateByPattern(_prefixVenta)
      ..invalidateByPattern(_prefixEstadisticas);
      logCache('Caché de ventas invalidado completamente');
    }
    logCache('Entradas en caché después de invalidación: ${_cache.size}');
  }
  
  /// Listar ventas con paginación y filtros
  /// 
  /// Retorna un mapa con las ventas y la paginación
  Future<Map<String, dynamic>> getVentas({
    int page = 1,
    int pageSize = 10,
    String? search,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    sucursalId,
    String? estado,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Asegurar que sucursalId sea siempre String para uniformidad
      final String sucursalKey = sucursalId != null ? sucursalId.toString() : 'global';
      final String fechaInicioStr = fechaInicio?.toIso8601String() ?? '';
      final String fechaFinStr = fechaFin?.toIso8601String() ?? '';
      final String searchStr = search ?? '';
      final String estadoStr = estado ?? '';
      
      final String cacheKey = '$_prefixListaVentas${sucursalKey}_p${page}_s${pageSize}_q${searchStr}_f${fechaInicioStr}_t${fechaFinStr}_e$estadoStr';
      
      // Si se requiere forzar la recarga, invalidar la caché primero
      if (forceRefresh) {
        Logger.debug('Forzando recarga de ventas para sucursal $sucursalId');
        if (sucursalId != null) {
          _cache.invalidate(cacheKey);
        } else {
          invalidateCache();
        }
      }
      
      // Intentar obtener desde caché si corresponde
      if (useCache && !forceRefresh) {
        try {
          final Map<String, dynamic>? cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
          if (cachedData != null && !_cache.isStale(cacheKey)) {
            logCache('Usando ventas en caché para sucursal $sucursalId (clave: $cacheKey)');
            return cachedData;
          }
        } catch (e) {
          // Si hay error al leer caché (por ejemplo, inconsistencia de tipos), 
          // invalidar la caché y continuar con la llamada a API
          Logger.error('Error al leer ventas de caché: $e');
          _cache.invalidate(cacheKey);
        }
      }
      
      final Map<String, String> queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      if (fechaInicio != null) {
        queryParams['fecha_inicio'] = fechaInicio.toIso8601String();
      }
      
      if (fechaFin != null) {
        queryParams['fecha_fin'] = fechaFin.toIso8601String();
      }
      
      if (estado != null && estado.isNotEmpty) {
        queryParams['estado'] = estado;
      }
      
      // Construir el endpoint de forma adecuada cuando se especifica la sucursal
      String endpoint = _endpoint;
      if (sucursalId != null && sucursalId.isNotEmpty) {
        // Ruta con sucursal: /api/{sucursalId}/ventas
        endpoint = '/$sucursalId/ventas';
        Logger.debug('Solicitando ventas para sucursal específica: $endpoint');
      } else {
        // Ruta general: /api/ventas (sin sucursal específica)
        Logger.debug('Solicitando ventas globales: $endpoint');
      }
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: endpoint,
        method: 'GET',
        queryParams: queryParams,
      );
      
      // Guardar en caché
      if (useCache) {
        _cache.set(cacheKey, response);
        logCache('Guardadas ventas en caché (clave: $cacheKey)');
      }
      
      Logger.debug('Respuesta de getVentas recibida: ${response.keys.toString()}');
      
      // Procesar la respuesta para añadir objetos Venta
      if (response.containsKey('data') && response['data'] is List) {
        final List<dynamic> ventasData = response['data'] as List;
        final List<Venta> ventas = ventasData.map((ventaData) {
          try {
            return Venta.fromJson(ventaData);
          } catch (e) {
            Logger.error('Error al parsear venta: $e');
            // Retornar un objeto venta vacío en caso de error
            return Venta(
              id: 0,
              tipoDocumentoId: 0,
              serieDocumento: '',
              numeroDocumento: '',
              monedaId: 0,
              metodoPagoId: 0,
              clienteId: 0,
              empleadoId: 0,
              sucursalId: 0,
              fechaEmision: DateTime.now(),
              horaEmision: '00:00:00',
              fechaCreacion: DateTime.now(),
              fechaActualizacion: DateTime.now(),
              detalles: [],
            );
          }
        }).toList();
        
        // Procesar paginación si existe
        Paginacion? paginacion;
        if (response.containsKey('pagination') && response['pagination'] is Map) {
          paginacion = Paginacion.fromJson(response['pagination']);
        }
        
        // Devolver datos procesados
        return {
          'data': ventas,
          'ventasRaw': response['data'], // Mantener datos originales
          'pagination': paginacion,
          'status': response['status'] ?? 'error',
          'message': response['message'] ?? '',
        };
      }
      
      return response;
    } catch (e) {
      Logger.error('Error al obtener ventas: $e');
      rethrow;
    }
  }
  
  /// Obtener una venta específica
  /// 
  /// [id] - ID de la venta
  /// [sucursalId] - ID de la sucursal
  /// [useCache] - Usar caché
  /// [forceRefresh] - Forzar recarga
  /// 
  /// Retorna un objeto Venta
  Future<Venta?> getVenta(
    String id, {
    sucursalId,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Asegurar que sucursalId sea siempre String para uniformidad
      final String sucursalKey = sucursalId != null ? sucursalId.toString() : 'global';
      final String cacheKey = '$_prefixVenta${sucursalKey}_$id';
      
      // Si se requiere forzar la recarga, invalidar la caché primero
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }
      
      // Intentar obtener desde caché si corresponde
      if (useCache && !forceRefresh) {
        try {
          final Map<String, dynamic>? cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
          if (cachedData != null && !_cache.isStale(cacheKey)) {
            logCache('Usando venta en caché: $cacheKey');
            try {
              return Venta.fromJson(cachedData);
            } catch (e) {
              Logger.error('Error al parsear venta desde caché: $e');
              // Si hay error al parsear, invalidar y continuar
              _cache.invalidate(cacheKey);
            }
          }
        } catch (e) {
          Logger.error('Error al acceder a caché de venta: $e');
          _cache.invalidate(cacheKey);
        }
      }
      
      // Construir el endpoint según si hay sucursal o no
      String endpoint = _endpoint;
      if (sucursalId != null) {
        final String sucursalIdStr = sucursalId.toString();
        if (sucursalIdStr.isNotEmpty) {
          endpoint = '/$sucursalIdStr/ventas';
        }
      }
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '$endpoint/$id',
        method: 'GET',
      );
      
      Map<String, dynamic> ventaData;
      if (response.containsKey('data') && response['data'] != null) {
        ventaData = response['data'];
      } else {
        ventaData = response;
      }
      
      try {
        final Venta venta = Venta.fromJson(ventaData);
        
        // Guardar en caché
        if (useCache) {
          _cache.set(cacheKey, ventaData);
          logCache('Guardada venta en caché: $cacheKey');
        }
        
        return venta;
      } catch (e) {
        Logger.error('Error al parsear datos de venta: $e');
        return null;
      }
    } catch (e) {
      Logger.error('Error al obtener venta: $e');
      rethrow;
    }
  }
  
  /// Crear una nueva venta
  /// 
  /// [ventaData] - Datos de la venta
  /// [sucursalId] - ID de la sucursal
  /// 
  /// Retorna los datos de la venta creada
  Future<Map<String, dynamic>> createVenta(Map<String, dynamic> ventaData, {sucursalId}) async {
    try {
      Logger.debug('Creando venta con datos: $ventaData');
      
      // Construir el endpoint según si hay sucursal o no
      String endpoint = _endpoint;
      if (sucursalId != null) {
        final String sucursalIdStr = sucursalId.toString();
        if (sucursalIdStr.isNotEmpty) {
          endpoint = '/$sucursalIdStr/ventas';
        }
      }
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: endpoint,
        method: 'POST',
        body: ventaData,
      );
      
      // Invalidar caché al crear una nueva venta
      if (sucursalId != null) {
        invalidateCache(sucursalId.toString());
      } else {
        invalidateCache();
      }
      
      Logger.debug('Venta creada correctamente: ${response['data'] ?? response}');
      
      Map<String, dynamic> resultData;
      if (response.containsKey('data') && response['data'] != null) {
        resultData = response['data'];
      } else {
        resultData = response;
      }
      
      return {
        'data': resultData,
        'status': response['status'] ?? 'success',
        'message': response['message'] ?? 'Venta creada correctamente',
      };
    } catch (e) {
      Logger.error('Error al crear venta: $e');
      rethrow;
    }
  }
  
  /// Actualizar una venta existente
  /// 
  /// [id] - ID de la venta
  /// [ventaData] - Datos a actualizar
  /// [sucursalId] - ID de la sucursal
  Future<Map<String, dynamic>> updateVenta(String id, Map<String, dynamic> ventaData, {sucursalId}) async {
    try {
      // Construir el endpoint según si hay sucursal o no
      String endpoint = _endpoint;
      if (sucursalId != null) {
        final String sucursalIdStr = sucursalId.toString();
        if (sucursalIdStr.isNotEmpty) {
          endpoint = '/$sucursalIdStr/ventas';
        }
      }
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '$endpoint/$id',
        method: 'PATCH',
        body: ventaData,
      );
      
      // Invalidar caché de esta venta específica
      final String sucursalKey = sucursalId != null ? sucursalId.toString() : 'global';
      final String cacheKey = '$_prefixVenta${sucursalKey}_$id';
      _cache.invalidate(cacheKey);
      
      // También invalidar listas que podrían contener esta venta
      if (sucursalId != null) {
        invalidateCache(sucursalId.toString());
      } else {
        invalidateCache();
      }
      
      return {
        'data': response['data'] ?? response,
        'status': response['status'] ?? 'success',
        'message': response['message'] ?? 'Venta actualizada correctamente',
      };
    } catch (e) {
      Logger.error('Error al actualizar venta: $e');
      rethrow;
    }
  }
  
  /// Cancelar una venta
  /// 
  /// [id] - ID de la venta
  /// [motivo] - Motivo de la cancelación
  /// [sucursalId] - ID de la sucursal
  Future<bool> cancelarVenta(String id, String motivo, {dynamic sucursalId}) async {
    try {
      // Construir el endpoint según si hay sucursal o no
      String endpoint = _endpoint;
      if (sucursalId != null) {
        final String sucursalIdStr = sucursalId.toString();
        if (sucursalIdStr.isNotEmpty) {
          endpoint = '/$sucursalIdStr/ventas';
        }
      }
      
      await _api.authenticatedRequest(
        endpoint: '$endpoint/$id/cancel',
        method: 'POST',
        body: <String, String>{
          'motivo': motivo
        },
      );
      
      // Invalidar caché relacionada
      if (sucursalId != null) {
        invalidateCache(sucursalId.toString());
      } else {
        invalidateCache();
      }
      
      return true;
    } catch (e) {
      Logger.error('Error al cancelar venta: $e');
      return false;
    }
  }
  
  /// Anular una venta
  /// 
  /// [id] - ID de la venta
  /// [motivo] - Motivo de la anulación
  /// [sucursalId] - ID de la sucursal
  Future<bool> anularVenta(String id, String motivo, {dynamic sucursalId}) async {
    try {
      // Construir el endpoint según si hay sucursal o no
      String endpoint = _endpoint;
      if (sucursalId != null) {
        final String sucursalIdStr = sucursalId.toString();
        if (sucursalIdStr.isNotEmpty) {
          endpoint = '/$sucursalIdStr/ventas';
        }
      }
      
      await _api.authenticatedRequest(
        endpoint: '$endpoint/$id/anular',
        method: 'POST',
        body: <String, String>{
          'motivo': motivo,
          'fecha_anulacion': DateTime.now().toIso8601String(),
        },
      );
      
      // Invalidar caché relacionada
      if (sucursalId != null) {
        invalidateCache(sucursalId.toString());
      } else {
        invalidateCache();
      }
      
      return true;
    } catch (e) {
      Logger.error('Error al anular venta: $e');
      return false;
    }
  }
  
  /// Obtener estadísticas de ventas
  /// 
  /// [fechaInicio] - Fecha de inicio
  /// [fechaFin] - Fecha de fin
  /// [sucursalId] - ID de la sucursal
  /// [useCache] - Usar caché
  /// [forceRefresh] - Forzar recarga
  Future<Map<String, dynamic>> getEstadisticas({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    dynamic sucursalId,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Generar clave de caché
      final String sucursalKey = sucursalId != null ? sucursalId.toString() : 'global';
      final String fechaInicioStr = fechaInicio?.toIso8601String() ?? '';
      final String fechaFinStr = fechaFin?.toIso8601String() ?? '';
      final String cacheKey = '$_prefixEstadisticas${sucursalKey}_f${fechaInicioStr}_t$fechaFinStr';
      
      // Si se requiere forzar la recarga, invalidar la caché primero
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }
      
      // Intentar obtener desde caché si corresponde
      if (useCache && !forceRefresh) {
        try {
          final Map<String, dynamic>? cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
          if (cachedData != null && !_cache.isStale(cacheKey)) {
            logCache('Usando estadísticas en caché: $cacheKey');
            return cachedData;
          }
        } catch (e) {
          Logger.error('Error al leer estadísticas de caché: $e');
          _cache.invalidate(cacheKey);
        }
      }
      
      final Map<String, String> queryParams = <String, String>{};
      
      if (fechaInicio != null) {
        queryParams['fecha_inicio'] = fechaInicio.toIso8601String();
      }
      
      if (fechaFin != null) {
        queryParams['fecha_fin'] = fechaFin.toIso8601String();
      }
      
      // Construir el endpoint según si hay sucursal o no
      String endpoint = '$_endpoint/estadisticas';
      if (sucursalId != null) {
        final String sucursalIdStr = sucursalId.toString();
        if (sucursalIdStr.isNotEmpty) {
          endpoint = '/$sucursalIdStr/ventas/estadisticas';
        }
      }
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: endpoint,
        method: 'GET',
        queryParams: queryParams,
      );
      
      // Guardar en caché
      if (useCache) {
        _cache.set(cacheKey, response);
        logCache('Guardadas estadísticas en caché: $cacheKey');
      }
      
      return response;
    } catch (e) {
      Logger.error('Error al obtener estadísticas: $e');
      return <String, dynamic>{
        'status': 'error',
        'message': 'Error al obtener estadísticas: $e',
      };
    }
  }
  
  /// Parsea una lista de ventas desde datos JSON
  List<Venta> parseVentas(data) {
    if (data == null) {
      return [];
    }
    
    // Determinar si los datos están en un arreglo o dentro de un objeto
    List<dynamic> ventasData;
    if (data is List) {
      ventasData = data;
    } else if (data is Map && data.containsKey('data') && data['data'] is List) {
      ventasData = data['data'] as List;
    } else {
      Logger.warn('Formato inesperado de respuesta de ventas: $data');
      return [];
    }
    
    // Convertir cada elemento a un objeto Venta
    return ventasData.map((item) {
      if (item is Map<String, dynamic>) {
        try {
          return Venta.fromJson(item);
        } catch (e) {
          Logger.error('Error al parsear venta: $e');
          // Retornar un objeto venta vacío en caso de error
          return Venta(
            id: 0,
            tipoDocumentoId: 0,
            serieDocumento: '',
            numeroDocumento: '',
            monedaId: 0,
            metodoPagoId: 0,
            clienteId: 0,
            empleadoId: 0,
            sucursalId: 0,
            fechaEmision: DateTime.now(),
            horaEmision: '00:00:00',
            fechaCreacion: DateTime.now(),
            fechaActualizacion: DateTime.now(),
            detalles: [],
          );
        }
      }
      
      throw FormatException('Formato de venta inválido: $item');
    }).toList();
  }
}