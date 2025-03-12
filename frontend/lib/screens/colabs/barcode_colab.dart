import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../api/productos.api.dart' as productos_api;
import '../../api/main.api.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Clase para dibujar las esquinas del cuadro de escaneo
class CornersPainter extends CustomPainter {
  final Color color;
  final double cornerSize;
  final double cornerWidth;

  CornersPainter({
    required this.color,
    required this.cornerSize,
    required this.cornerWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = cornerWidth
      ..style = PaintingStyle.stroke;

    final width = size.width;
    final height = size.height;

    // Esquina superior izquierda
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerSize)
        ..lineTo(0, 0)
        ..lineTo(cornerSize, 0),
      paint,
    );

    // Esquina superior derecha
    canvas.drawPath(
      Path()
        ..moveTo(width - cornerSize, 0)
        ..lineTo(width, 0)
        ..lineTo(width, cornerSize),
      paint,
    );

    // Esquina inferior izquierda
    canvas.drawPath(
      Path()
        ..moveTo(0, height - cornerSize)
        ..lineTo(0, height)
        ..lineTo(cornerSize, height),
      paint,
    );

    // Esquina inferior derecha
    canvas.drawPath(
      Path()
        ..moveTo(width - cornerSize, height)
        ..lineTo(width, height)
        ..lineTo(width, height - cornerSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class BarcodeColabScreen extends StatefulWidget {
  const BarcodeColabScreen({super.key});

  @override
  State<BarcodeColabScreen> createState() => _BarcodeColabScreenState();
}

class _BarcodeColabScreenState extends State<BarcodeColabScreen> {
  final _apiService = ApiService();
  late final productos_api.ProductosApi _productosApi;
  bool _isLoading = false;
  productos_api.Producto? _productoEncontrado;
  String? _error;
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _productosApi = productos_api.ProductosApi(_apiService);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
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
    // Calcular dimensiones adaptables para el cuadro de escaneo
    final screenWidth = MediaQuery.of(context).size.width;
    
    // El ancho del cuadro será el 80% del ancho de la pantalla
    final scanBoxWidth = screenWidth * 0.8;
    
    // La altura del cuadro será proporcional al ancho para mantener una relación de aspecto adecuada
    // para códigos de barras (más ancho que alto)
    final scanBoxHeight = scanBoxWidth * 0.4;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código de Barras'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? MdiIcons.flashlight : MdiIcons.flashlightOff,
              color: _isTorchOn ? Colors.yellow : null,
            ),
            onPressed: () {
              setState(() {
                _isTorchOn = !_isTorchOn;
                _scannerController.toggleTorch();
              });
            },
            tooltip: _isTorchOn ? 'Apagar linterna' : 'Encender linterna',
          ),
          IconButton(
            icon: Icon(MdiIcons.cameraSwitch),
            onPressed: () {
              _scannerController.switchCamera();
            },
            tooltip: 'Cambiar cámara',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Escáner
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        _buscarProducto(barcode.rawValue!);
                        return;
                      }
                    }
                  },
                ),
                
                // Overlay oscuro con recorte transparente para el área de escaneo
                ClipPath(
                  clipper: ScannerOverlayClipper(
                    scanBoxWidth: scanBoxWidth,
                    scanBoxHeight: scanBoxHeight,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
                
                // Cuadro de escaneo
                Container(
                  width: scanBoxWidth,
                  height: scanBoxHeight,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                
                // Líneas de esquina para mejorar la visibilidad
                SizedBox(
                  width: scanBoxWidth + 20,
                  height: scanBoxHeight + 20,
                  child: CustomPaint(
                    painter: CornersPainter(
                      color: Theme.of(context).colorScheme.primary,
                      cornerSize: 20,
                      cornerWidth: 4,
                    ),
                  ),
                ),
                
                // Instrucciones
                Positioned(
                  bottom: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          MdiIcons.barcode,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Coloque el código de barras dentro del recuadro',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: _buildResultsPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Buscando producto...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(FontAwesomeIcons.circleExclamation, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                },
                icon: Icon(MdiIcons.refresh),
                label: const Text('Volver a Escanear'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_productoEncontrado == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                MdiIcons.barcode,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Escanee un código de barras para buscar un producto',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Asegúrese de que el código esté bien iluminado y centrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  MdiIcons.packageVariantClosed,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Producto Encontrado',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _productoEncontrado!.nombre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            'Código',
            _productoEncontrado!.codigo,
            FontAwesomeIcons.barcode,
          ),
          const Divider(),
          _buildInfoRow(
            'Categoría',
            _productoEncontrado!.categoria,
            FontAwesomeIcons.tag,
          ),
          const Divider(),
          _buildInfoRow(
            'Precio',
            'S/ ${_productoEncontrado!.precioNormal.toStringAsFixed(2)}',
            FontAwesomeIcons.moneyBill,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, _productoEncontrado);
                  },
                  icon: Icon(MdiIcons.check),
                  label: const Text('Seleccionar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _productoEncontrado = null;
                    });
                  },
                  icon: Icon(MdiIcons.close),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          FaIcon(
            icon,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Clipper para crear un recorte transparente en el overlay
class ScannerOverlayClipper extends CustomClipper<Path> {
  final double scanBoxWidth;
  final double scanBoxHeight;

  ScannerOverlayClipper({
    required this.scanBoxWidth,
    required this.scanBoxHeight,
  });

  @override
  Path getClip(Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutLeft = (size.width - scanBoxWidth) / 2;
    final cutoutTop = (size.height - scanBoxHeight) / 2;

    final cutout = Rect.fromLTWH(
      cutoutLeft,
      cutoutTop,
      scanBoxWidth,
      scanBoxHeight,
    );

    path.addRect(cutout);
    return Path.combine(PathOperation.difference, path, Path()..addRect(cutout));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
} 