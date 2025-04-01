import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/providers/admin/index.admin.provider.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleado_detalles_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleado_form.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleados_table.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class ColaboradoresAdminScreen extends StatefulWidget {
  const ColaboradoresAdminScreen({super.key});

  @override
  State<ColaboradoresAdminScreen> createState() =>
      _ColaboradoresAdminScreenState();
}

class _ColaboradoresAdminScreenState extends State<ColaboradoresAdminScreen> {
  late EmpleadoProvider _empleadoProvider;

  @override
  void initState() {
    super.initState();
    // Inicialización y primera carga de datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _empleadoProvider = Provider.of<EmpleadoProvider>(context, listen: false);
      _empleadoProvider.cargarDatos();
    });
  }

  Future<void> _eliminarEmpleado(Empleado empleado) async {
    final bool? confirmacion = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '¿Eliminar colaborador?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Está seguro que desea eliminar a ${empleado.nombre} ${empleado.apellidos}? Esta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31E24),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmacion != true) {
      return;
    }

    final bool exito = await _empleadoProvider.eliminarEmpleado(empleado);

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Colaborador eliminado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _mostrarFormularioEmpleado([Empleado? empleado]) {
    showDialog(
      context: context,
      builder: (BuildContext context) => EmpleadoForm(
        empleado: empleado,
        sucursales: _empleadoProvider.nombresSucursales,
        roles: _empleadoProvider.roles,
        onSave: (Map<String, dynamic> empleadoData) =>
            _guardarEmpleado(empleado, empleadoData),
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _guardarEmpleado(
      Empleado? empleadoExistente, Map<String, dynamic> empleadoData) async {
    final bool exito = await _empleadoProvider.guardarEmpleado(
        empleadoExistente, empleadoData);

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(empleadoExistente == null
              ? 'Colaborador creado correctamente'
              : 'Colaborador actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _mostrarDetallesEmpleado(Empleado empleado) {
    showDialog(
      context: context,
      builder: (BuildContext context) => EmpleadoDetallesDialog(
        empleado: empleado,
        nombresSucursales: _empleadoProvider.nombresSucursales,
        obtenerRolDeEmpleado: _empleadoProvider.obtenerRolDeEmpleado,
        onEdit: _mostrarFormularioEmpleado,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmpleadoProvider>(
      builder: (context, empleadoProvider, _) {
        _empleadoProvider = empleadoProvider;
        final List<Empleado> empleados = empleadoProvider.empleados;
        final bool isLoading = empleadoProvider.isLoading;
        final String errorMessage = empleadoProvider.errorMessage;
        final Map<String, String> nombresSucursales =
            empleadoProvider.nombresSucursales;

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const FaIcon(
                          FontAwesomeIcons.users,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'COLABORADORES',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'gestión de personal',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        ElevatedButton.icon(
                          icon: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const FaIcon(FontAwesomeIcons.arrowsRotate,
                                  size: 16, color: Colors.white),
                          label: Text(isLoading
                              ? 'Actualizando...'
                              : 'Actualizar Datos'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0075FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () => empleadoProvider.cargarDatos(),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const FaIcon(FontAwesomeIcons.plus,
                              size: 16, color: Colors.white),
                          label: const Text('Nuevo Colaborador'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE31E24),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () => _mostrarFormularioEmpleado(),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 24),

                // Mensaje de error si existe
                if (errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            empleadoProvider.clearError();
                          },
                        ),
                      ],
                    ),
                  ),

                // Tabla de empleados
                Expanded(
                  child: EmpleadosTable(
                    empleados: empleados,
                    nombresSucursales: nombresSucursales,
                    obtenerRolDeEmpleado: empleadoProvider.obtenerRolDeEmpleado,
                    onEdit: _mostrarFormularioEmpleado,
                    onDelete: _eliminarEmpleado,
                    onViewDetails: _mostrarDetallesEmpleado,
                    isLoading: isLoading,
                    hasMorePages: false,
                    onLoadMore: () {},
                    errorMessage: errorMessage,
                    onRetry: () => empleadoProvider.cargarDatos(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
