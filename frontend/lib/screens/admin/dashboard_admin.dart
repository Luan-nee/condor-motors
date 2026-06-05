import 'package:condorsmotors/providers/admin/dashboard.admin.riverpod.dart';
import 'package:condorsmotors/screens/admin/widgets/dashboard/dashboard_charts.dart';
import 'package:condorsmotors/screens/admin/widgets/dashboard/dashboard_recent_sales.dart';
import 'package:condorsmotors/screens/admin/widgets/dashboard/dashboard_stock_bajo.dart';
import 'package:condorsmotors/screens/admin/widgets/dashboard/dashboard_summary_cards.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardAdminScreen extends ConsumerStatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  ConsumerState<DashboardAdminScreen> createState() =>
      _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends ConsumerState<DashboardAdminScreen> {
  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(dashboardAdminProvider.select((s) => s.isLoading));
    final state = ref.watch(dashboardAdminProvider);
    final notifier = ref.read(dashboardAdminProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardSummaryCards(
                    state: state,
                    onReload: notifier.recargarDatos,
                  ),
                  const SizedBox(height: 24),
                  DashboardCharts(state: state),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: DashboardRecentSales(state: state),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 5,
                        child: DashboardStockBajo(state: state),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
