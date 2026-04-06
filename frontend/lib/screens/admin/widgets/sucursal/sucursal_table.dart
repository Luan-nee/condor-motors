import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/screens/admin/widgets/sucursal/sucursal_row.dart';
import 'package:flutter/material.dart';

class SucursalTable extends StatelessWidget {
  final List<Sucursal> sucursales;
  final Function(Sucursal) onDetails;
  final Function(Sucursal) onEdit;
  final Function(Sucursal) onDelete;
  final ScrollController? scrollController;
  final bool shrinkWrap;

  const SucursalTable({
    super.key,
    required this.sucursales,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
    this.scrollController,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF2A2A2A),
            child: Row(
              children: [
                const SizedBox(width: 36),
                Expanded(
                  flex: 4,
                  child: Text(
                    'NOMBRE / CÓDIGO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'DIRECCIÓN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'SERIE FACTURA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'SERIE BOLETA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 110),
              ],
            ),
          ),

          // List
          if (shrinkWrap)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sucursales.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: Color(0xFF333333),
              ),
              itemBuilder: (context, index) {
                final sucursal = sucursales[index];
                return SucursalRow(
                  sucursal: sucursal,
                  onTap: () => onDetails(sucursal),
                  onEdit: () => onEdit(sucursal),
                  onDelete: () => onDelete(sucursal),
                );
              },
            )
          else
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: sucursales.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  color: Color(0xFF333333),
                ),
                itemBuilder: (context, index) {
                  final sucursal = sucursales[index];
                  return SucursalRow(
                    sucursal: sucursal,
                    onTap: () => onDetails(sucursal),
                    onEdit: () => onEdit(sucursal),
                    onDelete: () => onDelete(sucursal),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
