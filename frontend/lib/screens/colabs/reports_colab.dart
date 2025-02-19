import 'package:flutter/material.dart';

class ReportsColabScreen extends StatelessWidget {
  const ReportsColabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reportes y Estadísticas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildReportCard(
                  context,
                  'Reporte de Ventas',
                  Icons.bar_chart,
                  Colors.blue,
                  () {},
                ),
                _buildReportCard(
                  context,
                  'Reporte de Inventario',
                  Icons.inventory_2,
                  Colors.green,
                  () {},
                ),
                _buildReportCard(
                  context,
                  'Productos Más Vendidos',
                  Icons.trending_up,
                  Colors.orange,
                  () {},
                ),
                _buildReportCard(
                  context,
                  'Stock Bajo',
                  Icons.warning,
                  Colors.red,
                  () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
