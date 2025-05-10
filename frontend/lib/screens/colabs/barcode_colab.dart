import 'package:collection/collection.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:flutter/foundation.dart';
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
    canvas
      ..drawPath(
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
  final List<Producto> productos;
  final Function(Producto) onProductoSeleccionado;
  final bool isLoading;

  const BarcodeColabScreen({
    super.key,
    required this.productos,
    required this.onProductoSeleccionado,
    this.isLoading = false,
  });

  @override
  State<BarcodeColabScreen> createState() => _BarcodeColabScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Producto>('productos', productos))
      ..add(ObjectFlagProperty<Function(Producto)>.has(
          'onProductoSeleccionado', onProductoSeleccionado))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading));
  }
}

class _BarcodeColabScreenState extends State<BarcodeColabScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _lastScannedCode;
  Producto? _foundProduct;
  bool _quickAdd = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Nuevas variables para control de múltiples escaneos
  final Set<String> _scannedCodes = <String>{};
  final List<Producto> _foundProducts = <Producto>[];
  DateTime? _lastScanTime;
  static const Duration _scanCooldown = Duration(milliseconds: 1500);
  bool _isProcessingMultiple = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    final DateTime now = DateTime.now();

    // Verificar el cooldown entre escaneos
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!) < _scanCooldown) {
      return;
    }
    _lastScanTime = now;

    // Si hay múltiples códigos
    if (barcodes.length > 1) {
      _handleMultipleBarcodes(barcodes);
      return;
    }

    // Si es un solo código
    for (final Barcode barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code == null || code == _lastScannedCode) {
        continue;
      }

      _lastScannedCode = code;
      _searchProduct(code);
    }
  }

  void _handleMultipleBarcodes(List<Barcode> barcodes) {
    if (_isProcessingMultiple) {
      return;
    }
    _isProcessingMultiple = true;

    // Filtrar códigos únicos y válidos
    final Set<String> uniqueCodes = barcodes
        .where((b) => b.rawValue != null && !_scannedCodes.contains(b.rawValue))
        .map((b) => b.rawValue!)
        .toSet();

    if (uniqueCodes.isEmpty) {
      _isProcessingMultiple = false;
      return;
    }

    // Mostrar diálogo de confirmación
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.amber,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Múltiples Códigos Detectados',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Contenido
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Se detectaron ${uniqueCodes.length} códigos diferentes',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '¿Desea procesar todos los códigos encontrados?',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _isProcessingMultiple = false;
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _processMultipleCodes(uniqueCodes.toList());
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Procesar Todos'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processMultipleCodes(List<String> codes) async {
    setState(() => _isLoading = true);
    _foundProducts.clear();

    for (final String code in codes) {
      if (_scannedCodes.contains(code)) {
        continue;
      }

      final Producto? producto = widget.productos.firstWhereOrNull(
        (Producto p) => p.sku == code,
      );

      if (producto != null) {
        _foundProducts.add(producto);
        _scannedCodes.add(code);
      }
    }

    setState(() => _isLoading = false);

    if (_foundProducts.isEmpty) {
      _showNoProductsFoundDialog(codes);
      return;
    }

    _showMultipleProductsDialog(_foundProducts);
    _isProcessingMultiple = false;
  }

  void _showNoProductsFoundDialog(List<String> codes) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Productos No Encontrados',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No se encontraron productos con los siguientes códigos:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            ...codes.map((code) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• $code',
                    style: const TextStyle(color: Colors.white54),
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showMultipleProductsDialog(List<Producto> products) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: [
            const Icon(Icons.shopping_cart, color: Color(0xFF4CAF50)),
            const SizedBox(width: 8),
            Text(
              'Productos Encontrados (${products.length})',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final producto = products[index];
              final bool tieneStock = producto.stock > 0;

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    FontAwesomeIcons.box,
                    color: tieneStock ? const Color(0xFF4CAF50) : Colors.red,
                  ),
                ),
                title: Text(
                  producto.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SKU: ${producto.sku}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Stock: ${producto.stock}',
                      style: TextStyle(
                        color:
                            tieneStock ? const Color(0xFF4CAF50) : Colors.red,
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  'S/ ${producto.precioVenta.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                enabled: tieneStock,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            onPressed: () {
              Navigator.pop(context);
              // Agregar solo los productos con stock
              for (final producto in products) {
                if (producto.stock > 0) {
                  widget.onProductoSeleccionado(producto);
                }
              }
              Navigator.pop(context); // Cerrar pantalla de escaneo
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add_shopping_cart, size: 18),
                SizedBox(width: 8),
                Text('Agregar Todos'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _searchProduct(String code) {
    setState(() => _isLoading = true);

    // Buscar en la lista de productos proporcionada
    final Producto? producto = widget.productos.firstWhereOrNull(
      (Producto p) => p.sku == code,
    );

    setState(() {
      _foundProduct = producto;
      _isLoading = false;
    });

    if (_foundProduct != null) {
      if (_quickAdd && _foundProduct!.stock > 0) {
        // Modo de agregado rápido
        widget.onProductoSeleccionado(_foundProduct!);
        // Determinar el tipo de promoción
        final bool enLiquidacion = _foundProduct!.estaEnLiquidacion;
        final bool tienePromocionGratis = _foundProduct!.tienePromocionGratis;
        final bool tieneDescuentoPorcentual =
            _foundProduct!.tieneDescuentoPorcentual;

        // Construir el mensaje de promoción
        String mensajePromocion = '';
        Color colorPromocion = const Color(0xFF2E7D32);
        IconData iconoPromocion = Icons.bolt;

        if (enLiquidacion) {
          final double precioOriginal = _foundProduct!.precioVenta;
          final double precioLiquidacion =
              _foundProduct!.precioOferta ?? _foundProduct!.precioVenta;
          final int porcentajeDescuento =
              ((precioOriginal - precioLiquidacion) / precioOriginal * 100)
                  .round();
          mensajePromocion =
              '¡En liquidación! $porcentajeDescuento% de descuento';
          colorPromocion = Colors.amber;
          iconoPromocion = Icons.local_fire_department;
        } else if (tienePromocionGratis) {
          final int cantidadMinima =
              _foundProduct!.cantidadMinimaDescuento ?? 0;
          final int cantidadGratis =
              _foundProduct!.cantidadGratisDescuento ?? 0;
          mensajePromocion =
              'Lleva $cantidadMinima y paga ${(cantidadMinima) - (cantidadGratis)}';
          colorPromocion = const Color(0xFF4CAF50);
          iconoPromocion = Icons.card_giftcard;
        } else if (tieneDescuentoPorcentual) {
          final int porcentaje = _foundProduct!.porcentajeDescuento ?? 0;
          final int cantidadMinima =
              _foundProduct!.cantidadMinimaDescuento ?? 0;
          mensajePromocion = '$porcentaje% al llevar $cantidadMinima o más';
          colorPromocion = Colors.purple;
          iconoPromocion = Icons.percent;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(iconoPromocion, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agregado: ${_foundProduct!.nombre}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'S/ ${_foundProduct!.precioVenta.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                          if (mensajePromocion.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorPromocion.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                mensajePromocion,
                                style: TextStyle(
                                  color: colorPromocion,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E1E1E),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(8),
          ),
        );
      } else {
        _showProductDialog(_foundProduct!);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se encontró el producto con código: $code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showProductDialog(Producto producto) {
    // Determinar el tipo de promoción
    final bool enLiquidacion = producto.estaEnLiquidacion;
    final bool tienePromocionGratis = producto.tienePromocionGratis;
    final bool tieneDescuentoPorcentual = producto.tieneDescuentoPorcentual;
    final bool tieneStock = producto.stock > 0;

    // Determinar el color y el icono según el tipo de promoción
    Color colorPromocion = const Color(0xFF4CAF50);
    IconData iconoPromocion = FontAwesomeIcons.box;

    if (enLiquidacion) {
      colorPromocion = Colors.amber;
      iconoPromocion = Icons.local_fire_department;
    } else if (tienePromocionGratis) {
      colorPromocion = const Color(0xFF4CAF50);
      iconoPromocion = Icons.card_giftcard;
    } else if (tieneDescuentoPorcentual) {
      colorPromocion = Colors.purple;
      iconoPromocion = Icons.percent;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              tieneStock ? Icons.check_circle : Icons.error,
              color: tieneStock ? const Color(0xFF4CAF50) : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Producto Encontrado',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Icono y nombre del producto
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorPromocion.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    iconoPromocion,
                    size: 30,
                    color: colorPromocion,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'SKU: ${producto.sku}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Información de precio y stock
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Precio',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    if (enLiquidacion && producto.precioOferta != null) ...[
                      Text(
                        'S/ ${producto.precioVenta.toStringAsFixed(2)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'S/ ${producto.precioOferta!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'S/ ${producto.precioVenta.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tieneStock
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: tieneStock
                          ? Colors.green.withOpacity(0.5)
                          : Colors.red.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    'Stock: ${producto.stock}',
                    style: TextStyle(
                      color: tieneStock ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Información de promociones
            if (enLiquidacion) ...[
              _buildPromocionInfo(
                Icons.local_fire_department,
                Colors.amber,
                'Liquidación',
                'Precio especial por liquidación',
              ),
            ],

            if (tienePromocionGratis) ...[
              if (enLiquidacion) const SizedBox(height: 8),
              _buildPromocionInfo(
                Icons.card_giftcard,
                const Color(0xFF4CAF50),
                'Promoción "Lleva y Paga"',
                'Lleva ${producto.cantidadMinimaDescuento ?? 0} y paga ${(producto.cantidadMinimaDescuento ?? 0) - (producto.cantidadGratisDescuento ?? 0)}',
              ),
            ],

            if (tieneDescuentoPorcentual) ...[
              if (enLiquidacion || tienePromocionGratis)
                const SizedBox(height: 8),
              _buildPromocionInfo(
                Icons.percent,
                Colors.purple,
                'Descuento por Cantidad',
                '${producto.porcentajeDescuento}% al llevar ${producto.cantidadMinimaDescuento ?? 0} o más',
              ),
            ],

            // Información adicional
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.tag,
                  size: 14,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Text(
                  producto.categoria,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  FontAwesomeIcons.industry,
                  size: 14,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Text(
                  producto.marca,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  tieneStock ? const Color(0xFF4CAF50) : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: tieneStock
                ? () {
                    Navigator.pop(context);
                    widget.onProductoSeleccionado(producto);
                    Navigator.pop(context); // Cerrar pantalla de escaneo
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_shopping_cart, size: 18),
                  SizedBox(width: 8),
                  Text('Agregar al Carrito'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromocionInfo(
      IconData icon, Color color, String titulo, String descripcion) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descripcion,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
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
          // Botón de agregado rápido con animación
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: IconButton(
                  icon: Icon(
                    _quickAdd ? Icons.bolt : Icons.bolt_outlined,
                    color: _quickAdd ? Colors.amber : Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _quickAdd = !_quickAdd;
                    });
                    if (_quickAdd) {
                      _animationController.forward();
                    } else {
                      _animationController.reverse();
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              _quickAdd ? Icons.bolt : Icons.bolt_outlined,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _quickAdd
                                  ? 'Modo rápido: Agregado automático al escanear'
                                  : 'Modo normal: Confirmación antes de agregar',
                            ),
                          ],
                        ),
                        backgroundColor: _quickAdd
                            ? const Color(0xFF2E7D32)
                            : Colors.grey[700],
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Agregado Rápido',
                ),
              );
            },
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: MediaQuery.of(context).size.width * 0.9,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      _quickAdd ? Colors.amber : Theme.of(context).primaryColor,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      _quickAdd ? Icons.bolt : FontAwesomeIcons.barcode,
                      key: ValueKey<bool>(_quickAdd),
                      size: 40,
                      color: _quickAdd
                          ? Colors.amber.withOpacity(0.8)
                          : Theme.of(context).primaryColor.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Coloque el código de barras dentro del recuadro',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            shadows: <Shadow>[
                              Shadow(
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        if (_quickAdd) ...[
                          const SizedBox(height: 4),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: _quickAdd ? 1.0 : 0.0,
                            child: Text(
                              'Modo rápido activado',
                              style: TextStyle(
                                color: Colors.amber.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading || widget.isLoading)
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
    return Path.combine(
        PathOperation.difference, path, Path()..addRect(cutout));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}
