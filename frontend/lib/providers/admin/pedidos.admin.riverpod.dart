import 'dart:async';
import 'package:condorsmotors/models/cliente.model.dart';
import 'package:condorsmotors/models/pedido.model.dart';
import 'package:condorsmotors/repositories/cliente.repository.dart';
import 'package:condorsmotors/repositories/pedido.repository.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pedidos.admin.riverpod.g.dart';

/// Modelo de datos encapsulado para el estado del módulo de pedidos.
class PedidosAdminData {
  final List<PedidoExclusivo> pedidos;
  final Map<int, Cliente> clientes;

  PedidosAdminData({
    required this.pedidos,
    required this.clientes,
  });

  PedidosAdminData copyWith({
    List<PedidoExclusivo>? pedidos,
    Map<int, Cliente>? clientes,
  }) {
    return PedidosAdminData(
      pedidos: pedidos ?? this.pedidos,
      clientes: clientes ?? this.clientes,
    );
  }
}

/// Notifier para la gestión de pedidos exclusivos en el panel administrativo.
///
/// Utiliza el patrón [AsyncNotifier] de Riverpod 2.x para garantizar
/// consistencia de estado reactivo y desacoplamiento de red.
@riverpod
class PedidosAdmin extends _$PedidosAdmin {
  late final PedidoRepository _pedidoRepository;
  late final ClienteRepository _clienteRepository;

  @override
  FutureOr<PedidosAdminData> build() {
    _pedidoRepository = PedidoRepository.instance;
    _clienteRepository = ClienteRepository.instance;
    return _fetchDatos();
  }

  /// Recupera los pedidos y carga en paralelo los clientes relacionados.
  Future<PedidosAdminData> _fetchDatos({String? filtroEstado}) async {
    final pedidos = await _pedidoRepository.getPedidosExclusivos(
      filtroEstado: filtroEstado != null && filtroEstado != 'Todos' 
          ? filtroEstado.toLowerCase() 
          : null,
    );

    final Map<int, Cliente> clientesMap = {};
    final clienteIds = pedidos.map((p) => p.clienteId).toSet();

    // Consultas concurrentes en paralelo para optimizar la red
    await Future.wait(clienteIds.map((id) async {
      try {
        final cliente = await _clienteRepository.obtenerCliente(id.toString());
        clientesMap[id] = cliente;
      } catch (e) {
        debugPrint('No se pudo cargar cliente $id: $e');
      }
    }));

    return PedidosAdminData(
      pedidos: pedidos,
      clientes: clientesMap,
    );
  }

  /// Carga o recarga la lista de pedidos con filtros opcionales.
  Future<void> cargarPedidos({String? filtroEstado}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchDatos(filtroEstado: filtroEstado));
  }

  /// Elimina un pedido exclusivo del servidor y refresca el estado local.
  Future<bool> eliminarPedido(int id) async {
    state = const AsyncLoading();
    bool exito = false;
    state = await AsyncValue.guard(() async {
      exito = await _pedidoRepository.deletePedidoExclusivo(id);
      return _fetchDatos();
    });
    return exito;
  }
}
