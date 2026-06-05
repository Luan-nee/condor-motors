import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/repositories/index.repository.dart';

/// Repositorio para gestionar operaciones de facturación electrónica y SUNAT.
///
/// Encapsula la lógica de negocio y consumo de APIs de facturación,
/// delegando la autenticación mediante el mixin [AuthDelegator].
class FacturacionRepository with AuthDelegator implements BaseRepository {
  static final FacturacionRepository _instance =
      FacturacionRepository._internal();
  static FacturacionRepository get instance => _instance;

  FacturacionRepository._internal();

  /// Declara una venta a SUNAT.
  Future<Map<String, dynamic>> declararVenta({
    required String ventaId,
    String? sucursalId,
    bool enviarCliente = false,
  }) async {
    final String sucursalIdFinal =
        sucursalId ?? await getCurrentSucursalId() ?? '';
    if (sucursalIdFinal.isEmpty) {
      throw Exception('No se pudo obtener el ID de sucursal');
    }

    final int ventaIdInt = int.tryParse(ventaId) ?? 0;
    if (ventaIdInt <= 0) {
      throw Exception('ID de venta inválido: $ventaId');
    }

    return api_index.api.facturacion.declararVenta(
      ventaId: ventaIdInt,
      sucursalId: sucursalIdFinal,
      enviarCliente: enviarCliente,
    );
  }

  /// Sincroniza un documento tributario con SUNAT.
  Future<Map<String, dynamic>> sincronizarDocumento({
    required String documentoId,
    String? sucursalId,
  }) async {
    final String sucursalIdFinal =
        sucursalId ?? await getCurrentSucursalId() ?? '';
    if (sucursalIdFinal.isEmpty) {
      throw Exception('No se pudo obtener el ID de sucursal');
    }

    final int documentoIdInt = int.tryParse(documentoId) ?? 0;
    if (documentoIdInt <= 0) {
      throw Exception('ID de documento inválido: $documentoId');
    }

    return api_index.api.facturacion.sincronizarDocumento(
      documentoId: documentoIdInt,
      sucursalId: sucursalIdFinal,
    );
  }

  /// Anula un documento tributario facturado.
  Future<Map<String, dynamic>> anularDocumento({
    required String documentoId,
    required String motivo,
    String? sucursalId,
  }) async {
    final String sucursalIdFinal =
        sucursalId ?? await getCurrentSucursalId() ?? '';
    if (sucursalIdFinal.isEmpty) {
      throw Exception('No se pudo obtener el ID de sucursal');
    }

    final int documentoIdInt = int.tryParse(documentoId) ?? 0;
    if (documentoIdInt <= 0) {
      throw Exception('ID de documento inválido: $documentoId');
    }

    return api_index.api.facturacion.anularDocumento(
      documentoId: documentoIdInt,
      sucursalId: sucursalIdFinal,
      motivo: motivo,
    );
  }
}
