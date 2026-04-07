import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:condorsmotors/repositories/stock.repository.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_detalles_dialog.dart';
import 'package:condorsmotors/utils/stock_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StockDetalleSucursalDialog extends StatefulWidget {
  final Producto producto;

  const StockDetalleSucursalDialog({
    super.key,
    required this.producto,
  });

  @override
  State<StockDetalleSucursalDialog> createState() =>
      _StockDetalleSucursalDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Producto>('producto', producto));
  }
}

class _StockDetalleSucursalDialogState
    extends State<StockDetalleSucursalDialog> {
  final StockRepository _stockRepository = StockRepository.instance;
  final ProductoRepository _productoRepository = ProductoRepository.instance;

  bool _isLoading = true;
  String? _error;
  List<Sucursal> _sucursales = <Sucursal>[];
  Map<String, int> _stockPorSucursal = <String, int>{};
  Map<String, bool> _productoDisponibleEnSucursal = <String, bool>{};
  bool _dataLoaded = false;
  bool _mostrarInfoProducto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarSucursales();
    });
  }

  Future<void> _cargarSucursales() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<Sucursal> sucursales = await _stockRepository.getSucursales();
      final Map<String, int> stockMap = <String, int>{};
      final Map<String, bool> disponibilidadMap = <String, bool>{};
      final List<Future> futures = <Future>[];

      for (final Sucursal sucursal in sucursales) {
        futures.add(
            _cargarStockPorSucursal(sucursal.id, stockMap, disponibilidadMap));
      }

      await Future.wait(futures);

      if (mounted) {
        setState(() {
          _sucursales = sucursales;
          _stockPorSucursal = stockMap;
          _productoDisponibleEnSucursal = disponibilidadMap;
          _isLoading = false;
          _dataLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar sucursales: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cargarStockPorSucursal(String sucursalId,
      Map<String, int> stockMap, Map<String, bool> disponibilidadMap) async {
    try {
      final Producto? response = await _productoRepository.getProducto(
        sucursalId: sucursalId,
        productoId: widget.producto.id,
      );

      if (response != null) {
        stockMap[sucursalId] = response.stock;
        disponibilidadMap[sucursalId] = true;
      } else {
        stockMap[sucursalId] = 0;
        disponibilidadMap[sucursalId] = false;
      }
    } catch (e) {
      debugPrint('Error obteniendo stock para sucursal $sucursalId: $e');
      stockMap[sucursalId] = 0;
      disponibilidadMap[sucursalId] = false;
    }
  }

  Future<void> _verStockDetalle(Sucursal sucursal) async {
    final Producto productoSucursal = Producto(
      id: widget.producto.id,
      nombre: widget.producto.nombre,
      descripcion: widget.producto.descripcion,
      sku: widget.producto.sku,
      stock: _stockPorSucursal[sucursal.id] ?? 0,
      stockMinimo: widget.producto.stockMinimo,
      marca: widget.producto.marca,
      marcaId: widget.producto.marcaId,
      categoria: widget.producto.categoria,
      categoriaId: widget.producto.categoriaId,
      precioCompra: widget.producto.precioCompra,
      precioVenta: widget.producto.precioVenta,
      precioOferta: widget.producto.precioOferta,
      liquidacion: widget.producto.liquidacion,
      fechaCreacion: widget.producto.fechaCreacion,
    );

    final Producto? result = await showDialog<Producto>(
      context: context,
      builder: (BuildContext context) {
        return StockDetallesDialog(
          producto: productoSucursal,
          sucursalId: sucursal.id,
          sucursalNombre: sucursal.nombre,
        );
      },
    );

    if (result != null) {
      await _cargarSucursales();
    }
  }

  Color _getStockStatusColor(int stockActual, int stockMinimo) {
    final StockStatus status =
        StockUtils.getStockStatus(stockActual, stockMinimo);
    switch (status) {
      case StockStatus.agotado:
        return Colors.red.shade800;
      case StockStatus.stockBajo:
        return const Color(0xFFE31E24);
      case StockStatus.disponible:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    int stockTotal = 0;
    _stockPorSucursal.forEach((_, value) => stockTotal += value);

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 10,
      child: Container(
        width: 850,
        constraints: const BoxConstraints(maxHeight: 750),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Stock por Sucursal: ${widget.producto.nombre}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.white.withAlpha(51)),
            const SizedBox(height: 16),
            _buildProductoInfoColapsable(stockTotal),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                const FaIcon(FontAwesomeIcons.store,
                    size: 16, color: Color(0xFFE31E24)),
                const SizedBox(width: 8),
                const Text(
                  'Disponibilidad en Sucursales',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const Spacer(),
                if (_dataLoaded) ...<Widget>[
                  _buildLeyenda('Óptimo', Colors.green),
                  const SizedBox(width: 12),
                  _buildLeyenda('Bajo', Colors.orange),
                  const SizedBox(width: 12),
                  _buildLeyenda('Crítico', const Color(0xFFE31E24)),
                  const SizedBox(width: 12),
                  _buildLeyenda('No disponible', Colors.grey),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      CircularProgressIndicator(color: Color(0xFFE31E24)),
                      SizedBox(height: 16),
                      Text('Consultando stock en todas las sucursales...',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.error_outline,
                        color: Color(0xFFE31E24), size: 48),
                    const SizedBox(height: 16),
                    Text(_error!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      onPressed: _cargarSucursales,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE31E24),
                          foregroundColor: Colors.white),
                    ),
                  ],
                ),
              )
            else if (_sucursales.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No hay sucursales disponibles',
                      style: TextStyle(color: Colors.white)),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _sucursales.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Sucursal sucursal = _sucursales[index];
                    final int stockEnSucursal =
                        _stockPorSucursal[sucursal.id] ?? 0;
                    final int stockMinimo = widget.producto.stockMinimo ?? 0;
                    final bool disponible =
                        _productoDisponibleEnSucursal[sucursal.id] ?? false;
                    final Color statusColor = disponible
                        ? _getStockStatusColor(stockEnSucursal, stockMinimo)
                        : Colors.grey;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: const Color(0xFF2D2D2D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: disponible
                              ? statusColor.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _verStockDetalle(sucursal),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        FaIcon(
                                          sucursal.sucursalCentral
                                              ? FontAwesomeIcons.buildingFlag
                                              : FontAwesomeIcons.store,
                                          size: 14,
                                          color: sucursal.sucursalCentral
                                              ? Colors.amber
                                              : const Color(0xFFE31E24),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          sucursal.nombre,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        if (sucursal.sucursalCentral) ...<Widget>[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.amber
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text('CENTRAL',
                                                style: TextStyle(
                                                    color: Colors.amber,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sucursal.direccion ??
                                          'Sin dirección registrada',
                                      style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontSize: 13,
                                          fontStyle: sucursal.direccion != null
                                              ? FontStyle.normal
                                              : FontStyle.italic),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Precios en la sucursal
                              Expanded(
                                flex: 3,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    if (widget.producto.precioOferta != null) ...[
                                      Text(
                                        widget.producto.getPrecioVentaFormateado(),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.4),
                                          decoration: TextDecoration.lineThrough,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        widget.producto.getPrecioOfertaFormateado()!,
                                        style: TextStyle(
                                          color: widget.producto.liquidacion
                                              ? Colors.orange
                                              : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ] else
                                      Text(
                                        widget.producto.getPrecioVentaFormateado(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    const Text('Stock Actual',
                                        style: TextStyle(
                                            color: Colors.white70, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    if (disponible)
                                      Text(
                                        stockEnSucursal.toString(),
                                        style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      )
                                    else
                                      const Text('—',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeyenda(String texto, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(texto,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
      ],
    );
  }

  Widget _buildProductoInfoColapsable(int stockTotal) {
    final int stockMinimo = widget.producto.stockMinimo ?? 0;
    final Color stockTotalColor =
        StockUtils.getStockStatus(stockTotal, stockMinimo) ==
                StockStatus.disponible
            ? Colors.green
            : (stockTotal <= 0 ? Colors.red : Colors.orange);

    return Column(
      children: <Widget>[
        InkWell(
          onTap: () =>
              setState(() => _mostrarInfoProducto = !_mostrarInfoProducto),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Colors.white.withValues(
                      alpha: _mostrarInfoProducto ? 0.3 : 0.1)),
            ),
            child: Row(
              children: <Widget>[
                const FaIcon(FontAwesomeIcons.box,
                    size: 16, color: Color(0xFFE31E24)),
                const SizedBox(width: 12),
                const Text('Datos del Producto',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const Spacer(),
                _buildHeaderStat(
                    'STOCK TOTAL', stockTotal.toString(), stockTotalColor),
                const SizedBox(width: 24),
                _buildHeaderStat(
                    'MÍNIMO', stockMinimo.toString(), Colors.white70),
                const SizedBox(width: 16),
                FaIcon(
                    _mostrarInfoProducto
                        ? FontAwesomeIcons.chevronUp
                        : FontAwesomeIcons.chevronDown,
                    size: 12,
                    color: Colors.white54),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF242424),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildInfoRow('SKU', widget.producto.sku),
                          _buildInfoRow('Categoría', widget.producto.categoria),
                          _buildInfoRow('Marca', widget.producto.marca),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildInfoRow('P. Compra',
                              widget.producto.getPrecioCompraFormateado()),
                          _buildInfoRow('P. Venta',
                              widget.producto.getPrecioVentaFormateado()),
                          if (widget.producto.precioOferta != null)
                            _buildInfoRow(
                              widget.producto.liquidacion
                                  ? 'P. Liq.'
                                  : 'P. Oferta',
                              widget.producto.getPrecioOfertaFormateado()!,
                              textColor: widget.producto.liquidacion
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.producto.descripcion != null &&
                    widget.producto.descripcion!.isNotEmpty) ...<Widget>[
                  const Divider(height: 24, color: Colors.white10),
                  const Text('Descripción',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(widget.producto.descripcion!,
                      style: const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ],
            ),
          ),
          crossFadeState: _mostrarInfoProducto
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildHeaderStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(label,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.bold)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
