import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/api/protected/cache/fast_cache.dart';
import 'package:condorsmotors/utils/logger.dart';

/// API para gestionar la facturación electrónica y declaración SUNAT
class FacturacionApi {
  final ApiClient _api;
  final FastCache _cache = FastCache(maxSize: 50);

  // Prefijos para las claves de caché
  static const String _prefixDocumentos = 'documentos_facturacion_';

  FacturacionApi(this._api);

  /// Invalida el caché para una sucursal específica o para todas las sucursales
  ///
  /// [sucursalId] - ID de la sucursal (opcional)
  void invalidateCache([sucursalId]) {
    if (sucursalId != null) {
      // Convertir a String en caso de recibir un entero
      final String sucursalIdStr = sucursalId.toString();

      // Invalidar solo los documentos de esta sucursal
      _cache.invalidateByPattern('$_prefixDocumentos$sucursalIdStr');
      logCache('Caché de documentos invalidado para sucursal $sucursalIdStr');
    } else {
      // Invalidar todos los documentos en caché
      _cache.invalidateByPattern(_prefixDocumentos);
      logCache('Caché de documentos invalidado completamente');
    }
    logCache('Entradas en caché después de invalidación: ${_cache.size}');
  }

  /// Declara una venta a SUNAT
  ///
  /// Esta función implementa directamente la estructura de DeclareVentaDto
  /// [ventaId] - ID de la venta a declarar
  /// [sucursalId] - ID de la sucursal (requerido)
  /// [enviarCliente] - Indica si se debe enviar el comprobante al cliente
  /// [invalidarCacheVentas] - Indica si se debe invalidar también el caché de ventas
  Future<Map<String, dynamic>> declararVenta({
    required int ventaId,
    required String sucursalId,
    bool enviarCliente = false,
    bool invalidarCacheVentas = true,
  }) async {
    try {
      Logger.debug('Declarando venta $ventaId a SUNAT desde FacturacionApi');
      // Construir el endpoint para la declaración
      final String endpoint = '/$sucursalId/facturacion/declarar';

      // Preparar el cuerpo de la solicitud según DeclareVentaDto
      final Map<String, dynamic> body = {
        'ventaId': ventaId,
        'enviarCliente': enviarCliente,
      };

      // Realizar la solicitud
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: endpoint,
        method: 'POST',
        body: body,
      );

      // Invalidar caché de facturación
      invalidateCache(sucursalId);

      // Invalidar caché de ventas si es necesario
      if (invalidarCacheVentas) {
        try {
          Logger.debug(
              'Intentando invalidar caché de ventas tras declaración SUNAT');
          // Usamos la referencia global a api.ventas importada de index.api.dart
          api.ventas.invalidateCache(sucursalId);
          Logger.debug(
              'Caché de ventas invalidado correctamente tras declaración SUNAT');
        } catch (e) {
          Logger.debug('No se pudo invalidar caché de ventas: $e');
        }
      }

      // Procesar respuesta para mantener consistencia con el formato de VentasApi
      Map<String, dynamic> resultData;
      if (response.containsKey('data') && response['data'] != null) {
        resultData = response['data'];
      } else {
        resultData = response;
      }

      return {
        'data': resultData,
        'status': response['status'] ?? 'success',
        'message': response['message'] ?? 'Venta declarada correctamente',
      };
    } catch (e) {
      Logger.error('Error al declarar venta: $e');
      rethrow;
    }
  }

  /// Sincroniza un documento con SUNAT
  ///
  /// [documentoId] - ID del documento a sincronizar
  /// [sucursalId] - ID de la sucursal
  Future<Map<String, dynamic>> sincronizarDocumento({
    required int documentoId,
    required String sucursalId,
  }) async {
    try {
      Logger.debug('Sincronizando documento $documentoId con SUNAT');

      // Construir el endpoint para la sincronización
      final String endpoint = '/$sucursalId/facturacion/sincronizar';

      // Preparar el cuerpo de la solicitud
      final Map<String, dynamic> body = {
        'documentoId': documentoId,
      };

      // Realizar la solicitud
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: endpoint,
        method: 'POST',
        body: body,
      );

      // Invalidar caché después de sincronizar
      invalidateCache(sucursalId);

      return response;
    } catch (e) {
      Logger.error('Error al sincronizar documento: $e');
      rethrow;
    }
  }

  /// Anula un documento facturado
  ///
  /// [documentoId] - ID del documento a anular
  /// [sucursalId] - ID de la sucursal
  /// [motivo] - Motivo de la anulación
  Future<Map<String, dynamic>> anularDocumento({
    required int documentoId,
    required String sucursalId,
    required String motivo,
  }) async {
    try {
      Logger.debug('Anulando documento $documentoId en SUNAT');

      // Construir el endpoint para la anulación
      final String endpoint = '/$sucursalId/facturacion/anular';

      // Preparar el cuerpo de la solicitud
      final Map<String, dynamic> body = {
        'documentoId': documentoId,
        'motivo': motivo,
      };

      // Realizar la solicitud
      final Map<String, dynamic> response = await _api.authenticatedRequest(
        endpoint: endpoint,
        method: 'POST',
        body: body,
      );

      // Invalidar caché después de anular
      invalidateCache(sucursalId);

      return response;
    } catch (e) {
      Logger.error('Error al anular documento: $e');
      rethrow;
    }
  }
}
