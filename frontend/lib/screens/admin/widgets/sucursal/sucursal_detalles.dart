import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SucursalDetalles extends StatelessWidget {
  final Sucursal sucursal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SucursalDetalles({
    super.key,
    required this.sucursal,
    required this.onEdit,
    required this.onDelete,
  });

  // Método para obtener icono según la sucursal
  IconData _getIconForSucursal(Sucursal sucursal) {
    // Primero revisamos si es sucursal central
    if (sucursal.sucursalCentral) {
      return FontAwesomeIcons.building;
    }

    // Luego revisamos el nombre
    final String nombre = sucursal.nombre.toLowerCase();
    if (nombre.contains('central') || nombre.contains('principal')) {
      return FontAwesomeIcons.building;
    } else if (nombre.contains('taller')) {
      return FontAwesomeIcons.screwdriverWrench;
    } else if (nombre.contains('almacén') ||
        nombre.contains('almacen') ||
        nombre.contains('bodega')) {
      return FontAwesomeIcons.warehouse;
    } else if (nombre.contains('tienda') || nombre.contains('venta')) {
      return FontAwesomeIcons.store;
    }
    return FontAwesomeIcons.locationDot;
  }

  @override
  Widget build(BuildContext context) {
    final IconData icon = _getIconForSucursal(sucursal);

    return SizedBox(
      width: 180,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        color: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: sucursal.sucursalCentral
                ? const Color(0xFFE31E24).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Encabezado más compacto
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: sucursal.sucursalCentral
                      ? const Color(0xFFE31E24).withValues(alpha: 0.1)
                      : const Color(0xFF2D2D2D),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icono y nombre
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: sucursal.sucursalCentral
                                ? const Color(0xFFE31E24).withValues(alpha: 0.2)
                                : Colors.black26,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FaIcon(
                            icon,
                            color: sucursal.sucursalCentral
                                ? const Color(0xFFE31E24)
                                : Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 140,
                          child: Text(
                            sucursal.nombre,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Badges de estado
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: sucursal.sucursalCentral
                                ? const Color(0xFFE31E24).withValues(alpha: 0.2)
                                : Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            sucursal.sucursalCentral ? 'CENTRAL' : 'LOCAL',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: sucursal.sucursalCentral
                                  ? const Color(0xFFE31E24)
                                  : Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.users,
                                size: 11,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${sucursal.totalEmpleados}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
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
              ),

              // Contenido
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dirección
                    if (sucursal.direccion != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.locationDot,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                sucursal.direccion!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Grid de información
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'Código',
                            sucursal.codigoEstablecimiento ?? 'No configurado',
                            FontAwesomeIcons.buildingUser,
                            isConfigured:
                                sucursal.codigoEstablecimiento != null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSerieCard(
                            'Facturación',
                            sucursal.serieFactura,
                            sucursal.numeroFacturaInicial,
                            FontAwesomeIcons.fileInvoiceDollar,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSerieCard(
                            'Boletas',
                            sucursal.serieBoleta,
                            sucursal.numeroBoletaInicial,
                            FontAwesomeIcons.receipt,
                          ),
                        ),
                      ],
                    ),

                    const Divider(
                      color: Colors.grey,
                      height: 20,
                    ),

                    // Pie con fechas y acciones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Wrap(
                          spacing: 12,
                          children: [
                            _buildDateInfo(
                              'Creado',
                              sucursal.fechaCreacion,
                              FontAwesomeIcons.clock,
                            ),
                            _buildDateInfo(
                              'Actualizado',
                              sucursal.fechaActualizacion,
                              FontAwesomeIcons.clockRotateLeft,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const FaIcon(
                                FontAwesomeIcons.penToSquare,
                                size: 18,
                                color: Colors.white70,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              tooltip: 'Editar sucursal',
                              onPressed: onEdit,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 22,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              tooltip: 'Eliminar sucursal',
                              onPressed: onDelete,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon, {
    bool isConfigured = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isConfigured
            ? const Color(0xFF2D2D2D)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isConfigured
              ? Colors.grey.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                icon,
                size: 14,
                color: isConfigured ? Colors.white70 : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: isConfigured ? Colors.white70 : Colors.red,
              fontStyle: isConfigured ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSerieCard(
    String title,
    String? serie,
    int? numeroInicial,
    IconData icon,
  ) {
    final bool isConfigured = serie != null;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isConfigured
            ? const Color(0xFF2D2D2D)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isConfigured
              ? Colors.grey.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                icon,
                size: 14,
                color: isConfigured ? Colors.white70 : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          if (isConfigured) ...[
            const SizedBox(height: 6),
            Text(
              'Serie: $serie',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white70,
              ),
            ),
            Text(
              'Inicio: $numeroInicial',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white54,
              ),
            ),
          ] else
            Text(
              'No configurado',
              style: TextStyle(
                fontSize: 15,
                color: Colors.red.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(String label, DateTime date, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(
          icon,
          size: 12,
          color: Colors.white54,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ${_formatDate(date)}',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Sucursal>('sucursal', sucursal))
      ..add(ObjectFlagProperty<VoidCallback>.has('onEdit', onEdit))
      ..add(ObjectFlagProperty<VoidCallback>.has('onDelete', onDelete));
  }
}
