import 'package:condorsmotors/models/cliente.model.dart';
import 'package:condorsmotors/models/pedido.model.dart';
import 'package:condorsmotors/repositories/cliente.repository.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  late final ScrollController _tableScrollController;

  @override
  void initState() {
    super.initState();
    _tableScrollController = ScrollController();
  }

  @override
  void dispose() {
    _tableScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header oscuro
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppTheme.mediumRadius)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.red, size: 22),
                  const SizedBox(width: 12),
                  const Text(
                    'DETALLE PEDIDO EXCLUSIVO',
                    style: TextStyle(
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildInfoGeneral(context)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildDatosCliente(context)),
                        ],
                      ),
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
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: AppTheme.primaryColor, size: 18),
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
            _infoRow('Sucursal', widget.pedido.nombre, Icons.storefront),
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

  Widget _buildDatosCliente(BuildContext context) {
    return FutureBuilder<Cliente?>(
      future: ClienteRepository.instance
          .obtenerCliente(widget.pedido.clienteId.toString()),
      builder: (context, snapshot) {
        final cliente = snapshot.data;

        return Card(
          color: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.mediumRadius)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person, color: AppTheme.primaryColor, size: 18),
                    SizedBox(width: 8),
                    Text('Datos del Cliente',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                else if (snapshot.hasError)
                  Text(
                    'Error al cargar datos del cliente: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  )
                else ...[
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
                    _infoRow(
                        'Dirección', cliente.direccion!, Icons.location_on),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetallesReservaTable(BuildContext context) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.list, color: AppTheme.primaryColor, size: 18),
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
                controller: _tableScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _tableScrollController,
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(AppTheme.backgroundColor),
                    dataRowColor: WidgetStateProperty.all(AppTheme.cardColor),
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    dataTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
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
            // Total debajo de la tabla
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, right: 8),
                child: Text(
                  'Total: S/ ${_calcularTotalPedido().toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calcularTotalPedido() {
    return widget.pedido.detallesReserva.fold(
      0.0,
      (sum, item) => sum + (item.total),
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
