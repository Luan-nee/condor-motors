import 'package:condorsmotors/models/pedido.model.dart';
import 'package:condorsmotors/providers/admin/pedido.admin.provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DetallePedidoWidget extends StatefulWidget {
  final PedidoExclusivo pedido;
  final VoidCallback onUpdate;

  const DetallePedidoWidget({
    super.key,
    required this.pedido,
    required this.onUpdate,
  });

  @override
  State<DetallePedidoWidget> createState() => _DetallePedidoWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<PedidoExclusivo>('pedido', pedido))
      ..add(ObjectFlagProperty<VoidCallback>.has('onUpdate', onUpdate));
  }
}

class _DetallePedidoWidgetState extends State<DetallePedidoWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header oscuro
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF232323),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.red, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'DETALLE PEDIDO EXCLUSIVO',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoGeneral(context),
                      const SizedBox(height: 24),
                      _buildDetallesReservaTable(context),
                    ],
                  ),
                ),
              ),
            ),
            // Botón cerrar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('CERRAR',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGeneral(BuildContext context) {
    final cliente = Provider.of<PedidoAdminProvider>(context, listen: false)
        .getCliente(widget.pedido.clienteId);
    return Card(
      color: const Color(0xFF232323),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text('Información General',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow(
                'Descripción', widget.pedido.descripcion, Icons.description),
            _infoRow('Denominación', widget.pedido.denominacion, Icons.label),
            _infoRow('Monto Adelantado', 'S/ ${widget.pedido.montoAdelantado}',
                Icons.attach_money),
            _infoRow('Fecha de Recojo', widget.pedido.fechaRecojo,
                Icons.calendar_today),
            const Divider(color: Colors.white24),
            Row(
              children: const [
                Icon(Icons.person, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text('Datos del Cliente',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(
                'Cliente',
                cliente?.denominacion ?? 'ID: ${widget.pedido.clienteId}',
                Icons.person),
            _infoRow('Documento', cliente?.numeroDocumento ?? '-',
                Icons.credit_card),
            if (cliente != null &&
                cliente.correo != null &&
                cliente.correo!.isNotEmpty)
              _infoRow('Correo', cliente.correo!, Icons.email),
            if (cliente != null &&
                cliente.telefono != null &&
                cliente.telefono!.isNotEmpty)
              _infoRow('Teléfono', cliente.telefono!, Icons.phone),
            if (cliente != null &&
                cliente.direccion != null &&
                cliente.direccion!.isNotEmpty)
              _infoRow('Dirección', cliente.direccion!, Icons.location_on),
            _infoRow('ID Sucursal', widget.pedido.sucursalId.toString(),
                Icons.store),
            _infoRow('Nombre Sucursal', widget.pedido.nombre, Icons.storefront),
            _infoRow(
                'Fecha de creación',
                '${widget.pedido.fechaCreacion.day.toString().padLeft(2, '0')}/'
                    '${widget.pedido.fechaCreacion.month.toString().padLeft(2, '0')}/'
                    '${widget.pedido.fechaCreacion.year} '
                    '${widget.pedido.fechaCreacion.hour.toString().padLeft(2, '0')}:${widget.pedido.fechaCreacion.minute.toString().padLeft(2, '0')}',
                Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildDetallesReservaTable(BuildContext context) {
    return Card(
      color: const Color(0xFF232323),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.list, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text('Detalles de la Reserva',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFF1A1A1A)),
                    dataRowColor:
                        WidgetStateProperty.all(const Color(0xFF232323)),
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(
                          label: Text('Producto',
                              style: TextStyle(color: Colors.white))),
                      DataColumn(
                          label: Text('Cantidad',
                              style: TextStyle(color: Colors.white))),
                      DataColumn(
                          label: Text('Precio Venta',
                              style: TextStyle(color: Colors.white))),
                      DataColumn(
                          label: Text('Precio Compra',
                              style: TextStyle(color: Colors.white))),
                      DataColumn(
                          label: Text('Total',
                              style: TextStyle(color: Colors.white))),
                    ],
                    rows: List.generate(widget.pedido.detallesReserva.length,
                        (index) {
                      final detalle = widget.pedido.detallesReserva[index];
                      return DataRow(
                        cells: [
                          DataCell(Text(detalle.nombreProducto,
                              style: const TextStyle(color: Colors.white))),
                          DataCell(Text(detalle.cantidad.toString(),
                              style: const TextStyle(color: Colors.white))),
                          DataCell(Text('S/ ${detalle.precioVenta}',
                              style: const TextStyle(color: Colors.white))),
                          DataCell(Text('S/ ${detalle.precioCompra}',
                              style: const TextStyle(color: Colors.white))),
                          DataCell(Text('S/ ${detalle.total}',
                              style: const TextStyle(color: Colors.white))),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
