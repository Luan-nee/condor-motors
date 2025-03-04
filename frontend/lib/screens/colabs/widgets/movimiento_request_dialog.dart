import 'package:flutter/material.dart';
import '../../../api/movimientos_stock.api.dart';
import '../../../api/productos.api.dart' as productos_api;
import '../../../api/main.api.dart';

class MovimientoRequestDialog extends StatefulWidget {
  final Function(MovimientoStock) onSave;
  final String usuarioId;
  final int localId;

  const MovimientoRequestDialog({
    super.key,
    required this.onSave,
    required this.usuarioId,
    required this.localId,
  });

  @override
  State<MovimientoRequestDialog> createState() => _MovimientoRequestDialogState();
}

class _MovimientoRequestDialogState extends State<MovimientoRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _movimientosApi = MovimientosStockApi(ApiService());
  final _productosApi = productos_api.ProductosApi(ApiService());
  final _cantidadController = TextEditingController();
  
  productos_api.Producto? _productoSeleccionado;
  String? _destinoSeleccionado;
  bool _isLoading = false;
  List<productos_api.Producto> _productos = [];
  
  // Lista de sucursales disponibles
  final List<String> _sucursales = ['Central Principal', 'Sucursal 1', 'Sucursal 2'];
  
  // Sucursal actual (TODO: Obtener del estado global)
  final String _sucursalActual = 'Sucursal 1';
  
  List<String> get _sucursalesDisponibles => _sucursales
      .where((sucursal) => sucursal != _sucursalActual)
      .toList();

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() => _isLoading = true);
    try {
      final productos = await _productosApi.getProductos();
      
      if (!mounted) return;
      setState(() {
        _productos = productos;
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
      final response = await _movimientosApi.createMovimiento({
        'tipo': MovimientosStockApi.tipos['TRASLADO'],
        'estado': MovimientosStockApi.estadosDetalle['PENDIENTE'],
        'local_origen_id': widget.localId,
        'local_destino_id': int.parse(_destinoSeleccionado!),
        'solicitante_id': widget.usuarioId,
        'detalles': [
          {
            'producto_id': _productoSeleccionado!.id,
            'cantidad': int.parse(_cantidadController.text),
            'estado': MovimientosStockApi.estadosDetalle['PENDIENTE'],
          }
        ],
      });

      if (!mounted) return;
      
      if (response != null) {
        // Notificar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud creada correctamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Cerrar diálogo y retornar el movimiento creado
        Navigator.of(context).pop();
        widget.onSave(response);
      } else {
        throw Exception('No se pudo crear el movimiento');
      }
      
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
                    DropdownButtonFormField<productos_api.Producto>(
                      value: _productoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Producto',
                      ),
                      items: _productos.map((producto) {
                        return DropdownMenuItem(
                          value: producto,
                          child: Text(producto.nombre),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _productoSeleccionado = value);
                      },
                      validator: (value) {
                        if (value == null) return 'Seleccione un producto';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cantidadController,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese una cantidad';
                        }
                        final cantidad = int.tryParse(value);
                        if (cantidad == null || cantidad <= 0) {
                          return 'Cantidad inválida';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _destinoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Sucursal Destino',
                      ),
                      items: _sucursalesDisponibles.map((sucursal) {
                        return DropdownMenuItem(
                          value: sucursal,
                          child: Text(sucursal),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _destinoSeleccionado = value);
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
    _cantidadController.dispose();
    super.dispose();
  }
} 