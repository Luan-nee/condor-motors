import 'dart:io';

import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/api/main.api.dart';
import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';

/// Repositorio para gestionar empleados y sus cuentas de usuario.
///
/// Encapsula la lógica de negocio y consumo de APIs de empleados y cuentas,
/// delegando la autenticación mediante el mixin [AuthDelegator].
class EmpleadoRepository with AuthDelegator implements BaseRepository {
  static final EmpleadoRepository _instance = EmpleadoRepository._internal();
  static EmpleadoRepository get instance => _instance;

  late final dynamic _empleadosApi;
  late final dynamic _cuentasEmpleadosApi;
  late final dynamic _sucursalesApi;

  EmpleadoRepository._internal() {
    _empleadosApi = api_index.api.empleados;
    _cuentasEmpleadosApi = api_index.api.empleados;
    _sucursalesApi = api_index.api.sucursales;
  }

  /// Obtiene la lista completa de empleados.
  Future<EmpleadosPaginados> getEmpleados({bool useCache = true}) =>
      _empleadosApi.getEmpleados(useCache: useCache);

  /// Obtiene los empleados asociados a una sucursal.
  Future<EmpleadosPaginados> getEmpleadosPorSucursal(String sucursalId) =>
      _empleadosApi.getEmpleadosPorSucursal(sucursalId);

  /// Obtiene un empleado específico por su ID.
  Future<Empleado> getEmpleado(String id) =>
      _empleadosApi.getEmpleado(id);

  /// Crea un nuevo empleado.
  Future<Empleado> createEmpleado(
    Map<String, dynamic> empleadoData, {
    File? fotoFile,
  }) =>
      _empleadosApi.createEmpleado(empleadoData, fotoFile: fotoFile);

  /// Actualiza los datos de un empleado existente.
  Future<Empleado> updateEmpleado(
    String id,
    Map<String, dynamic> empleadoData, {
    File? fotoFile,
  }) =>
      _empleadosApi.updateEmpleado(id, empleadoData, fotoFile: fotoFile);

  /// Elimina un empleado por su ID.
  Future<bool> deleteEmpleado(String id) async {
    await _empleadosApi.deleteEmpleado(id);
    return true;
  }

  /// Obtiene la lista de todas las sucursales.
  Future<List<Sucursal>> getSucursales() =>
      _sucursalesApi.getSucursales();

  /// Obtiene un mapa indexado de nombres de sucursales por su ID.
  Future<Map<String, String>> getNombresSucursales() async {
    try {
      final List<Sucursal> sucursalesData = await getSucursales();
      final Map<String, String> sucursales = <String, String>{};

      for (final Sucursal sucursal in sucursalesData) {
        final String id = sucursal.id.toString();
        String nombre = sucursal.nombre;
        if (sucursal.sucursalCentral) {
          nombre = '$nombre (Central)';
        }
        if (id.isNotEmpty) {
          sucursales[id] = nombre;
        }
      }
      return sucursales;
    } catch (_) {
      return <String, String>{};
    }
  }

  /// Obtiene los roles de cuenta disponibles.
  Future<List<Map<String, dynamic>>> getRolesCuentas() =>
      _cuentasEmpleadosApi.getRolesCuentas();

  /// Obtiene una cuenta de empleado por su ID.
  Future<Map<String, dynamic>?> getCuentaEmpleadoById(int id) =>
      _cuentasEmpleadosApi.getCuentaEmpleado(id.toString());

  /// Obtiene la cuenta asociada a un empleado por su ID.
  Future<Map<String, dynamic>?> getCuentaByEmpleadoId(String empleadoId) async {
    try {
      return await _cuentasEmpleadosApi.getCuentaByEmpleadoId(empleadoId);
    } catch (e) {
      if (_esErrorNotFound(e.toString())) {
        throw Exception('El empleado no tiene cuenta asociada');
      }
      rethrow;
    }
  }

  /// Registra una nueva cuenta de acceso para un empleado.
  Future<Map<String, dynamic>> registerEmpleadoAccount({
    required String empleadoId,
    required String usuario,
    required String clave,
    required int rolCuentaEmpleadoId,
  }) async {
    try {
      return await _cuentasEmpleadosApi.registerEmpleadoAccount(
        empleadoId: empleadoId,
        usuario: usuario,
        clave: clave,
        rolCuentaEmpleadoId: rolCuentaEmpleadoId,
      );
    } catch (e) {
      if (e.toString().contains('Invalid or missing authorization token')) {
        throw Exception('Error de configuración: Verifica que el endpoint para '
            'cuentas de empleados sea correcto (debe incluir /api/)');
      }
      rethrow;
    }
  }

  /// Actualiza los datos de acceso de una cuenta de empleado.
  Future<Map<String, dynamic>> updateCuentaEmpleado({
    required int id,
    String? usuario,
    String? clave,
    int? rolCuentaEmpleadoId,
  }) async {
    try {
      return await _cuentasEmpleadosApi.updateCuentaEmpleado(
        cuentaId: id.toString(),
        usuario: usuario,
        clave: clave,
        rolCuentaEmpleadoId: rolCuentaEmpleadoId,
      );
    } catch (e) {
      if (e.toString().contains('Invalid or missing authorization token')) {
        throw Exception('Error de configuración: Verifica que el endpoint para '
            'cuentas de empleados sea correcto (debe incluir /api/)');
      }
      rethrow;
    }
  }

  /// Elimina una cuenta de empleado por su ID.
  Future<bool> deleteCuentaEmpleado(int id) =>
      _cuentasEmpleadosApi.deleteCuentaEmpleado(id);

  /// Obtiene la información completa consolidada de la cuenta de un empleado.
  Future<Map<String, dynamic>> obtenerInfoCuentaEmpleado(
      Empleado empleado) async {
    try {
      final Map<String, dynamic> resultado = <String, dynamic>{
        'cuentaNoEncontrada': false,
        'errorCargaInfo': null as String?,
        'usuarioActual': null as String?,
        'rolCuentaActual': null as String?,
        'cuentaId': null as String?,
        'rolActualId': null as int?,
      };

      if (empleado.cuentaEmpleadoId != null) {
        try {
          final int? cuentaIdInt = int.tryParse(empleado.cuentaEmpleadoId!);
          if (cuentaIdInt != null) {
            final Map<String, dynamic>? cuentaInfo =
                await getCuentaEmpleadoById(cuentaIdInt);
            if (cuentaInfo != null) {
              resultado['usuarioActual'] = cuentaInfo['usuario']?.toString();
              resultado['cuentaId'] = empleado.cuentaEmpleadoId;

              final rolId = cuentaInfo['rolCuentaEmpleadoId'];
              if (rolId != null) {
                resultado['rolActualId'] = rolId;
                resultado['rolCuentaActual'] = await obtenerNombreRol(rolId);
              }
              return resultado;
            }
          }
        } catch (e) {
          if (_esErrorAutenticacion(e.toString())) {
            rethrow;
          }
        }
      }

      try {
        final Map<String, dynamic>? cuentaInfo =
            await getCuentaByEmpleadoId(empleado.id);

        if (cuentaInfo != null) {
          resultado['usuarioActual'] = cuentaInfo['usuario']?.toString();
          resultado['cuentaId'] = cuentaInfo['id']?.toString();

          final rolId = cuentaInfo['rolCuentaEmpleadoId'];
          if (rolId != null) {
            resultado['rolActualId'] = rolId;
            resultado['rolCuentaActual'] = await obtenerNombreRol(rolId);
          }
          return resultado;
        } else {
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
      return {
        'cuentaNoEncontrada': _esErrorNotFound(e.toString()),
        'errorCargaInfo': 'Error: $e',
        'usuarioActual': null,
        'rolCuentaActual': null,
      };
    }
  }

  /// Obtiene el nombre de un rol de cuenta por su ID.
  Future<String?> obtenerNombreRol(int rolId) async {
    try {
      final List<Map<String, dynamic>> roles = await getRolesCuentas();
      final Map<String, dynamic> rol = roles.firstWhere(
        (Map<String, dynamic> r) => r['id'] == rolId,
        orElse: () => <String, dynamic>{},
      );
      return rol['nombre'] ?? rol['codigo'] ?? 'Rol #$rolId';
    } catch (_) {
      return null;
    }
  }

  /// Crea un nuevo rol de cuenta validando que sea único.
  Future<Map<String, dynamic>?> crearRolCuenta({
    required String nombre,
    required String codigo,
  }) async {
    final roles = await getRolesCuentas();
    if (roles.any((rol) =>
        rol['codigo'].toString().toLowerCase() == codigo.toLowerCase())) {
      throw ApiException(
        statusCode: 400,
        message: 'Ya existe un rol con el código "$codigo"',
        errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
      );
    }

    if (roles.any((rol) =>
        rol['nombreRol']?.toString().toLowerCase() == nombre.toLowerCase() ||
        rol['nombre']?.toString().toLowerCase() == nombre.toLowerCase())) {
      throw ApiException(
        statusCode: 400,
        message: 'Ya existe un rol con el nombre "$nombre"',
        errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
      );
    }

    return _cuentasEmpleadosApi.createRolCuenta(
      nombre: nombre,
      codigo: codigo,
    );
  }

  /// Valida la estructura lógica de los datos de cuenta.
  void validarDatosCuenta({
    String? usuario,
    String? clave,
    int? rolCuentaEmpleadoId,
    bool esCreacion = false,
  }) {
    if (esCreacion && (usuario?.isEmpty ?? true)) {
      throw ApiException(
        statusCode: 400,
        message: 'El nombre de usuario es obligatorio',
        errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
      );
    }

    if (esCreacion && (clave?.isEmpty ?? true)) {
      throw ApiException(
        statusCode: 400,
        message: 'La contraseña es obligatoria para crear una cuenta',
        errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
      );
    }

    if (esCreacion &&
        (rolCuentaEmpleadoId == null || rolCuentaEmpleadoId <= 0)) {
      throw ApiException(
        statusCode: 400,
        message: 'Debe seleccionar un rol válido',
        errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
      );
    }
  }

  /// Valida si el identificador de cuenta de empleado es correcto.
  void validarIdCuenta(String? cuentaEmpleadoId) {
    if (cuentaEmpleadoId == null) {
      throw ApiException(
        statusCode: 400,
        message: 'No se encontró ID de cuenta para este empleado',
        errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
      );
    }

    final int? cuentaId = int.tryParse(cuentaEmpleadoId);
    if (cuentaId == null || cuentaId <= 0) {
      throw ApiException(
        statusCode: 400,
        message: 'ID de cuenta inválido',
        errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
      );
    }
  }

  bool _esErrorNotFound(String errorMessage) {
    final String msgLower = errorMessage.toLowerCase();
    final List<String> errorNotFoundResponses = <String>[
      '404',
      'not found',
      'no encontrado',
      'no existe',
      'empleado no tiene cuenta'
    ];
    return errorNotFoundResponses.any(msgLower.contains);
  }

  bool _esErrorAutenticacion(String errorMessage) {
    final String msgLower = errorMessage.toLowerCase();
    final List<String> errorAuthResponses = <String>[
      '401',
      'no autorizado',
      'sesión expirada',
      'token inválido'
    ];
    return errorAuthResponses.any(msgLower.contains);
  }
}
