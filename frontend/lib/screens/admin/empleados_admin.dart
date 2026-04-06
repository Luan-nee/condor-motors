import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/providers/admin/empleados.admin.riverpod.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleado_cuenta_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleado_detalles_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleado_form.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleados_table.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
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
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'gestión de empleados',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    ElevatedButton.icon(
                      icon: state.isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16, color: Colors.white),
                      label: Text(state.isLoading ? 'Recargando...' : 'Recargar', style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D2D2D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: state.isLoading ? null : notifier.cargarDatos,
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const FaIcon(FontAwesomeIcons.plus, size: 16, color: Colors.white),
                      label: const Text('Agregar', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31E24),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () => _mostrarFormularioEmpleado(state.nombresSucursales, notifier),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty)
              _buildErrorBanner(state.errorMessage!, notifier),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFE31E24)))
                  : EmpleadosTable(
                      empleados: state.empleados,
                      nombresSucursales: state.nombresSucursales,
                      rolesCuentas: state.rolesCuentas,
                      obtenerRolDeEmpleado: _obtenerRolDeEmpleado,
                      onEmpleadoEdited: (e) => _mostrarFormularioEmpleado(state.nombresSucursales, notifier, e),
                      onEmpleadoDeleted: (e) => _eliminarEmpleado(e, notifier),
                      onEmpleadoDetails: (e) => _mostrarDetallesEmpleado(state.nombresSucursales, notifier, e),
                      onEditCuenta: (e) => _mostrarDialogoCuentaEmpleado(state.rolesCuentas, notifier, e),
                      onRefresh: notifier.cargarDatos,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message, EmpleadosAdmin notifier) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.red))),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: notifier.limpiarError,
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarEmpleado(Empleado empleado, EmpleadosAdmin notifier) async {
    final bool? confirmacion = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE31E24), foregroundColor: Colors.white),
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
