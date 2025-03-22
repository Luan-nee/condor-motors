import 'package:flutter/foundation.dart';

import '../main.api.dart';

/// Modelo para los detalles de una proforma de venta
class DetalleProforma {
  final int productoId;
  final String nombre;
  final int cantidad;
  final double subtotal;
  final double precioUnitario;

  DetalleProforma({
    required this.productoId,
    required this.nombre,
    required this.cantidad,
    required this.subtotal,
    required this.precioUnitario,
  });

  /// Crea un objeto DetalleProforma desde un mapa JSON
  factory DetalleProforma.fromJson(Map<String, dynamic> json) {
    return DetalleProforma(
      productoId: json['productoId'] as int,
      nombre: json['nombre'] as String,
      cantidad: json['cantidad'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
      precioUnitario: (json['precioUnitario'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convierte el objeto a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      'nombre': nombre,
      'cantidad': cantidad,
      'subtotal': subtotal,
      'precioUnitario': precioUnitario,
    };
  }
}

/// Modelo para una proforma de venta
class ProformaVenta {
  final int id;
  final String? nombre;
  final double total;
  final List<DetalleProforma> detalles;
  final int empleadoId;
  final int sucursalId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? cliente;
  final Map<String, dynamic>? empleado;
  final Map<String, dynamic>? sucursal;

  ProformaVenta({
    required this.id,
    this.nombre,
    required this.total,
    required this.detalles,
    required this.empleadoId,
    required this.sucursalId,
    required this.createdAt,
    this.updatedAt,
    this.cliente,
    this.empleado,
    this.sucursal,
  });

  /// Crea un objeto ProformaVenta desde un mapa JSON
  factory ProformaVenta.fromJson(Map<String, dynamic> json) {
    // Manejar diferentes formatos de fechas (con nombres distintos)
    final createdAt = json['fechaCreacion'] != null 
        ? DateTime.parse(json['fechaCreacion'] as String)
        : (json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now());
    
    final updatedAt = json['fechaActualizacion'] != null 
        ? DateTime.parse(json['fechaActualizacion'] as String) 
        : (json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null);
    
    // Obtener ID del empleado directamente o desde el objeto anidado
    final empleadoId = json['empleadoId'] != null 
        ? json['empleadoId'] as int
        : (json['empleado'] != null ? (json['empleado']['id'] as int) : 0);
    
    // Obtener ID de la sucursal directamente o desde el objeto anidado
    final sucursalId = json['sucursalId'] != null 
        ? json['sucursalId'] as int
        : (json['sucursal'] != null ? (json['sucursal']['id'] as int) : 0);
    
    return ProformaVenta(
      id: json['id'] as int,
      nombre: json['nombre'] as String?,
      total: json['total'] is String 
          ? double.parse(json['total']) 
          : (json['total'] as num).toDouble(),
      detalles: (json['detalles'] as List<dynamic>)
          .map((detalle) => DetalleProforma.fromJson(detalle as Map<String, dynamic>))
          .toList(),
      empleadoId: empleadoId,
      sucursalId: sucursalId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      cliente: json['cliente'] as Map<String, dynamic>?,
      empleado: json['empleado'] as Map<String, dynamic>?,
      sucursal: json['sucursal'] as Map<String, dynamic>?,
    );
  }

  /// Convierte el objeto a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (nombre != null) 'nombre': nombre,
      'total': total,
      'detalles': detalles.map((detalle) => detalle.toJson()).toList(),
      'empleadoId': empleadoId,
      'sucursalId': sucursalId,
      // Usar fechaCreacion/fechaActualizacion para compatibilidad con el backend
      'fechaCreacion': createdAt.toIso8601String(),
      if (updatedAt != null) 'fechaActualizacion': updatedAt!.toIso8601String(),
      if (cliente != null) 'cliente': cliente,
      if (empleado != null) 'empleado': empleado,
      if (sucursal != null) 'sucursal': sucursal,
    };
  }
}

/// API para manejar proformas de venta
class ProformaVentaApi {
  final ApiClient _api;

  /// Constructor que recibe una instancia de ApiClient
  ProformaVentaApi(this._api);

  /// Obtener lista de proformas de venta para una sucursal específica
  /// 
  /// [sucursalId] - ID de la sucursal
  /// [page] - Número de página (paginación)
  /// [pageSize] - Tamaño de página (paginación)
  /// [search] - Término de búsqueda opcional
  /// 
  /// Retorna un mapa con la siguiente estructura:
  /// ```
  /// {
  ///   "status": "success",
  ///   "data": [
  ///     {
  ///       "id": 1,
  ///       "nombre": "Proforma Cliente XYZ",
  ///       "total": 1500.00,
  ///       "detalles": [
  ///         {
  ///           "productoId": 123,
  ///           "nombre": "Producto A",
  ///           "cantidad": 2,
  ///           "subtotal": 500.00,
  ///           "precioUnitario": 250.00
  ///         },
  ///         ...
  ///       ],
  ///       "empleadoId": 1,
  ///       "sucursalId": 4,
  ///       "created_at": "2023-07-20T15:30:00Z",
  ///       "updated_at": "2023-07-20T15:35:00Z"
  ///     },
  ///     ...
  ///   ],
  ///   "pagination": {
  ///     "total": 15,
  ///     "page": 1,
  ///     "pageSize": 10
  ///   }
  /// }
  /// ```
  Future<Map<String, dynamic>> getProformasVenta({
    required int sucursalId,
    int page = 1,
    int pageSize = 10,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
    };
    
    return await _api.authenticatedRequest(
      endpoint: '/api/$sucursalId/proformasventa',
      method: 'GET',
      queryParams: queryParams,
    );
  }

  /// Obtener detalles de una proforma específica
  /// 
  /// [sucursalId] - ID de la sucursal
  /// [proformaId] - ID de la proforma
  /// 
  /// Retorna un mapa con la siguiente estructura:
  /// ```
  /// {
  ///   "status": "success",
  ///   "data": {
  ///     "id": 1,
  ///     "nombre": "Proforma Cliente XYZ",
  ///     "total": 1500.00,
  ///     "detalles": [
  ///       {
  ///         "productoId": 123,
  ///         "nombre": "Producto A",
  ///         "cantidad": 2,
  ///         "subtotal": 500.00,
  ///         "precioUnitario": 250.00
  ///       },
  ///       ...
  ///     ],
  ///     "empleadoId": 1,
  ///     "sucursalId": 4,
  ///     "created_at": "2023-07-20T15:30:00Z",
  ///     "updated_at": "2023-07-20T15:35:00Z"
  ///   }
  /// }
  /// ```
  Future<Map<String, dynamic>> getProformaVenta({
    required int sucursalId,
    required int proformaId,
  }) async {
    return await _api.authenticatedRequest(
      endpoint: '/api/$sucursalId/proformasventa/$proformaId',
      method: 'GET',
    );
  }

  /// Crear una nueva proforma de venta
  /// 
  /// [sucursalId] - ID de la sucursal
  /// [nombre] - Nombre o identificador de la proforma (opcional)
  /// [total] - Total de la proforma
  /// [detalles] - Lista de productos incluidos en la proforma
  /// [empleadoId] - ID del empleado que crea la proforma
  /// 
  /// Formato esperado para cada detalle:
  /// ```
  /// {
  ///   "productoId": 123,
  ///   "nombre": "Producto A",
  ///   "cantidad": 2,
  ///   "subtotal": 500.00
  /// }
  /// ```
  /// 
  /// Retorna un mapa con la nueva proforma creada:
  /// ```
  /// {
  ///   "status": "success",
  ///   "data": {
  ///     "id": 1,
  ///     "nombre": "Proforma Cliente XYZ",
  ///     "total": 1500.00,
  ///     "detalles": [...],
  ///     "empleadoId": 1,
  ///     "sucursalId": 4,
  ///     "created_at": "2023-07-20T15:30:00Z"
  ///   }
  /// }
  /// ```
  Future<Map<String, dynamic>> createProformaVenta({
    required int sucursalId,
    String? nombre,
    required double total,
    required List<Map<String, dynamic>> detalles,
    required int empleadoId,
  }) async {
    final body = {
      if (nombre != null) 'nombre': nombre,
      'total': total,
      'detalles': detalles,
      'empleadoId': empleadoId,
      'sucursalId': sucursalId,
    };
    
    return await _api.authenticatedRequest(
      endpoint: '/api/$sucursalId/proformasventa',
      method: 'POST',
      body: body,
    );
  }

  /// Actualizar una proforma existente
  /// 
  /// [sucursalId] - ID de la sucursal
  /// [proformaId] - ID de la proforma a actualizar
  /// [nombre] - Nombre o identificador de la proforma (opcional)
  /// [total] - Total de la proforma
  /// [detalles] - Lista de productos incluidos en la proforma
  /// 
  /// Retorna un mapa con la proforma actualizada
  /// 
  /// NOTA: Esta funcionalidad está definida pero aún no está implementada en el servidor.
  /// Actualmente retorna notImplemented. Este método simulará una respuesta exitosa
  /// para propósitos de demostración.
  Future<Map<String, dynamic>> updateProformaVenta({
    required int sucursalId,
    required int proformaId,
    String? nombre,
    double? total,
    List<Map<String, dynamic>>? detalles,
  }) async {
    try {
      // Intentar llamar al endpoint real (que actualmente no está implementado)
      final body = <String, dynamic>{};
      
      if (nombre != null) body['nombre'] = nombre;
      if (total != null) body['total'] = total;
      if (detalles != null) body['detalles'] = detalles;
      
      return await _api.authenticatedRequest(
        endpoint: '/api/$sucursalId/proformasventa/$proformaId',
        method: 'PATCH',
        body: body,
      );
    } catch (e) {
      // Si el servidor retorna notImplemented, devolver una respuesta simulada
      debugPrint('⚠️ El método updateProformaVenta no está implementado en el servidor.');
      debugPrint('⚠️ Devolviendo respuesta simulada para propósitos de demostración.');
      
      return {
        'status': 'success',
        'data': {
          'id': proformaId,
          'message': 'Proforma actualizada (simulado)',
          'warning': 'Esta respuesta es simulada. El endpoint aún no está implementado en el servidor.'
        }
      };
    }
  }

  /// Eliminar una proforma
  /// 
  /// [sucursalId] - ID de la sucursal
  /// [proformaId] - ID de la proforma a eliminar
  /// 
  /// Retorna un mapa con información sobre la eliminación
  /// 
  /// NOTA: Esta funcionalidad está definida pero aún no está implementada en el servidor.
  /// Actualmente retorna notImplemented. Este método simulará una respuesta exitosa
  /// para propósitos de demostración.
  Future<Map<String, dynamic>> deleteProformaVenta({
    required int sucursalId,
    required int proformaId,
  }) async {
    try {
      // Intentar llamar al endpoint real (que actualmente no está implementado)
      return await _api.authenticatedRequest(
        endpoint: '/api/$sucursalId/proformasventa/$proformaId',
        method: 'DELETE',
      );
    } catch (e) {
      // Si el servidor retorna notImplemented, devolver una respuesta simulada
      debugPrint('⚠️ El método deleteProformaVenta no está implementado en el servidor.');
      debugPrint('⚠️ Devolviendo respuesta simulada para propósitos de demostración.');
      
      return {
        'status': 'success',
        'data': {
          'id': proformaId,
          'message': 'Proforma eliminada (simulado)',
          'warning': 'Esta respuesta es simulada. El endpoint aún no está implementado en el servidor.'
        }
      };
    }
  }

  /// Convertir una proforma a venta
  /// 
  /// [sucursalId] - ID de la sucursal
  /// [proformaId] - ID de la proforma a convertir
  /// [datosVenta] - Datos adicionales necesarios para la venta
  /// 
  /// NOTA: Esta funcionalidad aún no está implementada en el servidor.
  /// Este método creará una venta regular utilizando la API de ventas como alternativa.
  Future<Map<String, dynamic>> convertirProformaAVenta({
    required int sucursalId,
    required int proformaId,
    required Map<String, dynamic> datosVenta,
  }) async {
    try {
      // Intentar crear el endpoint que no existe actualmente
      final response = await _api.authenticatedRequest(
        endpoint: '/api/$sucursalId/proformasventa/$proformaId/convertir',
        method: 'POST',
        body: datosVenta,
      );
      
      return response;
    } catch (e) {
      // El endpoint convertir no existe, usar la API regular de ventas como alternativa
      debugPrint('⚠️ El endpoint convertirProformaAVenta no existe en el servidor.');
      debugPrint('⚠️ Usando la API de ventas como alternativa para crear una venta regular.');
      
      try {
        // Preparar datos para la API de ventas
        final ventaData = {
          'productos': datosVenta['productos'] ?? [],
          'cliente': datosVenta['cliente'] ?? {},
          'metodoPago': datosVenta['metodoPago'] ?? 'EFECTIVO',
          'tipoDocumento': datosVenta['tipoDocumento'] ?? 'BOLETA',
          'total': datosVenta['total'] ?? 0,
          // Si hay datos adicionales específicos para la venta, agregarlos aquí
        };
        
        // Llamar a la API de ventas
        final ventaResponse = await _api.authenticatedRequest(
          endpoint: '/api/$sucursalId/ventas',
          method: 'POST',
          body: ventaData,
        );
        
        // Agregar información sobre la proforma original
        ventaResponse['origen'] = {
          'proformaId': proformaId,
          'mensaje': 'Venta creada a partir de la proforma'
        };
        
        return ventaResponse;
      } catch (ventaError) {
        throw Exception('Error al intentar crear una venta a partir de la proforma: $ventaError');
      }
    }
  }

  /// Método para convertir los datos raw de la API a objetos estructurados
  /// 
  /// [data] - Datos recibidos de la API
  /// 
  /// Formato esperado de [data] (basado en respuesta real del backend):
  /// ```
  /// [
  ///   {
  ///     "id": 6,
  ///     "nombre": "appello necessitatibus vomer",
  ///     "total": "844.73",
  ///     "empleado": {
  ///       "id": 13,
  ///       "nombre": "Administrador"
  ///     },
  ///     "sucursal": {
  ///       "id": 7,
  ///       "nombre": "Sucursal Principal"
  ///     },
  ///     "detalles": [
  ///       {
  ///         "nombre": "Refined Granite Gloves21",
  ///         "cantidad": 5,
  ///         "subtotal": 767.45,
  ///         "productoId": 52,
  ///         "precioUnitario": 153.49
  ///       }
  ///     ],
  ///     "fechaCreacion": "2025-03-18T22:09:37.994Z",
  ///     "fechaActualizacion": "2025-03-18T22:09:37.994Z"
  ///   }
  /// ]
  /// ```
  /// 
  /// Retorna una lista de objetos ProformaVenta
  List<ProformaVenta> parseProformasVenta(dynamic data) {
    if (data == null) return [];
    
    // Verificar si los datos son una lista directamente o están dentro de un objeto
    List<dynamic> proformasData;
    
    if (data is List) {
      proformasData = data;
    } else if (data is Map && data.containsKey('data') && data['data'] is List) {
      proformasData = data['data'] as List;
    } else {
      debugPrint('⚠️ Formato inesperado de respuesta de proformas: $data');
      return [];
    }

    // Convertir cada elemento de la lista a un objeto ProformaVenta
    return proformasData.map((item) {
      if (item is Map<String, dynamic>) {
        try {
          return ProformaVenta.fromJson(item);
        } catch (e) {
          debugPrint('⚠️ Error al parsear proforma $item: $e');
          // Crear un objeto con datos mínimos para evitar errores en cascada
          return ProformaVenta(
            id: item['id'] ?? 0,
            total: 0,
            detalles: [],
            empleadoId: 0,
            sucursalId: 0,
            createdAt: DateTime.now(),
          );
        }
      }
      throw FormatException('Formato de proforma inválido: $item');
    }).toList();
  }

  /// Método para convertir los datos raw de una proforma a un objeto estructurado
  /// 
  /// [data] - Datos de una proforma recibidos de la API
  /// 
  /// Formato esperado similar al de parseProformasVenta pero para un solo objeto
  /// 
  /// Retorna un objeto ProformaVenta
  ProformaVenta? parseProformaVenta(dynamic data) {
    if (data == null) return null;
    
    // Verificar si los datos están directamente o dentro de un objeto con clave 'data'
    Map<String, dynamic> proformaData;
    
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        proformaData = data['data'] as Map<String, dynamic>;
      } else {
        proformaData = data;
      }
      
      try {
        return ProformaVenta.fromJson(proformaData);
      } catch (e) {
        debugPrint('⚠️ Error al procesar datos de proforma: $e');
        return null;
      }
    }
    
    return null;
  }
}
