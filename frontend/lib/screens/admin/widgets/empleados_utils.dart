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

  /// Determina si una sucursal es central basado en su nombre
  static bool esSucursalCentral(String? sucursalId, Map<String, String> nombresSucursales) {
    if (sucursalId == null || sucursalId.isEmpty) {
      return false;
    }
    final nombre = nombresSucursales[sucursalId] ?? '';
    return nombre.contains('(Central)');
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
} 