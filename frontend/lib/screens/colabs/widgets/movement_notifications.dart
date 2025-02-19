import 'package:flutter/material.dart';
import '../../../models/movement.dart';
import '../../../api/movimientos.api.dart';
import '../../../api/api.service.dart';

class MovementNotifications extends StatefulWidget {
  const MovementNotifications({super.key});

  @override
  State<MovementNotifications> createState() => _MovementNotificationsState();
}

class _MovementNotificationsState extends State<MovementNotifications> {
  final _movimientosApi = MovimientosApi(ApiService());
  bool _isLoading = false;
  List<Movement> _notifications = [];
  String? _error;
  Movement? _selectedMovement;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _movimientosApi.getMovements();
      
      if (!mounted) return;
      setState(() {
        _notifications = response
            .map((m) => Movement.fromJson(m))
            .where((m) => m.estado == 'SOLICITANDO' || m.estado == 'PREPARADO')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: _loadNotifications,
          ),
        ),
      );
    }
  }

  Future<void> _handleMovementAction(Movement movement) async {
    setState(() => _selectedMovement = movement);
    
    try {
      await _movimientosApi.updateMovementStatus(
        movement.id,
        'PREPARADO',
      );
      
      if (!mounted) return;
      
      setState(() {
        _selectedMovement = null;
        _notifications.remove(movement);
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadNotifications();
    } catch (e) {
      if (!mounted) return;
      setState(() => _selectedMovement = null);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar estado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Movement> get _pendingMovements => _notifications.where((m) => 
      m.estado == 'SOLICITANDO' || m.estado == 'PREPARADO').toList();

  List<Movement> get _approvableMovements => _notifications.where((m) => 
      m.estado == 'RECIBIDO').toList();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      icon: Badge(
        backgroundColor: const Color(0xFFD32F2F),
        label: Text(
          _notifications.length.toString(),
          style: const TextStyle(color: Colors.white),
        ),
        isLabelVisible: _notifications.isNotEmpty,
        child: const Icon(
          Icons.notifications_outlined,
          color: Color(0xFFD32F2F),
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) => [
        if (_isLoading)
          const PopupMenuItem(
            enabled: false,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          PopupMenuItem(
            enabled: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
                TextButton(
                  onPressed: _loadNotifications,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          )
        else if (_notifications.isEmpty)
          const PopupMenuItem(
            enabled: false,
            child: Text('No hay notificaciones pendientes'),
          )
        else
          ...[
            if (_pendingMovements.isNotEmpty) ...[
              const PopupMenuItem(
                enabled: false,
                child: Text(
                  'Pendientes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ..._pendingMovements.map((m) => PopupMenuItem(
                child: _buildNotificationItem(m),
                onTap: () => _showMovementDetails(context, m),
              )),
            ],
            if (_approvableMovements.isNotEmpty) ...[
              const PopupMenuItem(
                enabled: false,
                child: Text(
                  'Para Aprobar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ..._approvableMovements.map((m) => PopupMenuItem(
                child: _buildNotificationItem(m, isApprovable: true),
                onTap: () => _showMovementDetails(context, m),
              )),
            ],
          ],
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: _loadNotifications,
          child: const Row(
            children: [
              Icon(Icons.refresh),
              SizedBox(width: 8),
              Text('Actualizar'),
            ],
          ),
        ),
        if (_selectedMovement != null)
          const PopupMenuItem(
            value: 'preparar',
            child: Row(
              children: [
                Icon(Icons.check_circle_outline),
                SizedBox(width: 8),
                Text('Marcar como preparado'),
              ],
            ),
          ),
      ],
      onSelected: (value) {
        if (value == 'preparar' && _selectedMovement != null) {
          _handleMovementAction(_selectedMovement!);
        }
      },
    );
  }

  Widget _buildNotificationItem(Movement movement, {bool isApprovable = false}) {
    final color = isApprovable ? const Color(0xFF43A047) : const Color(0xFFD32F2F);
    
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        border: Border(
          left: BorderSide(
            color: color,
            width: 4,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isApprovable ? Icons.check_circle : Icons.local_shipping,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isApprovable 
                      ? 'Movimiento para aprobar'
                      : movement.estado == 'SOLICITANDO'
                          ? 'Nueva solicitud de productos'
                          : 'Productos listos para envío',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF424242),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${movement.cantidad} ${movement.producto?.name ?? 'productos'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF757575),
                  ),
                ),
                Text(
                  'De: ${movement.sucursalOrigen} → A: ${movement.sucursalDestino}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMovementDetails(BuildContext context, Movement movement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          movement.estado == 'SOLICITANDO'
              ? 'Nueva Solicitud de Productos'
              : 'Productos Listos para Envío',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Producto: ${movement.producto?.name ?? 'No especificado'}'),
            Text('Cantidad: ${movement.cantidad}'),
            Text('Origen: ${movement.sucursalOrigen}'),
            Text('Destino: ${movement.sucursalDestino}'),
            Text('Estado: ${movement.estado}'),
            Text(
              'Fecha: ${_formatDate(movement.fechaMovimiento)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (movement.estado == 'SOLICITANDO')
            ElevatedButton(
              onPressed: () async {
                try {
                  await _movimientosApi.updateMovementStatus(
                    movement.id,
                    'PREPARADO',
                  );
                  
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  
                  await _loadNotifications();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Marcar como Preparado'),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 