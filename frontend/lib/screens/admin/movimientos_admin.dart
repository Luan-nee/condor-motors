import 'package:flutter/material.dart';
import '../../api/main.api.dart';
import '../../api/movimientos_stock.api.dart';
import '../../api/empleados.api.dart';
import '../../api/detalles_movimiento.api.dart';

class MovimientosAdminScreen extends StatefulWidget {
  const MovimientosAdminScreen({super.key});

  @override
  State<MovimientosAdminScreen> createState() => _MovimientosAdminScreenState();
}

class _MovimientosAdminScreenState extends State<MovimientosAdminScreen> {
  final _apiService = ApiService();
  late final MovimientosStockApi _movimientosApi;
  late final EmpleadoApi _empleadosApi;
  late final DetallesMovimientoApi _detallesApi;
  bool _isLoading = false;
  List<MovimientoStock> _movimientos = [];
  String _filtroEstado = 'Todos';
  String? _usuarioId;

  @override
  void initState() {
    super.initState();
    _movimientosApi = MovimientosStockApi(_apiService);
    _empleadosApi = EmpleadoApi(_apiService);
    _detallesApi = DetallesMovimientoApi(_apiService);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Implementar lógica para obtener el ID del usuario actual desde el estado de la aplicación o login
      if (_usuarioId == null) {
        // Por ahora solo cargamos los movimientos sin usuario
        await _cargarMovimientos();
        return;
      }
      
      final empleado = await _empleadosApi.getEmpleado(_usuarioId!);
      if (empleado != null) {
        setState(() {
          _usuarioId = empleado.id;
        });
      }
      
      await _cargarMovimientos();
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
      final movimientos = await _movimientosApi.getMovimientos(
        estado: _filtroEstado != 'Todos' ? _filtroEstado : null,
      );
      if (!mounted) return;
      setState(() => _movimientos = movimientos);
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
      // Primero verificamos que todos los detalles estén en estado RECIBIDO
      final detalles = await _detallesApi.getDetallesByMovimiento(int.parse(movimiento.id));
      final todosRecibidos = detalles.every((detalle) => detalle['estado'] == 'RECIBIDO');
      
      if (!todosRecibidos) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todos los productos deben estar recibidos antes de aprobar'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await _movimientosApi.aprobarMovimiento(
        movimiento.id,
        _usuarioId!,
      );
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
      children: [
        ...detalles.map((detalle) => FutureBuilder<List<Map<String, dynamic>>>(
          future: _detallesApi.getDetallesByMovimiento(detalle.movimientoId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ListTile(
                title: Center(child: CircularProgressIndicator()),
              );
            }
            
            if (snapshot.hasError) {
              return ListTile(
                title: Text('Error al cargar detalles: ${snapshot.error}'),
                tileColor: Colors.red.shade100,
              );
            }

            final detalleCompleto = snapshot.data?.firstWhere(
              (d) => d['id'] == detalle.id,
              orElse: () => {},
            );

            return ListTile(
              title: Text('Producto #${detalle.productoId}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cantidad: ${detalle.cantidad}'),
                  if (detalle.cantidadRecibida != null)
                    Text('Recibido: ${detalle.cantidadRecibida}'),
                  Text('Estado: ${detalle.estado}'),
                  if (detalleCompleto?['observaciones'] != null)
                    Text('Observaciones: ${detalleCompleto!['observaciones']}'),
                ],
              ),
              trailing: Text('Estado: ${detalle.estado}'),
            );
          },
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          DropdownButton<String>(
            value: _filtroEstado,
            items: [
              'Todos',
              ...MovimientosStockApi.estadosDetalle.keys.toList(),
            ].map((estado) {
              return DropdownMenuItem(
                value: estado,
                child: Text(estado),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _filtroEstado = value);
                _cargarMovimientos();
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _movimientos.length,
              itemBuilder: (context, index) {
                final movimiento = _movimientos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ExpansionTile(
                    title: Text(
                      'Movimiento #${movimiento.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Origen: Local #${movimiento.localOrigenId}'),
                        Text('Destino: Local #${movimiento.localDestinoId}'),
                        Text('Estado: ${movimiento.estado}'),
                      ],
                    ),
                    children: [
                      _buildDetallesList(movimiento.detalles),
                      if (movimiento.estado == 'RECIBIDO')
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () => _aprobarMovimiento(movimiento),
                            child: const Text('Aprobar'),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
} 