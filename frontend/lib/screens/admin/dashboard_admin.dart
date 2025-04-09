import 'package:condorsmotors/providers/admin/dashboard.admin.provider.dart';
import 'package:fl_chart/fl_chart.dart';
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

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  late DashboardProvider _dashboardProvider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeData();
      _isInitialized = true;
    }
  }

  Future<void> _initializeData() async {
    await _dashboardProvider.inicializar();
  }

  @override
  Widget build(BuildContext context) {
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCards(dashboardProvider),
                        const SizedBox(height: 24),
                        _buildCharts(dashboardProvider),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildRecentSales(dashboardProvider),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStockBajoSection(dashboardProvider),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSummaryCards(DashboardProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Ventas Hoy',
            'S/ ${provider.ventasHoy.toStringAsFixed(2)}',
            const FaIcon(FontAwesomeIcons.chartLine, color: Color(0xFFE31E24)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Ventas Totales',
            'S/ ${provider.totalVentas.toStringAsFixed(2)}',
            const FaIcon(FontAwesomeIcons.chartBar, color: Color(0xFFE31E24)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Ingresos Hoy',
            'S/ ${provider.ingresosHoy.toStringAsFixed(2)}',
            const FaIcon(FontAwesomeIcons.chartArea, color: Color(0xFFE31E24)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Ingresos Totales',
            'S/ ${provider.totalGanancias.toStringAsFixed(2)}',
            const FaIcon(FontAwesomeIcons.chartPie, color: Color(0xFFE31E24)),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Widget icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(DashboardProvider provider) {
    final titlesData = FlTitlesData(
      leftTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      topTitles: const AxisTitles(),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: _getBottomTitles,
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ventas por Sucursal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ver Todo',
                      style: TextStyle(
                        color: Color(0xFFE31E24),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: provider.totalVentas * 1.2,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: titlesData,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: _createBarGroups(provider),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ventas y Ganancias',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ver Todo',
                      style: TextStyle(
                        color: Color(0xFFE31E24),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: titlesData,
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _createLineSpots(provider.ventasMensuales),
                          isCurved: true,
                          color: const Color(0xFFE31E24),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFFE31E24).withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontSize: 12,
    );
    String text = value.toInt().toString();
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(text, style: style),
    );
  }

  List<BarChartGroupData> _createBarGroups(DashboardProvider provider) {
    return provider.sucursales.asMap().entries.map((entry) {
      final index = entry.key;
      final sucursal = entry.value;
      final ventasSucursal =
          provider.productosPorSucursal[sucursal.id.toString()]?.length ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: ventasSucursal.toDouble(),
            color: const Color(0xFFE31E24),
            width: 16,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  List<FlSpot> _createLineSpots(List<double> data) {
    return data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }

  Widget _buildStockBajoSection(DashboardProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Productos con Stock Bajo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 650),
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFF222222)),
                columnSpacing: 20,
                horizontalMargin: 12,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Sucursal',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Producto',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Stock',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Estado',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
                rows:
                    provider.productosStockBajoDetalle.take(5).map((producto) {
                  final bool stockCritico =
                      producto['stock'] <= (producto['stockMinimo'] / 2);
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        producto['sucursalNombre'],
                        style: const TextStyle(color: Colors.grey),
                      )),
                      DataCell(Text(
                        producto['productoNombre'],
                        style: const TextStyle(color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      )),
                      DataCell(Text(
                        '${producto['stock']}/${producto['stockMinimo']}',
                        style: const TextStyle(color: Colors.grey),
                      )),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: stockCritico
                              ? Colors.red.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          stockCritico ? 'Crítico' : 'Bajo',
                          style: TextStyle(
                            color: stockCritico ? Colors.red : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSales(DashboardProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ventas Recientes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 650),
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFF222222)),
                columnSpacing: 20,
                horizontalMargin: 12,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Fecha',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Cliente',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Monto',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Estado',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
                rows: provider.ventasRecientes.take(5).map((venta) {
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        venta.fecha,
                        style: const TextStyle(color: Colors.grey),
                      )),
                      DataCell(Text(
                        venta.cliente,
                        style: const TextStyle(color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      )),
                      DataCell(Text(
                        'S/ ${venta.monto.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.grey),
                      )),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: venta.estado == 'Pagado'
                              ? Colors.green.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          venta.estado,
                          style: TextStyle(
                            color: venta.estado == 'Pagado'
                                ? Colors.green
                                : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
