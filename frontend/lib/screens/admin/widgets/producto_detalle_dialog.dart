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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

class _ProductoDetalleDialogState extends State<ProductoDetalleDialog> {
  bool _isLoading = true;
  List<ProductoEnSucursal> _sucursalesCompartidas = [];
  String _filtro = 'todas'; // 'todas', 'disponibles', 'stockBajo', 'agotadas'
  String _error = '';

  @override
  void initState() {
    super.initState();
    _cargarDetallesProducto();
  }

  Future<void> _cargarDetallesProducto() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final List<ProductoEnSucursal> sucursales = await ProductosUtils.obtenerProductoEnSucursales(
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

  List<ProductoEnSucursal> get _sucursalesFiltradas {
    switch (_filtro) {
      case 'disponibles':
        return _sucursalesCompartidas.where((s) => s.disponible && s.producto.stock > 0).toList();
      case 'stockBajo':
        return _sucursalesCompartidas.where((s) => s.disponible && s.producto.tieneStockBajo()).toList();
      case 'agotadas':
        return _sucursalesCompartidas.where((s) => s.disponible && s.producto.stock <= 0).toList();
      case 'noDisponible':
        return _sucursalesCompartidas.where((s) => !s.disponible).toList();
      default:
        return _sucursalesCompartidas;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 800,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildProductoInfo(),
            const SizedBox(height: 24),
            _buildFiltros(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildSucursalesLista(),
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
        Text(
          'Detalles del Producto en Sucursales',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildProductoInfo() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      color: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícono del producto (o imagen si disponible)
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.producto.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'SKU: ${widget.producto.sku}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.producto.categoria,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.producto.marca,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.producto.descripcion != null && widget.producto.descripcion!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.producto.descripcion!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            
            // Atributos del producto expandidos
            ExpansionTile(
              initiallyExpanded: true,
              collapsedBackgroundColor: const Color(0xFF222222),
              backgroundColor: const Color(0xFF222222),
              title: const Text(
                'Información Detallada',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildInfoItem('Fecha Creación', _formatDate(widget.producto.fechaCreacion)),
                      _buildInfoItem('ID Producto', widget.producto.id.toString()),
                      if (widget.producto.detalleProductoId != null)
                        _buildInfoItem('ID Detalle', widget.producto.detalleProductoId.toString()),
                      _buildInfoItem('Precio Compra', widget.producto.getPrecioCompraFormateado()),
                      _buildInfoItem('Precio Venta', widget.producto.getPrecioVentaFormateado()),
                      if (widget.producto.precioOferta != null)
                        _buildInfoItem('Precio Oferta', widget.producto.getPrecioOfertaFormateado() ?? ''),
                      _buildInfoItem('Stock Actual', widget.producto.stock.toString(), 
                        color: widget.producto.tieneStockBajo() ? Colors.red : null
                      ),
                      if (widget.producto.stockMinimo != null)
                        _buildInfoItem('Stock Mínimo', widget.producto.stockMinimo.toString()),
                      if (widget.producto.maxDiasSinReabastecer != null)
                        _buildInfoItem('Días sin reabastecer', widget.producto.maxDiasSinReabastecer.toString()),
                      _buildInfoItem('Ganancia', 'S/ ${widget.producto.getGanancia().toStringAsFixed(2)}'),
                      _buildInfoItem('Margen', '${widget.producto.getMargenPorcentaje().toStringAsFixed(2)}%'),
                      if (widget.producto.color != null)
                        _buildInfoItem('Color', widget.producto.color ?? ''),
                      if (widget.producto.cantidadMinimaDescuento != null)
                        _buildInfoItem('Cantidad Min. Descuento', widget.producto.cantidadMinimaDescuento.toString()),
                      if (widget.producto.cantidadGratisDescuento != null)
                        _buildInfoItem('Cantidad Gratis', widget.producto.cantidadGratisDescuento.toString()),
                      if (widget.producto.porcentajeDescuento != null)
                        _buildInfoItem('% Descuento', '${widget.producto.porcentajeDescuento}%'),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            
            // Indicadores de stock y precio con barras de progreso
            ExpansionTile(
              initiallyExpanded: false,
              collapsedBackgroundColor: const Color(0xFF222222),
              backgroundColor: const Color(0xFF222222),
              title: const Text(
                'Indicadores',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Comparación de precio de venta vs compra
                      _buildProgressTitle('Margen de Ganancia', 
                          '${widget.producto.getMargenPorcentaje().toStringAsFixed(2)}%'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _calcularPorcentajeMargen(widget.producto.getMargenPorcentaje()),
                        backgroundColor: Colors.white10,
                        color: _getColorMargen(widget.producto.getMargenPorcentaje()),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Nivel de stock respecto al mínimo
                      _buildProgressTitle('Nivel de Stock', 
                          '${widget.producto.stock} / ${widget.producto.stockMinimo ?? 0}'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _calcularPorcentajeStock(
                          widget.producto.stock, 
                          widget.producto.stockMinimo
                        ),
                        backgroundColor: Colors.white10,
                        color: _getColorStock(
                          widget.producto.stock, 
                          widget.producto.stockMinimo
                        ),
                      ),
                      
                      if (widget.producto.estaEnOferta()) ...[
                        const SizedBox(height: 24),
                        
                        // Descuento activo
                        _buildProgressTitle('Descuento Activo', 
                            widget.producto.getPorcentajeDescuentoOfertaFormateado() ?? ''),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _calcularPorcentajeDescuento(
                            widget.producto.getPorcentajeDescuentoOferta() ?? 0
                          ),
                          backgroundColor: Colors.white10,
                          color: Colors.amber,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            
            // Estadísticas de disponibilidad en sucursales
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildEstadisticaTile(
                  'Sucursales',
                  _isLoading ? '...' : '${_sucursalesCompartidas.length}',
                  icon: FontAwesomeIcons.store,
                  color: Colors.blue,
                ),
                _buildEstadisticaTile(
                  'Con stock',
                  _isLoading
                      ? '...'
                      : '${_sucursalesCompartidas.where((s) => s.disponible && s.producto.stock > 0).length}',
                  icon: FontAwesomeIcons.boxOpen,
                  color: Colors.green,
                ),
                _buildEstadisticaTile(
                  'Stock bajo',
                  _isLoading
                      ? '...'
                      : '${_sucursalesCompartidas.where((s) => s.disponible && s.producto.tieneStockBajo()).length}',
                  icon: FontAwesomeIcons.exclamationTriangle,
                  color: const Color(0xFFE31E24),
                ),
                _buildEstadisticaTile(
                  'Agotado',
                  _isLoading
                      ? '...'
                      : '${_sucursalesCompartidas.where((s) => s.disponible && s.producto.stock <= 0).length}',
                  icon: FontAwesomeIcons.ban,
                  color: Colors.red.shade800,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticaTile(String label, String value, {IconData? icon, Color? color}) {
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

  Widget _buildFiltros() {
    return Row(
      children: [
        const Text(
          'Filtrar por: ',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        _buildFiltroChip('Todas', 'todas'),
        const SizedBox(width: 8),
        _buildFiltroChip('Disponibles', 'disponibles'),
        const SizedBox(width: 8),
        _buildFiltroChip('Stock Bajo', 'stockBajo', color: const Color(0xFFE31E24)),
        const SizedBox(width: 8),
        _buildFiltroChip('Agotadas', 'agotadas', color: Colors.red.shade800),
        const SizedBox(width: 8),
        _buildFiltroChip('No Disponible', 'noDisponible', color: Colors.grey),
      ],
    );
  }

  Widget _buildFiltroChip(String label, String value, {Color? color}) {
    final isSelected = _filtro == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtro = value;
        });
      },
      backgroundColor: const Color(0xFF2D2D2D),
      selectedColor: color ?? const Color(0xFFE31E24),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? (color ?? const Color(0xFFE31E24)) : Colors.white24,
          width: 1,
        ),
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
              label: const Text('Reintentar'),
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

    if (_sucursalesFiltradas.isEmpty) {
      String mensaje = 'No hay sucursales que coincidan con el filtro seleccionado.';
      if (_filtro == 'todas' && _sucursalesCompartidas.isEmpty) {
        mensaje = 'Este producto no está disponible en ninguna sucursal.';
      } else if (_filtro == 'disponibles') {
        mensaje = 'Este producto no está disponible en ninguna sucursal con stock.';
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

    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _sucursalesFiltradas.length,
        separatorBuilder: (context, index) => const Divider(
          color: Colors.white10,
          height: 1,
        ),
        itemBuilder: (context, index) {
          final sucursalInfo = _sucursalesFiltradas[index];
          return _buildSucursalTile(sucursalInfo);
        },
      ),
    );
  }

  Widget _buildSucursalTile(ProductoEnSucursal sucursalInfo) {
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 8,
        height: double.infinity,
        decoration: BoxDecoration(
          color: indicadorColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              sucursal.nombre,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (esCentral)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.blue,
                  width: 1,
                ),
              ),
              child: const Text(
                'CENTRAL',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            sucursal.direccion ?? 'Sin dirección',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: indicadorColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: indicadorColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      statusIcon,
                      size: 12,
                      color: indicadorColor,
                    ),
                    const SizedBox(width: 4),
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
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Stock: ',
                        style: TextStyle(
                          color: Colors.white70,
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
                      if (producto.stockMinimo != null) ...[
                        Text(
                          ' / Min: ${producto.stockMinimo}',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Precio: ',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        producto.getPrecioVentaFormateado(),
                        style: TextStyle(
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
      trailing: disponible ? const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white54,
        size: 16,
      ) : null,
      onTap: disponible ? () {
        // TODO: Permitir ir a la página específica del producto en esa sucursal
      } : null,
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          child: const Text(
            'Cerrar',
            style: TextStyle(color: Colors.white70),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
  
  Widget _buildInfoItem(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressTitle(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
  
  double _calcularPorcentajeMargen(double margen) {
    // Consideramos margen bueno entre 20-50%
    if (margen <= 0) return 0.05;
    if (margen > 100) return 1.0;
    return margen / 100;
  }
  
  Color _getColorMargen(double margen) {
    if (margen < 10) return Colors.red;
    if (margen < 20) return Colors.orange;
    if (margen < 35) return Colors.green;
    if (margen < 50) return Colors.lightGreen;
    return Colors.amber; // Márgenes muy altos podrían no ser creíbles
  }
  
  double _calcularPorcentajeStock(int stock, int? stockMinimo) {
    final minimo = stockMinimo ?? 0;
    if (minimo <= 0) return stock > 0 ? 1.0 : 0.0;
    
    // Considerar hasta 5 veces el stock mínimo como el máximo
    final ratio = stock / (minimo * 2);
    if (ratio > 1) return 1.0;
    if (ratio < 0) return 0.0;
    return ratio;
  }
  
  Color _getColorStock(int stock, int? stockMinimo) {
    final minimo = stockMinimo ?? 0;
    if (minimo <= 0) return stock > 0 ? Colors.green : Colors.red;
    
    if (stock <= 0) return Colors.red.shade800;  // Agotado
    if (stock < minimo) return Colors.red;       // Bajo stock
    if (stock < minimo * 1.5) return Colors.orange; // Alerta
    if (stock < minimo * 3) return Colors.green; // Bueno
    return Colors.lightGreen;                   // Muy bueno
  }
  
  double _calcularPorcentajeDescuento(double descuento) {
    if (descuento <= 0) return 0.05;
    if (descuento > 100) return 1.0;
    return descuento / 100;
  }
} 