import 'package:condorsmotors/providers/admin/ventas.provider.dart';
import 'package:condorsmotors/screens/admin/widgets/slide_sucursal.dart';
import 'package:condorsmotors/screens/admin/widgets/venta/venta_table.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class VentasAdminScreen extends StatefulWidget {
  const VentasAdminScreen({super.key});

  @override
  State<VentasAdminScreen> createState() => _VentasAdminScreenState();
}

class _VentasAdminScreenState extends State<VentasAdminScreen> {
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
      body: Row(
        children: [
          // Panel izquierdo: Tabla de ventas (70%)
          Expanded(
            flex: 7,
            child: Consumer<VentasProvider>(
              builder: (context, provider, child) {
                return VentaTable(
                  sucursalSeleccionada: provider.sucursalSeleccionada,
                  onRecargarVentas: provider.cargarSucursales,
                );
              },
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
                Consumer<VentasProvider>(
                  builder: (context, provider, child) {
                    return Container(
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
                          if (provider.isSucursalesLoading)
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
                    );
                  },
                ),

                // Mensaje de error para sucursales
                Consumer<VentasProvider>(
                  builder: (context, provider, child) {
                    if (provider.errorMessage.isNotEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          provider.errorMessage,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Selector de sucursales
                Expanded(
                  child: Consumer<VentasProvider>(
                    builder: (context, provider, child) {
                      if (provider.isSucursalesLoading) {
                        return const Center(
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
                        );
                      } else if (provider.sucursales.isEmpty &&
                          provider.errorMessage.isEmpty) {
                        return Center(
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
                                onPressed: provider.cargarSucursales,
                              ),
                            ],
                          ),
                        );
                      } else {
                        return SlideSucursal(
                          sucursales: provider.sucursales,
                          sucursalSeleccionada: provider.sucursalSeleccionada,
                          onSucursalSelected: provider.cambiarSucursal,
                          onRecargarSucursales: provider.cargarSucursales,
                          isLoading: provider.isSucursalesLoading,
                        );
                      }
                    },
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
