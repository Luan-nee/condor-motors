import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../models/empleado.model.dart';
import '../../api/main.api.dart' show ApiException;
import '../../main.dart' show api;
import 'utils/empleados_utils.dart';
import 'widgets/empleado_detalles_dialog.dart';
import 'widgets/empleado_form.dart';
import 'widgets/empleados_table.dart';

class ColaboradoresAdminScreen extends StatefulWidget {
  const ColaboradoresAdminScreen({super.key});

  @override
  State<ColaboradoresAdminScreen> createState() => _ColaboradoresAdminScreenState();
}

class _ColaboradoresAdminScreenState extends State<ColaboradoresAdminScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  List<Empleado> _empleados = [];
  Map<String, String> _nombresSucursales = {};
  
  // Ya no necesitamos estos parámetros de paginación
  // int _currentPage = 1;
  // final int _pageSize = 10;
  
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
      // Cargar sucursales primero para mostrar nombres en lugar de IDs
      // Esta llamada todavía es necesaria para el formulario de creación/edición
      await _cargarSucursales();
      
      // Cargar todos los empleados de una vez, sin paginación
      final empleadosData = await api.empleados.getEmpleados();
      
      final List<Empleado> empleados = [];
      for (var item in empleadosData) {
        try {
          // Los datos ya vienen como objetos Empleado, no necesitamos convertirlos
          final empleado = item;
          
          // Si el empleado tiene información de sucursal, actualizamos el mapa de nombres
          if (empleado.sucursalId != null && empleado.sucursalNombre != null) {
            _nombresSucursales[empleado.sucursalId!] = empleado.sucursalNombre!;
            if (empleado.sucursalCentral) {
              _nombresSucursales[empleado.sucursalId!] = '${empleado.sucursalNombre!} (Central)';
            }
          }
          
          empleados.add(empleado);
        } catch (e) {
          debugPrint('Error al convertir empleado: $e');
        }
      }
      
      // Ya no necesitamos verificar si hay más páginas
      
      if (!mounted) return;
      setState(() {
        _empleados = empleados;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar datos: $e';
      });
      
      // Manejar errores de autenticación
      if (e is ApiException && e.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión expirada. Por favor, inicie sesión nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
        await Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }
  
  Future<void> _cargarSucursales() async {
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
      
      setState(() {
        _nombresSucursales = sucursales;
      });
    } catch (e) {
      debugPrint('Error al cargar sucursales: $e');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar colaborador: $e'),
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
  
  Future<void> _guardarEmpleado(Empleado? empleadoExistente, Map<String, dynamic> empleadoData) async {
    try {
      if (empleadoExistente != null) {
        // Actualizar empleado existente
        await api.empleados.updateEmpleado(empleadoExistente.id, empleadoData);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Colaborador actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Crear nuevo empleado
        await api.empleados.createEmpleado(empleadoData);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Colaborador creado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Cerrar el diálogo y recargar datos
      if (!mounted) return;
      Navigator.pop(context);
      await _cargarDatos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar colaborador: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                  onPressed: _isLoading ? null : () => _mostrarFormularioEmpleado(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Tabla de empleados - modificada para no usar paginación
            Expanded(
              child: EmpleadosTable(
                empleados: _empleados,
                nombresSucursales: _nombresSucursales,
                obtenerRolDeEmpleado: EmpleadosUtils.obtenerRolDeEmpleado,
                onEdit: _mostrarFormularioEmpleado,
                onDelete: _eliminarEmpleado,
                onViewDetails: _mostrarDetallesEmpleado,
                isLoading: _isLoading,
                hasMorePages: false, // Siempre false ya que cargamos todo de una vez
                onLoadMore: () {}, // Función vacía, nunca se ejecutará porque hasMorePages es false
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