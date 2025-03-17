import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../api/protected/empleados.api.dart';
import 'empleados_utils.dart';

class EmpleadoListItem extends StatelessWidget {
  final Empleado empleado;
  final Map<String, String> nombresSucursales;
  final Function(Empleado) onEdit;
  final Function(Empleado) onDelete;
  final Function(Empleado) onViewDetails;
  final Function(Empleado, bool) onChangeStatus;
  final String Function(Empleado) obtenerRolDeEmpleado;

  const EmpleadoListItem({
    Key? key,
    required this.empleado,
    required this.nombresSucursales,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
    required this.onChangeStatus,
    required this.obtenerRolDeEmpleado,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final esCentral = EmpleadosUtils.esSucursalCentral(empleado.sucursalId, nombresSucursales);
    final nombreSucursal = EmpleadosUtils.getNombreSucursal(empleado.sucursalId, nombresSucursales);
    final rol = obtenerRolDeEmpleado(empleado);
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        children: [
          // Nombre
          Expanded(
            flex: 30,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: empleado.ubicacionFoto != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            empleado.ubicacionFoto!,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const FaIcon(
                              FontAwesomeIcons.user,
                              color: Color(0xFFE31E24),
                              size: 14,
                            ),
                          ),
                        )
                      : const FaIcon(
                          FontAwesomeIcons.user,
                          color: Color(0xFFE31E24),
                          size: 14,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${empleado.nombre} ${empleado.apellidos}',
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Rol
          Expanded(
            flex: 25,
            child: Row(
              children: [
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
                        size: 12,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        rol,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Local
          Expanded(
            flex: 25,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: esCentral 
                          ? const Color.fromARGB(255, 95, 208, 243) // Azul para centrales
                          : Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        esCentral
                          ? FontAwesomeIcons.building
                          : FontAwesomeIcons.store,
                        color: esCentral
                          ? const Color.fromARGB(255, 76, 152, 175) // Azul para centrales
                          : Colors.white54,
                        size: 12,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        nombreSucursal,
                        style: TextStyle(
                          color: esCentral
                            ? const Color.fromARGB(255, 76, 160, 175) // Azul para centrales
                            : Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Estado
          Expanded(
            flex: 10,
            child: Center(
              child: Switch(
                value: empleado.activo,
                onChanged: (value) => onChangeStatus(empleado, value),
                activeColor: const Color(0xFFE31E24),
              ),
            ),
          ),
          // Acciones
          Expanded(
            flex: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón de detalles (lupa)
                IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.magnifyingGlass,
                    color: Colors.white,
                    size: 16,
                  ),
                  onPressed: () => onViewDetails(empleado),
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.penToSquare,
                    color: Colors.white54,
                    size: 16,
                  ),
                  onPressed: () => onEdit(empleado),
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.trash,
                    color: Color(0xFFE31E24),
                    size: 16,
                  ),
                  onPressed: () => onDelete(empleado),
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 