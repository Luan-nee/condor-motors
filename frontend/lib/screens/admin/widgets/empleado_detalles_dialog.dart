import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../api/protected/empleados.api.dart';
import '../../../main.dart' show api;
import 'empleado_horario_dialog.dart';
import 'empleado_cuenta_dialog.dart';
import 'empleados_utils.dart';

class EmpleadoDetallesDialog extends StatefulWidget {
  final Empleado empleado;
  final Map<String, String> nombresSucursales;
  final String Function(Empleado) obtenerRolDeEmpleado;
  final Function(Empleado) onEdit;

  const EmpleadoDetallesDialog({
    Key? key,
    required this.empleado,
    required this.nombresSucursales,
    required this.obtenerRolDeEmpleado,
    required this.onEdit,
  }) : super(key: key);

  @override
  State<EmpleadoDetallesDialog> createState() => _EmpleadoDetallesDialogState();
}

class _EmpleadoDetallesDialogState extends State<EmpleadoDetallesDialog> {
  bool _isLoadingCuenta = false;
  String? _usuarioEmpleado;
  String? _rolCuentaEmpleado;
  
  @override
  void initState() {
    super.initState();
    _cargarInformacionCuenta();
  }
  
  Future<void> _cargarInformacionCuenta() async {
    setState(() => _isLoadingCuenta = true);
    
    try {
      final cuentaInfo = await api.empleados.getCuentaByEmpleadoId(widget.empleado.id);
      
      if (cuentaInfo != null) {
        setState(() {
          _usuarioEmpleado = cuentaInfo['usuario']?.toString();
          
          // Intentar obtener el nombre del rol
          final rolId = cuentaInfo['rolCuentaEmpleadoId'];
          if (rolId != null) {
            _obtenerNombreRol(rolId);
          }
        });
      }
    } catch (e) {
      // Manejar específicamente errores de autenticación
      if (e.toString().contains('401') || 
          e.toString().contains('Sesión expirada') || 
          e.toString().contains('No autorizado')) {
        debugPrint('Error de autenticación al cargar información de cuenta: $e');
        // No mostrar error en la UI para este componente
      } else {
        debugPrint('Error al cargar información de cuenta: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingCuenta = false);
      }
    }
  }
  
  Future<void> _obtenerNombreRol(int rolId) async {
    try {
      final roles = await api.empleados.getRolesCuentas();
      final rol = roles.firstWhere(
        (r) => r['id'] == rolId,
        orElse: () => <String, dynamic>{},
      );
      
      if (mounted) {
        setState(() {
          _rolCuentaEmpleado = rol['nombre'] ?? rol['codigo'] ?? 'Rol #$rolId';
        });
      }
    } catch (e) {
      // No actualizar el estado si hay error
      debugPrint('Error al obtener nombre de rol: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final esCentral = EmpleadosUtils.esSucursalCentral(widget.empleado.sucursalId, widget.nombresSucursales);
    final nombreSucursal = EmpleadosUtils.getNombreSucursal(widget.empleado.sucursalId, widget.nombresSucursales);
    final rol = widget.obtenerRolDeEmpleado(widget.empleado);
    
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con foto y nombre
              Row(
                children: [
                  // Foto o avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: widget.empleado.ubicacionFoto != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.empleado.ubicacionFoto!,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const FaIcon(
                                FontAwesomeIcons.user,
                                color: Color(0xFFE31E24),
                                size: 28,
                              ),
                            ),
                          )
                        : const FaIcon(
                            FontAwesomeIcons.user,
                            color: Color(0xFFE31E24),
                            size: 28,
                          ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Nombre y rol
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.empleado.nombre} ${widget.empleado.apellidos}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2D2D),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFE31E24).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(
                                EmpleadosUtils.getRolIcon(rol),
                                color: const Color(0xFFE31E24),
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                rol,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_usuarioEmpleado != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.userTag,
                                color: Colors.white54,
                                size: 12,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '@$_usuarioEmpleado',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Información personal
              const Text(
                'INFORMACIÓN PERSONAL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE31E24),
                ),
              ),
              const SizedBox(height: 12),
              
              // Dos columnas para la información
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna izquierda
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoItem('DNI', widget.empleado.dni ?? 'No especificado'),
                        const SizedBox(height: 12),
                        _buildInfoItem('Edad', widget.empleado.edad?.toString() ?? 'No especificada'),
                        const SizedBox(height: 12),
                        _buildInfoItem('Celular', widget.empleado.celular ?? 'No especificado'),
                      ],
                    ),
                  ),
                  
                  // Columna derecha
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoItem('Estado', widget.empleado.activo ? 'Activo' : 'Inactivo'),
                        const SizedBox(height: 12),
                        _buildInfoItem('Fecha Registro', widget.empleado.fechaRegistro ?? 'No especificada'),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Información de sucursal
              const Text(
                'SUCURSAL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE31E24),
                ),
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: esCentral 
                        ? const Color.fromARGB(255, 95, 208, 243) 
                        : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: FaIcon(
                          esCentral
                              ? FontAwesomeIcons.building
                              : FontAwesomeIcons.store,
                          color: esCentral
                              ? const Color.fromARGB(255, 95, 208, 243)
                              : Colors.white54,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombreSucursal,
                            style: TextStyle(
                              color: esCentral
                                  ? const Color.fromARGB(255, 95, 208, 243)
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (esCentral)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Sucursal Central',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Fecha Contratación: ${widget.empleado.fechaContratacion ?? 'No especificada'}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Información laboral
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'INFORMACIÓN LABORAL',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE31E24),
                    ),
                  ),
                  // Botones para ver horario y gestionar cuenta
                  Row(
                    children: [
                      // Botón para ver horario
                      TextButton.icon(
                        icon: const FaIcon(
                          FontAwesomeIcons.clock,
                          size: 14,
                          color: Colors.white70,
                        ),
                        label: const Text(
                          'Ver horario',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () => _mostrarHorarioEmpleado(context),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF2D2D2D),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botón para gestionar cuenta
                      TextButton.icon(
                        icon: const FaIcon(
                          FontAwesomeIcons.userGear,
                          size: 14,
                          color: Colors.white70,
                        ),
                        label: const Text(
                          'Gestionar cuenta',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () => _gestionarCuentaEmpleado(context),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF2D2D2D),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Información de cuenta (si existe)
              if (_isLoadingCuenta) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
                      ),
                    ),
                  ),
                ),
              ] else if (_usuarioEmpleado != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE31E24).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.userShield,
                            color: Color(0xFFE31E24),
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'INFORMACIÓN DE CUENTA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE31E24),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem('Usuario', '@$_usuarioEmpleado'),
                          ),
                          if (_rolCuentaEmpleado != null)
                            Expanded(
                              child: _buildInfoItem('Rol de cuenta', _rolCuentaEmpleado!),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna izquierda
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoItem('Sueldo', widget.empleado.sueldo != null 
                          ? 'S/ ${widget.empleado.sueldo!.toStringAsFixed(2)}' 
                          : 'No especificado'),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const FaIcon(
                      FontAwesomeIcons.arrowLeft,
                      size: 14,
                      color: Colors.white54,
                    ),
                    label: const Text('Volver'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white54,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const FaIcon(
                      FontAwesomeIcons.penToSquare,
                      size: 14,
                    ),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      // Cerrar el diálogo de detalles
                      Navigator.pop(context);
                      // Abrir el formulario de edición
                      widget.onEdit(widget.empleado);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarHorarioEmpleado(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EmpleadoHorarioDialog(empleado: widget.empleado),
    );
  }

  Future<void> _gestionarCuentaEmpleado(BuildContext context) async {
    // Obtener información de la cuenta del empleado
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Dialog(
          backgroundColor: Color(0xFF1A1A1A),
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Cargando información de cuenta...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );

      // Obtener roles disponibles
      final roles = await api.empleados.getRolesCuentas();
      
      // Obtener información de la cuenta (si existe)
      Map<String, dynamic>? cuentaInfo;
      String? cuentaId;
      String? usuarioActual;
      int? rolActualId;
      
      try {
        cuentaInfo = await api.empleados.getCuentaByEmpleadoId(widget.empleado.id);
        if (cuentaInfo != null) {
          cuentaId = cuentaInfo['id']?.toString();
          usuarioActual = cuentaInfo['usuario']?.toString();
          rolActualId = cuentaInfo['rolCuentaEmpleadoId'];
          debugPrint('Cuenta encontrada: ID=$cuentaId, Usuario=$usuarioActual, RolID=$rolActualId');
        }
      } catch (e) {
        // Manejar específicamente errores de autenticación
        if (e.toString().contains('401') || 
            e.toString().contains('Sesión expirada') || 
            e.toString().contains('No autorizado')) {
          debugPrint('Error de autenticación al obtener cuenta: $e');
        } else {
          debugPrint('Error al obtener cuenta: $e');
        }
        // La cuenta no existe o hubo un error, se creará una nueva si es posible
      }
      
      if (!context.mounted) return;
      
      // Cerrar diálogo de carga
      Navigator.pop(context);
      
      // Mostrar diálogo de gestión de cuenta
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => EmpleadoCuentaDialog(
          empleadoId: widget.empleado.id,
          empleadoNombre: '${widget.empleado.nombre} ${widget.empleado.apellidos}',
          cuentaId: cuentaId,
          usuarioActual: usuarioActual,
          rolActualId: rolActualId,
          roles: roles,
        ),
      );
      
      // Si se realizó algún cambio, actualizar la información
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta actualizada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recargar información de cuenta
        _cargarInformacionCuenta();
      }
    } catch (e) {
      if (!context.mounted) return;
      
      // Cerrar diálogo de carga si está abierto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Determinar el tipo de error para mostrar un mensaje apropiado
      String errorMessage;
      if (e.toString().contains('401') || 
          e.toString().contains('Sesión expirada') || 
          e.toString().contains('No autorizado')) {
        errorMessage = 'Sesión expirada. Por favor, inicie sesión nuevamente.';
      } else {
        errorMessage = 'Error al gestionar cuenta: $e';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          action: e.toString().contains('401') ? SnackBarAction(
            label: 'Iniciar sesión',
            textColor: Colors.white,
            onPressed: () {
              // TODO: Implementar navegación a la pantalla de login
              // Navigator.of(context).pushReplacementNamed('/login');
            },
          ) : null,
        ),
      );
    }
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
} 