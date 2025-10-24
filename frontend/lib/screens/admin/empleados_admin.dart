import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleado_cuenta_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleado_detalles_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleado_form.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleados_table.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ColaboradoresAdminScreen extends StatefulWidget {
  const ColaboradoresAdminScreen({super.key});

  @override
  State<ColaboradoresAdminScreen> createState() =>
      _ColaboradoresAdminScreenState();
}

class _ColaboradoresAdminScreenState extends State<ColaboradoresAdminScreen> {
  // Estados locales
  bool _isLoading = false;
  String _errorMessage = '';
  List<Empleado> _empleados = <Empleado>[];
  Map<String, String> _nombresSucursales = <String, String>{};
  List<Map<String, dynamic>> _rolesCuentas = <Map<String, dynamic>>[];

  // Repositorio
  late final EmpleadoRepository _empleadoRepository;

  @override
  void initState() {
    super.initState();
    _empleadoRepository = EmpleadoRepository.instance;
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Cargar datos en paralelo
      final Future<Map<String, String>> futureSucursales = _cargarSucursales();
      final Future<EmpleadosPaginados> futureEmpleados =
          _empleadoRepository.getEmpleados(useCache: false);
      final Future<List<Map<String, dynamic>>> futureRolesCuentas =
          _cargarRolesCuentas();

      final List<Object> results = await Future.wait(<Future<Object>>[
        futureSucursales,
        futureEmpleados,
        futureRolesCuentas,
      ]);

      if (mounted) {
        setState(() {
          _empleados = (results[1] as EmpleadosPaginados).empleados;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar datos: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, String>> _cargarSucursales() async {
    try {
      final sucursales = await _empleadoRepository.getNombresSucursales();
      if (mounted) {
        setState(() {
          _nombresSucursales = sucursales;
        });
      }
      return sucursales;
    } catch (e) {
      debugPrint('Error al cargar sucursales: $e');
      return <String, String>{};
    }
  }

  Future<List<Map<String, dynamic>>> _cargarRolesCuentas() async {
    try {
      final roles = await _empleadoRepository.getRolesCuentas();
      if (mounted) {
        setState(() {
          _rolesCuentas = roles;
        });
      }
      return roles;
    } catch (e) {
      debugPrint('Error al cargar roles: $e');
      return <Map<String, dynamic>>[];
    }
  }

  void _mostrarMensaje(String mensaje, bool esError) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _eliminarEmpleado(Empleado empleado) async {
    if (!mounted) {
      return;
    }

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

    if (confirmacion != true || !mounted) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _empleadoRepository.deleteEmpleado(empleado.id);

      if (mounted) {
        setState(() {
          _empleados.removeWhere((e) => e.id == empleado.id);
          _isLoading = false;
        });
        _mostrarMensaje('Colaborador eliminado correctamente', false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarMensaje('Error al eliminar colaborador: $e', true);
      }
    }
  }

  void _mostrarFormularioEmpleado([Empleado? empleado]) {
    if (!mounted) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => EmpleadoForm(
        empleado: empleado,
        sucursales: _nombresSucursales,
        onSaved: (Empleado empleadoGuardado) async {
          Navigator.pop(context);
          await _cargarDatos(); // Recargar datos después de guardar
        },
      ),
    );
  }

  String _obtenerRolDeEmpleado(Empleado empleado) {
    // Lógica simplificada para obtener rol
    if (empleado.id == '13') {
      return 'Administrador';
    }
    if (empleado.sucursalId == '7') {
      return 'Administrador';
    }

    final int idNum = int.tryParse(empleado.id) ?? 0;
    return idNum % 2 == 0 ? 'Vendedor' : 'Computadora';
  }

  void _mostrarDetallesEmpleado(Empleado empleado) {
    if (!mounted) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => EmpleadoDetallesDialog(
        empleado: empleado,
        nombresSucursales: _nombresSucursales,
        obtenerRolDeEmpleado: _obtenerRolDeEmpleado,
        onEdit: _mostrarFormularioEmpleado,
      ),
    );
  }

  void _mostrarDialogoCuentaEmpleado(Empleado empleado) {
    if (!mounted) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => EmpleadoCuentaDialog(
        empleado: empleado,
        roles: _rolesCuentas,
        esNuevaCuenta: empleado.cuentaEmpleadoUsuario == null,
        onRefresh:
            _cargarDatos, // Refrescar la lista después de crear/actualizar cuenta
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    FaIcon(
                      FontAwesomeIcons.users,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'COLABORADORES',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'gestión de empleados',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    // Botón de refrescar
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
                              color: Colors.white,
                            ),
                      label: Text(
                        _isLoading ? 'Recargando...' : 'Recargar',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D2D2D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _isLoading ? null : _cargarDatos,
                    ),
                    const SizedBox(width: 16),
                    // Botón de agregar
                    ElevatedButton.icon(
                      icon: const FaIcon(
                        FontAwesomeIcons.plus,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Agregar',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31E24),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _mostrarFormularioEmpleado,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Contenido principal
            if (_errorMessage.isNotEmpty)
              Container(
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
                    Expanded(
                        child: Text(_errorMessage,
                            style: const TextStyle(color: Colors.red))),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => setState(() => _errorMessage = ''),
                    ),
                  ],
                ),
              ),

            // Tabla de empleados
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE31E24),
                      ),
                    )
                  : EmpleadosTable(
                      empleados: _empleados,
                      nombresSucursales: _nombresSucursales,
                      rolesCuentas: _rolesCuentas,
                      obtenerRolDeEmpleado: _obtenerRolDeEmpleado,
                      onEmpleadoEdited: _mostrarFormularioEmpleado,
                      onEmpleadoDeleted: _eliminarEmpleado,
                      onEmpleadoDetails: _mostrarDetallesEmpleado,
                      onEditCuenta: _mostrarDialogoCuentaEmpleado,
                      onRefresh: _cargarDatos,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
