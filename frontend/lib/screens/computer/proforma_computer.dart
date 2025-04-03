import 'dart:async';

import 'package:condorsmotors/models/proforma.model.dart';
import 'package:condorsmotors/providers/computer/index.computer.provider.dart';
import 'package:condorsmotors/providers/paginacion.provider.dart';
import 'package:condorsmotors/screens/computer/proforma_list.dart';
import 'package:condorsmotors/screens/computer/widgets/proforma/proforma_widget.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Pantalla principal para gestionar proformas en la versión de computadora
class ProformaComputerScreen extends StatefulWidget {
  final int? sucursalId;
  final String nombreSucursal;

  const ProformaComputerScreen({
    super.key,
    this.sucursalId,
    this.nombreSucursal = 'Sucursal',
  });

  @override
  ProformaComputerScreenState createState() => ProformaComputerScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('sucursalId', sucursalId))
      ..add(StringProperty('nombreSucursal', nombreSucursal));
  }
}

class ProformaComputerScreenState extends State<ProformaComputerScreen> {
  late ProformaComputerProvider _proformaProvider;
  final PaginacionProvider _paginacionProvider = PaginacionProvider();

  @override
  void initState() {
    super.initState();
    // Inicialización se hará en didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inicializar el provider
    _proformaProvider =
        Provider.of<ProformaComputerProvider>(context, listen: false);
    _initializeProvider();
  }

  /// Inicializa el provider con los datos necesarios
  Future<void> _initializeProvider() async {
    await _proformaProvider.initialize(widget.sucursalId);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _paginacionProvider),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          title: Consumer<ProformaComputerProvider>(
            builder: (context, provider, _) {
              return Row(
                children: [
                  Text('Gestión de Proformas - ${widget.nombreSucursal}'),
                  if (provider.hayNuevasProformas)
                    Padding(
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
                ],
              );
            },
          ),
          elevation: 0,
          actions: [
            // Información del temporizador
            Consumer<ProformaComputerProvider>(
              builder: (context, provider, _) {
                return Center(
                  child: Text(
                    'Actualización: ${provider.intervaloActualizacion}s',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),

            // Botón de recarga
            Consumer<ProformaComputerProvider>(
              builder: (context, provider, _) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () =>
                          provider.loadProformas(sucursalId: widget.sucursalId),
                      tooltip: 'Recargar proformas',
                    ),
                    if (provider.hayNuevasProformas)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 10,
                          height: 10,
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

            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // TODO: Implementar creación de nueva proforma
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Crear nueva proforma (pendiente)'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              tooltip: 'Nueva proforma',
            ),
          ],
        ),
        body: Consumer<ProformaComputerProvider>(
          builder: (context, provider, _) {
            if (provider.errorMessage != null) {
              return _buildErrorWidget(provider);
            }

            // Actualizar paginación desde el provider
            if (provider.paginacion != null) {
              _paginacionProvider.actualizarPaginacion(provider.paginacion!);
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lista de proformas (1/3 del ancho)
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.35,
                  child: Column(
                    children: [
                      // Badge de actualización en tiempo real
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: provider.hayNuevasProformas
                              ? Colors.red.withOpacity(0.2)
                              : const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              provider.hayNuevasProformas
                                  ? Icons.notifications_active
                                  : Icons.sync,
                              color: provider.hayNuevasProformas
                                  ? Colors.red
                                  : const Color(0xFF4CAF50),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              provider.hayNuevasProformas
                                  ? '¡Nuevas proformas detectadas!'
                                  : 'Actualizando en tiempo real',
                              style: TextStyle(
                                color: provider.hayNuevasProformas
                                    ? Colors.red
                                    : const Color(0xFF4CAF50),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

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
                              _handleDeleteProforma(provider.selectedProforma!);
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
            );
          },
        ),
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
  Future<void> _handleDeleteProforma(Proforma proforma) async {
    // Mostrar diálogo de confirmación
    final bool confirmado = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            backgroundColor: const Color(0xFF2D2D2D),
            title: const Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 10),
                Text(
                  'Eliminar proforma',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: Text(
              '¿Está seguro que desea eliminar la proforma #${proforma.id}?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmado) {
      try {
        final bool exito =
            await _proformaProvider.deleteProforma(proforma, widget.sucursalId);

        if (mounted) {
          if (exito) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Proforma eliminada correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al eliminar proforma'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        Logger.error('Error al eliminar proforma: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar proforma: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildErrorWidget(ProformaComputerProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            provider.errorMessage ?? 'Error desconocido',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                provider.loadProformas(sucursalId: widget.sucursalId),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('sucursalId', widget.sucursalId));
    properties.add(StringProperty('nombreSucursal', widget.nombreSucursal));
  }
}
