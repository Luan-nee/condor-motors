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
      BuildContext context, VentasProvider ventasProvider, dynamic venta) {
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
            : DateTime.now());

    final double total = isVenta
        ? venta.calcularTotal()
        : (venta['totalesVenta'] != null &&
                venta['totalesVenta']['totalVenta'] != null
            ? (venta['totalesVenta']['totalVenta'] is String
                ? double.tryParse(venta['totalesVenta']['totalVenta']) ?? 0.0
                : venta['totalesVenta']['totalVenta'].toDouble())
            : 0.0);

    final String cliente = isVenta
        ? (venta.clienteDetalle?.denominacion ?? 'Cliente no especificado')
        : (venta['cliente'] != null
            ? venta['cliente']['denominacion'] ?? 'Cliente no especificado'
            : 'Cliente no especificado');

    final String estado = isVenta
        ? venta.estado.toText()
        : (venta['estado'] is Map
            ? venta['estado']['nombre'] ?? 'PENDIENTE'
            : venta['estado'] ?? 'PENDIENTE');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _mostrarDetalleVenta(context, ventasProvider, id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                    FontAwesomeIcons.fileInvoiceDollar,
                    color: _getEstadoColor(estado),
                  ),
                ),
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
                      'Fecha: ${_formatoFecha.format(fecha)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cliente: $cliente',
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: SizedBox(
            height: 100,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando detalles de la venta...'),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final Venta? venta = await ventasProvider.cargarDetalleVenta(id);

      Navigator.of(context).pop();

      if (venta == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ventasProvider.ventaDetalleErrorMessage),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => VentaDetalleDialog(venta: venta),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar detalles: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
