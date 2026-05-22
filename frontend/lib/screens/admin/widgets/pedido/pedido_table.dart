import 'package:condorsmotors/models/cliente.model.dart';
import 'package:condorsmotors/models/pedido.model.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class PedidoTable extends StatelessWidget {
  final List<PedidoExclusivo> pedidos;
  final bool isLoading;
  final Cliente? Function(int) getCliente;
  final ValueChanged<PedidoExclusivo> onViewDetails;
  final ValueChanged<PedidoExclusivo> onEdit;
  final ValueChanged<PedidoExclusivo> onDelete;
  final VoidCallback onNew;

  const PedidoTable({
    super.key,
    required this.pedidos,
    required this.isLoading,
    required this.getCliente,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDelete,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pedidos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const FaIcon(
                        FontAwesomeIcons.boxOpen,
                        color: Colors.grey,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay pedidos exclusivos disponibles',
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
                        label: const Text('Crear pedido'),
                        onPressed: onNew,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Encabezado de la tabla
                      Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(AppTheme.mediumRadius)),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        child: const Row(
                          children: <Widget>[
                            Expanded(
                              flex: 30,
                              child: Text('Descripción',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                            Expanded(
                              flex: 25,
                              child: Text('Cliente',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                            Expanded(
                              flex: 15,
                              child: Text('Sucursal',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                            Expanded(
                              flex: 15,
                              child: Text('Fecha',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                            Expanded(
                              flex: 15,
                              child: Text('Monto Adelantado',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                            Expanded(
                              flex: 15,
                              child: Text('Recojo',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                            Expanded(
                              flex: 15,
                              child: Text('Detalles',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                            Expanded(
                              flex: 20,
                              child: Text('Acciones',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                          ],
                        ),
                      ),
                      // Filas de pedidos
                      ...pedidos.map((pedido) => Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 25,
                                  child: Text(pedido.descripcion,
                                      style: const TextStyle(
                                          color: Colors.white)),
                                ),
                                Expanded(
                                  flex: 20,
                                  child: Text(
                                      getCliente(pedido.clienteId)
                                              ?.denominacion ??
                                          pedido.clienteId.toString(),
                                      style: const TextStyle(
                                          color: Colors.white)),
                                ),
                                Expanded(
                                  flex: 15,
                                  child: Text(
                                      pedido.nombre.isNotEmpty
                                          ? pedido.nombre
                                          : 'Sucursal ${pedido.sucursalId}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.white)),
                                ),
                                Expanded(
                                  flex: 15,
                                  child: Text(
                                      DateFormat('dd/MM/yyyy')
                                          .format(pedido.fechaCreacion),
                                      style: const TextStyle(
                                          color: Colors.white)),
                                ),
                                Expanded(
                                  flex: 15,
                                  child: Text('S/ ${pedido.montoAdelantado}',
                                      style: const TextStyle(
                                          color: Colors.white)),
                                ),
                                Expanded(
                                  flex: 15,
                                  child: Text(pedido.fechaRecojo,
                                      style: const TextStyle(
                                          color: Colors.white)),
                                ),
                                Expanded(
                                  flex: 15,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const FaIcon(
                                          FontAwesomeIcons.box,
                                          size: 12,
                                          color: AppTheme.primaryColor),
                                      const SizedBox(width: 6),
                                      Text(
                                          '${pedido.detallesReserva.length}',
                                          style: const TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontWeight:
                                                  FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 20,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: <Widget>[
                                      IconButton(
                                        icon: const FaIcon(
                                            FontAwesomeIcons.eye,
                                            color: Colors.white54,
                                            size: 16),
                                        onPressed: () => onViewDetails(pedido),
                                        constraints: const BoxConstraints(
                                            minWidth: 30, minHeight: 30),
                                        padding: EdgeInsets.zero,
                                      ),
                                      IconButton(
                                        icon: const FaIcon(
                                            FontAwesomeIcons.penToSquare,
                                            color: Colors.white54,
                                            size: 16),
                                        onPressed: () => onEdit(pedido),
                                        constraints: const BoxConstraints(
                                            minWidth: 30, minHeight: 30),
                                        padding: EdgeInsets.zero,
                                      ),
                                      IconButton(
                                        icon: const FaIcon(
                                            FontAwesomeIcons.trash,
                                            color: Colors.red,
                                            size: 16),
                                        onPressed: () => onDelete(pedido),
                                        constraints: const BoxConstraints(
                                            minWidth: 30, minHeight: 30),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
    );
  }
}
