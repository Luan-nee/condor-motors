import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../models/empleado.model.dart';
import '../../api/main.api.dart' show ApiException;
import '../../main.dart' show api;
import 'utils/empleados_utils.dart';
import 'widgets/empleado/empleado_detalles_dialog.dart';
import 'widgets/empleado/empleado_form.dart';
import 'widgets/empleado/empleados_table.dart';

class ColaboradoresAdminScreen extends StatefulWidget {
  const ColaboradoresAdminScreen({super.key});

  @override
  State<ColaboradoresAdminScreen> createState() =>
      _ColaboradoresAdminScreenState();
}

class _ColaboradoresAdminScreenState extends State<ColaboradoresAdminScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  List<Empleado> _empleados = [];
  Map<String, String> _nombresSucursales = {};

  // Lista de roles disponibles
  final List<String> _roles = ['Administrador', 'Vendedor', 'Computadora'];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      debugPrint('Cargando datos de colaboradores...');
      final futureSucursales = _cargarSucursales();
      final futureEmpleados = api.empleados.getEmpleados(useCache: false);
      final results = await Future.wait([futureSucursales, futureEmpleados]);
      final empleadosData = results[1] as List<dynamic>;
      final List<Empleado> empleados = [];
      for (var item in empleadosData) {
        try {
          final empleado = item;
          empleados.add(empleado);
        } catch (e) {
          debugPrint('Error al procesar empleado: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _empleados = empleados;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar datos';
      });
    }
  }

  Future<Map<String, String>> _cargarSucursales() async {
    try {
      final sucursalesData = await api.sucursales.getSucursales();
      final Map<String, String> sucursales = {};

      for (var sucursal in sucursalesData) {
        final id = sucursal.id.toString();
        String nombre = sucursal.nombre;
        final bool esCentral = sucursal.sucursalCentral;

        // Agregar indicador de Central al nombre si corresponde
        if (esCentral) {
          nombre = '$nombre (Central)';
        }

        if (id.isNotEmpty) {
          sucursales[id] = nombre;
        }
      }

      // Actualizar el estado si estamos montados
      if (mounted) {
        setState(() {
          _nombresSucursales = sucursales;
        });
      }

      return sucursales;
    } catch (e) {
      debugPrint('Error al cargar sucursales: $e');
      return {}; // Devolver mapa vacío en caso de error
    }
  }

  Future<void> _eliminarEmpleado(Empleado empleado) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '¿Eliminar colaborador?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Está seguro que desea eliminar a ${empleado.nombre} ${empleado.apellidos}? Esta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
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

    if (confirmacion != true) return;

    try {
      await api.empleados.deleteEmpleado(empleado.id);

      if (!mounted) return;

      // Actualizar localmente
      setState(() {
        _empleados.removeWhere((e) => e.id == empleado.id);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Colaborador eliminado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String mensajeError = 'Error al eliminar colaborador';
      if (e is ApiException) {
        mensajeError = '$mensajeError: ${e.message}';
      } else {
        mensajeError = '$mensajeError: $e';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarFormularioEmpleado([Empleado? empleado]) {
    // Importar el widget EmpleadoForm
    showDialog(
      context: context,
      builder: (context) => EmpleadoForm(
        empleado: empleado,
        sucursales: _nombresSucursales,
        roles: _roles,
        onSave: (empleadoData) => _guardarEmpleado(empleado, empleadoData),
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _guardarEmpleado(
      Empleado? empleadoExistente, Map<String, dynamic> empleadoData) async {
    try {
      if (empleadoExistente != null) {
        // Actualizar empleado existente
        await api.empleados.updateEmpleado(empleadoExistente.id, empleadoData);

        if (!mounted) return;

        _mostrarMensajeExito('Colaborador actualizado correctamente');
      } else {
        // Crear nuevo empleado
        await api.empleados.createEmpleado(empleadoData);

        if (!mounted) return;

        _mostrarMensajeExito('Colaborador creado correctamente');
      }

      // Cerrar el diálogo y recargar datos
      if (!mounted) return;
      Navigator.pop(context);
      await _cargarDatos();
    } catch (e) {
      if (!mounted) return;

      String mensajeError = 'Error al guardar colaborador';
      if (e is ApiException) {
        mensajeError = '$mensajeError: ${e.message}';
      } else {
        mensajeError = '$mensajeError: $e';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarMensajeExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _mostrarDetallesEmpleado(Empleado empleado) {
    showDialog(
      context: context,
      builder: (context) => EmpleadoDetallesDialog(
        empleado: empleado,
        nombresSucursales: _nombresSucursales,
        obtenerRolDeEmpleado: EmpleadosUtils.obtenerRolDeEmpleado,
        onEdit: _mostrarFormularioEmpleado,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.users,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                  children: [
                    ElevatedButton.icon(
                      icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const FaIcon(
                            FontAwesomeIcons.arrowsRotate,
                            size: 16,
                            color: Colors.white
                          ),
                      label: Text(_isLoading ? 'Actualizando...' : 'Actualizar Datos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0075FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      onPressed: _isLoading ? null : _cargarDatos,
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
                      onPressed: _isLoading
                          ? null
                          : () => _mostrarFormularioEmpleado(),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),

            // Tabla de empleados
            Expanded(
              child: EmpleadosTable(
                empleados: _empleados,
                nombresSucursales: _nombresSucursales,
                obtenerRolDeEmpleado: EmpleadosUtils.obtenerRolDeEmpleado,
                onEdit: _mostrarFormularioEmpleado,
                onDelete: _eliminarEmpleado,
                onViewDetails: _mostrarDetallesEmpleado,
                isLoading: _isLoading,
                hasMorePages: false,
                onLoadMore: () {},
                errorMessage: _errorMessage,
                onRetry: _cargarDatos,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
