import 'dart:io';

import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/cache/fast_cache.dart';
import 'package:condorsmotors/api/protected/paginacion.api.dart';
import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class EmpleadosApi {
  final ApiClient _api;
  // Fast Cache para las operaciones de empleados
  final FastCache _cache = FastCache();

  EmpleadosApi(this._api);

  /// Obtiene la lista de empleados con soporte de caché
  ///
  /// [useCache] Indica si se debe usar el caché (default: true)
  /// Retorna un objeto [EmpleadosPaginados] que contiene la lista de empleados, la información de paginación y las opciones de ordenamiento
  Future<EmpleadosPaginados> getEmpleados({
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
      final filtroParams = FiltroParams(
        page: page ?? 1,
        pageSize: pageSize ?? 20,
        sortBy: sortBy,
        order: order,
        search: search,
        filter: filter,
        filterValue: filterValue,
      );
      final String cacheKey =
          PaginacionUtils.generateCacheKey('empleados', filtroParams.toMap());

      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final EmpleadosPaginados? cachedData =
            _cache.get<EmpleadosPaginados>(cacheKey);
        if (cachedData != null) {
          logCache('Empleados paginados obtenidos desde caché: $cacheKey');
          return cachedData;
        }
      }

      Logger.debug('Obteniendo lista de empleados');

      // Construir parámetros de consulta
      final Map<String, String> queryParams = filtroParams.buildQueryParams();

      // Usar authenticatedRequest en lugar de request para manejar automáticamente tokens
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/empleados',
        method: 'GET',
        queryParams: queryParams,
      );

      Logger.debug('Respuesta de getEmpleados recibida');

      // Crear objeto EmpleadosPaginados directamente de la respuesta
      final EmpleadosPaginados empleadosPaginados =
          EmpleadosPaginados.fromJson(response);

      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, empleadosPaginados);
        logCache('Empleados paginados guardados en caché: $cacheKey');
      }

      Logger.debug(
          'Total de empleados encontrados: ${empleadosPaginados.empleados.length}');

      if (empleadosPaginados.sortByOptions.isNotEmpty) {
        Logger.debug(
            'Opciones de ordenamiento disponibles: ${empleadosPaginados.sortByOptions.join(', ')}');
      }

      return empleadosPaginados;
    } catch (e) {
      Logger.error('ERROR al obtener empleados: $e');
      rethrow;
    }
  }

  /// Obtiene un empleado por su ID
  ///
  /// El ID debe ser un string, aunque represente un número
  /// [useCache] Indica si se debe usar el caché (default: true)
  Future<Empleado> getEmpleado(String empleadoId,
      {bool useCache = true}) async {
    try {
      // Validar que empleadoId no sea nulo o vacío
      if (empleadoId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de empleado no puede estar vacío',
          errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
        );
      }

      // Clave para caché
      final String cacheKey = 'empleado_$empleadoId';

      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final Empleado? cachedData = _cache.get<Empleado>(cacheKey);
        if (cachedData != null) {
          logCache('Empleado obtenido desde caché: $cacheKey');
          return cachedData;
        }
      }

      Logger.debug('Obteniendo empleado con ID: $empleadoId');
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/empleados/$empleadoId',
        method: 'GET',
      );

      Logger.debug('Respuesta de getEmpleado recibida');

      // Manejar estructura anidada
      Map<String, dynamic>? data;
      if (response['data'] is Map<String, dynamic> &&
          (response['data'] as Map<String, dynamic>).containsKey('data')) {
        data = (response['data'] as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
      } else {
        data = response['data'] as Map<String, dynamic>;
      }

      final Empleado empleado = Empleado.fromJson(data);

      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, empleado);
        logCache('Empleado guardado en caché: $cacheKey');
      }

      return empleado;
    } catch (e) {
      Logger.error('ERROR al obtener empleado #$empleadoId: $e');
      rethrow;
    }
  }

  /// Crea un nuevo empleado
  Future<Empleado> createEmpleado(Map<String, dynamic> empleadoData,
      {File? fotoFile}) async {
    try {
      // Validar datos mínimos requeridos
      if (!empleadoData.containsKey('nombre') ||
          !empleadoData.containsKey('apellidos')) {
        throw ApiException(
          statusCode: 400,
          message: 'Nombre y apellidos son requeridos para crear empleado',
          errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
        );
      }

      final Map<String, dynamic> formattedData = Map.from(empleadoData);

      // Asegurar que horaInicioJornada tenga el formato correcto (hh:mm:ss)
      if (formattedData.containsKey('horaInicioJornada') &&
          formattedData['horaInicioJornada'] != null) {
        formattedData['horaInicioJornada'] =
            _formatTimeString(formattedData['horaInicioJornada']);
      }

      // Asegurar que horaFinJornada tenga el formato correcto (hh:mm:ss)
      if (formattedData.containsKey('horaFinJornada') &&
          formattedData['horaFinJornada'] != null) {
        formattedData['horaFinJornada'] =
            _formatTimeString(formattedData['horaFinJornada']);
      }

      dynamic bodyToSend;
      Options? options;
      if (fotoFile != null) {
        final String fileName =
            fotoFile.path.split(Platform.pathSeparator).last;
        final String fileExtension = fileName.contains('.')
            ? fileName.split('.').last.toLowerCase()
            : '';
        final int fileSize = await fotoFile.length();
        Logger.debug('[empleados.api] Imagen a enviar:');
        Logger.debug('  Path: \\${fotoFile.path}');
        Logger.debug('  Nombre: $fileName');
        Logger.debug('  Extensión: $fileExtension');
        Logger.debug('  Tamaño: $fileSize bytes');
        // Forzar el tipo MIME correcto
        String mimeType = 'jpeg';
        switch (fileExtension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'jpeg';
            break;
          case 'png':
            mimeType = 'png';
            break;
          case 'webp':
            mimeType = 'webp';
            break;
          default:
            mimeType = 'jpeg';
        }
        // Convertir 'activo' a string si existe
        if (formattedData.containsKey('activo')) {
          formattedData['activo'] =
              formattedData['activo'] == true ? 'true' : 'false';
        }
        final formData = FormData.fromMap({
          ...formattedData,
          'foto': await MultipartFile.fromFile(
            fotoFile.path,
            filename: fileName,
            contentType: MediaType('image', mimeType),
          ),
        });
        Logger.debug('[empleados.api] FormData campos: ${formattedData.keys}');
        Logger.debug(
            '[empleados.api] Archivo: ${fotoFile.path.split(Platform.pathSeparator).last}');
        bodyToSend = formData;
        options = Options(contentType: 'multipart/form-data');
      } else {
        bodyToSend = formattedData;
      }

      Logger.debug(
          'Creando nuevo empleado: ${formattedData['nombre']} ${formattedData['apellidos']}');
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/empleados',
        method: 'POST',
        body: bodyToSend,
        headers: options?.headers?.cast<String, String>(),
      );

      Logger.debug('Respuesta de createEmpleado recibida');
      Logger.debug(response['data'].toString());

      // Manejar estructura anidada
      Map<String, dynamic>? data;
      if (response['data'] is Map<String, dynamic> &&
          (response['data'] as Map<String, dynamic>).containsKey('data')) {
        data = (response['data'] as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
      } else if (response['data'] is Map<String, dynamic>) {
        data = response['data'] as Map<String, dynamic>;
      } else if (response['data'] is List<dynamic> &&
          (response['data'] as List<dynamic>).isNotEmpty) {
        data = (response['data'] as List<dynamic>)[0] as Map<String, dynamic>;
      } else {
        data = null;
      }

      Logger.debug('terminó con el manejar estructura anidada');

      if (data == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Error al crear empleado',
          errorCode: ApiConstants.errorCodes[500] ?? ApiConstants.unknownError,
        );
      }

      _invalidateListCache();

      Logger.debug('está a punto de retornar el empleado creado');
      return Empleado.fromJson(data);
    } catch (e) {
      Logger.error('ERROR al crear empleado: $e');
      rethrow;
    }
  }

  /// Actualiza un empleado existente
  ///
  /// El ID debe ser un string, aunque represente un número
  Future<Empleado> updateEmpleado(
      String empleadoId, Map<String, dynamic> empleadoData,
      {File? fotoFile}) async {
    try {
      if (empleadoId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de empleado no puede estar vacío',
          errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
        );
      }

      Logger.debug('Actualizando empleado con ID: $empleadoId');

      final Map<String, dynamic> formattedData = Map.from(empleadoData);

      if (formattedData.containsKey('horaInicioJornada') &&
          formattedData['horaInicioJornada'] != null) {
        formattedData['horaInicioJornada'] =
            _formatTimeString(formattedData['horaInicioJornada']);
      }

      if (formattedData.containsKey('horaFinJornada') &&
          formattedData['horaFinJornada'] != null) {
        formattedData['horaFinJornada'] =
            _formatTimeString(formattedData['horaFinJornada']);
      }

      dynamic bodyToSend;
      Options? options;
      if (fotoFile != null) {
        final String fileName =
            fotoFile.path.split(Platform.pathSeparator).last;
        final String fileExtension = fileName.contains('.')
            ? fileName.split('.').last.toLowerCase()
            : '';
        final int fileSize = await fotoFile.length();
        Logger.debug('[empleados.api] Imagen a enviar:');
        Logger.debug('  Path: \\${fotoFile.path}');
        Logger.debug('  Nombre: $fileName');
        Logger.debug('  Extensión: $fileExtension');
        Logger.debug('  Tamaño: $fileSize bytes');
        // Forzar el tipo MIME correcto
        String mimeType = 'jpeg';
        switch (fileExtension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'jpeg';
            break;
          case 'png':
            mimeType = 'png';
            break;
          case 'webp':
            mimeType = 'webp';
            break;
          default:
            mimeType = 'jpeg';
        }
        // Convertir 'activo' a string si existe
        if (formattedData.containsKey('activo')) {
          formattedData['activo'] =
              formattedData['activo'] == true ? 'true' : 'false';
        }
        final formData = FormData.fromMap({
          ...formattedData,
          'foto': await MultipartFile.fromFile(
            fotoFile.path,
            filename: fileName,
            contentType: MediaType('image', mimeType),
          ),
        });
        Logger.debug('[empleados.api] FormData campos: ${formattedData.keys}');
        Logger.debug(
            '[empleados.api] Archivo: ${fotoFile.path.split(Platform.pathSeparator).last}');
        bodyToSend = formData;
        options = Options(contentType: 'multipart/form-data');
      } else {
        bodyToSend = formattedData;
      }

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/empleados/$empleadoId',
        method: 'PATCH',
        body: bodyToSend,
        headers: options?.headers?.cast<String, String>(),
      );

      Logger.debug('Respuesta de updateEmpleado recibida');
      final Map<String, dynamic> data = _processResponse(response);

      _cache.invalidate('empleado_$empleadoId');
      _invalidateListCache();

      return Empleado.fromJson(data);
    } catch (e) {
      Logger.error('ERROR al actualizar empleado #$empleadoId: $e');
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
      final List<String> parts = timeString.split(':');
      if (parts.length == 1) {
        // Si solo hay horas, agregar minutos y segundos
        return '${parts[0].padLeft(2, '0')}:00:00';
      } else if (parts.length == 2) {
        // Si hay horas y minutos, agregar segundos
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:00';
      }
    } catch (e) {
      Logger.warn('Error al formatear hora: $e');
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
          errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
        );
      }

      Logger.debug('Eliminando empleado con ID: $empleadoId');

      // Como el endpoint DELETE está comentado en el servidor,
      // usamos PATCH para desactivar el empleado en su lugar
      await _api.authenticatedRequest(
        endpoint: '/empleados/$empleadoId',
        method: 'PATCH',
        body: <String, dynamic>{'activo': false},
      );

      // Invalidar caché del empleado específico y listas
      _cache.invalidate('empleado_$empleadoId');
      _invalidateListCache();

      Logger.info('Empleado desactivado correctamente');
    } catch (e) {
      Logger.error('ERROR al eliminar empleado #$empleadoId: $e');
      rethrow;
    }
  }

  /// Método auxiliar para procesar respuestas y manejar estructuras anidadas
  Map<String, dynamic> _processResponse(Map<String, dynamic> response) {
    // Manejar estructura anidada
    Map<String, dynamic>? data;
    if (response['data'] is Map<String, dynamic> &&
        (response['data'] as Map<String, dynamic>).containsKey('data')) {
      data = (response['data'] as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
    } else {
      data = response['data'] as Map<String, dynamic>;
    }
    return data;
  }

  /// Obtiene empleados filtrados por sucursal
  Future<EmpleadosPaginados> getEmpleadosPorSucursal(
    String sucursalId, {
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
  Future<EmpleadosPaginados> getEmpleadosActivos({
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
      Logger.debug('Registrando cuenta para empleado $empleadoId');

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/cuentasempleados',
        method: 'POST',
        body: <String, dynamic>{
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
          errorCode: ApiConstants.errorCodes[500] ?? ApiConstants.unknownError,
        );
      }
    } catch (e) {
      Logger.error('ERROR al registrar cuenta de empleado: $e');
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
        errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
      );
    }

    final Map<String, dynamic> data = <String, dynamic>{};
    if (usuario != null) {
      data['usuario'] = usuario;
    }
    if (clave != null) {
      data['clave'] = clave;
    }

    final Map<String, dynamic> response = await _api.authenticatedRequest(
      endpoint: '/cuentasempleados/$cuentaId',
      method: 'PATCH',
      body: data,
    );

    // Invalidar caché relacionada con esta cuenta
    _cache.invalidate('cuenta_$cuentaId');
    _invalidateCacheByPattern('cuentas');

    if (response['data'] is Map<String, dynamic>) {
      return response['data'] as Map<String, dynamic>;
    }

    throw ApiException(
      statusCode: 500,
      message: 'Formato de respuesta inesperado',
      errorCode: ApiConstants.errorCodes[500] ?? ApiConstants.unknownError,
    );
  }

  /// Obtiene la información de la cuenta de un empleado
  ///
  /// Retorna los detalles de la cuenta asociada a un empleado
  Future<Map<String, dynamic>> getCuentaEmpleado(String cuentaId,
      {bool useCache = true}) async {
    try {
      final String cacheKey = 'cuenta_$cuentaId';

      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final Map<String, dynamic>? cachedData =
            _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null) {
          logCache('Cuenta obtenida desde caché: $cacheKey');
          return cachedData;
        }
      }

      Logger.debug('Obteniendo información de cuenta $cuentaId');

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/cuentasempleados/$cuentaId',
        method: 'GET',
      );

      final Map<String, dynamic> cuenta = _processResponse(response);

      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, cuenta);
        logCache('Cuenta guardada en caché: $cacheKey');
      }

      Logger.debug('Información de cuenta obtenida correctamente');
      return cuenta;
    } catch (e) {
      Logger.error('ERROR al obtener información de cuenta: $e');
      rethrow;
    }
  }

  /// Obtiene todas las cuentas de empleados
  ///
  /// Retorna una lista con todas las cuentas de empleados registradas
  Future<List<dynamic>> getCuentasEmpleados({bool useCache = true}) async {
    try {
      const String cacheKey = 'cuentas_empleados_todas';

      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final List? cachedData = _cache.get<List<dynamic>>(cacheKey);
        if (cachedData != null) {
          logCache('Cuentas de empleados obtenidas desde caché: $cacheKey');
          return cachedData;
        }
      }

      Logger.debug('Obteniendo lista de cuentas de empleados');

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/cuentasempleados',
        method: 'GET',
      );

      // Procesar la respuesta
      List<dynamic> data;
      if (response['data'] is List<dynamic>) {
        data = response['data'] as List<dynamic>;
      } else if (response['data'] is Map<String, dynamic> &&
          (response['data'] as Map<String, dynamic>)['data'] is List<dynamic>) {
        data =
            (response['data'] as Map<String, dynamic>)['data'] as List<dynamic>;
      } else {
        data = <dynamic>[];
      }

      // Guardar en caché si useCache es true
      if (useCache) {
        _cache.set(cacheKey, data);
        logCache('Cuentas de empleados guardadas en caché: $cacheKey');
      }

      Logger.debug('Total de cuentas encontradas: ${data.length}');
      return data;
    } catch (e) {
      Logger.error('ERROR al obtener cuentas de empleados: $e');
      rethrow;
    }
  }

  /// Elimina la cuenta de un empleado
  ///
  /// Elimina permanentemente una cuenta de usuario
  Future<bool> deleteCuentaEmpleado(String cuentaId) async {
    try {
      Logger.debug('Eliminando cuenta de empleado $cuentaId');

      await _api.authenticatedRequest(
        endpoint: '/cuentasempleados/$cuentaId',
        method: 'DELETE',
      );

      // Invalidar caché relacionada
      _cache.invalidate('cuenta_$cuentaId');
      _invalidateCacheByPattern('cuentas');

      Logger.info('Cuenta de empleado eliminada correctamente');
      return true;
    } catch (e) {
      Logger.error('ERROR al eliminar cuenta de empleado: $e');
      return false;
    }
  }

  /// Obtiene los roles disponibles para cuentas de empleados
  Future<List<Map<String, dynamic>>> getRolesCuentas(
      {bool useCache = true}) async {
    try {
      const String cacheKey = 'roles_cuentas';

      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final List<Map<String, dynamic>>? cachedData =
            _cache.get<List<Map<String, dynamic>>>(cacheKey);
        if (cachedData != null) {
          logCache('Roles de cuentas obtenidos desde caché: $cacheKey');
          return cachedData;
        }
      }

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/rolescuentas',
        method: 'GET',
      );

      List<Map<String, dynamic>> roles = <Map<String, dynamic>>[];
      if (response['data'] is List<dynamic>) {
        roles = (response['data'] as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();

        // Guardar en caché si useCache es true
        if (useCache) {
          _cache.set(cacheKey, roles);
          logCache('Roles de cuentas guardados en caché: $cacheKey');
        }
      }

      return roles;
    } catch (e) {
      Logger.error('Error al obtener roles de cuentas: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// Obtiene la cuenta de un empleado por su ID
  Future<Map<String, dynamic>?> getCuentaByEmpleadoId(String empleadoId,
      {bool useCache = true}) async {
    try {
      final String cacheKey = 'cuenta_empleado_$empleadoId';

      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final Map<String, dynamic>? cachedData =
            _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null) {
          logCache('Cuenta por empleado obtenida desde caché: $cacheKey');
          return cachedData;
        }
      }

      // Añadir headers especiales para evitar que el token sea renovado automáticamente
      // si es un 401 específico de "no encontrado"
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/cuentasempleados/empleado/$empleadoId',
        method: 'GET',
        headers: <String, String>{
          'x-no-retry-on-401': 'true'
        }, // Header especial para evitar renovación automática
      );

      if (response['data'] is Map<String, dynamic>) {
        final Map<String, dynamic> cuenta =
            response['data'] as Map<String, dynamic>;

        // Guardar en caché si useCache es true
        if (useCache) {
          _cache.set(cacheKey, cuenta);
          logCache('Cuenta por empleado guardada en caché: $cacheKey');
        }

        return cuenta;
      }

      return null;
    } catch (e) {
      // Si el error es 404, o el mensaje contiene indicaciones de "no encontrado"
      // independientemente del código, manejarlo como "cuenta no encontrada"
      if (e is ApiException &&
          (e.statusCode == 404 ||
              (e.message.toLowerCase().contains('not found') ||
                  e.message.toLowerCase().contains('no encontrado') ||
                  e.message.toLowerCase().contains('no existe')))) {
        Logger.warn(
            'El empleado $empleadoId no tiene cuenta asociada (${e.statusCode})');
        // En lugar de devolver null, lanzamos una excepción específica para este caso
        throw ApiException(
          statusCode: 404, // Usar 404 para representar "no encontrado"
          message: 'El empleado no tiene cuenta asociada',
          errorCode: ApiConstants.errorCodes[404] ?? ApiConstants.unknownError,
        );
      }

      // Para otros errores, propagar la excepción
      Logger.error('ERROR al obtener cuenta por empleado: $e');
      rethrow;
    }
  }

  /// Invalida las caches relacionadas con listas de empleados
  void _invalidateListCache() {
    _invalidateCacheByPattern('empleados');
  }

  /// Invalida caché por patrón de clave
  void _invalidateCacheByPattern(String pattern) {
    _cache.invalidateByPattern(pattern);
    logCache('Caché invalidada para patrón: $pattern');
  }

  /// Método público para forzar refresco de caché
  void invalidateCache([String? empleadoId]) {
    if (empleadoId != null) {
      // Invalidar caché específica para este empleado
      _cache
        ..invalidate('empleado_$empleadoId')
        ..invalidate('cuenta_empleado_$empleadoId');
      logCache('Caché invalidada para empleado: $empleadoId');
    } else {
      // Invalidar toda la caché relacionada con empleados
      _cache.clear();
      logCache('Caché completamente invalidada');
    }
  }

  /// Método para verificar si los datos en caché están obsoletos
  bool isCacheStale(String cacheKey) {
    return _cache.isStale(cacheKey);
  }

  /// Obtiene las opciones de ordenamiento disponibles para empleados
  Future<List<String>> getSortByOptions({bool useCache = true}) async {
    try {
      const String cacheKey = 'empleados_sort_options';

      // Intentar obtener desde caché si useCache es true
      if (useCache) {
        final List<String>? cachedData = _cache.get<List<String>>(cacheKey);
        if (cachedData != null) {
          logCache('Opciones de ordenamiento obtenidas desde caché: $cacheKey');
          return cachedData;
        }
      }

      // Si no hay datos en caché, realizar una consulta para obtener metadatos
      final EmpleadosPaginados empleadosPaginados = await getEmpleados(
        page: 1,
        pageSize: 1, // Solo necesitamos un elemento para obtener los metadatos
        useCache: false, // No usar caché para esta consulta específica
      );

      final List<String> sortByOptions = empleadosPaginados.sortByOptions;

      // Guardar en caché si useCache es true
      if (useCache && sortByOptions.isNotEmpty) {
        _cache.set(cacheKey, sortByOptions);
        logCache('Opciones de ordenamiento guardadas en caché: $cacheKey');
      }

      return sortByOptions;
    } catch (e) {
      Logger.error('ERROR al obtener opciones de ordenamiento: $e');
      // Devolver una lista predeterminada en caso de error
      return <String>['fechaCreacion', 'nombre', 'apellidos'];
    }
  }
}
