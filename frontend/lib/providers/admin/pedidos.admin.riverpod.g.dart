// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pedidos.admin.riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pedidosAdminHash() => r'9ec0aa2109efe5ad251752a49cbb038de596c323';

/// Notifier para la gestión de pedidos exclusivos en el panel administrativo.
///
/// Utiliza el patrón [AsyncNotifier] de Riverpod 2.x para garantizar
/// consistencia de estado reactivo y desacoplamiento de red.
///
/// Copied from [PedidosAdmin].
@ProviderFor(PedidosAdmin)
final pedidosAdminProvider =
    AutoDisposeAsyncNotifierProvider<PedidosAdmin, PedidosAdminData>.internal(
      PedidosAdmin.new,
      name: r'pedidosAdminProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pedidosAdminHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PedidosAdmin = AutoDisposeAsyncNotifier<PedidosAdminData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
