import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/repositories/empleado.repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'empleados.admin.riverpod.g.dart';

/// Datos estructurados para el estado del módulo de administración de empleados.
class EmpleadosAdminData {
  final List<Empleado> empleados;
  final Map<String, String> nombresSucursales;
  final List<Map<String, dynamic>> rolesCuentas;

  EmpleadosAdminData({
    required this.empleados,
    required this.nombresSucursales,
    required this.rolesCuentas,
  });
}

/// Notifier para la gestión de colaboradores en el panel de administración.
///
/// Patron: [AsyncNotifier] de Riverpod 2.x.
/// Maneja la agregación de datos de múltiples fuentes de forma reactiva e inmutable.
@riverpod
class EmpleadosAdmin extends _$EmpleadosAdmin {
  final EmpleadoRepository _empleadoRepository = EmpleadoRepository.instance;

  @override
  FutureOr<EmpleadosAdminData> build() {
    return _fetchDatos();
  }

  /// Método privado para agrupar las peticiones concurrentes
  Future<EmpleadosAdminData> _fetchDatos() async {
    final sucursalesFuture = _empleadoRepository.getNombresSucursales();
    final empleadosFuture = _empleadoRepository.getEmpleados(useCache: false);
    final rolesFuture = _empleadoRepository.getRolesCuentas();

    final results = await Future.wait([
      sucursalesFuture,
      empleadosFuture,
      rolesFuture,
    ]);

    return EmpleadosAdminData(
      nombresSucursales: results[0] as Map<String, String>,
      empleados: (results[1] as EmpleadosPaginados).empleados,
      rolesCuentas: results[2] as List<Map<String, dynamic>>,
    );
  }

  /// Carga o recarga los datos desde la API
  Future<void> cargarDatos() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchDatos);
  }

  /// Elimina un colaborador por su ID
  ///
  /// Lanza la excepción para que el ScaffoldMessenger capture el error en la UI.
  Future<void> eliminarEmpleado(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _empleadoRepository.deleteEmpleado(id);
      return _fetchDatos();
    });
  }

  /// Limpia el estado de error y retorna al último valor de datos disponible
  void limpiarError() {
    final currentVal = state.value;
    if (currentVal != null) {
      state = AsyncData(currentVal);
    }
  }
}
