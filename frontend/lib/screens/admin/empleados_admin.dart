import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/providers/admin/empleados.admin.riverpod.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleado_cuenta_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleado_detalles_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleado_form.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleados_table.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/widgets/common/error_banner.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ColaboradoresAdminScreen extends ConsumerStatefulWidget {
  const ColaboradoresAdminScreen({super.key});

  @override
  ConsumerState<ColaboradoresAdminScreen> createState() => _ColaboradoresAdminScreenState();
}

class _ColaboradoresAdminScreenState extends ConsumerState<ColaboradoresAdminScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(empleadosAdminProvider);
    final notifier = ref.read(empleadosAdminProvider.notifier);

    final data = state.value;
    final empleados = data?.empleados ?? const [];
    final nombresSucursales = data?.nombresSucursales ?? const {};
    final rolesCuentas = data?.rolesCuentas ?? const [];

    return Scaffold(
      backgroundColor: AppTheme.darkSurface,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    FaIcon(FontAwesomeIcons.users, color: Colors.white, size: 24),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'COLABORADORES',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'gestión de empleados',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    SizedBox(
                      height: 46,
                      width: 46,
                      child: Tooltip(
                        message: state.isLoading
                            ? 'Recargando...'
                            : 'Recargar colaboradores',
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                            ),
                            elevation: 0,
                          ),
                          onPressed: state.isLoading ? null : notifier.cargarDatos,
                          child: state.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        icon: const FaIcon(FontAwesomeIcons.plus, size: 14, color: Colors.white),
                        label: const Text(
                          'Nuevo',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _mostrarFormularioEmpleado(nombresSucursales, notifier),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (state.hasError && !state.isLoading)
              ErrorBanner(
                message: state.error.toString(),
                onClose: notifier.limpiarError,
              ),
            Expanded(
                    child: EmpleadosTable(
                        empleados: empleados,
                        nombresSucursales: nombresSucursales,
                        rolesCuentas: rolesCuentas,
                        obtenerRolDeEmpleado: _obtenerRolDeEmpleado,
                        onEmpleadoEdited: (e) => _mostrarFormularioEmpleado(nombresSucursales, notifier, e),
                        onEmpleadoDeleted: (e) => _eliminarEmpleado(e, notifier),
                        onEmpleadoDetails: (e) => _mostrarDetallesEmpleado(nombresSucursales, notifier, e),
                        onEditCuenta: (e) => _mostrarDialogoCuentaEmpleado(rolesCuentas, notifier, e),
                        onRefresh: notifier.cargarDatos,
                        isLoading: state.isLoading,
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminarEmpleado(Empleado empleado, EmpleadosAdmin notifier) async {
    final bool? confirmacion = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text('¿Eliminar colaborador?', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Está seguro que desea eliminar a ${empleado.nombre} ${empleado.apellidos}? Esta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      try {
        await notifier.eliminarEmpleado(empleado.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Colaborador eliminado'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _mostrarFormularioEmpleado(Map<String, String> sucursales, EmpleadosAdmin notifier, [Empleado? empleado]) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => EmpleadoForm(
        empleado: empleado,
        sucursales: sucursales,
        onSaved: (Empleado empleadoGuardado) async {
          Navigator.pop(dialogContext);
          await notifier.cargarDatos();
        },
      ),
    );
  }

  String _obtenerRolDeEmpleado(Empleado empleado) {
    if (empleado.id == '13') {
      return 'Administrador';
    }
    if (empleado.sucursalId == '7') {
      return 'Administrador';
    }
    final int idNum = int.tryParse(empleado.id) ?? 0;
    return idNum % 2 == 0 ? 'Vendedor' : 'Computadora';
  }

  void _mostrarDetallesEmpleado(Map<String, String> sucursales, EmpleadosAdmin notifier, Empleado empleado) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => EmpleadoDetallesDialog(
        empleado: empleado,
        nombresSucursales: sucursales,
        obtenerRolDeEmpleado: _obtenerRolDeEmpleado,
        onEdit: (e) => _mostrarFormularioEmpleado(sucursales, notifier, e),
      ),
    );
  }

  void _mostrarDialogoCuentaEmpleado(List<Map<String, dynamic>> roles, EmpleadosAdmin notifier, Empleado empleado) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => EmpleadoCuentaDialog(
        empleado: empleado,
        roles: roles,
        esNuevaCuenta: empleado.cuentaEmpleadoUsuario == null,
        onRefresh: notifier.cargarDatos,
      ),
    );
  }
}
