import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/proforma.model.dart';
import 'package:condorsmotors/repositories/proforma.repository.dart';
import 'package:condorsmotors/screens/computer/widgets/proforma/proforma_conversion_utils.dart';
import 'package:condorsmotors/screens/computer/widgets/proforma/proforma_utils.dart';
import 'package:condorsmotors/utils/ventas_utils.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget para mostrar una lista paginada de proformas
class ProformaListWidget extends StatefulWidget {
  final List<Proforma> proformas;
  final Function(Proforma) onProformaSelected;
  final Function(Proforma)? onConvertToSale;
  final Function(Proforma)? onDeleteProforma;
  final Future<void> Function()? onRefresh;
  final bool isLoading;
  final String emptyMessage;
  final Paginacion? paginacion;
  final Function(int)? onPageChanged;
  final bool compact;

  const ProformaListWidget({
    super.key,
    required this.proformas,
    required this.onProformaSelected,
    this.onConvertToSale,
    this.onDeleteProforma,
    this.onRefresh,
    this.isLoading = false,
    this.emptyMessage = 'No hay proformas disponibles',
    this.paginacion,
    this.onPageChanged,
    this.compact = false,
  });

  @override
  State<ProformaListWidget> createState() => _ProformaListWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Proforma>('proformas', proformas))
      ..add(ObjectFlagProperty<Function(Proforma)>.has(
          'onProformaSelected', onProformaSelected))
      ..add(ObjectFlagProperty<Function(Proforma)?>.has(
          'onConvertToSale', onConvertToSale))
      ..add(ObjectFlagProperty<Function(Proforma)?>.has(
          'onDeleteProforma', onDeleteProforma))
      ..add(ObjectFlagProperty<Future<void> Function()?>.has(
          'onRefresh', onRefresh))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(StringProperty('emptyMessage', emptyMessage))
      ..add(DiagnosticsProperty<Paginacion?>('paginacion', paginacion))
      ..add(ObjectFlagProperty<Function(int)?>.has(
          'onPageChanged', onPageChanged))
      ..add(DiagnosticsProperty<bool>('compact', compact));
  }
}

class _ProformaListWidgetState extends State<ProformaListWidget> {
  String _searchQuery = '';
  late TextEditingController _searchController;
  List<Proforma> _filteredProformas = [];
  bool _procesandoConversion = false;
  // Instancia del repositorio para acceder a las proformas
  final ProformaRepository _proformaRepository = ProformaRepository.instance;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredProformas = widget.proformas;

    // Suscribirse a cambios en el sistema de proformas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Recargar datos automáticamente al iniciar
      _recargarDatosProformas();
    });
  }

  @override
  void didUpdateWidget(ProformaListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proformas != widget.proformas) {
      _filterProformas();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Recarga los datos de proformas para mantener la lista actualizada
  Future<void> _recargarDatosProformas() async {
    try {
      // Verificar si estamos procesando o si el widget ya no está montado
      if (_procesandoConversion || !mounted) {
        return;
      }

      // Obtener sucursalId
      final int? sucursalId = await VentasPendientesUtils.obtenerSucursalId();
      if (sucursalId == null) {
        debugPrint('Error: No se pudo obtener el ID de sucursal');
        return;
      }

      // Invalidar caché de proformas usando el repositorio directamente
      if (mounted) {
        _proformaRepository.invalidateCache(sucursalId.toString());
      }

      // Si hay un método de recarga, utilizarlo
      if (widget.onRefresh != null && mounted) {
        await widget.onRefresh!();
      }
    } catch (e) {
      debugPrint('Error al recargar datos de proformas: $e');
    }
  }

  // Filtra las proformas según el término de búsqueda
  void _filterProformas() {
    if (!mounted) {
      return;
    }

    if (_searchQuery.isEmpty) {
      _filteredProformas = List.from(widget.proformas);
    } else {
      final String query = _searchQuery.toLowerCase();
      _filteredProformas = widget.proformas.where((Proforma proforma) {
        // Buscar en nombre, cliente, ID
        final String nombre = (proforma.nombre ?? '').toLowerCase();
        final String cliente = proforma.getNombreCliente().toLowerCase();
        final String id = proforma.id.toString();

        // Buscar en productos
        bool contieneProducto = false;
        for (final detalle in proforma.detalles) {
          if (detalle.nombre.toLowerCase().contains(query)) {
            contieneProducto = true;
            break;
          }
        }

        return nombre.contains(query) ||
            cliente.contains(query) ||
            id.contains(query) ||
            contieneProducto;
      }).toList();
    }

    if (mounted) {
      setState(() {});
    }
  }

  // Convertir proforma a venta con manejo de errores mejorado
  void _handleConvertToSale(Proforma proforma) {
    // Verificar si el widget aún está montado
    if (!mounted) {
      return;
    }

    if (_procesandoConversion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Ya hay una conversión en proceso. Espere a que termine.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar diálogo para confirmar y elegir tipo de documento
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => ProformaSaleDialog(
        proforma: proforma,
        onConfirm: (Map<String, dynamic> ventaData) async {
          Navigator.of(dialogContext)
              .pop(); // Cerrar diálogo de confirmación usando el contexto del diálogo

          // Verificar si el widget sigue montado después de cerrar el diálogo
          if (!mounted) {
            return;
          }

          // Marcar como procesando para evitar múltiples intentos
          setState(() {
            _procesandoConversion = true;
          });

          // Obtener tipo de documento de los datos
          final String tipoDocumento =
              ventaData['tipoDocumento'] as String? ?? 'BOLETA';

          // Obtener sucursalId
          final sucursalId = await VentasPendientesUtils.obtenerSucursalId();

          // Verificar nuevamente si el widget sigue montado
          if (!mounted) {
            return;
          }

          if (sucursalId == null) {
            setState(() {
              _procesandoConversion = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('No se pudo determinar la sucursal del usuario'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          // Invalidar caché antes de la conversión usando el repositorio
          _proformaRepository.invalidateCache(sucursalId.toString());

          // Verificar si el widget sigue montado para pasar el contexto adecuado
          bool exitoConversion = false;

          if (mounted) {
            // Si está montado, usamos el contexto actual
            exitoConversion =
                await ProformaConversionManager.convertirProformaAVenta(
              context: context,
              sucursalId: sucursalId.toString(),
              proformaId: proforma.id,
              tipoDocumento: tipoDocumento,
              onSuccess: () {
                // Verificar si el widget sigue montado antes de actualizar el estado
                if (!mounted) {
                  return;
                }

                // Actualizar estado
                setState(() {
                  _procesandoConversion = false;
                });

                // Llamar al callback externo si existe
                if (widget.onConvertToSale != null) {
                  widget.onConvertToSale!(proforma);
                }

                // Recargar datos si hay un método de recarga disponible
                if (widget.onRefresh != null) {
                  widget.onRefresh!();
                }
              },
            );
          } else {
            // Si ya no está montado, no podemos proceder adecuadamente
            debugPrint(
                'Widget desmontado durante la conversión, cancelando operación');
            return;
          }

          // Verificar si el widget sigue montado antes de actualizar el estado
          if (!mounted) {
            return;
          }

          if (!exitoConversion) {
            // El error ya fue mostrado en el gestor
            setState(() {
              _procesandoConversion = false;
            });
          }

          // Recargar datos siempre después de intentar la conversión
          if (mounted) {
            _recargarDatosProformas();
          }
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // Barra de búsqueda y controles
        if (!widget.compact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (String query) {
                      if (!mounted) {
                        return;
                      }

                      setState(() {
                        _searchQuery = query;
                      });
                      _filterProformas();
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar proformas...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white54),
                      fillColor: const Color(0xFF1A1A1A),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: Colors.white54),
                              onPressed: () {
                                if (!mounted) {
                                  return;
                                }

                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                                _filterProformas();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Refresh button
                if (widget.onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: widget.onRefresh,
                  ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Lista de proformas
        Expanded(
          child: widget.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredProformas.isEmpty
                  ? Center(
                      child: Text(
                        widget.emptyMessage,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: widget.onRefresh ?? () async {},
                      child: ListView.builder(
                        itemCount: _filteredProformas.length,
                        itemBuilder: (context, index) {
                          final Proforma proforma = _filteredProformas[index];
                          return _buildProformaItem(proforma);
                        },
                      ),
                    ),
        ),

        // Paginación
        if (widget.paginacion != null && widget.onPageChanged != null)
          _buildPagination(),
      ],
    );
  }

  Widget _buildProformaItem(Proforma proforma) {
    final bool puedeConvertirse = proforma.puedeConvertirseEnVenta();

    // Verificar si hay promociones en esta proforma
    final bool tieneDescuentos = proforma.detalles.any(_tieneDescuento);
    final bool tieneUnidadesGratis =
        proforma.detalles.any(_tieneUnidadesGratis);
    final bool tienePromociones = tieneDescuentos || tieneUnidadesGratis;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => widget.onProformaSelected(proforma),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              // Icono según el estado
              _buildStatusIcon(proforma.estado),
              const SizedBox(width: 16),

              // Información principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      // Limitamos el tamaño de la fila para evitar overflow
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            proforma.nombre ?? 'Proforma #${proforma.id}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (tienePromociones) ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: _obtenerMensajePromociones(proforma),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.5),
                                ),
                              ),
                              child: const Text(
                                'PROMO',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      proforma.getNombreCliente(),
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Creado: ${VentasPendientesUtils.formatearFecha(proforma.fechaCreacion)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                    if (proforma.fechaExpiracion != null)
                      Text(
                        'Expira: ${VentasPendientesUtils.formatearFecha(proforma.fechaExpiracion!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: proforma.haExpirado()
                              ? Colors.red
                              : Colors.white54,
                        ),
                      ),
                  ],
                ),
              ),

              // Precio total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    VentasUtils.formatearMonto(proforma.total),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${proforma.detalles.length} ${proforma.detalles.length == 1 ? 'item' : 'items'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                      if (tienePromociones) ...[
                        const Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                        const Icon(
                          Icons.local_offer,
                          size: 12,
                          color: Colors.orange,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Botones de acción
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (widget.onDeleteProforma != null)
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red, size: 20),
                          onPressed: () => widget.onDeleteProforma!(proforma),
                          tooltip: 'Eliminar proforma',
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                        ),
                      if (widget.onConvertToSale != null && puedeConvertirse)
                        IconButton(
                          icon: const Icon(Icons.shopping_cart,
                              color: Colors.green, size: 20),
                          onPressed: () => _handleConvertToSale(proforma),
                          tooltip: 'Convertir a venta',
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(EstadoProforma estado) {
    IconData icon;
    Color color;

    switch (estado) {
      case EstadoProforma.pendiente:
        icon = Icons.pending;
        color = Colors.blue;
        break;
      case EstadoProforma.convertida:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case EstadoProforma.cancelada:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case EstadoProforma.expirada:
        icon = Icons.timer_off;
        color = Colors.orange;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildPagination() {
    // Comprobar si hay paginación
    if (widget.paginacion == null || widget.onPageChanged == null) {
      return const SizedBox.shrink();
    }

    // Verificar que la paginación tiene los datos necesarios
    if (widget.paginacion!.totalPages <= 0) {
      return const SizedBox.shrink();
    }

    // Usar el widget Paginador que ya tiene soporte para PaginacionProvider
    // y acepta un objeto Paginacion directamente
    return Paginador(
      paginacion: widget.paginacion!,
      onPageChanged: widget.onPageChanged!,
      backgroundColor: const Color(0xFF2D2D2D),
      textColor: Colors.white,
      accentColor: const Color(0xFFE31E24),
      forceCompactMode: true,
      radius: 8.0,
    );
  }

  /// Verificar si un detalle de proforma tiene descuento
  bool _tieneDescuento(DetalleProforma detalle) {
    try {
      final dynamic descuento = (detalle as dynamic).descuento;
      return descuento != null && descuento > 0;
    } catch (e) {
      return false;
    }
  }

  /// Verificar si un detalle tiene unidades gratis
  bool _tieneUnidadesGratis(DetalleProforma detalle) {
    try {
      final dynamic cantidadGratis = (detalle as dynamic).cantidadGratis;
      return cantidadGratis != null && cantidadGratis > 0;
    } catch (e) {
      return false;
    }
  }

  /// Obtener un mensaje descriptivo sobre las promociones en la proforma
  String _obtenerMensajePromociones(Proforma proforma) {
    final List<String> mensajes = [];

    int productosConDescuento = 0;
    int productosConUnidadesGratis = 0;

    for (final detalle in proforma.detalles) {
      if (_tieneDescuento(detalle)) {
        productosConDescuento++;
      }
      if (_tieneUnidadesGratis(detalle)) {
        productosConUnidadesGratis++;
      }
    }

    if (productosConDescuento > 0) {
      mensajes.add('$productosConDescuento productos con descuento');
    }

    if (productosConUnidadesGratis > 0) {
      mensajes.add('$productosConUnidadesGratis productos con unidades gratis');
    }

    return mensajes.join('\n');
  }
}

/// Diálogo para confirmar la conversión de proforma a venta
class ProformaSaleDialog extends StatefulWidget {
  final Proforma proforma;
  final Function(Map<String, dynamic>) onConfirm;
  final VoidCallback onCancel;

  const ProformaSaleDialog({
    super.key,
    required this.proforma,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<ProformaSaleDialog> createState() => _ProformaSaleDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Proforma>('proforma', proforma))
      ..add(ObjectFlagProperty<Function(Map<String, dynamic> p1)>.has(
          'onConfirm', onConfirm))
      ..add(ObjectFlagProperty<VoidCallback>.has('onCancel', onCancel));
  }
}

class _ProformaSaleDialogState extends State<ProformaSaleDialog> {
  String _tipoDocumento = 'BOLETA';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.shopping_cart,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Convertir Proforma #${widget.proforma.id} a Venta',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Selector de tipo de documento
            const Text(
              'Tipo de Documento:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                _buildDocumentTypeButton('BOLETA'),
                const SizedBox(width: 16),
                _buildDocumentTypeButton('FACTURA'),
              ],
            ),

            const SizedBox(height: 24),

            // Resumen de la proforma
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Text(
                        'Cliente:',
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.proforma.getNombreCliente(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Detalles:',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final detalle in widget.proforma.detalles)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            flex: 5,
                            child: Text(
                              detalle.nombre,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${detalle.cantidad}x',
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              VentasUtils.formatearMontoTexto(
                                  detalle.precioUnitario),
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              VentasUtils.formatearMontoTexto(detalle.subtotal),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(color: Colors.white24),
                  Row(
                    children: <Widget>[
                      const Spacer(),
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        VentasUtils.formatearMontoTexto(widget.proforma.total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    final Map<String, dynamic> ventaData = {
                      'tipoDocumento': _tipoDocumento,
                      'productos': widget.proforma.detalles
                          .map((detalle) => {
                                'productoId': detalle.productoId,
                                'cantidad': detalle.cantidad,
                                'precio': detalle.precioUnitario,
                                'subtotal': detalle.subtotal,
                              })
                          .toList(),
                      'cliente': widget.proforma.cliente ??
                          {'nombre': widget.proforma.getNombreCliente()},
                      'metodoPago': 'EFECTIVO', // Por defecto
                      'total': widget.proforma.total,
                    };
                    widget.onConfirm(ventaData);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTypeButton(String tipo) {
    final bool isSelected = _tipoDocumento == tipo;

    return Flexible(
      fit: FlexFit.tight,
      child: InkWell(
        onTap: () {
          setState(() {
            _tipoDocumento = tipo;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4CAF50).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF4CAF50) : Colors.white24,
            ),
          ),
          child: Center(
            child: Text(
              tipo,
              style: TextStyle(
                color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Proforma>('proforma', widget.proforma))
      ..add(ObjectFlagProperty<Function(Map<String, dynamic>)>.has(
          'onConfirm', widget.onConfirm))
      ..add(ObjectFlagProperty<VoidCallback>.has('onCancel', widget.onCancel))
      ..add(StringProperty('_tipoDocumento', _tipoDocumento));
  }
}

/// Diálogo de procesamiento para mostrar durante operaciones
class ProcessingDialog extends StatelessWidget {
  final String documentType;

  const ProcessingDialog({
    super.key,
    required this.documentType,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Procesando $documentType...',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Por favor espere',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('documentType', documentType));
  }
}
