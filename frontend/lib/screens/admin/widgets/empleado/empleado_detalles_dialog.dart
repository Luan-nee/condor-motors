import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleado_horario_dialog.dart';
import 'package:condorsmotors/utils/empleados_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Empleado>('empleado', empleado))
      ..add(DiagnosticsProperty<Map<String, String>>(
          'nombresSucursales', nombresSucursales))
      ..add(ObjectFlagProperty<String Function(Empleado p1)>.has(
          'obtenerRolDeEmpleado', obtenerRolDeEmpleado))
      ..add(ObjectFlagProperty<Function(Empleado p1)?>.has('onEdit', onEdit))
      ..add(ObjectFlagProperty<Function(BuildContext p1, Empleado p2)?>.has(
          'onGestionarCuenta', onGestionarCuenta))
      ..add(DiagnosticsProperty<bool>('showActions', showActions));
  }
}

class _EmpleadoDetallesViewerState extends State<EmpleadoDetallesViewer> {
  String? _usuarioEmpleado;
  bool _isHoveringPhoto = false;
  late final EmpleadoRepository _empleadoRepository;

  @override
  void initState() {
    super.initState();
    _empleadoRepository = EmpleadoRepository.instance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarInformacionCuenta();
    });
  }

  // Método para mostrar la foto en zoom
  void _mostrarFotoEnZoom(BuildContext context) {
    if (widget.empleado.fotoUrl == null || widget.empleado.fotoUrl!.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: <Widget>[
            // Fondo oscuro con tap para cerrar
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // Imagen centrada
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.empleado.fotoUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (BuildContext context, Object error,
                            StackTrace? stackTrace) =>
                        Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.image,
                              color: Colors.white54,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error al cargar imagen',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Botón cerrar
            Positioned(
              top: 40,
              right: 40,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cargarInformacionCuenta() async {
    if (!mounted) {
      return;
    }

    try {
      final Map<String, dynamic> resultado =
          await _empleadoRepository.obtenerInfoCuentaEmpleado(widget.empleado);

      if (mounted) {
        setState(() {
          _usuarioEmpleado = resultado['usuarioActual'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar información de cuenta: $e');
      if (mounted) {
        setState(() {
          _usuarioEmpleado = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usar los nuevos métodos para obtener información de sucursal
    final bool esCentral = EmpleadosUtils.esSucursalCentralEmpleado(
        widget.empleado, widget.nombresSucursales);
    final String nombreSucursal = EmpleadosUtils.getNombreSucursalEmpleado(
        widget.empleado, widget.nombresSucursales);
    final String rol = widget.obtenerRolDeEmpleado(widget.empleado);
    final String nombreCompleto =
        EmpleadosUtils.getNombreCompleto(widget.empleado);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Encabezado con foto y nombre
          Row(
            children: <Widget>[
              // Foto o avatar
              MouseRegion(
                onEnter: (event) => setState(() => _isHoveringPhoto = true),
                onExit: (event) => setState(() => _isHoveringPhoto = false),
                child: GestureDetector(
                  onTap: widget.empleado.fotoUrl != null &&
                          widget.empleado.fotoUrl!.isNotEmpty
                      ? () => _mostrarFotoEnZoom(context)
                      : null,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: (widget.empleado.fotoUrl != null &&
                              widget.empleado.fotoUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Image.network(
                                    widget.empleado.fotoUrl!,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (BuildContext context,
                                            Object error,
                                            StackTrace? stackTrace) =>
                                        const FaIcon(
                                      FontAwesomeIcons.user,
                                      color: Color(0xFFE31E24),
                                      size: 28,
                                    ),
                                  ),
                                  // Indicador de zoom (solo visible al pasar el mouse)
                                  if (_isHoveringPhoto)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: AnimatedOpacity(
                                        opacity: _isHoveringPhoto ? 1.0 : 0.0,
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.zoom_in,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : const FaIcon(
                              FontAwesomeIcons.user,
                              color: Color(0xFFE31E24),
                              size: 28,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Nombre y rol
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
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
                          color: const Color(0xFFE31E24).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
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
                    if (_usuarioEmpleado != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          const FaIcon(
                            FontAwesomeIcons.userTag,
                            color: Colors.white54,
                            size: 12,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '@$_usuarioEmpleado',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
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
            children: <Widget>[
              // Columna izquierda
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    EmpleadosUtils.buildInfoItem(
                        'DNI', widget.empleado.dni ?? 'No especificado'),
                    const SizedBox(height: 12),
                    EmpleadosUtils.buildInfoItem('Celular',
                        widget.empleado.celular ?? 'No especificado'),
                  ],
                ),
              ),

              // Columna derecha
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    EmpleadosUtils.buildInfoItem('Estado',
                        widget.empleado.activo ? 'Activo' : 'Inactivo'),
                    const SizedBox(height: 12),
                    EmpleadosUtils.buildInfoItem(
                        'Fecha Registro',
                        EmpleadosUtils.formatearFecha(
                            widget.empleado.fechaRegistro)),
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
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: <Widget>[
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
                    children: <Widget>[
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
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Fecha Contratación: ${EmpleadosUtils.formatearFecha(widget.empleado.fechaContratacion)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'INFORMACIÓN LABORAL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE31E24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Información de sueldo
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: EmpleadosUtils.buildInfoItem('Sueldo',
                    EmpleadosUtils.formatearSueldo(widget.empleado.sueldo)),
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
          ),

          // Botones de acción al final
          if (widget.showActions && widget.onEdit != null) ...<Widget>[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Empleado>('empleado', empleado))
      ..add(DiagnosticsProperty<Map<String, String>>(
          'nombresSucursales', nombresSucursales))
      ..add(ObjectFlagProperty<String Function(Empleado p1)>.has(
          'obtenerRolDeEmpleado', obtenerRolDeEmpleado))
      ..add(ObjectFlagProperty<Function(Empleado p1)>.has('onEdit', onEdit));
  }
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
          children: <Widget>[
            // Contenido principal usando el nuevo viewer
            Flexible(
              child: EmpleadoDetallesViewer(
                empleado: widget.empleado,
                nombresSucursales: widget.nombresSucursales,
                obtenerRolDeEmpleado: widget.obtenerRolDeEmpleado,
                onGestionarCuenta: _gestionarCuentaEmpleado,
              ),
            ),

            // Botones de acción
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
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

  Future<void> _gestionarCuentaEmpleado(
      BuildContext context, Empleado empleado) async {
    try {
      if (!context.mounted) {
        return;
      }

      // Mostrar diálogo de carga
      await EmpleadosUtils.mostrarDialogoCarga(context,
          mensaje: 'Cargando información de cuenta...');

      if (!context.mounted) {
        return;
      }

      // Obtener datos para gestionar la cuenta usando el repository
      await EmpleadoRepository.instance.getRolesCuentas();

      // Verificar si el empleado ya tiene cuenta
      bool esNuevaCuenta = true;
      try {
        await EmpleadoRepository.instance.getCuentaByEmpleadoId(empleado.id);
        esNuevaCuenta = false;
      } catch (e) {
        // Si hay error, asumimos que no tiene cuenta
        esNuevaCuenta = true;
      }

      if (!context.mounted) {
        return;
      }

      // Cerrar diálogo de carga
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }

      // Mostrar mensaje informativo
      EmpleadosUtils.mostrarMensaje(
        context,
        mensaje: esNuevaCuenta
            ? 'El empleado no tiene cuenta. Use el formulario de empleado para crear una.'
            : 'El empleado ya tiene cuenta. Use el formulario de empleado para gestionarla.',
        esError: false,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      // Cerrar diálogo de carga si está abierto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      EmpleadosUtils.mostrarMensaje(
        context,
        mensaje: 'Error al gestionar cuenta: $e',
        esError: true,
      );
    }
  }
}
