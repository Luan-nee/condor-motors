import 'package:condorsmotors/providers/admin/dashboard.admin.riverpod.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DashboardCharts extends StatelessWidget {
  final DashboardAdminState state;

  const DashboardCharts({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
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
              _getBottomTitles(value, meta, state),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
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
            child: (state.resumenEstadisticas?.ventas.sucursales.isEmpty ??
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
                      maxY: _getMaxChartValue(state),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final sucursalData =
                                state.resumenEstadisticas?.ventas.sucursales;
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
                      barGroups: _createBarGroups(state),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _getMaxChartValue(DashboardAdminState state) {
    final ventasSucursales = state.resumenEstadisticas?.ventas.sucursales ?? [];
    if (ventasSucursales.isEmpty) {
      return 10; // Valor por defecto
    }

    // Encontrar el valor máximo de ventas entre todas las sucursales
    double maxValue = 0;
    for (final sucursal in ventasSucursales) {
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
      double value, TitleMeta meta, DashboardAdminState state) {
    const style = TextStyle(
      color: Colors.grey,
      fontSize: 12,
    );

    final sucursales = state.resumenEstadisticas?.ventas.sucursales ?? [];
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

  List<BarChartGroupData> _createBarGroups(DashboardAdminState state) {
    // Obtener las sucursales con estadísticas de ventas desde el modelo
    final ventasSucursales = state.resumenEstadisticas?.ventas.sucursales ?? [];

    // Si no hay datos, mostrar barras vacías para las sucursales disponibles
    if (ventasSucursales.isEmpty) {
      return state.sucursales.asMap().entries.map((entry) {
        final index = entry.key;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: 0,
              color: AppTheme.primaryColor,
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
            color: AppTheme.primaryColor,
            width: 16,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }
}
