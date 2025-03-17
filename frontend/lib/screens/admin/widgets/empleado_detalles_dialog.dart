import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../api/protected/empleados.api.dart';
import 'empleado_horario_dialog.dart';
import 'empleados_utils.dart';

class EmpleadoDetallesDialog extends StatelessWidget {
  final Empleado empleado;
  final Map<String, String> nombresSucursales;
  final String Function(Empleado) obtenerRolDeEmpleado;
  final Function(Empleado) onEdit;

  const EmpleadoDetallesDialog({
    Key? key,
    required this.empleado,
    required this.nombresSucursales,
    required this.obtenerRolDeEmpleado,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final esCentral = EmpleadosUtils.esSucursalCentral(empleado.sucursalId, nombresSucursales);
    final nombreSucursal = EmpleadosUtils.getNombreSucursal(empleado.sucursalId, nombresSucursales);
    final rol = obtenerRolDeEmpleado(empleado);
    
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con foto y nombre
              Row(
                children: [
                  // Foto o avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: empleado.ubicacionFoto != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              empleado.ubicacionFoto!,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const FaIcon(
                                FontAwesomeIcons.user,
                                color: Color(0xFFE31E24),
                                size: 28,
                              ),
                            ),
                          )
                        : const FaIcon(
                            FontAwesomeIcons.user,
                            color: Color(0xFFE31E24),
                            size: 28,
                          ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Nombre y rol
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${empleado.nombre} ${empleado.apellidos}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2D2D),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFE31E24).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(
                                EmpleadosUtils.getRolIcon(rol),
                                color: const Color(0xFFE31E24),
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                rol,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Información personal
              const Text(
                'INFORMACIÓN PERSONAL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE31E24),
                ),
              ),
              const SizedBox(height: 12),
              
              // Dos columnas para la información
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna izquierda
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoItem('DNI', empleado.dni ?? 'No especificado'),
                        const SizedBox(height: 12),
                        _buildInfoItem('Edad', empleado.edad?.toString() ?? 'No especificada'),
                      ],
                    ),
                  ),
                  
                  // Columna derecha
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoItem('Estado', empleado.activo ? 'Activo' : 'Inactivo'),
                        const SizedBox(height: 12),
                        _buildInfoItem('Fecha Registro', empleado.fechaRegistro ?? 'No especificada'),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Información de sucursal
              const Text(
                'SUCURSAL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE31E24),
                ),
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: esCentral 
                        ? const Color.fromARGB(255, 95, 208, 243) 
                        : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: FaIcon(
                          esCentral
                              ? FontAwesomeIcons.building
                              : FontAwesomeIcons.store,
                          color: esCentral
                              ? const Color.fromARGB(255, 95, 208, 243)
                              : Colors.white54,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombreSucursal,
                            style: TextStyle(
                              color: esCentral
                                  ? const Color.fromARGB(255, 95, 208, 243)
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (esCentral)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Sucursal Central',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Fecha Contratación: ${empleado.fechaContratacion ?? 'No especificada'}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Información laboral
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'INFORMACIÓN LABORAL',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE31E24),
                    ),
                  ),
                  // Botón para ver horario
                  TextButton.icon(
                    icon: const FaIcon(
                      FontAwesomeIcons.clock,
                      size: 14,
                      color: Colors.white70,
                    ),
                    label: const Text(
                      'Ver horario',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () => _mostrarHorarioEmpleado(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2D2D),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna izquierda
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoItem('Sueldo', empleado.sueldo != null 
                          ? 'S/ ${empleado.sueldo!.toStringAsFixed(2)}' 
                          : 'No especificado'),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const FaIcon(
                      FontAwesomeIcons.arrowLeft,
                      size: 14,
                      color: Colors.white54,
                    ),
                    label: const Text('Volver'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white54,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const FaIcon(
                      FontAwesomeIcons.penToSquare,
                      size: 14,
                    ),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      // Cerrar el diálogo de detalles
                      Navigator.pop(context);
                      // Abrir el formulario de edición
                      onEdit(empleado);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarHorarioEmpleado(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EmpleadoHorarioDialog(empleado: empleado),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
} 