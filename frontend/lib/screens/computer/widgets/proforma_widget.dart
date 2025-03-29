import 'package:condorsmotors/models/proforma.model.dart';
import 'package:condorsmotors/screens/computer/widgets/proforma_conversion_utils.dart';
import 'package:condorsmotors/screens/computer/widgets/proforma_utils.dart';
import 'package:condorsmotors/screens/computer/widgets/form_proforma.dart';
import 'package:condorsmotors/utils/ventas_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget para mostrar los detalles de una proforma individual
class ProformaWidget extends StatelessWidget {
  final Proforma proforma;
  final Function(Proforma)? onConvert;
  final Function(Proforma)? onUpdate;
  final VoidCallback? onDelete;

  const ProformaWidget({
    super.key,
    required this.proforma,
    this.onConvert,
    this.onUpdate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool puedeConvertirse = proforma.puedeConvertirseEnVenta();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado con información general
        _buildHeader(context),
        
        const SizedBox(height: 24),
        
        // Información del cliente
        _buildClientInfo(),
        
        const SizedBox(height: 24),
        
        // Lista de productos
        Expanded(
          child: _buildProductList(context),
        ),
        
        const SizedBox(height: 16),
        
        // Resumen y acciones
        _buildSummary(context, puedeConvertirse),
      ],
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                proforma.nombre ?? 'Proforma #${proforma.id}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.white54,
              ),
              const SizedBox(width: 8),
              Text(
                'Creado: ${VentasPendientesUtils.formatearFecha(proforma.fechaCreacion)}',
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          if (proforma.fechaExpiracion != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: proforma.haExpirado() ? Colors.red : Colors.white54,
                ),
                const SizedBox(width: 8),
                Text(
                  'Expira: ${VentasPendientesUtils.formatearFecha(proforma.fechaExpiracion!)}',
                  style: TextStyle(
                    color: proforma.haExpirado() ? Colors.red : Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatusBadge() {
    Color color;
    String text;
    IconData icon;
    
    switch (proforma.estado) {
      case EstadoProforma.pendiente:
        if (proforma.haExpirado()) {
          color = Colors.orange;
          text = 'Expirada';
          icon = Icons.timer_off;
        } else {
          color = Colors.blue;
          text = 'Pendiente';
          icon = Icons.pending;
        }
        break;
      case EstadoProforma.convertida:
        color = Colors.green;
        text = 'Convertida';
        icon = Icons.check_circle;
        break;
      case EstadoProforma.cancelada:
        color = Colors.red;
        text = 'Cancelada';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = 'Desconocido';
        icon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildClientInfo() {
    final Map<String, dynamic>? cliente = proforma.cliente;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.person,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                'Información del Cliente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (cliente != null && cliente.isNotEmpty) ...[
            _buildClientField('Nombre', cliente['nombre'] ?? 'Sin nombre'),
            _buildClientField('Documento', cliente['numeroDocumento'] ?? 'Sin documento'),
            if (cliente['telefono'] != null)
              _buildClientField('Teléfono', cliente['telefono']),
            if (cliente['email'] != null)
              _buildClientField('Email', cliente['email']),
            if (cliente['direccion'] != null)
              _buildClientField('Dirección', cliente['direccion']),
          ] else ...[
            const Text(
              'Sin información de cliente',
              style: TextStyle(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildClientField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Productos (${proforma.detalles.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.white.withOpacity(0.1),
            height: 1,
          ),
          
          // Encabezados de la tabla
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  flex: 5,
                  child: Text(
                    'Descripción',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Cantidad',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Precio Unit.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Subtotal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade200,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de productos
          Expanded(
            child: proforma.detalles.isEmpty
                ? const Center(
                    child: Text(
                      'No hay productos en esta proforma',
                      style: TextStyle(
                        color: Colors.white54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: proforma.detalles.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.white.withOpacity(0.05),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final detalle = proforma.detalles[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                detalle.nombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${detalle.cantidad}',
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                VentasUtils.formatearMontoTexto(detalle.precioUnitario),
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                VentasUtils.formatearMontoTexto(detalle.subtotal),
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
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummary(BuildContext context, bool puedeConvertirse) {
    // Calcular impuestos
    final double subtotal = VentasUtils.calcularSubtotalDesdeTotal(proforma.total);
    final double igv = VentasUtils.calcularIGV(subtotal);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Resumen de totales
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Subtotal:',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 120,
                child: Text(
                  VentasUtils.formatearMontoTexto(subtotal),
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'IGV (18%):',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 120,
                child: Text(
                  VentasUtils.formatearMontoTexto(igv),
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 120,
                child: Text(
                  VentasUtils.formatearMontoTexto(proforma.total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onDelete != null)
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              const SizedBox(width: 16),
              if (onConvert != null && puedeConvertirse)
                ElevatedButton.icon(
                  onPressed: () => _handleConvert(context),
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Convertir a Venta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Future<void> _handleConvert(BuildContext context) async {
    // Mostrar diálogo para confirmar conversión
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => ProformaSaleDialog(
        proforma: proforma,
        onConfirm: (Map<String, dynamic> ventaData) async {
          Navigator.of(dialogContext).pop();
          
          // Mostrar diálogo de procesamiento
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => _buildProcessingDialog(ventaData['tipoDocumento'].toLowerCase()),
          );
          
          // Intentar la conversión
          bool success = await ProformaConversionManager.convertirProformaAVenta(
            context: context,
            sucursalId: await _obtenerSucursalId(),
            proformaId: proforma.id,
            tipoDocumento: ventaData['tipoDocumento'],
            onSuccess: () {
              if (onConvert != null) {
                onConvert!(proforma);
              }
            },
          );
          
          // Si falló, intentar con el método alternativo
          if (!success) {
            final sucursalId = await VentasPendientesUtils.obtenerSucursalId();
            if (sucursalId != null) {
              // Mostrar diálogo preguntando si desea intentar el método alternativo
              final bool intentarAlternativo = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  backgroundColor: const Color(0xFF2D2D2D),
                  title: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      SizedBox(width: 10),
                      Text(
                        'Error en la conversión',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  content: const Text(
                    'La conversión normal falló. ¿Desea intentar de nuevo?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                      ),
                      child: const Text('Intentar de nuevo'),
                    ),
                  ],
                ),
              ) ?? false;
              
              if (intentarAlternativo) {
                // Mostrar diálogo de procesamiento nuevamente
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) => _buildProcessingDialog(ventaData['tipoDocumento'].toLowerCase()),
                );
                
                // Intentar nuevamente
                await ProformaConversionManager.convertirProformaAVenta(
                  context: context,
                  sucursalId: sucursalId.toString(),
                  proformaId: proforma.id,
                  tipoDocumento: ventaData['tipoDocumento'],
                  onSuccess: () {
                    if (onConvert != null) {
                      onConvert!(proforma);
                    }
                  },
                );
              }
            }
          }
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }
  
  Widget _buildProcessingDialog(String tipoDocumento) {
    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Procesando $tipoDocumento...',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Por favor espere',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtener el ID de sucursal actual
  Future<String> _obtenerSucursalId() async {
    final int? sucursalId = await VentasPendientesUtils.obtenerSucursalId();
    if (sucursalId == null) {
      throw Exception('No se pudo obtener el ID de sucursal');
    }
    return sucursalId.toString();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Proforma>('proforma', proforma))
      ..add(ObjectFlagProperty<Function(Proforma)?>.has('onConvert', onConvert))
      ..add(ObjectFlagProperty<Function(Proforma)?>.has('onUpdate', onUpdate))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onDelete', onDelete));
  }
}

/// Diálogo para confirmar la conversión de proforma a venta
class ProformaSaleDialog extends StatefulWidget {
  final Proforma proforma;
  final Function(Map<String, dynamic>) onConfirm;
  final VoidCallback onCancel;

  const ProformaSaleDialog({
    super.key,
    required this.proforma,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<ProformaSaleDialog> createState() => _ProformaSaleDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Proforma>('proforma', proforma))
      ..add(ObjectFlagProperty<Function(Map<String, dynamic>)>.has('onConfirm', onConfirm))
      ..add(ObjectFlagProperty<VoidCallback>.has('onCancel', onCancel));
  }
}

class _ProformaSaleDialogState extends State<ProformaSaleDialog> {
  String _tipoDocumento = 'BOLETA';
  String _customerName = '';
  String _paymentAmount = '';
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    // Inicializar con el nombre del cliente de la proforma
    _customerName = widget.proforma.getNombreCliente();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isLargeScreen = screenSize.width > 1200;
    
    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: isLargeScreen ? 1100 : 900,
          maxHeight: isLargeScreen ? 700 : 600,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detalles de la proforma (lado izquierdo)
            Expanded(
              flex: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: [
                          const Icon(
                            Icons.shopping_cart,
                            color: Color(0xFF4CAF50),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Convertir Proforma #${widget.proforma.id}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: widget.onCancel,
                        tooltip: 'Cancelar',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Resumen de la proforma
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Text(
                                'Cliente:',
                                style: TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.proforma.getNombreCliente(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Detalles:',
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Lista de productos (con scroll)
                          Expanded(
                            child: ListView.builder(
                              itemCount: widget.proforma.detalles.length,
                              itemBuilder: (context, index) {
                                final detalle = widget.proforma.detalles[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        flex: 5,
                                        child: Text(
                                          detalle.nombre,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${detalle.cantidad}x',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          VentasUtils.formatearMontoTexto(detalle.precioUnitario),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          VentasUtils.formatearMontoTexto(detalle.subtotal),
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
                            ),
                          ),
                          
                          const Divider(color: Colors.white24),
                          Row(
                            children: <Widget>[
                              const Spacer(),
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                VentasUtils.formatearMontoTexto(widget.proforma.total),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Separador vertical
            const SizedBox(width: 20),
            Container(width: 1, height: double.infinity, color: Colors.white24),
            const SizedBox(width: 20),
            
            // Teclado numérico para cálculo de vuelto (lado derecho)
            Expanded(
              flex: 4,
              child: NumericKeypad(
                onKeyPressed: (value) {
                  setState(() {
                    _paymentAmount = value;
                  });
                },
                onClear: () {
                  setState(() {
                    _paymentAmount = '';
                  });
                },
                onSubmit: () {
                  // Método vacío, la acción se maneja en onCharge
                },
                currentAmount: widget.proforma.total.toString(),
                paymentAmount: _paymentAmount,
                customerName: _customerName,
                documentType: _tipoDocumento == 'BOLETA' ? 'Boleta' : 'Factura',
                onCustomerNameChanged: (String value) {
                  setState(() {
                    _customerName = value;
                  });
                },
                onDocumentTypeChanged: (String value) {
                  setState(() {
                    _tipoDocumento = value == 'Boleta' ? 'BOLETA' : 'FACTURA';
                  });
                },
                isProcessing: _isProcessing,
                minAmount: widget.proforma.total,
                onCharge: (montoRecibido) {
                  // Crear los datos de venta y llamar a onConfirm
                  final Map<String, dynamic> ventaData = {
                    'tipoDocumento': _tipoDocumento,
                    'productos': widget.proforma.detalles.map((detalle) => {
                      'productoId': detalle.productoId,
                      'cantidad': detalle.cantidad,
                      'precio': detalle.precioUnitario,
                      'subtotal': detalle.subtotal,
                    }).toList(),
                    'cliente': widget.proforma.cliente ?? {'nombre': _customerName},
                    'metodoPago': 'EFECTIVO', // Por defecto
                    'total': widget.proforma.total,
                    'montoRecibido': montoRecibido,
                    'vuelto': montoRecibido - widget.proforma.total,
                  };
                  
                  // Iniciar procesamiento
                  setState(() {
                    _isProcessing = true;
                  });
                  
                  // Invocar callback con los datos de venta
                  widget.onConfirm(ventaData);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('_tipoDocumento', _tipoDocumento));
    properties.add(StringProperty('_customerName', _customerName));
    properties.add(StringProperty('_paymentAmount', _paymentAmount));
    properties.add(DiagnosticsProperty<bool>('_isProcessing', _isProcessing));
  }
}
