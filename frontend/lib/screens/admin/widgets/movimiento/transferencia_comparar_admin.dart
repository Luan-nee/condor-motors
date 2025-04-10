import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TransferenciaCompararAdmin extends StatefulWidget {
  final ComparacionTransferencia comparacion;
  final Function() onCancel;
  final Function() onConfirm;

  const TransferenciaCompararAdmin({
    super.key,
    required this.comparacion,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<TransferenciaCompararAdmin> createState() =>
      _TransferenciaCompararAdminState();

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

class _TransferenciaCompararAdminState
    extends State<TransferenciaCompararAdmin> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: BoxConstraints(
          maxWidth: 1000,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const Divider(color: Colors.white24),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSucursalesInfo(),
                      const SizedBox(height: 16),
                      _buildProductosComparacion(),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE31E24).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.scaleBalanced,
                  color: Color(0xFFE31E24),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Comparación de Stock',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: widget.onCancel,
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildSucursalesInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sucursal Origen',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.comparacion.sucursalOrigen.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward,
                color: Colors.white70,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Sucursal Destino',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.comparacion.sucursalDestino.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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
    );
  }

  Widget _buildProductosComparacion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.boxesStacked,
                size: 16,
                color: Color(0xFFE31E24),
              ),
              const SizedBox(width: 12),
              Text(
                'Productos (${widget.comparacion.productos.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.comparacion.productos.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Colors.white24, height: 1),
              itemBuilder: (context, index) {
                final producto = widget.comparacion.productos[index];
                return _buildProductoItem(producto);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductoItem(ComparacionProducto producto) {
    final bool stockBajo = producto.origen?.stockBajoDespues ?? false;
    final bool stockSuficiente = producto.origen?.stockActual != null &&
        producto.origen!.stockActual >= producto.cantidadSolicitada;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cantidad solicitada: ${producto.cantidadSolicitada}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      (stockSuficiente ? Colors.green : const Color(0xFFE31E24))
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (stockSuficiente
                            ? Colors.green
                            : const Color(0xFFE31E24))
                        .withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      stockSuficiente ? Icons.check_circle : Icons.warning,
                      size: 14,
                      color: stockSuficiente
                          ? Colors.green
                          : const Color(0xFFE31E24),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      stockSuficiente
                          ? 'Stock Suficiente'
                          : 'Stock Insuficiente',
                      style: TextStyle(
                        color: stockSuficiente
                            ? Colors.green
                            : const Color(0xFFE31E24),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStockInfo(
                  'Stock Origen',
                  producto.origen?.stockActual ?? 0,
                  producto.origen?.stockDespues ?? 0,
                  stockBajo,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStockInfo(
                  'Stock Destino',
                  producto.destino.stockActual,
                  producto.destino.stockDespues,
                  false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockInfo(
    String label,
    int stockActual,
    int stockDespues,
    bool stockBajo,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
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
                      'Actual',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      stockActual.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withOpacity(0.1),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Después',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          stockDespues.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (stockBajo) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.warning,
                            color: Color(0xFFE31E24),
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : widget.onCancel,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : widget.onConfirm,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check),
            label: Text(_isLoading ? 'Enviando...' : 'Confirmar Envío'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31E24),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
