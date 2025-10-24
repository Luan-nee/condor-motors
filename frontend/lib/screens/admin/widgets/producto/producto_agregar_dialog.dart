import 'package:condorsmotors/models/producto.model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductoAgregarDialog extends StatefulWidget {
  final Producto producto;
  final void Function(Map<String, dynamic> productoData) onSave;
  final String? sucursalNombre;

  const ProductoAgregarDialog({
    super.key,
    required this.producto,
    required this.onSave,
    this.sucursalNombre,
  });

  static Future<void> show(
    BuildContext context, {
    required Producto producto,
    required void Function(Map<String, dynamic> productoData) onSave,
    String? sucursalNombre,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => ProductoAgregarDialog(
        producto: producto,
        onSave: onSave,
        sucursalNombre: sucursalNombre,
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

  // Variables para controlar la aparición de botones rápidos
  int _contadorClicsAumentar = 0;
  bool _mostrarBotonesRapidos = false;

  int get stockActual => widget.producto.stock;
  int get cantidadAgregar => int.tryParse(_cantidadController.text) ?? 0;
  int get stockNuevo => stockActual + cantidadAgregar;

  // Calcular ganancia y porcentaje
  double get precioCompra => double.tryParse(_precioCompraController.text) ?? 0;
  double get precioVenta => double.tryParse(_precioVentaController.text) ?? 0;
  double get ganancia => precioVenta - precioCompra;
  double get porcentajeGanancia =>
      precioCompra > 0 ? (ganancia / precioCompra) * 100 : 0;

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

      // Incrementar contador de clics para mostrar botones rápidos
      _contadorClicsAumentar++;

      // Después de 4 clics, mostrar botones rápidos
      if (_contadorClicsAumentar >= 5 && !_mostrarBotonesRapidos) {
        _mostrarBotonesRapidos = true;
      }
    });
  }

  void _decrementar() {
    setState(() {
      int val = cantidadAgregar;
      if (val > 0) {
        val--;
      }
      _cantidadController.text = val.toString();

      // Reiniciar contador de clics cuando reducimos
      _contadorClicsAumentar = 0;
      _mostrarBotonesRapidos = false;
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
              const Row(
                children: [
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

              // Información de la sucursal
              if (widget.sucursalNombre != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.store,
                          color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sucursal: ${widget.sucursalNombre}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

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
                        BorderSide(color: Colors.white.withValues(alpha: 0.2)),
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

              // Controles para ajustar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Botón para reducir la cantidad a agregar
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.circleMinus,
                        color: Colors.white),
                    onPressed: _decrementar,
                    tooltip: 'Reducir cantidad a agregar',
                  ),
                  const SizedBox(width: 16),
                  // Botón para aumentar la cantidad a agregar
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.circlePlus,
                        color: Colors.white),
                    onPressed: _incrementar,
                    tooltip: 'Aumentar cantidad',
                  ),
                ],
              ),

              // Botones de incremento rápido (aparecen después de 4 clics)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _mostrarBotonesRapidos ? 50 : 0,
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity: _mostrarBotonesRapidos ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: _mostrarBotonesRapidos
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              // Botón +5
                              ElevatedButton.icon(
                                icon: const FaIcon(
                                  FontAwesomeIcons.plus,
                                  size: 12,
                                ),
                                label: const Text('+5'),
                                onPressed: () {
                                  setState(() {
                                    int val = cantidadAgregar;
                                    val += 5;
                                    _cantidadController.text = val.toString();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3E3E3E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Botón +10
                              ElevatedButton.icon(
                                icon: const FaIcon(
                                  FontAwesomeIcons.plus,
                                  size: 12,
                                ),
                                label: const Text('+10'),
                                onPressed: () {
                                  setState(() {
                                    int val = cantidadAgregar;
                                    val += 10;
                                    _cantidadController.text = val.toString();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3E3E3E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
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
                        BorderSide(color: Colors.white.withValues(alpha: 0.2)),
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
                        BorderSide(color: Colors.white.withValues(alpha: 0.2)),
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

              // Información de ganancia
              ValueListenableBuilder(
                valueListenable: _precioVentaController,
                builder: (BuildContext context,
                    TextEditingValue precioVentaText, _) {
                  return ValueListenableBuilder(
                    valueListenable: _precioCompraController,
                    builder: (BuildContext context,
                        TextEditingValue precioCompraText, _) {
                      final double venta =
                          double.tryParse(precioVentaText.text) ?? 0;
                      final double compra =
                          double.tryParse(precioCompraText.text) ?? 0;
                      final double ganancia = venta - compra;
                      final num porcentaje =
                          compra > 0 ? (ganancia / compra) * 100 : 0;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Text(
                              'Ganancia:',
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              'S/ ${ganancia.toStringAsFixed(2)} (${porcentaje.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                color: ganancia > 0
                                    ? Colors.green[400]
                                    : const Color(0xFFE31E24),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Switch(
                    value: _liquidacion,
                    onChanged: (v) => setState(() => _liquidacion = v),
                    activeThumbColor: Colors.amber,
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
                      borderSide: BorderSide(
                          color: Colors.amber.withValues(alpha: 0.2)),
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
