import 'package:flutter/material.dart';
import '../../api/productos.api.dart' as productos_api;
import '../../api/main.api.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeVendorScreen extends StatefulWidget {
  const BarcodeVendorScreen({super.key});

  @override
  State<BarcodeVendorScreen> createState() => _BarcodeVendorScreenState();
}

class _BarcodeVendorScreenState extends State<BarcodeVendorScreen> {
  final _apiService = ApiService();
  late final productos_api.ProductosApi _productosApi;
  bool _isLoading = false;
  productos_api.Producto? _productoEncontrado;
  String? _error;

  @override
  void initState() {
    super.initState();
    _productosApi = productos_api.ProductosApi(_apiService);
  }

  Future<void> _buscarProducto(String codigo) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _productoEncontrado = null;
    });

    try {
      final productos = await _productosApi.searchProductos(codigo);
      
      if (!mounted) return;
      
      if (productos.isEmpty) {
        setState(() {
          _error = 'No se encontró ningún producto con el código $codigo';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _productoEncontrado = productos.first;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al buscar el producto: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner de Productos'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _buscarProducto(barcode.rawValue!);
                  }
                }
              },
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        )
                      : _productoEncontrado != null
                          ? _buildProductoInfo(_productoEncontrado!)
                          : const Center(
                              child: Text(
                                'Escanee un código de barras para ver la información del producto',
                                textAlign: TextAlign.center,
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductoInfo(productos_api.Producto producto) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              producto.nombre,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Código: ${producto.codigo}'),
            Text('Marca: ${producto.marca}'),
            Text('Categoría: ${producto.categoria}'),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Precio Normal:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'S/ ${producto.precioNormal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (producto.precioMayorista != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Precio Mayorista:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'S/ ${producto.precioMayorista!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            if (producto.precioDescuento != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Precio Descuento:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'S/ ${producto.precioDescuento!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
