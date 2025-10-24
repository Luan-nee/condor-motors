import 'dart:async';

import 'package:condorsmotors/models/proforma.model.dart';
import 'package:condorsmotors/providers/computer/proforma.computer.provider.dart';
import 'package:condorsmotors/screens/computer/proforma_list.dart';
import 'package:condorsmotors/screens/computer/widgets/proforma/proforma_widget.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProformaComputerScreen extends StatefulWidget {
  final int sucursalId;

  const ProformaComputerScreen({
    super.key,
    required this.sucursalId,
  });

  @override
  State<ProformaComputerScreen> createState() => ProformaComputerScreenState();
}

class ProformaComputerScreenState extends State<ProformaComputerScreen>
    with SingleTickerProviderStateMixin {
  late ProformaComputerProvider _proformaProvider;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Inicializar el provider
    _proformaProvider =
        Provider.of<ProformaComputerProvider>(context, listen: false);
    _initializeProvider();

    // Configurar suscripción al stream
    _suscribirseAStreamProformas();
  }

  void _suscribirseAStreamProformas() {
    // Cancelar suscripción existente
    _streamSubscription?.cancel();
    _streamSubscription = null;

    // Solo suscribirse si las actualizaciones automáticas están activas
    if (!_proformaProvider.actualizacionAutomaticaActiva) {
      return;
    }

    // Obtener el stream del provider
    final stream = _proformaProvider.proformasStream;

    if (stream != null) {
      _streamSubscription = stream.listen((proformas) {
        if (!mounted) {
          return;
        }
        // Animar el indicador de notificación cuando hay nuevas proformas
        if (_proformaProvider.hayNuevasProformas) {
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

  /// Inicializa el provider con los datos necesarios
  Future<void> _initializeProvider() async {
    await _proformaProvider.initialize(widget.sucursalId);
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _notificationAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: Consumer<ProformaComputerProvider>(
          builder: (context, provider, _) {
            return Row(
              children: [
                Text('Gestión de Proformas - Sucursal ${widget.sucursalId}'),
                if (provider.hayNuevasProformas)
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
            );
          },
        ),
        elevation: 0,
        actions: [
          // Control de intervalo de actualización
          Consumer<ProformaComputerProvider>(
            builder: (context, provider, _) {
              return PopupMenuButton<int>(
                tooltip: 'Cambiar intervalo de actualización',
                onSelected: (int intervalo) {
                  provider.setIntervaloActualizacion(
                      intervalo, widget.sucursalId);
                },
                itemBuilder: (BuildContext context) {
                  return ProformaComputerProvider.intervalosDisponibles
                      .map((int intervalo) {
                    return PopupMenuItem<int>(
                      value: intervalo,
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer,
                            size: 16,
                            color: provider.intervaloActualizacion == intervalo
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$intervalo segundos',
                            style: TextStyle(
                              color:
                                  provider.intervaloActualizacion == intervalo
                                      ? Colors.blue
                                      : null,
                            ),
                          ),
                          if (provider.intervaloActualizacion == intervalo)
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${provider.intervaloActualizacion}s',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 16),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // Botón de control de actualización
          Consumer<ProformaComputerProvider>(
            builder: (context, provider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      provider.actualizacionAutomaticaActiva
                          ? Icons.sync
                          : Icons.sync_disabled,
                      color: provider.actualizacionAutomaticaActiva
                          ? Colors.green
                          : Colors.orange,
                    ),
                    onPressed: () async {
                      await provider
                          .toggleActualizacionAutomatica(widget.sucursalId);
                      _suscribirseAStreamProformas();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              provider.actualizacionAutomaticaActiva
                                  ? 'Actualización automática activada'
                                  : 'Actualización automática pausada',
                            ),
                            backgroundColor:
                                provider.actualizacionAutomaticaActiva
                                    ? Colors.green
                                    : Colors.orange,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    tooltip: provider.actualizacionAutomaticaActiva
                        ? 'Pausar actualizaciones'
                        : 'Reanudar actualizaciones',
                  ),
                  if (provider.hayNuevasProformas)
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
              );
            },
          ),
        ],
      ),
      body: Consumer<ProformaComputerProvider>(
        builder: (context, provider, _) {
          if (provider.errorMessage != null) {
            return _buildErrorWidget(provider);
          }

          return Column(
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
                                proformas: provider.proformas,
                                onProformaSelected: provider.selectProforma,
                                onConvertToSale: _handleConvertToSale,
                                onDeleteProforma: _handleDeleteProforma,
                                onRefresh: () => provider.loadProformas(
                                    sucursalId: widget.sucursalId),
                                isLoading: provider.isLoading,
                                paginacion: provider.paginacion,
                                onPageChanged: (page) => provider.setPage(page,
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
                      child: provider.selectedProforma != null
                          ? Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ProformaWidget(
                                proforma: provider.selectedProforma!,
                                onConvert: _handleConvertToSale,
                                onUpdate: (_) => provider.loadProformas(
                                    sucursalId: widget.sucursalId),
                                onDelete: () {
                                  _handleDeleteProforma(
                                      provider.selectedProforma!);
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
          );
        },
      ),
    );
  }

  /// Maneja la conversión de proforma a venta
  void _handleConvertToSale(Proforma proforma) {
    _proformaProvider.handleConvertToSale(
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
                _proformaProvider.deleteProforma(
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
  Widget _buildErrorWidget(ProformaComputerProvider provider) {
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
            'Error: ${provider.errorMessage}',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                provider.loadProformas(sucursalId: widget.sucursalId),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
