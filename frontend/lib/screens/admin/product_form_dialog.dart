import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/regla_descuento.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? product;
  final Function(Product) onSave;

  const ProductFormDialog({
    super.key,
    this.product,
    required this.onSave,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _codeController;
  late TextEditingController _brandController;
  late TextEditingController _purchasePriceController;
  String _selectedCategory = 'Motor';
  List<ReglaDescuento> _discountRules = [];
  bool _isLiquidacion = false;
  bool _hasTimeDiscount = false;
  int _daysWithoutSale = 30;
  double _timeDiscountPercentage = 10;
  String _selectedBranch = 'Central';

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name);
    _descriptionController = TextEditingController(text: product?.description);
    _priceController = TextEditingController(
      text: product?.price.toString() ?? '0.00',
    );
    _stockController = TextEditingController(
      text: product?.stock.toString() ?? '0',
    );
    _codeController = TextEditingController(text: product?.codigo);
    _brandController = TextEditingController(text: product?.marca);
    _selectedCategory = product?.category ?? 'Motor';
    _discountRules = product?.discountRules ?? [];
    _isLiquidacion = product?.isLiquidacion ?? false;
    _purchasePriceController = TextEditingController(
      text: product?.purchasePrice.toString() ?? '0.00',
    );
    _hasTimeDiscount = product?.hasTimeDiscount ?? false;
    _daysWithoutSale = product?.daysWithoutSale ?? 30;
    _timeDiscountPercentage = product?.timeDiscountPercentage ?? 10;
    _selectedBranch = product?.local ?? 'Central';
  }

  void _addDiscountRule() {
    setState(() {
      _discountRules.add(ReglaDescuento(
        quantity: 2,
        discountPercentage: 10,
      ));
    });
  }

  void _removeDiscountRule(int index) {
    setState(() {
      _discountRules.removeAt(index);
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
                    widget.product == null ? 'Nuevo Producto' : 'Editar Producto',
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
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _codeController,
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
          controller: _purchasePriceController,
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
          controller: _priceController,
          decoration: const InputDecoration(
            labelText: 'Precio de Venta',
            prefixText: 'S/ ',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Campo requerido';
            final venta = double.tryParse(value!) ?? 0;
            final compra = double.tryParse(_purchasePriceController.text) ?? 0;
            if (venta <= compra) {
              return 'El precio de venta debe ser mayor al de compra';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _stockController,
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
          valueListenable: _priceController,
          builder: (context, priceText, child) {
            final venta = double.tryParse(priceText.text) ?? 0;
            final compra = double.tryParse(_purchasePriceController.text) ?? 0;
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
          controller: _brandController,
          decoration: const InputDecoration(
            labelText: 'Marca',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
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
              _selectedCategory = value!;
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
              onPressed: _addDiscountRule,
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._discountRules.asMap().entries.map((entry) {
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
                          _discountRules[index] = ReglaDescuento(
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
                          _discountRules[index] = ReglaDescuento(
                            quantity: rule.quantity,
                            discountPercentage: (int.tryParse(value) ?? 10).toDouble(),
                          );
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeDiscountRule(index),
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
          value: _isLiquidacion,
          onChanged: (value) {
            setState(() {
              _isLiquidacion = value;
            });
          },
        ),

        // Descuento por tiempo sin venta
        SwitchListTile(
          title: const Text('Descuento por tiempo sin venta'),
          subtitle: const Text('Aplicar descuento automático después de un período'),
          value: _hasTimeDiscount,
          onChanged: (value) {
            setState(() {
              _hasTimeDiscount = value;
            });
          },
        ),

        if (_hasTimeDiscount) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Días sin venta: $_daysWithoutSale',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _daysWithoutSale.toDouble(),
                      min: 15,
                      max: 90,
                      divisions: 15,
                      label: '$_daysWithoutSale días',
                      onChanged: (value) {
                        setState(() {
                          _daysWithoutSale = value.round();
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
                      'Descuento: ${_timeDiscountPercentage.round()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _timeDiscountPercentage,
                      min: 5,
                      max: 50,
                      divisions: 9,
                      label: '${_timeDiscountPercentage.round()}%',
                      onChanged: (value) {
                        setState(() {
                          _timeDiscountPercentage = value;
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
          value: _selectedBranch,
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
              _selectedBranch = value!;
            });
          },
        ),
      ],
    );
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final List<ReglaDescuento> allDiscounts = [..._discountRules];
      
      // Agregar regla de descuento por tiempo si está activa
      if (_hasTimeDiscount) {
        allDiscounts.add(ReglaDescuento(
          quantity: 1,
          discountPercentage: _timeDiscountPercentage.round().toDouble(),
          daysWithoutSale: _daysWithoutSale,
          timeDiscount: _timeDiscountPercentage,
        ));
      }

      final product = Product(
        id: widget.product?.id ?? 0,
        nombre: _nameController.text,
        codigo: _codeController.text,
        precio: double.parse(_priceController.text),
        precioCompra: double.parse(_purchasePriceController.text),
        existencias: int.parse(_stockController.text),
        descripcion: _descriptionController.text,
        categoria: _selectedCategory,
        marca: _brandController.text,
        esLiquidacion: _isLiquidacion,
        localId: int.parse(_selectedBranch.split(' ').last),
        reglasDescuento: allDiscounts,
        fechaCreacion: widget.product?.fechaCreacion ?? DateTime.now(),
        fechaActualizacion: DateTime.now(),
      );
      widget.onSave(product);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _codeController.dispose();
    _brandController.dispose();
    _purchasePriceController.dispose();
    super.dispose();
  }
} 