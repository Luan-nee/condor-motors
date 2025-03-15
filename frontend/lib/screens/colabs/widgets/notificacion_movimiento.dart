import 'package:flutter/material.dart';
import '../../../api/protected/movimientos.api.dart';
import '../../../main.dart' show api;

// Definición de la clase MovimientoStock para manejar los datos
class MovimientoStock {
  final String id;
  final String localOrigenId;
  final String localDestinoId;
  final String estado;
  final DateTime fechaCreacion;
  final List<DetalleMovimiento> detalles;

  MovimientoStock({
    required this.id,
    required this.localOrigenId,
    required this.localDestinoId,
    required this.estado,
    required this.fechaCreacion,
    required this.detalles,
  });

  factory MovimientoStock.fromJson(Map<String, dynamic> json) {
    return MovimientoStock(
      id: json['id'] ?? '',
      localOrigenId: json['local_origen_id'] ?? '',
      localDestinoId: json['local_destino_id'] ?? '',
      estado: json['estado'] ?? 'PENDIENTE',
      fechaCreacion: json['fecha_creacion'] != null 
          ? DateTime.parse(json['fecha_creacion']) 
          : DateTime.now(),
      detalles: (json['detalles'] as List<dynamic>?)
          ?.map((detalle) => DetalleMovimiento.fromJson(detalle))
          .toList() ?? [],
    );
  }
}

class DetalleMovimiento {
  final String productoId;
  final int cantidad;

  DetalleMovimiento({
    required this.productoId,
    required this.cantidad,
  });

  factory DetalleMovimiento.fromJson(Map<String, dynamic> json) {
    return DetalleMovimiento(
      productoId: json['producto_id'] ?? '',
      cantidad: json['cantidad'] ?? 0,
    );
  }
}

// Constantes para los estados de movimientos
class EstadosMovimiento {
  static const String pendiente = 'PENDIENTE';
  static const String enProceso = 'EN_PROCESO';
  static const String enTransito = 'EN_TRANSITO';
  static const String entregado = 'ENTREGADO';
  static const String completado = 'COMPLETADO';
  static const String preparado = 'PREPARADO';
  static const String recibido = 'RECIBIDO';
}

class NotificacionMovimiento extends StatefulWidget {
  const NotificacionMovimiento({super.key});

  @override
  State<NotificacionMovimiento> createState() => _NotificacionMovimientoState();
}

class _NotificacionMovimientoState extends State<NotificacionMovimiento> {
  late final MovimientosApi _movimientosApi;
  bool _isLoading = false;
  List<MovimientoStock> _notificaciones = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _movimientosApi = api.movimientos;
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
        estado: EstadosMovimiento.pendiente,
      );
      
      if (!mounted) return;
      
      final List<MovimientoStock> movimientosList = [];
      for (var item in response) {
        movimientosList.add(MovimientoStock.fromJson(item));
      }
      
      setState(() {
        _notificaciones = movimientosList
            .where((m) => m.estado == EstadosMovimiento.pendiente || 
                        m.estado == EstadosMovimiento.preparado)
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


  List<MovimientoStock> get _movimientosPendientes => _notificaciones.where((m) => 
      m.estado == EstadosMovimiento.pendiente || 
      m.estado == EstadosMovimiento.preparado).toList();

  List<MovimientoStock> get _movimientosParaAprobar => _notificaciones.where((m) => 
      m.estado == EstadosMovimiento.recibido).toList();

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
                      : movimiento.estado == EstadosMovimiento.pendiente
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
      builder: (dialogContext) => AlertDialog(
        title: Text(
          movimiento.estado == EstadosMovimiento.pendiente
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
          if (movimiento.estado == EstadosMovimiento.pendiente)
            ElevatedButton(
              onPressed: () async {
                // Guardar una referencia al contexto del diálogo antes de la operación asíncrona
                final BuildContext dialogContextCopy = dialogContext;
                
                try {
                  await _movimientosApi.updateMovimiento(
                    movimiento.id,
                    {'estado': EstadosMovimiento.preparado},
                  );
                  
                  if (!mounted) return;
                  
                  // Usar la referencia guardada del contexto
                  if (dialogContextCopy.mounted) {
                    Navigator.of(dialogContextCopy).pop();
                  }
                  
                  await _cargarNotificaciones();
                } catch (e) {
                  if (!mounted) return;
                  
                  // Usar la referencia guardada del contexto
                  if (dialogContextCopy.mounted) {
                    ScaffoldMessenger.of(dialogContextCopy).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
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