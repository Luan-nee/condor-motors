import 'package:condorsmotors/providers/admin/dashboard.admin.riverpod.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardRecentSales extends StatelessWidget {
  final DashboardAdminState state;

  const DashboardRecentSales({
    super.key,
    required this.state,
  });

  static final NumberFormat _formatoMoneda = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Últimas Ventas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              child: state.ventasRecientes.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          'No hay ventas recientes disponibles',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(AppTheme.deepSurface),
                      columnSpacing: 10,
                      horizontalMargin: 8,
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Fecha',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Doc.',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Monto',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                      rows: state.ventasRecientes.take(5).map((venta) {
                        return DataRow(
                          cells: [
                            DataCell(Text(
                              venta.fecha,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            )),
                            DataCell(Text(
                              venta.factura,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            )),
                            DataCell(Text(
                              _formatoMoneda.format(venta.monto),
                              style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            )),
                          ],
                        );
                      }).toList(),
                    ),
            );
          }),
        ],
      ),
    );
  }
}
