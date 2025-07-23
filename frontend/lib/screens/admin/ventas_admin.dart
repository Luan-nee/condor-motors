import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/models/ventas.model.dart';
import 'package:condorsmotors/providers/admin/ventas.admin.provider.dart';
import 'package:condorsmotors/screens/admin/widgets/slide_sucursal.dart';
import 'package:condorsmotors/screens/admin/widgets/venta/venta_detalle_dialog.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Clases de data para Selector optimization
class VentasListData {
  final List<Venta> ventas;
  final bool isVentasLoading;
  final String ventasErrorMessage;
  final String searchQuery;

  const VentasListData({
    required this.ventas,
    required this.isVentasLoading,
    required this.ventasErrorMessage,
    required this.searchQuery,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is VentasListData &&
        other.ventas.length == ventas.length &&
        other.isVentasLoading == isVentasLoading &&
        other.ventasErrorMessage == ventasErrorMessage &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode {
    return Object.hash(
      ventas.length,
      isVentasLoading,
      ventasErrorMessage,
      searchQuery,
    );
  }
}

class SucursalData {
  final List<Sucursal> sucursales;
  final Sucursal? sucursalSeleccionada;
  final bool isSucursalesLoading;
  final String errorMessage;

  const SucursalData({
    required this.sucursales,
    required this.sucursalSeleccionada,
    required this.isSucursalesLoading,
    required this.errorMessage,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SucursalData &&
        other.sucursales.length == sucursales.length &&
        other.sucursalSeleccionada?.id == sucursalSeleccionada?.id &&
        other.isSucursalesLoading == isSucursalesLoading &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      sucursales.length,
      sucursalSeleccionada?.id,
      isSucursalesLoading,
      errorMessage,
    );
  }
}

class FiltersData {
  final String searchQuery;

  const FiltersData({
    required this.searchQuery,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is FiltersData && other.searchQuery == searchQuery;
  }

  @override
  int get hashCode {
    return searchQuery.hashCode;
  }
}

class VentasAdminScreen extends StatefulWidget {
  const VentasAdminScreen({super.key});

  @override
  State<VentasAdminScreen> createState() => _VentasAdminScreenState();
}

class _VentasAdminScreenState extends State<VentasAdminScreen> {
  final NumberFormat _formatoMoneda = NumberFormat.currency(
    symbol: 'S/ ',
    decimalDigits: 2,
  );
  final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');
  late VentasProvider _ventasProvider;

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
      _ventasProvider = Provider.of<VentasProvider>(context, listen: false);
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
    // Solo inicializamos si no hay sucursales cargadas
    if (_ventasProvider.sucursales.isEmpty &&
        !_ventasProvider.isSucursalesLoading) {
      _ventasProvider.inicializar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Panel izquierdo: Contenido principal (70%)
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header optimizado con Selector
                Selector<VentasProvider, SucursalData>(
                  selector: (_, provider) => SucursalData(
                    sucursales: provider.sucursales,
                    sucursalSeleccionada: provider.sucursalSeleccionada,
                    isSucursalesLoading: provider.isSucursalesLoading,
                    errorMessage: provider.errorMessage,
                  ),
                  builder: (context, sucursalData, child) {
                    return _buildHeader(context, sucursalData);
                  },
                ),
                // Contenido de ventas optimizado con Selector
                Expanded(
                  child: Selector<VentasProvider, VentasListData>(
                    selector: (_, provider) => VentasListData(
                      ventas: provider.ventas,
                      isVentasLoading: provider.isVentasLoading,
                      ventasErrorMessage: provider.ventasErrorMessage,
                      searchQuery: provider.searchQuery,
                    ),
                    builder: (context, ventasData, child) {
                      return _buildVentasContent(context, ventasData);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Panel derecho: Selector de sucursales (30%) - Optimizado con Selector
          Container(
            width: 350,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                left: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Selector<VentasProvider, SucursalData>(
              selector: (_, provider) => SucursalData(
                sucursales: provider.sucursales,
                sucursalSeleccionada: provider.sucursalSeleccionada,
                isSucursalesLoading: provider.isSucursalesLoading,
                errorMessage: provider.errorMessage,
              ),
              builder: (context, sucursalData, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mensaje de error para sucursales
                    if (sucursalData.errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          sucursalData.errorMessage,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),

                    // Selector de sucursales
                    Expanded(
                      child: SlideSucursal(
                        sucursales: sucursalData.sucursales,
                        sucursalSeleccionada: sucursalData.sucursalSeleccionada,
                        onSucursalSelected: _ventasProvider.cambiarSucursal,
                        onRecargarSucursales: _ventasProvider.cargarSucursales,
                        isLoading: sucursalData.isSucursalesLoading,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SucursalData sucursalData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
            sucursalData.sucursalSeleccionada?.nombre ?? 'Todas las sucursales',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _buildSearchField(),
          ),
          const SizedBox(width: 16),
          // Selector de ordenamiento
          Selector<VentasProvider, String>(
            selector: (_, provider) =>
                '${provider.ordenarPor ?? 'fechaCreacion'}_${provider.orden}',
            builder: (context, ordenamientoActual, child) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: ordenamientoActual,
                    dropdownColor: const Color(0xFF1A1A1A),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Colors.white70),
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'fechaCreacion_desc',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(FontAwesomeIcons.clockRotateLeft,
                                size: 12, color: Colors.white70),
                            SizedBox(width: 8),
                            Text('Más recientes'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'fechaCreacion_asc',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(FontAwesomeIcons.clock,
                                size: 12, color: Colors.white70),
                            SizedBox(width: 8),
                            Text('Más antiguas'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'totalVenta_desc',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(FontAwesomeIcons.arrowDownWideShort,
                                size: 12, color: Colors.white70),
                            SizedBox(width: 8),
                            Text('Mayor valor'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'totalVenta_asc',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(FontAwesomeIcons.arrowUpWideShort,
                                size: 12, color: Colors.white70),
                            SizedBox(width: 8),
                            Text('Menor valor'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'declarada_desc',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(FontAwesomeIcons.circleCheck,
                                size: 12, color: Colors.white70),
                            SizedBox(width: 8),
                            Text('Declaradas primero'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'anulada_desc',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(FontAwesomeIcons.ban,
                                size: 12, color: Colors.white70),
                            SizedBox(width: 8),
                            Text('Anuladas primero'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'nombreEmpleado_asc',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(FontAwesomeIcons.user,
                                size: 12, color: Colors.white70),
                            SizedBox(width: 8),
                            Text('Por empleado'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (String? nuevoOrdenamiento) {
                      if (nuevoOrdenamiento != null) {
                        final partes = nuevoOrdenamiento.split('_');
                        final sortBy = partes[0];
                        final order = partes[1];
                        _ventasProvider.actualizarOrdenamiento(sortBy, order);
                      }
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          // Botón de recargar ventas - Optimizado con Selector
          Selector<VentasProvider, bool>(
            selector: (_, provider) => provider.isVentasLoading,
            builder: (context, isVentasLoading, child) {
              return ElevatedButton.icon(
                icon: isVentasLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const FaIcon(
                        FontAwesomeIcons.arrowsRotate,
                        size: 16,
                        color: Colors.white,
                      ),
                label: Text(
                  isVentasLoading ? 'Recargando...' : 'Recargar',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D2D2D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onPressed: isVentasLoading
                    ? null
                    : () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        await _ventasProvider.cargarVentas();
                        // Mostrar mensaje de éxito o error
                        if (!mounted) {
                          return;
                        }

                        if (_ventasProvider.ventasErrorMessage.isNotEmpty) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(_ventasProvider.ventasErrorMessage),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('Ventas recargadas exitosamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
              );
            },
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

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Selector<VentasProvider, String>(
        selector: (_, provider) => provider.searchQuery,
        builder: (context, searchQuery, child) {
          return TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              hintText: 'Buscar por cliente, número de documento o serie...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white70, size: 18),
                      onPressed: () {
                        // Limpiar búsqueda
                        _ventasProvider.actualizarBusqueda('');
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
                    _ventasProvider.actualizarBusqueda(value);
                  }
                });
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildVentasContent(BuildContext context, VentasListData ventasData) {
    if (ventasData.isVentasLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (ventasData.ventasErrorMessage.isNotEmpty) {
      return Center(
        child: _buildEmptyState(
          icon: FontAwesomeIcons.triangleExclamation,
          title: 'Error al cargar ventas',
          description: ventasData.ventasErrorMessage,
          actionText: 'Intentar de nuevo',
          onAction: () => _ventasProvider.cargarVentas(),
        ),
      );
    }

    if (ventasData.ventas.isEmpty) {
      String mensajeVacio = 'Aún no hay ventas registradas para esta sucursal';
      if (ventasData.searchQuery.isNotEmpty) {
        mensajeVacio =
            'No se encontraron ventas con el término "${ventasData.searchQuery}"';
      }

      return Center(
        child: _buildEmptyState(
          icon: FontAwesomeIcons.fileInvoiceDollar,
          title: 'No hay ventas registradas',
          description: mensajeVacio,
          actionText: 'Actualizar',
          onAction: () => _ventasProvider.cargarVentas(),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: ventasData.ventas.length,
            itemBuilder: (context, index) {
              final venta = ventasData.ventas[index];
              return _buildVentaItem(context, _ventasProvider, venta);
            },
          ),
        ),
        // Paginador al final de la columna - Optimizado con Selector
        Selector<VentasProvider, dynamic>(
          selector: (_, provider) => provider.paginacion,
          builder: (context, paginacion, child) {
            if (paginacion.totalPages > 0) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Paginador(
                      paginacion: paginacion,
                      backgroundColor: const Color(0xFF2D2D2D),
                      textColor: Colors.white,
                      accentColor: const Color(0xFFE31E24),
                      radius: 8.0,
                      onPageChanged: _ventasProvider.cambiarPagina,
                      onPageSizeChanged: _ventasProvider.cambiarItemsPorPagina,
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
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

  Widget _buildVentaItem(
      BuildContext context, VentasProvider ventasProvider, Venta venta) {
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
                          .withValues(alpha: 0.1),
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
                              .withValues(alpha: 0.1),
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

  Future<void> _mostrarDetalleVenta(
      BuildContext context, VentasProvider ventasProvider, String id) async {
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

    await Provider.of<VentasProvider>(context, listen: false).abrirPdf(url);
  }
}
