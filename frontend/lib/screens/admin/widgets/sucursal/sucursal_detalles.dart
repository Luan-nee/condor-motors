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

  Widget _buildInfoSection(String title, String primaryInfo,
      String secondaryInfo, bool isConfigured) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isConfigured
            ? const Color(0xFF2D2D2D)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConfigured
              ? Colors.grey.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isConfigured ? Icons.check_circle : Icons.error_outline,
                color: isConfigured ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            primaryInfo,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          if (secondaryInfo.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              secondaryInfo,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final IconData icon = _getIconForSucursal(sucursal);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: sucursal.sucursalCentral
              ? const Color(0xFFE31E24).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de la tarjeta
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sucursal.sucursalCentral
                  ? const Color(0xFFE31E24).withOpacity(0.1)
                  : const Color(0xFF2D2D2D),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: sucursal.sucursalCentral
                        ? const Color(0xFFE31E24).withOpacity(0.2)
                        : Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FaIcon(
                    icon,
                    color: sucursal.sucursalCentral
                        ? const Color(0xFFE31E24)
                        : Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              sucursal.nombre,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: sucursal.sucursalCentral
                                  ? const Color(0xFFE31E24).withOpacity(0.2)
                                  : Colors.black26,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              sucursal.sucursalCentral ? 'CENTRAL' : 'LOCAL',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: sucursal.sucursalCentral
                                    ? const Color(0xFFE31E24)
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sucursal.direccion ?? 'Sin dirección registrada',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontStyle: sucursal.direccion == null
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Detalles y configuración
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección de información de configuración
                const Text(
                  'Configuración de Facturación',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // Configuración de series y números
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoSection(
                        'Factura',
                        'Serie: ${sucursal.serieFactura ?? 'No configurada'}',
                        'Inicio: ${sucursal.numeroFacturaInicial ?? 1}',
                        sucursal.serieFactura != null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoSection(
                        'Boleta',
                        'Serie: ${sucursal.serieBoleta ?? 'No configurada'}',
                        'Inicio: ${sucursal.numeroBoletaInicial ?? 1}',
                        sucursal.serieBoleta != null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                // Código de establecimiento
                _buildInfoSection(
                  'Código de Establecimiento',
                  sucursal.codigoEstablecimiento ?? 'No configurado',
                  '',
                  sucursal.codigoEstablecimiento != null,
                ),

                const SizedBox(height: 16),
                const Divider(color: Colors.grey),

                // Información de tiempo y acciones
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Creado: ${_formatDate(sucursal.fechaCreacion)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const FaIcon(
                            FontAwesomeIcons.penToSquare,
                            size: 18,
                            color: Colors.white70,
                          ),
                          tooltip: 'Editar sucursal',
                          onPressed: onEdit,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 22,
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
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Sucursal>('sucursal', sucursal));
    properties.add(ObjectFlagProperty<VoidCallback>.has('onEdit', onEdit));
    properties.add(ObjectFlagProperty<VoidCallback>.has('onDelete', onDelete));
  }
}
