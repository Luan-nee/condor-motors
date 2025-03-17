import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../api/protected/empleados.api.dart';
import '../../../main.dart' show api;
import 'empleados_utils.dart';

class EmpleadoListItem extends StatefulWidget {
  final Empleado empleado;
  final Map<String, String> nombresSucursales;
  final String Function(Empleado) obtenerRolDeEmpleado;
  final Function(Empleado) onEdit;
  final Function(Empleado) onDelete;
  final Function(Empleado) onViewDetails;
  final Function(Empleado, bool) onChangeStatus;

  const EmpleadoListItem({
    Key? key,
    required this.empleado,
    required this.nombresSucursales,
    required this.obtenerRolDeEmpleado,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
    required this.onChangeStatus,
  }) : super(key: key);

  @override
  State<EmpleadoListItem> createState() => _EmpleadoListItemState();
}

class _EmpleadoListItemState extends State<EmpleadoListItem> {
  bool _isHovered = false;
  bool _isLoading = false;
  String? _usuarioEmpleado;
  
  @override
  void initState() {
    super.initState();
    _cargarUsuarioEmpleado();
  }
  
  Future<void> _cargarUsuarioEmpleado() async {
    try {
      setState(() => _isLoading = true);
      
      final cuentaInfo = await api.empleados.getCuentaByEmpleadoId(widget.empleado.id);
      if (cuentaInfo != null && cuentaInfo['usuario'] != null) {
        setState(() => _usuarioEmpleado = cuentaInfo['usuario'].toString());
      }
    } catch (e) {
      // Manejar específicamente errores de autenticación
      if (e.toString().contains('401') || 
          e.toString().contains('Sesión expirada') || 
          e.toString().contains('No autorizado')) {
        // No mostrar error en la UI para este componente
        debugPrint('Error de autenticación al cargar usuario: $e');
      } else {
        // Otros errores
        debugPrint('Error al cargar usuario del empleado: $e');
      }
      // No hacer nada más, simplemente no se mostrará el usuario
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esCentral = EmpleadosUtils.esSucursalCentral(
      widget.empleado.sucursalId, 
      widget.nombresSucursales
    );
    
    final nombreSucursal = EmpleadosUtils.getNombreSucursal(
      widget.empleado.sucursalId, 
      widget.nombresSucursales
    );
    
    final rol = widget.obtenerRolDeEmpleado(widget.empleado);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFF2D2D2D) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            children: [
              // Nombre (25% del ancho)
              Expanded(
                flex: 25,
                child: Row(
                  children: [
                    // Avatar o foto
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: widget.empleado.ubicacionFoto != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.empleado.ubicacionFoto!,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const FaIcon(
                                  FontAwesomeIcons.user,
                                  color: Color(0xFFE31E24),
                                  size: 16,
                                ),
                              ),
                            )
                          : const FaIcon(
                              FontAwesomeIcons.user,
                              color: Color(0xFFE31E24),
                              size: 16,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nombre y apellidos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.empleado.nombre} ${widget.empleado.apellidos}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_isLoading) ...[
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 2,
                              width: 60,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey[800],
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
                              ),
                            ),
                          ] else if (_usuarioEmpleado != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '(@$_usuarioEmpleado)',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Teléfono (15% del ancho)
              Expanded(
                flex: 15,
                child: Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.phone,
                      color: Color(0xFFE31E24),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.empleado.celular ?? 'No disponible',
                      style: TextStyle(
                        color: widget.empleado.celular != null ? Colors.white : Colors.white.withOpacity(0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Rol (20% del ancho)
              Expanded(
                flex: 20,
                child: Row(
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
                      ),
                    ),
                  ],
                ),
              ),
              
              // Local (20% del ancho)
              Expanded(
                flex: 20,
                child: Row(
                  children: [
                    FaIcon(
                      esCentral
                          ? FontAwesomeIcons.building
                          : FontAwesomeIcons.store,
                      color: esCentral
                          ? const Color.fromARGB(255, 95, 208, 243)
                          : Colors.white54,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nombreSucursal,
                        style: TextStyle(
                          color: esCentral
                              ? const Color.fromARGB(255, 95, 208, 243)
                              : Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Estado (10% del ancho)
              Expanded(
                flex: 10,
                child: Center(
                  child: Switch(
                    value: widget.empleado.activo,
                    onChanged: (value) => widget.onChangeStatus(widget.empleado, value),
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                    activeTrackColor: Colors.green.withOpacity(0.3),
                    inactiveTrackColor: Colors.red.withOpacity(0.3),
                  ),
                ),
              ),
              
              // Acciones (10% del ancho)
              Expanded(
                flex: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Botón para ver detalles
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.eye,
                        size: 16,
                        color: Colors.white70,
                      ),
                      onPressed: () => widget.onViewDetails(widget.empleado),
                      tooltip: 'Ver detalles',
                      splashRadius: 20,
                    ),
                    // Botón para editar
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.penToSquare,
                        size: 16,
                        color: Colors.white70,
                      ),
                      onPressed: () => widget.onEdit(widget.empleado),
                      tooltip: 'Editar',
                      splashRadius: 20,
                    ),
                    // Botón para eliminar
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.trash,
                        size: 16,
                        color: Colors.red,
                      ),
                      onPressed: () => widget.onDelete(widget.empleado),
                      tooltip: 'Eliminar',
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 