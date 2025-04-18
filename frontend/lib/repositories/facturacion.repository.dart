import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/foundation.dart';

/// Repositorio para gestionar operaciones de facturación electrónica y SUNAT
class FacturacionRepository implements BaseRepository {
  /// Instancia singleton del repositorio
  static final FacturacionRepository _instance =
      FacturacionRepository._internal();

  /// Getter para la instancia singleton
  static FacturacionRepository get instance => _instance;

  /// Constructor privado para el patrón singleton
  FacturacionRepository._internal();

  /// Obtiene datos del usuario desde la API centralizada
  @override
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      return await api.getUserData();
    } catch (e) {
      debugPrint('Error en FacturacionRepository.getUserData: $e');
      return null;
    }
  }

  /// Obtiene el ID de la sucursal del usuario actual
  @override
  Future<String?> getCurrentSucursalId() async {
    try {
      final userData = await getUserData();
      if (userData == null) {
        return null;
      }

      final sucursalId = userData['sucursalId'];
      if (sucursalId == null) {
        return null;
      }

      return sucursalId.toString();
    } catch (e) {
      debugPrint('Error en FacturacionRepository.getCurrentSucursalId: $e');
      return null;
    }
  }

  /// Declara una venta a SUNAT
  ///
  /// [ventaId] - ID de la venta a declarar
  /// [sucursalId] - ID de la sucursal (si no se proporciona, se usará la del usuario)
  /// [enviarCliente] - Indica si se debe enviar el comprobante al cliente
  Future<Map<String, dynamic>> declararVenta({
    required String ventaId,
    String? sucursalId,
    bool enviarCliente = false,
  }) async {
    try {
      // Obtener el ID de sucursal si no se proporciona
      final String sucursalIdFinal =
          sucursalId ?? await getCurrentSucursalId() ?? '';
      if (sucursalIdFinal.isEmpty) {
        throw Exception('No se pudo obtener el ID de sucursal');
      }

      // Convertir el ID de venta a entero
      final int ventaIdInt = int.tryParse(ventaId) ?? 0;
      if (ventaIdInt <= 0) {
        throw Exception('ID de venta inválido: $ventaId');
      }

      // Llamar a la API de facturación
      return await api.facturacion.declararVenta(
        ventaId: ventaIdInt,
        sucursalId: sucursalIdFinal,
        enviarCliente: enviarCliente,
      );
    } catch (e) {
      debugPrint('Error en FacturacionRepository.declararVenta: $e');
      rethrow;
    }
  }

  /// Sincroniza un documento con SUNAT
  ///
  /// [documentoId] - ID del documento a sincronizar
  /// [sucursalId] - ID de la sucursal (si no se proporciona, se usará la del usuario)
  Future<Map<String, dynamic>> sincronizarDocumento({
    required String documentoId,
    String? sucursalId,
  }) async {
    try {
      // Obtener el ID de sucursal si no se proporciona
      final String sucursalIdFinal =
          sucursalId ?? await getCurrentSucursalId() ?? '';
      if (sucursalIdFinal.isEmpty) {
        throw Exception('No se pudo obtener el ID de sucursal');
      }

      // Convertir el ID de documento a entero
      final int documentoIdInt = int.tryParse(documentoId) ?? 0;
      if (documentoIdInt <= 0) {
        throw Exception('ID de documento inválido: $documentoId');
      }

      // Llamar a la API de facturación
      return await api.facturacion.sincronizarDocumento(
        documentoId: documentoIdInt,
        sucursalId: sucursalIdFinal,
      );
    } catch (e) {
      debugPrint('Error en FacturacionRepository.sincronizarDocumento: $e');
      rethrow;
    }
  }

  /// Anula un documento facturado
  ///
  /// [documentoId] - ID del documento a anular
  /// [motivo] - Motivo de la anulación
  /// [sucursalId] - ID de la sucursal (si no se proporciona, se usará la del usuario)
  Future<Map<String, dynamic>> anularDocumento({
    required String documentoId,
    required String motivo,
    String? sucursalId,
  }) async {
    try {
      // Obtener el ID de sucursal si no se proporciona
      final String sucursalIdFinal =
          sucursalId ?? await getCurrentSucursalId() ?? '';
      if (sucursalIdFinal.isEmpty) {
        throw Exception('No se pudo obtener el ID de sucursal');
      }

      // Convertir el ID de documento a entero
      final int documentoIdInt = int.tryParse(documentoId) ?? 0;
      if (documentoIdInt <= 0) {
        throw Exception('ID de documento inválido: $documentoId');
      }

      // Llamar a la API de facturación
      return await api.facturacion.anularDocumento(
        documentoId: documentoIdInt,
        sucursalId: sucursalIdFinal,
        motivo: motivo,
      );
    } catch (e) {
      debugPrint('Error en FacturacionRepository.anularDocumento: $e');
      rethrow;
    }
  }
}
