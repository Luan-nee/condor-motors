import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/providers/admin/index.admin.provider.dart';
import 'package:condorsmotors/utils/empleados_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class EmpleadoListItem extends StatefulWidget {
  final Empleado empleado;
  final Map<String, String> nombresSucursales;
  final Function(Empleado) onEdit;
  final Function(Empleado) onDelete;
  final Function(Empleado) onViewDetails;
  final Function(Empleado) onEditCuenta;

  const EmpleadoListItem({
    super.key,
    required this.empleado,
    required this.nombresSucursales,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
    required this.onEditCuenta,
  });

  @override
  State<EmpleadoListItem> createState() => _EmpleadoListItemState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Empleado>('empleado', empleado))
      ..add(DiagnosticsProperty<Map<String, String>>(
          'nombresSucursales', nombresSucursales))
      ..add(ObjectFlagProperty<Function(Empleado p1)>.has('onEdit', onEdit))
      ..add(ObjectFlagProperty<Function(Empleado p1)>.has('onDelete', onDelete))
      ..add(ObjectFlagProperty<Function(Empleado p1)>.has(
          'onViewDetails', onViewDetails))
      ..add(ObjectFlagProperty<Function(Empleado p1)>.has(
          'onEditCuenta', onEditCuenta));
  }
}

class _EmpleadoListItemState extends State<EmpleadoListItem> {
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el provider para escuchar cambios
    final empleadoProvider = Provider.of<EmpleadoProvider>(context);

    // Obtener rol del empleado directamente desde el modelo
    final String rol = widget.empleado.rol?.nombre ??
        empleadoProvider.obtenerRolDeEmpleado(widget.empleado);

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
            children: <Widget>[
              // Nombre (25% del ancho)
              Expanded(
                flex: 25,
                child: Row(
                  children: <Widget>[
                    // Avatar o foto
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(8),
                        border: esInactivo
                            ? Border.all(
                                color: Colors.grey.withOpacity(0.4),
                              )
                            : null,
                      ),
                      child: Center(
                        child: widget.empleado.fotoUrl != null &&
                                widget.empleado.fotoUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  children: <Widget>[
                                    Image.network(
                                      widget.empleado.fotoUrl!,
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                      errorBuilder: (BuildContext context,
                                              Object error,
                                              StackTrace? stackTrace) =>
                                          const FaIcon(
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
                                children: <Widget>[
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
                        children: <Widget>[
                          Row(
                            children: <Widget>[
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
                          if (widget.empleado.cuentaEmpleadoUsuario !=
                              null) ...<Widget>[
                            const SizedBox(height: 4),
                            Text(
                              '(@${widget.empleado.cuentaEmpleadoUsuario})',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (esInactivo) ...<Widget>[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
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
                  children: <Widget>[
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
                            ? (esInactivo
                                ? Colors.white.withOpacity(0.4)
                                : Colors.white)
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
                  children: <Widget>[
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
                        color: esInactivo
                            ? Colors.white.withOpacity(0.4)
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Sucursal (25% del ancho - ajustado para dar más espacio a las acciones)
              Expanded(
                flex: 25,
                child: Row(
                  children: <Widget>[
                    FaIcon(
                      EmpleadosUtils.esSucursalCentral(
                              widget.empleado.sucursalId,
                              widget.nombresSucursales)
                          ? FontAwesomeIcons.building
                          : FontAwesomeIcons.store,
                      color: EmpleadosUtils.esSucursalCentral(
                              widget.empleado.sucursalId,
                              widget.nombresSucursales)
                          ? (esInactivo
                              ? const Color.fromARGB(255, 95, 208, 243)
                                  .withOpacity(0.5)
                              : const Color.fromARGB(255, 95, 208, 243))
                          : (esInactivo
                              ? Colors.grey[400]!.withOpacity(0.5)
                              : Colors.grey[400]),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getSucursalName(),
                        style: TextStyle(
                          color: EmpleadosUtils.esSucursalCentral(
                                  widget.empleado.sucursalId,
                                  widget.nombresSucursales)
                              ? (esInactivo
                                  ? const Color.fromARGB(255, 95, 208, 243)
                                      .withOpacity(0.5)
                                  : const Color.fromARGB(255, 95, 208, 243))
                              : (esInactivo
                                  ? Colors.white.withOpacity(0.4)
                                  : Colors.white),
                          fontWeight: EmpleadosUtils.esSucursalCentral(
                                  widget.empleado.sucursalId,
                                  widget.nombresSucursales)
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
                  children: <Widget>[
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
                    // Botón para editar cuenta de usuario
                    IconButton(
                      icon: FaIcon(
                        widget.empleado.cuentaEmpleadoUsuario != null
                            ? FontAwesomeIcons.userGear
                            : FontAwesomeIcons.userPlus,
                        size: 16,
                        color: esInactivo
                            ? Colors.white38
                            : (widget.empleado.cuentaEmpleadoUsuario != null
                                ? Colors.amber
                                : const Color(0xFFB9FF3A)),
                      ),
                      onPressed: () => widget.onEditCuenta(widget.empleado),
                      tooltip: widget.empleado.cuentaEmpleadoUsuario != null
                          ? 'Editar cuenta de usuario'
                          : 'Crear cuenta de usuario',
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
      return widget.nombresSucursales[widget.empleado.sucursalId!] ??
          'Sin sucursal';
    }

    return 'Sin sucursal';
  }
}
