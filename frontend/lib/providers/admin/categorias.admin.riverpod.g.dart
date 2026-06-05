// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categorias.admin.riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$categoriasAdminHash() => r'38083b56e3af829e9327832e00e809c9e9481e89';

/// Notifier para la gestión de categorías en el panel de administración.
///
/// Patron: [AsyncNotifier] de Riverpod 2.x.
/// Resuelve el bug sistemático de limpieza de errores y elimina el boilerplate.
///
/// Copied from [CategoriasAdmin].
@ProviderFor(CategoriasAdmin)
final categoriasAdminProvider =
    AutoDisposeAsyncNotifierProvider<CategoriasAdmin, List<Categoria>>.internal(
      CategoriasAdmin.new,
      name: r'categoriasAdminProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$categoriasAdminHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CategoriasAdmin = AutoDisposeAsyncNotifier<List<Categoria>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
