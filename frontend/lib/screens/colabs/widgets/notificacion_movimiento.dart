import 'package:flutter/material.dart';
import '../../../api/movimientos_stock.api.dart';
import '../../../api/main.api.dart';

class NotificacionMovimiento extends StatefulWidget {
  const NotificacionMovimiento({super.key});

  @override
  State<NotificacionMovimiento> createState() => _NotificacionMovimientoState();
}

class _NotificacionMovimientoState extends State<NotificacionMovimiento> {
  final _movimientosApi = MovimientosStockApi(ApiService());
  bool _isLoading = false;
  List<MovimientoStock> _notificaciones = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _movimientosApi.getMovimientos(
        estado: MovimientosStockApi.estadosDetalle['PENDIENTE'],
      );
      
      if (!mounted) return;
      setState(() {
        _notificaciones = response
            .where((m) => m.estado == MovimientosStockApi.estadosDetalle['PENDIENTE'] || 
                        m.estado == MovimientosStockApi.estadosDetalle['PREPARADO'])
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
            onPressed: _cargarNotificaciones,
          ),
        ),
      );
    }
  }

  Future<void> _manejarAccionMovimiento(MovimientoStock movimiento) async {
    try {
      await _movimientosApi.updateMovimiento(
        movimiento.id,
        {'estado': MovimientosStockApi.estadosDetalle['PREPARADO']},
      );
      
      if (!mounted) return;
      
      setState(() {
        _notificaciones.remove(movimiento);
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      await _cargarNotificaciones();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar estado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<MovimientoStock> get _movimientosPendientes => _notificaciones.where((m) => 
      m.estado == MovimientosStockApi.estadosDetalle['PENDIENTE'] || 
      m.estado == MovimientosStockApi.estadosDetalle['PREPARADO']).toList();

  List<MovimientoStock> get _movimientosParaAprobar => _notificaciones.where((m) => 
      m.estado == MovimientosStockApi.estadosDetalle['RECIBIDO']).toList();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      icon: Badge(
        backgroundColor: const Color(0xFFD32F2F),
        label: Text(
          _notificaciones.length.toString(),
          style: const TextStyle(color: Colors.white),
        ),
        isLabelVisible: _notificaciones.isNotEmpty,
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
                  onPressed: _cargarNotificaciones,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          )
        else if (_notificaciones.isEmpty)
          const PopupMenuItem(
            enabled: false,
            child: Text('No hay notificaciones pendientes'),
          )
        else
          ...[
            if (_movimientosPendientes.isNotEmpty) ...[
              const PopupMenuItem(
                enabled: false,
                child: Text(
                  'Pendientes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ..._movimientosPendientes.map((m) => PopupMenuItem(
                child: _construirItemNotificacion(m),
                onTap: () => _mostrarDetallesMovimiento(context, m),
              )),
            ],
            if (_movimientosParaAprobar.isNotEmpty) ...[
              const PopupMenuItem(
                enabled: false,
                child: Text(
                  'Para Aprobar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ..._movimientosParaAprobar.map((m) => PopupMenuItem(
                child: _construirItemNotificacion(m, paraAprobar: true),
                onTap: () => _mostrarDetallesMovimiento(context, m),
              )),
            ],
          ],
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: _cargarNotificaciones,
          child: const Row(
            children: [
              Icon(Icons.refresh),
              SizedBox(width: 8),
              Text('Actualizar'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirItemNotificacion(MovimientoStock movimiento, {bool paraAprobar = false}) {
    final color = paraAprobar ? const Color(0xFF43A047) : const Color(0xFFD32F2F);
    
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
              paraAprobar ? Icons.check_circle : Icons.local_shipping,
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
                  paraAprobar 
                      ? 'Movimiento para aprobar'
                      : movimiento.estado == MovimientosStockApi.estadosDetalle['PENDIENTE']
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
                  'Detalles: ${movimiento.detalles.length} productos',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF757575),
                  ),
                ),
                Text(
                  'De: Local #${movimiento.localOrigenId} → A: Local #${movimiento.localDestinoId}',
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

  void _mostrarDetallesMovimiento(BuildContext context, MovimientoStock movimiento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          movimiento.estado == MovimientosStockApi.estadosDetalle['PENDIENTE']
              ? 'Nueva Solicitud de Productos'
              : 'Productos Listos para Envío',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detalles: ${movimiento.detalles.length} productos'),
            Text('Origen: Local #${movimiento.localOrigenId}'),
            Text('Destino: Local #${movimiento.localDestinoId}'),
            Text('Estado: ${movimiento.estado}'),
            Text(
              'Fecha: ${_formatearFecha(movimiento.fechaCreacion)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (movimiento.estado == MovimientosStockApi.estadosDetalle['PENDIENTE'])
            ElevatedButton(
              onPressed: () async {
                try {
                  await _movimientosApi.updateMovimiento(
                    movimiento.id,
                    {'estado': MovimientosStockApi.estadosDetalle['PREPARADO']},
                  );
                  
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  
                  await _cargarNotificaciones();
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

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
} 