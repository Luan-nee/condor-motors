import 'package:condorsmotors/models/producto.model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductoAgregarDialog extends StatefulWidget {
  final Producto producto;
  final void Function(Map<String, dynamic> productoData) onSave;

  const ProductoAgregarDialog({
    super.key,
    required this.producto,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required Producto producto,
    required void Function(Map<String, dynamic> productoData) onSave,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => ProductoAgregarDialog(
        producto: producto,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ProductoAgregarDialog> createState() => _ProductoAgregarDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Producto>('producto', producto))
      ..add(ObjectFlagProperty<void Function(Map<String, dynamic>)>.has(
          'onSave', onSave));
  }
}

class _ProductoAgregarDialogState extends State<ProductoAgregarDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cantidadController =
      TextEditingController(text: '0');
  final TextEditingController _precioVentaController = TextEditingController();
  final TextEditingController _precioCompraController = TextEditingController();
  final TextEditingController _precioLiquidacionController =
      TextEditingController();

  bool _liquidacion = false;

  int get stockActual => widget.producto.stock;
  int get cantidadAgregar => int.tryParse(_cantidadController.text) ?? 0;
  int get stockNuevo => stockActual + cantidadAgregar;

  @override
  void initState() {
    super.initState();
    _precioVentaController.text = widget.producto.precioVenta > 0
        ? widget.producto.precioVenta.toStringAsFixed(2)
        : '';
    _precioCompraController.text = widget.producto.precioCompra > 0
        ? widget.producto.precioCompra.toStringAsFixed(2)
        : '';
    _liquidacion = widget.producto.liquidacion;
    _precioLiquidacionController.text = widget.producto.precioOferta != null &&
            widget.producto.precioOferta! > 0
        ? widget.producto.precioOferta!.toStringAsFixed(2)
        : '';
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _precioVentaController.dispose();
    _precioCompraController.dispose();
    _precioLiquidacionController.dispose();
    super.dispose();
  }

  void _incrementar() {
    setState(() {
      int val = cantidadAgregar;
      val++;
      _cantidadController.text = val.toString();
    });
  }

  void _decrementar() {
    setState(() {
      int val = cantidadAgregar;
      if (val > 0) {
        val--;
      }
      _cantidadController.text = val.toString();
    });
  }

  void _guardar() {
    if (_formKey.currentState?.validate() ?? false) {
      final int stock = stockNuevo;
      final double precioVenta =
          double.tryParse(_precioVentaController.text) ?? 0.0;
      final double precioCompra =
          double.tryParse(_precioCompraController.text) ?? 0.0;
      final double? precioOferta =
          _liquidacion && _precioLiquidacionController.text.isNotEmpty
              ? double.tryParse(_precioLiquidacionController.text)
              : null;
      final Map<String, dynamic> productoData = {
        'stock': stock,
        'precioVenta': precioVenta,
        'precioCompra': precioCompra,
        if (_liquidacion && precioOferta != null) 'precioOferta': precioOferta,
      };
      widget.onSave(productoData);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: const [
                  FaIcon(FontAwesomeIcons.boxOpen, color: Color(0xFFE31E24)),
                  SizedBox(width: 8),
                  Text('Habilitar Producto',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const Text('Actual',
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text('$stockActual',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22)),
                    ],
                  ),
                  const FaIcon(FontAwesomeIcons.arrowRight,
                      color: Colors.white54, size: 18),
                  Column(
                    children: [
                      const Text('Nuevo',
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text('$stockNuevo',
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 22)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _cantidadController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Cantidad a agregar',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF222222),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE31E24)),
                  ),
                  prefixIcon: const Icon(Icons.add, color: Colors.white54),
                  helperText: 'Ingrese la cantidad de stock a agregar',
                  helperStyle: const TextStyle(color: Colors.white38),
                ),
                validator: (value) {
                  final int? val = int.tryParse(value ?? '');
                  if (val == null || val < 1) {
                    return 'Ingrese una cantidad válida (>0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.white70),
                    onPressed: _decrementar,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white70),
                    onPressed: _incrementar,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precioCompraController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Precio de Compra',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF222222),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE31E24)),
                  ),
                  prefixText: 'S/ ',
                  prefixStyle: const TextStyle(color: Colors.white),
                  helperText: 'Ingrese el precio de compra',
                  helperStyle: const TextStyle(color: Colors.white38),
                ),
                validator: (value) {
                  final double? val = double.tryParse(value ?? '');
                  if (val == null || val <= 0) {
                    return 'Ingrese un precio válido (>0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precioVentaController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Precio de Venta',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF222222),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE31E24)),
                  ),
                  prefixText: 'S/ ',
                  prefixStyle: const TextStyle(color: Colors.white),
                  helperText: 'Ingrese el precio de venta',
                  helperStyle: const TextStyle(color: Colors.white38),
                ),
                validator: (value) {
                  final double? val = double.tryParse(value ?? '');
                  if (val == null || val <= 0) {
                    return 'Ingrese un precio válido (>0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Switch(
                    value: _liquidacion,
                    onChanged: (v) => setState(() => _liquidacion = v),
                    activeColor: Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  const Text('¿Está en liquidación?',
                      style: TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.bold)),
                ],
              ),
              if (_liquidacion) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _precioLiquidacionController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Precio de Liquidación',
                    labelStyle: const TextStyle(color: Colors.amber),
                    filled: true,
                    fillColor: const Color(0xFF222222),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.amber.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.amber),
                    ),
                    prefixText: 'S/ ',
                    prefixStyle: const TextStyle(color: Colors.amber),
                    helperText: 'Debe ser menor al precio de venta',
                    helperStyle: const TextStyle(color: Colors.amber),
                  ),
                  validator: (value) {
                    final double? val = double.tryParse(value ?? '');
                    final double venta =
                        double.tryParse(_precioVentaController.text) ?? 0;
                    if (val == null || val <= 0) {
                      return 'Ingrese un precio válido (>0)';
                    }
                    if (val >= venta) {
                      return 'Debe ser menor al precio de venta';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text('Habilitar Producto',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE31E24),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _guardar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('stockActual', stockActual))
      ..add(IntProperty('cantidadAgregar', cantidadAgregar))
      ..add(IntProperty('stockNuevo', stockNuevo))
      ..add(FlagProperty('liquidacion',
          value: _liquidacion,
          ifTrue: 'liquidacion',
          ifFalse: 'no liquidacion'));
  }
}
