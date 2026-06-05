// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'empleados.admin.riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$empleadosAdminHash() => r'3497bab228bbf5ecf61ab0349f9fbf071ddf0a77';

/// Notifier para la gestión de colaboradores en el panel de administración.
///
/// Patron: [AsyncNotifier] de Riverpod 2.x.
/// Maneja la agregación de datos de múltiples fuentes de forma reactiva e inmutable.
///
/// Copied from [EmpleadosAdmin].
@ProviderFor(EmpleadosAdmin)
final empleadosAdminProvider =
    AutoDisposeAsyncNotifierProvider<
      EmpleadosAdmin,
      EmpleadosAdminData
    >.internal(
      EmpleadosAdmin.new,
      name: r'empleadosAdminProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$empleadosAdminHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$EmpleadosAdmin = AutoDisposeAsyncNotifier<EmpleadosAdminData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
