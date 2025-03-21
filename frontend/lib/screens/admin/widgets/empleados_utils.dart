import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import '../../../models/empleado.model.dart';
import '../../../main.dart' show api;
import '../../../api/main.api.dart' show ApiException;
import 'empleado_cuenta_dialog.dart';
import 'empleado_horario_dialog.dart';

/// Clase de utilidades para funciones comunes relacionadas con empleados
///
/// Este archivo centraliza funciones reutilizables relacionadas con empleados, sus cuentas,
/// roles, sucursales y presentación en la interfaz de usuario. Al mantener estas funciones
/// en una clase de utilidad, se logra:
///
/// 1. Reducir la duplicación de código en diferentes widgets
/// 2. Facilitar el mantenimiento al centralizar la lógica común
/// 3. Mejorar la consistencia en la presentación y el comportamiento
/// 4. Permitir la reutilización en otros componentes de la aplicación
/// 5. Separar la lógica de negocio de la lógica de presentación
///
/// Las funciones incluidas manejan la carga de información de cuentas, la gestión de cuentas,
/// la inicialización de campos de formulario, y la presentación visual de datos de empleados.
class EmpleadosUtils {
  /// Obtiene el icono correspondiente al rol del empleado
  static IconData getRolIcon(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
        return FontAwesomeIcons.userGear;
      case 'vendedor':
        return FontAwesomeIcons.cashRegister;
      case 'computadora':
        return FontAwesomeIcons.desktop;
      default:
        return FontAwesomeIcons.user;
    }
  }
  
  /// Determina el rol de un empleado basado en su ID y sucursal
  static String obtenerRolDeEmpleado(Empleado empleado) {
    // En un entorno de producción, esto se obtendría de una propiedad del empleado
    // o consultando una tabla de relaciones empleado-rol
    
    // Como no tenemos el rol en los datos del empleado, podemos asignar roles 
    // basados en alguna lógica de negocio o patrón:
    
    // Por ejemplo, el ID 13 corresponde al "Administrador Principal"
    if (empleado.id == "13") {
      return "Administrador";
    }
    
    // Sucursal central (ID 7) podrían ser administradores
    if (empleado.sucursalId == "7") {
      return "Administrador";
    }
    
    // Alternamos entre vendedor y computadora para el resto
    final idNum = int.tryParse(empleado.id) ?? 0;
    if (idNum % 2 == 0) {
      return "Vendedor";
    } else {
      return "Computadora";
    }
    
    // NOTA: Esta es una asignación ficticia. En producción, deberías obtener
    // el rol real de cada empleado desde la base de datos
  }
  
  /// Obtiene el nombre de la sucursal a partir de su ID
  static String getNombreSucursal(String? sucursalId, Map<String, String> nombresSucursales) {
    if (sucursalId == null || sucursalId.isEmpty) {
      return 'Sin asignar';
    }
    return nombresSucursales[sucursalId] ?? 'Sucursal $sucursalId';
  }

  /// Obtiene el nombre de la sucursal de un empleado
  static String getNombreSucursalEmpleado(Empleado empleado, Map<String, String> nombresSucursales) {
    // Primero intentar usar el nombre de sucursal que viene directamente del empleado
    if (empleado.sucursalNombre != null) {
      if (empleado.sucursalCentral) {
        return "${empleado.sucursalNombre!} (Central)";
      }
      return empleado.sucursalNombre!;
    }
    
    // Si no está disponible, usar el mapa de nombres de sucursales
    return getNombreSucursal(empleado.sucursalId, nombresSucursales);
  }

  /// Determina si una sucursal es central basado en su nombre
  static bool esSucursalCentral(String? sucursalId, Map<String, String> nombresSucursales) {
    if (sucursalId == null || sucursalId.isEmpty) {
      return false;
    }
    final nombre = nombresSucursales[sucursalId] ?? '';
    return nombre.contains('(Central)');
  }
  
  /// Determina si la sucursal de un empleado es central
  static bool esSucursalCentralEmpleado(Empleado empleado, Map<String, String> nombresSucursales) {
    // Si tenemos el dato directamente del empleado, usarlo
    if (empleado.sucursalCentral) {
      return true;
    }
    
    // Si no, usar el método tradicional
    return esSucursalCentral(empleado.sucursalId, nombresSucursales);
  }
  
  /// Obtiene el ID de cuenta asociado a un empleado
  /// 
  /// Retorna el ID de la cuenta si existe, o null si no tiene cuenta asociada
  static String? getCuentaEmpleadoId(Empleado empleado) {
    return empleado.cuentaEmpleadoId;
  }
  
  /// Determina si un empleado tiene cuenta de usuario asociada
  /// 
  /// Retorna true si el empleado tiene una cuenta asociada
  static bool tieneCuentaAsociada(Empleado empleado) {
    return empleado.cuentaEmpleadoId != null;
  }
  
  /// Formatea una hora para mostrarla sin segundos
  static String formatearHora(String? hora) {
    if (hora == null || hora.isEmpty) {
      return 'No especificada';
    }
    
    // Si la hora ya tiene el formato HH:MM, devolverla como está
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(hora)) {
      return hora;
    }
    
    // Si la hora tiene formato HH:MM:SS, quitar los segundos
    if (RegExp(r'^\d{1,2}:\d{2}:\d{2}$').hasMatch(hora)) {
      return hora.substring(0, 5);
    }
    
    // Si no se puede formatear, devolver la hora original
    return hora;
  }
  
  /// Agrupa empleados por su estado (activo/inactivo)
  ///
  /// Retorna un mapa con dos listas: 'activos' e 'inactivos'
  static Map<String, List<Empleado>> agruparEmpleadosPorEstado(List<Empleado> empleados) {
    final Map<String, List<Empleado>> grupos = {
      'activos': [],
      'inactivos': [],
    };
    
    for (final empleado in empleados) {
      if (empleado.activo) {
        grupos['activos']!.add(empleado);
      } else {
        grupos['inactivos']!.add(empleado);
      }
    }
    
    return grupos;
  }
  
  /// Obtiene un ícono para el estado de un empleado (activo/inactivo)
  static IconData getIconoEstadoEmpleado(bool activo) {
    return activo ? FontAwesomeIcons.userCheck : FontAwesomeIcons.userXmark;
  }
  
  /// Obtiene el color para el estado de un empleado (activo/inactivo)
  static Color getColorEstadoEmpleado(bool activo) {
    return activo ? const Color(0xFF4CAF50) : Colors.grey;
  }
  
  /// Obtiene una etiqueta descriptiva para un grupo de empleados según su estado
  ///
  /// Retorna un widget con un estilo adecuado para cada tipo de grupo
  static Widget getEtiquetaGrupoEmpleados(String grupo, int cantidad) {
    late final Color color;
    late final IconData icono;
    late final String texto;
    
    switch (grupo) {
      case 'activos':
        color = const Color(0xFF4CAF50);
        icono = FontAwesomeIcons.userCheck;
        texto = 'Colaboradores Activos';
        break;
      case 'inactivos':
        // Cambiamos el color de los inactivos a gris neutral en lugar de rojo
        color = Colors.grey;
        icono = FontAwesomeIcons.userXmark;
        texto = 'Colaboradores Inactivos';
        break;
      default:
        color = Colors.grey;
        icono = FontAwesomeIcons.users;
        texto = 'Colaboradores';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icono,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            '$texto ($cantidad)',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Inicializa los controladores de horario con valores predeterminados o desde valores existentes
  static void inicializarHorarios({
    required TextEditingController horaInicioHoraController,
    required TextEditingController horaInicioMinutoController,
    required TextEditingController horaFinHoraController,
    required TextEditingController horaFinMinutoController,
    String? horaInicio,
    String? horaFin,
  }) {
    // Inicializar hora de inicio
    if (horaInicio != null && horaInicio.isNotEmpty) {
      final partes = horaInicio.split(':');
      if (partes.length >= 2) {
        horaInicioHoraController.text = partes[0].padLeft(2, '0');
        horaInicioMinutoController.text = partes[1].padLeft(2, '0');
      } else {
        horaInicioHoraController.text = '08';
        horaInicioMinutoController.text = '00';
      }
    } else {
      horaInicioHoraController.text = '08';
      horaInicioMinutoController.text = '00';
    }
    
    // Inicializar hora de fin
    if (horaFin != null && horaFin.isNotEmpty) {
      final partes = horaFin.split(':');
      if (partes.length >= 2) {
        horaFinHoraController.text = partes[0].padLeft(2, '0');
        horaFinMinutoController.text = partes[1].padLeft(2, '0');
      } else {
        horaFinHoraController.text = '17';
        horaFinMinutoController.text = '00';
      }
    } else {
      horaFinHoraController.text = '17';
      horaFinMinutoController.text = '00';
    }
  }
  
  /// Obtiene el nombre de un rol a partir de su ID
  static Future<String?> obtenerNombreRol(int rolId) async {
    try {
      final roles = await api.cuentasEmpleados.getRolesCuentas();
      final rol = roles.firstWhere(
        (r) => r['id'] == rolId,
        orElse: () => <String, dynamic>{},
      );
      
      return rol['nombre'] ?? rol['codigo'] ?? 'Rol #$rolId';
    } catch (e) {
      // No actualizar el estado si hay error
      debugPrint('Error al obtener nombre de rol: $e');
      return null;
    }
  }
  
  /// Carga información de la cuenta de un empleado
  /// 
  /// Retorna un Future con un Map que contiene la información de la cuenta
  static Future<Map<String, dynamic>> cargarInformacionCuenta(Empleado empleado) async {
    final Map<String, dynamic> resultado = {
      'cuentaNoEncontrada': false,
      'errorCargaInfo': null as String?,
      'usuarioActual': null as String?,
      'rolCuentaActual': null as String?,
    };
    
    try {
      // Verificar si el empleado ya tiene una cuenta asociada
      if (empleado.cuentaEmpleadoId != null) {
        final cuentaId = empleado.cuentaEmpleadoId!;
        final cuentaIdInt = int.tryParse(cuentaId);
        
        if (cuentaIdInt != null) {
          try {
            // Obtener información de la cuenta usando la API
            final cuentaInfo = await api.cuentasEmpleados.getCuentaEmpleadoById(cuentaIdInt);
            
            if (cuentaInfo != null) {
              resultado['usuarioActual'] = cuentaInfo['usuario']?.toString();
              
              // Obtener información del rol si está disponible
              final rolId = cuentaInfo['rolCuentaEmpleadoId'];
              if (rolId != null) {
                resultado['rolCuentaActual'] = await obtenerNombreRol(rolId);
              }
              return resultado; // Encontramos la cuenta, devolver resultado exitoso
            } else {
              // La cuenta no fue encontrada a pesar de tener un ID registrado
              resultado['cuentaNoEncontrada'] = true;
              resultado['errorCargaInfo'] = 'Cuenta no encontrada. El ID registrado parece ser inválido.';
              return resultado; // Devolver resultado con cuenta no encontrada
            }
          } catch (e) {
            // Si el error indica que no se encontró la cuenta, marcar como cuenta no encontrada
            if (e.toString().contains('404') || 
                e.toString().contains('not found') ||
                e.toString().contains('no encontrado') ||
                e.toString().contains('no existe')) {
              debugPrint('EmpleadosUtils: Cuenta no encontrada por ID: ${e.toString()}');
              resultado['cuentaNoEncontrada'] = true;
              return resultado; // Devolver resultado con cuenta no encontrada
            }
            
            // Determinar si es un error de autenticación genuino
            final esErrorAutenticacion = e.toString().contains('401') && 
                (e.toString().contains('No autorizado') || 
                e.toString().contains('Sesión expirada') ||
                e.toString().contains('token inválido'));
            
            if (esErrorAutenticacion) {
              debugPrint('EmpleadosUtils: Error de autenticación al obtener cuenta por ID: $e');
              rethrow; // Propagar error de autenticación
            }
            
            // Otro tipo de error, continuar intentando con el empleadoId
            debugPrint('EmpleadosUtils: Error al obtener cuenta por ID: $e');
          }
        }
      }
      
      // Si llegamos aquí, intentar obtener la cuenta por ID de empleado
      try {
        // Usar headers especiales para evitar reintentos de token
        final cuentaInfo = await api.cuentasEmpleados.getCuentaByEmpleadoId(empleado.id);
        
        if (cuentaInfo != null) {
          resultado['usuarioActual'] = cuentaInfo['usuario']?.toString();
          
          // Obtener información del rol si está disponible
          final rolId = cuentaInfo['rolCuentaEmpleadoId'];
          if (rolId != null) {
            resultado['rolCuentaActual'] = await obtenerNombreRol(rolId);
          }
        } else {
          // No se encontró una cuenta - indicar que no hay cuenta
          resultado['cuentaNoEncontrada'] = true;
        }
      } catch (e) {
        // Identificar el tipo de error
        final bool esErrorNotFound = e.toString().contains('404') || 
            e.toString().toLowerCase().contains('not found') ||
            e.toString().toLowerCase().contains('no encontrado') ||
            e.toString().toLowerCase().contains('no existe') ||
            e.toString().toLowerCase().contains('empleado no tiene cuenta');
        
        final bool esErrorAutenticacion = e.toString().contains('401') && 
            (e.toString().contains('No autorizado') || 
            e.toString().contains('Sesión expirada') ||
            e.toString().contains('token inválido'));
        
        if (esErrorNotFound) {
          // Si el error indica que no se encontró la cuenta, marcar como cuenta no encontrada
          debugPrint('EmpleadosUtils: Empleado sin cuenta: ${e.toString()}');
          resultado['cuentaNoEncontrada'] = true;
        } else if (esErrorAutenticacion) {
          // Si es un error de autenticación, propagarlo para que se maneje a nivel superior
          debugPrint('EmpleadosUtils: Error de autenticación: ${e.toString()}');
          rethrow;
        } else {
          // Para otros errores, mostrar mensaje genérico
          debugPrint('Error al cargar información de cuenta: $e');
          resultado['errorCargaInfo'] = 'Error al cargar información: ${e.toString().replaceAll('Exception: ', '')}';
        }
      }
    } catch (e) {
      // Para errores en el flujo principal (incluyendo errores de autenticación propagados)
      debugPrint('Error general al cargar información de cuenta: $e');
      
      // Verificar si es un error relacionado con "cuenta no encontrada"
      final bool esErrorNotFound = e.toString().contains('404') || 
          e.toString().toLowerCase().contains('not found') ||
          e.toString().toLowerCase().contains('no encontrado') ||
          e.toString().toLowerCase().contains('no existe') ||
          e.toString().toLowerCase().contains('empleado no tiene cuenta');
      
      if (esErrorNotFound) {
        // Si el error indica que no se encontró la cuenta, marcar como cuenta no encontrada
        debugPrint('EmpleadosUtils: Empleado sin cuenta (error general): ${e.toString()}');
        resultado['cuentaNoEncontrada'] = true;
        return resultado;
      }
      
      // Si es un error de autenticación, propagarlo
      if (e.toString().contains('401') && 
          (e.toString().contains('No autorizado') || 
          e.toString().contains('Sesión expirada') ||
          e.toString().contains('token inválido'))) {
        rethrow;
      }
      
      resultado['errorCargaInfo'] = 'Error al cargar información: ${e.toString().replaceAll('Exception: ', '')}';
    }
    
    return resultado;
  }
  
  /// Gestiona la cuenta de un empleado (creación, edición o eliminación)
  /// 
  /// Muestra un diálogo para gestionar la cuenta y maneja todas las interacciones con la API
  static Future<bool> gestionarCuenta(BuildContext context, Empleado empleado) async {
    bool isLoading = true;
    
    try {
      // Obtener roles disponibles
      final roles = await api.cuentasEmpleados.getRolesCuentas();
      
      // Obtener información de la cuenta (si existe)
      Map<String, dynamic>? cuentaInfo;
      String? cuentaId;
      String? usuarioActual;
      int? rolActualId;
      bool cuentaEncontrada = false;
      bool esCreacionDeCuenta = false;
      
      // Verificar si el empleado ya tiene una cuenta asociada
      if (tieneCuentaAsociada(empleado)) {
        cuentaId = empleado.cuentaEmpleadoId;
        
        // Intentar obtener la cuenta por ID
        if (cuentaId != null) {
          final cuentaIdInt = int.tryParse(cuentaId);
          if (cuentaIdInt != null) {
            try {
              cuentaInfo = await api.cuentasEmpleados.getCuentaEmpleadoById(cuentaIdInt);
              if (cuentaInfo != null) {
                cuentaEncontrada = true;
                usuarioActual = cuentaInfo['usuario']?.toString();
                rolActualId = cuentaInfo['rolCuentaEmpleadoId'];
              }
            } catch (e) {
              // Determinar si es un error de autenticación genuino
              final esErrorAutenticacion = e.toString().contains('401') && 
                  (e.toString().contains('No autorizado') || 
                   e.toString().contains('Sesión expirada') ||
                   e.toString().contains('token inválido'));
              
              if (esErrorAutenticacion) {
                debugPrint('EmpleadosUtils: Error de autenticación al obtener cuenta: $e');
                rethrow; // Propagar error de autenticación para manejarlo a nivel superior
              }
              
              // Verificar si el error indica que no se encontró la cuenta
              final esErrorNotFound = e.toString().contains('404') || 
                  e.toString().toLowerCase().contains('not found') ||
                  e.toString().toLowerCase().contains('no encontrado') ||
                  e.toString().toLowerCase().contains('no existe') ||
                  e.toString().toLowerCase().contains('empleado no tiene cuenta');
                  
              if (esErrorNotFound) {
                // Si el error indica que no se encontró la cuenta, continuar como cuenta no encontrada
                debugPrint('EmpleadosUtils: Cuenta no encontrada por ID: ${e.toString()}');
                esCreacionDeCuenta = true;
              } else {
                debugPrint('Error al obtener cuenta por ID: $e');
              }
              // Continuar para intentar buscar por ID de empleado
            }
          }
        }
      }
      
      // Si no se encontró la cuenta por ID directo, intentar por ID de empleado
      if (!cuentaEncontrada) {
        try {
          cuentaInfo = await api.cuentasEmpleados.getCuentaByEmpleadoId(empleado.id);
          if (cuentaInfo != null) {
            cuentaEncontrada = true;
            cuentaId = cuentaInfo['id']?.toString();
            usuarioActual = cuentaInfo['usuario']?.toString();
            rolActualId = cuentaInfo['rolCuentaEmpleadoId'];
          } else {
            // No se encontró una cuenta (respuesta exitosa pero sin datos)
            debugPrint('EmpleadosUtils: No se encontró cuenta para empleado ${empleado.id}');
            esCreacionDeCuenta = true;
            debugPrint('EmpleadosUtils: Estableciendo esCreacionDeCuenta = true por respuesta exitosa sin datos');
          }
        } catch (e) {
          // Identificar el tipo de error
          final bool esErrorNotFound = e.toString().contains('404') || 
              e.toString().toLowerCase().contains('not found') ||
              e.toString().toLowerCase().contains('no encontrado') ||
              e.toString().toLowerCase().contains('no existe') ||
              e.toString().toLowerCase().contains('empleado no tiene cuenta');
          
          final bool esErrorAutenticacion = e.toString().contains('401') && 
              (e.toString().contains('No autorizado') || 
               e.toString().contains('Sesión expirada') ||
               e.toString().contains('token inválido'));
          
          if (esErrorNotFound) {
            // Es un error "no encontrado", tratar como creación de cuenta nueva
            debugPrint('EmpleadosUtils: Empleado sin cuenta confirmado: ${e.toString()}');
            esCreacionDeCuenta = true;
            debugPrint('EmpleadosUtils: Estableciendo esCreacionDeCuenta = true por error 404/not found');
          } else if (esErrorAutenticacion) {
            // Es un error genuino de autenticación, propagarlo
            debugPrint('EmpleadosUtils: Error de autenticación al buscar cuenta: $e');
            rethrow;
          } else {
            // Para otros errores, propagar para que se manejen externamente
            debugPrint('EmpleadosUtils: Error al buscar cuenta: $e');
            rethrow;
          }
        }
      }
      
      isLoading = false;
      
      // Preparar título para el diálogo
      final nombreEmpleado = '${empleado.nombre} ${empleado.apellidos}';
      
      // Mostrar diálogo para gestionar la cuenta
      final dialogResult = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: EmpleadoCuentaDialog(
              empleadoId: empleado.id,
              empleadoNombre: nombreEmpleado,
              cuentaId: cuentaId,
              usuarioActual: usuarioActual,
              rolActualId: rolActualId,
              roles: roles,
              // Indicar explícitamente si debe mostrarse como creación de cuenta
              esNuevaCuenta: esCreacionDeCuenta,
            ),
          ),
        ),
      );
      
      return dialogResult == true;
    } catch (e) {
      debugPrint('Error al gestionar cuenta: $e');
      isLoading = false;
      
      // Verificar si es un error que indica que no se encontró la cuenta
      final bool esErrorNotFound = e.toString().contains('404') || 
          e.toString().toLowerCase().contains('not found') ||
          e.toString().toLowerCase().contains('no encontrado') ||
          e.toString().toLowerCase().contains('no existe') ||
          e.toString().toLowerCase().contains('empleado no tiene cuenta');
          
      if (esErrorNotFound && context.mounted) {
        // Si es un error "no encontrado", mostrar diálogo de creación de cuenta
        debugPrint('EmpleadosUtils: Mostrando formulario de creación de cuenta tras error 404/not found');
        
        // Preparar título para el diálogo
        final nombreEmpleado = '${empleado.nombre} ${empleado.apellidos}';
        
        // Obtener roles disponibles (reintento)
        List<Map<String, dynamic>> roles = [];
        try {
          roles = await api.cuentasEmpleados.getRolesCuentas();
        } catch (rolesError) {
          debugPrint('EmpleadosUtils: Error al obtener roles: $rolesError');
          // Continuar con lista vacía
        }
        
        // Mostrar diálogo de creación de cuenta
        final dialogResult = await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: EmpleadoCuentaDialog(
                empleadoId: empleado.id,
                empleadoNombre: nombreEmpleado,
                roles: roles,
                esNuevaCuenta: true, // Forzar modo de creación de cuenta
              ),
            ),
          ),
        );
        
        return dialogResult == true;
      }
      
      rethrow;
    }
  }
  
  /// Crea un widget para mostrar información de cuenta en forma de filas de información
  static Widget buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  /// Formatea un valor de sueldo para mostrar
  static String formatearSueldo(double? sueldo) {
    if (sueldo == null) return 'No especificado';
    return 'S/ ${sueldo.toStringAsFixed(2)}';
  }
  
  /// Formatea un valor de fecha para mostrar
  static String formatearFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return 'No especificada';
    // Si se necesita un formato más complejo, se puede implementar aquí
    return fecha;
  }
  
  /// Muestra el diálogo de horario del empleado
  static Future<void> mostrarHorarioEmpleado(BuildContext context, Empleado empleado) async {
    await showDialog(
      context: context,
      builder: (context) => EmpleadoHorarioDialog(empleado: empleado),
    );
  }
  
  /// Muestra un diálogo de carga
  static Future<void> mostrarDialogoCarga(BuildContext context, {
    String mensaje = 'Procesando...',
    bool barrierDismissible = false,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                mensaje,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Muestra un mensaje de error o éxito usando un SnackBar
  static void mostrarMensaje(
    BuildContext context, {
    required String mensaje,
    bool esError = false,
    VoidCallback? accion,
    String? textoAccion,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red : Colors.green,
        action: accion != null && textoAccion != null
            ? SnackBarAction(
                label: textoAccion,
                textColor: Colors.white,
                onPressed: accion,
              )
            : null,
      ),
    );
  }
  
  /// Formatea el nombre completo de un empleado
  static String getNombreCompleto(Empleado empleado) {
    return '${empleado.nombre} ${empleado.apellidos}';
  }
  
  /// Genera un mensaje descriptivo para estados de empleado activo/inactivo
  static String getDescripcionEstado(bool activo) {
    return activo 
        ? 'El colaborador está trabajando actualmente en la empresa'
        : 'El colaborador no está trabajando actualmente en la empresa';
  }
  
  /// Obtiene un texto formateado con la información de horario
  static String getHorarioFormateado(Empleado empleado) {
    final horaInicio = formatearHora(empleado.horaInicioJornada);
    final horaFin = formatearHora(empleado.horaFinJornada);
    return '$horaInicio - $horaFin';
  }
  
  /// Genera un contenedor con información de cuenta para mostrar en diferentes pantallas
  static Widget buildInfoCuentaContainer({
    required bool isLoading,
    String? usuarioActual,
    String? rolCuentaActual,
    Function()? onGestionarCuenta,
  }) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
            ),
          ),
        ),
      );
    } else if (usuarioActual != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE31E24).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.userShield,
                  color: Color(0xFFE31E24),
                  size: 14,
                ),
                SizedBox(width: 8),
                Text(
                  'INFORMACIÓN DE CUENTA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE31E24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: buildInfoItem('Usuario', '@$usuarioActual'),
                ),
                if (rolCuentaActual != null)
                  Expanded(
                    child: buildInfoItem('Rol de cuenta', rolCuentaActual),
                  ),
              ],
            ),
            if (onGestionarCuenta != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const FaIcon(
                      FontAwesomeIcons.key,
                      size: 12,
                      color: Colors.white70,
                    ),
                    label: const Text(
                      'Gestionar cuenta',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: onGestionarCuenta,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF3D3D3D),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    } else {
      return const SizedBox.shrink(); // Devolver un widget vacío si no hay cuenta
    }
  }
} 