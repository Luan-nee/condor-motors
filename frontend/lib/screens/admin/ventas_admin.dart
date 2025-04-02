import 'package:condorsmotors/models/ventas.model.dart';
import 'package:condorsmotors/providers/admin/ventas.provider.dart';
import 'package:condorsmotors/screens/admin/widgets/slide_sucursal.dart';
import 'package:condorsmotors/screens/admin/widgets/venta/venta_detalle_dialog.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    // La inicialización se realizará en didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ventasProvider = Provider.of<VentasProvider>(context, listen: false);

    // Inicializamos el provider si es necesario
    _cargarDatos();
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
      body: Consumer<VentasProvider>(
        builder: (context, ventasProvider, child) {
          return Row(
            children: [
              // Panel izquierdo: Contenido principal (70%)
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, ventasProvider),
                    Expanded(
                      child: _buildVentasContent(context, ventasProvider),
                    ),
                  ],
                ),
              ),

              // Panel derecho: Selector de sucursales (30%)
              Container(
                width: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  border: Border(
                    left: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera del panel de sucursales
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      color: const Color(0xFF2D2D2D),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.buildingUser,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'SUCURSALES',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          if (ventasProvider.isSucursalesLoading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Mensaje de error para sucursales
                    if (ventasProvider.errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ventasProvider.errorMessage,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),

                    // Selector de sucursales
                    Expanded(
                      child: SlideSucursal(
                        sucursales: ventasProvider.sucursales,
                        sucursalSeleccionada:
                            ventasProvider.sucursalSeleccionada,
                        onSucursalSelected: ventasProvider.cambiarSucursal,
                        onRecargarSucursales: ventasProvider.cargarSucursales,
                        isLoading: ventasProvider.isSucursalesLoading,
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

  Widget _buildHeader(BuildContext context, VentasProvider ventasProvider) {
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
                'Todas las sucursales',
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

  Widget _buildSearchField(VentasProvider ventasProvider) {
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
          Future.delayed(const Duration(milliseconds: 500), () {
            ventasProvider.actualizarBusqueda(value);
          });
        },
      ),
    );
  }

  Widget _buildVentasContent(
      BuildContext context, VentasProvider ventasProvider) {
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
          child: Row(
            children: [
              Text(
                'Mostrando ${ventasProvider.ventas.length} ventas',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
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
                  // TODO: Implementar filtro por fecha
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función en desarrollo'),
                      backgroundColor: Colors.blue,
                    ),
                  );
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
                  // TODO: Implementar filtro por estado
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función en desarrollo'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
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
      BuildContext context, VentasProvider ventasProvider, venta) {
    final bool isVenta = venta is Venta;

    final String id = isVenta ? venta.id.toString() : venta['id'].toString();

    final String serie =
        isVenta ? venta.serieDocumento : venta['serieDocumento'] ?? '';

    final String numero =
        isVenta ? venta.numeroDocumento : venta['numeroDocumento'] ?? '';

    final DateTime fecha = isVenta
        ? venta.fechaCreacion
        : (venta['fechaCreacion'] != null
            ? DateTime.parse(venta['fechaCreacion'])
            : (venta['fechaEmision'] != null
                ? DateTime.parse(venta['fechaEmision'])
                : DateTime.now()));

    final String horaEmision =
        isVenta ? venta.horaEmision : venta['horaEmision'] ?? '';

    final double total = isVenta
        ? venta.calcularTotal()
        : (venta['totalesVenta'] != null &&
                venta['totalesVenta']['totalVenta'] != null
            ? (venta['totalesVenta']['totalVenta'] is String
                ? double.tryParse(venta['totalesVenta']['totalVenta']) ?? 0.0
                : venta['totalesVenta']['totalVenta'].toDouble())
            : 0.0);

    // El empleado siempre está disponible en las ventas
    final String empleado = isVenta
        ? (venta.empleadoDetalle != null
            ? '${venta.empleadoDetalle!.nombre} ${venta.empleadoDetalle!.apellidos}'
            : 'No especificado')
        : (venta['empleado'] != null
            ? '${venta['empleado']['nombre']} ${venta['empleado']['apellidos']}'
            : 'No especificado');

    // Verifica si hay PDF
    final bool tienePdf = isVenta
        ? (venta.documentoFacturacion != null &&
            venta.documentoFacturacion!.linkPdf != null)
        : (venta['documentoFacturacion'] != null &&
            venta['documentoFacturacion']['linkPdf'] != null);

    final String? pdfLink = isVenta
        ? (venta.documentoFacturacion?.linkPdf)
        : (tienePdf ? venta['documentoFacturacion']['linkPdf'] : null);

    // Estados adicionales (declarada/anulada)
    final bool declarada =
        isVenta ? venta.declarada : venta['declarada'] ?? false;

    final bool anulada = isVenta ? venta.anulada : venta['anulada'] ?? false;

    // Estado de SUNAT
    final String estado = isVenta
        ? venta.estado.toText()
        : (venta['estado'] is Map
            ? venta['estado']['nombre'] ?? 'PENDIENTE'
            : (anulada ? 'ANULADA' : (declarada ? 'DECLARADA' : 'PENDIENTE')));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _mostrarDetalleVenta(context, ventasProvider, id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono principal con indicador de estado
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getEstadoColor(estado).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: FaIcon(
                        tienePdf
                            ? FontAwesomeIcons.filePdf
                            : FontAwesomeIcons.fileInvoiceDollar,
                        color: _getEstadoColor(estado),
                      ),
                    ),
                  ),
                  // Indicador visual para declarada o anulada
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
                          color: _getEstadoColor(estado).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          estado,
                          style: TextStyle(
                            color: _getEstadoColor(estado),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (tienePdf)
                        IconButton(
                          icon: FaIcon(
                            FontAwesomeIcons.fileArrowDown,
                            size: 14,
                            color: Colors.blue,
                          ),
                          tooltip: 'Descargar PDF',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          onPressed: () => _abrirPdf(pdfLink!),
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

  Color _getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'COMPLETADA':
        return Colors.green;
      case 'ANULADA':
        return Colors.red;
      case 'DECLARADA':
        return Colors.blue;
      case 'ACEPTADO-SUNAT':
        return Colors.green;
      case 'ACEPTADO ANTE LA SUNAT':
        return Colors.green;
      case 'PENDIENTE':
      default:
        return Colors.orange;
    }
  }

  Future<void> _mostrarDetalleVenta(
      BuildContext context, VentasProvider ventasProvider, String id) async {
    // Buscamos primero si ya tenemos esta venta en nuestra lista
    dynamic ventaPrevia;
    for (var v in ventasProvider.ventas) {
      if ((v is Venta && v.id.toString() == id) ||
          (v is Map && v['id'].toString() == id)) {
        ventaPrevia = v;
        break;
      }
    }

    // Creamos un ValueNotifier para gestionar los datos de la venta
    final ValueNotifier<dynamic> ventaNotifier =
        ValueNotifier<dynamic>(ventaPrevia);
    // Notifier para controlar el estado de carga
    final ValueNotifier<bool> isLoadingFullData = ValueNotifier<bool>(false);

    // Función para declarar la venta a SUNAT usando los callbacks del provider
    Future<void> declararVenta(String ventaId) async {
      // Actualizamos el estado de carga
      isLoadingFullData.value = true;

      // Llamar al provider para declarar la venta usando callbacks para manejar éxito y error
      await ventasProvider.declararVenta(
        ventaId,
        onSuccess: () async {
          // Recargar los detalles completos de la venta
          final ventaActualizada =
              await ventasProvider.cargarDetalleVenta(ventaId);
          ventaNotifier.value = ventaActualizada;
          isLoadingFullData.value = false;
        },
        onError: (errorMsg) {
          // No necesitamos mostrar el error aquí, lo manejará el provider
          isLoadingFullData.value = false;
        },
      );
    }

    // Mostramos un diálogo con la información cargada hasta el momento
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ValueListenableBuilder<dynamic>(
          valueListenable: ventaNotifier,
          builder: (context, currentVenta, child) {
            return ValueListenableBuilder<bool>(
                valueListenable: isLoadingFullData,
                builder: (context, isLoading, _) {
                  return VentaDetalleDialog(
                    venta: currentVenta,
                    isLoadingFullData: isLoading,
                    onDeclararPressed: declararVenta,
                  );
                });
          },
        );
      },
    );

    try {
      // Marcamos que estamos cargando los datos completos
      isLoadingFullData.value = true;

      // Obtener datos completos de la venta para mostrar todos los detalles
      final ventaCompleta = await ventasProvider.cargarDetalleVenta(id);

      // Actualizar los datos de la venta en el ValueNotifier
      ventaNotifier.value = ventaCompleta;

      // Marcar que ya no estamos cargando
      isLoadingFullData.value = false;
    } catch (e) {
      // En caso de error, actualizar el estado y mostrar el mensaje desde el provider
      ventasProvider.mostrarMensaje(
        mensaje: 'Error al cargar los detalles de la venta: ${e.toString()}',
        backgroundColor: Colors.red,
      );
      isLoadingFullData.value = false;
    }
  }

  // Método para abrir PDFs usando el método del provider
  Future<void> _abrirPdf(String url) async {
    // Utilizamos el método del provider para abrir PDFs
    await Provider.of<VentasProvider>(context, listen: false)
        .abrirPdf(url, context);
  }
}
