// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marcas.admin.riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$marcasAdminHash() => r'bfb95bccfa719eb471828902e527eb5a9f5e08d9';

/// Notifier para la gestión de marcas en el panel de administración.
///
/// Patron: [AsyncNotifier] de Riverpod 2.x.
/// Maneja el estado asíncrono nativamente mediante [AsyncValue].
///
/// Copied from [MarcasAdmin].
@ProviderFor(MarcasAdmin)
final marcasAdminProvider =
    AutoDisposeAsyncNotifierProvider<MarcasAdmin, List<Marca>>.internal(
      MarcasAdmin.new,
      name: r'marcasAdminProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$marcasAdminHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MarcasAdmin = AutoDisposeAsyncNotifier<List<Marca>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
