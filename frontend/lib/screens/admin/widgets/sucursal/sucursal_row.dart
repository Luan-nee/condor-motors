import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/utils/sucursal_utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SucursalRow extends StatelessWidget {
  final Sucursal sucursal;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SucursalRow({
    super.key,
    required this.sucursal,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon = SucursalUtils.getIconForSucursal(sucursal);
    final Color iconColor = SucursalUtils.getColorForSucursal(sucursal);
    final Color iconBgColor = SucursalUtils.getIconBackgroundColor(sucursal);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icono
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Nombre y Código
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sucursal.nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (sucursal.codigoEstablecimiento != null)
                          SucursalUtils.buildCodigoEstablecimiento(
                            sucursal.codigoEstablecimiento,
                          ),
                        if (sucursal.sucursalCentral) ...[
                          const SizedBox(width: 8),
                          SucursalUtils.buildTipoSucursalBadge(sucursal),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Dirección
              Expanded(
                flex: 4,
                child: Text(
                  sucursal.direccion ?? 'Sin dirección',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontStyle: sucursal.direccion == null
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Serie Factura
              Expanded(
                flex: 2,
                child: SucursalUtils.buildSerieInfo(
                  sucursal.serieFactura,
                  sucursal.numeroFacturaInicial,
                ),
              ),

              // Serie Boleta
              Expanded(
                flex: 2,
                child: SucursalUtils.buildSerieInfo(
                  sucursal.serieBoleta,
                  sucursal.numeroBoletaInicial,
                ),
              ),

              // Acciones
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.eye,
                      size: 16,
                      color: Colors.white70,
                    ),
                    tooltip: 'Ver detalles',
                    onPressed: onTap,
                  ),
                  IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.penToSquare,
                      size: 16,
                      color: Colors.white70,
                    ),
                    tooltip: 'Editar sucursal',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      size: 18,
                      color: Colors.red,
                    ),
                    tooltip: 'Eliminar sucursal',
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
