import 'package:condorsmotors/api/main.api.dart' show ApiException;
import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:condorsmotors/utils/empleados_utils.dart';
import 'package:flutter/material.dart';

/// Provider para gestionar los empleados/colaboradores en el panel de administración
class EmpleadoProvider extends ChangeNotifier {
  // Repositorio para acceder a los empleados
  final EmpleadoRepository _empleadoRepository;

  // Estados
  bool _isLoading = false;
  bool _isCuentaLoading = false;
  String _errorMessage = '';
  List<Empleado> _empleados = <Empleado>[];
  Map<String, String> _nombresSucursales = <String, String>{};
  List<Map<String, dynamic>> _rolesCuentas = <Map<String, dynamic>>[];

  // Lista de roles disponibles
  final List<String> _roles = <String>[
    'Administrador',
    'Vendedor',
    'Computadora'
  ];

  // Constantes para manejar errores comunes
  static const List<String> _errorNotFoundResponses = <String>[
    '404',
    'not found',
    'no encontrado',
    'no existe',
    'empleado no tiene cuenta'
  ];

  // Getters
  bool get isLoading => _isLoading;
  bool get isCuentaLoading => _isCuentaLoading;
  String get errorMessage => _errorMessage;
  List<Empleado> get empleados => _empleados;
  Map<String, String> get nombresSucursales => _nombresSucursales;
  List<String> get roles => _roles;
  List<Map<String, dynamic>> get rolesCuentas => _rolesCuentas;

  // Constructor
  EmpleadoProvider({EmpleadoRepository? empleadoRepository})
      : _empleadoRepository = empleadoRepository ?? EmpleadoRepository.instance;

  /// Recarga todos los datos forzando actualización desde el servidor
  Future<void> recargarDatos() async {
    _setLoading(true);
    clearError();

    try {
      debugPrint(
          'Forzando recarga de datos de colaboradores desde el repositorio...');
      await cargarDatos();
      debugPrint('Datos de colaboradores recargados exitosamente');
    } catch (e) {
      debugPrint('Error al recargar datos de colaboradores: $e');
      _setError('Error al recargar datos: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Carga los datos de empleados y sucursales
  Future<void> cargarDatos() async {
    _setLoading(true);
    clearError();

    try {
      debugPrint('Cargando datos de colaboradores...');
      final Future<Map<String, String>> futureSucursales = _cargarSucursales();
      final Future<EmpleadosPaginados> futureEmpleados =
          _empleadoRepository.getEmpleados(useCache: false);
      final Future<List<Map<String, dynamic>>> futureRolesCuentas =
          cargarRolesCuentas();

      final List<Object> results = await Future.wait(<Future<Object>>[
        futureSucursales,
        futureEmpleados,
        futureRolesCuentas,
      ]);

      final EmpleadosPaginados empleadosPaginados =
          results[1] as EmpleadosPaginados;
      _empleados = empleadosPaginados.empleados;
      debugPrint('${_empleados.length} empleados cargados correctamente');
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
      _setError('Error al cargar datos: $e');

      // Manejar errores de autenticación
      if (e is ApiException && e.statusCode == 401) {
        _setError('Sesión expirada. Por favor, inicie sesión nuevamente.');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Carga la lista de sucursales
  Future<Map<String, String>> _cargarSucursales() async {
    try {
      final Map<String, String> sucursales =
          await _empleadoRepository.getNombresSucursales();
      _nombresSucursales = sucursales;
      return sucursales;
    } catch (e) {
      debugPrint('Error al cargar sucursales: $e');
      return <String, String>{}; // Devolver mapa vacío en caso de error
    }
  }

  /// Carga los roles disponibles para cuentas de usuario
  Future<List<Map<String, dynamic>>> cargarRolesCuentas() async {
    try {
      final List<Map<String, dynamic>> roles =
          await _empleadoRepository.getRolesCuentas();
      _rolesCuentas = roles;
      return roles;
    } catch (e) {
      debugPrint('Error al cargar roles: $e');
      _rolesCuentas = <Map<String, dynamic>>[];
      return <Map<String, dynamic>>[];
    }
  }

  /// Crea un nuevo rol de cuenta de usuario
  Future<Map<String, dynamic>?> crearRolCuenta({
    required String nombre,
    required String codigo,
  }) async {
    try {
      return await _empleadoRepository.crearRolCuenta(
        nombre: nombre,
        codigo: codigo,
      );
    } catch (e) {
      _handleApiError(e);
      return null;
    }
  }

  /// Guarda un empleado (creación o actualización)
  Future<bool> guardarEmpleado(
      Empleado? empleadoExistente, Map<String, dynamic> empleadoData) async {
    _setLoading(true);
    clearError();

    try {
      if (empleadoExistente != null) {
        // Actualizar empleado existente
        await _empleadoRepository.updateEmpleado(
            empleadoExistente.id, empleadoData);
      } else {
        // Crear nuevo empleado
        await _empleadoRepository.createEmpleado(empleadoData);
      }

      // Recargar la lista de empleados para mostrar cambios
      await cargarDatos();
      return true;
    } catch (e) {
      debugPrint('Error al guardar empleado: $e');

      String mensajeError = 'Error al guardar colaborador';
      if (e is ApiException) {
        mensajeError = '$mensajeError: ${e.message}';
      } else {
        mensajeError = '$mensajeError: $e';
      }

      _setError(mensajeError);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Elimina un empleado
  Future<bool> eliminarEmpleado(Empleado empleado) async {
    _setLoading(true);
    clearError();

    try {
      await _empleadoRepository.deleteEmpleado(empleado.id);

      // Actualizar localmente sin tener que recargar todo
      _empleados.removeWhere((Empleado e) => e.id == empleado.id);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error al eliminar empleado: $e');

      String mensajeError = 'Error al eliminar colaborador';
      if (e is ApiException) {
        mensajeError = '$mensajeError: ${e.message}';
      } else {
        mensajeError = '$mensajeError: $e';
      }

      _setError(mensajeError);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Busca un empleado por su ID
  Empleado? buscarEmpleadoPorId(String id) {
    try {
      return _empleados.firstWhere((empleado) => empleado.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene el rol de un empleado utilizando la lógica de negocio
  String obtenerRolDeEmpleado(Empleado empleado) {
    // En un entorno de producción, esto se obtendría de una propiedad del empleado
    // o consultando una tabla de relaciones empleado-rol

    // Por ejemplo, el ID 13 corresponde al "Administrador Principal"
    if (empleado.id == '13') {
      return 'Administrador';
    }

    // Sucursal central (ID 7) podrían ser administradores
    if (empleado.sucursalId == '7') {
      return 'Administrador';
    }

    // Alternamos entre vendedor y computadora para el resto
    final int idNum = int.tryParse(empleado.id) ?? 0;
    if (idNum % 2 == 0) {
      return 'Vendedor';
    } else {
      return 'Computadora';
    }
  }

  /// Obtiene información de la cuenta de un empleado
  Future<Map<String, dynamic>> obtenerInfoCuentaEmpleado(
      Empleado empleado) async {
    _setCuentaLoading(true);

    try {
      final result =
          await _empleadoRepository.obtenerInfoCuentaEmpleado(empleado);
      return result;
    } catch (e) {
      debugPrint('Error al obtener información de cuenta: $e');
      return {
        'cuentaNoEncontrada': _esErrorNotFound(e.toString()),
        'errorCargaInfo': 'Error: $e',
        'usuarioActual': null,
        'rolCuentaActual': null,
      };
    } finally {
      _setCuentaLoading(false);
    }
  }

  /// Obtiene el nombre de un rol a partir de su ID
  Future<String?> obtenerNombreRol(int rolId) async {
    try {
      return await _empleadoRepository.obtenerNombreRol(rolId);
    } catch (e) {
      debugPrint('Error al obtener nombre de rol: $e');
      return null;
    }
  }

  /// Determina si un error es debido a recurso no encontrado
  bool _esErrorNotFound(String errorMessage) {
    final String msgLower = errorMessage.toLowerCase();
    return _errorNotFoundResponses.any((String term) {
      return msgLower.contains(term);
    });
  }

  /// Crea una nueva cuenta de usuario para un empleado
  Future<bool> crearCuentaEmpleado({
    required String empleadoId,
    required String usuario,
    required String clave,
    required int rolCuentaEmpleadoId,
  }) async {
    _setCuentaLoading(true);
    clearError();

    try {
      await _empleadoRepository.registerEmpleadoAccount(
        empleadoId: empleadoId,
        usuario: usuario,
        clave: clave,
        rolCuentaEmpleadoId: rolCuentaEmpleadoId,
      );

      // Recargar datos para actualizar la información
      await cargarDatos();
      return true;
    } catch (e) {
      // Verificar si es un error 404 relacionado con empleado no encontrado
      if (e is ApiException && e.statusCode == 404) {
        _setError(
            'No se pudo crear la cuenta: El empleado o rol especificado no existe');
      } else if (e is ApiException &&
          e.message.contains('Formato de respuesta inesperado')) {
        _setError(
            'Error al registrar la cuenta: Respuesta inesperada del servidor. Verifique que el ID de empleado y rol sean válidos.');
      } else {
        _handleApiError(e);
      }
      return false;
    } finally {
      _setCuentaLoading(false);
    }
  }

  /// Actualiza una cuenta de usuario existente
  Future<bool> actualizarCuentaEmpleado({
    required int id,
    String? usuario,
    String? clave,
    int? rolCuentaEmpleadoId,
  }) async {
    _setCuentaLoading(true);
    clearError();

    try {
      await _empleadoRepository.updateCuentaEmpleado(
        id: id,
        usuario: usuario,
        clave: clave,
        rolCuentaEmpleadoId: rolCuentaEmpleadoId,
      );

      // Recargar datos para actualizar la información
      await cargarDatos();
      return true;
    } catch (e) {
      // Manejar casos específicos de error en actualización
      if (e is ApiException && e.statusCode == 404) {
        _setError(
            'No se pudo actualizar la cuenta: La cuenta especificada no existe');
      } else if (e is ApiException &&
          e.message.contains('Formato de respuesta inesperado')) {
        _setError(
            'Error al actualizar la cuenta: Respuesta inesperada del servidor');
      } else {
        _handleApiError(e);
      }
      return false;
    } finally {
      _setCuentaLoading(false);
    }
  }

  /// Elimina una cuenta de usuario
  Future<bool> eliminarCuentaEmpleado(int id) async {
    _setCuentaLoading(true);
    clearError();

    try {
      final bool success = await _empleadoRepository.deleteCuentaEmpleado(id);

      if (success) {
        // Recargar datos para actualizar la información
        await cargarDatos();
        return true;
      } else {
        _setError('No se pudo eliminar la cuenta');
        return false;
      }
    } catch (e) {
      // Manejar casos específicos de error en eliminación
      if (e is ApiException && e.statusCode == 404) {
        _setError(
            'No se pudo eliminar la cuenta: La cuenta especificada no existe');
      } else if (e is ApiException &&
          e.message.contains('Formato de respuesta inesperado')) {
        _setError(
            'Error al eliminar la cuenta: Respuesta inesperada del servidor');
      } else {
        _handleApiError(e);
      }
      return false;
    } finally {
      _setCuentaLoading(false);
    }
  }

  /// Prepara y devuelve los datos necesarios para gestionar la cuenta de un empleado
  ///
  /// Este método solo prepara los datos, no muestra ningún diálogo
  Future<Map<String, dynamic>> prepararDatosGestionCuenta(
      Empleado empleado) async {
    try {
      // Obtener información de la cuenta actual
      final Map<String, dynamic> cuentaInfo =
          await obtenerInfoCuentaEmpleado(empleado);

      // Cargar roles disponibles si no están cargados ya
      if (_rolesCuentas.isEmpty) {
        await cargarRolesCuentas();
      }

      // Preparar datos para devolver
      return {
        'empleadoId': empleado.id,
        'empleadoNombre': EmpleadosUtils.getNombreCompleto(empleado),
        'cuentaId': cuentaInfo['cuentaId'] as String?,
        'usuarioActual': cuentaInfo['usuarioActual'] as String?,
        'rolActualId': cuentaInfo['rolActualId'] as int?,
        'roles': _rolesCuentas,
        'esNuevaCuenta': cuentaInfo['cuentaNoEncontrada'] as bool? ?? true,
      };
    } catch (e) {
      _handleApiError(e);
      rethrow;
    }
  }

  /// Gestiona el proceso de actualización de una cuenta de empleado existente
  Future<Map<String, dynamic>> gestionarActualizacionCuenta({
    required Empleado empleado,
    required String? nuevoUsuario,
    required String? nuevaClave,
    required int? nuevoRolId,
    bool validarSoloSiHayCambios = true,
  }) async {
    _setCuentaLoading(true);
    clearError();

    try {
      // Validar ID de cuenta
      _empleadoRepository.validarIdCuenta(empleado.cuentaEmpleadoId);
      final int cuentaId = int.parse(empleado.cuentaEmpleadoId!);

      // Verificar si hay cambios que realizar
      if (validarSoloSiHayCambios &&
          nuevoUsuario == null &&
          nuevaClave == null &&
          nuevoRolId == null) {
        return {
          'success': true,
          'message': 'No se realizaron cambios',
          'noChanges': true,
        };
      }

      // Realizar la actualización
      final bool success = await actualizarCuentaEmpleado(
        id: cuentaId,
        usuario: nuevoUsuario,
        clave: nuevaClave,
        rolCuentaEmpleadoId: nuevoRolId,
      );

      if (success) {
        return {
          'success': true,
          'message': 'Cuenta actualizada correctamente',
          'noChanges': false,
        };
      } else {
        return {
          'success': false,
          'message': 'Error al actualizar la cuenta',
          'noChanges': false,
        };
      }
    } catch (e) {
      _handleApiError(e);
      return {
        'success': false,
        'message': 'Error: $_errorMessage',
        'noChanges': false,
      };
    } finally {
      _setCuentaLoading(false);
    }
  }

  /// Gestiona el proceso de creación de una cuenta de empleado
  Future<Map<String, dynamic>> gestionarCreacionCuenta({
    required String empleadoId,
    required String usuario,
    required String clave,
    required int rolCuentaEmpleadoId,
  }) async {
    _setCuentaLoading(true);
    clearError();

    try {
      // Validar datos
      _empleadoRepository.validarDatosCuenta(
        usuario: usuario,
        clave: clave,
        rolCuentaEmpleadoId: rolCuentaEmpleadoId,
        esCreacion: true,
      );

      // Realizar la creación
      final bool success = await crearCuentaEmpleado(
        empleadoId: empleadoId,
        usuario: usuario,
        clave: clave,
        rolCuentaEmpleadoId: rolCuentaEmpleadoId,
      );

      if (success) {
        return {
          'success': true,
          'message': 'Cuenta creada correctamente',
        };
      } else {
        return {
          'success': false,
          'message': 'Error al crear la cuenta',
        };
      }
    } catch (e) {
      _handleApiError(e);
      return {
        'success': false,
        'message': 'Error: $_errorMessage',
      };
    } finally {
      _setCuentaLoading(false);
    }
  }

  /// Gestiona el proceso de eliminación de una cuenta de empleado
  Future<Map<String, dynamic>> gestionarEliminacionCuenta({
    required Empleado empleado,
  }) async {
    _setCuentaLoading(true);
    clearError();

    try {
      // Validar ID de cuenta
      _empleadoRepository.validarIdCuenta(empleado.cuentaEmpleadoId);
      final int cuentaId = int.parse(empleado.cuentaEmpleadoId!);

      // Realizar la eliminación
      final bool success = await eliminarCuentaEmpleado(cuentaId);

      if (success) {
        return {
          'success': true,
          'message': 'Cuenta eliminada correctamente',
        };
      } else {
        return {
          'success': false,
          'message':
              'No se pudo eliminar la cuenta. Por favor, intente nuevamente.',
        };
      }
    } catch (e) {
      _handleApiError(e);
      return {
        'success': false,
        'message': 'Error: $_errorMessage',
      };
    } finally {
      _setCuentaLoading(false);
    }
  }

  // Método para manejar errores de la API
  void _handleApiError(e) {
    String errorMsg = e.toString();

    if (e is ApiException) {
      switch (e.statusCode) {
        case 401:
          errorMsg = 'Sesión expirada. Inicie sesión nuevamente.';
          break;
        case 400:
          if (e.message.contains('exists') || e.message.contains('ya existe')) {
            errorMsg =
                'El nombre de usuario ya está en uso. Por favor, elija otro.';
          } else if (e.message.contains('invalid')) {
            errorMsg = 'Datos inválidos: ${e.message}';
          } else if (e.message.contains('formato')) {
            errorMsg = 'Error en el formato de datos: ${e.message}';
          } else {
            errorMsg = 'Error en los datos: ${e.message}';
          }
          break;
        case 403:
          errorMsg = 'No tiene permisos para realizar esta acción.';
          break;
        case 404:
          errorMsg = 'Recurso no encontrado: ${e.message}';
          break;
        case 409:
          errorMsg = 'Conflicto al procesar la solicitud: ${e.message}';
          break;
        case 422:
          errorMsg = 'Error de validación: ${e.message}';
          break;
        case 500:
          if (e.message.contains('Formato de respuesta inesperado')) {
            errorMsg =
                'Error en la comunicación con el servidor. Por favor, verifique que los datos sean correctos e intente nuevamente.';
          } else {
            errorMsg = 'Error en el servidor. Intente nuevamente más tarde.';
          }
          break;
        default:
          errorMsg = 'Error ${e.statusCode}: ${e.message}';
      }
    } else if (e.toString().contains('timed out')) {
      errorMsg =
          'La conexión con el servidor ha expirado. Verifique su conexión a internet e intente nuevamente.';
    } else if (e.toString().contains('SocketException') ||
        e.toString().contains('Failed host lookup')) {
      errorMsg =
          'No se pudo conectar al servidor. Verifique su conexión a internet.';
    }

    _setError(errorMsg);
  }

  // Métodos privados para gestionar el estado
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setCuentaLoading(bool value) {
    _isCuentaLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Limpia el mensaje de error actual
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  /// Valida un nombre de usuario
  String? validarUsuario(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese un nombre de usuario';
    }
    if (value.length < 4) {
      return 'Mínimo 4 caracteres';
    }
    if (value.length > 20) {
      return 'Máximo 20 caracteres';
    }
    if (!RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(value)) {
      return 'Solo letras, números, guiones y guiones bajos';
    }
    return null;
  }

  /// Valida una contraseña
  String? validarClave(String? value, {bool esRequerida = true}) {
    if (esRequerida && (value == null || value.isEmpty)) {
      return 'Ingrese una contraseña';
    }
    if (value != null && value.isNotEmpty) {
      if (value.length < 6) {
        return 'Mínimo 6 caracteres';
      }
      if (value.length > 20) {
        return 'Máximo 20 caracteres';
      }
      if (!RegExp(r'\d').hasMatch(value)) {
        return 'Debe contener al menos un número';
      }
    }
    return null;
  }

  /// Valida que dos contraseñas coincidan
  String? validarConfirmacionClave(String? value, String? claveOriginal) {
    if (claveOriginal != null &&
        claveOriginal.isNotEmpty &&
        value != claveOriginal) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }
}
