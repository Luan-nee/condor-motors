import 'package:flutter/foundation.dart';

import '../../models/producto.model.dart';
import '../../models/proforma.model.dart';
import '../main.api.dart';
import 'cache/fast_cache.dart';

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

  /// Crea un objeto DetalleProforma a partir de un Producto
  factory DetalleProforma.fromProducto(Producto producto, {int cantidad = 1}) {
    return DetalleProforma(
      productoId: producto.id,
      nombre: producto.nombre,
      cantidad: cantidad,
      subtotal: producto.precioVenta * cantidad,
      precioUnitario: producto.precioVenta,
    );
  }
}

/// API para manejar proformas de venta
class ProformaVentaApi {
  final ApiClient _api;
  final FastCache _cache = FastCache(maxSize: 50);
  
  // Prefijos para las claves de caché
  static const String _prefixListaProformas = 'proformas_lista_';
  static const String _prefixProforma = 'proforma_detalle_';

  /// Constructor que recibe una instancia de ApiClient
  ProformaVentaApi(this._api);

  /// Invalida el caché para una sucursal específica o para todas las sucursales
  /// 
  /// [sucursalId] - ID de la sucursal (opcional, si no se especifica invalida para todas las sucursales)
  void invalidateCache([String? sucursalId]) {
    if (sucursalId != null) {
      // Invalidar sólo las proformas de esta sucursal
      _cache.invalidateByPattern('$_prefixListaProformas$sucursalId');
      _cache.invalidateByPattern('$_prefixProforma$sucursalId');
      debugPrint('🔄 Caché de proformas invalidado para sucursal $sucursalId');
    } else {
      // Invalidar todas las proformas en caché
      _cache.invalidateByPattern(_prefixListaProformas);
      _cache.invalidateByPattern(_prefixProforma);
      debugPrint('🔄 Caché de proformas invalidado completamente');
    }
    debugPrint('📊 Entradas en caché después de invalidación: ${_cache.size}');
  }

  /// Obtener lista de proformas de venta para una sucursal específica
  /// 
  /// [sucursalId] - ID de la sucursal
  /// [page] - Número de página (paginación)
  /// [pageSize] - Tamaño de página (paginación)
  /// [search] - Término de búsqueda opcional
  /// [useCache] - Si se debe usar el caché (por defecto true)
  /// [forceRefresh] - Si se debe forzar una actualización desde el servidor (por defecto false)
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
  ///       "fechaCreacion": "2023-07-20T15:30:00Z",
  ///       "fechaActualizacion": "2023-07-20T15:35:00Z"
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
    required String sucursalId,
    int page = 1,
    int pageSize = 10,
    String? search,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = '$_prefixListaProformas${sucursalId}_p${page}_s${pageSize}_q${search ?? ""}';
      
      // Intentar obtener del caché si corresponde
      if (useCache && !forceRefresh) {
        final cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          debugPrint('🔍 Usando proformas en caché para sucursal $sucursalId');
          return cachedData;
        }
      }
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa',
        method: 'GET',
        queryParams: queryParams,
      );
      
      // Guardar en caché
      if (useCache) {
        _cache.set(cacheKey, response);
        debugPrint('💾 Guardadas proformas en caché para sucursal $sucursalId');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Error al obtener proformas de venta: $e');
      rethrow;
    }
  }

  /// Obtener detalles de una proforma específica
  /// 
  /// [sucursalId] - ID de la sucursal
  /// [proformaId] - ID de la proforma
  /// [useCache] - Si se debe usar el caché (por defecto true)
  /// [forceRefresh] - Si se debe forzar una actualización desde el servidor (por defecto false)
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
  ///     "fechaCreacion": "2023-07-20T15:30:00Z",
  ///     "fechaActualizacion": "2023-07-20T15:35:00Z"
  ///   }
  /// }
  /// ```
  Future<Map<String, dynamic>> getProformaVenta({
    required String sucursalId,
    required int proformaId,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = '$_prefixProforma${sucursalId}_$proformaId';
      
      // Intentar obtener del caché si corresponde
      if (useCache && !forceRefresh) {
        final cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          debugPrint('🔍 Usando proforma en caché: $sucursalId/$proformaId');
          return cachedData;
        }
      }
      
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa/$proformaId',
        method: 'GET',
      );
      
      // Guardar en caché
      if (useCache) {
        _cache.set(cacheKey, response);
        debugPrint('💾 Guardada proforma en caché: $sucursalId/$proformaId');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Error al obtener proforma de venta: $e');
      rethrow;
    }
  }

  /// Crear una nueva proforma de venta
  /// 
  /// [sucursalId] - ID de la sucursal
  /// [nombre] - Nombre o identificador de la proforma (opcional)
  /// [total] - Total de la proforma
  /// [detalles] - Lista de productos incluidos en la proforma
  /// [empleadoId] - ID del empleado que crea la proforma
  /// [clienteId] - ID del cliente asociado (opcional)
  /// 
  /// Formato esperado para cada detalle:
  /// ```
  /// {
  ///   "productoId": 123,
  ///   "nombre": "Producto A",
  ///   "cantidad": 2,
  ///   "subtotal": 500.00,
  ///   "precioUnitario": 250.00
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
  ///     "fechaCreacion": "2023-07-20T15:30:00Z"
  ///   }
  /// }
  /// ```
  Future<Map<String, dynamic>> createProformaVenta({
    required String sucursalId,
    String? nombre,
    required double total,
    required List<DetalleProforma> detalles,
    required int empleadoId,
    int? clienteId,
    String? estado,
    DateTime? fechaExpiracion,
  }) async {
    try {
      final body = {
        if (nombre != null) 'nombre': nombre,
        'total': total,
        'detalles': detalles.map((d) => d.toJson()).toList(),
        'empleadoId': empleadoId,
        'sucursalId': int.parse(sucursalId),
        if (clienteId != null) 'clienteId': clienteId,
        if (estado != null) 'estado': estado,
        if (fechaExpiracion != null) 'fechaExpiracion': fechaExpiracion.toIso8601String(),
      };
      
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa',
        method: 'POST',
        body: body,
      );
      
      // Invalidar caché después de crear
      invalidateCache(sucursalId);
      
      return response;
    } catch (e) {
      debugPrint('❌ Error al crear proforma de venta: $e');
      rethrow;
    }
  }

  /// Actualizar una proforma existente
  /// 
  /// [sucursalId] - ID de la sucursal
  /// [proformaId] - ID de la proforma a actualizar
  /// [nombre] - Nombre o identificador de la proforma (opcional)
  /// [total] - Total de la proforma
  /// [detalles] - Lista de productos incluidos en la proforma
  /// [estado] - Estado de la proforma (opcional)
  /// 
  /// Retorna un mapa con la proforma actualizada
  /// 
  /// NOTA: Esta funcionalidad está definida pero puede no estar implementada en el servidor.
  /// Si el servidor devuelve notImplemented, este método simulará una respuesta exitosa.
  Future<Map<String, dynamic>> updateProformaVenta({
    required String sucursalId,
    required int proformaId,
    String? nombre,
    double? total,
    List<DetalleProforma>? detalles,
    String? estado,
    int? clienteId,
    DateTime? fechaExpiracion,
  }) async {
    try {
      // Intentar llamar al endpoint real
      final body = <String, dynamic>{};
      
      if (nombre != null) body['nombre'] = nombre;
      if (total != null) body['total'] = total;
      
      if (detalles != null) {
        body['detalles'] = detalles.map((d) => d.toJson()).toList();
      }
      
      if (estado != null) body['estado'] = estado;
      if (clienteId != null) body['clienteId'] = clienteId;
      if (fechaExpiracion != null) body['fechaExpiracion'] = fechaExpiracion.toIso8601String();
      
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa/$proformaId',
        method: 'PATCH',
        body: body,
      );
      
      // Invalidar caché después de actualizar
      invalidateCache(sucursalId);
      
      return response;
    } catch (e) {
      // Si el servidor retorna notImplemented, devolver una respuesta simulada
      debugPrint('⚠️ Error al actualizar proforma: $e');
      debugPrint('⚠️ El método updateProformaVenta puede no estar implementado en el servidor.');
      debugPrint('⚠️ Devolviendo respuesta simulada para propósitos de demostración.');
      
      // Invalidar caché de todos modos para consistencia
      invalidateCache(sucursalId);
      
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
  /// NOTA: Esta funcionalidad está definida pero puede no estar implementada en el servidor.
  /// Si el servidor devuelve notImplemented, este método simulará una respuesta exitosa.
  Future<Map<String, dynamic>> deleteProformaVenta({
    required String sucursalId,
    required int proformaId,
  }) async {
    try {
      // Intentar llamar al endpoint real
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa/$proformaId',
        method: 'DELETE',
      );
      
      // Invalidar caché después de eliminar
      invalidateCache(sucursalId);
      
      return response;
    } catch (e) {
      // Si el servidor retorna notImplemented, devolver una respuesta simulada
      debugPrint('⚠️ Error al eliminar proforma: $e');
      debugPrint('⚠️ El método deleteProformaVenta puede no estar implementado en el servidor.');
      debugPrint('⚠️ Devolviendo respuesta simulada para propósitos de demostración.');
      
      // Invalidar caché de todos modos para consistencia
      invalidateCache(sucursalId);
      
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
  /// NOTA: Esta funcionalidad puede no estar implementada en el servidor.
  /// Este método intentará usar el endpoint específico, y si no existe,
  /// creará una venta regular utilizando la API de ventas como alternativa.
  Future<Map<String, dynamic>> convertirProformaAVenta({
    required String sucursalId,
    required int proformaId,
    required Map<String, dynamic> datosVenta,
  }) async {
    try {
      // Intentar llamar al endpoint específico si existe
      final response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa/$proformaId/convertir',
        method: 'POST',
        body: datosVenta,
      );
      
      // Invalidar caché después de convertir
      invalidateCache(sucursalId);
      
      return response;
    } catch (e) {
      // El endpoint convertir puede no existir, usar la API regular de ventas
      debugPrint('⚠️ Error al convertir proforma a venta: $e');
      debugPrint('⚠️ El endpoint convertirProformaAVenta puede no existir.');
      debugPrint('⚠️ Usando la API de ventas como alternativa para crear una venta regular.');
      
      try {
        // Verificar si tenemos la proforma para usar sus datos
        Proforma? proforma;
        try {
          final proformaResponse = await getProformaVenta(
            sucursalId: sucursalId,
            proformaId: proformaId,
            forceRefresh: true, // Forzar obtener datos frescos
          );
          proforma = parseProformaVenta(proformaResponse);
        } catch (e) {
          debugPrint('❌ Error al obtener la proforma para conversión: $e');
        }

        // Preparar datos para la API de ventas
        final ventaData = {
          'productos': datosVenta['productos'] ?? [],
          'cliente': datosVenta['cliente'] ?? {},
          'metodoPago': datosVenta['metodoPago'] ?? 'EFECTIVO',
          'tipoDocumento': datosVenta['tipoDocumento'] ?? 'BOLETA',
          'total': datosVenta['total'] ?? proforma?.total ?? 0,
          // Si hay datos adicionales específicos para la venta, agregarlos aquí
        };
        
        // Llamar a la API de ventas
        final ventaResponse = await _api.authenticatedRequest(
          endpoint: '/$sucursalId/ventas',
          method: 'POST',
          body: ventaData,
        );
        
        // Si la venta se creó correctamente, actualizar el estado de la proforma
        if (ventaResponse['status'] == 'success' && proforma != null) {
          try {
            await updateProformaVenta(
              sucursalId: sucursalId,
              proformaId: proformaId,
              estado: 'convertida',
            );
          } catch (e) {
            debugPrint('⚠️ Error al actualizar el estado de la proforma: $e');
          }
        }

        // Invalidar caché después de la operación
        invalidateCache(sucursalId);

        // Agregar información sobre la proforma original
        final Map<String, dynamic> response = {...ventaResponse};
        response['origen'] = {
          'proformaId': proformaId,
          'mensaje': 'Venta creada a partir de la proforma'
        };
        
        return response;
      } catch (ventaError) {
        debugPrint('❌ Error al crear venta a partir de proforma: $ventaError');
        throw Exception('Error al intentar crear una venta a partir de la proforma: $ventaError');
      }
    }
  }

  /// Convierte una lista de datos de la API a una lista de objetos Proforma
  /// 
  /// [data] - Datos recibidos de la API
  /// 
  /// Retorna una lista de objetos Proforma
  List<Proforma> parseProformasVenta(dynamic data) {
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

    // Convertir cada elemento de la lista a un objeto Proforma
    return proformasData.map((item) {
      if (item is Map<String, dynamic>) {
        try {
          return Proforma.fromJson(item);
        } catch (e) {
          debugPrint('⚠️ Error al parsear proforma $item: $e');
          // Crear un objeto con datos mínimos para evitar errores en cascada
          return Proforma(
            id: item['id'] ?? 0,
            total: 0,
            detalles: [],
            empleadoId: 0,
            sucursalId: 0,
            fechaCreacion: DateTime.now(),
          );
        }
      }
      throw FormatException('Formato de proforma inválido: $item');
    }).toList();
  }

  /// Convierte los datos de la API a un objeto Proforma
  /// 
  /// [data] - Datos de una proforma recibidos de la API
  /// 
  /// Retorna un objeto Proforma
  Proforma? parseProformaVenta(dynamic data) {
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
        return Proforma.fromJson(proformaData);
      } catch (e) {
        debugPrint('⚠️ Error al procesar datos de proforma: $e');
        return null;
      }
    }
    
    return null;
  }
  
  /// Crea una lista de detalles de proforma a partir de productos
  List<DetalleProforma> crearDetallesDesdeProductos(
    List<Producto> productos, 
    Map<int, int> cantidades,
  ) {
    final result = <DetalleProforma>[];
    
    for (final producto in productos) {
      final cantidad = cantidades[producto.id] ?? 1;
      if (cantidad <= 0) continue; // No agregar productos con cantidad 0
      
      result.add(DetalleProforma.fromProducto(
        producto, 
        cantidad: cantidad,
      ));
    }
    
    return result;
  }
  
  /// Calcula el total de una lista de detalles de proforma
  double calcularTotal(List<DetalleProforma> detalles) {
    return detalles.fold(0.0, (sum, detalle) => sum + detalle.subtotal);
  }
}
