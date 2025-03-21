import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/producto.model.dart';
import '../../../models/sucursal.model.dart';
import 'productos_utils.dart';

class ProductoDetalleDialog extends StatefulWidget {
  final Producto producto;
  final List<Sucursal> sucursales;

  const ProductoDetalleDialog({
    super.key,
    required this.producto,
    required this.sucursales,
  });

  static Future<void> show({
    required BuildContext context,
    required Producto producto,
    required List<Sucursal> sucursales,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF222222),
          child: ProductoDetalleDialog(
            producto: producto,
            sucursales: sucursales,
          ),
        );
      },
    );
  }

  @override
  State<ProductoDetalleDialog> createState() => _ProductoDetalleDialogState();
}

class _ProductoDetalleDialogState extends State<ProductoDetalleDialog>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  List<ProductoEnSucursal> _sucursalesCompartidas = [];
  String _filtro =
      'todas'; // 'todas', 'disponibles', 'stockBajo', 'agotadas', 'noDisponible'
  String _error = '';

  // Controlador para pestañas
  late TabController _atributosTabController;

  @override
  void initState() {
    super.initState();
    _cargarDetallesProducto();

    // Inicializar controlador de pestañas
    _atributosTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _atributosTabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDetallesProducto() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final List<ProductoEnSucursal> sucursales =
          await ProductosUtils.obtenerProductoEnSucursales(
        productoId: widget.producto.id,
        sucursales: widget.sucursales,
      );

      setState(() {
        _sucursalesCompartidas = sucursales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los detalles del producto: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el ancho de la pantalla para responsive
    final screenWidth = MediaQuery.of(context).size.width;
    // Determinar si es pantalla pequeña (< 800px)
    final isPantallaReducida = screenWidth < 800;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 900,
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            // Información básica del producto
            _buildProductoBasicInfo(isPantallaReducida),
            const SizedBox(height: 16),
            // Ambas pestañas juntas (atributos y filtros) con su contenido
            Expanded(
              child: _buildTabBars(isPantallaReducida),
            ),
            const SizedBox(height: 16),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Detalles del Producto en Sucursales',
            style: const TextStyle(
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
      elevation: 4,
      margin: EdgeInsets.zero,
      color: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono del producto
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.box,
                  size: 32,
                  color: widget.producto.tieneStockBajo()
                      ? const Color(0xFFE31E24).withOpacity(0.7)
                      : Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Información principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.producto.nombre,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTag('SKU: ${widget.producto.sku}',
                            fontFamily: 'monospace'),
                        const SizedBox(width: 8),
                        _buildTag(widget.producto.categoria),
                        const SizedBox(width: 8),
                        _buildTag(widget.producto.marca),
                        if (widget.producto.color != null &&
                            widget.producto.color!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _buildTag('Color: ${widget.producto.color}'),
                        ],
                      ],
                    ),
                  ),
                  if (widget.producto.descripcion != null &&
                      widget.producto.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 8),
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

  // Nuevo método para combinar ambas barras de pestañas
  Widget _buildTabBars(bool isPantallaReducida) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      color: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección de estadísticas compacta
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCompactEstadistica(
                  'Sucursales',
                  _isLoading ? '...' : '${_sucursalesCompartidas.length}',
                  icon: FontAwesomeIcons.store,
                  color: Colors.blue,
                  isSmall: isPantallaReducida,
                ),
                _buildCompactEstadistica(
                  'Con stock',
                  _isLoading
                      ? '...'
                      : '${_sucursalesCompartidas.where((s) => s.disponible && s.producto.stock > 0).length}',
                  icon: FontAwesomeIcons.boxOpen,
                  color: Colors.green,
                  isSmall: isPantallaReducida,
                ),
                _buildCompactEstadistica(
                  'Stock bajo',
                  _isLoading
                      ? '...'
                      : '${_sucursalesCompartidas.where((s) => s.disponible && s.producto.tieneStockBajo()).length}',
                  icon: FontAwesomeIcons.exclamationTriangle,
                  color: const Color(0xFFE31E24),
                  isSmall: isPantallaReducida,
                ),
                _buildCompactEstadistica(
                  'Agotado',
                  _isLoading
                      ? '...'
                      : '${_sucursalesCompartidas.where((s) => s.disponible && s.producto.stock <= 0).length}',
                  icon: FontAwesomeIcons.ban,
                  color: Colors.red.shade800,
                  isSmall: isPantallaReducida,
                ),
              ],
            ),
          ),

          // Contenedor para todas las pestañas
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isPantallaReducida ? 12.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pestañas superiores: Atributos y Filtros
                  Row(
                    children: [
                      // Pestañas de atributos
                      Expanded(
                        flex: isPantallaReducida ? 3 : 2,
                        child: Container(
                          height: isPantallaReducida ? 40 : 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white10, width: 1),
                          ),
                          child: TabBar(
                            controller: _atributosTabController,
                            isScrollable: true,
                            indicatorColor: const Color(0xFFE31E24),
                            indicatorSize: TabBarIndicatorSize.label,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white70,
                            padding: EdgeInsets.symmetric(
                                horizontal: isPantallaReducida ? 4 : 8),
                            labelPadding: EdgeInsets.symmetric(
                                horizontal: isPantallaReducida ? 8 : 12),
                            tabs: [
                              Tab(
                                height: isPantallaReducida ? 34 : 40,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FaIcon(FontAwesomeIcons.moneyBillWave,
                                        size: isPantallaReducida ? 14 : 16,
                                        color: Colors.green.shade700),
                                    SizedBox(width: isPantallaReducida ? 4 : 8),
                                    const Text('Precios',
                                        style: TextStyle(fontSize: 15)),
                                  ],
                                ),
                              ),
                              Tab(
                                height: isPantallaReducida ? 34 : 40,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FaIcon(FontAwesomeIcons.boxOpen,
                                        size: isPantallaReducida ? 14 : 16,
                                        color: const Color(0xFFE31E24)),
                                    SizedBox(width: isPantallaReducida ? 4 : 8),
                                    const Text('Stock',
                                        style: TextStyle(fontSize: 15)),
                                  ],
                                ),
                              ),
                              Tab(
                                height: isPantallaReducida ? 34 : 40,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FaIcon(FontAwesomeIcons.circleInfo,
                                        size: isPantallaReducida ? 14 : 16,
                                        color: Colors.blue),
                                    SizedBox(width: isPantallaReducida ? 4 : 8),
                                    const Text('Detalles',
                                        style: TextStyle(fontSize: 15)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Área para mostrar el contenido combinado de las pestañas
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Card(
                        margin: EdgeInsets.zero,
                        color: const Color(0xFF1A1A1A),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: TabBarView(
                          controller: _atributosTabController,
                          children: [
                            // Pestaña de Precios (ahora con descuentos integrados)
                            Padding(
                              padding: EdgeInsets.all(
                                  isPantallaReducida ? 12.0 : 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Sección de precios
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Información de Precios',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        isPantallaReducida
                                            ? _buildPreciosWrap()
                                            : _buildPreciosRow(),
                                      ],
                                    ),
                                  ),

                                  // Sección de descuentos (si aplica)
                                  if (widget.producto.cantidadMinimaDescuento != null ||
                                      widget.producto.cantidadGratisDescuento !=
                                          null ||
                                      widget.producto.porcentajeDescuento !=
                                          null ||
                                      widget.producto.estaEnOferta()) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color:
                                                Colors.amber.withOpacity(0.3),
                                            width: 1),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              FaIcon(
                                                FontAwesomeIcons.tags,
                                                size: 16,
                                                color: Colors.amber,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Descuentos y Promociones',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.amber,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          isPantallaReducida
                                              ? _buildDescuentosWrap()
                                              : _buildDescuentosRow(),
                                        ],
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),

                            // Pestaña de Stock (con lista de sucursales integrada)
                            _buildStockConSucursales(isPantallaReducida),

                            // Pestaña de Información Adicional
                            Padding(
                              padding: EdgeInsets.all(
                                  isPantallaReducida ? 12.0 : 16.0),
                              child: isPantallaReducida
                                  ? _buildInfoAdicionalWrap()
                                  : _buildInfoAdicionalRow(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Estadística en formato compacto
  Widget _buildCompactEstadistica(String label, String valor,
      {required IconData icon, required Color color, bool isSmall = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            size: isSmall ? 12 : 14,
            color: color,
          ),
          SizedBox(width: isSmall ? 4 : 6),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: isSmall ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: isSmall ? 3 : 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: isSmall ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          child: const Text(
            'Cerrar',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // Métodos para la pestaña de precios
  Widget _buildPreciosRow() {
    return Row(
      children: [
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
        children: [
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
                child: _buildAtributo('Precio oferta',
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

  // Métodos para la pestaña de stock
  Widget _buildStockRow() {
    return Row(
      children: [
        Expanded(
            child: _buildAtributo('Stock actual', '${widget.producto.stock}',
                color: widget.producto.tieneStockBajo()
                    ? const Color(0xFFE31E24)
                    : null)),
        Expanded(
            child: _buildAtributo('Stock mínimo',
                '${widget.producto.stockMinimo ?? "No definido"}')),
        Expanded(
            child: _buildAtributo(
                'Estado',
                widget.producto.tieneStockBajo()
                    ? 'Stock bajo'
                    : (widget.producto.stock <= 0 ? 'Agotado' : 'Disponible'),
                color: widget.producto.tieneStockBajo()
                    ? const Color(0xFFE31E24)
                    : (widget.producto.stock <= 0
                        ? Colors.red
                        : Colors.green))),
        if (widget.producto.maxDiasSinReabastecer != null)
          Expanded(
              child: _buildAtributo('Días sin reabastecer',
                  '${widget.producto.maxDiasSinReabastecer}')),
      ],
    );
  }

  Widget _buildStockWrap() {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          SizedBox(
              width: 150,
              child: _buildAtributo('Stock actual', '${widget.producto.stock}',
                  color: widget.producto.tieneStockBajo()
                      ? const Color(0xFFE31E24)
                      : null)),
          SizedBox(
              width: 150,
              child: _buildAtributo('Stock mínimo',
                  '${widget.producto.stockMinimo ?? "No definido"}')),
          SizedBox(
              width: 150,
              child: _buildAtributo(
                  'Estado',
                  widget.producto.tieneStockBajo()
                      ? 'Stock bajo'
                      : (widget.producto.stock <= 0 ? 'Agotado' : 'Disponible'),
                  color: widget.producto.tieneStockBajo()
                      ? const Color(0xFFE31E24)
                      : (widget.producto.stock <= 0
                          ? Colors.red
                          : Colors.green))),
          if (widget.producto.maxDiasSinReabastecer != null)
            SizedBox(
                width: 150,
                child: _buildAtributo('Días sin reabastecer',
                    '${widget.producto.maxDiasSinReabastecer}')),
        ],
      ),
    );
  }

  // Métodos para la pestaña de descuentos
  Widget _buildDescuentosRow() {
    return Row(
      children: [
        if (widget.producto.cantidadMinimaDescuento != null)
          Expanded(
              child: _buildAtributo('Cant. mín. descuento',
                  '${widget.producto.cantidadMinimaDescuento}')),
        if (widget.producto.cantidadGratisDescuento != null)
          Expanded(
              child: _buildAtributo('Cant. gratis',
                  '${widget.producto.cantidadGratisDescuento}')),
        if (widget.producto.porcentajeDescuento != null)
          Expanded(
              child: _buildAtributo(
                  '% descuento', '${widget.producto.porcentajeDescuento}%')),
        if (widget.producto.estaEnOferta())
          Expanded(
              child: _buildAtributo(
                  'Descuento oferta',
                  widget.producto.getPorcentajeDescuentoOfertaFormateado() ??
                      '',
                  color: Colors.amber)),
        // Expandir para llenar espacio si hay pocos elementos
        if ((widget.producto.cantidadMinimaDescuento != null ? 1 : 0) +
                (widget.producto.cantidadGratisDescuento != null ? 1 : 0) +
                (widget.producto.porcentajeDescuento != null ? 1 : 0) +
                (widget.producto.estaEnOferta() ? 1 : 0) <
            4)
          Expanded(child: Container()),
      ],
    );
  }

  Widget _buildDescuentosWrap() {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          if (widget.producto.cantidadMinimaDescuento != null)
            SizedBox(
                width: 150,
                child: _buildAtributo('Cant. mín. descuento',
                    '${widget.producto.cantidadMinimaDescuento}')),
          if (widget.producto.cantidadGratisDescuento != null)
            SizedBox(
                width: 150,
                child: _buildAtributo('Cant. gratis',
                    '${widget.producto.cantidadGratisDescuento}')),
          if (widget.producto.porcentajeDescuento != null)
            SizedBox(
                width: 150,
                child: _buildAtributo(
                    '% descuento', '${widget.producto.porcentajeDescuento}%')),
          if (widget.producto.estaEnOferta())
            SizedBox(
                width: 150,
                child: _buildAtributo(
                    'Descuento oferta',
                    widget.producto.getPorcentajeDescuentoOfertaFormateado() ??
                        '',
                    color: Colors.amber)),
        ],
      ),
    );
  }

  // Métodos para la pestaña de información adicional
  Widget _buildInfoAdicionalRow() {
    return Row(
      children: [
        Expanded(child: _buildAtributo('ID', '${widget.producto.id}')),
        if (widget.producto.detalleProductoId != null)
          Expanded(
              child: _buildAtributo(
                  'ID Detalle', '${widget.producto.detalleProductoId}')),
        Expanded(
            child: _buildAtributo('Fecha creación',
                '${widget.producto.fechaCreacion.day}/${widget.producto.fechaCreacion.month}/${widget.producto.fechaCreacion.year}')),
        // Expandir para llenar espacio
        Expanded(child: Container()),
      ],
    );
  }

  Widget _buildInfoAdicionalWrap() {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          SizedBox(
              width: 150, child: _buildAtributo('ID', '${widget.producto.id}')),
          if (widget.producto.detalleProductoId != null)
            SizedBox(
                width: 150,
                child: _buildAtributo(
                    'ID Detalle', '${widget.producto.detalleProductoId}')),
          SizedBox(
              width: 150,
              child: _buildAtributo('Fecha creación',
                  '${widget.producto.fechaCreacion.day}/${widget.producto.fechaCreacion.month}/${widget.producto.fechaCreacion.year}')),
        ],
      ),
    );
  }

  // Widget para crear una etiqueta con valor
  Widget _buildAtributo(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
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

  // Widget para crear un título de sección
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white.withOpacity(0.9),
      ),
    );
  }

  // Widget para crear una etiqueta/tag
  Widget _buildTag(String text, {String? fontFamily}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
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

  Widget _buildEstadisticaTile(String label, String value,
      {IconData? icon, Color? color}) {
    return Expanded(
      child: Column(
        children: [
          if (icon != null) ...[
            FaIcon(
              icon,
              size: 16,
              color: color ?? Colors.white70,
            ),
            const SizedBox(height: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
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
      ),
    );
  }

  // Método para combinar la información de stock del producto con el listado de sucursales
  Widget _buildStockConSucursales(bool isPantallaReducida) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Información básica de stock del producto
        Padding(
          padding: EdgeInsets.all(isPantallaReducida ? 12.0 : 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información de Stock',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                isPantallaReducida ? _buildStockWrap() : _buildStockRow(),
              ],
            ),
          ),
        ),

        // Divisor
        const Divider(color: Colors.white24, height: 1),

        // Título de sección
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Stock por Sucursal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              // Selector de filtros (desplegable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filtro,
                    icon: const Icon(Icons.filter_list,
                        color: Colors.white54, size: 16),
                    dropdownColor: const Color(0xFF2D2D2D),
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _filtro = newValue;
                        });
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'todas',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(FontAwesomeIcons.layerGroup,
                                size: 12, color: Colors.white),
                            const SizedBox(width: 6),
                            Text('Todas (${_sucursalesCompartidas.length})'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'disponibles',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(FontAwesomeIcons.boxOpen,
                                size: 12, color: Colors.green),
                            const SizedBox(width: 6),
                            Text(
                                'Disponibles (${_sucursalesCompartidas.where((s) => s.disponible && s.producto.stock > 0).length})'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'stockBajo',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(FontAwesomeIcons.exclamationTriangle,
                                size: 12, color: Color(0xFFE31E24)),
                            const SizedBox(width: 6),
                            Text(
                                'Stock Bajo (${_sucursalesCompartidas.where((s) => s.disponible && s.producto.tieneStockBajo()).length})'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'agotadas',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(FontAwesomeIcons.ban,
                                size: 12, color: Colors.red.shade800),
                            const SizedBox(width: 6),
                            Text(
                                'Agotadas (${_sucursalesCompartidas.where((s) => s.disponible && s.producto.stock <= 0).length})'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'noDisponible',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(FontAwesomeIcons.ghost,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                                'No Disponible (${_sucursalesCompartidas.where((s) => !s.disponible).length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Lista de sucursales filtradas
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildSucursalesLista(),
          ),
        ),
      ],
    );
  }

  Widget _buildSucursalesLista() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFE31E24),
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
                backgroundColor: const Color(0xFFE31E24),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Aplicar el filtro directo en lugar de utilizar _sucursalesFiltradas
    List<ProductoEnSucursal> sucursalesFiltradas;

    // Aplicar el filtro específico
    switch (_filtro) {
      case 'disponibles':
        sucursalesFiltradas = _sucursalesCompartidas
            .where((s) => s.disponible && s.producto.stock > 0)
            .toList();
        break;
      case 'stockBajo':
        sucursalesFiltradas = _sucursalesCompartidas
            .where((s) => s.disponible && s.producto.tieneStockBajo())
            .toList();
        break;
      case 'agotadas':
        sucursalesFiltradas = _sucursalesCompartidas
            .where((s) => s.disponible && s.producto.stock <= 0)
            .toList();
        break;
      case 'noDisponible':
        sucursalesFiltradas =
            _sucursalesCompartidas.where((s) => !s.disponible).toList();
        break;
      default: // 'todas'
        sucursalesFiltradas = _sucursalesCompartidas;
        break;
    }

    if (sucursalesFiltradas.isEmpty) {
      String mensaje =
          'No hay sucursales que coincidan con el filtro seleccionado.';
      if (_filtro == 'todas' && _sucursalesCompartidas.isEmpty) {
        mensaje = 'Este producto no está disponible en ninguna sucursal.';
      } else if (_filtro == 'disponibles') {
        mensaje =
            'Este producto no está disponible en ninguna sucursal con stock.';
      } else if (_filtro == 'stockBajo') {
        mensaje = 'No hay sucursales con stock bajo para este producto.';
      } else if (_filtro == 'agotadas') {
        mensaje = 'No hay sucursales con stock agotado para este producto.';
      } else if (_filtro == 'noDisponible') {
        mensaje = 'Este producto está disponible en todas las sucursales.';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.store,
              size: 48,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              style: const TextStyle(
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: sucursalesFiltradas.length,
      separatorBuilder: (context, index) => const Divider(
        color: Colors.white10,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final sucursalInfo = sucursalesFiltradas[index];
        return _buildCompactSucursalTile(sucursalInfo);
      },
    );
  }

  // Versión compacta del tile de sucursal
  Widget _buildCompactSucursalTile(ProductoEnSucursal sucursalInfo) {
    final disponible = sucursalInfo.disponible;
    final producto = sucursalInfo.producto;
    final sucursal = sucursalInfo.sucursal;

    final stockBajo = disponible && producto.tieneStockBajo();
    final agotado = disponible && producto.stock <= 0;
    final esCentral = sucursal.sucursalCentral;

    Color indicadorColor = Colors.green;
    IconData statusIcon = FontAwesomeIcons.check;
    String statusText = 'Disponible';

    if (!disponible) {
      indicadorColor = Colors.grey;
      statusIcon = FontAwesomeIcons.ban;
      statusText = 'No disponible';
    } else if (agotado) {
      indicadorColor = Colors.red.shade800;
      statusIcon = FontAwesomeIcons.ban;
      statusText = 'Agotado';
    } else if (stockBajo) {
      indicadorColor = const Color(0xFFE31E24);
      statusIcon = FontAwesomeIcons.exclamationTriangle;
      statusText = 'Stock bajo';
    }

    // Versión compacta del tile
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Indicador de estado (barra vertical)
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: indicadorColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // Información principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre de sucursal y etiqueta central
                Row(
                  children: [
                    Expanded(
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
                    if (esCentral)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: Colors.blue,
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'CENTRAL',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),

                // Dirección en formato compacto
                Text(
                  sucursal.direccion ?? 'Sin dirección',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Etiquetas de información en una sola fila
                Row(
                  children: [
                    // Estado (Disponible, Stock bajo, etc.)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: indicadorColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: indicadorColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            statusIcon,
                            size: 10,
                            color: indicadorColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: indicadorColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (disponible) ...[
                      const SizedBox(width: 8),

                      // Stock
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Stock: ',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${producto.stock}',
                              style: TextStyle(
                                color: indicadorColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (producto.stockMinimo != null)
                              Text(
                                '/${producto.stockMinimo}',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Precio
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              producto.getPrecioVentaFormateado(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Flecha de navegación
          if (disponible)
            const Icon(
              Icons.chevron_right,
              color: Colors.white38,
              size: 18,
            ),
        ],
      ),
    );
  }
}
