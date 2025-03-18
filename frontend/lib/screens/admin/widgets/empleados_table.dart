import 'package:flutter/material.dart';
import '../../../api/protected/empleados.api.dart';
import 'empleado_list_item.dart';
import 'empleados_utils.dart';

class EmpleadosTable extends StatelessWidget {
  final List<Empleado> empleados;
  final Map<String, String> nombresSucursales;
  final String Function(Empleado) obtenerRolDeEmpleado;
  final Function(Empleado) onEdit;
  final Function(Empleado) onDelete;
  final Function(Empleado) onViewDetails;
  final Function(Empleado, bool) onChangeStatus;
  final bool isLoading;
  final bool hasMorePages;
  final VoidCallback onLoadMore;
  final String errorMessage;
  final VoidCallback onRetry;

  const EmpleadosTable({
    Key? key,
    required this.empleados,
    required this.nombresSucursales,
    required this.obtenerRolDeEmpleado,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
    required this.onChangeStatus,
    required this.isLoading,
    required this.hasMorePages,
    required this.onLoadMore,
    this.errorMessage = '',
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Agrupar empleados por estado
    final gruposEmpleados = EmpleadosUtils.agruparEmpleadosPorEstado(empleados);
    final empleadosActivos = gruposEmpleados['activos'] ?? [];
    final empleadosInactivos = gruposEmpleados['inactivos'] ?? [];
    
    // Determinar si hay empleados inactivos para mostrar
    final hayEmpleadosInactivos = empleadosInactivos.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: isLoading && empleados.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onRetry,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : empleados.isEmpty
            ? const Center(
                child: Text(
                  'No hay colaboradores para mostrar',
                  style: TextStyle(color: Colors.white54),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Encabezado de la tabla
                    Container(
                      color: const Color(0xFF2D2D2D),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      child: const Row(
                        children: [
                          // Nombre (25% del ancho)
                          Expanded(
                            flex: 25,
                            child: Text(
                              'Nombre',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Celular (15% del ancho)
                          Expanded(
                            flex: 15,
                            child: Text(
                              'Celular',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Rol (20% del ancho)
                          Expanded(
                            flex: 20,
                            child: Text(
                              'Rol',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Local (30% del ancho - aumentado del 20% al 30%)
                          Expanded(
                            flex: 30,
                            child: Text(
                              'Local',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Acciones (10% del ancho)
                          Expanded(
                            flex: 10,
                            child: Text(
                              'Acciones',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Filas de colaboradores activos
                    if (empleadosActivos.isNotEmpty) ...[
                      ...empleadosActivos.map((empleado) => EmpleadoListItem(
                        empleado: empleado,
                        nombresSucursales: nombresSucursales,
                        onEdit: onEdit,
                        onDelete: onDelete,
                        onViewDetails: onViewDetails,
                        onChangeStatus: onChangeStatus,
                        obtenerRolDeEmpleado: obtenerRolDeEmpleado,
                      )),
                    ],
                    
                    // Sección de colaboradores inactivos
                    if (hayEmpleadosInactivos) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: EmpleadosUtils.getEtiquetaGrupoEmpleados('inactivos', empleadosInactivos.length),
                      ),
                      const SizedBox(height: 8),
                      
                      // Contenedor con fondo especial para empleados inactivos
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          border: Border.all(
                            color: const Color(0xFFE31E24).withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: empleadosInactivos.map((empleado) => EmpleadoListItem(
                            empleado: empleado,
                            nombresSucursales: nombresSucursales,
                            onEdit: onEdit,
                            onDelete: onDelete,
                            onViewDetails: onViewDetails,
                            onChangeStatus: onChangeStatus,
                            obtenerRolDeEmpleado: obtenerRolDeEmpleado,
                          )).toList(),
                        ),
                      ),
                    ],
                    
                    // Botón para cargar más
                    if (hasMorePages && !isLoading)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: onLoadMore,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D2D2D),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Cargar más'),
                          ),
                        ),
                      ),
                      
                    // Indicador de carga para paginación
                    if (isLoading && empleados.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
} 