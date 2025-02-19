import 'package:flutter/material.dart';
import '../../../models/movement.dart';
import '../../../models/product.dart';
import '../../../api/api.service.dart';
import '../../../api/movimientos.api.dart';

class MovementRequestDialog extends StatefulWidget {
  final Function(Movement) onSave;
  final int userId;
  final int localId;

  const MovementRequestDialog({
    super.key,
    required this.onSave,
    required this.userId,
    required this.localId,
  });

  @override
  State<MovementRequestDialog> createState() => _MovementRequestDialogState();
}

class _MovementRequestDialogState extends State<MovementRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _movimientosApi = MovimientosApi(ApiService());
  final _quantityController = TextEditingController();
  
  Product? _selectedProduct;
  String? _selectedDestination;
  bool _isLoading = false;
  List<Product> _products = [];
  
  // Lista de sucursales disponibles
  final List<String> _branches = ['Central Principal', 'Sucursal 1', 'Sucursal 2'];
  
  // Sucursal actual (TODO: Obtener del estado global)
  final String _currentBranch = 'Sucursal 1';
  
  List<String> get _availableBranches => _branches
      .where((branch) => branch != _currentBranch)
      .toList();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final productsData = await _movimientosApi.api.request(
        endpoint: '/productos',
        method: 'GET',
        queryParams: const {},
      );
      
      if (!mounted) return;
      setState(() {
        _products = (productsData as List)
            .map((p) => Product.fromJson(p))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar productos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    setState(() => _isLoading = true);
    
    try {
      final response = await _movimientosApi.createMovement({
        'producto_id': _selectedProduct!.id,
        'usuario_id': widget.userId,
        'local_id': widget.localId,
        'cantidad': int.parse(_quantityController.text),
        'sucursal_origen': _currentBranch,
        'sucursal_destino': _selectedDestination!,
      });

      if (!mounted) return;
      
      // Notificar éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud creada correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Cerrar diálogo y retornar el movimiento creado
      if (!mounted) return;
      Navigator.of(context).pop(Movement.fromJson(response));
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Solicitud de Productos'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Product>(
                      value: _selectedProduct,
                      decoration: const InputDecoration(
                        labelText: 'Producto',
                      ),
                      items: _products.map((product) {
                        return DropdownMenuItem(
                          value: product,
                          child: Text(product.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedProduct = value);
                      },
                      validator: (value) {
                        if (value == null) return 'Seleccione un producto';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese una cantidad';
                        }
                        final quantity = int.tryParse(value);
                        if (quantity == null || quantity <= 0) {
                          return 'Cantidad inválida';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedDestination,
                      decoration: const InputDecoration(
                        labelText: 'Sucursal Destino',
                      ),
                      items: _availableBranches.map((branch) {
                        return DropdownMenuItem(
                          value: branch,
                          child: Text(branch),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedDestination = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Seleccione la sucursal destino';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: const Text('Solicitar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
} 