import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/cache/fast_cache.dart';
import 'package:condorsmotors/api/protected/paginacion.api.dart';
import 'package:condorsmotors/models/categoria.model.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/utils/logger.dart';

class CategoriasApi {
  final ApiClient _api;
  final String _endpoint = '/categorias';
  // Fast Cache para las operaciones de categorías
  final FastCache _cache = FastCache();

  CategoriasApi(this._api);

  /// Obtiene todas las categorías
  ///
  /// Ordenadas alfabéticamente por nombre
  /// [useCache] Indica si se debe usar el caché (default: true)
  /// [page] Número de página para paginación (opcional)
  /// [pageSize] Número de elementos por página (opcional)
  ///
  /// La respuesta incluye el campo `totalProductos` que indica la cantidad de
  /// productos asociados a cada categoría.
  Future<PaginatedResponse<dynamic>> getCategoriasPaginadas({
    bool useCache = true,
    int? page,
    int? pageSize,
  }) async {
    try {
      // Crear objeto FiltroParams para manejar los parámetros
      final FiltroParams filtroParams = FiltroParams(
        page: page ?? 1,
        pageSize: pageSize ?? 20,
        sortBy: 'nombre',
      );

      // Generar clave de caché
      final String cacheKey = PaginacionUtils.generateCacheKey(
        'categorias_paginadas',
        filtroParams.toMap(),
      );

      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final PaginatedResponse<dynamic>? cachedData =
            _cache.get<PaginatedResponse<dynamic>>(cacheKey);
        if (cachedData != null) {
          logCache('Categorías paginadas obtenidas desde caché');
          return cachedData;
        }
      }

      Logger.debug('Obteniendo categorías paginadas');
      PaginacionUtils.logPaginacion('Categorías', filtroParams.toMap());

      final Map<String, String> queryParams = filtroParams.buildQueryParams();

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: _endpoint,
        method: 'GET',
        queryParams: queryParams,
      );

      Logger.debug('Respuesta recibida, status: ${response['status']}');

      // Procesar respuesta usando la utilidad
      final PaginatedResponse<dynamic> result =
          PaginacionUtils.parsePaginatedResponse(
        response,
        (item) => item, // Mantenemos como dynamic para compatibilidad
      );

      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, result);
        logCache('Categorías paginadas guardadas en caché');
      }

      return result;
    } catch (e) {
      Logger.error('Error al obtener categorías paginadas: $e');
      // Capturar más detalles sobre el error
      if (e is ApiException) {
        Logger.error('Código de error: ${e.statusCode}, Mensaje: ${e.message}');
        if (e.data != null) {
          Logger.error('Datos adicionales del error: ${e.data}');
        }
      }
      rethrow;
    }
  }

  /// Obtiene todas las categorías
  ///
  /// Ordenadas alfabéticamente por nombre
  /// [useCache] Indica si se debe usar el caché (default: true)
  ///
  /// La respuesta incluye el campo `totalProductos` que indica la cantidad de
  /// productos asociados a cada categoría.
  Future<List<dynamic>> getCategorias({bool useCache = true}) async {
    try {
      const String cacheKey = 'categorias_all';

      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final List? cachedData = _cache.get<List<dynamic>>(cacheKey);
        if (cachedData != null) {
          logCache('Categorías obtenidas desde caché');
          return cachedData;
        }
      }

      Logger.debug('Obteniendo categorías');

      final Map<String, String> queryParams = <String, String>{
        'sort_by': 'nombre',
      };

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: _endpoint,
        method: 'GET',
        queryParams: queryParams,
      );

      Logger.debug('Respuesta recibida, status: ${response['status']}');

      // Verificar estructura de respuesta
      if (response['data'] == null) {
        Logger.warn('La respuesta no contiene datos');
        return <List<dynamic>>[];
      }

      if (response['data'] is! List) {
        Logger.warn(
            'Formato de datos inesperado. Recibido: ${response['data'].runtimeType}');
        return <List<dynamic>>[];
      }

      final List categorias = response['data'] as List;
      Logger.debug('${categorias.length} categorías encontradas');

      // Información adicional sobre totalProductos
      int totalProductosGlobal = 0;
      for (final cat in categorias) {
        if (cat is Map && cat.containsKey('totalProductos')) {
          totalProductosGlobal += (cat['totalProductos'] as int? ?? 0);
        }
      }
      Logger.debug(
          'Total de productos en todas las categorías: $totalProductosGlobal');

      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, categorias);
        logCache('Categorías guardadas en caché');
      }

      return categorias;
    } catch (e) {
      Logger.error('Error al obtener categorías: $e');
      // Capturar más detalles sobre el error
      if (e is ApiException) {
        Logger.error('Código de error: ${e.statusCode}, Mensaje: ${e.message}');
        if (e.data != null) {
          Logger.error('Datos adicionales del error: ${e.data}');
        }
      }
      rethrow;
    }
  }

  /// Obtiene todas las categorías como objetos [Categoria]
  ///
  /// Ordenadas alfabéticamente por nombre
  /// [useCache] Indica si se debe usar el caché (default: true)
  /// [page] Número de página para paginación (opcional)
  /// [pageSize] Número de elementos por página (opcional)
  ///
  /// Si se proporcionan page y pageSize, devuelve un resultado paginado,
  /// de lo contrario devuelve una lista simple.
  Future<PaginatedResponse<Categoria>> getCategoriasObjetosPaginados({
    bool useCache = true,
    int? page,
    int? pageSize,
  }) async {
    try {
      if (page != null || pageSize != null) {
        // Obtener categorías paginadas
        final PaginatedResponse<dynamic> response =
            await getCategoriasPaginadas(
          useCache: useCache,
          page: page,
          pageSize: pageSize,
        );

        // Convertir a objetos Categoria
        return response.map((data) => Categoria.fromJson(data));
      } else {
        // Si no se proporciona paginación, obtener todas y convertir a una respuesta paginada
        final List<Categoria> categorias =
            await getCategoriasObjetos(useCache: useCache);

        return PaginatedResponse<Categoria>(
          items: categorias,
          paginacion: Paginacion.fromParams(
            totalItems: categorias.length,
            pageSize: categorias.length,
            currentPage: 1,
          ),
        );
      }
    } catch (e) {
      Logger.error('ERROR al obtener categorías como objetos paginados: $e');
      rethrow;
    }
  }

  /// Obtiene todas las categorías como objetos [Categoria]
  ///
  /// Ordenadas alfabéticamente por nombre
  /// [useCache] Indica si se debe usar el caché (default: true)
  ///
  /// La respuesta incluye el campo `totalProductos` que indica la cantidad de
  /// productos asociados a cada categoría.
  Future<List<Categoria>> getCategoriasObjetos({bool useCache = true}) async {
    try {
      final List categoriasRaw = await getCategorias(useCache: useCache);
      final List<Categoria> categorias = categoriasRaw
          .map((data) => Categoria.fromJson(data))
          .toList()
        ..sort((Categoria a, Categoria b) => a.nombre.compareTo(b.nombre));

      return categorias;
    } catch (e) {
      Logger.error('ERROR al obtener categorías como objetos: $e');
      rethrow;
    }
  }

  /// Crea una nueva categoría
  ///
  /// [nombre] Nombre de la categoría
  /// [descripcion] Descripción opcional de la categoría
  Future<Map<String, dynamic>> createCategoria({
    required String nombre,
    String? descripcion,
  }) async {
    try {
      Logger.debug('Creando nueva categoría: $nombre');

      final Map<String, dynamic> body = <String, dynamic>{
        'nombre': nombre,
      };

      if (descripcion != null) {
        body['descripcion'] = descripcion;
      }

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: _endpoint,
        method: 'POST',
        body: body,
      );

      Logger.info('Categoría creada con éxito');

      // Invalidar caché de categorías
      _invalidateCache();

      return response['data'];
    } catch (e) {
      Logger.error('Error al crear categoría: $e');
      // Capturar más detalles sobre el error
      if (e is ApiException) {
        Logger.error('Código de error: ${e.statusCode}, Mensaje: ${e.message}');
        if (e.data != null) {
          Logger.error('Datos adicionales del error: ${e.data}');
        }
      }
      rethrow;
    }
  }

  /// Crea una nueva categoría usando un objeto [Categoria]
  Future<Categoria> createCategoriaObjeto(Categoria categoria) async {
    try {
      final Map<String, dynamic> data = await createCategoria(
        nombre: categoria.nombre,
        descripcion: categoria.descripcion,
      );
      return Categoria.fromJson(data);
    } catch (e) {
      Logger.error('ERROR al crear categoría como objeto: $e');
      rethrow;
    }
  }

  /// Actualiza una categoría existente
  ///
  /// [id] ID de la categoría a actualizar
  /// [nombre] Nuevo nombre de la categoría (opcional)
  /// [descripcion] Nueva descripción de la categoría (opcional)
  Future<Map<String, dynamic>> updateCategoria({
    required String id,
    String? nombre,
    String? descripcion,
  }) async {
    try {
      Logger.debug('Actualizando categoría con ID: $id');

      // Construir el cuerpo de la solicitud solo con los campos que se van a actualizar
      final Map<String, dynamic> body = <String, dynamic>{};

      if (nombre != null) {
        body['nombre'] = nombre;
      }

      if (descripcion != null) {
        body['descripcion'] = descripcion;
      }

      // Si no hay campos para actualizar, lanzar un error
      if (body.isEmpty) {
        throw Exception('Debe proporcionar al menos un campo para actualizar');
      }

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id',
        method: 'PATCH', // Usar PATCH para actualización parcial
        body: body,
      );

      Logger.info('Categoría actualizada con éxito');

      // Invalidar caché
      _invalidateCache();
      _cache.invalidate('categoria_$id');

      return response['data'];
    } catch (e) {
      Logger.error('Error al actualizar categoría: $e');
      // Capturar más detalles sobre el error
      if (e is ApiException) {
        Logger.error('Código de error: ${e.statusCode}, Mensaje: ${e.message}');
        if (e.data != null) {
          Logger.error('Datos adicionales del error: ${e.data}');
        }
      }
      rethrow;
    }
  }

  /// Actualiza una categoría existente usando un objeto [Categoria]
  Future<Categoria> updateCategoriaObjeto(Categoria categoria) async {
    try {
      final Map<String, dynamic> data = await updateCategoria(
        id: categoria.id.toString(),
        nombre: categoria.nombre,
        descripcion: categoria.descripcion,
      );
      return Categoria.fromJson(data);
    } catch (e) {
      Logger.error('ERROR al actualizar categoría como objeto: $e');
      rethrow;
    }
  }

  /// Elimina una categoría
  ///
  /// [id] ID de la categoría a eliminar
  Future<bool> deleteCategoria(String id) async {
    try {
      Logger.debug('Eliminando categoría con ID: $id');

      await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id',
        method: 'DELETE',
      );

      Logger.info('Categoría eliminada con éxito');

      // Invalidar caché
      _invalidateCache();
      _cache.invalidate('categoria_$id');

      return true;
    } catch (e) {
      Logger.error('Error al eliminar categoría: $e');
      // Capturar más detalles sobre el error
      if (e is ApiException) {
        Logger.error('Código de error: ${e.statusCode}, Mensaje: ${e.message}');
        if (e.data != null) {
          Logger.error('Datos adicionales del error: ${e.data}');
        }
      }
      return false;
    }
  }

  /// Obtiene una categoría específica por su ID
  ///
  /// [id] ID de la categoría a obtener
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<Map<String, dynamic>> getCategoria(String id,
      {bool useCache = true}) async {
    try {
      final String cacheKey = 'categoria_$id';

      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final Map<String, dynamic>? cachedData =
            _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null) {
          logCache('Categoría obtenida desde caché: $cacheKey');
          return cachedData;
        }
      }

      Logger.debug('Obteniendo categoría con ID: $id');

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id',
        method: 'GET',
      );

      Logger.debug('Categoría obtenida con éxito');

      final Map<String, dynamic> categoria =
          response['data'] as Map<String, dynamic>;

      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, categoria);
        logCache('Categoría guardada en caché: $cacheKey');
      }

      return categoria;
    } catch (e) {
      Logger.error('Error al obtener categoría: $e');
      // Capturar más detalles sobre el error
      if (e is ApiException) {
        Logger.error('Código de error: ${e.statusCode}, Mensaje: ${e.message}');
        if (e.data != null) {
          Logger.error('Datos adicionales del error: ${e.data}');
        }
      }
      rethrow;
    }
  }

  /// Obtiene una categoría específica por su ID como objeto [Categoria]
  Future<Categoria> getCategoriaObjeto(String id,
      {bool useCache = true}) async {
    try {
      final Map<String, dynamic> categoriaData =
          await getCategoria(id, useCache: useCache);
      return Categoria.fromJson(categoriaData);
    } catch (e) {
      Logger.error('ERROR al obtener categoría como objeto: $e');
      rethrow;
    }
  }

  /// Busca categorías por nombre
  ///
  /// [nombre] Término de búsqueda
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<List<Categoria>> buscarCategoriasPorNombre(
    String nombre, {
    bool useCache = true,
  }) async {
    try {
      // Obtener todas las categorías
      final List<Categoria> categorias =
          await getCategoriasObjetos(useCache: useCache);

      // Filtrar por nombre
      final String nombreLower = nombre.toLowerCase();
      return categorias
          .where((c) => c.nombre.toLowerCase().contains(nombreLower))
          .toList();
    } catch (e) {
      Logger.error('ERROR al buscar categorías por nombre: $e');
      rethrow;
    }
  }

  /// Invalidar caché de categorías
  void _invalidateCache() {
    _cache.invalidate('categorias_all');
    _cache.invalidateByPattern('categorias_paginadas');
    logCache('Caché de categorías invalidada');
  }

  /// Método público para forzar refresco de caché
  void invalidateCache([String? categoriaId]) {
    if (categoriaId != null) {
      _cache.invalidate('categoria_$categoriaId');
      _invalidateCache();
      logCache('Caché invalidada para categoría: $categoriaId');
    } else {
      _cache.clear();
      logCache('Caché de categorías completamente invalidada');
    }
  }
}
