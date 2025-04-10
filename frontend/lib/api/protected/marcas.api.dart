import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/cache/fast_cache.dart';
import 'package:condorsmotors/models/marca.model.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/utils/logger.dart';

/// Clase para gestionar las operaciones de API relacionadas con Marcas
class MarcasApi {
  final ApiClient _api;
  // Fast Cache para las operaciones de marcas
  final FastCache _cache = FastCache(maxSize: 50);

  // Prefijos para las claves de caché
  static const String _prefixListaMarcas = 'marcas_lista_';
  static const String _prefixMarca = 'marca_detalle_';

  MarcasApi(this._api);

  /// Obtiene todas las marcas con paginación opcional
  ///
  /// [page] Número de página (1-based, default: 1)
  /// [pageSize] Tamaño de página (default: 10)
  /// [useCache] Indica si se debe usar el caché (default: true)
  /// [forceRefresh] Fuerza a obtener datos frescos del servidor (default: false)
  Future<ResultadoPaginado<Marca>> getMarcasPaginadas({
    int page = 1,
    int pageSize = 10,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Validar parámetros
      if (page < 1) {
        page = 1;
      }
      if (pageSize < 1) {
        pageSize = 10;
      }

      // Generar clave única para este conjunto de parámetros
      final String cacheKey = '$_prefixListaMarcas${page}_$pageSize';

      // Forzar refresco del caché si es necesario
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }

      // Intentar obtener desde caché si useCache es true
      if (useCache && !forceRefresh) {
        final ResultadoPaginado<Marca>? cachedData =
            _cache.get<ResultadoPaginado<Marca>>(cacheKey);
        if (cachedData != null) {
          logCache(
              '[MarcasApi] Marcas paginadas obtenidas desde caché: $cacheKey');
          return cachedData;
        }
      }

      Logger.debug(
          '[MarcasApi] Obteniendo lista de marcas paginada (página: $page, tamaño: $pageSize)');
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/marcas',
        method: 'GET',
        queryParams: <String, String>{
          'page': page.toString(),
          'pageSize': pageSize.toString(),
        },
      );

      Logger.debug('[MarcasApi] Respuesta de getMarcasPaginadas recibida');

      // Extraer datos de la respuesta
      final data = response['data'];
      if (data == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Respuesta inesperada del servidor: falta campo "data"',
        );
      }

      // Extraer lista de marcas
      final List<dynamic> items = data['data'] ?? <dynamic>[];

      // Extraer información de paginación
      final paginationData = data['pagination'];
      if (paginationData == null) {
        Logger.warn(
            '[MarcasApi] La respuesta no contiene información de paginación');
      }

      final int totalItems = paginationData?['total'] ?? items.length;
      final int currentPage = paginationData?['page'] ?? page;
      final int totalPages = paginationData?['totalPages'] ?? 1;
      final int actualPageSize = paginationData?['pageSize'] ?? pageSize;

      Logger.debug(
          '[MarcasApi] Marcas recuperadas: ${items.length}, total: $totalItems, página: $currentPage de $totalPages');

      // Convertir a objetos Marca
      final List<Marca> marcas = items
          .map((item) {
            try {
              return Marca.fromJson(item);
            } catch (e) {
              Logger.warn('[MarcasApi] Error al convertir marca: $e');
              // Si hay un error en la conversión, lo ignoramos y continuamos
              return Marca(id: 0, nombre: 'Error');
            }
          })
          .where((Marca marca) => marca.id > 0)
          .toList();

      // Crear resultado paginado
      final ResultadoPaginado<Marca> resultado = ResultadoPaginado<Marca>(
        items: marcas,
        total: totalItems,
        page: currentPage,
        totalPages: totalPages,
        pageSize: actualPageSize,
      );

      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, resultado);
        logCache('[MarcasApi] Marcas paginadas guardadas en caché: $cacheKey');
      }

      return resultado;
    } catch (e) {
      Logger.error('[MarcasApi] ERROR al obtener marcas paginadas: $e');
      rethrow;
    }
  }

  /// Obtiene todas las marcas (sin paginación)
  ///
  /// [useCache] Indica si se debe usar el caché (default: true)
  /// [forceRefresh] Fuerza a obtener datos frescos del servidor (default: false)
  Future<List<Marca>> getMarcas({
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Generar clave única
      const String cacheKey = '${_prefixListaMarcas}todas';

      // Forzar refresco del caché si es necesario
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }

      // Intentar obtener desde caché si useCache es true
      if (useCache && !forceRefresh) {
        final List<Marca>? cachedData = _cache.get<List<Marca>>(cacheKey);
        if (cachedData != null) {
          logCache('[MarcasApi] Todas las marcas obtenidas desde caché');
          return cachedData;
        }
      }

      // Obtener todas las marcas a través de la paginación
      // Usando un tamaño de página grande para reducir peticiones
      final ResultadoPaginado<Marca> resultado = await getMarcasPaginadas(
        pageSize:
            100, // Tamaño grande para obtener más marcas en una sola petición
        useCache: false, // No usar caché para la paginación interna
      );

      final List<Marca> marcas = resultado.items;

      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, marcas);
        logCache(
            '[MarcasApi] Todas las marcas guardadas en caché: ${marcas.length} elementos');
      }

      return marcas;
    } catch (e) {
      Logger.error('[MarcasApi] ERROR al obtener todas las marcas: $e');
      rethrow;
    }
  }

  /// Obtiene una marca por su ID
  ///
  /// [marcaId] ID de la marca a obtener
  /// [useCache] Indica si se debe usar el caché (default: true)
  /// [forceRefresh] Fuerza a obtener datos frescos del servidor (default: false)
  Future<Marca> getMarca(
    marcaId, {
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Validar que marcaId no sea nulo o vacío
      final String id = marcaId.toString();
      if (id.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de marca no puede estar vacío',
        );
      }

      final String cacheKey = '$_prefixMarca$id';

      // Forzar refresco del caché si es necesario
      if (forceRefresh) {
        _cache.invalidate(cacheKey);
      }

      // Intentar obtener desde caché si useCache es true
      if (useCache && !forceRefresh) {
        final Marca? cachedData = _cache.get<Marca>(cacheKey);
        if (cachedData != null) {
          logCache('[MarcasApi] Marca obtenida desde caché: $cacheKey');
          return cachedData;
        }
      }

      Logger.debug('[MarcasApi] Obteniendo marca con ID: $id');
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/marcas/$id',
        method: 'GET',
      );

      Logger.debug('[MarcasApi] Respuesta de getMarca recibida');

      // Extraer datos de la respuesta
      final dynamic data = response['data'];
      if (data == null) {
        throw ApiException(
          statusCode: 404,
          message: 'Marca no encontrada',
        );
      }

      // Convertir a objeto Marca
      final Marca marca = Marca.fromJson(data);

      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, marca);
        logCache('[MarcasApi] Marca guardada en caché: $cacheKey');
      }

      return marca;
    } catch (e) {
      Logger.error('[MarcasApi] ERROR al obtener marca #$marcaId: $e');
      rethrow;
    }
  }

  /// Crea una nueva marca
  ///
  /// [marcaData] Datos de la marca a crear
  Future<Marca> createMarca(Map<String, dynamic> marcaData) async {
    try {
      // Validar datos mínimos requeridos
      if (!marcaData.containsKey('nombre') ||
          marcaData['nombre'].toString().isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'Nombre de marca es requerido',
        );
      }

      Logger.debug('[MarcasApi] Creando nueva marca: ${marcaData['nombre']}');
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/marcas',
        method: 'POST',
        body: marcaData,
      );

      Logger.debug('[MarcasApi] Respuesta de createMarca recibida');

      // Extraer datos de la respuesta
      final dynamic data = response['data'];
      if (data == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Error al crear marca: respuesta inesperada del servidor',
        );
      }

      // Convertir a objeto Marca
      final Marca marca = Marca.fromJson(data);

      // Invalidar caché
      invalidateCache();

      return marca;
    } catch (e) {
      Logger.error('[MarcasApi] ERROR al crear marca: $e');
      rethrow;
    }
  }

  /// Crea una nueva marca usando un objeto [Marca]
  ///
  /// [marca] Objeto Marca con los datos a crear
  Future<Marca> createMarcaObjeto(Marca marca) async {
    return createMarca(marca.toJson());
  }

  /// Actualiza una marca existente
  ///
  /// [marcaId] ID de la marca a actualizar
  /// [marcaData] Datos actualizados de la marca
  Future<Marca> updateMarca(marcaId, Map<String, dynamic> marcaData) async {
    try {
      // Validar que marcaId no sea nulo o vacío
      final String id = marcaId.toString();
      if (id.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de marca no puede estar vacío',
        );
      }

      // Validar datos mínimos requeridos
      if (!marcaData.containsKey('nombre') ||
          marcaData['nombre'].toString().isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'Nombre de marca es requerido',
        );
      }

      Logger.debug('[MarcasApi] Actualizando marca con ID: $id');
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/marcas/$id',
        method: 'PATCH',
        body: marcaData,
      );

      Logger.debug('[MarcasApi] Respuesta de updateMarca recibida');

      // Extraer datos de la respuesta
      final dynamic data = response['data'];
      if (data == null) {
        throw ApiException(
          statusCode: 404,
          message: 'Marca no encontrada',
        );
      }

      // Convertir a objeto Marca
      final Marca marca = Marca.fromJson(data);

      // Invalidar caché específico y general
      _cache.invalidate('$_prefixMarca$id');
      invalidateCache();

      return marca;
    } catch (e) {
      Logger.error('[MarcasApi] ERROR al actualizar marca #$marcaId: $e');
      rethrow;
    }
  }

  /// Actualiza una marca existente usando un objeto [Marca]
  ///
  /// [marca] Objeto Marca con los datos actualizados
  Future<Marca> updateMarcaObjeto(Marca marca) async {
    return updateMarca(marca.id, marca.toJson());
  }

  /// Elimina una marca
  ///
  /// [marcaId] ID de la marca a eliminar
  Future<bool> deleteMarca(marcaId) async {
    try {
      // Validar que marcaId no sea nulo o vacío
      final String id = marcaId.toString();
      if (id.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de marca no puede estar vacío',
        );
      }

      Logger.debug('[MarcasApi] Eliminando marca con ID: $id');
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/marcas/$id',
        method: 'DELETE',
      );

      Logger.info('[MarcasApi] Marca eliminada correctamente');

      // Invalidar caché específico y general
      _cache.invalidate('$_prefixMarca$id');
      invalidateCache();

      return response['ok'] == true;
    } catch (e) {
      Logger.error('[MarcasApi] ERROR al eliminar marca #$marcaId: $e');
      rethrow;
    }
  }

  /// Método público para invalidar el caché de marcas
  ///
  /// [marcaId] ID opcional de la marca específica a invalidar
  void invalidateCache([String? marcaId]) {
    if (marcaId != null) {
      _cache.invalidate('$_prefixMarca$marcaId');
      logCache('[MarcasApi] Caché invalidada para marca: $marcaId');
    }

    // Invalidar todas las listas de marcas
    _cache.invalidateByPattern(_prefixListaMarcas);
    logCache('[MarcasApi] Caché de listas de marcas invalidada');
  }

  /// Método público para limpiar completamente el caché
  void clearCache() {
    _cache.clear();
    logCache('[MarcasApi] Caché completamente limpiada');
  }
}
