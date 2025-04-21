import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/models/pedido.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/foundation.dart';

/// Repositorio para gestionar pedidos exclusivos
///
/// Actúa como intermediario entre la UI y la API
class PedidoRepository implements BaseRepository {
  /// Instancia singleton del repositorio
  static final PedidoRepository _instance = PedidoRepository._internal();

  /// Getter para la instancia singleton
  static PedidoRepository get instance => _instance;

  /// Constructor privado para el patrón singleton
  PedidoRepository._internal();

  /// Obtiene datos del usuario desde la API centralizada
  @override
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      return await api.getUserData();
    } catch (e) {
      debugPrint('Error en PedidoRepository.getUserData: $e');
      return null;
    }
  }

  /// Obtiene el ID de la sucursal del usuario actual
  ///
  /// Útil para operaciones que requieren el ID de sucursal automáticamente
  @override
  Future<String?> getCurrentSucursalId() async {
    try {
      final userData = await getUserData();
      if (userData == null) {
        return null;
      }
      return userData['sucursalId']?.toString();
    } catch (e) {
      debugPrint('Error en PedidoRepository.getCurrentSucursalId: $e');
      return null;
    }
  }

  /// Obtiene todos los pedidos exclusivos
  ///
  /// [filtroEstado] Opcional, filtra por estado de pedido
  Future<List<PedidoExclusivo>> getPedidosExclusivos(
      {String? filtroEstado}) async {
    try {
      final pedidos = await api.pedidos.exclusivos.getPedidosExclusivos();
      return pedidos;
    } catch (e) {
      debugPrint('Error en PedidoRepository.getPedidosExclusivos: $e');
      rethrow;
    }
  }

  /// Obtiene un pedido exclusivo por su ID
  ///
  /// [id] ID del pedido a obtener
  Future<PedidoExclusivo> getPedidoExclusivo(int id) async {
    try {
      return await api.pedidos.exclusivos.getPedidoExclusivo(id);
    } catch (e) {
      debugPrint('Error en PedidoRepository.getPedidoExclusivo: $e');
      rethrow;
    }
  }

  /// Crea un nuevo pedido exclusivo
  ///
  /// [pedido] Datos del pedido a crear
  Future<PedidoExclusivo> createPedidoExclusivo(PedidoExclusivo pedido) async {
    try {
      return await api.pedidos.exclusivos.createPedidoExclusivo(pedido);
    } catch (e) {
      debugPrint('Error en PedidoRepository.createPedidoExclusivo: $e');
      rethrow;
    }
  }

  /// Actualiza un pedido exclusivo existente
  ///
  /// [id] ID del pedido a actualizar
  /// [pedido] Nuevos datos del pedido
  Future<PedidoExclusivo> updatePedidoExclusivo(
      int id, PedidoExclusivo pedido) async {
    try {
      return await api.pedidos.exclusivos.updatePedidoExclusivo(id, pedido);
    } catch (e) {
      debugPrint('Error en PedidoRepository.updatePedidoExclusivo: $e');
      rethrow;
    }
  }

  /// Elimina un pedido exclusivo
  ///
  /// [id] ID del pedido a eliminar
  Future<bool> deletePedidoExclusivo(int id) async {
    try {
      return await api.pedidos.exclusivos.deletePedidoExclusivo(id);
    } catch (e) {
      debugPrint('Error en PedidoRepository.deletePedidoExclusivo: $e');
      rethrow;
    }
  }
}
