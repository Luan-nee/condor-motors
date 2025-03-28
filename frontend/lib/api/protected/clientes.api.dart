import 'package:flutter/foundation.dart';

import '../../models/cliente.model.dart';
import '../main.api.dart';
import 'cache/fast_cache.dart';

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
      final cacheKey = _generateCacheKey(
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
        final cachedData = _cache.get<List<Cliente>>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Clientes obtenidos desde caché: $cacheKey');
          return cachedData;
        }
      }
      
      debugPrint('ClientesApi: Obteniendo lista de clientes');
      
      // Construir parámetros de consulta
      final Map<String, String> queryParams = {};
      
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
      final response = await _api.authenticatedRequest(
        endpoint: '/clientes',
        method: 'GET',
        queryParams: queryParams,
      );
      
      debugPrint('ClientesApi: Respuesta de getClientes recibida');
      
      // Extraer los datos de la respuesta
      List<dynamic> items = [];
      
      if (response['data'] is List) {
        // Nueva estructura: { status: "success", data: [ ... ] }
        items = response['data'] as List<dynamic>;
      } else if (response['data'] is Map) {
        if (response['data'].containsKey('data') && response['data']['data'] is List) {
          // Estructura anterior anidada: { data: { data: [ ... ] } }
          items = response['data']['data'] as List<dynamic>;
        }
      }
      
      // Convertir a lista de Cliente
      final clientes = items
          .map((item) => Cliente.fromJson(item as Map<String, dynamic>))
          .toList();
      
      debugPrint('ClientesApi: Total de clientes encontrados: ${clientes.length}');
      
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
        );
      }
      
      // Clave para caché
      final cacheKey = 'cliente_$clienteId';
      
      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final cachedData = _cache.get<Cliente>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Cliente obtenido desde caché: $cacheKey');
          return cachedData;
        }
      }
      
      debugPrint('ClientesApi: Obteniendo cliente con ID: $clienteId');
      final response = await _api.authenticatedRequest(
        endpoint: '/clientes/$clienteId',
        method: 'GET',
      );
      
      debugPrint('ClientesApi: Respuesta de getCliente recibida');
      
      // Manejar estructura anidada
      Map<String, dynamic>? data;
      if (response['data'] is Map && response['data'].containsKey('data')) {
        data = response['data']['data'] as Map<String, dynamic>;
      } else {
        data = response['data'] as Map<String, dynamic>;
      }
      
      final cliente = Cliente.fromJson(data);
      
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
  Future<Cliente?> getClienteByDoc(String numeroDocumento, {bool useCache = true}) async {
    try {
      // Validar que numeroDocumento no sea nulo o vacío
      if (numeroDocumento.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'Número de documento no puede estar vacío',
        );
      }
      
      // Clave para caché
      final cacheKey = 'cliente_doc_$numeroDocumento';
      
      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final cachedData = _cache.get<Cliente>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Cliente obtenido desde caché: $cacheKey');
          return cachedData;
        }
      }
      
      debugPrint('ClientesApi: Buscando cliente con documento: $numeroDocumento');
      final response = await _api.authenticatedRequest(
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
      
      final cliente = Cliente.fromJson(data);
      
      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, cliente);
        debugPrint('✅ Cliente guardado en caché: $cacheKey');
      }
      
      return cliente;
    } catch (e) {
      debugPrint('ClientesApi: ERROR al buscar cliente por documento $numeroDocumento: $e');
      
      // Si se produce un error 404, devolver null
      if (e is ApiException && e.statusCode == 404) {
        return null;
      }
      
      rethrow;
    }
  }
  
  /// Crea un nuevo cliente
  Future<Cliente> createCliente(Map<String, dynamic> clienteData) async {
    try {
      // Validar datos mínimos requeridos
      if (!clienteData.containsKey('denominacion') || !clienteData.containsKey('numeroDocumento')) {
        throw ApiException(
          statusCode: 400,
          message: 'Denominación y número de documento son requeridos para crear cliente',
        );
      }
      
      debugPrint('ClientesApi: Creando nuevo cliente: ${clienteData['denominacion']}');
      final response = await _api.authenticatedRequest(
        endpoint: '/clientes',
        method: 'POST',
        body: clienteData,
      );
      
      debugPrint('ClientesApi: Respuesta de createCliente recibida');
      
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
          message: 'Error al crear cliente',
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
  Future<Cliente> updateCliente(String clienteId, Map<String, dynamic> clienteData) async {
    try {
      // Validar que clienteId no sea nulo o vacío
      if (clienteId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de cliente no puede estar vacío',
        );
      }
      
      debugPrint('ClientesApi: Actualizando cliente con ID: $clienteId');
      final response = await _api.authenticatedRequest(
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
    final List<String> parts = [prefix];
    
    if (page != null) parts.add('page=$page');
    if (pageSize != null) parts.add('pageSize=$pageSize');
    if (sortBy != null) parts.add('sort=$sortBy');
    if (order != null) parts.add('order=$order');
    if (search != null) parts.add('search=$search');
    if (filter != null) parts.add('filter=$filter');
    if (filterValue != null) parts.add('filterValue=$filterValue');
    
    return parts.join('_');
  }
}
