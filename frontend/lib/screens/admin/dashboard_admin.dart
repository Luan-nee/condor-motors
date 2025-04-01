import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/providers/admin/dashboard.provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

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
  late AnimationController _animationController;
  late Animation<double> _animation;
  late DashboardProvider _dashboardProvider;

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

    // Inicializar provider
    _dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    _dashboardProvider.inicializar();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    return Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, child) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Dashboard de Administración',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF222222),
          actions: <Widget>[
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.rotate),
              onPressed: dashboardProvider.recargarDatos,
              tooltip: 'Recargar datos',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: dashboardProvider.isLoading
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
                    children: <Widget>[
                      // Sección de estadísticas principales
                      FadeTransition(
                        opacity: _animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -0.1),
                            end: Offset.zero,
                          ).animate(_animation),
                          child: _buildMainStatsSection(
                              isMobile, dashboardProvider),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Placeholder para gráfico de ventas (se implementará más adelante)
                      FadeTransition(
                        opacity: _animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.05),
                            end: Offset.zero,
                          ).animate(_animation),
                          child: _buildVentasChart(dashboardProvider),
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
                          child: _buildSucursalesDistribution(
                              isMobile, dashboardProvider),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      );
    });
  }

  Widget _buildMainStatsSection(bool isMobile, DashboardProvider provider) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final List<DashboardItemInfo> statsItems = <DashboardItemInfo>[
      DashboardItemInfo(
        icon: FontAwesomeIcons.boxesStacked,
        title: 'Productos',
        value: provider.productos.length.toString(),
        color: Colors.blue,
        bgColor: Colors.blue.withOpacity(0.15),
      ),
      DashboardItemInfo(
        icon: FontAwesomeIcons.moneyBillWave,
        title: 'Ventas',
        value: 'S/ ${provider.totalVentas.toStringAsFixed(2)}',
        color: Colors.green,
        bgColor: Colors.green.withOpacity(0.15),
      ),
      DashboardItemInfo(
        icon: FontAwesomeIcons.store,
        title: 'Locales',
        value: provider.sucursales.length.toString(),
        color: Colors.orange,
        bgColor: Colors.orange.withOpacity(0.15),
      ),
      DashboardItemInfo(
        icon: FontAwesomeIcons.userTie,
        title: 'Colaboradores',
        value: provider.totalEmpleados.toString(),
        color: Colors.teal,
        bgColor: Colors.teal.withOpacity(0.15),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 16),
          child: Row(
            children: <Widget>[
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
                children: statsItems.map((DashboardItemInfo item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildModernCard(item),
                  );
                }).toList(),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: screenWidth > 1200 ? 4 : 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: statsItems.length,
                itemBuilder: (context, index) {
                  return _buildModernCard(statsItems[index]);
                },
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
          colors: const [
            Color(0xFF1A1A1A),
            Color(0xFF282828),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
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

  Widget _buildVentasChart(DashboardProvider provider) {
    // Simplemente mostrar un contenedor con un mensaje
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(20),
      height: 200, // Altura reducida para el placeholder
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.chartLine,
            color: Colors.grey,
            size: 36,
          ),
          SizedBox(height: 16),
          Text(
            'Gráfico de ventas mensuales',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Los gráficos estadísticos serán implementados próximamente',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSucursalesDistribution(
      bool isMobile, DashboardProvider provider) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
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
        children: <Widget>[
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
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
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile
                  ? 1
                  : screenWidth > 1200
                      ? 3
                      : 2,
              childAspectRatio: 2.0,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: provider.sucursales.length,
            itemBuilder: (BuildContext context, int index) {
              final Sucursal sucursal = provider.sucursales[index];
              return _buildSucursalCard(sucursal, provider);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSucursalCard(Sucursal sucursal, DashboardProvider provider) {
    // Obtener la lista de productos para esta sucursal
    final List<dynamic> productosSucursal =
        provider.productosPorSucursal[sucursal.id.toString()] ?? [];

    // Contar productos con stock bajo (menos de 5 unidades)
    final int productosStockBajo = productosSucursal
        .where((producto) =>
            producto.stock != null && producto.stock > 0 && producto.stock < 5)
        .length;

    // Contar productos agotados
    final int productosAgotados = productosSucursal
        .where((producto) => producto.stock == null || producto.stock <= 0)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: sucursal.sucursalCentral
              ? [
                  const Color(0xFF352D1A),
                  const Color(0xFF3D3523),
                ]
              : [
                  const Color(0xFF2D2D2D),
                  const Color(0xFF363636),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
        border: sucursal.sucursalCentral
            ? Border.all(
                color: Colors.amber.withOpacity(0.5),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
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
                  children: <Widget>[
                    Row(
                      children: <Widget>[
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
                      sucursal.direccion ?? 'Sin dirección registrada',
                      style: TextStyle(
                        color: sucursal.direccion != null
                            ? Colors.white.withOpacity(0.7)
                            : Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontStyle: sucursal.direccion != null
                            ? FontStyle.normal
                            : FontStyle.italic,
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

          // Indicadores de productos y stock
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _buildMiniStat(
                    FontAwesomeIcons.boxesStacked,
                    'Productos',
                    '${productosSucursal.length}',
                    Colors.blue,
                  ),
                  _buildMiniStat(
                    FontAwesomeIcons.userTie,
                    'Colaboradores',
                    '3', // Este dato debería venir de una API real
                    Colors.teal,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _buildMiniStat(
                    FontAwesomeIcons.triangleExclamation,
                    'Stock bajo',
                    '$productosStockBajo',
                    Colors.orange,
                  ),
                  _buildMiniStat(
                    FontAwesomeIcons.circleExclamation,
                    'Agotados',
                    '$productosAgotados',
                    const Color(0xFFE31E24),
                  ),
                ],
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
        children: <Widget>[
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
