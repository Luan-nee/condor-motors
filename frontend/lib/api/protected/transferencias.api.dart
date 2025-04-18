import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/api/protected/cache/fast_cache.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:flutter/foundation.dart';

class TransferenciasInventarioApi {
  final ApiClient _api;
  final String _endpoint = '/transferenciasInventario';
  final FastCache _cache = FastCache(maxSize: 75);

  // Prefijos para las claves de caché
  static const String _prefixListaMovimientos = 'transferencias_lista_';
  static const String _prefixMovimiento = 'transferencia_detalle_';

  TransferenciasInventarioApi(this._api);

  /// Invalida el caché de transferencias
  void invalidateCache([String? sucursalId]) {
    if (sucursalId != null) {
      _cache
        ..invalidateByPattern('$_prefixListaMovimientos$sucursalId')
        ..invalidateByPattern('$_prefixMovimiento$sucursalId');
      debugPrint('Cache invalidado para sucursal: $sucursalId');
    } else {
      _cache
        ..invalidateByPattern(_prefixListaMovimientos)
        ..invalidateByPattern(_prefixMovimiento);
      debugPrint('Cache invalidado completamente');
    }
  }

  /// Obtiene todas las transferencias de inventario
  Future<PaginatedResponse<TransferenciaInventario>> getTransferencias({
    String? sucursalId,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? sortBy,
    String? order,
    int? page,
    int? pageSize,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Generar clave de caché
      final String cacheKey = _generateCacheKey(
        sucursalId: sucursalId,
        estado: estado,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        sortBy: sortBy,
        order: order,
        page: page,
        pageSize: pageSize,
      );

      // Verificar caché
      if (!forceRefresh && useCache) {
        final PaginatedResponse<TransferenciaInventario>? cached =
            _cache.get(cacheKey);
        if (cached != null) {
          debugPrint('Datos obtenidos desde caché: $cacheKey');
          return cached;
        }
      }

      // Preparar parámetros de consulta
      final Map<String, String> queryParams = <String, String>{
        if (sucursalId != null) 'sucursal_id': sucursalId,
        if (estado != null) 'estado': estado,
        if (fechaInicio != null) 'fecha_inicio': fechaInicio.toIso8601String(),
        if (fechaFin != null) 'fecha_fin': fechaFin.toIso8601String(),
        if (sortBy != null) 'sort_by': sortBy,
        if (order != null) 'order': order,
        if (page != null) 'page': page.toString(),
        if (pageSize != null) 'page_size': pageSize.toString(),
      };

      // Realizar petición
      final Map<String, dynamic> response = await _api
          .authenticatedRequest(
            endpoint: _endpoint,
            method: 'GET',
            queryParams: queryParams,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw ApiException(
              message: 'Tiempo de espera agotado al obtener transferencias',
              statusCode: 408,
              errorCode:
                  ApiConstants.errorCodes[408] ?? ApiConstants.unknownError,
            ),
          );

      // Procesar respuesta usando PaginatedResponse
      final PaginatedResponse<TransferenciaInventario> paginatedResponse =
          PaginatedResponse.fromApiResponse(
        response,
        (Map<String, dynamic> json) => TransferenciaInventario.fromJson(json),
      );

      // Guardar en caché si es necesario
      if (useCache) {
        _cache.set(cacheKey, paginatedResponse);
      }

      return paginatedResponse;
    } catch (e) {
      debugPrint('Error al obtener transferencias: $e');
      rethrow;
    }
  }

  /// Obtiene una transferencia específica por ID
  Future<TransferenciaInventario> getTransferencia(
    String id, {
    bool useCache = true,
  }) async {
    try {
      final String cacheKey = '$_prefixMovimiento$id';

      // Verificar caché
      if (useCache) {
        final TransferenciaInventario? cached = _cache.get(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      // Realizar petición
      final Map<String, dynamic> response = await _api
          .authenticatedRequest(
            endpoint: '$_endpoint/$id',
            method: 'GET',
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw ApiException(
              message:
                  'Tiempo de espera agotado al obtener detalles de la transferencia',
              statusCode: 408,
              errorCode:
                  ApiConstants.errorCodes[408] ?? ApiConstants.unknownError,
            ),
          );

      // Procesar respuesta
      final TransferenciaInventario transferencia =
          _processTransferenciaResponse(response, id);

      // Guardar en caché si es necesario
      if (useCache) {
        _cache.set(cacheKey, transferencia);
      }

      return transferencia;
    } catch (e) {
      debugPrint('Error al obtener transferencia $id: $e');
      rethrow;
    }
  }

  /// Crea una nueva transferencia de inventario
  Future<TransferenciaInventario> createTransferencia({
    required int sucursalDestinoId,
    required List<Map<String, dynamic>> items,
    String? observaciones,
  }) async {
    try {
      final Map<String, dynamic> data = <String, dynamic>{
        'sucursalDestinoId': sucursalDestinoId,
        'items': items,
        if (observaciones != null) 'observaciones': observaciones,
      };

      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: _endpoint,
        method: 'POST',
        body: data,
      );

      // Invalidar caché
      invalidateCache();

      return TransferenciaInventario.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error al crear transferencia: $e');
      rethrow;
    }
  }

  /// Envía una transferencia de inventario
  Future<TransferenciaInventario> enviarTransferencia(
    String id, {
    required int sucursalOrigenId,
  }) async {
    try {
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id/enviar',
        method: 'POST',
        body: <String, dynamic>{
          'sucursalOrigenId': sucursalOrigenId,
        },
      );

      // Invalidar caché
      _invalidateRelatedCache(id);

      // Si la respuesta es parcial, construimos un objeto TransferenciaInventario con los datos mínimos
      final data = response['data'];
      if (data != null && !data.containsKey('estado')) {
        return TransferenciaInventario(
          id: int.parse(id),
          estado: EstadoTransferencia.enviado,
          sucursalDestinoId: data['sucursalDestinoId'],
          nombreSucursalDestino: 'Pendiente de actualizar',
          modificable: false,
        );
      }

      return TransferenciaInventario.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error al enviar transferencia $id: $e');
      rethrow;
    }
  }

  /// Recibe una transferencia de inventario
  Future<TransferenciaInventario> recibirTransferencia(String id) async {
    try {
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id/recibir',
        method: 'POST',
      );

      // Invalidar caché
      _invalidateRelatedCache(id);

      return TransferenciaInventario.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error al recibir transferencia $id: $e');
      rethrow;
    }
  }

  /// Cancela una transferencia de inventario
  Future<bool> cancelarTransferencia(String id) async {
    try {
      await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id/cancelar',
        method: 'POST',
      );

      // Invalidar caché
      _invalidateRelatedCache(id);

      return true;
    } catch (e) {
      debugPrint('Error al cancelar transferencia $id: $e');
      return false;
    }
  }

  /// Agrega items a una transferencia
  Future<TransferenciaInventario> agregarItems({
    required String id,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id/items',
        method: 'POST',
        body: <String, dynamic>{'items': items},
      );

      // Invalidar caché
      _invalidateRelatedCache(id);

      return TransferenciaInventario.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error al agregar items a transferencia $id: $e');
      rethrow;
    }
  }

  /// Actualiza un item de una transferencia
  Future<TransferenciaInventario> actualizarItem({
    required String id,
    required String itemId,
    required int cantidad,
  }) async {
    try {
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id/items/$itemId',
        method: 'PATCH',
        body: <String, dynamic>{'cantidad': cantidad},
      );

      // Invalidar caché
      _invalidateRelatedCache(id);

      return TransferenciaInventario.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error al actualizar item $itemId de transferencia $id: $e');
      rethrow;
    }
  }

  /// Elimina un item de una transferencia
  Future<TransferenciaInventario> eliminarItem({
    required String id,
    required String itemId,
  }) async {
    try {
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id/items/$itemId',
        method: 'DELETE',
      );

      // Invalidar caché
      _invalidateRelatedCache(id);

      return TransferenciaInventario.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error al eliminar item $itemId de transferencia $id: $e');
      rethrow;
    }
  }

  /// Elimina una transferencia de inventario
  Future<bool> eliminarTransferencia(String id) async {
    try {
      await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id',
        method: 'DELETE',
      );

      // Invalidar caché
      _invalidateRelatedCache(id);

      return true;
    } catch (e) {
      debugPrint('Error al eliminar transferencia $id: $e');
      return false;
    }
  }

  /// Compara el stock de una transferencia entre sucursales
  Future<ComparacionTransferencia> compararTransferencia({
    required String id,
    required int sucursalOrigenId,
    bool useCache = true,
  }) async {
    try {
      final String cacheKey =
          '${_prefixMovimiento}comparacion_${id}_$sucursalOrigenId';

      // Verificar caché
      if (useCache) {
        final ComparacionTransferencia? cached = _cache.get(cacheKey);
        if (cached != null) {
          debugPrint('Comparación obtenida desde caché: $cacheKey');
          return cached;
        }
      }

      // Realizar petición
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: '$_endpoint/$id/comparar',
        method: 'POST',
        body: <String, dynamic>{
          'sucursalOrigenId': sucursalOrigenId,
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw ApiException(
          message: 'Tiempo de espera agotado al comparar transferencia',
          statusCode: 408,
          errorCode: ApiConstants.errorCodes[408] ?? ApiConstants.unknownError,
        ),
      );

      // Procesar respuesta
      final ComparacionTransferencia comparacion =
          _processComparacionResponse(response);

      // Guardar en caché si es necesario
      if (useCache) {
        _cache.set(cacheKey, comparacion);
      }

      return comparacion;
    } catch (e) {
      debugPrint('Error al comparar transferencia $id: $e');
      rethrow;
    }
  }

  /// Obtiene todas las transferencias sin filtrar por sucursal
  Future<PaginatedResponse<TransferenciaInventario>> getAllTransferencias({
    String? estado,
    bool forceRefresh = false,
    int? page,
    int? pageSize,
    String? sortBy,
    String? order,
  }) async {
    try {
      // Preparar parámetros de consulta
      final Map<String, String> queryParams = <String, String>{
        if (estado != null) 'estado': estado,
        if (page != null) 'page': page.toString(),
        if (pageSize != null) 'page_size': pageSize.toString(),
        if (sortBy != null) 'sort_by': sortBy,
        if (order != null) 'order': order,
      };

      // Realizar petición
      final Map<String, dynamic> response = await _api
          .authenticatedRequest(
            endpoint: _endpoint,
            method: 'GET',
            queryParams: queryParams,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw ApiException(
              message: 'Tiempo de espera agotado al obtener transferencias',
              statusCode: 408,
              errorCode:
                  ApiConstants.errorCodes[408] ?? ApiConstants.unknownError,
            ),
          );

      // Procesar respuesta usando PaginatedResponse
      return PaginatedResponse.fromApiResponse(
        response,
        (Map<String, dynamic> json) => TransferenciaInventario.fromJson(json),
      );
    } catch (e) {
      debugPrint('Error al obtener todas las transferencias: $e');
      rethrow;
    }
  }

  // Métodos privados de ayuda
  String _generateCacheKey({
    String? sucursalId,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? sortBy,
    String? order,
    int? page,
    int? pageSize,
  }) {
    final List<String> components = <String>[_prefixListaMovimientos];

    if (sucursalId != null) {
      components.add('s:$sucursalId');
    }
    if (estado != null) {
      components.add('e:$estado');
    }
    if (fechaInicio != null) {
      components.add('fi:${fechaInicio.toIso8601String()}');
    }
    if (fechaFin != null) {
      components.add('ff:${fechaFin.toIso8601String()}');
    }
    if (sortBy != null) {
      components.add('sb:$sortBy');
    }
    if (order != null) {
      components.add('o:$order');
    }
    if (page != null) {
      components.add('p:$page');
    }
    if (pageSize != null) {
      components.add('ps:$pageSize');
    }

    return components.join('_');
  }

  void _invalidateRelatedCache(String id) {
    _cache
      ..invalidate('$_prefixMovimiento$id')
      ..invalidateByPattern(_prefixListaMovimientos);
    debugPrint('Caché invalidado para transferencia $id');
  }

  TransferenciaInventario _processTransferenciaResponse(
      Map<String, dynamic> response, String id) {
    Map<String, dynamic> data;

    if (response.containsKey('data')) {
      data = Map<String, dynamic>.from(response['data']);
    } else {
      data = Map<String, dynamic>.from(response);
    }

    if (!data.containsKey('id')) {
      data['id'] = id;
    }

    return TransferenciaInventario.fromJson(data);
  }

  ComparacionTransferencia _processComparacionResponse(
      Map<String, dynamic> response) {
    Map<String, dynamic> data;

    if (response.containsKey('data')) {
      data = Map<String, dynamic>.from(response['data']);
    } else {
      data = Map<String, dynamic>.from(response);
    }

    return ComparacionTransferencia.fromJson(data);
  }
}
