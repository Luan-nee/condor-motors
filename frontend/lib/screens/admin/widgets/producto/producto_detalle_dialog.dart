import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../main.dart' show api;
import '../../../../models/color.model.dart';
import '../../../../models/producto.model.dart';
import '../../../../models/sucursal.model.dart';
import '../../utils/productos_utils.dart';

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
    Function(Producto)? onSave,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF222222),
          child: ProductoDetalleDialog(
            producto: producto,
            sucursales: sucursales,
            onSave: onSave,
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
  List<ColorApp> _colores = [];
  ColorApp? _colorProducto;
  String _error = '';

  // Controlador para pestañas
  late TabController _atributosTabController;

  bool _isEditingPrecio = false;
  TextEditingController _precioOfertaController = TextEditingController();
  bool _liquidacionModificada = false;
  bool _enLiquidacion = false;

  @override
  void initState() {
    super.initState();
    _cargarDetallesProducto();
    _cargarColores();

    // Inicializar estado de liquidación
    _enLiquidacion = widget.producto.liquidacion;
    _precioOfertaController.text = widget.producto.precioOferta?.toString() ?? '';
    
    // Inicializar controlador de pestañas
    _atributosTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _atributosTabController.dispose();
    _precioOfertaController.dispose();
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

  Future<void> _cargarColores() async {

    try {
      final colores = await api.colores.getColores();

      if (mounted) {
        setState(() {
          _colores = colores;

          // Si el producto tiene color, buscar la coincidencia en la lista
          if (widget.producto.color != null && widget.producto.color!.isNotEmpty) {
            try {
              _colorProducto = _colores.firstWhere(
                (color) => color.nombre.toLowerCase() == widget.producto.color!.toLowerCase(),
              );
            } catch (e) {
              // No se encontró coincidencia, _colorProducto queda como null
              _colorProducto = null;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error al cargar colores: $e');

      if (mounted) {
      }
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
                  Row(
                    children: [
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
                      if (widget.producto.liquidacion) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(
                                FontAwesomeIcons.tag,
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
                          _buildColorTag(widget.producto.color!, _colorProducto),
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
                  icon: FontAwesomeIcons.triangleExclamation,
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
                            border: Border.all(color: Colors.white10),
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
                            // Pestaña de Precios (ahora con descuentos y precios por sucursal)
                            _buildPreciosTab(isPantallaReducida),

                            // Pestaña de Stock (con lista de sucursales integrada)
                            _buildStockConSucursales(isPantallaReducida),

                            // Pestaña de Información Adicional
                            Container(
                              padding: EdgeInsets.all(
                                  isPantallaReducida ? 12.0 : 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Información Adicional',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: isPantallaReducida
                                          ? _buildInfoAdicionalWrap()
                                          : _buildInfoAdicionalRow(),
                                    ),
                                  ),
                                ],
                              ),
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
        border: Border.all(color: color.withOpacity(0.3)),
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

  // Pestaña de Precios (ahora con descuentos integrados)
  Widget _buildPreciosTab(bool isPantallaReducida) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isPantallaReducida ? 12.0 : 16.0),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información de Precios',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  isPantallaReducida ? _buildPreciosWrap() : _buildPreciosRow(),
                ],
              ),
            ),

            // Sección de liquidación
            if (widget.onSave != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _enLiquidacion 
                    ? Colors.amber.withOpacity(0.08) 
                    : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _enLiquidacion 
                      ? Colors.amber.withOpacity(0.3) 
                      : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.tag,
                              size: 16,
                              color: _enLiquidacion ? Colors.amber : Colors.white60,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Liquidación',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _enLiquidacion ? Colors.amber : Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _enLiquidacion,
                          onChanged: (value) {
                            setState(() {
                              _enLiquidacion = value;
                              _liquidacionModificada = true;
                              if (!value) {
                                _precioOfertaController.text = '';
                              }
                            });
                          },
                          activeColor: Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_enLiquidacion) ...[
                      _isEditingPrecio 
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _precioOfertaController,
                              decoration: InputDecoration(
                                labelText: 'Precio de liquidación',
                                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                prefixText: 'S/ ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF2D2D2D),
                              ),
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditingPrecio = false;
                                      _precioOfertaController.text = widget.producto.precioOferta?.toString() ?? '';
                                    });
                                  },
                                  child: const Text('Cancelar'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditingPrecio = false;
                                      _liquidacionModificada = true;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text('Guardar'),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Precio de venta:',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.producto.getPrecioVentaFormateado(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.lineThrough,
                                          decorationColor: Colors.red.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Precio de liquidación:',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            _precioOfertaController.text.isNotEmpty
                                              ? 'S/ ${double.parse(_precioOfertaController.text).toStringAsFixed(2)}'
                                              : widget.producto.getPrecioOfertaFormateado() ?? 'No definido',
                                            style: const TextStyle(
                                              color: Colors.amber,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 16, color: Colors.amber),
                                            onPressed: () {
                                              setState(() {
                                                _isEditingPrecio = true;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Mostrar descuento
                            if (widget.producto.precioOferta != null && widget.producto.precioOferta! > 0) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Ahorro:',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'S/ ${(widget.producto.precioVenta - (widget.producto.precioOferta ?? 0)).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${widget.producto.getPorcentajeDescuentoOfertaFormateado()} descuento',
                                        style: const TextStyle(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      
                      if (_liquidacionModificada && widget.onSave != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _guardarLiquidacion,
                              icon: const FaIcon(FontAwesomeIcons.floppyDisk, size: 16),
                              label: const Text('Guardar Cambios'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ] else ...[
                      Text(
                        'Active esta opción para establecer un precio especial de liquidación. '
                        'El producto se mostrará como "En liquidación" en todas las vistas.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      if (_liquidacionModificada && widget.onSave != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _guardarLiquidacion,
                              icon: const FaIcon(FontAwesomeIcons.floppyDisk, size: 16),
                              label: const Text('Guardar Cambios'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],

            // Sección de descuentos (si aplica)
            if (widget.producto.cantidadMinimaDescuento != null ||
                widget.producto.cantidadGratisDescuento != null ||
                widget.producto.porcentajeDescuento != null ||
                widget.producto.estaEnOferta()) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
            ],

            // Nueva sección: Precios por sucursal
            if (_sucursalesCompartidas.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.store,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Precios por local',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPreciosPorSucursal(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Nuevo widget para mostrar precios por sucursal
  Widget _buildPreciosPorSucursal() {
    final sucursalesDisponibles =
        _sucursalesCompartidas.where((s) => s.disponible).toList();

    if (sucursalesDisponibles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'No hay información de precios disponible en sucursales',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Encabezado
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Local',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Precio de venta',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Precio de liquidación',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        // Divisor
        Divider(color: Colors.white24, height: 1),

        // Lista de sucursales con precios
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: sucursalesDisponibles.length,
          itemBuilder: (context, index) {
            final item = sucursalesDisponibles[index];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white10,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Nombre de la sucursal
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        FaIcon(
                          item.sucursal.sucursalCentral
                              ? FontAwesomeIcons.building
                              : FontAwesomeIcons.store,
                          size: 12,
                          color: item.sucursal.sucursalCentral
                              ? Colors.blue
                              : Colors.white54,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            item.sucursal.nombre,
                            style: TextStyle(
                              color: item.sucursal.sucursalCentral
                                  ? Colors.blue
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: item.sucursal.sucursalCentral
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Precio de venta
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.producto.getPrecioVentaFormateado(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Precio de oferta
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.producto.estaEnOferta()
                          ? item.producto.getPrecioOfertaFormateado() ?? '-'
                          : '-',
                      style: TextStyle(
                        color: item.producto.estaEnOferta()
                            ? Colors.amber
                            : Colors.white54,
                        fontSize: 14,
                        fontWeight: item.producto.estaEnOferta()
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
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

  // Método para mostrar la pestaña de Stock con sucursales
  Widget _buildStockConSucursales(bool isPantallaReducida) {
    return SingleChildScrollView(
      child: Column(
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
              padding: const EdgeInsets.all(16.0),
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
                  const SizedBox(height: 16),
                  // Cambiamos a formato similar a precios (en 4 columnas o wrap)
                  isPantallaReducida ? _buildStockWrap() : _buildStockRow(),
                ],
              ),
            ),
          ),

          // Divisor
          const Divider(color: Colors.white24, height: 1),

          // Título de sección con filtros
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
              ],
            ),
          ),

          // Lista de sucursales filtradas (sin Expanded para permitir scroll)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildSucursalesLista(),
          ),
        ],
      ),
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

    // Ya no usamos filtrado, mostramos todas las sucursales disponibles
    final sucursalesDisponibles =
        _sucursalesCompartidas.where((s) => s.disponible).toList();

    if (sucursalesDisponibles.isEmpty) {
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
              'Este producto no está disponible en ninguna sucursal.',
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
      itemCount: sucursalesDisponibles.length,
      separatorBuilder: (context, index) => const Divider(
        color: Colors.white10,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final sucursalInfo = sucursalesDisponibles[index];
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
      statusIcon = FontAwesomeIcons.triangleExclamation;
      statusText = 'Stock bajo';
    }

    // Versión compacta del tile
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
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
                  sucursal.direccion,
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
              child: _buildAtributo('Días Antes de Liquidación',
                  '${widget.producto.maxDiasSinReabastecer}')),
        // Si no hay "Días sin reabastecer", añadir un contenedor vacío
        if (widget.producto.maxDiasSinReabastecer == null)
          Expanded(child: Container()),
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
              width: 150,
              child:
                  _buildAtributo('ID del producto', '${widget.producto.id}')),
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
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Muestra visual del color
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: colorVisual,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
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
          if (colorApp?.hex != null && colorApp!.hex!.isNotEmpty) ...[
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

  // Método para guardar los cambios en la liquidación
  void _guardarLiquidacion() {
    if (widget.onSave == null) return;
    
    try {
      double? precioOferta;
      if (_enLiquidacion && _precioOfertaController.text.isNotEmpty) {
        precioOferta = double.tryParse(_precioOfertaController.text);
        if (precioOferta == null || precioOferta <= 0 || precioOferta >= widget.producto.precioVenta) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El precio de liquidación debe ser mayor a 0 y menor al precio de venta'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      
      // Crear copia del producto con los valores modificados
      final productoActualizado = widget.producto.copyWith(
        liquidacion: _enLiquidacion,
        precioOferta: _enLiquidacion ? precioOferta : null,
      );
      
      // Llamar al callback onSave
      widget.onSave!(productoActualizado);
      
      setState(() {
        _liquidacionModificada = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cambios guardados correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar cambios: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
