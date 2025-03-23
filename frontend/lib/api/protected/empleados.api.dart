import 'package:flutter/foundation.dart';

import '../../models/empleado.model.dart';
import '../main.api.dart';
import 'cache/fast_cache.dart';

class EmpleadosApi {
  final ApiClient _api;
  // Fast Cache para las operaciones de empleados
  final FastCache _cache = FastCache();

  EmpleadosApi(this._api);
  
  /// Obtiene la lista de empleados con soporte de caché
  /// 
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<List<Empleado>> getEmpleados({
    int? page,
    int? pageSize,
    String? sortBy,
    String order = 'asc',
    String? search,
    String? filter,
    String? filterValue,
    bool useCache = true,
  }) async {
    try {
      // Generar clave única para este conjunto de parámetros
      final cacheKey = _generateCacheKey(
        'empleados',
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        order: order,
        search: search,
        filter: filter,
        filterValue: filterValue,
      );
      
      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final cachedData = _cache.get<List<Empleado>>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Empleados obtenidos desde caché: $cacheKey');
          return cachedData;
        }
      }
      
      debugPrint('EmpleadosApi: Obteniendo lista de empleados');
      
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
        endpoint: '/empleados',
        method: 'GET',
        queryParams: queryParams,
      );
      
      debugPrint('EmpleadosApi: Respuesta de getEmpleados recibida');
      
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
      
      // Convertir a lista de Empleado
      final empleados = items
          .map((item) => Empleado.fromJson(item as Map<String, dynamic>))
          .toList();
      
      debugPrint('EmpleadosApi: Total de empleados encontrados: ${empleados.length}');
      
      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, empleados);
        debugPrint('✅ Empleados guardados en caché: $cacheKey');
      }
      
      return empleados;
    } catch (e) {
      debugPrint('EmpleadosApi: ERROR al obtener empleados: $e');
      rethrow;
    }
  }
  
  /// Obtiene un empleado por su ID
  /// 
  /// El ID debe ser un string, aunque represente un número
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<Empleado> getEmpleado(String empleadoId, {bool useCache = true}) async {
    try {
      // Validar que empleadoId no sea nulo o vacío
      if (empleadoId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de empleado no puede estar vacío',
        );
      }
      
      // Clave para caché
      final cacheKey = 'empleado_$empleadoId';
      
      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final cachedData = _cache.get<Empleado>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Empleado obtenido desde caché: $cacheKey');
          return cachedData;
        }
      }
      
      debugPrint('EmpleadosApi: Obteniendo empleado con ID: $empleadoId');
      final response = await _api.authenticatedRequest(
        endpoint: '/empleados/$empleadoId',
        method: 'GET',
      );
      
      debugPrint('EmpleadosApi: Respuesta de getEmpleado recibida');
      
      // Manejar estructura anidada
      Map<String, dynamic>? data;
      if (response['data'] is Map && response['data'].containsKey('data')) {
        data = response['data']['data'] as Map<String, dynamic>;
      } else {
        data = response['data'] as Map<String, dynamic>;
      }
      
      final empleado = Empleado.fromJson(data);
      
      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, empleado);
        debugPrint('✅ Empleado guardado en caché: $cacheKey');
      }
      
      return empleado;
    } catch (e) {
      debugPrint('EmpleadosApi: ERROR al obtener empleado #$empleadoId: $e');
      rethrow;
    }
  }
  
  /// Crea un nuevo empleado
  Future<Empleado> createEmpleado(Map<String, dynamic> empleadoData) async {
    try {
      // Validar datos mínimos requeridos
      if (!empleadoData.containsKey('nombre') || !empleadoData.containsKey('apellidos')) {
        throw ApiException(
          statusCode: 400,
          message: 'Nombre y apellidos son requeridos para crear empleado',
        );
      }
      
      // Formatear las horas correctamente si están presentes
      final Map<String, dynamic> formattedData = Map.from(empleadoData);
      
      // Asegurar que horaInicioJornada tenga el formato correcto (hh:mm:ss)
      if (formattedData.containsKey('horaInicioJornada') && formattedData['horaInicioJornada'] != null) {
        formattedData['horaInicioJornada'] = _formatTimeString(formattedData['horaInicioJornada']);
      }
      
      // Asegurar que horaFinJornada tenga el formato correcto (hh:mm:ss)
      if (formattedData.containsKey('horaFinJornada') && formattedData['horaFinJornada'] != null) {
        formattedData['horaFinJornada'] = _formatTimeString(formattedData['horaFinJornada']);
      }
      
      debugPrint('EmpleadosApi: Creando nuevo empleado: ${formattedData['nombre']} ${formattedData['apellidos']}');
      final response = await _api.authenticatedRequest(
        endpoint: '/empleados',
        method: 'POST',
        body: formattedData,
      );
      
      debugPrint('EmpleadosApi: Respuesta de createEmpleado recibida');
      
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
          message: 'Error al crear empleado',
        );
      }
      
      // Invalidar caché de listas de empleados
      _invalidateListCache();
      
      return Empleado.fromJson(data);
    } catch (e) {
      debugPrint('EmpleadosApi: ERROR al crear empleado: $e');
      rethrow;
    }
  }
  
  /// Actualiza un empleado existente
  /// 
  /// El ID debe ser un string, aunque represente un número
  Future<Empleado> updateEmpleado(String empleadoId, Map<String, dynamic> empleadoData) async {
    try {
      // Validar que empleadoId no sea nulo o vacío
      if (empleadoId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de empleado no puede estar vacío',
        );
      }
      
      debugPrint('EmpleadosApi: Actualizando empleado con ID: $empleadoId');
      
      // Formatear las horas correctamente si están presentes
      final Map<String, dynamic> formattedData = Map.from(empleadoData);
      
      // Asegurar que horaInicioJornada tenga el formato correcto (hh:mm:ss)
      if (formattedData.containsKey('horaInicioJornada') && formattedData['horaInicioJornada'] != null) {
        formattedData['horaInicioJornada'] = _formatTimeString(formattedData['horaInicioJornada']);
      }
      
      // Asegurar que horaFinJornada tenga el formato correcto (hh:mm:ss)
      if (formattedData.containsKey('horaFinJornada') && formattedData['horaFinJornada'] != null) {
        formattedData['horaFinJornada'] = _formatTimeString(formattedData['horaFinJornada']);
      }
      
      // Usar PATCH para actualizar el empleado
      final response = await _api.authenticatedRequest(
        endpoint: '/empleados/$empleadoId',
        method: 'PATCH',
        body: formattedData,
      );
      
      debugPrint('EmpleadosApi: Respuesta de updateEmpleado recibida');
      final data = _processResponse(response);
      
      // Invalidar caché del empleado específico y listas
      _cache.invalidate('empleado_$empleadoId');
      _invalidateListCache();
      
      return Empleado.fromJson(data);
    } catch (e) {
      debugPrint('EmpleadosApi: ERROR al actualizar empleado #$empleadoId: $e');
      rethrow;
    }
  }
  
  /// Formatea una cadena de tiempo para asegurar que tenga el formato hh:mm:ss
  String _formatTimeString(String timeString) {
    // Si ya tiene el formato correcto (hh:mm:ss), devolverlo tal cual
    if (RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(timeString)) {
      return timeString;
    }
    
    // Si tiene el formato hh:mm, agregar :00 para los segundos
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(timeString)) {
      return '$timeString:00';
    }
    
    // Para otros formatos, intentar convertir a hh:mm:ss
    try {
      final parts = timeString.split(':');
      if (parts.length == 1) {
        // Si solo hay horas, agregar minutos y segundos
        return '${parts[0].padLeft(2, '0')}:00:00';
      } else if (parts.length == 2) {
        // Si hay horas y minutos, agregar segundos
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:00';
      }
    } catch (e) {
      debugPrint('EmpleadosApi: Error al formatear hora: $e');
    }
    
    // Si no se puede formatear, devolver el valor original
    return timeString;
  }
  
  /// Elimina un empleado
  /// 
  /// El ID debe ser un string, aunque represente un número
  /// NOTA: Este endpoint está comentado en el servidor actualmente
  Future<void> deleteEmpleado(String empleadoId) async {
    try {
      // Validar que empleadoId no sea nulo o vacío
      if (empleadoId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de empleado no puede estar vacío',
        );
      }
      
      debugPrint('EmpleadosApi: Eliminando empleado con ID: $empleadoId');
      
      // Como el endpoint DELETE está comentado en el servidor,
      // usamos PATCH para desactivar el empleado en su lugar
      await _api.authenticatedRequest(
        endpoint: '/empleados/$empleadoId',
        method: 'PATCH',
        body: {'activo': false},
      );
      
      // Invalidar caché del empleado específico y listas
      _cache.invalidate('empleado_$empleadoId');
      _invalidateListCache();
      
      debugPrint('EmpleadosApi: Empleado desactivado correctamente');
    } catch (e) {
      debugPrint('EmpleadosApi: ERROR al eliminar empleado #$empleadoId: $e');
      rethrow;
    }
  }
  
  /// Método auxiliar para procesar respuestas y manejar estructuras anidadas
  Map<String, dynamic> _processResponse(Map<String, dynamic> response) {
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
        message: 'Error al procesar respuesta del servidor',
      );
    }
    
    return data;
  }
  
  /// Obtiene empleados filtrados por sucursal
  Future<List<Empleado>> getEmpleadosPorSucursal(String sucursalId, {
    int page = 1,
    int pageSize = 10,
    String order = 'asc',
    bool useCache = true,
  }) async {
    return getEmpleados(
      page: page,
      pageSize: pageSize,
      order: order,
      filter: 'sucursalId',
      filterValue: sucursalId,
      useCache: useCache,
    );
  }
  
  /// Obtiene empleados activos
  Future<List<Empleado>> getEmpleadosActivos({
    int page = 1, 
    int pageSize = 10,
    String order = 'asc',
    bool useCache = true,
  }) async {
    return getEmpleados(
      page: page,
      pageSize: pageSize,
      order: order,
      filter: 'activo',
      filterValue: 'true',
      useCache: useCache,
    );
  }

  /// Registra una cuenta para un empleado
  /// 
  /// Crea una nueva cuenta de usuario asociada a un empleado existente
  Future<Map<String, dynamic>> registerEmpleadoAccount({
    required String empleadoId,
    required String usuario,
    required String clave,
    required int rolCuentaEmpleadoId,
  }) async {
    try {
      debugPrint('EmpleadosApi: Registrando cuenta para empleado $empleadoId');
      
      final response = await _api.authenticatedRequest(
        endpoint: '/auth/register',
        method: 'POST',
        body: {
          'empleadoId': empleadoId,
          'usuario': usuario,
          'clave': clave,
          'rolCuentaEmpleadoId': rolCuentaEmpleadoId,
        },
      );
      
      // Procesar la respuesta
      if (response['data'] is Map<String, dynamic>) {
        // Invalidar caché relacionada con cuentas
        _invalidateCacheByPattern('cuentas');
        return response['data'] as Map<String, dynamic>;
      } else {
        throw ApiException(
          statusCode: 500,
          message: 'Formato de respuesta inesperado al registrar cuenta',
        );
      }
      
    } catch (e) {
      debugPrint('EmpleadosApi: ERROR al registrar cuenta de empleado: $e');
      rethrow;
    }
  }
  
  /// Actualiza la cuenta de un empleado (usuario y/o clave)
  /// 
  /// Permite cambiar el nombre de usuario y/o la contraseña de una cuenta existente
  Future<Map<String, dynamic>> updateCuentaEmpleado({
    required String cuentaId,
    String? usuario,
    String? clave,
  }) async {
    // Validar que al menos un campo sea proporcionado
    if (usuario == null && clave == null) {
      throw ApiException(
        statusCode: 400,
        message: 'Debe proporcionar al menos un campo para actualizar',
      );
    }

    final Map<String, dynamic> data = {};
    if (usuario != null) data['usuario'] = usuario;
    if (clave != null) data['clave'] = clave;

    final response = await _api.authenticatedRequest(
      endpoint: '/cuentasempleados/$cuentaId',
      method: 'PATCH',
      body: data,
    );

    // Invalidar caché relacionada con esta cuenta
    _cache.invalidate('cuenta_$cuentaId');
    _invalidateCacheByPattern('cuentas');

    if (response['data'] is Map<String, dynamic>) {
      return response['data'];
    }

    throw ApiException(
      statusCode: 500,
      message: 'Formato de respuesta inesperado',
    );
  }
  
  /// Obtiene la información de la cuenta de un empleado
  /// 
  /// Retorna los detalles de la cuenta asociada a un empleado
  Future<Map<String, dynamic>> getCuentaEmpleado(String cuentaId, {bool useCache = true}) async {
    try {
      final cacheKey = 'cuenta_$cuentaId';
      
      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Cuenta obtenida desde caché: $cacheKey');
          return cachedData;
        }
      }
      
      debugPrint('EmpleadosApi: Obteniendo información de cuenta $cuentaId');
      
      final response = await _api.authenticatedRequest(
        endpoint: '/cuentasempleados/$cuentaId',
        method: 'GET',
      );
      
      final cuenta = _processResponse(response);
      
      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, cuenta);
        debugPrint('✅ Cuenta guardada en caché: $cacheKey');
      }
      
      debugPrint('EmpleadosApi: Información de cuenta obtenida correctamente');
      return cuenta;
    } catch (e) {
      debugPrint('EmpleadosApi: ERROR al obtener información de cuenta: $e');
      rethrow;
    }
  }
  
  /// Obtiene todas las cuentas de empleados
  /// 
  /// Retorna una lista con todas las cuentas de empleados registradas
  Future<List<dynamic>> getCuentasEmpleados({bool useCache = true}) async {
    try {
      final cacheKey = 'cuentas_empleados_todas';
      
      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final cachedData = _cache.get<List<dynamic>>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Cuentas de empleados obtenidas desde caché: $cacheKey');
          return cachedData;
        }
      }
      
      debugPrint('EmpleadosApi: Obteniendo lista de cuentas de empleados');
      
      final response = await _api.authenticatedRequest(
        endpoint: '/cuentasempleados',
        method: 'GET',
      );
      
      // Procesar la respuesta
      List<dynamic> data;
      if (response['data'] is List) {
        data = response['data'];
      } else if (response['data'] is Map && response['data']['data'] is List) {
        data = response['data']['data'];
      } else {
        data = [];
      }
      
      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, data);
        debugPrint('✅ Cuentas de empleados guardadas en caché: $cacheKey');
      }
      
      debugPrint('EmpleadosApi: Total de cuentas encontradas: ${data.length}');
      return data;
    } catch (e) {
      debugPrint('EmpleadosApi: ERROR al obtener cuentas de empleados: $e');
      rethrow;
    }
  }
  
  /// Elimina la cuenta de un empleado
  /// 
  /// Elimina permanentemente una cuenta de usuario
  Future<bool> deleteCuentaEmpleado(String cuentaId) async {
    try {
      debugPrint('EmpleadosApi: Eliminando cuenta de empleado $cuentaId');
      
      await _api.authenticatedRequest(
        endpoint: '/cuentasempleados/$cuentaId',
        method: 'DELETE',
      );
      
      // Invalidar caché relacionada
      _cache.invalidate('cuenta_$cuentaId');
      _invalidateCacheByPattern('cuentas');
      
      debugPrint('EmpleadosApi: Cuenta de empleado eliminada correctamente');
      return true;
    } catch (e) {
      debugPrint('EmpleadosApi: ERROR al eliminar cuenta de empleado: $e');
      return false;
    }
  }

  /// Obtiene los roles disponibles para cuentas de empleados
  Future<List<Map<String, dynamic>>> getRolesCuentas({bool useCache = true}) async {
    try {
      const cacheKey = 'roles_cuentas';
      
      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final cachedData = _cache.get<List<Map<String, dynamic>>>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Roles de cuentas obtenidos desde caché: $cacheKey');
          return cachedData;
        }
      }
      
      final response = await _api.authenticatedRequest(
        endpoint: '/rolescuentas',
        method: 'GET',
      );
      
      List<Map<String, dynamic>> roles = [];
      if (response['data'] is List) {
        roles = (response['data'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        
        // Guardar en caché si useCache es true
        if (useCache) {
          _cache.set(cacheKey, roles);
          debugPrint('✅ Roles de cuentas guardados en caché: $cacheKey');
        }
      }
      
      return roles;
    } catch (e) {
      debugPrint('Error al obtener roles de cuentas: $e');
      return [];
    }
  }

  /// Obtiene la cuenta de un empleado por su ID
  Future<Map<String, dynamic>?> getCuentaByEmpleadoId(String empleadoId, {bool useCache = true}) async {
    try {
      final cacheKey = 'cuenta_empleado_$empleadoId';
      
      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ Cuenta por empleado obtenida desde caché: $cacheKey');
          return cachedData;
        }
      }
      
      // Añadir headers especiales para evitar que el token sea renovado automáticamente
      // si es un 401 específico de "no encontrado"
      final response = await _api.authenticatedRequest(
        endpoint: '/cuentasempleados/empleado/$empleadoId',
        method: 'GET',
        headers: {'x-no-retry-on-401': 'true'}, // Header especial para evitar renovación automática
      );
      
      if (response['data'] is Map<String, dynamic>) {
        final cuenta = response['data'] as Map<String, dynamic>;
        
        // Guardar en caché si useCache es true
        if (useCache) {
          _cache.set(cacheKey, cuenta);
          debugPrint('✅ Cuenta por empleado guardada en caché: $cacheKey');
        }
        
        return cuenta;
      }
      
      return null;
    } catch (e) {
      // Si el error es 404, o el mensaje contiene indicaciones de "no encontrado"
      // independientemente del código, manejarlo como "cuenta no encontrada"
      if (e is ApiException && (e.statusCode == 404 || 
          (e.message.toLowerCase().contains('not found') || 
           e.message.toLowerCase().contains('no encontrado') ||
           e.message.toLowerCase().contains('no existe')))) {
        debugPrint('EmpleadosApi: El empleado $empleadoId no tiene cuenta asociada (${e.statusCode})');
        // En lugar de devolver null, lanzamos una excepción específica para este caso
        throw ApiException(
          statusCode: 404, // Usar 404 para representar "no encontrado"
          message: 'El empleado no tiene cuenta asociada',
          errorCode: ApiException.errorNotFound,
        );
      } 
      
      // Para otros errores, propagar la excepción
      debugPrint('EmpleadosApi: ERROR al obtener cuenta por empleado: $e');
      rethrow;
    }
  }
  
  /// Método helper para generar claves de caché consistentes
  String _generateCacheKey(
    String base, {
    int? page,
    int? pageSize,
    String? sortBy,
    String? order,
    String? search,
    String? filter,
    String? filterValue,
  }) {
    final List<String> components = [base];
    
    if (page != null) components.add('p:$page');
    if (pageSize != null) components.add('ps:$pageSize');
    if (sortBy != null && sortBy.isNotEmpty) components.add('sb:$sortBy');
    if (order != null && order != 'asc') components.add('o:$order');
    if (search != null && search.isNotEmpty) components.add('s:$search');
    if (filter != null && filter.isNotEmpty) components.add('f:$filter');
    if (filterValue != null) components.add('fv:$filterValue');
    
    return components.join('_');
  }
  
  /// Invalida las caches relacionadas con listas de empleados
  void _invalidateListCache() {
    _invalidateCacheByPattern('empleados');
  }
  
  /// Invalida caché por patrón de clave
  void _invalidateCacheByPattern(String pattern) {
    _cache.invalidateByPattern(pattern);
    debugPrint('✅ Caché invalidada para patrón: $pattern');
  }
  
  /// Método público para forzar refresco de caché
  void invalidateCache([String? empleadoId]) {
    if (empleadoId != null) {
      // Invalidar caché específica para este empleado
      _cache.invalidate('empleado_$empleadoId');
      _cache.invalidate('cuenta_empleado_$empleadoId');
      debugPrint('✅ Caché invalidada para empleado: $empleadoId');
    } else {
      // Invalidar toda la caché relacionada con empleados
      _cache.clear();
      debugPrint('✅ Caché completamente invalidada');
    }
  }
  
  /// Método para verificar si los datos en caché están obsoletos
  bool isCacheStale(String cacheKey) {
    return _cache.isStale(cacheKey);
  }
}
