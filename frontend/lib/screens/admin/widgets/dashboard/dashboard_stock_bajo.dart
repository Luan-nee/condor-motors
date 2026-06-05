import 'package:condorsmotors/models/estadisticas.model.dart';
import 'package:condorsmotors/providers/admin/dashboard.admin.riverpod.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:flutter/material.dart';

class DashboardStockBajo extends StatelessWidget {
  final DashboardAdminState state;

  const DashboardStockBajo({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    // Verificar si tenemos datos de estadísticas
    final estadisticasProductos = state.resumenEstadisticas?.productos;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
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
                      borderRadius: BorderRadius.circular(AppTheme.largeRadius),
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
                      borderRadius: BorderRadius.circular(AppTheme.largeRadius),
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
          _buildStockBajoContent(estadisticasProductos),
        ],
      ),
    );
  }

  Widget _buildStockBajoContent(EstadisticasProductos? estadisticas) {
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
    return LayoutBuilder(builder: (context, constraints) {
      return SizedBox(
        width: constraints.maxWidth,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.deepSurface),
          columnSpacing: 10,
          horizontalMargin: 8,
          columns: const [
            DataColumn(
              label: Text(
                'Sucursal',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            DataColumn(
              label: Text(
                'Stock',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            DataColumn(
              label: Text(
                'Liq.',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            DataColumn(
              label: Text(
                'Estado',
                style: TextStyle(color: Colors.white, fontSize: 13),
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
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                )),
                DataCell(Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${sucursal.stockBajo}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )),
                DataCell(Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${sucursal.liquidacion}',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
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
                      fontSize: 11,
                    ),
                  ),
                )),
              ],
            );
          }).toList(),
        ),
      );
    });
  }
}
