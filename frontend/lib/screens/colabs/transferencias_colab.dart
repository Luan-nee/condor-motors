import 'dart:async';

import 'package:condorsmotors/components/transferencia_notificacion.dart';
import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/providers/colabs/transferencias.colab.provider.dart';
import 'package:condorsmotors/repositories/transferencia.repository.dart';
import 'package:condorsmotors/screens/colabs/widgets/transferencias/transferencia_detalle_colab.dart';
import 'package:condorsmotors/screens/colabs/widgets/transferencias/transferencia_form_colab.dart';
import 'package:condorsmotors/utils/transferencias_utils.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransferenciasColabScreen extends StatefulWidget {
  const TransferenciasColabScreen({super.key});

  @override
  State<TransferenciasColabScreen> createState() =>
      _TransferenciasColabScreenState();
}

class _TransferenciasColabScreenState extends State<TransferenciasColabScreen>
    with WidgetsBindingObserver {
  late final TransferenciasColabProvider _provider;
  Timer? _pollingTimer;
  int? _ultimoIdTransferenciaRecibida;
  Duration _pollingInterval = const Duration(minutes: 1);

  final TransferenciaRepository _repository = TransferenciaRepository.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _provider = context.read<TransferenciasColabProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initData();
      _initPolling();
      _cargarTransferenciasPaginadas();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _setPollingInterval(const Duration(minutes: 5));
    } else if (state == AppLifecycleState.resumed) {
      _setPollingInterval(const Duration(minutes: 1));
    }
  }

  void _setPollingInterval(Duration interval) {
    if (_pollingInterval != interval) {
      _pollingInterval = interval;
      _pollingTimer?.cancel();
      _initPolling();
    }
  }

  Future<void> _initData() async {
    await _provider.inicializar();
    await TransferenciaNotificacion.initTransferenciaNotifications(
      onSelect: (payload) {
        if (payload != null && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TransferenciaDetalleColab(
                transferenciaid:
                    payload['id'] != null ? payload['id'].toString() : '',
              ),
            ),
          );
        }
      },
    );
    await _cargarUltimoIdTransferencia();
    await _cargarUltimoIdTransferenciaEnviada();
  }

  Future<void> _cargarUltimoIdTransferencia() async {
    final prefs = await SharedPreferences.getInstance();
    _ultimoIdTransferenciaRecibida =
        prefs.getInt('ultimo_id_transferencia_recibida');
    debugPrint(
        '[Polling] Cargado último ID de transferencia recibida: \\$_ultimoIdTransferenciaRecibida');
  }

  Future<void> _cargarUltimoIdTransferenciaEnviada() async {}

  Future<void> _guardarUltimoIdTransferencia(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ultimo_id_transferencia_recibida', id);
    _ultimoIdTransferenciaRecibida = id;
    debugPrint('[Polling] Guardado último ID de transferencia recibida: $id');
  }

  void _initPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) async {
      debugPrint('--- [Polling] Ejecutando polling de transferencias ---');
      final prefs = await SharedPreferences.getInstance();
      final notificacionesActivas =
          prefs.getBool('notificaciones_transferencias') ?? true;
      debugPrint('[Polling] Notificaciones activas: $notificacionesActivas');
      if (!notificacionesActivas) {
        debugPrint('[Polling] Notificaciones desactivadas, saliendo...');
        return;
      }
      try {
        await _notificarTransferenciaMasReciente();
      } catch (e, stack) {
        debugPrint('[Polling] Error en polling: \\$e');
        debugPrint('[Polling] Stacktrace: \\$stack');
      }
      debugPrint('--- [Polling] Fin de ciclo ---');
    });
  }

  /// Notifica la transferencia más reciente según el filtro de estado (o todas si es null)
  Future<void> _notificarTransferenciaMasReciente({String? estado}) async {
    final result = await _repository.getTransferencias(
      estado: estado, // Puede ser null para traer todas
      sortBy: 'id',
      order: 'desc',
      page: 1,
      pageSize: 1,
      forceRefresh: true,
    );
    final transferencia = result.items.isNotEmpty ? result.items.first : null;
    if (transferencia != null &&
        (_ultimoIdTransferenciaRecibida == null ||
            transferencia.id > _ultimoIdTransferenciaRecibida!)) {
      final bool esPedido = transferencia.estado == EstadoTransferencia.pedido;
      final String sucursalSolicitante = esPedido
          ? (transferencia.nombreSucursalDestino)
          : (transferencia.nombreSucursalOrigen ?? 'Sucursal desconocida');
      final int cantidadProductos = transferencia.productos?.length ?? 0;
      debugPrint(
          '[Polling] Notificación: $sucursalSolicitante solicita $cantidadProductos producto${cantidadProductos == 1 ? '' : 's'}');
      if (esPedido) {
        await TransferenciaNotificacion.showTransferenciaPedido(transferencia,
            sucursalSolicitante: sucursalSolicitante);
      } else if (transferencia.estado == EstadoTransferencia.enviado) {
        await TransferenciaNotificacion.showTransferenciaEnviada(transferencia,
            sucursalSolicitante: sucursalSolicitante);
      }
      await _guardarUltimoIdTransferencia(transferencia.id);
    }
  }

  Future<void> _cargarTransferenciasPaginadas() async {
    try {
      setState(() {
        _provider.cargarTransferencias(forceRefresh: true);
      });
    } catch (e) {
      // El manejo de errores lo hace el provider
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransferenciasColabProvider>(
      builder: (context, provider, child) {
        final transferencias = provider.getTransferenciasFiltradas();

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2D2D2D),
            title: const Text(
              'Transferencias',
              style: TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: <Widget>[
              Theme(
                data: Theme.of(context).copyWith(
                  popupMenuTheme: PopupMenuThemeData(
                    color: const Color(0xFF2D2D2D),
                    textStyle: const TextStyle(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                child: PopupMenuButton<String>(
                  icon: Stack(
                    children: <Widget>[
                      const Icon(Icons.filter_list, color: Colors.white),
                      if (provider.selectedFilter != 'Todos')
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE31E24),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                  tooltip: 'Filtrar por estado',
                  itemBuilder: (BuildContext context) =>
                      provider.filters.map((String filter) {
                    final bool isSelected = provider.selectedFilter == filter;
                    Color? stateColor;
                    if (filter != 'Todos') {
                      final estado = EstadoTransferencia.values.firstWhere(
                        (e) => e.nombre == filter,
                        orElse: () => EstadoTransferencia.pedido,
                      );
                      stateColor = _getEstadoColor(estado);
                    }

                    return PopupMenuItem<String>(
                      value: filter,
                      child: Row(
                        children: <Widget>[
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(Icons.check,
                                  size: 18, color: Colors.white),
                            ),
                          if (stateColor != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: stateColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          Text(filter),
                        ],
                      ),
                    );
                  }).toList(),
                  onSelected: (String filter) {
                    provider.cambiarFiltro(filter);
                  },
                ),
              ),
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.arrowsRotate,
                  color: Colors.white,
                ),
                onPressed: () =>
                    provider.cargarTransferencias(forceRefresh: true),
                tooltip: 'Recargar',
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.errorMessage != null
                        ? Center(child: Text('Error: ${provider.errorMessage}'))
                        : transferencias.isEmpty
                            ? const Center(
                                child:
                                    Text('No hay transferencias disponibles'))
                            : ListView.builder(
                                itemCount: transferencias.length,
                                itemBuilder: (context, index) {
                                  final transferencia = transferencias[index];
                                  return _buildTransferenciaCard(
                                    transferencia,
                                    MediaQuery.of(context).size.width < 600,
                                    provider,
                                  );
                                },
                              ),
              ),
              if (provider.paginacion != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Paginador(
                    paginacion: provider.paginacion!,
                    onPageChanged: (page) => provider.cambiarPagina(page),
                    onPageSizeChanged: (size) =>
                        provider.cambiarTamanoPagina(size),
                  ),
                ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: FloatingActionButton(
              onPressed: () => _showCreateTransferenciaDialog(context),
              backgroundColor: const Color(0xFFE31E24),
              tooltip: 'Nueva transferencia',
              child: const FaIcon(FontAwesomeIcons.plus),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransferenciaCard(
    TransferenciaInventario transferencia,
    bool isMobile,
    TransferenciasColabProvider provider,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        TransferenciasUtils.getEstadoColor(transferencia.estado)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FaIcon(
                    TransferenciasUtils.getEstadoIcon(transferencia.estado),
                    color: TransferenciasUtils.getEstadoColor(
                        transferencia.estado),
                    size: isMobile ? 16 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            'TRF${transferencia.id}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: TransferenciasUtils.getEstadoColor(
                                      transferencia.estado)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              transferencia.estado.nombre,
                              style: TextStyle(
                                color: TransferenciasUtils.getEstadoColor(
                                    transferencia.estado),
                                fontSize: isMobile ? 10 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sucursal Destino: ${transferencia.nombreSucursalDestino}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                                if (transferencia.nombreSucursalOrigen != null)
                                  Text(
                                    'Sucursal Origen: ${transferencia.nombreSucursalOrigen}',
                                    style: TextStyle(
                                      color: const Color(0xFF43A047),
                                      fontSize: isMobile ? 12 : 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                Text(
                                  'Creado: ${_formatDateTime(transferencia.fechaCreacion)}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: isMobile ? 11 : 12,
                                  ),
                                ),
                                Text(
                                  'Actualizado: ${_formatDateTime(transferencia.fechaActualizacion)}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: isMobile ? 11 : 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (transferencia.productos != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: TransferenciasUtils
                                  .getProductCountBadgeStyle(),
                              child: Text(
                                '${transferencia.productos!.length} productos',
                                style: const TextStyle(
                                  color: Color(0xFFE31E24),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                MouseRegion(
                  child: IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.eye,
                      color: Colors.white70,
                      size: 18,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransferenciaDetalleColab(
                            transferenciaid: transferencia.id.toString(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (transferencia.estado == EstadoTransferencia.enviado &&
                    _provider.sucursalId != null &&
                    transferencia.sucursalDestinoId.toString() ==
                        _provider.sucursalId)
                  ElevatedButton.icon(
                    onPressed: () => _showValidationDialog(transferencia),
                    icon: FaIcon(FontAwesomeIcons.check,
                        size: isMobile ? 14 : 16),
                    label: Text(
                      'Validar',
                      style: TextStyle(fontSize: isMobile ? 12 : 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 16,
                        vertical: isMobile ? 4 : 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1A1A1A), height: 1),
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: _buildTimeline(transferencia, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(TransferenciaInventario transferencia, bool isMobile) {
    final steps = TransferenciasUtils.getTransferenciaSteps(transferencia);
    final double iconSize = isMobile ? 16 : 20;
    final double fontSize = isMobile ? 12 : 14;
    final double containerSize = isMobile ? 36 : 44;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: steps.asMap().entries.map((entry) {
          final int index = entry.key;
          final Map<String, dynamic> step = entry.value;
          final bool isLast = index == steps.length - 1;
          final DateTime? date = step['date'] as DateTime?;
          final String? formattedDate =
              date != null ? '${date.day}/${date.month}/${date.year}' : null;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: containerSize,
                            height: containerSize,
                            decoration: BoxDecoration(
                              color: step['isCompleted'] as bool
                                  ? (step['color'] as Color).withValues(alpha: 0.1)
                                  : const Color(0xFF1A1A1A),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: step['isCompleted'] as bool
                                    ? step['color'] as Color
                                    : Colors.grey[800]!,
                                width: 2,
                              ),
                            ),
                          ),
                          FaIcon(
                            step['icon'] as IconData,
                            size: iconSize,
                            color: step['isCompleted'] as bool
                                ? step['color'] as Color
                                : Colors.grey[600],
                          ),
                          if (step['isCompleted'] as bool)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: step['color'] as Color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF1A1A1A),
                                    width: 2,
                                  ),
                                ),
                                child: FaIcon(
                                  FontAwesomeIcons.check,
                                  size: iconSize * 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step['title'] as String,
                        style: TextStyle(
                          color: step['isCompleted'] as bool
                              ? Colors.white
                              : Colors.grey[600],
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        step['subtitle'] as String,
                        style: TextStyle(
                          color: step['isCompleted'] as bool
                              ? Colors.grey[400]
                              : Colors.grey[700],
                          fontSize: fontSize - 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (formattedDate != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (step['color'] as Color).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            formattedDate,
                            style: TextStyle(
                              color: step['color'] as Color,
                              fontSize: fontSize - 2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: step['isCompleted'] as bool
                          ? step['color'] as Color
                          : Colors.grey[800],
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showValidationDialog(TransferenciaInventario transferencia) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          title: const Row(
            children: [
              FaIcon(
                FontAwesomeIcons.circleInfo,
                color: Color(0xFFE31E24),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Validación de Transferencia',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Está seguro que desea validar la recepción de esta transferencia?',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                'TRF${transferencia.id} - ${transferencia.nombreSucursalOrigen ?? "Desconocido"} → ${transferencia.nombreSucursalDestino}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Esta acción confirmará que todos los productos han sido recibidos correctamente y actualizará el inventario.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            Consumer<TransferenciasColabProvider>(
                builder: (context, provider, child) {
              return ElevatedButton(
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        try {
                          // Usar directamente el provider y mostrar el estado de carga
                          await provider.validarRecepcion(transferencia);

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Transferencia recibida correctamente'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Error al recibir transferencia: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF43A047),
                  foregroundColor: Colors.white,
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Confirmar Recepción'),
              );
            }),
          ],
        );
      },
    );
  }

  Color _getEstadoColor(EstadoTransferencia estado) {
    return TransferenciasUtils.getEstadoColor(estado);
  }

  Future<void> _showCreateTransferenciaDialog(BuildContext context) async {
    if (_provider.sucursalId == null || _provider.empleadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo obtener información del usuario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final BuildContext dialogContext = context;
    showDialog(
      context: dialogContext,
      builder: (BuildContext context) => TransferenciaFormColab(
        onSave: (int sucursalDestino, List<DetalleProducto> productos) async {
          try {
            final bool success = await _provider.crearTransferencia(
              sucursalDestino,
              productos,
            );

            if (context.mounted) {
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Transferencia creada exitosamente'
                        : 'Error al crear la transferencia',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al crear transferencia: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        sucursalId: _provider.sucursalId!,
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'N/A';
    }
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
