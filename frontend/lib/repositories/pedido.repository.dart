import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/models/pedido.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';

/// Repositorio para gestionar pedidos exclusivos.
///
/// Encapsula la lógica de negocio y consumo de APIs de pedidos exclusivos,
/// delegando la autenticación mediante el mixin [AuthDelegator].
class PedidoRepository with AuthDelegator implements BaseRepository {
  static final PedidoRepository _instance = PedidoRepository._internal();
  static PedidoRepository get instance => _instance;

  PedidoRepository._internal();

  /// Obtiene todos los pedidos exclusivos filtrados opcionalmente por estado.
  Future<List<PedidoExclusivo>> getPedidosExclusivos({String? filtroEstado}) =>
      api_index.api.pedidos.exclusivos.getPedidosExclusivos();

  /// Obtiene un pedido exclusivo por su ID.
  Future<PedidoExclusivo> getPedidoExclusivo(int id) =>
      api_index.api.pedidos.exclusivos.getPedidoExclusivo(id);

  /// Crea un nuevo pedido exclusivo.
  Future<PedidoExclusivo> createPedidoExclusivo(PedidoExclusivo pedido) =>
      api_index.api.pedidos.exclusivos.createPedidoExclusivo(pedido);

  /// Actualiza un pedido exclusivo existente.
  Future<PedidoExclusivo> updatePedidoExclusivo(int id, PedidoExclusivo pedido) =>
      api_index.api.pedidos.exclusivos.updatePedidoExclusivo(id, pedido);

  /// Elimina un pedido exclusivo.
  Future<bool> deletePedidoExclusivo(int id) =>
      api_index.api.pedidos.exclusivos.deletePedidoExclusivo(id);
}
