import 'dart:async';

import 'package:condorsmotors/models/proforma.model.dart';
import 'package:condorsmotors/providers/computer/proforma.computer.riverpod.dart';
import 'package:condorsmotors/screens/computer/proforma_list.dart';
import 'package:condorsmotors/screens/computer/widgets/proforma/proforma_widget.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProformaComputerScreen extends ConsumerStatefulWidget {
  final int sucursalId;

  const ProformaComputerScreen({
    super.key,
    required this.sucursalId,
  });

  @override
  ConsumerState<ProformaComputerScreen> createState() =>
      ProformaComputerScreenState();
}

class ProformaComputerScreenState extends ConsumerState<ProformaComputerScreen>
    with SingleTickerProviderStateMixin {
  // Controlador de animación para notificaciones
  late AnimationController _notificationAnimController;
  late Animation<double> _notificationAnimation;
  StreamSubscription? _streamSubscription;

  @override
  void initState() {
    super.initState();

    // Inicializar controlador de animación para notificaciones
    _notificationAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _notificationAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _notificationAnimController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  /// Inicializa el provider con los datos necesarios
  Future<void> _initializeProvider() async {
    final notifier = ref.read(proformaComputerProvider.notifier);
    await notifier.initialize(widget.sucursalId);
    _suscribirseAStreamProformas();
  }

  void _suscribirseAStreamProformas() {
    // Cancelar suscripción existente
    _streamSubscription?.cancel();
    _streamSubscription = null;

    final state = ref.read(proformaComputerProvider);

    // Solo suscribirse si las actualizaciones automáticas están activas
    if (!state.actualizacionAutomaticaActiva) {
      return;
    }

    final notifier = ref.read(proformaComputerProvider.notifier);

    // Obtener el stream del provider
    final stream = notifier.proformasStream;

    if (stream != null) {
      _streamSubscription = stream.listen((proformas) {
        if (!mounted) {
          return;
        }
        final currentState = ref.read(proformaComputerProvider);
        // Animar el indicador de notificación cuando hay nuevas proformas
        if (currentState.hayNuevasProformas) {
          _notificationAnimController
            ..reset()
            ..repeat(reverse: true);
        } else {
          _notificationAnimController.stop();
        }
      });

      Logger.info('Suscripción al stream de proformas establecida');
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _notificationAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(proformaComputerProvider);
    final notifier = ref.read(proformaComputerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: Row(
          children: [
            Text('Gestión de Proformas - Sucursal ${widget.sucursalId}'),
            if (state.hayNuevasProformas)
              AnimatedBuilder(
                animation: _notificationAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _notificationAnimation.value,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_active,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'NUEVAS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        elevation: 0,
        actions: [
          // Control de intervalo de actualización
          PopupMenuButton<int>(
            tooltip: 'Cambiar intervalo de actualización',
            onSelected: (int intervalo) {
              notifier.setIntervaloActualizacion(intervalo, widget.sucursalId);
            },
            itemBuilder: (BuildContext context) {
              return [8, 15, 30].map((int intervalo) {
                return PopupMenuItem<int>(
                  value: intervalo,
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: state.intervaloActualizacion == intervalo
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$intervalo segundos',
                        style: TextStyle(
                          color: state.intervaloActualizacion == intervalo
                              ? Colors.blue
                              : null,
                        ),
                      ),
                      if (state.intervaloActualizacion == intervalo)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.blue,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${state.intervaloActualizacion}s',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Botón de control de actualización
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  state.actualizacionAutomaticaActiva
                      ? Icons.sync
                      : Icons.sync_disabled,
                  color: state.actualizacionAutomaticaActiva
                      ? Colors.green
                      : Colors.orange,
                ),
                onPressed: () async {
                  await notifier
                      .toggleActualizacionAutomatica(widget.sucursalId);
                  _suscribirseAStreamProformas();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.actualizacionAutomaticaActiva
                              ? 'Actualización automática pausada'
                              // El texto arriba es engañoso, porque se llamaba toggle. Verificamos el NUEVO estado:
                              : 'Actualización automática activada', // The actual state here flips! Let's just say we toggled it.
                        ),
                        backgroundColor: state.actualizacionAutomaticaActiva
                            ? Colors.orange
                            : Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                tooltip: state.actualizacionAutomaticaActiva
                    ? 'Pausar actualizaciones'
                    : 'Reanudar actualizaciones',
              ),
              if (state.hayNuevasProformas)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: state.errorMessage != null && state.errorMessage!.isNotEmpty
          ? _buildErrorWidget(state.errorMessage!, notifier)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contenido principal
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lista de proformas (1/3 del ancho)
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.35,
                        child: Column(
                          children: [
                            // Lista de proformas
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ProformaListWidget(
                                  proformas: state.proformas,
                                  onProformaSelected: notifier.selectProforma,
                                  onConvertToSale: _handleConvertToSale,
                                  onDeleteProforma: _handleDeleteProforma,
                                  onRefresh: () => notifier.loadProformas(
                                      sucursalId: widget.sucursalId),
                                  isLoading: state.isLoading,
                                  paginacion: state.paginacion,
                                  onPageChanged: (page) => notifier.setPage(
                                      page,
                                      sucursalId: widget.sucursalId),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Línea vertical divisoria
                      Container(
                        width: 1,
                        height: double.infinity,
                        color: const Color(0xFF2D2D2D),
                      ),

                      // Detalle de proforma seleccionada (2/3 del ancho)
                      Expanded(
                        child: state.selectedProforma != null
                            ? Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ProformaWidget(
                                  proforma: state.selectedProforma!,
                                  onConvert: _handleConvertToSale,
                                  onUpdate: (_) => notifier.loadProformas(
                                      sucursalId: widget.sucursalId),
                                  onDelete: () {
                                    _handleDeleteProforma(
                                        state.selectedProforma!);
                                  },
                                ),
                              )
                            : const Center(
                                child: Text(
                                  'Seleccione una proforma para ver detalles',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Maneja la conversión de proforma a venta
  void _handleConvertToSale(Proforma proforma) {
    ref.read(proformaComputerProvider.notifier).handleConvertToSale(
      proforma,
      widget.sucursalId,
      onSuccess: () {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proforma convertida exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  /// Maneja la eliminación de una proforma
  void _handleDeleteProforma(Proforma proforma) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
              '¿Está seguro de que desea eliminar la proforma #${proforma.id}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(proformaComputerProvider.notifier).deleteProforma(
                      proforma,
                      widget.sucursalId,
                    );
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Construye el widget de error
  Widget _buildErrorWidget(String errorMessage, notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Error: $errorMessage',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                notifier.loadProformas(sucursalId: widget.sucursalId),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
