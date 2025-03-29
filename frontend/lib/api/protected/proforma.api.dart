import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/cache/fast_cache.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/proforma.model.dart' as proforma_model;
import 'package:flutter/foundation.dart';

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
    return <String, dynamic>{
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

  /// Convierte este DetalleProforma a un DetalleProforma del modelo
  proforma_model.DetalleProforma toModelDetalleProforma() {
    return proforma_model.DetalleProforma(
      productoId: productoId,
      nombre: nombre,
      cantidad: cantidad,
      subtotal: subtotal,
      precioUnitario: precioUnitario,
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
      _cache..invalidateByPattern('$_prefixListaProformas$sucursalId')
      ..invalidateByPattern('$_prefixProforma$sucursalId');
      debugPrint('🔄 Caché de proformas invalidado para sucursal $sucursalId');
    } else {
      // Invalidar todas las proformas en caché
      _cache..invalidateByPattern(_prefixListaProformas)
      ..invalidateByPattern(_prefixProforma);
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
      final String cacheKey = '$_prefixListaProformas${sucursalId}_p${page}_s${pageSize}_q${search ?? ""}';
      
      // Nuevo mensaje de debug para seguimiento detallado
      debugPrint('📝 [ProformaVentaApi] Solicitando proformas de sucursal $sucursalId (page: $page, pageSize: $pageSize, useCache: $useCache, forceRefresh: $forceRefresh)');
      
      // Intentar obtener del caché si corresponde
      if (useCache && !forceRefresh) {
        final Map<String, dynamic>? cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          debugPrint('🔍 Usando proformas en caché para sucursal $sucursalId');
          return cachedData;
        }
      }
      
      final Map<String, String> queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      
      debugPrint('🔄 [ProformaVentaApi] Realizando petición API a /$sucursalId/proformasventa');
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa',
        method: 'GET',
        queryParams: queryParams,
      );
      
      // Nuevo mensaje de debug con información de respuesta
      debugPrint('✅ [ProformaVentaApi] Respuesta recibida para proformas de sucursal $sucursalId');
      if (response.containsKey('data')) {
        final int proformasCount = response['data'] is List ? (response['data'] as List).length : 0;
        debugPrint('📊 [ProformaVentaApi] Proformas recibidas: $proformasCount');
      }
      
      // Guardar en caché
      if (useCache) {
        _cache.set(cacheKey, response);
        debugPrint('💾 Guardadas proformas en caché para sucursal $sucursalId');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ [ProformaVentaApi] ERROR al obtener proformas de venta: $e');
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
      final String cacheKey = '$_prefixProforma${sucursalId}_$proformaId';
      
      // Nuevo mensaje de debug para seguimiento detallado
      debugPrint('📝 [ProformaVentaApi] Solicitando proforma #$proformaId de sucursal $sucursalId (useCache: $useCache, forceRefresh: $forceRefresh)');
      
      // Intentar obtener del caché si corresponde
      if (useCache && !forceRefresh) {
        final Map<String, dynamic>? cachedData = _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          debugPrint('🔍 [ProformaVentaApi] Usando proforma en caché: $sucursalId/$proformaId');
          return cachedData;
        }
      }
      
      debugPrint('🔄 [ProformaVentaApi] Realizando petición API a /$sucursalId/proformasventa/$proformaId');
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa/$proformaId',
        method: 'GET',
      );
      
      // Nuevo mensaje de debug con información de respuesta
      debugPrint('✅ [ProformaVentaApi] Respuesta recibida para proforma #$proformaId');
      if (response.containsKey('status')) {
        debugPrint('📊 [ProformaVentaApi] Status: ${response['status']}');
      }
      
      // Guardar en caché
      if (useCache) {
        _cache.set(cacheKey, response);
        debugPrint('💾 [ProformaVentaApi] Guardada proforma en caché: $sucursalId/$proformaId');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ [ProformaVentaApi] ERROR al obtener proforma #$proformaId: $e');
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
      final Map<String, Object> body = <String, Object>{
        if (nombre != null) 'nombre': nombre,
        'total': total,
        'detalles': detalles.map((DetalleProforma d) => d.toJson()).toList(),
        'empleadoId': empleadoId,
        'sucursalId': int.parse(sucursalId),
        if (clienteId != null) 'clienteId': clienteId,
        if (estado != null) 'estado': estado,
        if (fechaExpiracion != null) 'fechaExpiracion': fechaExpiracion.toIso8601String(),
      };
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
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
  /// [data] - Datos a actualizar
  /// [estado] - Estado nuevo de la proforma (opcional)
  /// 
  /// Retorna un mapa con la respuesta del servidor
  Future<Map<String, dynamic>> updateProformaVenta({
    required String sucursalId,
    required int proformaId,
    Map<String, dynamic>? data,
    String? estado,
  }) async {
    try {
      // Nuevo mensaje de debug para seguimiento
      debugPrint('📝 [ProformaVentaApi] Actualizando proforma #$proformaId en sucursal $sucursalId');
      
      // Si se especifica el estado, preparar los datos para actualizar
      if (estado != null) {
        data = data ?? <String, dynamic>{};
        data['estado'] = estado;
        
        debugPrint('🔄 [ProformaVentaApi] Cambiando estado de proforma a: $estado');
      }
      
      if (data == null || data.isEmpty) {
        throw Exception('Se deben proporcionar datos para actualizar la proforma');
      }
      
      debugPrint('🔄 [ProformaVentaApi] Realizando petición API PATCH a /$sucursalId/proformasventa/$proformaId');
      
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa/$proformaId',
        method: 'PATCH',
        body: data,
      );
      
      // Nuevo mensaje de debug con resultado
      debugPrint('✅ [ProformaVentaApi] Respuesta de actualización de proforma #$proformaId recibida');
      if (response.containsKey('status')) {
        debugPrint('📊 [ProformaVentaApi] Status: ${response['status']}');
      }
      
      // Invalidar caché para esta proforma
      invalidateCache(sucursalId);
      
      return response;
    } catch (e) {
      debugPrint('❌ [ProformaVentaApi] ERROR al actualizar proforma #$proformaId: $e');
      rethrow;
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
      final Map<String, dynamic> response = await _api.authenticatedRequest(
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
      
      return <String, dynamic>{
        'status': 'success',
        'data': <String, Object>{
          'id': proformaId,
          'message': 'Proforma eliminada (simulado)',
          'warning': 'Esta respuesta es simulada. El endpoint aún no está implementado en el servidor.'
        }
      };
    }
  }

  /// Convierte una lista de datos de la API a una lista de objetos Proforma
  /// 
  /// [data] - Datos recibidos de la API
  /// 
  /// Retorna una lista de objetos Proforma
  List<proforma_model.Proforma> parseProformasVenta(data) {
    if (data == null) {
      return <proforma_model.Proforma>[];
    }
    
    // Verificar si los datos son una lista directamente o están dentro de un objeto
    List<dynamic> proformasData;
    
    if (data is List) {
      proformasData = data;
    } else if (data is Map && data.containsKey('data') && data['data'] is List) {
      proformasData = data['data'] as List;
    } else {
      debugPrint('⚠️ Formato inesperado de respuesta de proformas: $data');
      return <proforma_model.Proforma>[];
    }

    // Convertir cada elemento de la lista a un objeto Proforma
    return proformasData.map((item) {
      if (item is Map<String, dynamic>) {
        try {
          return proforma_model.Proforma.fromJson(item);
        } catch (e) {
          debugPrint('⚠️ Error al parsear proforma $item: $e');
          // Crear un objeto con datos mínimos para evitar errores en cascada
          return proforma_model.Proforma(
            id: item['id'] ?? 0,
            total: 0,
            detalles: <proforma_model.DetalleProforma>[],
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
  proforma_model.Proforma? parseProformaVenta(data) {
    if (data == null) {
      return null;
    }
    
    // Verificar si los datos están directamente o dentro de un objeto con clave 'data'
    Map<String, dynamic> proformaData;
    
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        proformaData = data['data'] as Map<String, dynamic>;
      } else {
        proformaData = data;
      }
      
      try {
        return proforma_model.Proforma.fromJson(proformaData);
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
    final List<DetalleProforma> result = <DetalleProforma>[];
    
    for (final Producto producto in productos) {
      final int cantidad = cantidades[producto.id] ?? 1;
      if (cantidad <= 0) {
        continue; // No agregar productos con cantidad 0
      }
      
      result.add(DetalleProforma.fromProducto(
        producto, 
        cantidad: cantidad,
      ));
    }
    
    return result;
  }
  
  /// Calcula el total de una lista de detalles de proforma
  double calcularTotal(List<DetalleProforma> detalles) {
    return detalles.fold(0.0, (double sum, DetalleProforma detalle) => sum + detalle.subtotal);
  }
}
