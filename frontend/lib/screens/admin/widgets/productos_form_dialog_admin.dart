import 'package:flutter/material.dart';
import '../../../models/producto.model.dart';

class ProductosFormDialogAdmin extends StatefulWidget {
  final Producto? producto;
  final Function(Producto) onSave;

  const ProductosFormDialogAdmin({
    super.key,
    this.producto,
    required this.onSave,
  });

  @override
  State<ProductosFormDialogAdmin> createState() => _ProductosFormDialogAdminState();
}

class _ProductosFormDialogAdminState extends State<ProductosFormDialogAdmin> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioController;
  late TextEditingController _existenciasController;
  late TextEditingController _codigoController;
  late TextEditingController _marcaController;
  late TextEditingController _precioCompraController;
  String _categoriaSeleccionada = 'Motor';
  List<ReglaDescuento> _reglasDescuento = [];
  bool _esLiquidacion = false;
  bool _tieneDescuentoTiempo = false;
  int _diasSinVenta = 30;
  double _porcentajeDescuentoTiempo = 10;
  String _localSeleccionado = 'Central';

  @override
  void initState() {
    super.initState();
    final producto = widget.producto;
    _nombreController = TextEditingController(text: producto?.nombre);
    _descripcionController = TextEditingController(text: producto?.descripcion);
    _precioController = TextEditingController(
      text: producto?.precio.toString() ?? '0.00',
    );
    _existenciasController = TextEditingController(
      text: producto?.existencias.toString() ?? '0',
    );
    _codigoController = TextEditingController(text: producto?.codigo);
    _marcaController = TextEditingController(text: producto?.marca);
    _categoriaSeleccionada = producto?.categoria ?? 'Motor';
    _reglasDescuento = producto?.reglasDescuento ?? [];
    _esLiquidacion = producto?.esLiquidacion ?? false;
    _precioCompraController = TextEditingController(
      text: producto?.precioCompra.toString() ?? '0.00',
    );
    _tieneDescuentoTiempo = producto?.tieneDescuentoTiempo ?? false;
    _diasSinVenta = producto?.diasSinVenta ?? 30;
    _porcentajeDescuentoTiempo = producto?.porcentajeDescuentoTiempo ?? 10;
    _localSeleccionado = producto?.local ?? 'Central';
  }

  void _agregarReglaDescuento() {
    setState(() {
      _reglasDescuento.add(ReglaDescuento(
        quantity: 2,
        discountPercentage: 10,
      ));
    });
  }

  void _eliminarReglaDescuento(int index) {
    setState(() {
      _reglasDescuento.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isHorizontal = screenSize.width > screenSize.height;
    final isWideScreen = screenSize.width > 600;

    return Dialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWideScreen ? screenSize.width * 0.1 : 16,
        vertical: isWideScreen ? screenSize.height * 0.1 : 24,
      ),
      child: Container(
        width: isWideScreen ? screenSize.width * 0.8 : screenSize.width,
        constraints: BoxConstraints(
          maxWidth: 1200,
          maxHeight: isHorizontal 
              ? screenSize.height * 0.9
              : screenSize.height * 0.8,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    widget.producto == null ? 'Nuevo Producto' : 'Editar Producto',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: isHorizontal && isWideScreen
                      ? _buildTwoColumnLayout()
                      : _buildOneColumnLayout(),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _handleSave,
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOneColumnLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBasicInfoSection(),
        const SizedBox(height: 32),
        _buildPricingSection(),
        const SizedBox(height: 32),
        _buildCategorySection(),
        const SizedBox(height: 32),
        _buildDiscountSection(),
      ],
    );
  }

  Widget _buildTwoColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 32),
              _buildPricingSection(),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategorySection(),
              const SizedBox(height: 32),
              _buildDiscountSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información Básica',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nombreController,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descripcionController,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _codigoController,
          decoration: const InputDecoration(
            labelText: 'Código',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Campo requerido' : null,
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Precios y Stock',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _precioCompraController,
          decoration: const InputDecoration(
            labelText: 'Precio de Compra',
            prefixText: 'S/ ',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _precioController,
          decoration: const InputDecoration(
            labelText: 'Precio de Venta',
            prefixText: 'S/ ',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Campo requerido';
            final venta = double.tryParse(value!) ?? 0;
            final compra = double.tryParse(_precioCompraController.text) ?? 0;
            if (venta <= compra) {
              return 'El precio de venta debe ser mayor al de compra';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _existenciasController,
          decoration: const InputDecoration(
            labelText: 'Stock',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder(
          valueListenable: _precioController,
          builder: (context, precioText, child) {
            final venta = double.tryParse(precioText.text) ?? 0;
            final compra = double.tryParse(_precioCompraController.text) ?? 0;
            final ganancia = venta - compra;
            final porcentaje = compra > 0 ? (ganancia / compra) * 100 : 0;
            
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ganancia:'),
                  Text(
                    'S/ ${ganancia.toStringAsFixed(2)} (${porcentaje.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      color: ganancia > 0 ? Colors.green[700] : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categorización',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _marcaController,
          decoration: const InputDecoration(
            labelText: 'Marca',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _categoriaSeleccionada,
          decoration: const InputDecoration(
            labelText: 'Categoría',
            border: OutlineInputBorder(),
          ),
          items: [
            'Motor',
            'Cascos',
            'Sliders',
            'Trajes',
            'Repuestos',
            'Stickers',
            'llantas'
          ].map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _categoriaSeleccionada = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDiscountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reglas de Descuento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _agregarReglaDescuento,
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._reglasDescuento.asMap().entries.map((entry) {
          final index = entry.key;
          final rule = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: rule.quantity.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Cantidad',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _reglasDescuento[index] = ReglaDescuento(
                            quantity: int.tryParse(value) ?? 2,
                            discountPercentage: rule.discountPercentage,
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: rule.discountPercentage.toString(),
                      decoration: const InputDecoration(
                        labelText: '% Descuento',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _reglasDescuento[index] = ReglaDescuento(
                            quantity: rule.quantity,
                            discountPercentage: (int.tryParse(value) ?? 10).toDouble(),
                          );
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _eliminarReglaDescuento(index),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        const Divider(height: 32),
        
        // Sección de Liquidación
        const Text(
          'Liquidación',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Switch de liquidación general
        SwitchListTile(
          title: const Text('Producto en liquidación'),
          subtitle: const Text('Aplicar descuento inmediato'),
          value: _esLiquidacion,
          onChanged: (value) {
            setState(() {
              _esLiquidacion = value;
            });
          },
        ),

        // Descuento por tiempo sin venta
        SwitchListTile(
          title: const Text('Descuento por tiempo sin venta'),
          subtitle: const Text('Aplicar descuento automático después de un período'),
          value: _tieneDescuentoTiempo,
          onChanged: (value) {
            setState(() {
              _tieneDescuentoTiempo = value;
            });
          },
        ),

        if (_tieneDescuentoTiempo) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Días sin venta: $_diasSinVenta',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _diasSinVenta.toDouble(),
                      min: 15,
                      max: 90,
                      divisions: 15,
                      label: '$_diasSinVenta días',
                      onChanged: (value) {
                        setState(() {
                          _diasSinVenta = value.round();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descuento: ${_porcentajeDescuentoTiempo.round()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _porcentajeDescuentoTiempo,
                      min: 5,
                      max: 50,
                      divisions: 9,
                      label: '${_porcentajeDescuentoTiempo.round()}%',
                      onChanged: (value) {
                        setState(() {
                          _porcentajeDescuentoTiempo = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],

        const Divider(height: 32),
        
        // Sección de Ubicación
        const Text(
          'Ubicación del Producto',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        DropdownButtonFormField<String>(
          value: _localSeleccionado,
          decoration: const InputDecoration(
            labelText: 'Local',
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(
              value: 'Central',
              child: Row(
                children: [
                  const Icon(Icons.store),
                  const SizedBox(width: 8),
                  const Text('Central'),
                  const SizedBox(width: 8),
                  Text(
                    'Av. La Marina 123',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'Sucursal 1',
              child: Row(
                children: [
                  const Icon(Icons.store),
                  const SizedBox(width: 8),
                  const Text('Sucursal 1'),
                  const SizedBox(width: 8),
                  Text(
                    'Av. Brasil 456',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'Sucursal 2',
              child: Row(
                children: [
                  const Icon(Icons.store),
                  const SizedBox(width: 8),
                  const Text('Sucursal 2'),
                  const SizedBox(width: 8),
                  Text(
                    'Av. Arequipa 789',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _localSeleccionado = value!;
            });
          },
        ),
      ],
    );
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final List<ReglaDescuento> todosLosDescuentos = [..._reglasDescuento];
      
      if (_tieneDescuentoTiempo) {
        todosLosDescuentos.add(ReglaDescuento(
          quantity: 1,
          discountPercentage: _porcentajeDescuentoTiempo.round().toDouble(),
          daysWithoutSale: _diasSinVenta,
          timeDiscount: _porcentajeDescuentoTiempo,
        ));
      }

      final producto = Producto(
        id: widget.producto?.id ?? 0,
        nombre: _nombreController.text,
        codigo: _codigoController.text,
        precio: double.parse(_precioController.text),
        precioCompra: double.parse(_precioCompraController.text),
        existencias: int.parse(_existenciasController.text),
        descripcion: _descripcionController.text,
        categoria: _categoriaSeleccionada,
        marca: _marcaController.text,
        esLiquidacion: _esLiquidacion,
        local: _localSeleccionado,
        reglasDescuento: todosLosDescuentos,
        fechaCreacion: widget.producto?.fechaCreacion ?? DateTime.now(),
        fechaActualizacion: DateTime.now(),
        tieneDescuentoTiempo: _tieneDescuentoTiempo,
        diasSinVenta: _tieneDescuentoTiempo ? _diasSinVenta : null,
        porcentajeDescuentoTiempo: _tieneDescuentoTiempo ? _porcentajeDescuentoTiempo : null,
        tieneDescuento: todosLosDescuentos.isNotEmpty,
      );

      widget.onSave(producto);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _existenciasController.dispose();
    _codigoController.dispose();
    _marcaController.dispose();
    _precioCompraController.dispose();
    super.dispose();
  }
} 