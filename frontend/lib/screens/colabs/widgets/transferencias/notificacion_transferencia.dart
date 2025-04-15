import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/repositories/transferencia.repository.dart';
import 'package:flutter/material.dart';

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
      estado: json['estado'] ?? EstadoTransferencia.pedido.codigo,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : DateTime.now(),
      detalles: (json['detalles'] as List<dynamic>?)
              ?.map((detalle) => DetalleMovimiento.fromJson(detalle))
              .toList() ??
          <DetalleMovimiento>[],
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
  late final TransferenciaRepository _transferenciaRepository;
  bool _isLoading = false;
  List<TransferenciaInventario> _notificaciones = <TransferenciaInventario>[];
  String? _error;

  @override
  void initState() {
    super.initState();
    _transferenciaRepository = TransferenciaRepository.instance;
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final paginatedResponse =
          await _transferenciaRepository.getTransferencias(
        estado: EstadoTransferencia.pedido.codigo,
        pageSize:
            50, // Ajustamos el tamaño de página para obtener más resultados
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _notificaciones = paginatedResponse.items
            .where((t) =>
                t.estado == EstadoTransferencia.pedido ||
                t.estado == EstadoTransferencia.enviado)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

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

  List<TransferenciaInventario> get _transferenciasEnProceso => _notificaciones
      .where((t) =>
          t.estado == EstadoTransferencia.pedido ||
          t.estado == EstadoTransferencia.enviado)
      .toList();

  List<TransferenciaInventario> get _transferenciasParaAprobar =>
      _notificaciones
          .where((t) => t.estado == EstadoTransferencia.recibido)
          .toList();

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
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
              children: <Widget>[
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
        else ...<PopupMenuEntry<String>>[
          if (_transferenciasEnProceso.isNotEmpty) ...<PopupMenuEntry<String>>[
            const PopupMenuItem(
              enabled: false,
              child: Text(
                'En Proceso',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ..._transferenciasEnProceso.map((t) => PopupMenuItem(
                  child: _construirItemNotificacion(t),
                  onTap: () => _mostrarDetallesTransferencia(context, t),
                )),
          ],
          if (_transferenciasParaAprobar
              .isNotEmpty) ...<PopupMenuEntry<String>>[
            const PopupMenuItem(
              enabled: false,
              child: Text(
                'Para Aprobar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ..._transferenciasParaAprobar.map((t) => PopupMenuItem(
                  child: _construirItemNotificacion(t, paraAprobar: true),
                  onTap: () => _mostrarDetallesTransferencia(context, t),
                )),
          ],
        ],
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: _cargarNotificaciones,
          child: const Row(
            children: <Widget>[
              Icon(Icons.refresh),
              SizedBox(width: 8),
              Text('Actualizar'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirItemNotificacion(TransferenciaInventario transferencia,
      {bool paraAprobar = false}) {
    final Color color =
        paraAprobar ? const Color(0xFF43A047) : const Color(0xFFD32F2F);

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
        children: <Widget>[
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
              children: <Widget>[
                Text(
                  paraAprobar
                      ? 'Transferencia para aprobar'
                      : transferencia.estado == EstadoTransferencia.pedido
                          ? 'Nueva solicitud de productos'
                          : 'Productos listos para envío',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF424242),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                if (transferencia.productos != null)
                  Text(
                    'Detalles: ${transferencia.productos!.length} productos',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF757575),
                    ),
                  ),
                Text(
                  'De: ${transferencia.nombreSucursalOrigen} → A: ${transferencia.nombreSucursalDestino}',
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

  void _mostrarDetallesTransferencia(
      BuildContext context, TransferenciaInventario transferencia) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          transferencia.estado == EstadoTransferencia.pedido
              ? 'Nueva Solicitud de Productos'
              : 'Productos Listos para Envío',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (transferencia.productos != null)
              Text('Detalles: ${transferencia.productos!.length} productos'),
            Text('Origen: ${transferencia.nombreSucursalOrigen}'),
            Text('Destino: ${transferencia.nombreSucursalDestino}'),
            Text('Estado: ${transferencia.estado.nombre}'),
            if (transferencia.salidaOrigen != null)
              Text('Fecha: ${_formatearFecha(transferencia.salidaOrigen!)}'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
          if (transferencia.estado == EstadoTransferencia.pedido)
            ElevatedButton(
              onPressed: () async {
                final BuildContext dialogContextCopy = dialogContext;

                try {
                  if (transferencia.sucursalOrigenId == null) {
                    throw Exception(
                        'No se ha establecido la sucursal de origen');
                  }

                  await _transferenciaRepository.enviarTransferencia(
                    transferencia.id.toString(),
                    sucursalOrigenId: transferencia.sucursalOrigenId!,
                  );

                  if (!mounted) {
                    return;
                  }

                  if (dialogContextCopy.mounted) {
                    Navigator.of(dialogContextCopy).pop();
                  }

                  await _cargarNotificaciones();
                } catch (e) {
                  if (!mounted) {
                    return;
                  }

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
              child: const Text('Marcar Como Enviado'),
            ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}
