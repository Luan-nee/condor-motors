import 'package:condorsmotors/models/color.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/color.repository.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/utils/productos_utils.dart';
import 'package:condorsmotors/utils/sucursal_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductoDetalleDialog extends StatefulWidget {
  final Producto producto;
  final List<Sucursal> sucursales;
  final Function(Producto)? onSave;

  const ProductoDetalleDialog({
    super.key,
    required this.producto,
    required this.sucursales,
    this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required Producto producto,
    required List<Sucursal> sucursales,
    required Future<void> Function(Producto) onSave,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => ProductoDetalleDialog(
        producto: producto,
        sucursales: sucursales,
        onSave: (Producto productoActualizado) {
          // Solo notificamos que se actualizó el producto sin volver a guardarlo
          onSave(productoActualizado);
        },
      ),
    );
  }

  @override
  State<ProductoDetalleDialog> createState() => _ProductoDetalleDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Producto>('producto', producto))
      ..add(IterableProperty<Sucursal>('sucursales', sucursales))
      ..add(ObjectFlagProperty<Function(Producto)?>.has('onSave', onSave));
  }
}

class _ProductoDetalleDialogState extends State<ProductoDetalleDialog> {
  bool _isLoading = true;
  final List<ProductoEnSucursal> _sucursalesCompartidas =
      <ProductoEnSucursal>[];
  ColorApp? _colorProducto;
  String _error = '';
  bool _isHoveringPhoto = false;

  @override
  void initState() {
    super.initState();
    _cargarDetallesProducto();
    _cargarColores();
  }

  Future<void> _cargarDetallesProducto() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Cargar información del producto en todas las sucursales
      final List<ProductoEnSucursal> sucursalesCompartidas =
          await ProductosUtils.obtenerProductoEnSucursales(
        productoId: widget.producto.id,
        sucursales: widget.sucursales,
      );

      if (mounted) {
        setState(() {
          _sucursalesCompartidas
            ..clear()
            ..addAll(sucursalesCompartidas);
          _isLoading = false;
        });
      }

      debugPrint(
          'ProductoDetalleDialog: Cargados ${sucursalesCompartidas.length} sucursales para el producto ${widget.producto.id}');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              'No se pudieron cargar los detalles del producto: ${e.toString().replaceAll('Exception: ', '')}';
          _isLoading = false;
        });
        debugPrint('Error al cargar detalles del producto: $e');
      }
    }
  }

  Future<void> _cargarColores() async {
    try {
      if (widget.producto.color != null && widget.producto.color!.isNotEmpty) {
        // Buscar el color real en el endpoint
        final colorRepository = ColorRepository.instance;
        final colorEncontrado =
            await colorRepository.getColorPorNombre(widget.producto.color!);

        if (mounted) {
          setState(() {
            _colorProducto = colorEncontrado;
          });
        }
      }
    } catch (e) {
      debugPrint('Error al cargar colores: $e');
    }
  }

  // Método para mostrar la foto en zoom
  void _mostrarFotoEnZoom(BuildContext context) {
    final String? fotoUrl =
        ProductoRepository.getProductoImageUrl(widget.producto);
    debugPrint(
        'ProductoDetalleDialog: _mostrarFotoEnZoom llamado con URL: $fotoUrl');
    if (fotoUrl == null || fotoUrl.isEmpty) {
      debugPrint('ProductoDetalleDialog: URL vacía, no se puede mostrar zoom');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: <Widget>[
            // Fondo oscuro con tap para cerrar
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // Imagen centrada
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                  child: Image.network(
                    fotoUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (BuildContext context, Object error,
                            StackTrace? stackTrace) =>
                        Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.box,
                              color: Colors.white54,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error al cargar imagen',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Botón cerrar
            Positioned(
              top: 40,
              right: 40,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el ancho de la pantalla para responsive
    final double screenWidth = MediaQuery.of(context).size.width;
    // Determinar si es pantalla pequeña (< 800px)
    final bool isPantallaReducida = screenWidth < 800;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1000,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Encabezado común
                _buildHeader(context),
                const SizedBox(height: 16),

                // Información básica del producto (destacada arriba)
                _buildProductoBasicInfo(isPantallaReducida),
                const SizedBox(height: 16),

                // Contenido principal (ocupa todo el ancho)
                Expanded(
                  child: _buildContenidoPrincipal(isPantallaReducida),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        const Expanded(
          child: Text(
            'Detalles del Producto en Sucursales',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white70, size: 26),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // Nuevo método para mostrar solo la información básica del producto
  Widget _buildProductoBasicInfo(bool isPantallaReducida) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.smallRadius)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Imagen del producto o ícono
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(AppTheme.smallRadius),
              ),
              child: (() {
                // Usar la misma lógica que productos_form.dart
                final String? fotoUrl =
                    ProductoRepository.getProductoImageUrl(widget.producto);
                debugPrint(
                    'ProductoDetalleDialog: Foto URL del producto: $fotoUrl');
                if (fotoUrl != null && fotoUrl.isNotEmpty) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                    child: Stack(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              debugPrint(
                                  'ProductoDetalleDialog: Tap en imagen detectado');
                              _mostrarFotoEnZoom(context);
                            },
                            child: MouseRegion(
                              onEnter: (event) =>
                                  setState(() => _isHoveringPhoto = true),
                              onExit: (event) =>
                                  setState(() => _isHoveringPhoto = false),
                              child: Image.network(
                                fotoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const FaIcon(FontAwesomeIcons.box,
                                        size: 32, color: Colors.white24),
                              ),
                            ),
                          ),
                        ),
                        // Indicador de zoom (solo visible al pasar el mouse)
                        if (_isHoveringPhoto)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: AnimatedOpacity(
                              opacity: _isHoveringPhoto ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                } else {
                  return Center(
                    child: FaIcon(
                      FontAwesomeIcons.box,
                      size: 32,
                      color: widget.producto.tieneStockBajo()
                          ? AppTheme.primaryColor.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  );
                }
              })(),
            ),
            const SizedBox(width: 16),
            // Información principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          widget.producto.nombre,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (widget.producto.liquidacion) ...<Widget>[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              FaIcon(
                                FontAwesomeIcons.fireFlameCurved,
                                size: 12,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'EN LIQUIDACIÓN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        _buildTag('SKU: ${widget.producto.sku}',
                            fontFamily: 'monospace'),
                        const SizedBox(width: 8),
                        _buildTag('ID: ${widget.producto.id}'),
                        if (widget.producto.detalleProductoId != null) ...[
                          const SizedBox(width: 8),
                          _buildTag('ID Detalle: ${widget.producto.detalleProductoId}'),
                        ],
                        const SizedBox(width: 8),
                        _buildTag(
                            'Creado: ${widget.producto.fechaCreacion.day}/${widget.producto.fechaCreacion.month}/${widget.producto.fechaCreacion.year}'),
                        const SizedBox(width: 8),
                        _buildTag(widget.producto.categoria),
                        const SizedBox(width: 8),
                        _buildTag(widget.producto.marca),
                        if (widget.producto.color != null &&
                            widget.producto.color!.isNotEmpty) ...<Widget>[
                          const SizedBox(width: 8),
                          _buildColorTag(
                              widget.producto.color!, _colorProducto),
                        ],
                      ],
                    ),
                  ),

                  if (widget.producto.descripcion != null &&
                      widget.producto.descripcion!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      widget.producto.descripcion!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para construir el contenido principal (Precios, descuentos y stock por sucursal integrados)
  Widget _buildContenidoPrincipal(bool isPantallaReducida) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.smallRadius)),
      child: Padding(
        padding: EdgeInsets.all(isPantallaReducida ? 12.0 : 16.0),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: AppTheme.darkSurface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.smallRadius)),
          child: _buildPreciosTab(isPantallaReducida),
        ),
      ),
    );
  }





  // Pestaña de Precios - Quitar la edición de liquidación
  Widget _buildPreciosTab(bool isPantallaReducida) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isPantallaReducida ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Sección de precios
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(AppTheme.smallRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (isPantallaReducida)
                    _buildPreciosWrap()
                  else
                    _buildPreciosRow(),
                ],
              ),
            ),

            // Mostrar sección de promociones en modo solo visualización (exceptuando liquidación que ya se ve arriba)
            if ((widget.producto.cantidadGratisDescuento != null &&
                    widget.producto.cantidadGratisDescuento! > 0) ||
                (widget.producto.cantidadMinimaDescuento != null &&
                    widget.producto.cantidadMinimaDescuento! > 0 &&
                    widget.producto.porcentajeDescuento != null &&
                    widget.producto.porcentajeDescuento! > 0)) ...<Widget>[
              const SizedBox(height: 16),
              _buildPromocionesInfo(),
            ],

            // Divisor
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),

            const SizedBox(height: 12),

            // Lista de precios por sucursal
            _buildPreciosPorSucursal(),
          ],
        ),
      ),
    );
  }

  // Construye la lista de precios por sucursal
  Widget _buildPreciosPorSucursal() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              color: AppTheme.primaryColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar', style: TextStyle(fontSize: 15)),
              onPressed: _cargarDetallesProducto,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Mostramos todas las sucursales disponibles
    final List<ProductoEnSucursal> sucursalesDisponibles =
        _sucursalesCompartidas
            .where((ProductoEnSucursal s) => s.disponible)
            .toList();

    if (sucursalesDisponibles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FaIcon(
              FontAwesomeIcons.store,
              size: 48,
              color: Colors.white24,
            ),
            SizedBox(height: 16),
            Text(
              'Este producto no está disponible en ninguna sucursal.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: sucursalesDisponibles.length,
      separatorBuilder: (BuildContext context, int index) => const Divider(
        color: Colors.white10,
        height: 1,
      ),
      itemBuilder: (BuildContext context, int index) {
        final ProductoEnSucursal sucursalInfo = sucursalesDisponibles[index];
        return _buildPreciosSucursalTile(sucursalInfo);
      },
    );
  }

  // Tile para mostrar precios por sucursal
  Widget _buildPreciosSucursalTile(ProductoEnSucursal sucursalInfo) {
    final Producto producto = sucursalInfo.producto;
    final Sucursal sucursal = sucursalInfo.sucursal;
    final bool esCentral = sucursal.sucursalCentral;
    final bool tieneOferta = producto.estaEnOferta();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Información principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Nombre de sucursal y etiqueta central
                Row(
                  children: <Widget>[
                    // Nombre de sucursal y etiqueta central juntos al lado izquierdo
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              sucursal.nombre,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (esCentral) ...[
                            const SizedBox(width: 8),
                            SucursalUtils.buildTipoSucursalBadge(sucursal),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                     // Stock en la sucursal con color de alerta roja si está agotado, neutro de lo contrario
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: producto.stock <= 0
                            ? Colors.red.shade800.withValues(alpha: 0.15)
                            : Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: producto.stock <= 0
                            ? Border.all(
                                color: Colors.red.shade800.withValues(alpha: 0.3),
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Text(
                            'Stock: ',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${producto.stock}',
                            style: TextStyle(
                              color: producto.stock <= 0
                                  ? Colors.red
                                  : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (producto.stockMinimo != null)
                            Text(
                              '/${producto.stockMinimo}',
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Información de precios, ganancia y margen en la misma línea
                Row(
                  children: <Widget>[
                    // Precio compra
                    _buildPrecioChip(
                      'Compra',
                      producto.getPrecioCompraFormateado(),
                      Colors.blue,
                      FontAwesomeIcons.cartShopping,
                    ),
                    const SizedBox(width: 8),

                    // Precio venta
                    _buildPrecioChip(
                      'Venta',
                      producto.getPrecioVentaFormateado(),
                      Colors.green,
                      FontAwesomeIcons.tag,
                    ),

                    // Precio liquidación (sólo si tiene)
                    if (tieneOferta) ...[
                      const SizedBox(width: 8),
                      _buildPrecioChip(
                        'Liquidación',
                        producto.getPrecioOfertaFormateado() ?? 'N/A',
                        Colors.amber,
                        FontAwesomeIcons.fireFlameCurved,
                      ),
                    ],

                    const SizedBox(width: 24), // Separación elegante

                    // Ganancia
                    Text(
                      'Ganancia: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      ProductosUtils.formatearPrecio(producto.getGanancia()),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Margen
                    Text(
                      'Margen: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      ProductosUtils.formatearPorcentaje(
                          producto.getMargenPorcentaje()),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget para crear una tarjeta con precio
  Widget _buildPrecioChip(
      String label, String precio, Color color, FaIconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FaIcon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.9),
                ),
              ),
              Text(
                precio,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Nueva función para mostrar el resumen de las promociones en la pestaña de precios
  Widget _buildPromocionesInfo() {
    final Producto producto = widget.producto;
    final bool tienePromocionGratis =
        producto.cantidadGratisDescuento != null &&
            producto.cantidadGratisDescuento! > 0;
    final bool tieneDescuentoPorcentual =
        producto.cantidadMinimaDescuento != null &&
            producto.cantidadMinimaDescuento! > 0 &&
            producto.porcentajeDescuento != null &&
            producto.porcentajeDescuento! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (tienePromocionGratis) ...<Widget>[
          _buildResumenPromocion(
              'Promoción: Lleva y Paga',
              'Lleva ${producto.cantidadMinimaDescuento}, paga ${producto.cantidadMinimaDescuento! - producto.cantidadGratisDescuento!}',
              Colors.green,
              FontAwesomeIcons.gift),
        ],

        if (tieneDescuentoPorcentual) ...<Widget>[
          if (tienePromocionGratis) const SizedBox(height: 8),
          _buildResumenPromocion(
              'Descuento por Cantidad',
              '${producto.porcentajeDescuento}% al comprar ${producto.cantidadMinimaDescuento} o más',
              Colors.blue,
              FontAwesomeIcons.percent),
        ],
      ],
    );
  }

  // Método auxiliar para construir el resumen de cada promoción
  Widget _buildResumenPromocion(
      String titulo, String descripcion, Color color, FaIconData icono) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: <Widget>[
          FaIcon(
            icono,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descripcion,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Métodos para la pestaña de precios
  Widget _buildPreciosRow() {
    return Row(
      children: <Widget>[
        Expanded(
            child: _buildAtributo(
                'Precio compra', widget.producto.getPrecioCompraFormateado())),
        Expanded(
            child: _buildAtributo(
                'Precio venta', widget.producto.getPrecioVentaFormateado())),
        if (widget.producto.estaEnOferta())
          Expanded(
              child: _buildAtributo('Precio de liquidación',
                  widget.producto.getPrecioOfertaFormateado() ?? '',
                  color: Colors.amber)),
        Expanded(
            child: _buildAtributo('Ganancia',
                ProductosUtils.formatearPrecio(widget.producto.getGanancia()))),
        Expanded(
            child: _buildAtributo(
                'Margen',
                ProductosUtils.formatearPorcentaje(
                    widget.producto.getMargenPorcentaje()))),
      ],
    );
  }

  Widget _buildPreciosWrap() {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: <Widget>[
          SizedBox(
              width: 150,
              child: _buildAtributo('Precio compra',
                  widget.producto.getPrecioCompraFormateado())),
          SizedBox(
              width: 150,
              child: _buildAtributo(
                  'Precio venta', widget.producto.getPrecioVentaFormateado())),
          if (widget.producto.estaEnOferta())
            SizedBox(
                width: 150,
                child: _buildAtributo('Precio liquidación',
                    widget.producto.getPrecioOfertaFormateado() ?? '',
                    color: Colors.amber)),
          SizedBox(
              width: 150,
              child: _buildAtributo(
                  'Ganancia',
                  ProductosUtils.formatearPrecio(
                      widget.producto.getGanancia()))),
          SizedBox(
              width: 150,
              child: _buildAtributo(
                  'Margen',
                  ProductosUtils.formatearPorcentaje(
                      widget.producto.getMargenPorcentaje()))),
        ],
      ),
    );
  }







  // Widget para crear una etiqueta con valor
  Widget _buildAtributo(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.white,
          ),
        ),
      ],
    );
  }

  // Widget para crear una etiqueta/tag
  Widget _buildTag(String text, {String? fontFamily}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontFamily: fontFamily,
          color: Colors.white70,
        ),
      ),
    );
  }

  // Widget para crear una etiqueta de color con muestra visual
  Widget _buildColorTag(String colorNombre, ColorApp? colorApp) {
    // Determinar el color a mostrar
    Color colorVisual = Colors.grey;

    if (colorApp != null) {
      // Si tenemos el objeto de color, usar su método toColor()
      colorVisual = colorApp.toColor();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Muestra visual del color
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: colorVisual,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Nombre del color
          Text(
            colorNombre,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          // Código hexadecimal (si está disponible)
          if (colorApp?.hex != null && colorApp!.hex!.isNotEmpty) ...<Widget>[
            const SizedBox(width: 4),
            Text(
              colorApp.hex!.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: Colors.white54,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
