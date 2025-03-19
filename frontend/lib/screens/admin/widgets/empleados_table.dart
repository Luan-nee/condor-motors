import 'package:flutter/material.dart';
import '../../../models/empleado.model.dart';
import 'empleado_list_item.dart';
import 'empleados_utils.dart';

class EmpleadosTable extends StatefulWidget {
  final List<Empleado> empleados;
  final Map<String, String> nombresSucursales;
  final String Function(Empleado) obtenerRolDeEmpleado;
  final Function(Empleado) onEdit;
  final Function(Empleado) onDelete;
  final Function(Empleado) onViewDetails;
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
    required this.isLoading,
    required this.hasMorePages,
    required this.onLoadMore,
    this.errorMessage = '',
    required this.onRetry,
  }) : super(key: key);

  @override
  State<EmpleadosTable> createState() => _EmpleadosTableState();
}

class _EmpleadosTableState extends State<EmpleadosTable> {
  // Estado para controlar si la sección de inactivos está expandida
  bool _isInactiveSectionExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Agrupar empleados por estado
    final gruposEmpleados = EmpleadosUtils.agruparEmpleadosPorEstado(widget.empleados);
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
      child: widget.isLoading && widget.empleados.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : widget.errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: widget.onRetry,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : widget.empleados.isEmpty
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
                          // Local (25% del ancho)
                          Expanded(
                            flex: 25,
                            child: Text(
                              'Local',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Acciones (15% del ancho)
                          Expanded(
                            flex: 15,
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
                        nombresSucursales: widget.nombresSucursales,
                        onEdit: widget.onEdit,
                        onDelete: widget.onDelete,
                        onViewDetails: widget.onViewDetails,
                        obtenerRolDeEmpleado: widget.obtenerRolDeEmpleado,
                      )),
                    ],
                    
                    // Sección desplegable de colaboradores inactivos
                    if (hayEmpleadosInactivos) ...[
                      const SizedBox(height: 16),
                      
                      // Encabezado desplegable para inactivos
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isInactiveSectionExpanded = !_isInactiveSectionExpanded;
                          });
                        },
                        child: Container(
                          color: const Color(0xFF2D2D2D),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          child: Row(
                            children: [
                              Icon(
                                _isInactiveSectionExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Colaboradores Inactivos (${empleadosInactivos.length})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                      
                      // Contenido expandible
                      if (_isInactiveSectionExpanded)
                        Column(
                          children: empleadosInactivos.map((empleado) => EmpleadoListItem(
                            empleado: empleado,
                            nombresSucursales: widget.nombresSucursales,
                            onEdit: widget.onEdit,
                            onDelete: widget.onDelete,
                            onViewDetails: widget.onViewDetails,
                            obtenerRolDeEmpleado: widget.obtenerRolDeEmpleado,
                          )).toList(),
                        ),
                    ],
                    
                    // Botón para cargar más
                    if (widget.hasMorePages && !widget.isLoading)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: widget.onLoadMore,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D2D2D),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Cargar más'),
                          ),
                        ),
                      ),
                      
                    // Indicador de carga para paginación
                    if (widget.isLoading && widget.empleados.isNotEmpty)
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