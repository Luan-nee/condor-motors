import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/main.api.dart';

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
  bool _isLoading = false;
  List<MovimientoStock> _movimientos = [];
  String _filtroSeleccionado = 'Todos';
  final TextEditingController _searchController = TextEditingController();
  int? _usuarioId = 1; // ID de prueba

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
    setState(() => _isLoading = true);
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
        setState(() => _isLoading = false);
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

  Future<void> _aprobarMovimiento(MovimientoStock movimiento) async {
    if (_usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener el ID del usuario actual'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Simulamos la aprobación
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        final index = _movimientosPrueba.indexWhere((m) => m.id == movimiento.id);
        if (index != -1) {
          _movimientosPrueba[index] = MovimientoStock(
            id: movimiento.id,
            localOrigenId: movimiento.localOrigenId,
            localDestinoId: movimiento.localDestinoId,
            estado: 'APROBADO',
            detalles: movimiento.detalles,
          );
        }
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Movimiento aprobado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      await _cargarMovimientos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aprobar movimiento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDetallesList(List<DetalleMovimiento> detalles) {
    return Column(
      children: detalles.map((detalle) => ListTile(
        title: Text('Producto #${detalle.productoId}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cantidad: ${detalle.cantidad}'),
            if (detalle.cantidadRecibida != null)
              Text('Recibido: ${detalle.cantidadRecibida}'),
            Text('Estado: ${detalle.estado}'),
          ],
        ),
        trailing: Text('Estado: ${detalle.estado}'),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header rojo con título
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A1A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INVENTARIO / movimiento de inventario',
                  style: TextStyle(
                    color: Color(0xFFE31E24),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Barra de búsqueda y filtros
                Row(
                  children: [
                    // Dropdown de filtros
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: DropdownButton<String>(
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
                    ),
                    const SizedBox(width: 16),
                    // Campo de búsqueda
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Buscador',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          filled: true,
                          fillColor: const Color(0xFF2D2D2D),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: const Icon(Icons.search, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabla de movimientos
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Table(
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(1.2), // Fecha solicitada
                    1: FlexColumnWidth(1.2), // Fecha de respuesta
                    2: FlexColumnWidth(2), // Proveedor
                    3: FlexColumnWidth(2), // Solicitante
                    4: FlexColumnWidth(1.5), // Origen
                    5: FlexColumnWidth(1.5), // Destino
                    6: FlexColumnWidth(1), // Estado
                    7: FlexColumnWidth(1), // Detalles
                  },
                  children: [
                    // Encabezados
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D2D2D),
                      ),
                      children: [
                        _buildHeaderCell('Fecha solicitada', color: const Color(0xFFE31E24)),
                        _buildHeaderCell('Fecha de respuesta', color: const Color(0xFFE31E24)),
                        _buildHeaderCell('Proveedor', color: const Color(0xFFE31E24)),
                        _buildHeaderCell('Solicitante', color: const Color(0xFFE31E24)),
                        _buildHeaderCell('Origen', color: const Color(0xFFE31E24)),
                        _buildHeaderCell('Destino', color: const Color(0xFFE31E24)),
                        _buildHeaderCell('Estado', color: const Color(0xFFE31E24)),
                        _buildHeaderCell('Lista de\nproductos\nsolicitados', color: const Color(0xFFE31E24)),
                      ],
                    ),
                    // Filas de datos
                    ..._movimientos.map((movimiento) => TableRow(
                      children: [
                        _buildCell(movimiento.id.toString()),
                        _buildCell(movimiento.estado),
                        _buildCell(movimiento.localOrigenId.toString()),
                        _buildCell(movimiento.localDestinoId.toString()),
                        _buildCell(movimiento.detalles.first.productoId.toString()),
                        _buildCell(movimiento.detalles.first.cantidad.toString()),
                        _buildEstadoCell(movimiento.estado),
                        _buildDetallesCell(movimiento.detalles),
                      ],
                    )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCell(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildEstadoCell(String estado) {
    Color backgroundColor;
    Color textColor = Colors.white;

    switch (estado.toLowerCase()) {
      case 'finalizado':
        backgroundColor = Colors.green;
        break;
      case 'solicitando':
        backgroundColor = Colors.yellow;
        textColor = Colors.black;
        break;
      case 'rechazado':
        backgroundColor = Colors.red;
        break;
      default:
        backgroundColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          estado,
          style: TextStyle(color: textColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDetallesCell(List<DetalleMovimiento> detalles) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: TextButton(
        onPressed: () {
          // TODO: Implementar vista de detalles
        },
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFE31E24),
        ),
        child: const Text('ver detalles'),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 