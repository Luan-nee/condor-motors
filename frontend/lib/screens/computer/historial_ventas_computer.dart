import 'package:condorsmotors/models/ventas.model.dart';
import 'package:condorsmotors/providers/computer/ventas.computer.provider.dart';
import 'package:condorsmotors/repositories/venta.repository.dart';
import 'package:condorsmotors/screens/admin/widgets/venta/venta_detalle_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Widget para mostrar la lista de ventas
class VentasListComputer extends StatelessWidget {
  final List<Venta> ventas;
  final bool isLoading;
  final Function(Venta) onAnularVenta;
  final VoidCallback onRecargarVentas;

  const VentasListComputer({
    super.key,
    required this.ventas,
    required this.isLoading,
    required this.onAnularVenta,
    required this.onRecargarVentas,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (ventas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.boxOpen,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay ventas para mostrar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta ajustar los filtros de búsqueda',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRecargarVentas,
              icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 14),
              label: const Text('Recargar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31E24),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: ventas.length,
      itemBuilder: (context, index) {
        final venta = ventas[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(
              'Venta #${venta.id} - ${venta.serieDocumento}-${venta.numeroDocumento}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cliente: ${venta.clienteDetalle?.denominacion ?? "No especificado"}',
                ),
                Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(venta.fechaCreacion)}',
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  NumberFormat.currency(
                    symbol: 'S/',
                    decimalDigits: 2,
                  ).format(venta.calcularTotal()),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 16),
                _buildEstadoChip(venta.estado),
                if (!venta.anulada && !venta.declarada)
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.ban),
                    onPressed: () => onAnularVenta(venta),
                    tooltip: 'Anular venta',
                  ),
              ],
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => VentaDetalleDialog(
                  venta: venta,
                  onDeclararPressed: venta.estado == EstadoVenta.pendiente
                      ? (_) => onAnularVenta(venta)
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEstadoChip(EstadoVenta estado) {
    Color color;
    Color textColor = Colors.white;

    switch (estado) {
      case EstadoVenta.pendiente:
        color = Colors.orange;
        break;
      case EstadoVenta.completada:
        color = Colors.green;
        break;
      case EstadoVenta.anulada:
        color = Colors.red;
        break;
      case EstadoVenta.declarada:
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado.toText(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Venta>('ventas', ventas))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(ObjectFlagProperty<Function(Venta p1)>.has(
          'onAnularVenta', onAnularVenta))
      ..add(ObjectFlagProperty<VoidCallback>.has(
          'onRecargarVentas', onRecargarVentas));
  }
}

class HistorialVentasComputerScreen extends StatefulWidget {
  final int? sucursalId;
  final String nombreSucursal;

  const HistorialVentasComputerScreen({
    super.key,
    this.sucursalId,
    this.nombreSucursal = 'Sucursal',
  });

  @override
  State<HistorialVentasComputerScreen> createState() =>
      _HistorialVentasComputerScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('sucursalId', sucursalId))
      ..add(StringProperty('nombreSucursal', nombreSucursal));
  }
}

class _HistorialVentasComputerScreenState
    extends State<HistorialVentasComputerScreen> {
  late VentasComputerProvider _ventasProvider;
  bool _isInitialized = false;
  // Instancia del repositorio para acceder a las ventas
  final VentaRepository _ventaRepository = VentaRepository.instance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _ventasProvider =
          Provider.of<VentasComputerProvider>(context, listen: false);
      _inicializarProvider();
      _isInitialized = true;
    }
  }

  Future<void> _inicializarProvider() async {
    if (widget.sucursalId != null) {
      await _ventasProvider.establecerSucursalPorId(widget.sucursalId);
    }
    _ventasProvider.cargarVentas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Ventas - ${widget.nombreSucursal}'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF121212),
      body: Consumer<VentasComputerProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Barra de filtros
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Búsqueda
                        Expanded(
                          child: TextField(
                            onChanged: provider.actualizarBusqueda,
                            decoration: InputDecoration(
                              hintText: 'Buscar por número o cliente...',
                              prefixIcon: const FaIcon(
                                  FontAwesomeIcons.magnifyingGlass,
                                  size: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Filtro de estado
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              hint: const Text('Estado'),
                              value: provider.estadoFiltro,
                              items: const [
                                DropdownMenuItem(child: Text('Todos')),
                                DropdownMenuItem(
                                    value: 'PENDIENTE',
                                    child: Text('Pendientes')),
                                DropdownMenuItem(
                                    value: 'COMPLETADA',
                                    child: Text('Completadas')),
                                DropdownMenuItem(
                                    value: 'ANULADA', child: Text('Anuladas')),
                                DropdownMenuItem(
                                    value: 'DECLARADA',
                                    child: Text('Declaradas')),
                              ],
                              onChanged: provider.actualizarFiltroEstado,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Fecha inicio
                        InkWell(
                          onTap: () async {
                            final DateTime? fecha = await showDatePicker(
                              context: context,
                              initialDate:
                                  provider.fechaInicio ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (fecha != null) {
                              provider.actualizarFiltrosFecha(
                                  fecha, provider.fechaFin);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const FaIcon(FontAwesomeIcons.calendarDay,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  provider.fechaInicio == null
                                      ? 'Fecha inicio'
                                      : DateFormat('dd/MM/yyyy')
                                          .format(provider.fechaInicio!),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Fecha fin
                        InkWell(
                          onTap: () async {
                            final DateTime? fecha = await showDatePicker(
                              context: context,
                              initialDate: provider.fechaFin ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (fecha != null) {
                              provider.actualizarFiltrosFecha(
                                  provider.fechaInicio, fecha);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const FaIcon(FontAwesomeIcons.calendarDay,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  provider.fechaFin == null
                                      ? 'Fecha fin'
                                      : DateFormat('dd/MM/yyyy')
                                          .format(provider.fechaFin!),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Botón de limpiar filtros
                        ElevatedButton.icon(
                          onPressed: provider.limpiarFiltros,
                          icon: const FaIcon(FontAwesomeIcons.filterCircleXmark,
                              size: 14),
                          label: const Text('Limpiar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Botón de refrescar
                        ElevatedButton.icon(
                          onPressed: () => provider.cargarVentas(),
                          icon: const FaIcon(FontAwesomeIcons.arrowsRotate,
                              size: 14),
                          label: const Text('Refrescar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE31E24),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Lista de ventas
              Expanded(
                child: VentasListComputer(
                  ventas: provider.ventas,
                  isLoading: provider.isVentasLoading,
                  onAnularVenta: (venta) => _mostrarAnularVentaDialog(venta),
                  onRecargarVentas: () => provider.cargarVentas(),
                ),
              ),

              // Paginación
              if (provider.paginacion.totalPages > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF1A1A1A),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.angleLeft),
                        onPressed: provider.paginacion.hasPrev
                            ? () => provider.cambiarPagina(
                                provider.paginacion.currentPage - 1)
                            : null,
                      ),
                      ...List.generate(
                        provider.paginacion.totalPages,
                        (index) {
                          final pageNumber = index + 1;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              onPressed:
                                  pageNumber != provider.paginacion.currentPage
                                      ? () => provider.cambiarPagina(pageNumber)
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: pageNumber ==
                                        provider.paginacion.currentPage
                                    ? const Color(0xFFE31E24)
                                    : Colors.grey[800],
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(40, 40),
                              ),
                              child: Text(pageNumber.toString()),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.angleRight),
                        onPressed: provider.paginacion.hasNext
                            ? () => provider.cambiarPagina(
                                provider.paginacion.currentPage + 1)
                            : null,
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

  Future<void> _mostrarAnularVentaDialog(Venta venta) async {
    final TextEditingController motivoController = TextEditingController();

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anular Venta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                '¿Está seguro que desea anular esta venta? Esta acción no se puede deshacer.'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo de anulación',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motivoController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Debe ingresar un motivo para anular la venta')),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Anular'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      if (!mounted) {
        return;
      }

      // Mostrar cargando
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Anulando venta...'),
            ],
          ),
        ),
      );

      try {
        final bool resultado = await _ventaRepository.anularVenta(
          venta.id.toString(),
          motivoController.text,
          sucursalId: widget.sucursalId?.toString(),
        );

        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(); // Cerrar diálogo de carga

        if (resultado) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Venta anulada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          _ventasProvider.cargarVentas();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al anular la venta'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(); // Cerrar diálogo de carga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al anular la venta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Función auxiliar para el registro de depuración
void logCache(String message) {
  debugPrint('FastCache: $message');
}
