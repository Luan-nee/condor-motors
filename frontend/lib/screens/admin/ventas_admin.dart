import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/screens/admin/widgets/slide_sucursal.dart';
import 'package:condorsmotors/screens/admin/widgets/venta/venta_table.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class VentasAdminScreen extends StatefulWidget {
  const VentasAdminScreen({super.key});

  @override
  State<VentasAdminScreen> createState() => _VentasAdminScreenState();
}

class _VentasAdminScreenState extends State<VentasAdminScreen> {
  String _errorMessage = '';
  List<Sucursal> _sucursales = [];
  Sucursal? _sucursalSeleccionada;
  bool _isSucursalesLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarSucursales();
  }

  // Carga las sucursales disponibles
  Future<void> _cargarSucursales() async {
    setState(() {
      _isSucursalesLoading = true;
      _errorMessage = '';
    });

    try {
      debugPrint('Cargando sucursales desde la API...');
      final data = await api.sucursales.getSucursales();

      if (!mounted) {
        return;
      }

      debugPrint('Datos recibidos tipo: ${data.runtimeType}');
      debugPrint('Longitud de la lista: ${data.length}');
      if (data.isNotEmpty) {
        debugPrint('Primer elemento tipo: ${data.first.runtimeType}');
      }

      List<Sucursal> sucursalesParsed = [];

      // Procesamiento seguro de los datos
      for (var item in data) {
        try {
          // Si ya es un objeto Sucursal, lo usamos directamente
          sucursalesParsed.add(item);
        } catch (e) {
          debugPrint('Error al procesar sucursal: $e');
        }
      }

      // Ordenar por nombre
      sucursalesParsed.sort((a, b) => a.nombre.compareTo(b.nombre));

      debugPrint(
          'Sucursales cargadas correctamente: ${sucursalesParsed.length}');

      setState(() {
        _sucursales = sucursalesParsed;
        _isSucursalesLoading = false;

        // Seleccionar la primera sucursal como predeterminada si hay sucursales
        if (_sucursales.isNotEmpty && _sucursalSeleccionada == null) {
          _sucursalSeleccionada = _sucursales.first;
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      debugPrint('Error al cargar sucursales: $e');
      setState(() {
        _isSucursalesLoading = false;
        _errorMessage = 'Error al cargar sucursales: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar sucursales: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Cambia la sucursal seleccionada
  void _cambiarSucursal(Sucursal sucursal) {
    setState(() {
      _sucursalSeleccionada = sucursal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Panel izquierdo: Tabla de ventas (70%)
          Expanded(
            flex: 7,
            child: VentaTable(
              sucursalSeleccionada: _sucursalSeleccionada,
              onRecargarVentas: _cargarSucursales,
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
                      if (_isSucursalesLoading)
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
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),

                // Selector de sucursales
                Expanded(
                  child: _isSucursalesLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              CircularProgressIndicator(
                                color: Color(0xFFE31E24),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Cargando sucursales...',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        )
                      : _sucursales.isEmpty && _errorMessage.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const FaIcon(
                                    FontAwesomeIcons.buildingCircleXmark,
                                    color: Colors.white54,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No hay sucursales disponibles',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    icon: const FaIcon(
                                        FontAwesomeIcons.arrowsRotate,
                                        size: 16),
                                    label: const Text('Recargar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE31E24),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: _cargarSucursales,
                                  ),
                                ],
                              ),
                            )
                          : SlideSucursal(
                              sucursales: _sucursales,
                              sucursalSeleccionada: _sucursalSeleccionada,
                              onSucursalSelected: _cambiarSucursal,
                              onRecargarSucursales: _cargarSucursales,
                              isLoading: _isSucursalesLoading,
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
