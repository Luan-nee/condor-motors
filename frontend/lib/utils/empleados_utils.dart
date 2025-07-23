import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleado_horario_dialog.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Clase de utilidades para funciones comunes relacionadas con empleados
///
/// Este archivo centraliza funciones reutilizables relacionadas con empleados
/// para formateo, visualización y presentación en la interfaz de usuario.
/// Al mantener estas funciones en una clase de utilidad, se logra:
///
/// 1. Reducir la duplicación de código en diferentes widgets
/// 2. Facilitar el mantenimiento al centralizar la lógica común
/// 3. Mejorar la consistencia en la presentación y el comportamiento
/// 4. Permitir la reutilización en otros componentes de la aplicación
///
/// Las funciones incluidas manejan la presentación visual de datos de empleados
/// y funcionan como utilidades UI para los componentes de la aplicación.
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

  /// Obtiene el rol de un empleado con prioridad al rol del modelo
  static String getRolEmpleado(
      Empleado empleado, Function obtenerRolDeEmpleado) {
    // Primero intentar usar el rol que viene directamente del empleado
    if (empleado.rol != null) {
      return empleado.rol!.nombre;
    }

    // Si no está disponible, usar la función del provider
    return obtenerRolDeEmpleado(empleado);
  }

  /// Obtiene el nombre de la sucursal a partir de su ID
  static String getNombreSucursal(
      String? sucursalId, Map<String, String> nombresSucursales) {
    if (sucursalId == null || sucursalId.isEmpty) {
      return 'Sin asignar';
    }
    return nombresSucursales[sucursalId] ?? 'Sucursal $sucursalId';
  }

  /// Obtiene el nombre de la sucursal de un empleado
  static String getNombreSucursalEmpleado(
      Empleado empleado, Map<String, String> nombresSucursales) {
    // Primero intentar usar el nombre de sucursal que viene directamente del empleado
    if (empleado.sucursalNombre != null) {
      if (empleado.sucursalCentral) {
        return '${empleado.sucursalNombre!} (Central)';
      }
      return empleado.sucursalNombre!;
    }

    // Si no está disponible, usar el mapa de nombres de sucursales
    return getNombreSucursal(empleado.sucursalId, nombresSucursales);
  }

  /// Determina si una sucursal es central basado en su nombre
  static bool esSucursalCentral(
      String? sucursalId, Map<String, String> nombresSucursales) {
    if (sucursalId == null || sucursalId.isEmpty) {
      return false;
    }
    final String nombre = nombresSucursales[sucursalId] ?? '';
    return nombre.contains('(Central)');
  }

  /// Determina si la sucursal de un empleado es central
  static bool esSucursalCentralEmpleado(
      Empleado empleado, Map<String, String> nombresSucursales) {
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
    return empleado.tieneCuenta;
  }

  /// Obtiene el nombre de usuario de la cuenta de un empleado
  ///
  /// Retorna el nombre de usuario o null si no tiene cuenta asociada
  static String? getUsuarioCuenta(Empleado empleado) {
    return empleado.cuentaEmpleadoUsuario;
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
  static Map<String, List<Empleado>> agruparEmpleadosPorEstado(
      List<Empleado> empleados) {
    final Map<String, List<Empleado>> grupos = <String, List<Empleado>>{
      'activos': <Empleado>[],
      'inactivos': <Empleado>[],
    };

    for (final Empleado empleado in empleados) {
      if (empleado.activo) {
        grupos['activos']!.add(empleado);
      } else {
        grupos['inactivos']!.add(empleado);
      }
    }

    return grupos;
  }

  /// Obtiene un ícono para el estado de un empleado (activo/inactivo)
  static IconData getIconoEstadoEmpleado({required bool activo}) {
    return activo ? FontAwesomeIcons.userCheck : FontAwesomeIcons.userXmark;
  }

  /// Obtiene el color para el estado de un empleado (activo/inactivo)
  static Color getColorEstadoEmpleado({required bool activo}) {
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
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
      final List<String> partes = horaInicio.split(':');
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
      final List<String> partes = horaFin.split(':');
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

  /// Crea un widget para mostrar información de cuenta en forma de filas de información
  static Widget buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
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
    if (sueldo == null) {
      return 'No especificado';
    }
    return 'S/ ${sueldo.toStringAsFixed(2)}';
  }

  /// Formatea un valor de fecha para mostrar
  static String formatearFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) {
      return 'No especificada';
    }
    // Si se necesita un formato más complejo, se puede implementar aquí
    return fecha;
  }

  /// Muestra el diálogo de horario del empleado
  static Future<void> mostrarHorarioEmpleado(
      BuildContext context, Empleado empleado) async {
    // Verificar si el contexto es seguro de usar antes de mostrar el diálogo
    if (!context.mounted) {
      return;
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) =>
          EmpleadoHorarioDialog(empleado: empleado),
    );
  }

  /// Muestra un diálogo de carga
  static Future<void> mostrarDialogoCarga(
    BuildContext context, {
    String mensaje = 'Procesando...',
    bool barrierDismissible = false,
  }) async {
    // Verificar si el contexto es seguro de usar antes de mostrar el diálogo
    if (!context.mounted) {
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
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
    required bool esError,
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
  static String getDescripcionEstado({required bool activo}) {
    return activo
        ? 'El colaborador está trabajando actualmente en la empresa'
        : 'El colaborador no está trabajando actualmente en la empresa';
  }

  /// Obtiene un texto formateado con la información de horario
  static String getHorarioFormateado(Empleado empleado) {
    final String horaInicio = formatearHora(empleado.horaInicioJornada);
    final String horaFin = formatearHora(empleado.horaFinJornada);
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
            color: const Color(0xFFE31E24).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
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
              children: <Widget>[
                Expanded(
                  child: buildInfoItem('Usuario', '@$usuarioActual'),
                ),
                if (rolCuentaActual != null)
                  Expanded(
                    child: buildInfoItem('Rol de cuenta', rolCuentaActual),
                  ),
              ],
            ),
            if (onGestionarCuenta != null) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
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
      return const SizedBox
          .shrink(); // Devolver un widget vacío si no hay cuenta
    }
  }

  /// Genera un contenedor con información de cuenta directamente desde un objeto Empleado
  static Widget buildInfoCuentaContainerFromEmpleado({
    required Empleado empleado,
    required bool isLoading,
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
    } else if (empleado.tieneCuenta) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE31E24).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
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
              children: <Widget>[
                Expanded(
                  child: buildInfoItem(
                      'Usuario', '@${empleado.cuentaEmpleadoUsuario}'),
                ),
                if (empleado.rol != null)
                  Expanded(
                    child: buildInfoItem('Rol de cuenta', empleado.rol!.nombre),
                  ),
              ],
            ),
            if (onGestionarCuenta != null) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
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
      return const SizedBox
          .shrink(); // Devolver un widget vacío si no hay cuenta
    }
  }
}
