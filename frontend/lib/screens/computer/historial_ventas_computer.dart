import 'dart:math' show min;
import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/ventas.model.dart';
import 'package:condorsmotors/screens/admin/widgets/venta/venta_detalle_dialog.dart';
import 'package:condorsmotors/screens/computer/widgets/venta/ventas_list_computer.dart';
import 'package:flutter/foundation.dart';
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
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Asegurar que sucursalId sea un valor manejable para la API
      final sucursalIdParam = widget.sucursalId?.toString();

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

      // Verificar que la respuesta esté en el formato esperado
      if (!mounted) return;

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

        // Procesar la paginación desde el mapa
        if (response.containsKey('pagination') &&
            response['pagination'] is Map<String, dynamic>) {
          final paginationMap = response['pagination'] as Map<String, dynamic>;
          debugPrint('Datos de paginación recibidos: $paginationMap');

          try {
            _paginacion = Paginacion(
              totalItems: paginationMap['totalItems'] as int? ?? 0,
              totalPages: paginationMap['totalPages'] as int? ?? 1,
              currentPage: paginationMap['currentPage'] as int? ?? 1,
              hasNext: paginationMap['hasNext'] as bool? ?? false,
              hasPrev: paginationMap['hasPrev'] as bool? ?? false,
            );
            debugPrint('Paginación procesada correctamente: $_paginacion');
          } catch (e) {
            debugPrint('Error al procesar paginación: $e');
            _paginacion = null;
          }
        } else {
          _paginacion = null;
        }

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar ventas: $e');
      if (mounted) {
        setState(() {
          _ventas = [];
          _paginacion = null;
          _isLoading = false;
        });

        // Mostrar error al usuario
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

  // Método actualizado para usar el componente VentaDetalleDialog
  Future<void> _mostrarDetalleVenta(Venta venta) async {
    // Buscar detalles completos de la venta si es necesario
    if (venta.detalles.isEmpty) {
      try {
        final sucursalIdParam = widget.sucursalId?.toString();
        final dynamic ventaCompleta = await api.ventas.getVenta(
          venta.id.toString(),
          sucursalId: sucursalIdParam ?? '',
          forceRefresh: true,
        );

        // Manejar diferentes tipos de respuesta de la API
        if (ventaCompleta != null) {
          if (ventaCompleta is Venta) {
            // Si la API devuelve un objeto Venta directamente
            venta = ventaCompleta;
          } else if (ventaCompleta is Map<String, dynamic>) {
            // Si la API devuelve un Map
            final data = ventaCompleta['data'];
            if (data != null && data is Map<String, dynamic>) {
              venta = Venta.fromJson(data);
            }
          }
        }
      } catch (e) {
        debugPrint('Error al cargar detalles de venta: $e');
        // Continuamos con la venta actual si hay un error
      }
    }

    if (!mounted) return;

    // Mostrar el diálogo con la venta
    await showDialog(
      context: context,
      builder: (context) => VentaDetalleDialog(
        venta: venta,
        isLoadingFullData: false,
        onDeclararPressed: (venta.estado == EstadoVenta.pendiente)
            ? (_) => _mostrarAnularVentaDialog(venta)
            : null,
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
                final sucursalIdParam = widget.sucursalId?.toString();

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
                          contentPadding: const EdgeInsets.symmetric(),
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

          // Lista de ventas usando el componente VentasListComputer
          Expanded(
            child: VentasListComputer(
              ventas: _ventas,
              isLoading: _isLoading,
              onAnularVenta: (venta) => _mostrarAnularVentaDialog(venta),
              onRecargarVentas: () => _cargarVentas(forceRefresh: true),
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
                        if (pageNumber > _paginacion!.totalPages) {
                          return const SizedBox();
                        }

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
