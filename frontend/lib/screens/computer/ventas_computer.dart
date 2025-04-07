import 'package:condorsmotors/models/ventas.model.dart';
import 'package:condorsmotors/providers/computer/ventas.computer.provider.dart';
import 'package:condorsmotors/screens/admin/widgets/venta/venta_detalle_dialog.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VentasComputerScreen extends StatefulWidget {
  final int? sucursalId;
  final String nombreSucursal;

  const VentasComputerScreen(
      {super.key,
      this.sucursalId,
      this.nombreSucursal = 'Todas las sucursales'});

  @override
  State<VentasComputerScreen> createState() => _VentasComputerScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('sucursalId', sucursalId));
    properties.add(StringProperty('nombreSucursal', nombreSucursal));
  }
}

class _VentasComputerScreenState extends State<VentasComputerScreen> {
  final NumberFormat _formatoMoneda = NumberFormat.currency(
    symbol: 'S/ ',
    decimalDigits: 2,
  );
  final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');
  late VentasComputerProvider _ventasProvider;

  // Variables para controlar el estado de operaciones asíncronas
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // La inicialización se realizará en didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Solo realizar la inicialización una vez
    if (!_isInitialized) {
      _ventasProvider =
          Provider.of<VentasComputerProvider>(context, listen: false);
      // Programar la carga de datos para después del primer frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Verificar si el widget sigue montado cuando se ejecute el callback
        if (mounted) {
          _cargarDatos();
        }
      });
      _isInitialized = true;
    }
  }

  void _cargarDatos() {
    // Inicializar siempre, independientemente del estado de las sucursales
    _ventasProvider.inicializar();

    // Si se proporciona un ID de sucursal, establecerlo como filtro de inmediato
    if (widget.sucursalId != null) {
      debugPrint(
          'Estableciendo sucursal ID: ${widget.sucursalId} - ${widget.nombreSucursal}');

      // Intentar establecer la sucursal por ID de manera directa
      _ventasProvider
          .establecerSucursalPorId(widget.sucursalId)
          .then((bool success) {
        if (success) {
          debugPrint(
              'Sucursal establecida correctamente: ${widget.nombreSucursal}');
          // Cargar las ventas una vez establecida la sucursal
          _ventasProvider.cargarVentas();
        } else {
          debugPrint('Error al establecer la sucursal: ${widget.sucursalId}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Error al conectar con la sucursal: ${widget.nombreSucursal}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      });
    } else {
      debugPrint(
          'No se proporcionó un ID de sucursal, usando la primera disponible');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<VentasComputerProvider>(
        builder: (context, ventasProvider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, ventasProvider),
              Expanded(
                child: _buildVentasContent(context, ventasProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, VentasComputerProvider ventasProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const FaIcon(
            FontAwesomeIcons.fileInvoiceDollar,
            color: Color(0xFFE31E24),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            ventasProvider.sucursalSeleccionada?.nombre ??
                widget.nombreSucursal,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _buildSearchField(ventasProvider),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
            label: const Text('Nueva Venta'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFFE31E24),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onPressed: () {
              // Implementar creación de nueva venta
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función en desarrollo'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(VentasComputerProvider ventasProvider) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          hintText: 'Buscar por cliente, número de documento o serie...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.5),
          ),
          suffixIcon: ventasProvider.searchQuery.isNotEmpty
              ? IconButton(
                  icon:
                      const Icon(Icons.close, color: Colors.white70, size: 18),
                  onPressed: () {
                    // Limpiar búsqueda
                    ventasProvider.actualizarBusqueda('');
                  },
                )
              : null,
        ),
        onChanged: (value) {
          // Actualizar búsqueda después de un pequeño retraso
          // Verificar que el widget esté montado antes de continuar
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 500), () {
              // Verificar nuevamente que el widget está montado antes de actualizar
              if (mounted) {
                ventasProvider.actualizarBusqueda(value);
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildVentasContent(
      BuildContext context, VentasComputerProvider ventasProvider) {
    if (ventasProvider.isVentasLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (ventasProvider.ventasErrorMessage.isNotEmpty) {
      return Center(
        child: _buildEmptyState(
          icon: FontAwesomeIcons.triangleExclamation,
          title: 'Error al cargar ventas',
          description: ventasProvider.ventasErrorMessage,
          actionText: 'Intentar de nuevo',
          onAction: () => ventasProvider.cargarVentas(),
        ),
      );
    }

    if (ventasProvider.ventas.isEmpty) {
      String mensajeVacio = 'Aún no hay ventas registradas para esta sucursal';
      if (ventasProvider.searchQuery.isNotEmpty) {
        mensajeVacio =
            'No se encontraron ventas con el término "${ventasProvider.searchQuery}"';
      }

      return Center(
        child: _buildEmptyState(
          icon: FontAwesomeIcons.fileInvoiceDollar,
          title: 'No hay ventas registradas',
          description: mensajeVacio,
          actionText: 'Actualizar',
          onAction: () => ventasProvider.cargarVentas(),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF222222),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const FaIcon(
                      FontAwesomeIcons.calendarDays,
                      size: 14,
                    ),
                    label: const Text('Filtrar por fecha'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () {
                      if (mounted) {
                        _mostrarSelectorFechas(context, ventasProvider);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const FaIcon(
                      FontAwesomeIcons.filter,
                      size: 14,
                    ),
                    label: const Text('Filtrar por estado'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () {
                      if (mounted) {
                        _mostrarMenuEstados(context, ventasProvider);
                      }
                    },
                  ),
                  // Botón para limpiar filtros (visible solo si hay filtros activos)
                  if (ventasProvider.fechaInicio != null ||
                      ventasProvider.fechaFin != null ||
                      ventasProvider.estadoFiltro != null ||
                      ventasProvider.searchQuery.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const FaIcon(
                        FontAwesomeIcons.filterCircleXmark,
                        size: 14,
                        color: Color(0xFFE31E24),
                      ),
                      label: const Text('Limpiar filtros'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE31E24),
                        side: const BorderSide(color: Color(0xFFE31E24)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () {
                        ventasProvider.limpiarFiltros();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Filtros eliminados'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),

              // Indicador de filtros activos
              if (ventasProvider.fechaInicio != null ||
                  ventasProvider.fechaFin != null ||
                  ventasProvider.estadoFiltro != null ||
                  ventasProvider.searchQuery.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.filter,
                        size: 12,
                        color: Color(0xFFE31E24),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Filtros activos:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (ventasProvider.searchQuery.isNotEmpty)
                        _buildFiltroChip(
                          'Búsqueda: "${ventasProvider.searchQuery}"',
                          () {
                            ventasProvider.actualizarBusqueda('');
                          },
                        ),
                      if (ventasProvider.fechaInicio != null &&
                          ventasProvider.fechaFin != null)
                        _buildFiltroChip(
                          'Período: ${DateFormat('dd/MM/yyyy').format(ventasProvider.fechaInicio!)} - ${DateFormat('dd/MM/yyyy').format(ventasProvider.fechaFin!)}',
                          () {
                            ventasProvider.actualizarFiltrosFecha(null, null);
                          },
                        ),
                      if (ventasProvider.estadoFiltro != null)
                        _buildFiltroChip(
                          'Estado: ${ventasProvider.estadoFiltro}',
                          () {
                            ventasProvider.actualizarFiltroEstado(null);
                          },
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: ventasProvider.ventas.length,
            itemBuilder: (context, index) {
              final venta = ventasProvider.ventas[index];
              return _buildVentaItem(context, ventasProvider, venta);
            },
          ),
        ),
        // Paginador al final de la columna
        if (ventasProvider.paginacion.totalPages > 0)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Paginador(
                  paginacion: ventasProvider.paginacion,
                  backgroundColor: const Color(0xFF2D2D2D),
                  textColor: Colors.white,
                  accentColor: const Color(0xFFE31E24),
                  radius: 8.0,
                  onPageChanged: ventasProvider.cambiarPagina,
                  onPageSizeChanged: ventasProvider.cambiarItemsPorPagina,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FaIcon(
          icon,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE31E24),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
          child: Text(actionText),
        ),
      ],
    );
  }

  Widget _buildVentaItem(BuildContext context,
      VentasComputerProvider ventasProvider, Venta venta) {
    final String id = venta.id.toString();
    final String serie = venta.serieDocumento;
    final String numero = venta.numeroDocumento;
    final DateTime fecha = venta.fechaCreacion;
    final String horaEmision = venta.horaEmision;
    final double total = venta.calcularTotal();

    final String empleado = venta.empleadoDetalle != null
        ? venta.empleadoDetalle!.getNombreCompleto()
        : 'No especificado';

    final bool tienePdf = venta.documentoFacturacion?.linkPdf != null;
    final String? pdfLink = venta.documentoFacturacion?.linkPdf;

    final bool declarada = venta.declarada;
    final bool anulada = venta.anulada;

    final String estado = venta.estado.toText();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          if (mounted) {
            _mostrarDetalleVenta(context, ventasProvider, id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: ventasProvider
                          .getEstadoColor(estado)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: FaIcon(
                        tienePdf
                            ? FontAwesomeIcons.filePdf
                            : FontAwesomeIcons.fileInvoiceDollar,
                        color: ventasProvider.getEstadoColor(estado),
                      ),
                    ),
                  ),
                  if (declarada || anulada)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: anulada
                              ? Colors.red
                              : (declarada ? Colors.green : Colors.transparent),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serie.isNotEmpty && numero.isNotEmpty
                          ? '$serie-$numero'
                          : 'Venta #$id',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fecha: ${_formatoFecha.format(fecha)}${horaEmision.isNotEmpty ? ' $horaEmision' : ''}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Atendido por: $empleado',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatoMoneda.format(total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ventasProvider
                              .getEstadoColor(estado)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          estado,
                          style: TextStyle(
                            color: ventasProvider.getEstadoColor(estado),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (tienePdf)
                        IconButton(
                          icon: const FaIcon(
                            FontAwesomeIcons.fileArrowDown,
                            size: 14,
                            color: Colors.blue,
                          ),
                          tooltip: 'Descargar PDF',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          onPressed: () {
                            if (mounted && pdfLink != null) {
                              _abrirPdf(pdfLink);
                            }
                          },
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

  Future<void> _mostrarDetalleVenta(BuildContext context,
      VentasComputerProvider ventasProvider, String id) async {
    final ValueNotifier<Venta?> ventaNotifier = ValueNotifier<Venta?>(null);
    final ValueNotifier<bool> isLoadingFullData = ValueNotifier<bool>(true);

    Venta? ventaBasica;
    try {
      ventaBasica =
          ventasProvider.ventas.firstWhere((v) => v.id.toString() == id);
      ventaNotifier.value = ventaBasica;
      isLoadingFullData.value = true;
    } catch (e) {
      debugPrint("Venta básica no encontrada en la lista: $id");
    }

    Future<void> declararVenta(String ventaId) async {
      if (!mounted) {
        return;
      }

      isLoadingFullData.value = true;

      await ventasProvider.declararVenta(
        ventaId,
        onSuccess: () async {
          if (!mounted) {
            return;
          }

          final ventaActualizada =
              await ventasProvider.cargarDetalleVenta(ventaId);

          if (!mounted) {
            return;
          }

          ventaNotifier.value = ventaActualizada;
          isLoadingFullData.value = false;
        },
        onError: (errorMsg) {
          if (!mounted) {
            return;
          }

          isLoadingFullData.value = false;
        },
      );
    }

    if (!mounted) {
      return;
    }
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: ventasProvider,
        child: ValueListenableBuilder<Venta?>(
          valueListenable: ventaNotifier,
          builder: (dialogContext, currentVenta, child) {
            return ValueListenableBuilder<bool>(
              valueListenable: isLoadingFullData,
              builder: (dialogContextLoading, isLoading, _) {
                return VentaDetalleDialog(
                  venta: currentVenta,
                  isLoadingFullData: isLoading,
                  onDeclararPressed: declararVenta,
                );
              },
            );
          },
        ),
      ),
    );

    try {
      final ventaCompleta = await ventasProvider.cargarDetalleVenta(id);

      if (!mounted) {
        return;
      }

      ventaNotifier.value = ventaCompleta;

      isLoadingFullData.value = false;
    } catch (e) {
      if (!mounted) {
        return;
      }

      ventasProvider.mostrarMensaje(
        mensaje: 'Error al cargar los detalles de la venta: ${e.toString()}',
        backgroundColor: Colors.red,
      );
      isLoadingFullData.value = false;
    }
  }

  Future<void> _abrirPdf(String url) async {
    if (!mounted) {
      return;
    }

    await Provider.of<VentasComputerProvider>(context, listen: false)
        .abrirPdf(url);
  }

  Future<void> _mostrarSelectorFechas(
      BuildContext context, VentasComputerProvider ventasProvider) async {
    // Guardar el contexto en una variable local
    final BuildContext currentContext = context;

    if (!mounted) {
      return;
    }

    final DateTimeRange? rango = await showDateRangePicker(
      context: currentContext,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange:
          ventasProvider.fechaInicio != null && ventasProvider.fechaFin != null
              ? DateTimeRange(
                  start: ventasProvider.fechaInicio!,
                  end: ventasProvider.fechaFin!,
                )
              : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE31E24),
              onPrimary: Colors.white,
              surface: Color(0xFF2D2D2D),
            ),
            dialogBackgroundColor: const Color(0xFF1A1A1A),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (rango != null) {
      ventasProvider.actualizarFiltrosFecha(
        rango.start,
        rango.end,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text(
            'Filtrando desde ${DateFormat('dd/MM/yyyy').format(rango.start)} hasta ${DateFormat('dd/MM/yyyy').format(rango.end)}',
          ),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Limpiar',
            textColor: Colors.white,
            onPressed: () {
              if (mounted) {
                ventasProvider.actualizarFiltrosFecha(null, null);
              }
            },
          ),
        ),
      );
    }
  }

  void _mostrarMenuEstados(
      BuildContext context, VentasComputerProvider ventasProvider) {
    // Guardar el contexto en una variable local
    final BuildContext currentContext = context;

    if (!mounted) {
      return;
    }

    final estados = [
      {'id': null, 'nombre': 'Todos los estados'},
      {'id': 'PENDIENTE', 'nombre': 'Pendiente'},
      {'id': 'COMPLETADA', 'nombre': 'Completada'},
      {'id': 'ANULADA', 'nombre': 'Anulada'},
      {'id': 'DECLARADA', 'nombre': 'Declarada'},
      {'id': 'ACEPTADO-SUNAT', 'nombre': 'Aceptado SUNAT'},
    ];

    final RenderBox button = currentContext.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(currentContext).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: currentContext,
      position: position,
      color: const Color(0xFF2D2D2D),
      items: estados.map((estado) {
        final esSeleccionado = ventasProvider.estadoFiltro == estado['id'];
        return PopupMenuItem<String>(
          value: estado['id'],
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: esSeleccionado
                      ? const Color(0xFFE31E24)
                      : Colors.transparent,
                  border: Border.all(
                    color: esSeleccionado
                        ? const Color(0xFFE31E24)
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
                child: esSeleccionado
                    ? const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      )
                    : null,
              ),
              Text(
                estado['nombre'] as String,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                      esSeleccionado ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ).then((String? seleccionado) {
      if (!mounted) {
        return;
      }

      if (seleccionado != null || seleccionado == null) {
        ventasProvider.actualizarFiltroEstado(seleccionado);

        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(
              'Filtrando por estado: ${seleccionado ?? 'Todos'}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  Widget _buildFiltroChip(String label, VoidCallback onPressed) {
    return Chip(
      label: Text(label),
      onDeleted: onPressed,
      deleteIconColor: Colors.white,
      backgroundColor: const Color(0xFF1A1A1A),
      labelStyle: const TextStyle(color: Colors.white70),
    );
  }
}
