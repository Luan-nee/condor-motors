import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TransferenciaCompararColab extends StatelessWidget {
  final ComparacionTransferencia comparacion;
  final Function() onCancel;
  final Function() onConfirm;

  const TransferenciaCompararColab({
    super.key,
    required this.comparacion,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;

    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: isMobile ? screenSize.width * 0.95 : 600,
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(isMobile),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSucursalesInfo(),
                      const SizedBox(height: 16),
                      _buildAlertasStock(),
                      const SizedBox(height: 16),
                      _buildProductosComparacion(isMobile),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const FaIcon(
            FontAwesomeIcons.scaleBalanced,
            color: Color(0xFFE31E24),
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Verificación de Stock',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const FaIcon(
              FontAwesomeIcons.xmark,
              color: Colors.white,
              size: 16,
            ),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildSucursalesInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildSucursalRow(
            'Origen',
            comparacion.sucursalOrigen.nombre,
            FontAwesomeIcons.store,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: FaIcon(
              FontAwesomeIcons.arrowDown,
              color: Color(0xFFE31E24),
              size: 16,
            ),
          ),
          _buildSucursalRow(
            'Destino',
            comparacion.sucursalDestino.nombre,
            FontAwesomeIcons.locationDot,
          ),
        ],
      ),
    );
  }

  Widget _buildSucursalRow(String label, String nombre, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE31E24).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(
            icon,
            color: const Color(0xFFE31E24),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              Text(
                nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertasStock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!comparacion.todosProductosProcesables)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE31E24).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.triangleExclamation,
                  color: Color(0xFFE31E24),
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hay productos con stock insuficiente. Revise la lista antes de continuar.',
                    style: TextStyle(
                      color: Color(0xFFE31E24),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (comparacion.productosConStockBajo.isNotEmpty) ...[
          if (!comparacion.todosProductosProcesables) const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.exclamation,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hay ${comparacion.productosConStockBajo.length} productos que quedarán con stock bajo.',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductosComparacion(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado con total de productos
        Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.boxesStacked,
              color: Color(0xFFE31E24),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Productos a Transferir (${comparacion.productos.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Lista de productos
        ...comparacion.productos
            .map(_buildProductoItem),
      ],
    );
  }

  Widget _buildProductoItem(ComparacionProducto producto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: producto.hayStockSuficiente
              ? producto.quedaConStockBajo
                  ? Colors.orange
                  : const Color(0xFF43A047)
              : const Color(0xFFE31E24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.box,
                color: Color(0xFFE31E24),
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (producto.origen?.stockMinimo != null)
                      Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.chartLine,
                            color: Colors.grey,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Stock mínimo: ${producto.origen?.stockMinimo}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStockInfo(
                'Stock Actual',
                (producto.origen?.stockActual ?? 0).toString(),
                FontAwesomeIcons.boxesStacked,
                Colors.grey,
              ),
              _buildStockInfo(
                'Stock Transferido',
                producto.cantidadSolicitada.toString(),
                FontAwesomeIcons.truckFast,
                const Color(0xFFE31E24),
              ),
              _buildStockInfo(
                'Stock Final',
                (producto.origen?.stockDespues ?? 0).toString(),
                FontAwesomeIcons.boxesStacked,
                producto.quedaConStockBajo
                    ? Colors.orange
                    : producto.hayStockSuficiente
                        ? const Color(0xFF43A047)
                        : const Color(0xFFE31E24),
                showIcon: true,
                stockBajo: producto.quedaConStockBajo,
                stockDisponible: producto.hayStockSuficiente,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockInfo(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool showIcon = false,
    bool stockBajo = false,
    bool stockDisponible = true,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              color: color,
              size: 14,
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (showIcon) ...[
              const SizedBox(width: 4),
              FaIcon(
                stockDisponible && !stockBajo
                    ? FontAwesomeIcons.check
                    : stockBajo
                        ? FontAwesomeIcons.exclamation
                        : FontAwesomeIcons.xmark,
                color: color,
                size: 12,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onCancel,
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed:
                !comparacion.todosProductosProcesables ? null : onConfirm,
            icon: const FaIcon(
              FontAwesomeIcons.paperPlane,
              size: 16,
            ),
            label: const Text('Confirmar Envío'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31E24),
              disabledBackgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ComparacionTransferencia>(
          'comparacion', comparacion))
      ..add(ObjectFlagProperty<Function()>.has('onCancel', onCancel))
      ..add(ObjectFlagProperty<Function()>.has('onConfirm', onConfirm));
  }
}
