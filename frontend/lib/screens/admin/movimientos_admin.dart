import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Modelos temporales para desarrollo
class MovimientoStock {
  final int id;
  final int localOrigenId;
  final int localDestinoId;
  final String estado;
  final List<DetalleMovimiento> detalles;

  MovimientoStock({
    required this.id,
    required this.localOrigenId,
    required this.localDestinoId,
    required this.estado,
    required this.detalles,
  });
}

class DetalleMovimiento {
  final int id;
  final int movimientoId;
  final int productoId;
  final int cantidad;
  final int? cantidadRecibida;
  final String estado;

  DetalleMovimiento({
    required this.id,
    required this.movimientoId,
    required this.productoId,
    required this.cantidad,
    this.cantidadRecibida,
    required this.estado,
  });
}

class MovimientosAdminScreen extends StatefulWidget {
  const MovimientosAdminScreen({super.key});

  @override
  State<MovimientosAdminScreen> createState() => _MovimientosAdminScreenState();
}

class _MovimientosAdminScreenState extends State<MovimientosAdminScreen> {
  List<MovimientoStock> _movimientos = [];
  String _filtroSeleccionado = 'Todos';

  // Datos de prueba
  static final List<MovimientoStock> _movimientosPrueba = [
    MovimientoStock(
      id: 1,
      localOrigenId: 1,
      localDestinoId: 2,
      estado: 'PENDIENTE',
      detalles: [
        DetalleMovimiento(
          id: 1,
          movimientoId: 1,
          productoId: 101,
          cantidad: 5,
          estado: 'PENDIENTE',
        ),
        DetalleMovimiento(
          id: 2,
          movimientoId: 1,
          productoId: 102,
          cantidad: 3,
          estado: 'PENDIENTE',
        ),
      ],
    ),
    MovimientoStock(
      id: 2,
      localOrigenId: 2,
      localDestinoId: 3,
      estado: 'RECIBIDO',
      detalles: [
        DetalleMovimiento(
          id: 3,
          movimientoId: 2,
          productoId: 103,
          cantidad: 10,
          cantidadRecibida: 10,
          estado: 'RECIBIDO',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      // Simulamos una carga de datos
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _movimientos = _movimientosPrueba);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
      }
    }
  }

  Future<void> _cargarMovimientos() async {
    try {
      // Simulamos filtrado de datos
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        if (_filtroSeleccionado == 'Todos') {
          _movimientos = _movimientosPrueba;
        } else {
          _movimientos = _movimientosPrueba
              .where((m) => m.estado == _filtroSeleccionado)
              .toList();
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar movimientos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.truck,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INVENTARIO',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'movimiento de inventario',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Barra de búsqueda y filtros
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.filter,
                        color: Color(0xFFE31E24),
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _filtroSeleccionado,
                        dropdownColor: const Color(0xFF2D2D2D),
                        style: const TextStyle(color: Colors.white),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                          DropdownMenuItem(value: 'Proveedor', child: Text('Proveedor')),
                          DropdownMenuItem(value: 'Solicitante', child: Text('Solicitante')),
                          DropdownMenuItem(value: 'Origen', child: Text('Origen')),
                          DropdownMenuItem(value: 'Destino', child: Text('Destino')),
                          DropdownMenuItem(value: 'Estado', child: Text('Estado')),
                        ],
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() => _filtroSeleccionado = value);
                            _cargarMovimientos();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Tabla de movimientos
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Encabezado de la tabla
                      Container(
                        color: const Color(0xFF2D2D2D),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        child: const Row(
                          children: [
                            // Fecha solicitada (15%)
                            Expanded(
                              flex: 15,
                              child: Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.calendar,
                                    color: Color(0xFFE31E24),
                                    size: 14,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Fecha solicitada',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Proveedor (20%)
                            Expanded(
                              flex: 20,
                              child: Text(
                                'Proveedor',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Solicitante (20%)
                            Expanded(
                              flex: 20,
                              child: Text(
                                'Solicitante',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Origen (15%)
                            Expanded(
                              flex: 15,
                              child: Text(
                                'Origen',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Destino (15%)
                            Expanded(
                              flex: 15,
                              child: Text(
                                'Destino',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Estado (15%)
                            Expanded(
                              flex: 15,
                              child: Text(
                                'Estado',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Filas de movimientos
                      ..._movimientos.map((movimiento) => Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        child: Row(
                          children: [
                            // Fecha solicitada
                            Expanded(
                              flex: 15,
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D2D2D),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: FaIcon(
                                        FontAwesomeIcons.calendar,
                                        color: Color(0xFFE31E24),
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    movimiento.id.toString(), // TODO: Cambiar por fecha real
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            // Proveedor
                            Expanded(
                              flex: 20,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D2D2D),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const FaIcon(
                                          FontAwesomeIcons.building,
                                          color: Colors.white54,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Proveedor ${movimiento.localOrigenId}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Solicitante
                            Expanded(
                              flex: 20,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D2D2D),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const FaIcon(
                                          FontAwesomeIcons.user,
                                          color: Colors.white54,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Solicitante ${movimiento.localDestinoId}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Origen
                            Expanded(
                              flex: 15,
                              child: Text(
                                'Local ${movimiento.localOrigenId}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            // Destino
                            Expanded(
                              flex: 15,
                              child: Text(
                                'Local ${movimiento.localDestinoId}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            // Estado
                            Expanded(
                              flex: 15,
                              child: _buildEstadoCell(movimiento.estado),
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoCell(String estado) {
    Color backgroundColor;
    Color textColor = Colors.white;
    IconData iconData;
    String tooltipText;

    switch (estado.toLowerCase()) {
      case 'finalizado':
        backgroundColor = const Color(0xFF2D8A3B).withOpacity(0.2);
        textColor = const Color(0xFF4CAF50);
        iconData = FontAwesomeIcons.circleCheck;
        tooltipText = 'Movimiento finalizado';
        break;
      case 'solicitando':
        backgroundColor = const Color(0xFFFFA000).withOpacity(0.2);
        textColor = const Color(0xFFFFA000);
        iconData = FontAwesomeIcons.clockRotateLeft;
        tooltipText = 'En proceso de solicitud';
        break;
      case 'rechazado':
        backgroundColor = const Color(0xFFE31E24).withOpacity(0.2);
        textColor = const Color(0xFFE31E24);
        iconData = FontAwesomeIcons.circleXmark;
        tooltipText = 'Movimiento rechazado';
        break;
      case 'pendiente':
        backgroundColor = const Color(0xFF1976D2).withOpacity(0.2);
        textColor = const Color(0xFF1976D2);
        iconData = FontAwesomeIcons.hourglassHalf;
        tooltipText = 'Pendiente de aprobación';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
        iconData = FontAwesomeIcons.circleQuestion;
        tooltipText = 'Estado desconocido';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      child: Tooltip(
        message: tooltipText,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: textColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                iconData,
                color: textColor,
                size: 12,
              ),
              const SizedBox(width: 8),
              Text(
                estado,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
} 