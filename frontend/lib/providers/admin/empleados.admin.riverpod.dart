import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/repositories/empleado.repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'empleados.admin.riverpod.g.dart';

class EmpleadosAdminState {
  final bool isLoading;
  final List<Empleado> empleados;
  final Map<String, String> nombresSucursales;
  final List<Map<String, dynamic>> rolesCuentas;
  final String? errorMessage;

  EmpleadosAdminState({
    this.isLoading = false,
    this.empleados = const [],
    this.nombresSucursales = const {},
    this.rolesCuentas = const [],
    this.errorMessage,
  });

  EmpleadosAdminState copyWith({
    bool? isLoading,
    List<Empleado>? empleados,
    Map<String, String>? nombresSucursales,
    List<Map<String, dynamic>>? rolesCuentas,
    String? errorMessage,
  }) {
    return EmpleadosAdminState(
      isLoading: isLoading ?? this.isLoading,
      empleados: empleados ?? this.empleados,
      nombresSucursales: nombresSucursales ?? this.nombresSucursales,
      rolesCuentas: rolesCuentas ?? this.rolesCuentas,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

@riverpod
class EmpleadosAdmin extends _$EmpleadosAdmin {
  late final EmpleadoRepository _empleadoRepository;

  @override
  EmpleadosAdminState build() {
    _empleadoRepository = EmpleadoRepository.instance;
    Future.microtask(cargarDatos);
    return EmpleadosAdminState();
  }

  Future<void> cargarDatos() async {
    state = state.copyWith(isLoading: true);
    try {
      final sucursalesFuture = _empleadoRepository.getNombresSucursales();
      final empleadosFuture = _empleadoRepository.getEmpleados(useCache: false);
      final rolesFuture = _empleadoRepository.getRolesCuentas();

      final results = await Future.wait([
        sucursalesFuture,
        empleadosFuture,
        rolesFuture,
      ]);

      state = state.copyWith(
        nombresSucursales: results[0] as Map<String, String>,
        empleados: (results[1] as EmpleadosPaginados).empleados,
        rolesCuentas: results[2] as List<Map<String, dynamic>>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al cargar datos: $e',
        isLoading: false,
      );
    }
  }

  Future<void> eliminarEmpleado(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _empleadoRepository.deleteEmpleado(id);
      await cargarDatos();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al eliminar: $e',
        isLoading: false,
      );
      rethrow;
    }
  }

  void limpiarError() {
    state = state.copyWith();
  }
}
