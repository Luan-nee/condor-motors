import 'package:condorsmotors/models/ventas.model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class VentaDetalleDialog extends StatelessWidget {
  final dynamic venta;
  final NumberFormat _formatoMoneda = NumberFormat.currency(
    symbol: 'S/ ',
    decimalDigits: 2,
  );
  final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

  VentaDetalleDialog({
    super.key,
    required this.venta,
  });

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<dynamic>('venta', venta));
  }

  @override
  Widget build(BuildContext context) {
    // Verificar si es un objeto Map o un objeto Venta
    final bool isMap = venta is Map;
    final bool isVenta = venta is Venta;

    // Extraer información común según el tipo
    final String idVenta = isMap ? venta['id'].toString() : venta.id.toString();
    final DateTime fechaCreacion = isMap
        ? (venta['fechaCreacion'] != null
            ? DateTime.parse(venta['fechaCreacion'])
            : (venta['fecha_creacion'] != null
                ? DateTime.parse(venta['fecha_creacion'])
                : DateTime.now()))
        : venta.fechaCreacion;

    final String serie = isMap
        ? (venta['serieDocumento'] ?? '').toString()
        : venta.serieDocumento;

    final String numero = isMap
        ? (venta['numeroDocumento'] ?? '').toString()
        : venta.numeroDocumento;

    final String observaciones = isMap
        ? (venta['observaciones'] ?? '').toString()
        : (venta.observaciones ?? '');

    // Manejar el caso donde el estado puede venir como objeto o como string
    String estadoText;
    if (isMap) {
      if (venta['estado'] is Map) {
        // Formato del ejemplo JSON: {"codigo": "aceptado-sunat", "nombre": "Aceptado ante la sunat"}
        estadoText = ((venta['estado'] as Map)['nombre'] ?? 'PENDIENTE')
            .toString()
            .toUpperCase();
      } else {
        estadoText = (venta['estado'] ?? 'PENDIENTE').toString().toUpperCase();
      }
    } else {
      estadoText = isVenta ? venta.estado.toText() : 'PENDIENTE';
    }

    // Datos del documento
    final String tipoDocumento = isMap
        ? (venta['tipoDocumento'] ?? '').toString()
        : (isVenta ? (venta.tipoDocumento ?? '') : '');

    // Datos del cliente
    final clienteNombre = isMap
        ? (venta['cliente'] != null
            ? venta['cliente']['denominacion'] ?? 'Cliente no especificado'
            : 'Cliente no especificado')
        : isVenta && venta.clienteDetalle != null
            ? venta.clienteDetalle!.denominacion
            : 'Cliente no especificado';

    final clienteDocumento = isMap
        ? (venta['cliente'] != null
            ? '${venta['cliente']['tipoDocumento'] ?? ''}: ${venta['cliente']['numeroDocumento'] ?? ''}'
            : '')
        : isVenta && venta.clienteDetalle != null
            ? '${venta.clienteDetalle!.tipoDocumento ?? ''}: ${venta.clienteDetalle!.numeroDocumento ?? ''}'
            : '';

    // Datos del empleado
    final empleadoNombre = isMap
        ? (venta['empleado'] != null
            ? '${venta['empleado']['nombre'] ?? ''} ${venta['empleado']['apellidos'] ?? ''}'
            : 'Empleado no especificado')
        : isVenta && venta.empleadoDetalle != null
            ? venta.empleadoDetalle!.getNombreCompleto()
            : 'Empleado no especificado';

    // Datos de la sucursal
    final sucursalNombre = isMap
        ? (venta['sucursal'] != null
            ? venta['sucursal']['nombre'] ?? 'Sucursal no especificada'
            : 'Sucursal no especificada')
        : isVenta && venta.sucursalDetalle != null
            ? venta.sucursalDetalle!.nombre
            : 'Sucursal no especificada';

    // Documentos de facturación
    final tieneDocs = isMap
        ? venta['documentoFacturacion'] != null
        : isVenta && venta.documentoFacturacion != null;

    final String? linkPdf = isMap
        ? (venta['documentoFacturacion'] != null
            ? venta['documentoFacturacion']['linkPdf']
            : null)
        : isVenta && venta.documentoFacturacion != null
            ? venta.documentoFacturacion!.linkPdf
            : null;

    // Información SUNAT
    Map<String, dynamic>? infoSunat;
    if (isMap && venta['documentoFacturacion'] != null) {
      infoSunat = venta['documentoFacturacion']['informacionSunat']
          as Map<String, dynamic>?;
    } else if (isVenta && venta.documentoFacturacion != null) {
      infoSunat = venta.documentoFacturacion!.informacionSunat;
    }

    final String estadoSunat = infoSunat != null
        ? infoSunat['description'] ?? 'No disponible'
        : 'No disponible';

    // Obtener los detalles de la venta
    List<dynamic> detalles;
    if (isMap) {
      // Primero intentamos con 'detallesVenta' como en el ejemplo JSON
      if (venta['detallesVenta'] is List) {
        detalles = venta['detallesVenta'];
      }
      // Luego con 'detalles' como alternativa
      else if (venta['detalles'] is List) {
        detalles = venta['detalles'];
      } else {
        detalles = [];
      }
    } else {
      detalles = venta.detalles;
    }

    // Calcular el total
    double total = 0.0;
    if (isMap) {
      // Intentar obtener el total del formato del ejemplo JSON
      if (venta['totalesVenta'] != null &&
          venta['totalesVenta']['totalVenta'] != null) {
        final totalValue = venta['totalesVenta']['totalVenta'];
        if (totalValue is String) {
          total = double.tryParse(totalValue) ?? 0.0;
        } else {
          total = (totalValue ?? 0.0).toDouble();
        }
      } else {
        // Fallback al método existente
        total = _calcularTotal(venta);
      }
    } else {
      total = venta.calcularTotal();
    }

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera del diálogo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.fileInvoice,
                          color: Color(0xFFE31E24),
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serie.isNotEmpty && numero.isNotEmpty
                              ? '$serie-$numero'
                              : 'Venta #$idVenta',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatoFecha.format(fechaCreacion),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Información general
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información General',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Primera fila: ID, estado, total
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ID de Venta',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              idVenta,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estado',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getEstadoColor(estadoText)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                estadoText,
                                style: TextStyle(
                                  color: _getEstadoColor(estadoText),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatoMoneda.format(total),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Segunda fila: Tipo documento, Serie-Número, Cliente
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tipo de Documento',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tipoDocumento,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Serie-Número',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              serie.isNotEmpty && numero.isNotEmpty
                                  ? '$serie-$numero'
                                  : 'No registrado',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cliente',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              clienteNombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (clienteDocumento.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    // Tercera fila: Documento cliente, empleado, sucursal
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Documento Cliente',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                clienteDocumento,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Empleado',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                empleadoNombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sucursal',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sucursalNombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (observaciones.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Observaciones',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      observaciones,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],

                  // Información de facturación electrónica
                  if (tieneDocs) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    const Text(
                      'Facturación Electrónica',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estado SUNAT',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                estadoSunat,
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (linkPdf != null) ...[
                          ElevatedButton.icon(
                            icon: const FaIcon(
                              FontAwesomeIcons.filePdf,
                              size: 16,
                            ),
                            label: const Text('Ver PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE31E24),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              _abrirUrl(linkPdf);
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Listado de productos
            const Text(
              'Líneas de Productos',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),

            // Cabecera de la tabla
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 16,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF2D2D2D),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Producto',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Cant.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Precio',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Total',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),

            // Lista de productos
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border.all(
                  color: const Color(0xFF2D2D2D),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: detalles.length,
                itemBuilder: (context, index) {
                  final detalle = detalles[index];
                  return _buildDetalleItem(detalle, isMap);
                },
              ),
            ),

            const SizedBox(height: 24),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (tieneDocs && linkPdf != null) ...[
                  ElevatedButton.icon(
                    icon: const FaIcon(
                      FontAwesomeIcons.download,
                      size: 16,
                    ),
                    label: const Text('Descargar PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2D2D),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _abrirUrl(linkPdf);
                    },
                  ),
                  const SizedBox(width: 16),
                ],
                ElevatedButton.icon(
                  icon: const FaIcon(
                    FontAwesomeIcons.print,
                    size: 16,
                  ),
                  label: const Text('Imprimir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2D2D),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Función en desarrollo'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  child: const Text('Cerrar'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget para cada línea de detalle
  Widget _buildDetalleItem(detalle, bool isMap) {
    // Adaptación para la estructura de detallesVenta del ejemplo JSON
    final String nombre =
        isMap ? detalle['nombre'] ?? 'Producto sin nombre' : detalle.nombre;

    final int cantidad = isMap
        ? (detalle['cantidad'] is String
            ? int.tryParse(detalle['cantidad']) ?? 0
            : detalle['cantidad'] ?? 0)
        : detalle.cantidad;

    // Adaptación para los precios según el formato del ejemplo JSON
    final double precio = isMap
        ? (detalle['precioConIgv'] is String
            ? double.tryParse(detalle['precioConIgv']) ?? 0.0
            : (detalle['precioConIgv'] ?? 0.0).toDouble())
        : detalle.precioConIgv;

    final double total = isMap
        ? (detalle['total'] is String
            ? double.tryParse(detalle['total']) ?? 0.0
            : (detalle['total'] ?? 0.0).toDouble())
        : detalle.total;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 16,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF2D2D2D),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              nombre,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: Text(
              cantidad.toString(),
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              _formatoMoneda.format(precio),
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              _formatoMoneda.format(total),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Abrir URL en el navegador
  Future<void> _abrirUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('No se pudo abrir la URL: $url');
    }
  }

  // Obtener el color según el estado de la venta
  Color _getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'COMPLETADA':
        return Colors.green;
      case 'ANULADA':
        return Colors.red;
      case 'DECLARADA':
        return Colors.blue;
      case 'ACEPTADO-SUNAT':
        return Colors.green;
      case 'ACEPTADO ANTE LA SUNAT':
        return Colors.green;
      case 'PENDIENTE':
      default:
        return Colors.orange;
    }
  }

  // Calcular el total de la venta
  double _calcularTotal(Map<String, dynamic> venta) {
    // Primero intentamos con el formato del ejemplo JSON (totalesVenta)
    if (venta.containsKey('totalesVenta') && venta['totalesVenta'] != null) {
      if (venta['totalesVenta']['totalVenta'] != null) {
        final value = venta['totalesVenta']['totalVenta'];
        if (value is String) {
          return double.tryParse(value) ?? 0.0;
        } else {
          return (value ?? 0.0).toDouble();
        }
      }
    }

    // Luego intentamos con el formato anterior
    if (venta.containsKey('total')) {
      final value = venta['total'];
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      } else {
        return (value ?? 0.0).toDouble();
      }
    } else if (venta.containsKey('subtotal') && venta.containsKey('igv')) {
      final subtotal = venta['subtotal'] is String
          ? double.tryParse(venta['subtotal']) ?? 0.0
          : (venta['subtotal'] ?? 0.0).toDouble();
      final igv = venta['igv'] is String
          ? double.tryParse(venta['igv']) ?? 0.0
          : (venta['igv'] ?? 0.0).toDouble();
      return subtotal + igv;
    }

    // Si no hay total, intentamos sumando los detalles
    double totalCalculado = 0.0;
    if (venta.containsKey('detallesVenta') && venta['detallesVenta'] is List) {
      for (var detalle in venta['detallesVenta']) {
        if (detalle is Map && detalle.containsKey('total')) {
          final total = detalle['total'] is String
              ? double.tryParse(detalle['total']) ?? 0.0
              : (detalle['total'] ?? 0.0).toDouble();
          totalCalculado += total;
        }
      }
      return totalCalculado;
    }

    return 0.0;
  }
}
