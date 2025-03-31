import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/models/ventas.model.dart';
import 'package:condorsmotors/screens/admin/widgets/venta/venta_detalle_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/venta/venta_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class VentaTable extends StatefulWidget {
  final Sucursal? sucursalSeleccionada;
  final VoidCallback onRecargarVentas;

  const VentaTable({
    super.key,
    required this.sucursalSeleccionada,
    required this.onRecargarVentas,
  });

  @override
  State<VentaTable> createState() => _VentaTableState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Sucursal?>(
          'sucursalSeleccionada', sucursalSeleccionada))
      ..add(ObjectFlagProperty<VoidCallback>.has(
          'onRecargarVentas', onRecargarVentas));
  }
}

class _VentaTableState extends State<VentaTable> {
  bool _isLoading = false;
  String _errorMessage = '';
  List<dynamic> _ventas = [];

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  @override
  void didUpdateWidget(VentaTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sucursalSeleccionada?.id != widget.sucursalSeleccionada?.id) {
      _cargarVentas();
    }
  }

  // Método para cargar las ventas de una sucursal específica
  Future<void> _cargarVentas() async {
    if (widget.sucursalSeleccionada == null) {
      setState(() {
        _errorMessage = 'Debe seleccionar una sucursal';
        _ventas = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      debugPrint(
          'Cargando ventas para sucursal: ${widget.sucursalSeleccionada!.id}');
      final Map<String, dynamic> response = await api.ventas.getVentas(
        sucursalId: widget.sucursalSeleccionada!.id,
      );

      if (!mounted) {
        return;
      }

      debugPrint(
          'Respuesta de ventas recibida, tipo de datos: ${response['data']?.runtimeType}');

      List<dynamic> ventasList = [];
      if (response['data'] != null) {
        if (response['data'] is List) {
          // Si los datos son una lista, los usamos directamente
          ventasList = response['data'];
          debugPrint(
              'Datos recibidos como lista: ${ventasList.length} elementos');

          // Si son Maps, los convertimos a objetos Venta
          if (ventasList.isNotEmpty &&
              ventasList.first is Map<String, dynamic>) {
            try {
              debugPrint('Convirtiendo Maps a objetos Venta');
              ventasList = ventasList
                  .map((item) => Venta.fromJson(item as Map<String, dynamic>))
                  .toList();
            } catch (e) {
              debugPrint('Error al convertir Maps a Venta: $e');
              // Si hay error, mantenemos los datos originales como Map
            }
          }
        } else if (response['ventasRaw'] != null &&
            response['ventasRaw'] is List) {
          // En caso de que la API ya haya convertido los datos pero también proporcione los datos raw
          ventasList = response['data'];
          debugPrint(
              'Usando datos procesados de la API: ${ventasList.length} elementos');
        }
      }

      setState(() {
        _ventas = ventasList;
        _isLoading = false;
      });

      debugPrint(
          'Ventas cargadas: ${_ventas.length}, tipo: ${_ventas.isNotEmpty ? _ventas.first.runtimeType : "N/A"}');
    } catch (e) {
      if (!mounted) {
        return;
      }

      debugPrint('Error al cargar ventas: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar ventas: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar ventas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Abre el diálogo de detalle de venta
  void _mostrarDetalleVenta(venta) {
    showDialog(
      context: context,
      builder: (context) => VentaDetalleDialog(venta: venta),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VENTAS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.sucursalSeleccionada != null)
                    Text(
                      'Sucursal: ${widget.sucursalSeleccionada!.nombre}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  if (_isLoading)
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cargando...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.arrowsRotate,
                      color: Colors.white,
                      size: 16,
                    ),
                    onPressed: _isLoading
                        ? null
                        : () {
                            _cargarVentas();
                            widget.onRecargarVentas();
                          },
                    tooltip: 'Recargar ventas',
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const FaIcon(
                      FontAwesomeIcons.plus,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text('Nueva Venta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _isLoading || widget.sucursalSeleccionada == null
                        ? null
                        : () {
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
            ],
          ),

          const SizedBox(height: 16),

          // Mensaje de error
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _errorMessage = '';
                      });
                    },
                  ),
                ],
              ),
            ),

          // Tabla de ventas
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: VentaList(
                ventas: _ventas,
                isLoading: _isLoading,
                onVerDetalle: _mostrarDetalleVenta,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
