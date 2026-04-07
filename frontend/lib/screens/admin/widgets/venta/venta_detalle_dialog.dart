import 'dart:math' show min;

import 'package:condorsmotors/models/ventas.model.dart';
import 'package:condorsmotors/providers/print.riverpod.dart';
import 'package:condorsmotors/screens/admin/widgets/venta/venta_info_card.dart';
import 'package:condorsmotors/screens/admin/widgets/venta/venta_productos_table.dart';
import 'package:condorsmotors/utils/ventas_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class VentaDetalleDialog extends ConsumerStatefulWidget {
  final Venta? venta;
  final bool isLoadingFullData;
  final Function(String)? onDeclararPressed;

  const VentaDetalleDialog({
    super.key,
    required this.venta,
    this.isLoadingFullData = false,
    this.onDeclararPressed,
  });

  @override
  ConsumerState<VentaDetalleDialog> createState() => _VentaDetalleDialogState();
}

class _VentaDetalleDialogState extends ConsumerState<VentaDetalleDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.venta == null) {
      return _buildLoadingOrErrorState();
    }

    final Venta venta = widget.venta!;

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          width: min(MediaQuery.of(context).size.width * 0.95, 850),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(venta),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      VentaInfoCard(
                        venta: venta,
                        isLoadingFullData: widget.isLoadingFullData,
                      ),
                      const SizedBox(height: 24),
                      VentaProductosTable(
                        detalles: venta.detalles,
                        isLoading: widget.isLoadingFullData,
                      ),
                      const SizedBox(height: 24),
                      _buildActionButtons(venta),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOrErrorState() {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isLoadingFullData)
              const CircularProgressIndicator(color: Color(0xFFE31E24))
            else
              const Text('Venta no encontrada.', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Venta venta) {
    final bool tienePdf = VentasUtils.tienePdfDisponible(venta);
    final String? pdfLink = VentasUtils.obtenerUrlPdf(venta);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
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
                child: Center(
                  child: FaIcon(
                    tienePdf ? FontAwesomeIcons.filePdf : FontAwesomeIcons.fileInvoice,
                    color: const Color(0xFFE31E24),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venta.serieDocumento.isNotEmpty 
                      ? '${venta.serieDocumento}-${venta.numeroDocumento}' 
                      : 'Venta #${venta.id}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(venta.fechaCreacion),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              if (tienePdf)
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.filePdf, color: Colors.blue, size: 18),
                  onPressed: () => pdfLink != null ? ref.read(printConfigProvider.notifier).abrirPdf(pdfLink, context) : null,
                ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Venta venta) {
    if (venta.anulada || venta.cancelada) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!venta.declarada && widget.onDeclararPressed != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.receipt, size: 14),
              label: const Text('Declarar a SUNAT'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D8B95), foregroundColor: Colors.white),
              onPressed: () => _confirmarDeclaracion(venta.id.toString()),
            ),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D2D2D), foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  void _confirmarDeclaracion(String idVenta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Declaración'),
        content: const Text('¿Está seguro que desea declarar esta venta a SUNAT?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDeclararPressed?.call(idVenta);
            },
            child: const Text('Declarar'),
          ),
        ],
      ),
    );
  }
}
