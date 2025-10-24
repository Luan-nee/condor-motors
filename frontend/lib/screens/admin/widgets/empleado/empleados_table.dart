import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleado_list.dart';
import 'package:condorsmotors/utils/empleados_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class EmpleadosTable extends StatefulWidget {
  final List<Empleado> empleados;
  final Map<String, String> nombresSucursales;
  final List<Map<String, dynamic>>? rolesCuentas;
  final String Function(Empleado) obtenerRolDeEmpleado;
  final Function(Empleado) onEmpleadoEdited;
  final Function(Empleado) onEmpleadoDeleted;
  final Function(Empleado) onEmpleadoDetails;
  final Function(Empleado)? onEditCuenta;
  final VoidCallback onRefresh;

  const EmpleadosTable({
    super.key,
    required this.empleados,
    required this.nombresSucursales,
    this.rolesCuentas,
    required this.obtenerRolDeEmpleado,
    required this.onEmpleadoEdited,
    required this.onEmpleadoDeleted,
    required this.onEmpleadoDetails,
    this.onEditCuenta,
    required this.onRefresh,
  });

  @override
  State<EmpleadosTable> createState() => _EmpleadosTableState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Empleado>('empleados', empleados))
      ..add(DiagnosticsProperty<Map<String, String>>(
          'nombresSucursales', nombresSucursales))
      ..add(ObjectFlagProperty<Function(Empleado p1)>.has(
          'onEmpleadoEdited', onEmpleadoEdited))
      ..add(ObjectFlagProperty<Function(Empleado p1)>.has(
          'onEmpleadoDeleted', onEmpleadoDeleted))
      ..add(ObjectFlagProperty<Function(Empleado p1)>.has(
          'onEmpleadoDetails', onEmpleadoDetails))
      ..add(ObjectFlagProperty<Function(Empleado p1)?>.has(
          'onEditCuenta', onEditCuenta))
      ..add(ObjectFlagProperty<VoidCallback>.has('onRefresh', onRefresh));
  }
}

class _EmpleadosTableState extends State<EmpleadosTable> {
  // Estado para controlar si la sección de inactivos está expandida

  @override
  Widget build(BuildContext context) {
    // Agrupar empleados por estado
    final Map<String, List<Empleado>> gruposEmpleados =
        EmpleadosUtils.agruparEmpleadosPorEstado(widget.empleados);
    final List<Empleado> empleadosActivos =
        gruposEmpleados['activos'] ?? <Empleado>[];
    final List<Empleado> empleadosInactivos =
        gruposEmpleados['inactivos'] ?? <Empleado>[];

    // Determinar si hay empleados inactivos para mostrar
    final bool hayEmpleadosInactivos = empleadosInactivos.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: widget.empleados.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'No hay colaboradores para mostrar',
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: widget.onRefresh,
                    child: const Text('Recargar datos'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Encabezado de la tabla
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF2D2D2D),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    child: const Row(
                      children: <Widget>[
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
                        // Sucursal (25% del ancho)
                        Expanded(
                          flex: 25,
                          child: Text(
                            'Sucursal',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Estado (10% del ancho)
                        Expanded(
                          flex: 10,
                          child: Text(
                            'Estado',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Acciones (5% del ancho)
                        SizedBox(
                          width: 32,
                          child: Center(
                            child: Text(
                              'Acciones',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Filas de colaboradores activos
                  ...empleadosActivos.map((empleado) => EmpleadoListItem(
                        empleado: empleado,
                        nombresSucursales: widget.nombresSucursales,
                        obtenerRolDeEmpleado: widget.obtenerRolDeEmpleado,
                        onEdit: widget.onEmpleadoEdited,
                        onDelete: widget.onEmpleadoDeleted,
                        onViewDetails: widget.onEmpleadoDetails,
                        onEditCuenta: widget.onEditCuenta,
                      )),
                  // Sección desplegable de colaboradores inactivos
                  if (hayEmpleadosInactivos) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          'Colaboradores Inactivos (${empleadosInactivos.length})',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                        iconColor: Colors.white54,
                        collapsedIconColor: Colors.white54,
                        backgroundColor: Colors.transparent,
                        collapsedBackgroundColor: Colors.transparent,
                        children: empleadosInactivos
                            .map((empleado) => EmpleadoListItem(
                                  empleado: empleado,
                                  nombresSucursales: widget.nombresSucursales,
                                  obtenerRolDeEmpleado:
                                      widget.obtenerRolDeEmpleado,
                                  onEdit: widget.onEmpleadoEdited,
                                  onDelete: widget.onEmpleadoDeleted,
                                  onViewDetails: widget.onEmpleadoDetails,
                                  onEditCuenta: widget.onEditCuenta,
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
