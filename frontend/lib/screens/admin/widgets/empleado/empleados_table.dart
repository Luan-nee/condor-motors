import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleado_list.dart';
import 'package:condorsmotors/theme/apptheme.dart';
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
  final bool isLoading;

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
    this.isLoading = false,
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
      ..add(ObjectFlagProperty<VoidCallback>.has('onRefresh', onRefresh))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading));
  }
}

class _EmpleadosTableState extends State<EmpleadosTable> {
  // Estado para controlar si la sección de inactivos está expandida
  bool _isInactivosExpanded = false;

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
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        ),
        child: (widget.empleados.isEmpty && !widget.isLoading)
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
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: widget.onRefresh,
                    child: const Text('Recargar datos'),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Encabezado de la tabla (siempre visible)
                Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceColor,
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
                      // Acciones (15% del ancho - Ajustado para coincidir con ListItem)
                      Expanded(
                        flex: 15,
                        child: Center(
                          child: Text(
                            'Acciones',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 2,
                  child: (widget.isLoading && widget.empleados.isNotEmpty)
                      ? const LinearProgressIndicator(
                          backgroundColor: Colors.white12,
                          color: AppTheme.primaryColor,
                          minHeight: 2,
                        )
                      : const SizedBox.shrink(),
                ),
                // Cuerpo de la tabla (scrollable y reactivo a la carga)
                Expanded(
                  child: (widget.isLoading && widget.empleados.isEmpty)
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : SingleChildScrollView(
                          child: AnimatedOpacity(
                            opacity: widget.isLoading ? 0.5 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                ...empleadosActivos.map((empleado) => EmpleadoListItem(
                                      empleado: empleado,
                                      nombresSucursales: widget.nombresSucursales,
                                      obtenerRolDeEmpleado: widget.obtenerRolDeEmpleado,
                                      onEdit: widget.onEmpleadoEdited,
                                      onDelete: widget.onEmpleadoDeleted,
                                      onViewDetails: widget.onEmpleadoDetails,
                                      onEditCuenta: widget.onEditCuenta,
                                      mostrarBordeInferior:
                                          empleado != empleadosActivos.last ||
                                              (hayEmpleadosInactivos &&
                                                  !_isInactivosExpanded),
                                    )),
                                // Sección desplegable de colaboradores inactivos
                                if (hayEmpleadosInactivos) ...[
                                  DecoratedBox(
                                    decoration: const BoxDecoration(
                                      color: AppTheme.surfaceColor,
                                    ),
                                    child: ExpansionTile(
                                      shape: const Border(),
                                      collapsedShape: const Border(),
                                      onExpansionChanged: (bool expanded) {
                                        setState(() {
                                          _isInactivosExpanded = expanded;
                                        });
                                      },
                                      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
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
                                          .map((empleado) => ColoredBox(
                                                color: AppTheme.darkSurface,
                                                child: EmpleadoListItem(
                                                  empleado: empleado,
                                                  nombresSucursales: widget.nombresSucursales,
                                                  obtenerRolDeEmpleado:
                                                      widget.obtenerRolDeEmpleado,
                                                  onEdit: widget.onEmpleadoEdited,
                                                  onDelete: widget.onEmpleadoDeleted,
                                                  onViewDetails: widget.onEmpleadoDetails,
                                                  onEditCuenta: widget.onEditCuenta,
                                                  mostrarBordeInferior:
                                                      empleado !=
                                                          empleadosInactivos
                                                              .last,
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
      ),
    );
  }
}
