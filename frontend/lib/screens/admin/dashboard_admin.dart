import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../main.dart' show api;
import '../../models/producto.model.dart';
import '../../models/sucursal.model.dart';

// Un modelo básico para el widget de estadísticas del Dashboard
class DashboardItemInfo {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color bgColor;

  DashboardItemInfo({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.bgColor,
  });
}

// Definición de la clase Stock para manejar los datos
class Stock {
  final int productoId;
  final int cantidad;

  Stock({
    required this.productoId,
    required this.cantidad,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      productoId: json['producto_id'] ?? 0,
      cantidad: json['cantidad'] ?? 0,
    );
  }
}

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _sucursalSeleccionadaId = '';

  // Controlador de animación para los elementos del dashboard
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Datos para mostrar en el dashboard
  List<Sucursal> _sucursales = [];
  List<Producto> _productos = [];
  double _totalVentas = 0;
  double _totalGanancias = 0;
  int _totalEmpleados = 0;
  int _productosAgotados = 0;

  // Mapa para agrupar productos por sucursal
  Map<String, List<Producto>> _productosPorSucursal = {};

  @override
  void initState() {
    super.initState();
    // Configurar animación
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();

    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Cargar sucursales primero
      final sucursalesResponse = await api.sucursales.getSucursales();

      final List<Sucursal> sucursalesList = [];
      final List<Sucursal> centralesList = [];

      for (var sucursal in sucursalesResponse) {
        sucursalesList.add(sucursal);
        if (sucursal.sucursalCentral) {
          centralesList.add(sucursal);
        }
      }

      // Establecer la sucursal seleccionada: central si existe, o la primera disponible
      String sucursalId = '';
      if (centralesList.isNotEmpty) {
        sucursalId = centralesList.first.id.toString();
      } else if (sucursalesList.isNotEmpty) {
        sucursalId = sucursalesList.first.id.toString();
      }

      if (sucursalId.isNotEmpty) {
        _sucursalSeleccionadaId = sucursalId;
        await Future.wait([
          _loadProductos(),
          _loadEmpleados(),
          _loadCategorias(),
          _loadColores(),
          _loadVentasStats(),
        ]);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _sucursales = sucursalesList;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos iniciales: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadProductos() async {
    try {
      // Mapa para organizar productos por sucursal
      final Map<String, List<Producto>> productosBySucursal = {};

      // Inicializar listas vacías para cada sucursal
      for (var sucursal in _sucursales) {
        productosBySucursal[sucursal.id.toString()] = [];
      }

      // Cargar productos para la sucursal seleccionada
      final paginatedProductos = await api.productos.getProductos(
        sucursalId: _sucursalSeleccionadaId,
      );

      final Map<int, int> newExistencias = {};
      int agotados = 0;

      // Procesar los datos de productos
      for (var producto in paginatedProductos.items) {
        newExistencias[producto.id] = producto.stock;
        if (producto.stock <= 0) {
          agotados++;
        }

        // Agregar al mapa de productos por sucursal
        final sucId = _sucursalSeleccionadaId;
        if (productosBySucursal.containsKey(sucId)) {
          productosBySucursal[sucId]!.add(producto);
        }
      }

      // Para cada sucursal, cargar algunos productos (en una implementación real,
      // podrías cargar datos para todas las sucursales de forma paralela)
      for (var sucursal in _sucursales) {
        if (sucursal.id.toString() != _sucursalSeleccionadaId) {
          try {
            // Cargar solo algunos productos para evitar demasiadas llamadas API
            // En producción, podrías implementar una API que devuelva conteos por sucursal
            final sucProducts = await api.productos.getProductos(
              sucursalId: sucursal.id.toString(),
              pageSize: 10, // Solo obtener algunos para la demo
            );
            productosBySucursal[sucursal.id.toString()] = sucProducts.items;
          } catch (e) {
            debugPrint(
                'Error cargando productos para sucursal ${sucursal.id}: $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          _productos = paginatedProductos.items;
          _productosAgotados = agotados;
          _productosPorSucursal = productosBySucursal;
        });
      }
    } catch (e) {
      debugPrint('Error cargando productos: $e');
    }
  }

  Future<void> _loadEmpleados() async {
    try {
      final empleados = await api.empleados.getEmpleados();
      if (mounted) {
        setState(() {
          _totalEmpleados = empleados.length;
        });
      }
    } catch (e) {
      debugPrint('Error cargando empleados: $e');
    }
  }

  Future<void> _loadCategorias() async {
    try {
      if (mounted) {
        setState(() {
        });
      }
    } catch (e) {
      debugPrint('Error cargando categorías: $e');
    }
  }

  Future<void> _loadColores() async {
    try {
      if (mounted) {
        setState(() {
        });
      }
    } catch (e) {
      debugPrint('Error cargando colores: $e');
    }
  }

  Future<void> _loadVentasStats() async {
    try {
      // Simulando datos de ventas y ganancias
      // En una implementación real, deberías obtener estos datos de la API
      final random = math.Random();
      _totalVentas = 15000 + random.nextDouble() * 5000;
      _totalGanancias = _totalVentas * 0.3;

      // Idealmente, obtendrías estos datos de la API de ventas
      // final ventasStats = await api.ventas.getVentasStats(sucursalId: _sucursalSeleccionadaId);
      // _totalVentas = ventasStats.total;
      // _totalGanancias = ventasStats.ganancias;
    } catch (e) {
      debugPrint('Error cargando estadísticas de ventas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard de Administración',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF222222),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.rotate),
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await _loadData();
            },
            tooltip: 'Recargar datos',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE31E24),
              ),
            )
          : Container(
              color: const Color(0xFF111111),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    // Sección de estadísticas principales
                    FadeTransition(
                      opacity: _animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.1),
                          end: Offset.zero,
                        ).animate(_animation),
                        child: _buildMainStatsSection(isMobile),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Distribución geográfica de sucursales
                    FadeTransition(
                      opacity: _animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(_animation),
                        child: _buildSucursalesDistribution(isMobile),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMainStatsSection(bool isMobile) {
    final List<DashboardItemInfo> statsItems = [
      DashboardItemInfo(
        icon: FontAwesomeIcons.boxesStacked,
        title: 'Productos',
        value: _productos.length.toString(),
        color: Colors.blue,
        bgColor: Colors.blue.withOpacity(0.15),
      ),
      DashboardItemInfo(
        icon: FontAwesomeIcons.moneyBillWave,
        title: 'Ventas',
        value: 'S/ ${_totalVentas.toStringAsFixed(2)}',
        color: Colors.green,
        bgColor: Colors.green.withOpacity(0.15),
      ),
      DashboardItemInfo(
        icon: FontAwesomeIcons.chartLine,
        title: 'Ganancias',
        value: 'S/ ${_totalGanancias.toStringAsFixed(2)}',
        color: Colors.purple,
        bgColor: Colors.purple.withOpacity(0.15),
      ),
      DashboardItemInfo(
        icon: FontAwesomeIcons.store,
        title: 'Locales',
        value: _sucursales.length.toString(),
        color: Colors.orange,
        bgColor: Colors.orange.withOpacity(0.15),
      ),
      DashboardItemInfo(
        icon: FontAwesomeIcons.userTie,
        title: 'Colaboradores',
        value: _totalEmpleados.toString(),
        color: Colors.teal,
        bgColor: Colors.teal.withOpacity(0.15),
      ),
      DashboardItemInfo(
        icon: FontAwesomeIcons.circleExclamation,
        title: 'Productos agotados',
        value: _productosAgotados.toString(),
        color: const Color(0xFFE31E24),
        bgColor: const Color(0xFFE31E24).withOpacity(0.15),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 16),
          child: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.gaugeHigh,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Panel de Control',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        isMobile
            ? Column(
                children: statsItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildModernCard(item),
                  );
                }).toList(),
              )
            : Wrap(
                spacing: 10, // Espaciado horizontal entre tarjetas
                runSpacing: 10, // Espaciado vertical entre tarjetas
                children: statsItems.map((item) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth:
                          isMobile ? double.infinity : 200, // Ancho mínimo
                      maxWidth:
                          isMobile ? double.infinity : 300, // Ancho máximo
                    ),
                    child: _buildModernCard(item),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildModernCard(DashboardItemInfo info) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF282828),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  info.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: info.bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FaIcon(
                    info.icon,
                    color: info.color,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              info.value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: info.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSucursalesDistribution(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              FaIcon(
                FontAwesomeIcons.mapLocationDot,
                color: Colors.orange,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Distribución de locales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _sucursales.length,
            itemBuilder: (context, index) {
              final sucursal = _sucursales[index];
              return _buildSucursalCard(sucursal);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSucursalCard(Sucursal sucursal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2D2D2D),
            const Color(0xFF363636),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: sucursal.sucursalCentral
                      ? Colors.amber.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(
                  sucursal.sucursalCentral
                      ? FontAwesomeIcons.buildingFlag
                      : FontAwesomeIcons.store,
                  color: sucursal.sucursalCentral ? Colors.amber : Colors.blue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sucursal.nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (sucursal.sucursalCentral)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.amber.withOpacity(0.5),
                              ),
                            ),
                            child: const Text(
                              'CENTRAL',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sucursal.direccion,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Indicadores de productos y empleados
          Row(
            children: [
              _buildMiniStat(
                FontAwesomeIcons.boxesStacked,
                'Productos',
                '${_productosPorSucursal[sucursal.id.toString()]?.length ?? 0}',
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildMiniStat(
                FontAwesomeIcons.userTie,
                'Colaboradores',
                '3', // Este dato debería venir de una API real
                Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          FaIcon(
            icon,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
