import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/empleado.model.dart';
import '../utils/empleados_utils.dart';
import 'empleado_horario_dialog.dart';

/// Widget para mostrar los detalles de un empleado
/// 
/// Puede ser usado como un componente dentro de otros widgets o como un diálogo
class EmpleadoDetallesViewer extends StatefulWidget {
  final Empleado empleado;
  final Map<String, String> nombresSucursales;
  final String Function(Empleado) obtenerRolDeEmpleado;
  final Function(Empleado)? onEdit;
  final Function(BuildContext, Empleado)? onGestionarCuenta;
  final bool showActions;

  const EmpleadoDetallesViewer({
    super.key,
    required this.empleado,
    required this.nombresSucursales,
    required this.obtenerRolDeEmpleado,
    this.onEdit,
    this.onGestionarCuenta,
    this.showActions = true,
  });

  @override
  State<EmpleadoDetallesViewer> createState() => _EmpleadoDetallesViewerState();
}

class _EmpleadoDetallesViewerState extends State<EmpleadoDetallesViewer> {
  bool _isLoadingCuenta = false;
  String? _usuarioEmpleado;
  String? _rolCuentaEmpleado;
  bool _cuentaNoEncontrada = false;
  
  @override
  void initState() {
    super.initState();
    
    // Cargar información de cuenta del empleado al iniciar
    _cargarInformacionCuenta();
  }
  
  Future<void> _cargarInformacionCuenta() async {
    setState(() {
      _isLoadingCuenta = true;
      _cuentaNoEncontrada = false;
    });
    
    try {
      // Usar la función de utilidad para cargar la información de la cuenta
      final resultado = await EmpleadosUtils.cargarInformacionCuenta(widget.empleado);
      
      if (mounted) {
        setState(() {
          _usuarioEmpleado = resultado['usuarioActual'] as String?;
          _rolCuentaEmpleado = resultado['rolCuentaActual'] as String?;
          _cuentaNoEncontrada = resultado['cuentaNoEncontrada'] as bool;
        });
        
        // Agregar mensaje de depuración si no se encontró cuenta
        if (_cuentaNoEncontrada) {
          debugPrint('EmpleadoDetallesViewer: Empleado ${widget.empleado.id} no tiene cuenta asociada (detectado en resultado)');
        }
      }
    } catch (e) {
      // Si hay un error, verificar si es por ausencia de cuenta
      if (e.toString().contains('404') || 
          e.toString().contains('not found') || 
          e.toString().contains('no se encontró') || 
          e.toString().contains('no existe') ||
          e.toString().contains('no tiene cuenta') ||
          e.toString().contains('cuentasempleados/empleado')) {
        // Este es un caso esperado cuando el empleado no tiene cuenta
        if (mounted) {
          setState(() {
            _cuentaNoEncontrada = true;
            _usuarioEmpleado = null;
            _rolCuentaEmpleado = null;
          });
        }
        debugPrint('EmpleadoDetallesViewer: El empleado no tiene cuenta asociada (error capturado)');
      }
      // Manejar específicamente errores de autenticación genuinos (sesión expirada)
      else if (e.toString().contains('401') && (
          e.toString().contains('Sesión expirada') || 
          e.toString().contains('No autorizado') || 
          e.toString().contains('token'))) {
        debugPrint('Error de autenticación al cargar información de cuenta: $e');
        // No mostrar error en la UI para este componente
      } else {
        // Otros errores inesperados
        debugPrint('Error al cargar información de cuenta: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingCuenta = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usar los nuevos métodos para obtener información de sucursal
    final esCentral = EmpleadosUtils.esSucursalCentralEmpleado(widget.empleado, widget.nombresSucursales);
    final nombreSucursal = EmpleadosUtils.getNombreSucursalEmpleado(widget.empleado, widget.nombresSucursales);
    final rol = widget.obtenerRolDeEmpleado(widget.empleado);
    final nombreCompleto = EmpleadosUtils.getNombreCompleto(widget.empleado);
    
    return SingleChildScrollView(
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
                      nombreCompleto,
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
                    EmpleadosUtils.buildInfoItem('DNI', widget.empleado.dni ?? 'No especificado'),
                    const SizedBox(height: 12),
                    EmpleadosUtils.buildInfoItem('Celular', widget.empleado.celular ?? 'No especificado'),
                  ],
                ),
              ),
              
              // Columna derecha
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EmpleadosUtils.buildInfoItem('Estado', widget.empleado.activo ? 'Activo' : 'Inactivo'),
                    const SizedBox(height: 12),
                    EmpleadosUtils.buildInfoItem('Fecha Registro', EmpleadosUtils.formatearFecha(widget.empleado.fechaRegistro)),
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
                          'Fecha Contratación: ${EmpleadosUtils.formatearFecha(widget.empleado.fechaContratacion)}',
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
          
          // Información laboral y Gestión de cuenta
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
              // Botón para gestionar cuenta
              if (widget.showActions && widget.onGestionarCuenta != null)
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
                  onPressed: () => widget.onGestionarCuenta!(context, widget.empleado),
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
          const SizedBox(height: 12),
          
          // Información de cuenta (si existe)
          _cuentaNoEncontrada 
          ? _buildCrearCuentaContainer()
          : EmpleadosUtils.buildInfoCuentaContainer(
              isLoading: _isLoadingCuenta,
              usuarioActual: _usuarioEmpleado,
              rolCuentaActual: _rolCuentaEmpleado,
              onGestionarCuenta: widget.onGestionarCuenta == null 
                  ? null 
                  : () => widget.onGestionarCuenta!(context, widget.empleado),
            ),
          
          const SizedBox(height: 12),
          
          // Información de sueldo
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: EmpleadosUtils.buildInfoItem(
                  'Sueldo', 
                  EmpleadosUtils.formatearSueldo(widget.empleado.sueldo)
                ),
              ),
            ],
          ),
          
          // Horario laboral
          const SizedBox(height: 24),
          
          const Text(
            'HORARIO LABORAL',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE31E24),
            ),
          ),
          const SizedBox(height: 12),
          
          // Utilizar el EmpleadoHorarioViewer para mostrar el horario
          EmpleadoHorarioViewer(
            empleado: widget.empleado,
            showTitle: false,
            width: double.infinity,
          ),
          
          // Botones de acción al final
          if (widget.showActions && widget.onEdit != null) ...[
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
                  onPressed: () => widget.onEdit!(widget.empleado),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildCrearCuentaContainer() {
    if (widget.onGestionarCuenta == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.triangleExclamation,
                  color: Colors.amber,
                  size: 18,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Este colaborador no tiene una cuenta para acceder al sistema',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.triangleExclamation,
                color: Colors.amber,
                size: 18,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Este colaborador no tiene una cuenta para acceder al sistema',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Para permitir que este colaborador inicie sesión en el sistema, necesita crear una cuenta de usuario con un rol asignado.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => widget.onGestionarCuenta!(context, widget.empleado),
              icon: const FaIcon(
                FontAwesomeIcons.userPlus,
                size: 16,
              ),
              label: const Text('Crear Cuenta de Usuario'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Diálogo para mostrar los detalles de un empleado
class EmpleadoDetallesDialog extends StatefulWidget {
  final Empleado empleado;
  final Map<String, String> nombresSucursales;
  final String Function(Empleado) obtenerRolDeEmpleado;
  final Function(Empleado) onEdit;

  const EmpleadoDetallesDialog({
    super.key,
    required this.empleado,
    required this.nombresSucursales,
    required this.obtenerRolDeEmpleado,
    required this.onEdit,
  });

  @override
  State<EmpleadoDetallesDialog> createState() => _EmpleadoDetallesDialogState();
}

class _EmpleadoDetallesDialogState extends State<EmpleadoDetallesDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contenido principal usando el nuevo viewer
            Flexible(
              child: EmpleadoDetallesViewer(
                empleado: widget.empleado,
                nombresSucursales: widget.nombresSucursales,
                obtenerRolDeEmpleado: widget.obtenerRolDeEmpleado,
                onEdit: null, // No mostrar el botón de editar en el viewer
                onGestionarCuenta: _gestionarCuentaEmpleado,
              ),
            ),
            
            // Botones de acción
            const SizedBox(height: 16),
            
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
    );
  }

  Future<void> _gestionarCuentaEmpleado(BuildContext context, Empleado empleado) async {
    try {
      if (!context.mounted) return;
      await EmpleadosUtils.mostrarDialogoCarga(
        context, 
        mensaje: 'Cargando información de cuenta...',
        barrierDismissible: true // Permitir cancelar el diálogo si tarda demasiado
      );

      // Verificar si el contexto sigue montado después del diálogo de carga
      if (!context.mounted) return;

      // Usar la función de utilidad para gestionar la cuenta
      final cuentaActualizada = await EmpleadosUtils.gestionarCuenta(context, empleado);
      
      // Verificar si el widget y el contexto siguen montados después de la operación asíncrona
      if (!mounted) return;
      if (!context.mounted) return;
      
      // Cerrar diálogo de carga (si sigue abierto)
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
      
      // Si se realizó algún cambio, actualizar la información
      if (cuentaActualizada) {
        EmpleadosUtils.mostrarMensaje(
          context,
          mensaje: 'Cuenta actualizada correctamente'
        );
        
        setState(() {
          // Forzar reconstrucción para actualizar los datos
        });
      }
    } catch (e) {
      // Verificar si el widget y el contexto siguen montados después de la operación asíncrona
      if (!mounted) return;
      if (!context.mounted) return;
      
      // Cerrar diálogo de carga si está abierto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Determinar el tipo de error para mostrar un mensaje apropiado
      final bool esErrorAutenticacion = e.toString().contains('401') && 
          (e.toString().contains('No autorizado') || 
           e.toString().contains('Sesión expirada') ||
           e.toString().contains('token inválido'));
      
      final String errorMessage = esErrorAutenticacion
          ? 'Sesión expirada. Por favor, inicie sesión nuevamente.'
          : 'Error al gestionar cuenta: $e';
      
      EmpleadosUtils.mostrarMensaje(
        context,
        mensaje: errorMessage,
        esError: true,
      );
    }
  }
} 