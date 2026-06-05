import 'package:condorsmotors/providers/admin/dashboard.admin.riverpod.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class DashboardSummaryCards extends StatelessWidget {
  final DashboardAdminState state;
  final VoidCallback onReload;

  const DashboardSummaryCards({
    super.key,
    required this.state,
    required this.onReload,
  });

  static final NumberFormat _formatoMoneda = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    // Obtener valores de ventas desde el provider
    final ventasHoy =
        state.resumenEstadisticas?.ventas.getVentasValue('hoy') ?? 0;
    final ventasEsteMes =
        state.resumenEstadisticas?.ventas.getVentasValue('esteMes') ?? 0;
    final totalVentasHoy =
        state.resumenEstadisticas?.ventas.getTotalVentasValue('hoy') ?? 0;
    final totalVentasEsteMes =
        state.resumenEstadisticas?.ventas.getTotalVentasValue('esteMes') ?? 0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Ventas Hoy',
              '${ventasHoy.toInt()}', // Mostrar cantidad
              const FaIcon(FontAwesomeIcons.chartLine, color: AppTheme.primaryColor, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Ventas del Mes',
              '${ventasEsteMes.toInt()}', // Mostrar cantidad
              const FaIcon(FontAwesomeIcons.chartBar, color: AppTheme.primaryColor, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Ingresos Hoy',
              _formatoMoneda.format(totalVentasHoy),
              const FaIcon(FontAwesomeIcons.moneyBill, color: AppTheme.primaryColor, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Ingresos del Mes',
              _formatoMoneda.format(totalVentasEsteMes),
              const FaIcon(FontAwesomeIcons.sackDollar, color: AppTheme.primaryColor, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          // Botón de recargar en forma de Card
          SizedBox(
            width: 120,
            child: _buildReloadCard(onReload),
          ),
        ],
      ),
    );
  }

  Widget _buildReloadCard(VoidCallback onPressed) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(
          color: Colors.grey.withAlpha(50),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          onTap: onPressed,
          hoverColor: AppTheme.surfaceColor.withValues(alpha: 0.4),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.arrowsRotate,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                SizedBox(height: 8),
                Text(
                  'Recargar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Widget icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(
          color: Colors.grey.withAlpha(50),
        ),
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
          const SizedBox(height: 8),
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
}
