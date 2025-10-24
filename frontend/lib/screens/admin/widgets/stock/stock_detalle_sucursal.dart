import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
// Importar los repositorios necesarios
import 'package:condorsmotors/repositories/stock.repository.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_detalles_dialog.dart';
import 'package:condorsmotors/utils/stock_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Diálogo que muestra el stock de un producto en todas las sucursales
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
  // Instancias de repositorios
  final StockRepository _stockRepository = StockRepository.instance;
  final ProductoRepository _productoRepository = ProductoRepository.instance;

  bool _isLoading = true;
  String? _error;
  List<Sucursal> _sucursales = <Sucursal>[];
  Map<String, int> _stockPorSucursal = <String, int>{};
  Map<String, bool> _productoDisponibleEnSucursal = <String, bool>{};
  bool _dataLoaded = false;

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
      // Cargar las sucursales usando el repositorio
      final List<Sucursal> sucursales = await _stockRepository.getSucursales();

      // Para cada sucursal, cargar el stock del producto
      final Map<String, int> stockMap = <String, int>{};
      final Map<String, bool> disponibilidadMap = <String, bool>{};

      // Utilizamos Future.wait para cargar todos los datos en paralelo
      final List<Future> futures = <Future>[];

      for (final Sucursal sucursal in sucursales) {
        // Añadir un Future para cada sucursal
        futures.add(
            _cargarStockPorSucursal(sucursal.id, stockMap, disponibilidadMap));
      }

      // Esperar a que todas las cargas se completen
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
      // Obtener el stock específico para esta sucursal usando el repositorio de productos
      final Producto? response = await _productoRepository.getProducto(
        sucursalId: sucursalId,
        productoId: widget.producto.id,
      );

      // Si la respuesta existe, almacenar el stock
      if (response != null) {
        stockMap[sucursalId] = response.stock;
        disponibilidadMap[sucursalId] = true;
      } else {
        stockMap[sucursalId] = 0;
        disponibilidadMap[sucursalId] = false;
      }
    } catch (e) {
      // En caso de error, marcamos el producto como no disponible
      debugPrint('Error obteniendo stock para sucursal $sucursalId: $e');
      stockMap[sucursalId] = 0;
      disponibilidadMap[sucursalId] = false;
    }
  }

  Future<void> _verStockDetalle(Sucursal sucursal) async {
    // Crear una copia del producto con el stock de la sucursal seleccionada
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

    // Mostrar el diálogo de detalles de stock para la sucursal seleccionada
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

    // Si hubo cambios en el stock o liquidación, recargar las sucursales para actualizar la información
    if (result != null) {
      await _cargarSucursales();
    }
  }

  // Métodos auxiliares que usan el provider
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

  IconData _getStockStatusIcon(int stockActual, int stockMinimo) {
    final StockStatus status =
        StockUtils.getStockStatus(stockActual, stockMinimo);
    switch (status) {
      case StockStatus.agotado:
        return FontAwesomeIcons.ban;
      case StockStatus.stockBajo:
        return FontAwesomeIcons.triangleExclamation;
      case StockStatus.disponible:
        return FontAwesomeIcons.check;
    }
  }

  String _getStockStatusText(int stockActual, int stockMinimo) {
    final StockStatus status =
        StockUtils.getStockStatus(stockActual, stockMinimo);
    switch (status) {
      case StockStatus.agotado:
        return 'Agotado';
      case StockStatus.stockBajo:
        return 'Stock bajo';
      case StockStatus.disponible:
        return 'Disponible';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 10,
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Título y cierre
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Stock por Sucursal: ${widget.producto.nombre}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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

            Divider(color: Colors.white.withValues(alpha: 0.2)),

            const SizedBox(height: 16),

            // Información del producto
            _buildProductoInfo(),

            const SizedBox(height: 16),

            // Título para la lista de sucursales
            Row(
              children: <Widget>[
                const FaIcon(
                  FontAwesomeIcons.store,
                  size: 16,
                  color: Color(0xFFE31E24),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Disponibilidad en Sucursales',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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

            // Estado de carga
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      CircularProgressIndicator(
                        color: Color(0xFFE31E24),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Consultando stock en todas las sucursales...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFE31E24),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      onPressed: _cargarSucursales,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31E24),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            else if (_sucursales.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'No hay sucursales disponibles',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            else
              // Lista de sucursales
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
                    final IconData statusIcon = disponible
                        ? _getStockStatusIcon(stockEnSucursal, stockMinimo)
                        : FontAwesomeIcons.ban;
                    final String statusText = disponible
                        ? _getStockStatusText(stockEnSucursal, stockMinimo)
                        : 'No disponible';

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
                        hoverColor: Colors.white.withValues(alpha: 0.05),
                        splashColor: Colors.white.withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: <Widget>[
                              // Información de la sucursal
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
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (sucursal
                                            .sucursalCentral) ...<Widget>[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.amber
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'CENTRAL',
                                              style: TextStyle(
                                                color: Colors.amber,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sucursal.direccion ??
                                          'Sin dirección registrada',
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                        fontSize: 14,
                                        fontStyle: sucursal.direccion != null
                                            ? FontStyle.normal
                                            : FontStyle.italic,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Estado del stock
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color:
                                            statusColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          FaIcon(
                                            statusIcon,
                                            color: statusColor,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            statusText,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Stock en la sucursal
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: <Widget>[
                                    const Text(
                                      'Stock Actual',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (disponible)
                                      Text(
                                        stockEnSucursal.toString(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      )
                                    else
                                      const Text(
                                        '—',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
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
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          texto,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildProductoInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Título con icono
          Row(
            children: <Widget>[
              const FaIcon(
                FontAwesomeIcons.box,
                size: 16,
                color: Color(0xFFE31E24),
              ),
              const SizedBox(width: 8),
              const Text(
                'Información del Producto',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (widget.producto.liquidacion) ...<Widget>[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FaIcon(
                        FontAwesomeIcons.fire,
                        size: 12,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'En Liquidación',
                        style: TextStyle(
                          color: Colors.orange,
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

          const SizedBox(height: 16),

          // Información básica en forma de rejilla (2 columnas)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Columna 1 - Datos generales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildInfoRow('SKU', widget.producto.sku),
                    _buildInfoRow('Categoría', widget.producto.categoria),
                    _buildInfoRow('Marca', widget.producto.marca),
                    if (widget.producto.stockMinimo != null)
                      _buildInfoRow('Stock Mínimo',
                          widget.producto.stockMinimo.toString()),
                  ],
                ),
              ),

              // Columna 2 - Precios
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildInfoRow('Precio Compra',
                        widget.producto.getPrecioCompraFormateado()),
                    _buildInfoRow('Precio Venta',
                        widget.producto.getPrecioVentaFormateado()),
                    if (widget.producto.precioOferta != null)
                      _buildInfoRow(
                        widget.producto.liquidacion
                            ? 'Precio Liquidación'
                            : 'Precio Oferta',
                        widget.producto.getPrecioOfertaFormateado()!,
                        textColor: widget.producto.liquidacion
                            ? Colors.orange
                            : Colors.green,
                      ),
                    if (widget.producto.liquidacion)
                      _buildInfoRow(
                        'Descuento',
                        widget.producto
                                .getPorcentajeDescuentoOfertaFormateado() ??
                            '0%',
                        textColor: Colors.orange,
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Descripción (si existe)
          if (widget.producto.descripcion != null &&
              widget.producto.descripcion!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            const Text(
              'Descripción:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.producto.descripcion!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper para crear filas de información
  Widget _buildInfoRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
