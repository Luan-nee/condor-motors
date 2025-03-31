import 'dart:math' show min;
import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/ventas.model.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

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
}

class _HistorialVentasComputerScreenState
    extends State<HistorialVentasComputerScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? _estadoSeleccionado;
  List<Venta> _ventas = [];
  Paginacion? _paginacion;
  bool _isLoading = false;
  int _currentPage = 1;
  final int _pageSize = 10;

  // Filtros de estado predefinidos
  final List<Map<String, dynamic>> _estadosFiltro = [
    {'value': null, 'label': 'Todos'},
    {'value': 'PENDIENTE', 'label': 'Pendientes'},
    {'value': 'COMPLETADA', 'label': 'Completadas'},
    {'value': 'ANULADA', 'label': 'Anuladas'},
    {'value': 'DECLARADA', 'label': 'Declaradas'},
  ];

  // Formateo de moneda
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    // Cargar ventas al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarVentas();
    });
  }

  Future<void> _cargarVentas({bool forceRefresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Asegurar que sucursalId sea un valor manejable para la API
      final sucursalIdParam =
          widget.sucursalId != null ? widget.sucursalId.toString() : null;

      final response = await api.ventas.getVentas(
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        sucursalId: sucursalIdParam,
        estado: _estadoSeleccionado,
        forceRefresh: forceRefresh,
      );

      setState(() {
        if (response.containsKey('data') && response['data'] is List<Venta>) {
          _ventas = response['data'] as List<Venta>;
        } else if (response.containsKey('data')) {
          try {
            _ventas = api.ventas.parseVentas(response['data']);
          } catch (e) {
            debugPrint('Error al parsear ventas: $e');
            _ventas = [];
          }
        } else {
          _ventas = [];
        }

        _paginacion = response['pagination'] as Paginacion?;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar ventas: $e');
      setState(() {
        _ventas = [];
        _isLoading = false;
      });
      // Mostrar error al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar ventas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _seleccionarFecha(
      BuildContext context, bool esFechaInicio) async {
    final DateTime hoy = DateTime.now();
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: esFechaInicio ? _fechaInicio ?? hoy : _fechaFin ?? hoy,
      firstDate: DateTime(2020),
      lastDate: hoy,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE31E24),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null) {
      setState(() {
        if (esFechaInicio) {
          _fechaInicio = fechaSeleccionada;
          // Si fecha fin es anterior a fecha inicio, ajustarla
          if (_fechaFin != null && _fechaFin!.isBefore(_fechaInicio!)) {
            _fechaFin = _fechaInicio;
          }
        } else {
          _fechaFin = fechaSeleccionada;
          // Si fecha inicio es posterior a fecha fin, ajustarla
          if (_fechaInicio != null && _fechaInicio!.isAfter(_fechaFin!)) {
            _fechaInicio = _fechaFin;
          }
        }
        _currentPage = 1; // Reiniciar a primera página al cambiar filtros
        _cargarVentas(forceRefresh: true);
      });
    }
  }

  void _cambiarPagina(int nuevaPagina) {
    if (nuevaPagina != _currentPage) {
      setState(() {
        _currentPage = nuevaPagina;
      });
      _cargarVentas();
    }
  }

  Future<void> _mostrarDetalleVenta(Venta venta) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Detalle de ${venta.getNombreFormateado()}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildEstadoChip(venta.estado),
                    ],
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.xmark),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Información principal
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna izquierda - información básica
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(
                            'Información de Venta',
                            const FaIcon(FontAwesomeIcons.fileInvoice,
                                size: 16, color: Color(0xFFE31E24)),
                            [
                              _buildInfoRow('Documento',
                                  '${venta.serieDocumento}-${venta.numeroDocumento}'),
                              _buildInfoRow(
                                  'Fecha', venta.getFechaFormateada()),
                              _buildInfoRow('Estado', venta.estado.toText()),
                              _buildInfoRow(
                                  'Total',
                                  venta.totales != null
                                      ? _currencyFormat
                                          .format(venta.totales!.totalVenta)
                                      : _currencyFormat
                                          .format(venta.calcularTotal()),
                                  isHighlighted: true),
                            ]),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Columna derecha - resumen de totales
                  if (venta.totales != null)
                    Expanded(
                      flex: 1,
                      child: _buildInfoCard(
                          'Resumen de Totales',
                          const FaIcon(FontAwesomeIcons.moneyBillWave,
                              size: 16, color: Colors.green),
                          [
                            _buildInfoRow(
                                'Base Gravada',
                                _currencyFormat
                                    .format(venta.totales!.totalGravadas)),
                            _buildInfoRow(
                                'Exonerado',
                                _currencyFormat
                                    .format(venta.totales!.totalExoneradas)),
                            _buildInfoRow(
                                'Gratuito',
                                _currencyFormat
                                    .format(venta.totales!.totalGratuitas)),
                            _buildInfoRow(
                                'Impuestos',
                                _currencyFormat
                                    .format(venta.totales!.totalTax)),
                            _buildInfoRow(
                                'Total',
                                _currencyFormat
                                    .format(venta.totales!.totalVenta),
                                isHighlighted: true),
                          ]),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Lista de productos
              _buildInfoCard(
                  'Productos',
                  const FaIcon(FontAwesomeIcons.boxesStacked,
                      size: 16, color: Color(0xFF5B9BD5)),
                  [
                    // Cabecera de la tabla
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const SizedBox(
                              width: 40,
                              child: Text('Cant.',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          const SizedBox(width: 8),
                          const Expanded(
                              child: Text('Producto',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          const SizedBox(width: 8),
                          const SizedBox(
                              width: 100,
                              child: Text('Precio',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          const SizedBox(
                              width: 100,
                              child: Text('Total',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right)),
                        ],
                      ),
                    ),

                    // Divisor
                    const Divider(height: 1),

                    // Productos (lista con scroll si hay muchos)
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: 200,
                        minHeight: min(venta.detalles.length * 40.0, 200),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: venta.detalles
                              .map((detalle) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                            width: 40,
                                            child: Text('${detalle.cantidad}x',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(detalle.nombre)),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                            width: 100,
                                            child: Text(_currencyFormat
                                                .format(detalle.precioConIgv))),
                                        SizedBox(
                                            width: 100,
                                            child: Text(
                                              _currencyFormat
                                                  .format(detalle.total),
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            )),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ]),

              const SizedBox(height: 20),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (venta.estado == EstadoVenta.pendiente)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _mostrarAnularVentaDialog(venta);
                      },
                      icon: const FaIcon(FontAwesomeIcons.ban, size: 14),
                      label: const Text('Anular Venta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const FaIcon(FontAwesomeIcons.circleCheck, size: 14),
                    label: const Text('Aceptar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
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

  Widget _buildInfoCard(String title, Widget icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              icon,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                color: isHighlighted ? Colors.white : Colors.grey[400],
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                color: isHighlighted ? Colors.white : null,
                fontSize: isHighlighted ? 16 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarAnularVentaDialog(Venta venta) async {
    final TextEditingController motivoController = TextEditingController();

    return showDialog(
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (motivoController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Debe ingresar un motivo para anular la venta')),
                );
                return;
              }

              Navigator.of(context).pop();

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
                // Asegurar que sucursalId sea un valor manejable para la API
                final sucursalIdParam = widget.sucursalId != null
                    ? widget.sucursalId.toString()
                    : null;

                final bool resultado = await api.ventas.anularVenta(
                  venta.id.toString(),
                  motivoController.text,
                  sucursalId: sucursalIdParam,
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
                  _cargarVentas(forceRefresh: true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error al anular la venta'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                Navigator.of(context).pop(); // Cerrar diálogo de carga
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al anular la venta: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
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
      body: Column(
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
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por número o cliente...',
                          prefixIcon: const FaIcon(
                              FontAwesomeIcons.magnifyingGlass,
                              size: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onSubmitted: (_) {
                          _currentPage = 1;
                          _cargarVentas(forceRefresh: true);
                        },
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
                          value: _estadoSeleccionado,
                          items: _estadosFiltro.map((estado) {
                            return DropdownMenuItem<String?>(
                              value: estado['value'] as String?,
                              child: Text(estado['label'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _estadoSeleccionado = value;
                              _currentPage = 1;
                            });
                            _cargarVentas(forceRefresh: true);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Fecha inicio
                    InkWell(
                      onTap: () => _seleccionarFecha(context, true),
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
                              _fechaInicio == null
                                  ? 'Fecha inicio'
                                  : DateFormat('dd/MM/yyyy')
                                      .format(_fechaInicio!),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Fecha fin
                    InkWell(
                      onTap: () => _seleccionarFecha(context, false),
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
                              _fechaFin == null
                                  ? 'Fecha fin'
                                  : DateFormat('dd/MM/yyyy').format(_fechaFin!),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Botón de limpiar filtros
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _fechaInicio = null;
                          _fechaFin = null;
                          _estadoSeleccionado = null;
                          _currentPage = 1;
                        });
                        _cargarVentas(forceRefresh: true);
                      },
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
                      onPressed: () => _cargarVentas(forceRefresh: true),
                      icon:
                          const FaIcon(FontAwesomeIcons.arrowsRotate, size: 14),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _ventas.isEmpty
                    ? const Center(
                        child: Text(
                          'No se encontraron ventas',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _ventas.length,
                        itemBuilder: (context, index) {
                          final venta = _ventas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            color: const Color(0xFF1A1A1A),
                            child: InkWell(
                              onTap: () => _mostrarDetalleVenta(venta),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Encabezado: ID y Estado
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Izquierda: ID y estado
                                        Row(
                                          children: [
                                            Text(
                                              venta.getNombreFormateado(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            _buildEstadoChip(venta.estado),
                                          ],
                                        ),

                                        // Derecha: Total y botón
                                        Row(
                                          children: [
                                            Text(
                                              venta.totales != null
                                                  ? _currencyFormat.format(
                                                      venta.totales!.totalVenta)
                                                  : _currencyFormat.format(
                                                      venta.calcularTotal()),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  _mostrarDetalleVenta(venta),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFFE31E24),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                              ),
                                              child: const Text('Detalles'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    // Información secundaria
                                    Row(
                                      children: [
                                        // Serie y número
                                        const FaIcon(FontAwesomeIcons.receipt,
                                            size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${venta.serieDocumento}-${venta.numeroDocumento}',
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                        const SizedBox(width: 16),

                                        // Fecha
                                        const FaIcon(FontAwesomeIcons.calendar,
                                            size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          venta.getFechaFormateada(),
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                      ],
                                    ),

                                    // Mostrar productos solo si hay
                                    if (venta.detalles.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const FaIcon(
                                              FontAwesomeIcons.cartShopping,
                                              size: 12,
                                              color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              venta.detalles
                                                      .take(2)
                                                      .map((d) =>
                                                          '${d.cantidad}x ${d.nombre}')
                                                      .join(', ') +
                                                  (venta.detalles.length > 2
                                                      ? ' y ${venta.detalles.length - 2} más'
                                                      : ''),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Paginación
          if (_paginacion != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1A1A1A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón página anterior
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.angleLeft),
                    onPressed: _currentPage > 1
                        ? () => _cambiarPagina(_currentPage - 1)
                        : null,
                  ),

                  // Páginas numeradas
                  Row(
                    children: List.generate(
                      _paginacion!.totalPages <= 5
                          ? _paginacion!.totalPages
                          : 5,
                      (index) {
                        int pageNumber;
                        if (_paginacion!.totalPages <= 5) {
                          pageNumber = index + 1;
                        } else if (_currentPage <= 3) {
                          pageNumber = index + 1;
                        } else if (_currentPage >=
                            _paginacion!.totalPages - 2) {
                          pageNumber = _paginacion!.totalPages - 4 + index;
                        } else {
                          pageNumber = _currentPage - 2 + index;
                        }

                        // Asegurarse de que el número de página esté en rango
                        if (pageNumber > _paginacion!.totalPages)
                          return const SizedBox();

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton(
                            onPressed: pageNumber != _currentPage
                                ? () => _cambiarPagina(pageNumber)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: pageNumber == _currentPage
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
                  ),

                  // Botón página siguiente
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.angleRight),
                    onPressed: _currentPage < (_paginacion?.totalPages ?? 1)
                        ? () => _cambiarPagina(_currentPage + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
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
}

// Función auxiliar para el registro de depuración
void logCache(String message) {
  debugPrint('FastCache: $message');
}
