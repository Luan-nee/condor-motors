import 'dart:developer';
import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/models/pedido.model.dart';

class PedidosApi {
  final ApiClient _api;
  late final PedidosExclusivosApi _pedidosExclusivos;

  PedidosApi(this._api) {
    _pedidosExclusivos = PedidosExclusivosApi(_api);
  }

  // Método para acceder a la API de pedidos exclusivos
  PedidosExclusivosApi get exclusivos => _pedidosExclusivos;
}

class PedidosExclusivosApi {
  final ApiClient _apiClient;

  PedidosExclusivosApi(this._apiClient);
  // Obtener un pedido exclusivo por ID
  Future<PedidoExclusivo> getPedidoExclusivo(int id) async {
    try {
      final response = await _apiClient.request(
        endpoint: '/pedidosexclusivos/$id',
        method: 'GET',
        requiresAuth: true,
      );
      return PedidoExclusivo.fromJson(response['data']);
    } catch (e) {
      log('Error en getPedidoExclusivo: $e');
      rethrow;
    }
  }

  // Crear un nuevo pedido exclusivo
  Future<PedidoExclusivo> createPedidoExclusivo(PedidoExclusivo pedido) async {
    try {
      final response = await _apiClient.request(
        endpoint: '/pedidosexclusivos',
        method: 'POST',
        body: pedido.toJson(),
        requiresAuth: true,
      );
      return PedidoExclusivo.fromJson(response['data']);
    } catch (e) {
      log('Error en createPedidoExclusivo: $e');
      rethrow;
    }
  }

  // Actualizar un pedido exclusivo existente
  Future<PedidoExclusivo> updatePedidoExclusivo(
      int id, PedidoExclusivo pedido) async {
    try {
      final response = await _apiClient.request(
        endpoint: '/pedidosexclusivos/$id',
        method: 'PATCH',
        body: pedido.toJson(),
        requiresAuth: true,
      );
      return PedidoExclusivo.fromJson(response['data']);
    } catch (e) {
      log('Error en updatePedidoExclusivo: $e');
      rethrow;
    }
  }

  // Eliminar un pedido exclusivo
  Future<bool> deletePedidoExclusivo(int id) async {
    try {
      await _apiClient.request(
        endpoint: '/pedidosexclusivos/$id',
        method: 'DELETE',
        requiresAuth: true,
      );
      return true;
    } catch (e) {
      log('Error en deletePedidoExclusivo: $e');
      rethrow;
    }
  }

  // Obtener lista de pedidos exclusivos
  Future<List<PedidoExclusivo>> getPedidosExclusivos() async {
    try {
      final response = await _apiClient.request(
        endpoint: '/pedidosexclusivos',
        method: 'GET',
        requiresAuth: true,
      );
      final List<dynamic> data = response['data'] as List<dynamic>;
      return PedidoExclusivo.fromJsonList(data);
    } catch (e) {
      log('Error en getPedidosExclusivos: $e');
      rethrow;
    }
  }
}
