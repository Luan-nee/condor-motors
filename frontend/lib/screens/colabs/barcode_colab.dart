import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = cornerWidth
      ..style = PaintingStyle.stroke;

    final double width = size.width;
    final double height = size.height;

    // Esquina superior izquierda
    canvas..drawPath(
      Path()
        ..moveTo(0, cornerSize)
        ..lineTo(0, 0)
        ..lineTo(cornerSize, 0),
      paint,
    )

    // Esquina superior derecha
    ..drawPath(
      Path()
        ..moveTo(width - cornerSize, 0)
        ..lineTo(width, 0)
        ..lineTo(width, cornerSize),
      paint,
    )

    // Esquina inferior izquierda
    ..drawPath(
      Path()
        ..moveTo(0, height - cornerSize)
        ..lineTo(0, height)
        ..lineTo(cornerSize, height),
      paint,
    )

    // Esquina inferior derecha
    ..drawPath(
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
  bool _isLoading = false;
  String? _lastScannedCode;
  Map<String, dynamic>? _foundProduct;

  // Datos de ejemplo para productos
  final List<Map<String, dynamic>> _productos = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 1,
      'codigo': 'CAS001',
      'nombre': 'Casco MT Thunder',
      'descripcion': 'Casco integral MT Thunder con sistema de ventilación avanzado',
      'precio': 299.99,
      'precioMayorista': 250.00,
      'stock': 15,
      'stockMinimo': 5,
      'categoria': 'Cascos',
      'marca': 'MT Helmets',
      'estado': 'ACTIVO',
      'imagen': 'assets/images/casco_mt.jpg'
    },
    <String, dynamic>{
      'id': 2,
      'codigo': 'ACE001',
      'nombre': 'Aceite Motul 5100',
      'descripcion': 'Aceite sintético 4T 15W-50 para motocicletas',
      'precio': 89.99,
      'precioMayorista': 75.00,
      'stock': 3,
      'stockMinimo': 10,
      'categoria': 'Lubricantes',
      'marca': 'Motul',
      'estado': 'BAJO_STOCK',
      'imagen': 'assets/images/aceite_motul.jpg'
    },
    <String, dynamic>{
      'id': 3,
      'codigo': 'LLA001',
      'nombre': 'Llanta Pirelli Diablo',
      'descripcion': 'Llanta deportiva Pirelli Diablo Rosso III 180/55 ZR17',
      'precio': 450.00,
      'precioMayorista': 380.00,
      'stock': 0,
      'stockMinimo': 4,
      'categoria': 'Llantas',
      'marca': 'Pirelli',
      'estado': 'AGOTADO',
      'imagen': 'assets/images/llanta_pirelli.jpg'
    },
    <String, dynamic>{
      'id': 4,
      'codigo': 'FRE001',
      'nombre': 'Kit de Frenos Brembo',
      'descripcion': 'Kit completo de frenos Brembo con pastillas y disco',
      'precio': 850.00,
      'precioMayorista': 720.00,
      'stock': 8,
      'stockMinimo': 3,
      'categoria': 'Frenos',
      'marca': 'Brembo',
      'estado': 'ACTIVO',
      'imagen': 'assets/images/frenos_brembo.jpg'
    },
    <String, dynamic>{
      'id': 5,
      'codigo': 'AMO001',
      'nombre': 'Amortiguador YSS',
      'descripcion': 'Amortiguador trasero YSS ajustable en compresión y rebote',
      'precio': 599.99,
      'precioMayorista': 520.00,
      'stock': 6,
      'stockMinimo': 4,
      'categoria': 'Suspensión',
      'marca': 'YSS',
      'estado': 'ACTIVO',
      'imagen': 'assets/images/amortiguador_yss.jpg'
    }
  ];

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    
    for (final Barcode barcode in barcodes) {
      if (barcode.rawValue == _lastScannedCode) {
        return; // Evitar escaneos duplicados
      }
      
      _lastScannedCode = barcode.rawValue;
      _searchProduct(barcode.rawValue ?? '');
    }
  }

  void _searchProduct(String code) {
    setState(() => _isLoading = true);

    // Simular búsqueda en datos locales
    final Map<String, dynamic> producto = _productos.firstWhere(
      (Map<String, dynamic> p) => p['codigo'] == code,
      orElse: () => <String, dynamic>{},
    );

    setState(() {
      _foundProduct = producto.isNotEmpty ? producto : null;
      _isLoading = false;
    });

    if (_foundProduct != null) {
      _showProductDialog(_foundProduct!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se encontró el producto con código: $code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showProductDialog(Map<String, dynamic> producto) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Producto Encontrado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              producto['nombre'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Código: ${producto['codigo']}'),
            Text('Marca: ${producto['marca']}'),
            Text('Categoría: ${producto['categoria']}'),
            const SizedBox(height: 8),
            Text(
              'S/ ${producto['precio'].toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            Text(
              'Stock: ${producto['stock']}',
              style: TextStyle(
                color: producto['estado'] == 'AGOTADO'
                    ? Colors.red
                    : producto['estado'] == 'BAJO_STOCK'
                        ? Colors.orange
                        : Colors.green,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, producto);
            },
            child: const Text('Seleccionar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código'),
        actions: <Widget>[
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.keyboard),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de entrada manual en desarrollo'),
                ),
              );
            },
            tooltip: 'Entrada manual',
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          MobileScanner(
            onDetect: _onDetect,
          ),
          // Overlay con guía de escaneo
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    FontAwesomeIcons.barcode,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Coloque el código de barras\ndentro del recuadro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      shadows: <Shadow>[
                        Shadow(
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
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
    final Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final double cutoutLeft = (size.width - scanBoxWidth) / 2;
    final double cutoutTop = (size.height - scanBoxHeight) / 2;

    final Rect cutout = Rect.fromLTWH(
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