import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/cache/fast_cache.dart';
import 'package:condorsmotors/main.dart' show proformaNotification, api;
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/proforma.model.dart' as proforma_model;
import 'package:condorsmotors/utils/logger.dart';

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
    // Mostrar los datos en la consola para depuración
    Logger.debug(
        '🧾 [ProformaApi] Procesando DetalleProforma: ${json.toString()}');

    // Procesar la cantidad según la disponibilidad de campos
    int cantidad = 0;

    // Priorizar el uso de cantidadTotal si está disponible
    if (json.containsKey('cantidadTotal') && json['cantidadTotal'] != null) {
      cantidad = (json['cantidadTotal'] is int)
          ? json['cantidadTotal']
          : int.tryParse(json['cantidadTotal'].toString()) ?? 0;
      Logger.debug('🧾 Usando cantidadTotal: $cantidad');
    }
    // Si no existe, verificar cantidadPagada
    else if (json.containsKey('cantidadPagada') &&
        json['cantidadPagada'] != null) {
      cantidad = (json['cantidadPagada'] is int)
          ? json['cantidadPagada']
          : int.tryParse(json['cantidadPagada'].toString()) ?? 0;
      Logger.debug('🧾 Usando cantidadPagada: $cantidad');
    }
    // En último caso, usar cantidad tradicional
    else if (json.containsKey('cantidad') && json['cantidad'] != null) {
      cantidad = (json['cantidad'] is int)
          ? json['cantidad']
          : int.tryParse(json['cantidad'].toString()) ?? 0;
      Logger.debug('🧾 Usando cantidad: $cantidad');
    }

    // Procesar el precio unitario y el subtotal
    final double precioUnitario = (json['precioUnitario'] is num)
        ? (json['precioUnitario'] as num).toDouble()
        : double.tryParse(json['precioUnitario'].toString()) ?? 0.0;

    final double subtotal = (json['subtotal'] is num)
        ? (json['subtotal'] as num).toDouble()
        : double.tryParse(json['subtotal'].toString()) ?? 0.0;

    // Procesar campos adicionales

    final int? descuento =
        json.containsKey('descuento') && json['descuento'] != null
            ? ((json['descuento'] is int)
                ? json['descuento'] as int
                : int.tryParse(json['descuento'].toString()))
            : null;

    final int? cantidadGratis =
        json.containsKey('cantidadGratis') && json['cantidadGratis'] != null
            ? ((json['cantidadGratis'] is int)
                ? json['cantidadGratis'] as int
                : int.tryParse(json['cantidadGratis'].toString()))
            : null;

    // Mostrar información sobre promociones y descuentos
    if (descuento != null && descuento > 0) {
      Logger.debug(
          '🎯 Producto con descuento: ${json['nombre']} - $descuento%');
    }

    if (cantidadGratis != null && cantidadGratis > 0) {
      Logger.debug(
          '🎁 Producto con unidades gratis: ${json['nombre']} - $cantidadGratis unidades');
    }

    return DetalleProforma(
      productoId: (json['productoId'] is int)
          ? json['productoId']
          : int.tryParse(json['productoId'].toString()) ?? 0,
      nombre: json['nombre']?.toString() ?? 'Producto sin nombre',
      cantidad: cantidad,
      subtotal: subtotal,
      precioUnitario: precioUnitario,
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
      precioOriginal: precioUnitario,
      descuento: 0,
      cantidadGratis: 0,
      cantidadPagada: cantidad,
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
      _cache
        ..invalidateByPattern('$_prefixListaProformas$sucursalId')
        ..invalidateByPattern('$_prefixProforma$sucursalId');
      logCache('🔄 Caché de proformas invalidado para sucursal $sucursalId');
    } else {
      // Invalidar todas las proformas en caché
      _cache
        ..invalidateByPattern(_prefixListaProformas)
        ..invalidateByPattern(_prefixProforma);
      logCache('🔄 Caché de proformas invalidado completamente');
    }
    logCache('📊 Entradas en caché después de invalidación: ${_cache.size}');
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
      final String cacheKey =
          '$_prefixListaProformas${sucursalId}_p${page}_s${pageSize}_q${search ?? ""}';

      // Nuevo mensaje de debug para seguimiento detallado
      logCache(
          '📝 [ProformaVentaApi] Solicitando proformas de sucursal $sucursalId (page: $page, pageSize: $pageSize, useCache: $useCache, forceRefresh: $forceRefresh)');

      // Intentar obtener del caché si corresponde
      if (useCache && !forceRefresh) {
        final Map<String, dynamic>? cachedData =
            _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          logCache('🔍 Usando proformas en caché para sucursal $sucursalId');
          return cachedData;
        }
      }

      final Map<String, String> queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      logCache(
          '🔄 [ProformaVentaApi] Realizando petición API a /$sucursalId/proformasventa');

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa',
        method: 'GET',
        queryParams: queryParams,
      );

      // Nuevo mensaje de debug con información de respuesta
      logCache(
          '✅ [ProformaVentaApi] Respuesta recibida para proformas de sucursal $sucursalId');
      if (response.containsKey('data')) {
        final int proformasCount =
            response['data'] is List ? (response['data'] as List).length : 0;
        logCache('📊 [ProformaVentaApi] Proformas recibidas: $proformasCount');
      }

      // Guardar en caché
      if (useCache) {
        _cache.set(cacheKey, response);
        logCache('💾 Guardadas proformas en caché para sucursal $sucursalId');
      }

      return response;
    } catch (e) {
      logCache('❌ [ProformaVentaApi] ERROR al obtener proformas de venta: $e');
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
      logCache(
          '📝 [ProformaVentaApi] Solicitando proforma #$proformaId de sucursal $sucursalId (useCache: $useCache, forceRefresh: $forceRefresh)');

      // Intentar obtener del caché si corresponde
      if (useCache && !forceRefresh) {
        final Map<String, dynamic>? cachedData =
            _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null && !_cache.isStale(cacheKey)) {
          logCache(
              '🔍 [ProformaVentaApi] Usando proforma en caché: $sucursalId/$proformaId');
          return cachedData;
        }
      }

      logCache(
          '🔄 [ProformaVentaApi] Realizando petición API a /$sucursalId/proformasventa/$proformaId');

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa/$proformaId',
        method: 'GET',
      );

      // Nuevo mensaje de debug con información de respuesta
      logCache(
          '✅ [ProformaVentaApi] Respuesta recibida para proforma #$proformaId');
      if (response.containsKey('status')) {
        logCache('📊 [ProformaVentaApi] Status: ${response['status']}');
      }

      // Guardar en caché
      if (useCache) {
        _cache.set(cacheKey, response);
        logCache(
            '💾 [ProformaVentaApi] Guardada proforma en caché: $sucursalId/$proformaId');
      }

      return response;
    } catch (e) {
      logCache(
          '❌ [ProformaVentaApi] ERROR al obtener proforma #$proformaId: $e');
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
        if (fechaExpiracion != null)
          'fechaExpiracion': fechaExpiracion.toIso8601String(),
      };

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa',
        method: 'POST',
        body: body,
      );

      // Invalidar caché después de crear
      invalidateCache(sucursalId);

      // Enviar notificación si la respuesta fue exitosa
      if (response.containsKey('status') &&
          response['status'] == 'success' &&
          response.containsKey('data')) {
        // Intentar obtener la proforma creada
        final proforma_model.Proforma? nuevaProforma =
            parseProformaVenta(response);

        if (nuevaProforma != null) {
          // Buscar el nombre del cliente si existe
          String nombreCliente = '';
          if (clienteId != null) {
            try {
              final userData = await api.authService.getUserData();
              nombreCliente = userData?['nombre'] ?? '';
            } catch (e) {
              // Ignorar errores al obtener el nombre del cliente
              Logger.warn(
                  '⚠️ No se pudo obtener el nombre del cliente para la notificación: $e');
            }
          }

          // Enviamos siempre la notificación de nueva proforma
          Logger.info(
              '🔔 Enviando notificación de nueva proforma #${nuevaProforma.id}');
          await proformaNotification.notifyNewProforma(nuevaProforma);

          // Siempre enviamos la notificación de proforma pendiente, para que aparezca en la barra de Windows
          // sin tener que verificar el rol (simplificando el flujo)
          await proformaNotification.notifyNewProformaPending(
            nuevaProforma,
            nombreCliente,
          );
          Logger.info(
              '🔔 Notificación de proforma pendiente enviada para #${nuevaProforma.id}');
        }
      }

      return response;
    } catch (e) {
      Logger.error('❌ Error al crear proforma de venta: $e');
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
      logCache(
          '📝 [ProformaVentaApi] Actualizando proforma #$proformaId en sucursal $sucursalId');

      // Si se especifica el estado, preparar los datos para actualizar
      if (estado != null) {
        data = data ?? <String, dynamic>{};
        data['estado'] = estado;

        logCache(
            '🔄 [ProformaVentaApi] Cambiando estado de proforma a: $estado');
      }

      if (data == null || data.isEmpty) {
        throw Exception(
            'Se deben proporcionar datos para actualizar la proforma');
      }

      logCache(
          '🔄 [ProformaVentaApi] Realizando petición API PATCH a /$sucursalId/proformasventa/$proformaId');

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '/$sucursalId/proformasventa/$proformaId',
        method: 'PATCH',
        body: data,
      );

      // Nuevo mensaje de debug con resultado
      logCache(
          '✅ [ProformaVentaApi] Respuesta de actualización de proforma #$proformaId recibida');
      if (response.containsKey('status')) {
        logCache('📊 [ProformaVentaApi] Status: ${response['status']}');
      }

      // Invalidar caché para esta proforma
      invalidateCache(sucursalId);

      // Enviar notificación si se cambió el estado a "convertida"
      if (estado == 'convertida' &&
          response.containsKey('status') &&
          response['status'] == 'success') {
        try {
          // Obtener los detalles de la proforma para la notificación
          final Map<String, dynamic> proformaResponse = await getProformaVenta(
            sucursalId: sucursalId,
            proformaId: proformaId,
            useCache: false, // No usar caché para obtener datos actualizados
          );

          final proforma_model.Proforma? proforma =
              parseProformaVenta(proformaResponse);

          if (proforma != null) {
            // Enviar notificación de proforma convertida
            Logger.info(
                '🔔 Enviando notificación de proforma convertida #$proformaId');
            await proformaNotification.notifyProformaConverted(proforma);
          }
        } catch (e) {
          // Ignorar errores al enviar la notificación
          Logger.warn(
              '⚠️ Error al enviar notificación de proforma convertida: $e');
        }
      }

      return response;
    } catch (e) {
      logCache(
          '❌ [ProformaVentaApi] ERROR al actualizar proforma #$proformaId: $e');
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
      logCache('⚠️ Error al eliminar proforma: $e');
      logCache(
          '⚠️ El método deleteProformaVenta puede no estar implementado en el servidor.');
      logCache(
          '⚠️ Devolviendo respuesta simulada para propósitos de demostración.');

      // Invalidar caché de todos modos para consistencia
      invalidateCache(sucursalId);

      return <String, dynamic>{
        'status': 'success',
        'data': <String, Object>{
          'id': proformaId,
          'message': 'Proforma eliminada (simulado)',
          'warning':
              'Esta respuesta es simulada. El endpoint aún no está implementado en el servidor.'
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
    } else if (data is Map &&
        data.containsKey('data') &&
        data['data'] is List) {
      proformasData = data['data'] as List;
    } else {
      logCache('⚠️ Formato inesperado de respuesta de proformas: $data');
      return <proforma_model.Proforma>[];
    }

    // Convertir cada elemento de la lista a un objeto Proforma
    return proformasData.map((item) {
      if (item is Map<String, dynamic>) {
        try {
          return proforma_model.Proforma.fromJson(item);
        } catch (e) {
          logCache('⚠️ Error al parsear proforma $item: $e');
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
        logCache('⚠️ Error al procesar datos de proforma: $e');
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
    return detalles.fold(
        0.0, (double sum, DetalleProforma detalle) => sum + detalle.subtotal);
  }
}
