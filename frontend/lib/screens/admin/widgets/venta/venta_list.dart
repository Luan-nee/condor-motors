import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class VentaList extends StatelessWidget {
  final List<dynamic> ventas;
  final bool isLoading;
  final void Function(Object venta) onVerDetalle;
  final NumberFormat formatoMoneda = NumberFormat.currency(
    symbol: 'S/ ',
    decimalDigits: 2,
  );

  VentaList({
    super.key,
    required this.ventas,
    this.isLoading = false,
    required this.onVerDetalle,
  });

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<dynamic>('ventas', ventas))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(ObjectFlagProperty<void Function(Object)>.has(
          'onVerDetalle', onVerDetalle))
      ..add(DiagnosticsProperty<NumberFormat>('formatoMoneda', formatoMoneda));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (ventas.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildVentasList(context);
  }

  // Widget para cuando no hay ventas
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FaIcon(
            FontAwesomeIcons.fileInvoice,
            color: Colors.grey,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay ventas registradas',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const FaIcon(
              FontAwesomeIcons.plus,
              size: 14,
            ),
            label: const Text('Crear venta'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función en desarrollo'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Widget con la lista de ventas
  Widget _buildVentasList(BuildContext context) {
    return Column(
      children: [
        // Cabecera de la tabla
        Container(
          color: const Color(0xFF2D2D2D),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: const Row(
            children: [
              // ID/Número (8% del ancho)
              Expanded(
                flex: 8,
                child: Text(
                  'ID',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Tipo Doc (10% del ancho)
              Expanded(
                flex: 10,
                child: Text(
                  'Tipo Doc.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Fecha (12% del ancho)
              Expanded(
                flex: 12,
                child: Text(
                  'Emisión',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Información (25% del ancho)
              Expanded(
                flex: 25,
                child: Text(
                  'Información',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Estado (10% del ancho)
              Expanded(
                flex: 10,
                child: Text(
                  'Estado',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Empleado (15% del ancho)
              Expanded(
                flex: 15,
                child: Text(
                  'Empleado',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Total (10% del ancho)
              Expanded(
                flex: 10,
                child: Text(
                  'Total',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Acciones (10% del ancho)
              Expanded(
                flex: 10,
                child: Text(
                  'Acciones',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filas de ventas
        Expanded(
          child: ListView.builder(
            itemCount: ventas.length,
            itemBuilder: (context, index) {
              final venta = ventas[index];

              // Extraer información de diferentes formatos de venta
              final String tipoDocumento = _obtenerTipoDocumento(venta);
              final String fechaEmision = _obtenerFechaEmision(venta);
              final String horaEmision = _obtenerHoraEmision(venta);
              final String nombreEmpleado = _obtenerNombreEmpleado(venta);
              final Color colorTipoDoc =
                  _obtenerColorTipoDocumento(tipoDocumento);

              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onVerDetalle(venta),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      child: Row(
                        children: [
                          // ID/Número
                          Expanded(
                            flex: 8,
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2D2D2D),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: FaIcon(
                                      FontAwesomeIcons.fileInvoice,
                                      color: Color(0xFFE31E24),
                                      size: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${venta is Map ? venta['id'] : venta.id}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),

                          // Tipo de documento
                          Expanded(
                            flex: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorTipoDoc.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: colorTipoDoc.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                tipoDocumento.contains('Boleta')
                                    ? 'BOLETA'
                                    : (tipoDocumento.contains('Factura')
                                        ? 'FACTURA'
                                        : tipoDocumento),
                                style: TextStyle(
                                  color: colorTipoDoc,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          // Fecha y hora de emisión
                          Expanded(
                            flex: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fechaEmision,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  horaEmision,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Información
                          Expanded(
                            flex: 25,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  venta is Map
                                      ? (venta['serie_documento'] != null &&
                                              venta['numero_documento'] != null
                                          ? '${venta['serie_documento']}-${venta['numero_documento']}'
                                          : 'Venta #${venta['id']}')
                                      : (venta.serieDocumento.isNotEmpty &&
                                              venta.numeroDocumento.isNotEmpty
                                          ? '${venta.serieDocumento}-${venta.numeroDocumento}'
                                          : 'Venta #${venta.id}'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                if (venta is Map
                                    ? (venta['observaciones'] != null &&
                                        venta['observaciones']
                                            .toString()
                                            .isNotEmpty)
                                    : (venta.observaciones != null &&
                                        venta.observaciones!.isNotEmpty))
                                  Text(
                                    venta is Map
                                        ? venta['observaciones'].toString()
                                        : venta.observaciones!,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),

                          // Estado
                          Expanded(
                            flex: 10,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getEstadoColor(venta is Map
                                          ? (venta['estado'] ?? 'PENDIENTE')
                                          : venta.estado.toText())
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  venta is Map
                                      ? (venta['estado'] ?? 'PENDIENTE')
                                          .toString()
                                          .toUpperCase()
                                      : venta.estado.toText(),
                                  style: TextStyle(
                                    color: _getEstadoColor(venta is Map
                                        ? (venta['estado'] ?? 'PENDIENTE')
                                        : venta.estado.toText()),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Empleado
                          Expanded(
                            flex: 15,
                            child: Text(
                              nombreEmpleado,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Total
                          Expanded(
                            flex: 10,
                            child: Text(
                              formatoMoneda.format(_calcularTotal(venta)),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Acciones
                          Expanded(
                            flex: 10,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const FaIcon(
                                    FontAwesomeIcons.eye,
                                    color: Colors.white54,
                                    size: 16,
                                  ),
                                  onPressed: () => onVerDetalle(venta),
                                  tooltip: 'Ver detalle',
                                ),
                                IconButton(
                                  icon: const FaIcon(
                                    FontAwesomeIcons.print,
                                    color: Colors.white54,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Función en desarrollo'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  },
                                  tooltip: 'Imprimir',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Método para obtener el tipo de documento
  String _obtenerTipoDocumento(venta) {
    if (venta is Map) {
      return venta['tipoDocumento'] ?? 'Documento sin tipo';
    } else {
      // En caso de ser un objeto Venta, tendríamos que agregar esta propiedad
      // al modelo, por ahora usaremos un valor genérico basado en tipoDocumentoId
      return venta.tipoDocumentoId == 3
          ? 'Factura electrónica'
          : venta.tipoDocumentoId == 4
              ? 'Boleta de venta electrónica'
              : 'Documento sin tipo';
    }
  }

  // Método para obtener la fecha de emisión
  String _obtenerFechaEmision(venta) {
    if (venta is Map) {
      return venta['fechaEmision'] ?? 'Sin fecha';
    } else {
      // Ajustar si el objeto Venta ya tiene este campo
      return DateFormat('yyyy-MM-dd').format(venta.fechaEmision);
    }
  }

  // Método para obtener la hora de emisión
  String _obtenerHoraEmision(venta) {
    if (venta is Map) {
      return venta['horaEmision'] ?? 'Sin hora';
    } else {
      // Ajustar si el objeto Venta ya tiene este campo
      return venta.horaEmision;
    }
  }

  // Método para obtener el nombre del empleado
  String _obtenerNombreEmpleado(venta) {
    if (venta is Map && venta['empleado'] != null) {
      final empleado = venta['empleado'];
      return '${empleado['nombre'] ?? ''} ${empleado['apellidos'] ?? ''}';
    } else {
      // Para el objeto Venta tendríamos que agregar esta información
      return 'Empleado no identificado';
    }
  }

  // Método para obtener el color según el tipo de documento
  Color _obtenerColorTipoDocumento(String tipoDocumento) {
    if (tipoDocumento.contains('Boleta')) {
      return Colors.blue;
    } else if (tipoDocumento.contains('Factura')) {
      return Colors.green;
    } else {
      return Colors.orange;
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
      case 'PENDIENTE':
      default:
        return Colors.orange;
    }
  }

  // Calcular el total de la venta
  double _calcularTotal(venta) {
    if (venta is Map) {
      if (venta.containsKey('total')) {
        return (venta['total'] ?? 0.0).toDouble();
      } else if (venta.containsKey('subtotal') && venta.containsKey('igv')) {
        final double subtotal = (venta['subtotal'] ?? 0.0).toDouble();
        final double igv = (venta['igv'] ?? 0.0).toDouble();
        return subtotal + igv;
      } else if (venta.containsKey('totalesVenta') &&
          venta['totalesVenta'] != null) {
        // Obtener datos desde el formato de respuesta API
        final totales = venta['totalesVenta'];
        return double.tryParse(totales['totalVenta']?.toString() ?? '0.0') ??
            0.0;
      }
      return 0.0;
    } else {
      // Es un objeto Venta
      return venta.calcularTotal();
    }
  }
}
