import 'package:condorsmotors/models/estadisticas.model.dart';
import 'package:condorsmotors/providers/admin/dashboard.admin.provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Un modelo básico para el widget de estadísticas del Dashboard
class DashboardItemInfo {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color bgColor;

  const DashboardItemInfo({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.bgColor,
  });
}

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  late DashboardProvider _dashboardProvider;
  bool _isInitialized = false;
  final NumberFormat _formatoMoneda = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    debugPrint('[DashboardAdminScreen] initState');
    _dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('[DashboardAdminScreen] didChangeDependencies');
    if (!_isInitialized) {
      // Usar addPostFrameCallback para evitar errores de "setState during build"
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint('[DashboardAdminScreen] Llamando _initializeData');
          _initializeData();
        }
      });
      _isInitialized = true;
    }
  }

  Future<void> _initializeData() async {
    debugPrint('[DashboardAdminScreen] _initializeData INICIO');
    await _dashboardProvider.inicializar();
    debugPrint('[DashboardAdminScreen] _initializeData FIN');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[DashboardAdminScreen] build ejecutado');
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        debugPrint(
            '[DashboardAdminScreen] Consumer ejecutado, isLoading:  dashboardProvider.isLoading');
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
    debugPrint('[DashboardAdminScreen] _buildSummaryCards ejecutado');
    // Obtener valores de ventas desde el provider
    final ventasHoy =
        provider.resumenEstadisticas?.ventas.getVentasValue('hoy') ?? 0;
    final ventasEsteMes =
        provider.resumenEstadisticas?.ventas.getVentasValue('esteMes') ?? 0;
    final totalVentasHoy =
        provider.resumenEstadisticas?.ventas.getTotalVentasValue('hoy') ?? 0;
    final totalVentasEsteMes =
        provider.resumenEstadisticas?.ventas.getTotalVentasValue('esteMes') ??
            0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Ventas Hoy',
            '${ventasHoy.toInt()}', // Mostrar cantidad
            const FaIcon(FontAwesomeIcons.chartLine, color: Color(0xFFE31E24)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Ventas del Mes',
            '${ventasEsteMes.toInt()}', // Mostrar cantidad
            const FaIcon(FontAwesomeIcons.chartBar, color: Color(0xFFE31E24)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Ingresos Hoy',
            _formatoMoneda.format(totalVentasHoy),
            const FaIcon(FontAwesomeIcons.moneyBill, color: Color(0xFFE31E24)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Ingresos del Mes',
            _formatoMoneda.format(totalVentasEsteMes),
            const FaIcon(FontAwesomeIcons.sackDollar, color: Color(0xFFE31E24)),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Widget icon) {
    debugPrint('[DashboardAdminScreen] _buildSummaryCard ejecutado: $title');
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
    debugPrint('[DashboardAdminScreen] _buildCharts ejecutado');
    final titlesData = FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            // Solo mostrar números enteros para el eje Y
            if (value == value.roundToDouble()) {
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
          reservedSize: 30,
        ),
      ),
      rightTitles: const AxisTitles(),
      topTitles: const AxisTitles(),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) =>
              _getBottomTitles(value, meta, provider),
        ),
      ),
    );

    return Container(
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
                'Número de Ventas por Sucursal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Cantidad de ventas realizadas por cada sucursal',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: (provider.resumenEstadisticas?.ventas.sucursales.isEmpty ??
                    true)
                ? const Center(
                    child: Text(
                      'No hay datos disponibles',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxChartValue(provider),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final sucursalData =
                                provider.resumenEstadisticas?.ventas.sucursales;
                            if (sucursalData == null ||
                                sucursalData.isEmpty ||
                                groupIndex >= sucursalData.length) {
                              return null;
                            }
                            final sucursal = sucursalData[groupIndex];

                            return BarTooltipItem(
                              '${sucursal.nombre}\n'
                              'Número de ventas: ${sucursal.ventas}',
                              const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            );
                          },
                        ),
                      ),
                      titlesData: titlesData,
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withAlpha(51),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withAlpha(51),
                          ),
                          left: BorderSide(
                            color: Colors.grey.withAlpha(51),
                          ),
                        ),
                      ),
                      barGroups: _createBarGroups(provider),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _getMaxChartValue(DashboardProvider provider) {
    final ventasSucursales =
        provider.resumenEstadisticas?.ventas.sucursales ?? [];
    if (ventasSucursales.isEmpty) {
      return 10; // Valor por defecto
    }

    // Encontrar el valor máximo de ventas entre todas las sucursales
    double maxValue = 0;
    for (var sucursal in ventasSucursales) {
      if (sucursal.ventas > maxValue) {
        maxValue = sucursal.ventas.toDouble();
      }
    }

    // Si todas las ventas son 0, usar un valor mínimo para que se vea el gráfico
    if (maxValue == 0) {
      return 10;
    }

    // Añadir un margen para que las barras no lleguen al tope
    // Redondear al siguiente entero para tener una escala limpia
    return (maxValue * 1.2).ceilToDouble();
  }

  Widget _getBottomTitles(
      double value, TitleMeta meta, DashboardProvider provider) {
    const style = TextStyle(
      color: Colors.grey,
      fontSize: 12,
    );

    final sucursales = provider.resumenEstadisticas?.ventas.sucursales ?? [];
    if (sucursales.isEmpty || value.toInt() >= sucursales.length) {
      return const SizedBox.shrink();
    }

    // Mostrar solo las primeras letras del nombre de la sucursal para evitar solapamiento
    String text = sucursales[value.toInt()].nombre;
    if (text.length > 8) {
      text = '${text.substring(0, 7)}...';
    }

    return SideTitleWidget(
      meta: meta,
      child: Text(text, style: style),
    );
  }

  List<BarChartGroupData> _createBarGroups(DashboardProvider provider) {
    // Obtener las sucursales con estadísticas de ventas desde el modelo
    final ventasSucursales =
        provider.resumenEstadisticas?.ventas.sucursales ?? [];

    // Si no hay datos, mostrar barras vacías para las sucursales disponibles
    if (ventasSucursales.isEmpty) {
      return provider.sucursales.asMap().entries.map((entry) {
        final index = entry.key;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: 0,
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

    // Crear las barras con los datos reales de ventas por sucursal
    return ventasSucursales.asMap().entries.map((entry) {
      final index = entry.key;
      final sucursalEstadistica = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            // Usar cantidad de ventas para el gráfico
            toY: sucursalEstadistica.ventas.toDouble(),
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

  Widget _buildStockBajoSection(DashboardProvider provider) {
    debugPrint('[DashboardAdminScreen] _buildStockBajoSection ejecutado');
    // Verificar si tenemos datos de estadísticas
    final estadisticasProductos = provider.resumenEstadisticas?.productos;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Productos con Stock Bajo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withAlpha(51),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.redAccent, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Total: ${estadisticasProductos?.stockBajo ?? 0}',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withAlpha(51),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer_outlined,
                            color: Colors.orangeAccent, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Liquidación: ${estadisticasProductos?.liquidacion ?? 0}',
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildStockBajoContent(provider, estadisticasProductos),
        ],
      ),
    );
  }

  Widget _buildStockBajoContent(
      DashboardProvider provider, EstadisticasProductos? estadisticas) {
    debugPrint('[DashboardAdminScreen] _buildStockBajoContent ejecutado');
    // Si tenemos datos de estadísticas, mostrar el resumen por sucursal
    if (estadisticas != null &&
        (estadisticas.stockBajo > 0 || estadisticas.liquidacion > 0) &&
        estadisticas.sucursales.isNotEmpty) {
      return _buildStockBajoSucursales(estadisticas);
    } else {
      // No hay datos en ningún lado
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: Colors.grey,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'No hay productos con stock bajo',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Todos los inventarios están bien abastecidos',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildStockBajoSucursales(EstadisticasProductos estadisticas) {
    debugPrint('[DashboardAdminScreen] _buildStockBajoSucursales ejecutado');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 650),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF222222)),
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
                'Stock Bajo',
                style: TextStyle(color: Colors.white),
              ),
            ),
            DataColumn(
              label: Text(
                'Liquidación',
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
          rows: estadisticas.sucursales
              .where((sucursal) =>
                  sucursal.stockBajo > 0 || sucursal.liquidacion > 0)
              .take(5)
              .map((sucursal) {
            return DataRow(
              cells: [
                DataCell(Text(
                  sucursal.nombre,
                  style: const TextStyle(color: Colors.grey),
                )),
                DataCell(Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(26),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${sucursal.stockBajo}',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'productos',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                )),
                DataCell(Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(26),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${sucursal.liquidacion}',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'productos',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                )),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sucursal.stockBajo > 2
                        ? Colors.red.withAlpha(51)
                        : Colors.orange.withAlpha(51),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    sucursal.stockBajo > 2 ? 'Urgente' : 'Revisar',
                    style: TextStyle(
                      color:
                          sucursal.stockBajo > 2 ? Colors.red : Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRecentSales(DashboardProvider provider) {
    debugPrint('[DashboardAdminScreen] _buildRecentSales ejecutado');
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
            'Últimas Ventas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: provider.ventasRecientes.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Text(
                        'No hay ventas recientes disponibles',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 650),
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(const Color(0xFF222222)),
                      columnSpacing: 16,
                      horizontalMargin: 12,
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Fecha/Hora',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Documento',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Sucursal',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Monto',
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
                            DataCell(Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  venta.factura,
                                  style: const TextStyle(color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (venta.tipoDocumento != null &&
                                    venta.tipoDocumento!.isNotEmpty)
                                  Text(
                                    venta.tipoDocumento!,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            )),
                            DataCell(Text(
                              venta.sucursalNombre ?? 'No especificada',
                              style: const TextStyle(color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            )),
                            DataCell(Text(
                              _formatoMoneda.format(venta.monto),
                              style: const TextStyle(color: Colors.grey),
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
