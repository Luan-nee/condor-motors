import 'package:condorsmotors/api/main.api.dart' show ApiException;
import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/utils/empleados_utils.dart';
import 'package:flutter/material.dart';

/// Provider para gestionar los empleados/colaboradores en el panel de administración
class EmpleadoProvider extends ChangeNotifier {
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

  static const List<String> _errorAuthResponses = <String>[
    '401',
    'no autorizado',
    'sesión expirada',
    'token inválido'
  ];

  // Getters
  bool get isLoading => _isLoading;
  bool get isCuentaLoading => _isCuentaLoading;
  String get errorMessage => _errorMessage;
  List<Empleado> get empleados => _empleados;
  Map<String, String> get nombresSucursales => _nombresSucursales;
  List<String> get roles => _roles;
  List<Map<String, dynamic>> get rolesCuentas => _rolesCuentas;

  /// Recarga todos los datos forzando actualización desde el servidor
  Future<void> recargarDatos() async {
    _setLoading(true);
    clearError();

    try {
      debugPrint('Forzando recarga de datos de colaboradores desde la API...');
      await cargarDatos();
      debugPrint('Datos de colaboradores recargados exitosamente desde la API');
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
          api.empleados.getEmpleados(useCache: false);
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
      final List<Sucursal> sucursalesData =
          await api.sucursales.getSucursales();
      final Map<String, String> sucursales = <String, String>{};

      for (Sucursal sucursal in sucursalesData) {
        final String id = sucursal.id.toString();
        String nombre = sucursal.nombre;
        final bool esCentral = sucursal.sucursalCentral;

        // Agregar indicador de Central al nombre si corresponde
        if (esCentral) {
          nombre = '$nombre (Central)';
        }

        if (id.isNotEmpty) {
          sucursales[id] = nombre;
        }
      }

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
          await api.cuentasEmpleados.getRolesCuentas();
      _rolesCuentas = roles;
      return roles;
    } catch (e) {
      debugPrint('Error al cargar roles: $e');
      _rolesCuentas = <Map<String, dynamic>>[];
      return <Map<String, dynamic>>[];
    }
  }

  /// Crea un nuevo rol de cuenta de usuario
  ///
  /// Esta función es un ejemplo y no está realmente implementada en el backend.
  /// En una implementación real, esta función invocaría un endpoint API
  /// para crear un nuevo rol de cuenta de empleado.
  Future<Map<String, dynamic>?> crearRolCuenta({
    required String nombre,
    required String codigo,
  }) async {
    // Verificar que el código sea único (simulación)
    if (_rolesCuentas.any((rol) =>
        rol['codigo'].toString().toLowerCase() == codigo.toLowerCase())) {
      throw ApiException(
        statusCode: 400,
        message: 'Ya existe un rol con el código "$codigo"',
      );
    }

    // Verificar que el nombre sea único (simulación)
    if (_rolesCuentas.any((rol) =>
        rol['nombreRol']?.toString().toLowerCase() == nombre.toLowerCase() ||
        rol['nombre']?.toString().toLowerCase() == nombre.toLowerCase())) {
      throw ApiException(
        statusCode: 400,
        message: 'Ya existe un rol con el nombre "$nombre"',
      );
    }

    // Simular la creación del rol con un ID temporal
    // En una implementación real, esto vendría del backend
    final Map<String, dynamic> nuevoRol = {
      'id': _rolesCuentas.length +
          10, // Generar un ID temporal único (simulación)
      'nombreRol': nombre,
      'codigo': codigo,
    };

    // Agregar a la lista local (simulación)
    _rolesCuentas.add(nuevoRol);
    notifyListeners();

    debugPrint('Nuevo rol creado (simulación): $nuevoRol');

    // TODO: En una implementación real, esta función invocaría al backend:
    // return await api.cuentasEmpleados.createRolCuenta(nombre: nombre, codigo: codigo);

    return nuevoRol;
  }

  /// Guarda un empleado (creación o actualización)
  Future<bool> guardarEmpleado(
      Empleado? empleadoExistente, Map<String, dynamic> empleadoData) async {
    _setLoading(true);
    clearError();

    try {
      if (empleadoExistente != null) {
        // Actualizar empleado existente
        await api.empleados.updateEmpleado(empleadoExistente.id, empleadoData);
      } else {
        // Crear nuevo empleado
        await api.empleados.createEmpleado(empleadoData);
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
      await api.empleados.deleteEmpleado(empleado.id);

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
      // Preparar valores por defecto
      final Map<String, dynamic> resultado = <String, dynamic>{
        'cuentaNoEncontrada': false,
        'errorCargaInfo': null as String?,
        'usuarioActual': null as String?,
        'rolCuentaActual': null as String?,
        'cuentaId': null as String?,
        'rolActualId': null as int?,
      };

      // Intentar obtener la cuenta - primero por ID de cuenta si está disponible
      if (empleado.cuentaEmpleadoId != null) {
        try {
          final int? cuentaIdInt = int.tryParse(empleado.cuentaEmpleadoId!);
          if (cuentaIdInt != null) {
            final Map<String, dynamic>? cuentaInfo =
                await api.cuentasEmpleados.getCuentaEmpleadoById(cuentaIdInt);
            if (cuentaInfo != null) {
              // Cuenta encontrada por ID
              resultado['usuarioActual'] = cuentaInfo['usuario']?.toString();
              resultado['cuentaId'] = empleado.cuentaEmpleadoId;

              // Obtener información del rol si está disponible
              final rolId = cuentaInfo['rolCuentaEmpleadoId'];
              if (rolId != null) {
                resultado['rolActualId'] = rolId;
                resultado['rolCuentaActual'] = await obtenerNombreRol(rolId);
              }

              return resultado;
            }
          }
        } catch (e) {
          final String errorStr = e.toString();
          // Si es error de "no encontrado", solo continuamos al siguiente método
          // Si es error de autenticación, lo propagamos
          if (_esErrorAutenticacion(errorStr)) {
            rethrow;
          }
          // Para otros errores, continuamos con el siguiente método
        }
      }

      // Si llegamos aquí, intentamos encontrar la cuenta por ID de empleado
      try {
        final Map<String, dynamic>? cuentaInfo =
            await api.cuentasEmpleados.getCuentaByEmpleadoId(empleado.id);

        if (cuentaInfo != null) {
          resultado['usuarioActual'] = cuentaInfo['usuario']?.toString();
          resultado['cuentaId'] = cuentaInfo['id']?.toString();

          // Obtener información del rol si está disponible
          final rolId = cuentaInfo['rolCuentaEmpleadoId'];
          if (rolId != null) {
            resultado['rolActualId'] = rolId;
            resultado['rolCuentaActual'] = await obtenerNombreRol(rolId);
          }

          return resultado;
        } else {
          // API devolvió null - no hay cuenta
          resultado['cuentaNoEncontrada'] = true;
          return resultado;
        }
      } catch (e) {
        final String errorStr = e.toString();

        if (_esErrorNotFound(errorStr)) {
          resultado['cuentaNoEncontrada'] = true;
          return resultado;
        }

        if (_esErrorAutenticacion(errorStr)) {
          rethrow;
        }

        // Cualquier otro error
        resultado['errorCargaInfo'] =
            'Error: ${errorStr.replaceAll('Exception: ', '')}';
        return resultado;
      }
    } catch (e) {
      if (_esErrorNotFound(e.toString())) {
        return {
          'cuentaNoEncontrada': true,
          'errorCargaInfo': null,
          'usuarioActual': null,
          'rolCuentaActual': null,
        };
      }

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
      final List<Map<String, dynamic>> roles =
          await api.cuentasEmpleados.getRolesCuentas();
      final Map<String, dynamic> rol = roles.firstWhere(
        (Map<String, dynamic> r) => r['id'] == rolId,
        orElse: () => <String, dynamic>{},
      );

      return rol['nombre'] ?? rol['codigo'] ?? 'Rol #$rolId';
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

  /// Determina si un error es debido a problemas de autenticación
  bool _esErrorAutenticacion(String errorMessage) {
    final String msgLower = errorMessage.toLowerCase();
    return _errorAuthResponses.any((String term) {
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
      await api.cuentasEmpleados.registerEmpleadoAccount(
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
      await api.cuentasEmpleados.updateCuentaEmpleado(
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
      final bool success = await api.cuentasEmpleados.deleteCuentaEmpleado(id);

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
  ///
  /// Maneja toda la lógica de validación y procesa la actualización
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
      // Verificar que tengamos un ID de cuenta válido
      if (empleado.cuentaEmpleadoId == null) {
        throw ApiException(
          statusCode: 400,
          message: 'No se encontró ID de cuenta para este empleado',
        );
      }

      final int? cuentaId = int.tryParse(empleado.cuentaEmpleadoId!);
      if (cuentaId == null) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de cuenta inválido',
        );
      }

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
  ///
  /// Maneja toda la lógica de validación y procesa la creación
  Future<Map<String, dynamic>> gestionarCreacionCuenta({
    required String empleadoId,
    required String usuario,
    required String clave,
    required int rolCuentaEmpleadoId,
  }) async {
    _setCuentaLoading(true);
    clearError();

    try {
      // Validar que los datos mínimos estén presentes
      if (usuario.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'El nombre de usuario es obligatorio',
        );
      }

      if (clave.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'La contraseña es obligatoria para crear una cuenta',
        );
      }

      if (rolCuentaEmpleadoId <= 0) {
        throw ApiException(
          statusCode: 400,
          message: 'Debe seleccionar un rol válido',
        );
      }

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
  ///
  /// Maneja toda la lógica de validación y procesa la eliminación
  Future<Map<String, dynamic>> gestionarEliminacionCuenta({
    required Empleado empleado,
  }) async {
    _setCuentaLoading(true);
    clearError();

    try {
      // Verificar que tengamos un ID de cuenta válido
      if (empleado.cuentaEmpleadoId == null) {
        throw ApiException(
          statusCode: 400,
          message: 'No se encontró ID de cuenta para este empleado',
        );
      }

      final int? cuentaId = int.tryParse(empleado.cuentaEmpleadoId!);
      if (cuentaId == null || cuentaId <= 0) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de cuenta inválido',
        );
      }

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
