import 'package:flutter/material.dart';
import '../../models/movement.dart';
import '../../api/movimientos.api.dart';
import '../../api/api.service.dart';
import '../../widgets/movement_progress.dart';

class MovementsAdminScreen extends StatefulWidget {
  const MovementsAdminScreen({super.key});

  @override
  State<MovementsAdminScreen> createState() => _MovementsAdminScreenState();
}

class _MovementsAdminScreenState extends State<MovementsAdminScreen> {
  final _movimientosApi = MovimientosApi(ApiService());
  bool _isLoading = false;
  List<Movement> _movements = [];

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final movements = await _movimientosApi.getMovements();
      if (!mounted) return;
      setState(() {
        _movements = movements
            .map((m) => Movement.fromJson(m))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approveMovement(Movement movement) async {
    try {
      await _movimientosApi.updateMovementStatus(
        movement.id,
        'APROBADO',
      );
      await _loadMovements();
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Movimientos de Productos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
                onPressed: _loadMovements,
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _movements.length,
                  itemBuilder: (context, index) {
                    final movement = _movements[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.local_shipping),
                        title: Text('${movement.producto?.name ?? 'Producto'} - ${movement.cantidad} unidades'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('De: ${movement.sucursalOrigen}'),
                            Text('A: ${movement.sucursalDestino}'),
                            MovementProgress(
                              currentStatus: MovementStatus.values.firstWhere(
                                (status) => status.toString().split('.').last == movement.estado.toLowerCase(),
                                orElse: () => MovementStatus.solicitando,
                              ),
                              onInfoTap: () {
                                // El diálogo de información se maneja internamente
                              },
                            ),
                          ],
                        ),
                        trailing: movement.estado == 'RECIBIDO'
                            ? IconButton(
                                icon: const Icon(Icons.check_circle_outline),
                                onPressed: () => _approveMovement(movement),
                                tooltip: 'Aprobar movimiento',
                              )
                            : null,
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
} 