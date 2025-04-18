import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/cache/fast_cache.dart';
import 'package:condorsmotors/models/cliente.model.dart';
import 'package:flutter/foundation.dart';

class ClientesApi {
  final ApiClient _api;
  // Fast Cache para las operaciones de clientes
  final FastCache _cache = FastCache();

  ClientesApi(this._api);

  /// Obtiene la lista de clientes con soporte de caché
  ///
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<List<Cliente>> getClientes({
    int? page,
    int? pageSize,
    String? sortBy,
    String order = 'asc',
    String? search,
    String? filter,
    String? filterValue,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Generar clave única para este conjunto de parámetros
      final String cacheKey = _generateCacheKey(
        'clientes',
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        order: order,
        search: search,
        filter: filter,
        filterValue: filterValue,
      );

      // Intentar obtener desde caché si useCache es true y no se fuerza la actualización
      if (useCache && !forceRefresh) {
        final List<Cliente>? cachedData = _cache.get<List<Cliente>>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Clientes obtenidos desde caché: $cacheKey');
          return cachedData;
        }
      }

      debugPrint('ClientesApi: Obteniendo lista de clientes');

      // Construir parámetros de consulta
      final Map<String, String> queryParams = <String, String>{};

      // Solo agregar parámetros de paginación si se proporcionan explícitamente
      if (page != null && page > 0) {
        queryParams['page'] = page.toString();
      }

      if (pageSize != null && pageSize > 0) {
        queryParams['page_size'] = pageSize.toString();
      }

      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sort_by'] = sortBy;
        queryParams['order'] = order;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (filter != null && filter.isNotEmpty && filterValue != null) {
        queryParams['filter'] = filter;
        queryParams['filter_value'] = filterValue;
      }

      // Usar authenticatedRequest en lugar de request para manejar automáticamente tokens
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/clientes',
        method: 'GET',
        queryParams: queryParams,
      );

      debugPrint('ClientesApi: Respuesta de getClientes recibida');

      // Extraer los datos de la respuesta
      List<dynamic> items = <dynamic>[];

      if (response['status'] == 'success' && response['data'] is List) {
        // Nueva estructura: { status: "success", data: [ ... ] }
        items = response['data'] as List<dynamic>;
      } else if (response['data'] is List) {
        // Estructura alternativa: { data: [ ... ] }
        items = response['data'] as List<dynamic>;
      } else if (response['data'] is Map && response['data']['data'] is List) {
        // Estructura anterior anidada: { data: { data: [ ... ] } }
        items = response['data']['data'] as List<dynamic>;
      }

      // Convertir a lista de Cliente
      final List<Cliente> clientes = items
          .map((item) => Cliente.fromJson(item as Map<String, dynamic>))
          .toList();

      debugPrint(
          'ClientesApi: Total de clientes encontrados: ${clientes.length}');

      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, clientes);
        debugPrint('✅ Clientes guardados en caché: $cacheKey');
      }

      return clientes;
    } catch (e) {
      debugPrint('ClientesApi: ERROR al obtener clientes: $e');
      rethrow;
    }
  }

  /// Obtiene un cliente por su ID
  ///
  /// El ID debe ser un string, aunque represente un número
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<Cliente> getCliente(String clienteId, {bool useCache = true}) async {
    try {
      // Validar que clienteId no sea nulo o vacío
      if (clienteId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de cliente no puede estar vacío',
          errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
        );
      }

      // Clave para caché
      final String cacheKey = 'cliente_$clienteId';

      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final Cliente? cachedData = _cache.get<Cliente>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Cliente obtenido desde caché: $cacheKey');
          return cachedData;
        }
      }

      debugPrint('ClientesApi: Obteniendo cliente con ID: $clienteId');
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/clientes/$clienteId',
        method: 'GET',
      );

      debugPrint('ClientesApi: Respuesta de getCliente recibida');

      // Manejar estructura de respuesta
      Map<String, dynamic>? data;
      if (response['status'] == 'success' &&
          response['data'] is Map<String, dynamic>) {
        data = response['data'] as Map<String, dynamic>;
      } else if (response['data'] is Map<String, dynamic>) {
        data = response['data'] as Map<String, dynamic>;
      } else if (response['data'] is Map && response['data']['data'] is Map) {
        data = response['data']['data'] as Map<String, dynamic>;
      }

      if (data == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Error: Respuesta del servidor no tiene el formato esperado',
          errorCode: ApiConstants.errorCodes[500] ?? ApiConstants.unknownError,
        );
      }

      final Cliente cliente = Cliente.fromJson(data);

      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, cliente);
        debugPrint('✅ Cliente guardado en caché: $cacheKey');
      }

      return cliente;
    } catch (e) {
      debugPrint('ClientesApi: ERROR al obtener cliente #$clienteId: $e');
      rethrow;
    }
  }

  /// Busca un cliente por su número de documento
  ///
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<Cliente?> getClienteByDoc(String numeroDocumento,
      {bool useCache = true}) async {
    try {
      // Validar que numeroDocumento no sea nulo o vacío
      if (numeroDocumento.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'Número de documento no puede estar vacío',
          errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
        );
      }

      // Clave para caché
      final String cacheKey = 'cliente_doc_$numeroDocumento';

      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final Cliente? cachedData = _cache.get<Cliente>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Cliente obtenido desde caché: $cacheKey');
          return cachedData;
        }
      }

      debugPrint(
          'ClientesApi: Buscando cliente con documento: $numeroDocumento');
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/clientes/doc/$numeroDocumento',
        method: 'GET',
      );

      debugPrint('ClientesApi: Respuesta de getClienteByDoc recibida');

      // Manejar estructura anidada
      Map<String, dynamic>? data;
      if (response['data'] is Map && response['data'].containsKey('data')) {
        data = response['data']['data'] as Map<String, dynamic>;
      } else {
        data = response['data'] as Map<String, dynamic>;
      }

      final Cliente cliente = Cliente.fromJson(data);

      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, cliente);
        debugPrint('✅ Cliente guardado en caché: $cacheKey');
      }

      return cliente;
    } catch (e) {
      debugPrint(
          'ClientesApi: ERROR al buscar cliente por documento $numeroDocumento: $e');

      // Si se produce un error 404, devolver null
      if (e is ApiException && e.statusCode == 404) {
        return null;
      }

      rethrow;
    }
  }

  /// Busca datos de un cliente externo (RENIEC/SUNAT) por su número de documento
  ///
  /// Este método consulta un servicio externo para obtener los datos de un cliente
  /// que aún no existe en la base de datos, para facilitar el registro de nuevos clientes.
  ///
  /// Retorna un mapa con los datos del cliente o null si no se encontró.
  Future<Map<String, dynamic>?> buscarClienteExternoPorDoc(
      String numeroDocumento) async {
    try {
      // Validar que el número de documento no sea nulo o vacío
      if (numeroDocumento.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'Número de documento no puede estar vacío',
          errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
        );
      }

      debugPrint(
          'ClientesApi: Consultando API externa para documento: $numeroDocumento');

      // Realizar la petición al endpoint externo
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/clientes/doc/$numeroDocumento',
        method: 'GET',
      );

      debugPrint('ClientesApi: Respuesta de API externa recibida');

      // Verificar si la respuesta fue exitosa
      if (response['status'] != 'success' || response['data'] == null) {
        debugPrint(
            'ClientesApi: La API externa no encontró datos para el documento $numeroDocumento');
        return null;
      }

      // Extraer los datos del cliente de la respuesta
      Map<String, dynamic> clienteData;
      if (response['data'] is Map<String, dynamic>) {
        clienteData = response['data'] as Map<String, dynamic>;
      } else {
        debugPrint('ClientesApi: Formato de respuesta inesperado');
        return null;
      }

      debugPrint(
          'ClientesApi: Datos encontrados: ${clienteData['denominacion']}');
      return clienteData;
    } catch (e) {
      debugPrint(
          'ClientesApi: ERROR al consultar API externa para documento $numeroDocumento: $e');

      // Si ocurre cualquier error, devolvemos null para manejar el error de forma silenciosa
      return null;
    }
  }

  /// Crea un nuevo cliente
  Future<Cliente> createCliente(Map<String, dynamic> clienteData) async {
    try {
      // Validar datos mínimos requeridos
      if (!clienteData.containsKey('denominacion') ||
          !clienteData.containsKey('numeroDocumento')) {
        throw ApiException(
          statusCode: 400,
          message:
              'Denominación y número de documento son requeridos para crear cliente',
          errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
        );
      }

      // Limpiar datos antes de enviar (remover campos vacíos)
      final Map<String, dynamic> datosLimpios = Map.from(clienteData)
        ..removeWhere((key, value) =>
            value == null ||
            (value is String && value.isEmpty) ||
            (key == 'correo' &&
                (value == null || value.toString().trim().isEmpty)) ||
            (key == 'direccion' &&
                (value == null || value.toString().trim().isEmpty)) ||
            (key == 'telefono' &&
                (value == null ||
                    value.toString().trim() == '+51 ' ||
                    value.toString().trim().isEmpty)));

      debugPrint(
          'ClientesApi: Creando nuevo cliente: ${datosLimpios['denominacion']}');
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/clientes',
        method: 'POST',
        body: datosLimpios,
      );

      debugPrint('ClientesApi: Respuesta de createCliente recibida');

      // Manejar estructura de respuesta
      Map<String, dynamic>? data;
      if (response['status'] == 'success' &&
          response['data'] is Map<String, dynamic>) {
        data = response['data'] as Map<String, dynamic>;
      } else if (response['data'] is Map<String, dynamic>) {
        data = response['data'] as Map<String, dynamic>;
      } else if (response['data'] is Map && response['data']['data'] is Map) {
        data = response['data']['data'] as Map<String, dynamic>;
      }

      if (data == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Error: Respuesta del servidor no tiene el formato esperado',
          errorCode: ApiConstants.errorCodes[500] ?? ApiConstants.unknownError,
        );
      }

      // Invalidar caché de listas de clientes
      _invalidateListCache();

      return Cliente.fromJson(data);
    } catch (e) {
      debugPrint('ClientesApi: ERROR al crear cliente: $e');
      rethrow;
    }
  }

  /// Actualiza un cliente existente
  ///
  /// El ID debe ser un string, aunque represente un número
  Future<Cliente> updateCliente(
      String clienteId, Map<String, dynamic> clienteData) async {
    try {
      // Validar que clienteId no sea nulo o vacío
      if (clienteId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de cliente no puede estar vacío',
          errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
        );
      }

      debugPrint('ClientesApi: Actualizando cliente con ID: $clienteId');
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/clientes/$clienteId',
        method: 'PATCH',
        body: clienteData,
      );

      debugPrint('ClientesApi: Respuesta de updateCliente recibida');

      // Manejar estructura anidada
      Map<String, dynamic>? data;
      if (response['data'] is Map && response['data'].containsKey('data')) {
        data = response['data']['data'];
      } else {
        data = response['data'];
      }

      if (data == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Error al actualizar cliente',
          errorCode: ApiConstants.errorCodes[500] ?? ApiConstants.unknownError,
        );
      }

      // Invalidar caché de listas de clientes y este cliente específico
      _invalidateClientCache(clienteId);

      return Cliente.fromJson(data);
    } catch (e) {
      debugPrint('ClientesApi: ERROR al actualizar cliente #$clienteId: $e');
      rethrow;
    }
  }

  /// Invalidar caché de listas de clientes
  void _invalidateListCache() {
    _cache.invalidateByPattern('clientes');
    debugPrint('🗑️ Caché de listas de clientes invalidada');
  }

  /// Invalidar caché de un cliente específico
  void _invalidateClientCache(String clienteId) {
    _cache.invalidate('cliente_$clienteId');
    _invalidateListCache(); // También invalidar listas
    debugPrint('🗑️ Caché del cliente #$clienteId invalidada');
  }

  /// Generar clave única para caché basada en parámetros
  String _generateCacheKey(
    String prefix, {
    int? page,
    int? pageSize,
    String? sortBy,
    String? order,
    String? search,
    String? filter,
    String? filterValue,
  }) {
    final List<String> parts = <String>[prefix];

    if (page != null) {
      parts.add('page=$page');
    }
    if (pageSize != null) {
      parts.add('pageSize=$pageSize');
    }
    if (sortBy != null) {
      parts.add('sort=$sortBy');
    }
    if (order != null) {
      parts.add('order=$order');
    }
    if (search != null) {
      parts.add('search=$search');
    }
    if (filter != null) {
      parts.add('filter=$filter');
    }
    if (filterValue != null) {
      parts.add('filterValue=$filterValue');
    }

    return parts.join('_');
  }
}
