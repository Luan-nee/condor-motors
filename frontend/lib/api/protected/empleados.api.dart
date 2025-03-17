import '../main.api.dart';
import 'package:flutter/foundation.dart';

/// Modelo para representar un empleado
class Empleado {
  final String id;
  final String nombre;
  final String apellidos;
  final String? ubicacionFoto;
  final int? edad;
  final String? dni;
  final String? horaInicioJornada;
  final String? horaFinJornada;
  final String? fechaContratacion;
  final double? sueldo;
  final String? fechaRegistro;
  final String? sucursalId;
  final bool activo;

  Empleado({
    required this.id,
    required this.nombre,
    required this.apellidos,
    this.ubicacionFoto,
    this.edad,
    this.dni,
    this.horaInicioJornada,
    this.horaFinJornada,
    this.fechaContratacion,
    this.sueldo,
    this.fechaRegistro,
    this.sucursalId,
    this.activo = true,
  });

  factory Empleado.fromJson(Map<String, dynamic> json) {
    return Empleado(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
      ubicacionFoto: json['ubicacionFoto'],
      edad: json['edad'],
      dni: json['dni'],
      horaInicioJornada: json['horaInicioJornada'],
      horaFinJornada: json['horaFinJornada'],
      fechaContratacion: json['fechaContratacion'],
      sueldo: json['sueldo'] != null ? double.parse(json['sueldo'].toString()) : null,
      fechaRegistro: json['fechaRegistro'],
      sucursalId: json['sucursalId']?.toString(),
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'apellidos': apellidos,
      'ubicacionFoto': ubicacionFoto,
      'edad': edad,
      'dni': dni,
      'horaInicioJornada': horaInicioJornada,
      'horaFinJornada': horaFinJornada,
      'fechaContratacion': fechaContratacion,
      'sueldo': sueldo,
      'sucursalId': sucursalId,
      'activo': activo,
    };
  }
  
  @override
  String toString() {
    return 'Empleado{id: $id, nombre: $nombre $apellidos, activo: $activo}';
  }
}

/// Modelo para la respuesta paginada
class EmpleadosPaginados {
  final List<Empleado> empleados;
  final Map<String, dynamic> paginacion;

  EmpleadosPaginados({
    required this.empleados,
    required this.paginacion,
  });
}

class EmpleadosApi {
  final ApiClient _api;

  EmpleadosApi(this._api);

  /// Obtiene todos los empleados con soporte para paginación y ordenación
  /// 
  /// Parámetros:
  /// - page: Número de página (comienza en 1)
  /// - pageSize: Número de registros por página
  /// - sortBy: Campo para ordenar (ej: 'nombre', 'fechaRegistro')
  /// - order: Dirección de ordenación ('asc' o 'desc')
  /// - search: Término de búsqueda
  /// - filter: Campo para filtrar (ej: 'sucursalId')
  /// - filterValue: Valor del filtro
  Future<List<dynamic>> getEmpleados({
    int page = 1,
    int pageSize = 10,
    String? sortBy,
    String order = 'asc',
    String? search,
    String? filter,
    String? filterValue,
  }) async {
    try {
      debugPrint('EmpleadosApi: Obteniendo lista de empleados');
      
      // Construir parámetros de consulta
      final Map<String, String> queryParams = {};
      
      if (page > 0) {
        queryParams['page'] = page.toString();
      }
      
      if (pageSize > 0) {
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
      
      final response = await _api.authenticatedRequest(
        endpoint: '/empleados',
        method: 'GET',
        queryParams: queryParams,
      );
      
      debugPrint('EmpleadosApi: Respuesta de getEmpleados recibida');
      debugPrint('EmpleadosApi: Estructura de respuesta: ${response.keys.toList()}');
      
      // Manejar estructura anidada: response.data.data
      if (response['data'] is Map && response['data'].containsKey('data')) {
        debugPrint('EmpleadosApi: Encontrada estructura anidada en la respuesta');
        final items = response['data']['data'] ?? [];
        debugPrint('EmpleadosApi: Total de empleados encontrados: ${items.length}');
        return items;
      }
      
      // Si la estructura cambia en el futuro y ya no está anidada
      debugPrint('EmpleadosApi: Usando estructura directa de respuesta');
      final items = response['data'] ?? [];
      debugPrint('EmpleadosApi: Total de empleados encontrados: ${items.length}');
      return items;
    } catch (e) {
      debugPrint('EmpleadosApi: ERROR al obtener empleados: $e');
      rethrow;
    }
  }
  
  /// Obtiene un empleado por su ID
  /// 
  /// El ID debe ser un string, aunque represente un número
  Future<Map<String, dynamic>> getEmpleado(String empleadoId) async {
    try {
      // Validar que empleadoId no sea nulo o vacío
      if (empleadoId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de empleado no puede estar vacío',
        );
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
        data = response['data']['data'];
      } else {
        data = response['data'];
      }
      
      if (data == null) {
        throw ApiException(
          statusCode: 404,
          message: 'Empleado no encontrado',
        );
      }
      
      return data;
    } catch (e) {
      debugPrint('EmpleadosApi: ERROR al obtener empleado #$empleadoId: $e');
      rethrow;
    }
  }
  
  /// Crea un nuevo empleado
  Future<Map<String, dynamic>> createEmpleado(Map<String, dynamic> empleadoData) async {
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
      
      return data;
    } catch (e) {
      debugPrint('EmpleadosApi: ERROR al crear empleado: $e');
      rethrow;
    }
  }
  
  /// Actualiza un empleado existente
  /// 
  /// El ID debe ser un string, aunque represente un número
  Future<Map<String, dynamic>> updateEmpleado(String empleadoId, Map<String, dynamic> empleadoData) async {
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
      return _processResponse(response);
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
  Future<List<dynamic>> getEmpleadosPorSucursal(String sucursalId, {
    int page = 1,
    int pageSize = 10,
    String order = 'asc',
  }) async {
    return getEmpleados(
      page: page,
      pageSize: pageSize,
      order: order,
      filter: 'sucursalId',
      filterValue: sucursalId,
    );
  }
  
  /// Obtiene empleados activos
  Future<List<dynamic>> getEmpleadosActivos({
    int page = 1, 
    int pageSize = 10,
    String order = 'asc',
  }) async {
    return getEmpleados(
      page: page,
      pageSize: pageSize,
      order: order,
      filter: 'activo',
      filterValue: 'true',
    );
  }
}
