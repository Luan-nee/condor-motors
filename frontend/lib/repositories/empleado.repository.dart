import 'dart:io';

import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Repositorio para gestionar empleados
///
/// Esta clase encapsula la lógica de negocio relacionada con empleados y sus cuentas,
/// actuando como una capa intermedia entre la UI y la API
class EmpleadoRepository implements BaseRepository {
  /// Instancia singleton del repositorio
  static final EmpleadoRepository _instance = EmpleadoRepository._internal();

  /// Getter para la instancia singleton
  static EmpleadoRepository get instance => _instance;

  /// API de empleados
  late final dynamic _empleadosApi;

  /// API de cuentas de empleados
  late final dynamic _cuentasEmpleadosApi;

  /// API de sucursales
  late final dynamic _sucursalesApi;

  /// Constructor privado para el patrón singleton
  EmpleadoRepository._internal() {
    try {
      // Utilizamos la API global inicializada en index.api.dart
      _empleadosApi = api.empleados;
      _cuentasEmpleadosApi = api.cuentasEmpleados;
      _sucursalesApi = api.sucursales;
    } catch (e) {
      debugPrint('Error al obtener API de empleados: $e');
      // Si hay un error al acceder a la API global, lanzamos una excepción
      throw Exception('No se pudo inicializar EmpleadoRepository: $e');
    }
  }

  /// Obtiene datos del usuario desde la API centralizada
  ///
  /// Ayuda a los providers a acceder a la información del usuario autenticado
  @override
  Future<Map<String, dynamic>?> getUserData() =>
      AuthRepository.instance.getUserData();

  /// Obtiene el ID de la sucursal del usuario actual
  ///
  /// Útil para operaciones que requieren el ID de sucursal automáticamente
  @override
  Future<String?> getCurrentSucursalId() =>
      AuthRepository.instance.getCurrentSucursalId();

  /// Obtiene la lista de empleados
  ///
  /// [useCache] Indica si se debe usar la caché
  Future<EmpleadosPaginados> getEmpleados({bool useCache = true}) async {
    try {
      return await _empleadosApi.getEmpleados(useCache: useCache);
    } catch (e) {
      debugPrint('Error en EmpleadoRepository.getEmpleados: $e');
      rethrow;
    }
  }

  /// Obtiene los empleados de una sucursal específica
  ///
  /// [sucursalId] ID de la sucursal
  Future<EmpleadosPaginados> getEmpleadosPorSucursal(String sucursalId) async {
    try {
      return await _empleadosApi.getEmpleadosPorSucursal(sucursalId);
    } catch (e) {
      debugPrint('Error en EmpleadoRepository.getEmpleadosPorSucursal: $e');
      rethrow;
    }
  }

  /// Obtiene un empleado específico por su ID
  ///
  /// [id] ID del empleado
  Future<Empleado> getEmpleado(String id) async {
    try {
      return await _empleadosApi.getEmpleado(id);
    } catch (e) {
      debugPrint('Error en EmpleadoRepository.getEmpleado: $e');
      rethrow;
    }
  }

  /// Crea un nuevo empleado
  ///
  /// [empleadoData] Datos del empleado a crear
  Future<Empleado> createEmpleado(Map<String, dynamic> empleadoData,
      {File? fotoFile}) async {
    try {
      if (fotoFile != null) {
        final String fileName =
            fotoFile.path.split(Platform.pathSeparator).last;
        final String fileExtension =
            fileName.contains('.') ? fileName.split('.').last : '';
        final int fileSize = await fotoFile.length();
        debugPrint('[empleado_repository] Imagen a enviar:');
        debugPrint('  Path: \\${fotoFile.path}');
        debugPrint('  Nombre: $fileName');
        debugPrint('  Extensión: $fileExtension');
        debugPrint('  Tamaño: $fileSize bytes');
      }
      return await _empleadosApi.createEmpleado(empleadoData,
          fotoFile: fotoFile);
    } catch (e) {
      debugPrint('Error en EmpleadoRepository.createEmpleado: $e');
      rethrow;
    }
  }

  /// Actualiza un empleado existente
  ///
  /// [id] ID del empleado a actualizar
  /// [empleadoData] Datos actualizados del empleado
  Future<Empleado> updateEmpleado(String id, Map<String, dynamic> empleadoData,
      {File? fotoFile}) async {
    try {
      if (fotoFile != null) {
        final String fileName =
            fotoFile.path.split(Platform.pathSeparator).last;
        final String fileExtension =
            fileName.contains('.') ? fileName.split('.').last : '';
        final int fileSize = await fotoFile.length();
        debugPrint('[empleado_repository] Imagen a enviar:');
        debugPrint('  Path: \\${fotoFile.path}');
        debugPrint('  Nombre: $fileName');
        debugPrint('  Extensión: $fileExtension');
        debugPrint('  Tamaño: $fileSize bytes');
      }
      return await _empleadosApi.updateEmpleado(id, empleadoData,
          fotoFile: fotoFile);
    } catch (e) {
      debugPrint('Error en EmpleadoRepository.updateEmpleado: $e');
      rethrow;
    }
  }

  /// Elimina un empleado
  ///
  /// [id] ID del empleado a eliminar
  Future<bool> deleteEmpleado(String id) async {
    try {
      await _empleadosApi.deleteEmpleado(id);
      return true;
    } catch (e) {
      debugPrint('Error en EmpleadoRepository.deleteEmpleado: $e');
      return false;
    }
  }

  /// Obtiene la lista de sucursales
  ///
  /// Retorna lista de sucursales para asociar empleados
  Future<List<Sucursal>> getSucursales() async {
    try {
      return await _sucursalesApi.getSucursales();
    } catch (e) {
      debugPrint('Error en EmpleadoRepository.getSucursales: $e');
      rethrow;
    }
  }

  /// Obtiene un mapa de nombres de sucursales por ID
  ///
  /// Facilita la visualización de nombres de sucursales
  Future<Map<String, String>> getNombresSucursales() async {
    try {
      final List<Sucursal> sucursalesData = await getSucursales();
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

      return sucursales;
    } catch (e) {
      debugPrint('Error en EmpleadoRepository.getNombresSucursales: $e');
      return <String, String>{}; // Devolver mapa vacío en caso de error
    }
  }

  // MÉTODOS PARA CUENTAS DE EMPLEADOS

  /// Obtiene la lista de roles de cuentas
  ///
  /// Retorna la lista de roles disponibles para asignar a cuentas de empleados
  Future<List<Map<String, dynamic>>> getRolesCuentas() async {
    try {
      return await _cuentasEmpleadosApi.getRolesCuentas();
    } catch (e) {
      debugPrint('Error en EmpleadoRepository.getRolesCuentas: $e');
      rethrow;
    }
  }

  /// Obtiene una cuenta de empleado por su ID
  ///
  /// [id] ID de la cuenta de empleado
  Future<Map<String, dynamic>?> getCuentaEmpleadoById(int id) async {
    try {
      return await _cuentasEmpleadosApi.getCuentaEmpleadoById(id);
    } catch (e) {
      debugPrint('Error en EmpleadoRepository.getCuentaEmpleadoById: $e');
      rethrow;
    }
  }

  /// Obtiene una cuenta asociada a un empleado
  ///
  /// [empleadoId] ID del empleado
  Future<Map<String, dynamic>?> getCuentaByEmpleadoId(String empleadoId) async {
    try {
      // Problema conocido: el endpoint debe incluir "/api" al inicio
      // Para esta operación, usamos la API existente esperando que esté ajustada
      try {
        return await _cuentasEmpleadosApi.getCuentaByEmpleadoId(empleadoId);
      } catch (e) {
        // Si falla, esto podría deberse al prefijo incorrecto en la API
        debugPrint('Error al obtener cuenta de empleado (API original): $e');

        // Si el error es por prefijo, y en tu ambiente el endpoint correcto es /api/cuentasempleados,
        // deberás modificar en la API y no aquí - el repositorio debe mantenerse agnóstico a URLs directas
        rethrow;
      }
    } catch (e) {
      if (_esErrorNotFound(e.toString())) {
        debugPrint('El empleado $empleadoId no tiene cuenta asociada');
        throw Exception('El empleado no tiene cuenta asociada');
      }

      debugPrint('ERROR al obtener cuenta por empleado: $e');
      rethrow;
    }
  }

  /// Crea una cuenta para un empleado
  ///
  /// [empleadoId] ID del empleado
  /// [usuario] Nombre de usuario
  /// [clave] Contraseña
  /// [rolCuentaEmpleadoId] ID del rol para la cuenta
  Future<Map<String, dynamic>> registerEmpleadoAccount({
    required String empleadoId,
    required String usuario,
    required String clave,
    required int rolCuentaEmpleadoId,
  }) async {
    try {
      // Problema conocido: el endpoint debe incluir "/api" al inicio
      // En lugar de modificar el repositorio, se debería corregir en api/index.api.dart
      return await _cuentasEmpleadosApi.registerEmpleadoAccount(
        empleadoId: empleadoId,
        usuario: usuario,
        clave: clave,
        rolCuentaEmpleadoId: rolCuentaEmpleadoId,
      );
    } catch (e) {
      debugPrint('Error en EmpleadoRepository.registerEmpleadoAccount: $e');
      // Mensaje específico para problemas de configuración de URL
      if (e.toString().contains('Invalid or missing authorization token')) {
        throw Exception('Error de configuración: Verifica que el endpoint para '
            'cuentas de empleados sea correcto (debe incluir /api/)');
      }
      rethrow;
    }
  }

  /// Actualiza una cuenta de empleado
  ///
  /// [id] ID de la cuenta
  /// [usuario] Nuevo nombre de usuario (opcional)
  /// [clave] Nueva contraseña (opcional)
  /// [rolCuentaEmpleadoId] Nuevo ID de rol (opcional)
  Future<Map<String, dynamic>> updateCuentaEmpleado({
    required int id,
    String? usuario,
    String? clave,
    int? rolCuentaEmpleadoId,
  }) async {
    try {
      // Problema conocido: el endpoint debe incluir "/api" al inicio
      // En lugar de modificar el repositorio, se debería corregir en api/index.api.dart
      return await _cuentasEmpleadosApi.updateCuentaEmpleado(
        id: id,
        usuario: usuario,
        clave: clave,
        rolCuentaEmpleadoId: rolCuentaEmpleadoId,
      );
    } catch (e) {
      debugPrint('Error en EmpleadoRepository.updateCuentaEmpleado: $e');
      // Mensaje específico para problemas de configuración de URL
      if (e.toString().contains('Invalid or missing authorization token')) {
        throw Exception('Error de configuración: Verifica que el endpoint para '
            'cuentas de empleados sea correcto (debe incluir /api/)');
      }
      rethrow;
    }
  }

  /// Elimina una cuenta de empleado
  ///
  /// [id] ID de la cuenta a eliminar
  Future<bool> deleteCuentaEmpleado(int id) async {
    try {
      return await _cuentasEmpleadosApi.deleteCuentaEmpleado(id);
    } catch (e) {
      debugPrint('Error en EmpleadoRepository.deleteCuentaEmpleado: $e');
      rethrow;
    }
  }

  /// Obtiene información completa sobre la cuenta de un empleado
  ///
  /// [empleado] Empleado del que se quiere obtener información de cuenta
  Future<Map<String, dynamic>> obtenerInfoCuentaEmpleado(
      Empleado empleado) async {
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
                await getCuentaEmpleadoById(cuentaIdInt);
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
            await getCuentaByEmpleadoId(empleado.id);

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

      debugPrint('Error en EmpleadoRepository.obtenerInfoCuentaEmpleado: $e');
      return {
        'cuentaNoEncontrada': _esErrorNotFound(e.toString()),
        'errorCargaInfo': 'Error: $e',
        'usuarioActual': null,
        'rolCuentaActual': null,
      };
    }
  }

  /// Obtiene el nombre de un rol a partir de su ID
  ///
  /// [rolId] ID del rol
  Future<String?> obtenerNombreRol(int rolId) async {
    try {
      final List<Map<String, dynamic>> roles = await getRolesCuentas();
      final Map<String, dynamic> rol = roles.firstWhere(
        (Map<String, dynamic> r) => r['id'] == rolId,
        orElse: () => <String, dynamic>{},
      );

      return rol['nombre'] ?? rol['codigo'] ?? 'Rol #$rolId';
    } catch (e) {
      debugPrint('Error en EmpleadoRepository.obtenerNombreRol: $e');
      return null;
    }
  }

  /// Crea un nuevo rol de cuenta de empleado
  ///
  /// [nombre] Nombre del rol
  /// [codigo] Código único del rol
  Future<Map<String, dynamic>?> crearRolCuenta({
    required String nombre,
    required String codigo,
  }) async {
    try {
      // Validar que el código sea único
      final roles = await getRolesCuentas();
      if (roles.any((rol) =>
          rol['codigo'].toString().toLowerCase() == codigo.toLowerCase())) {
        throw ApiException(
          statusCode: 400,
          message: 'Ya existe un rol con el código "$codigo"',
          errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
        );
      }

      // Validar que el nombre sea único
      if (roles.any((rol) =>
          rol['nombreRol']?.toString().toLowerCase() == nombre.toLowerCase() ||
          rol['nombre']?.toString().toLowerCase() == nombre.toLowerCase())) {
        throw ApiException(
          statusCode: 400,
          message: 'Ya existe un rol con el nombre "$nombre"',
          errorCode: ApiConstants.errorCodes[400] ?? ApiConstants.unknownError,
        );
      }

      // Llamar al endpoint de creación de rol
      return await _cuentasEmpleadosApi.createRolCuenta(
        nombre: nombre,
        codigo: codigo,
      );
    } catch (e) {
      debugPrint('Error en EmpleadoRepository.crearRolCuenta: $e');
      rethrow;
    }
  }

  /// Valida los datos de una cuenta de empleado
  ///
  /// Lanza ApiException si los datos son inválidos
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

  /// Valida el ID de cuenta de un empleado
  ///
  /// Lanza ApiException si el ID es inválido
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

  // MÉTODOS AUXILIARES

  /// Determina si un error es debido a recurso no encontrado
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

  /// Determina si un error es debido a problemas de autenticación
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
