import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import '../../../api/protected/empleados.api.dart';

/// Clase de utilidades para funciones comunes relacionadas con empleados
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
        color = const Color(0xFFE31E24);
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
} 