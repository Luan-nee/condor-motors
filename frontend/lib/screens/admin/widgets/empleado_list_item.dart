import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../main.dart' show api;
import '../../../models/empleado.model.dart';
import '../utils/empleados_utils.dart';

class EmpleadoListItem extends StatefulWidget {
  final Empleado empleado;
  final Map<String, String> nombresSucursales;
  final String Function(Empleado) obtenerRolDeEmpleado;
  final Function(Empleado) onEdit;
  final Function(Empleado) onDelete;
  final Function(Empleado) onViewDetails;

  const EmpleadoListItem({
    super.key,
    required this.empleado,
    required this.nombresSucursales,
    required this.obtenerRolDeEmpleado,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
  });

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
    
    // Solo cargar la información de usuario si no viene en la respuesta de la API
    if (widget.empleado.cuentaEmpleadoId != null && _usuarioEmpleado == null) {
      _cargarUsuarioEmpleado();
    }
  }
  
  Future<void> _cargarUsuarioEmpleado() async {
    try {
      setState(() => _isLoading = true);
      
      // Obtener información de la cuenta de empleado por su ID
      if (widget.empleado.cuentaEmpleadoId != null) {
        final cuentaInfo = await api.empleados.getCuentaEmpleado(widget.empleado.cuentaEmpleadoId!);
        if (cuentaInfo['usuario'] != null) {
          setState(() => _usuarioEmpleado = cuentaInfo['usuario'].toString());
        }
      } else {
        // Compatibilidad con versión anterior: obtener por ID de empleado
        final cuentaInfo = await api.empleados.getCuentaByEmpleadoId(widget.empleado.id);
        if (cuentaInfo != null && cuentaInfo['usuario'] != null) {
          setState(() => _usuarioEmpleado = cuentaInfo['usuario'].toString());
        }
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
    // Obtener rol del empleado
    final String rol = widget.obtenerRolDeEmpleado(widget.empleado);
    
    // Determinar si el empleado está activo o inactivo
    final bool esInactivo = !widget.empleado.activo;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: _isHovered 
            ? const Color(0xFF2D2D2D)
            : (esInactivo ? Colors.transparent : Colors.transparent),
          border: Border(
            bottom: BorderSide(
              color: esInactivo 
                ? Colors.grey.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
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
                        border: esInactivo ? Border.all(
                          color: Colors.grey.withOpacity(0.4),
                        ) : null,
                      ),
                      child: Center(
                        child: widget.empleado.ubicacionFoto != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  Image.network(
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
                                  if (esInactivo)
                                    Container(
                                      width: 36,
                                      height: 36,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                ],
                              ),
                            )
                          : Stack(
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.user,
                                  color: Color(0xFFE31E24),
                                  size: 16,
                                ),
                                if (esInactivo)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE31E24),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: FaIcon(
                                          FontAwesomeIcons.xmark,
                                          color: Colors.white,
                                          size: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nombre y apellidos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${widget.empleado.nombre} ${widget.empleado.apellidos}',
                                  style: TextStyle(
                                    color: esInactivo
                                      ? Colors.white.withOpacity(0.6)
                                      : Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (esInactivo)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
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
                          if (esInactivo) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              child: const Text(
                                'Inactivo',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                    FaIcon(
                      FontAwesomeIcons.phone,
                      color: esInactivo
                        ? Colors.grey.withOpacity(0.5)
                        : const Color(0xFFE31E24),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.empleado.celular ?? 'No disponible',
                      style: TextStyle(
                        color: widget.empleado.celular != null 
                          ? (esInactivo ? Colors.white.withOpacity(0.4) : Colors.white)
                          : Colors.white.withOpacity(0.3),
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
                      color: esInactivo
                        ? Colors.grey.withOpacity(0.5)
                        : const Color(0xFFE31E24),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      rol,
                      style: TextStyle(
                        color: esInactivo ? Colors.white.withOpacity(0.4) : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Sucursal (25% del ancho - ajustado para dar más espacio a las acciones)
              Expanded(
                flex: 25,
                child: Row(
                  children: [
                    FaIcon(
                      EmpleadosUtils.esSucursalCentral(widget.empleado.sucursalId, widget.nombresSucursales)
                          ? FontAwesomeIcons.building
                          : FontAwesomeIcons.store,
                      color: EmpleadosUtils.esSucursalCentral(widget.empleado.sucursalId, widget.nombresSucursales)
                          ? (esInactivo ? const Color.fromARGB(255, 95, 208, 243).withOpacity(0.5) : const Color.fromARGB(255, 95, 208, 243))
                          : (esInactivo ? Colors.grey[400]!.withOpacity(0.5) : Colors.grey[400]),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getSucursalName(),
                        style: TextStyle(
                          color: EmpleadosUtils.esSucursalCentral(widget.empleado.sucursalId, widget.nombresSucursales)
                              ? (esInactivo ? const Color.fromARGB(255, 95, 208, 243).withOpacity(0.5) : const Color.fromARGB(255, 95, 208, 243))
                              : (esInactivo ? Colors.white.withOpacity(0.4) : Colors.white),
                          fontWeight: EmpleadosUtils.esSucursalCentral(widget.empleado.sucursalId, widget.nombresSucursales)
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Acciones (15% del ancho - aumentado de 10% a 15% para evitar overflow)
              Expanded(
                flex: 15,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botón para ver detalles
                    IconButton(
                      icon: FaIcon(
                        FontAwesomeIcons.eye,
                        size: 16,
                        color: esInactivo ? Colors.white38 : Colors.white70,
                      ),
                      onPressed: () => widget.onViewDetails(widget.empleado),
                      tooltip: 'Ver detalles',
                      splashRadius: 18,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                    // Botón para editar
                    IconButton(
                      icon: FaIcon(
                        FontAwesomeIcons.penToSquare,
                        size: 16,
                        color: esInactivo ? Colors.white38 : Colors.white70,
                      ),
                      onPressed: () => widget.onEdit(widget.empleado),
                      tooltip: 'Editar',
                      splashRadius: 18,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
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
                      splashRadius: 18,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
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

  // Método para obtener el nombre de la sucursal
  String _getSucursalName() {
    // Primero intentar usar el nombre de sucursal que viene directamente del empleado
    if (widget.empleado.sucursalNombre != null) {
      if (widget.empleado.sucursalCentral) {
        return '${widget.empleado.sucursalNombre!} (Central)';
      }
      return widget.empleado.sucursalNombre!;
    }
    
    // Si no está disponible, usar el mapa de nombres de sucursales
    if (widget.empleado.sucursalId != null) {
      return widget.nombresSucursales[widget.empleado.sucursalId!] ?? 'Sin sucursal';
    }
    
    return 'Sin sucursal';
  }
}