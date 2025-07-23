import 'dart:math' as math;
import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/cache/fast_cache.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/utils/logger.dart';

/// Clase utilitaria para manejar parámetros de paginación y filtrado
///
/// Esta clase abstracta proporciona métodos y lógica reutilizable para
/// diferentes APIs que necesiten implementar paginación, filtrado y ordenación.
class PaginacionUtils {
  /// Genera una clave única para la caché basada en los parámetros de paginación y filtrado
  ///
  /// [base] Clave base (generalmente el nombre del recurso)
  /// [params] Mapa de parámetros de búsqueda, paginación y filtrado
  static String generateCacheKey(String base, Map<String, dynamic> params) {
    final List<String> components = <String>[base];

    // Ordenar las claves para garantizar consistencia en las claves de caché
    final List<String> sortedKeys = params.keys.toList()..sort();

    for (final String key in sortedKeys) {
      final dynamic value = params[key];
      if (value != null) {
        // Convertir los valores a cadenas adecuadas para la clave
        String stringValue;
        if (value is bool) {
          stringValue = value ? 'true' : 'false';
        } else {
          stringValue = value.toString();
        }

        // Solo incluir valores no vacíos
        if (stringValue.isNotEmpty) {
          components
              .add('${key.substring(0, math.min(3, key.length))}:$stringValue');
        }
      }
    }

    return components.join('_');
  }

  /// Construye parámetros de consulta para solicitudes HTTP basados en filtros de paginación
  ///
  /// [search] Término de búsqueda
  /// [page] Número de página
  /// [pageSize] Elementos por página
  /// [sortBy] Campo para ordenar
  /// [order] Dirección de ordenación (asc/desc)
  /// [filter] Campo para filtrar
  /// [filterValue] Valor del filtro
  /// [filterType] Tipo de operación de filtrado (eq, lt, gt, etc.)
  /// [extraParams] Parámetros adicionales específicos de cada API
  static Map<String, String> buildQueryParams({
    String? search,
    int? page,
    int? pageSize,
    String? sortBy,
    String? order,
    String? filter,
    String? filterValue,
    String? filterType,
    Map<String, String>? extraParams,
  }) {
    final Map<String, String> queryParams = <String, String>{};

    // Añadir parámetros básicos de paginación
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (page != null) {
      queryParams['page'] = page.toString();
    }

    if (pageSize != null) {
      queryParams['page_size'] = pageSize.toString();
    }

    // Añadir parámetros de ordenación
    if (sortBy != null && sortBy.isNotEmpty) {
      queryParams['sort_by'] = sortBy;
    }

    if (order != null && order.isNotEmpty) {
      queryParams['order'] = order;
    }

    // Añadir parámetros de filtrado
    if (filter != null && filter.isNotEmpty) {
      queryParams['filter'] = filter;
    }

    if (filterValue != null) {
      queryParams['filter_value'] = filterValue;
    }

    if (filterType != null && filterType.isNotEmpty) {
      queryParams['filter_type'] = filterType;
    }

    // Añadir parámetros adicionales si existen
    if (extraParams != null && extraParams.isNotEmpty) {
      queryParams.addAll(extraParams);
    }

    return queryParams;
  }

  /// Aplica filtrado en memoria a una lista de elementos cuando no es posible hacerlo en el servidor
  ///
  /// [items] Lista de elementos originales
  /// [filtroFn] Función de filtro que determina si un elemento debe incluirse
  /// [page] Número de página actual
  /// [pageSize] Tamaño de página
  /// [paginacionOriginal] Objeto de paginación original, usado como base
  static PaginatedResponse<T> aplicarFiltroPaginado<T>({
    required List<T> items,
    required bool Function(T) filtroFn,
    required int page,
    required int pageSize,
    required Paginacion paginacionOriginal,
    Map<String, dynamic>? metadata,
  }) {
    // Aplicar el filtro a todos los elementos
    final List<T> elementosFiltrados = items.where(filtroFn).toList();

    // Calcular la paginación para los elementos filtrados
    final int totalElementos = elementosFiltrados.length;
    final int totalPaginas = (totalElementos / pageSize).ceil();

    // Crear paginación ajustada
    final Paginacion paginacionAjustada = Paginacion(
      currentPage: page,
      totalPages: totalPaginas > 0 ? totalPaginas : 1,
      totalItems: totalElementos,
      hasNext: page < totalPaginas,
      hasPrev: page > 1,
    );

    // Obtener elementos para la página actual
    final int startIndex = (page - 1) * pageSize;
    final int endIndex = startIndex + pageSize < totalElementos
        ? startIndex + pageSize
        : totalElementos;

    // Asegurarse de no ir fuera de rango
    final List<T> elementosPaginados = startIndex < totalElementos
        ? elementosFiltrados.sublist(startIndex, endIndex)
        : <T>[];

    return PaginatedResponse<T>(
      items: elementosPaginados,
      paginacion: paginacionAjustada,
      metadata: metadata,
    );
  }

  /// Registra información detallada sobre parámetros de paginación para depuración
  ///
  /// [recurso] Nombre del recurso o endpoint
  /// [params] Mapa de parámetros de consulta
  static void logPaginacion(String recurso, Map<String, dynamic> params) {
    final StringBuffer sb = StringBuffer()
    ..write('Parámetros de paginación para $recurso: { ');

    int i = 0;
    params.forEach((key, value) {
      if (i > 0) {
        sb.write(', ');
      }
      sb.write('$key: $value');
      i++;
    });

    sb.write(' }');
    Logger.debug(sb.toString());
  }

  /// Parsea una respuesta de API para extraer paginación y datos
  ///
  /// [response] Respuesta completa de la API
  /// [fromJson] Función para convertir elementos JSON a objetos tipados
  static PaginatedResponse<T> parsePaginatedResponse<T>(
    Map<String, dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    // Extraer los datos
    final List<dynamic> rawData = response['data'] ?? <dynamic>[];
    final List<T> items =
        rawData.map((item) => fromJson(item as Map<String, dynamic>)).toList();

    // Extraer información de paginación
    Map<String, dynamic> paginacionData = <String, dynamic>{};
    if (response.containsKey('pagination') && response['pagination'] != null) {
      paginacionData = response['pagination'] as Map<String, dynamic>;
    }

    // Extraer metadata si está disponible
    Map<String, dynamic>? metadata;
    if (response.containsKey('metadata') && response['metadata'] != null) {
      metadata = response['metadata'] as Map<String, dynamic>;
    }

    // Crear la respuesta paginada
    return PaginatedResponse<T>(
      items: items,
      paginacion: Paginacion.fromJson(paginacionData),
      metadata: metadata,
    );
  }
}

/// Tipos de operaciones de filtrado soportadas
class FilterType {
  static const String equal = 'eq'; // Igual a
  static const String notEqual = 'neq'; // No igual a
  static const String greaterThan = 'gt'; // Mayor que
  static const String lessThan = 'lt'; // Menor que
  static const String greaterEqual = 'gte'; // Mayor o igual que
  static const String lessEqual = 'lte'; // Menor o igual que
  static const String contains = 'cont'; // Contiene
  static const String startsWith = 'start'; // Comienza con
  static const String endsWith = 'end'; // Termina con
  static const String between = 'btw'; // Entre dos valores
  static const String isNull = 'null'; // Es nulo
  static const String isNotNull = 'nnull'; // No es nulo
  static const String in_ = 'in'; // Está en una lista de valores
}

/// Clase que encapsula los parámetros de filtrado para simplificar su manejo
class FiltroParams {
  final String? search;
  final int page;
  final int pageSize;
  final String? sortBy;
  final String? order;
  final String? filter;
  final String? filterValue;
  final String? filterType;
  final Map<String, String>? extraParams;

  FiltroParams({
    this.search,
    this.page = 1,
    this.pageSize = 20,
    this.sortBy,
    this.order = 'asc',
    this.filter,
    this.filterValue,
    this.filterType = FilterType.equal,
    this.extraParams,
  });

  /// Convierte los parámetros a un mapa que puede ser usado para generar claves de caché
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{
      'search': search,
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
      'order': order,
      'filter': filter,
      'filterValue': filterValue,
      'filterType': filterType,
    };

    // Añadir parámetros adicionales
    if (extraParams != null) {
      map.addAll(extraParams!);
    }

    return map;
  }

  /// Construye parámetros de consulta para una solicitud HTTP
  Map<String, String> buildQueryParams() {
    return PaginacionUtils.buildQueryParams(
      search: search,
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      order: order,
      filter: filter,
      filterValue: filterValue,
      filterType: filterType,
      extraParams: extraParams,
    );
  }

  /// Crea una nueva instancia con algunos parámetros modificados
  FiltroParams copyWith({
    String? search,
    int? page,
    int? pageSize,
    String? sortBy,
    String? order,
    String? filter,
    String? filterValue,
    String? filterType,
    Map<String, String>? extraParams,
  }) {
    return FiltroParams(
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
      order: order ?? this.order,
      filter: filter ?? this.filter,
      filterValue: filterValue ?? this.filterValue,
      filterType: filterType ?? this.filterType,
      extraParams: extraParams ?? this.extraParams,
    );
  }
}

/// Servicio genérico de paginación que puede ser utilizado para cualquier tipo de recurso
class PaginacionService<T> {
  final ApiClient _api;
  final FastCache _cache;
  final String _baseEndpoint;
  final String _cachePrefix;
  final T Function(Map<String, dynamic>) _fromJson;

  PaginacionService({
    required ApiClient api,
    required FastCache cache,
    required String baseEndpoint,
    required String cachePrefix,
    required T Function(Map<String, dynamic>) fromJson,
  })  : _api = api,
        _cache = cache,
        _baseEndpoint = baseEndpoint,
        _cachePrefix = cachePrefix,
        _fromJson = fromJson;

  /// Obtiene elementos paginados
  ///
  /// [params] Parámetros de filtrado y paginación
  /// [endpoint] Endpoint específico (opcional, por defecto usa el baseEndpoint)
  /// [useCache] Indica si se debe usar el caché (default: true)
  /// [forceRefresh] Si es true, invalida la caché antes de obtener los datos
  Future<PaginatedResponse<T>> getPaginados({
    required FiltroParams params,
    String? endpoint,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      final String apiEndpoint = endpoint ?? _baseEndpoint;

      // Si se requiere forzar la recarga, invalidar la caché primero
      if (forceRefresh) {
        Logger.debug('Forzando recarga de $_cachePrefix');
        invalidateCache();
      }

      // Generar clave de caché
      final String cacheKey = PaginacionUtils.generateCacheKey(
        '${_cachePrefix}_list',
        params.toMap(),
      );

      // Intentar obtener desde caché si useCache es true
      if (useCache && !forceRefresh) {
        final PaginatedResponse<T>? cachedData =
            _cache.get<PaginatedResponse<T>>(cacheKey);
        if (cachedData != null) {
          logCache('Datos obtenidos desde caché: $cacheKey');
          return cachedData;
        }
      }

      // Si no hay caché o useCache es false, obtener desde la API
      PaginacionUtils.logPaginacion(
        'Endpoint: $apiEndpoint',
        params.toMap(),
      );

      // Construir query params
      final Map<String, String> queryParams = params.buildQueryParams();

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: apiEndpoint,
        method: 'GET',
        queryParams: queryParams,
      );

      // Procesar respuesta
      final PaginatedResponse<T> result =
          PaginacionUtils.parsePaginatedResponse(
        response,
        _fromJson,
      );

      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, result);
        logCache('Datos guardados en caché: $cacheKey');
      }

      return result;
    } catch (e) {
      Logger.debug('Error al obtener elementos paginados: $e');
      rethrow;
    }
  }

  /// Obtiene un elemento por su ID
  ///
  /// [id] ID del elemento
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<T> getById(String id, {bool useCache = true}) async {
    try {
      final String cacheKey = '${_cachePrefix}_$id';

      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final T? cachedData = _cache.get<T>(cacheKey);
        if (cachedData != null) {
          logCache('Elemento obtenido desde caché: $cacheKey');
          return cachedData;
        }
      }

      Logger.debug('Obteniendo $_cachePrefix con ID: $id');

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '$_baseEndpoint/$id',
        method: 'GET',
      );

      final T item = _fromJson(response['data'] as Map<String, dynamic>);

      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, item);
        logCache('Elemento guardado en caché: $cacheKey');
      }

      return item;
    } catch (e) {
      Logger.debug('Error al obtener elemento por ID: $e');
      rethrow;
    }
  }

  /// Crea un nuevo elemento
  ///
  /// [data] Datos del elemento a crear
  Future<T> create(Map<String, dynamic> data) async {
    try {
      Logger.debug('Creando nuevo elemento $_cachePrefix');

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: _baseEndpoint,
        method: 'POST',
        body: data,
      );

      // Invalidar caché relacionada
      invalidateCache();

      return _fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      Logger.debug('Error al crear elemento: $e');
      rethrow;
    }
  }

  /// Actualiza un elemento existente
  ///
  /// [id] ID del elemento
  /// [data] Datos actualizados
  Future<T> update(String id, Map<String, dynamic> data) async {
    try {
      Logger.debug('Actualizando elemento $_cachePrefix con ID: $id');

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '$_baseEndpoint/$id',
        method: 'PATCH',
        body: data,
      );

      // Invalidar caché relacionada
      invalidateCache();
      _cache.invalidate('${_cachePrefix}_$id');

      return _fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      Logger.debug('Error al actualizar elemento: $e');
      rethrow;
    }
  }

  /// Elimina un elemento
  ///
  /// [id] ID del elemento
  Future<bool> delete(String id) async {
    try {
      Logger.debug('Eliminando elemento $_cachePrefix con ID: $id');

      await _api.authenticatedRequest(
        endpoint: '$_baseEndpoint/$id',
        method: 'DELETE',
      );

      // Invalidar caché relacionada
      invalidateCache();
      _cache.invalidate('${_cachePrefix}_$id');

      return true;
    } catch (e) {
      Logger.debug('Error al eliminar elemento: $e');
      return false;
    }
  }

  /// Invalida la caché relacionada con este servicio
  void invalidateCache() {
    _cache.invalidateByPattern('${_cachePrefix}_');
    logCache('Caché de $_cachePrefix invalidada');
  }
}
