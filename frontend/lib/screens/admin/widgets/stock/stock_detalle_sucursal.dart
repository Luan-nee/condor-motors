import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../main.dart' show api;
import '../../../../models/producto.model.dart';
import '../../../../models/sucursal.model.dart';
import '../../../../utils/stock_utils.dart';
import 'stock_detalles_dialog.dart';

/// Diálogo que muestra el stock de un producto en todas las sucursales
class StockDetalleSucursalDialog extends StatefulWidget {
  final Producto producto;
  
  const StockDetalleSucursalDialog({
    super.key,
    required this.producto,
  });
  
  @override
  State<StockDetalleSucursalDialog> createState() => _StockDetalleSucursalDialogState();
}

class _StockDetalleSucursalDialogState extends State<StockDetalleSucursalDialog> {
  bool _isLoading = true;
  String? _error;
  List<Sucursal> _sucursales = [];
  Map<String, int> _stockPorSucursal = {};
  Map<String, bool> _productoDisponibleEnSucursal = {};
  bool _dataLoaded = false;
  
  @override
  void initState() {
    super.initState();
    _cargarSucursales();
  }
  
  Future<void> _cargarSucursales() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Cargar las sucursales
      final sucursales = await api.sucursales.getSucursales();
      
      // Para cada sucursal, cargar el stock del producto
      final Map<String, int> stockMap = {};
      final Map<String, bool> disponibilidadMap = {};
      
      // Utilizamos Future.wait para cargar todos los datos en paralelo
      final futures = <Future>[];
      
      for (final sucursal in sucursales) {
        // Añadir un Future para cada sucursal
        futures.add(_cargarStockPorSucursal(sucursal.id, stockMap, disponibilidadMap));
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
  
  Future<void> _cargarStockPorSucursal(
    String sucursalId, 
    Map<String, int> stockMap, 
    Map<String, bool> disponibilidadMap
  ) async {
    try {
      // Obtener el stock específico para esta sucursal
      final response = await api.productos.getProducto(
        productoId: widget.producto.id,
        sucursalId: sucursalId,
      );
      
      // Si la respuesta existe, almacenar el stock
      stockMap[sucursalId] = response.stock;
      disponibilidadMap[sucursalId] = true;
        } catch (e) {
      // En caso de error, marcamos el producto como no disponible
      debugPrint('Error obteniendo stock para sucursal $sucursalId: $e');
      stockMap[sucursalId] = 0;
      disponibilidadMap[sucursalId] = false;
    }
  }
  
  Future<void> _verStockDetalle(Sucursal sucursal) async {
    // Crear una copia del producto con el stock de la sucursal seleccionada
    final productoSucursal = Producto(
      id: widget.producto.id,
      nombre: widget.producto.nombre,
      descripcion: widget.producto.descripcion,
      sku: widget.producto.sku,
      stock: _stockPorSucursal[sucursal.id] ?? 0,
      stockMinimo: widget.producto.stockMinimo,
      marca: widget.producto.marca,
      categoria: widget.producto.categoria,
      precioCompra: widget.producto.precioCompra,
      precioVenta: widget.producto.precioVenta,
      precioOferta: widget.producto.precioOferta,
      liquidacion: widget.producto.liquidacion,
      fechaCreacion: widget.producto.fechaCreacion,
    );
    
    // Mostrar el diálogo de detalles de stock para la sucursal seleccionada
    final result = await showDialog<Producto>(
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
          children: [
            // Título y cierre
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
            
            Divider(color: Colors.white.withOpacity(0.2)),
            
            const SizedBox(height: 16),
            
            // Información del producto
            _buildProductoInfo(),
            
            const SizedBox(height: 16),
            
            // Título para la lista de sucursales
            Row(
              children: [
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
                if (_dataLoaded) ...[
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
                    children: [
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
                  children: [
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
                  itemBuilder: (context, index) {
                    final sucursal = _sucursales[index];
                    final stockEnSucursal = _stockPorSucursal[sucursal.id] ?? 0;
                    final stockMinimo = widget.producto.stockMinimo ?? 0;
                    final disponible = _productoDisponibleEnSucursal[sucursal.id] ?? false;
                    
                    final statusColor = disponible 
                        ? StockUtils.getStockStatusColor(stockEnSucursal, stockMinimo)
                        : Colors.grey;
                    final statusIcon = disponible
                        ? StockUtils.getStockStatusIcon(stockEnSucursal, stockMinimo)
                        : FontAwesomeIcons.ban;
                    final statusText = disponible
                        ? StockUtils.getStockStatusText(stockEnSucursal, stockMinimo)
                        : 'No disponible';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: const Color(0xFF2D2D2D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: disponible 
                              ? statusColor.withOpacity(0.5) 
                              : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _verStockDetalle(sucursal),
                        borderRadius: BorderRadius.circular(8),
                        hoverColor: Colors.white.withOpacity(0.05),
                        splashColor: Colors.white.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Información de la sucursal
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
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
                                        if (sucursal.sucursalCentral) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
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
                                      sucursal.direccion,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Estado del stock
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
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
                                  children: [
                                    const Text(
                                      'Stock Actual',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    disponible
                                      ? Text(
                                          stockEnSucursal.toString(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        )
                                      : const Text(
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
                              
                              // Botón para editar el stock
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: ElevatedButton.icon(
                                    icon: FaIcon(
                                      disponible
                                          ? FontAwesomeIcons.chartLine
                                          : FontAwesomeIcons.plus,
                                      size: 14,
                                    ),
                                    label: Text(disponible ? 'Gestionar' : 'Añadir'),
                                    onPressed: () => _verStockDetalle(sucursal),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: disponible
                                          ? const Color(0xFF3E3E3E)
                                          : const Color(0xFF1E631E), // Verde para añadir
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
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
      children: [
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
            color: Colors.white.withOpacity(0.7),
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
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con icono
          Row(
            children: [
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
              if (widget.producto.liquidacion) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.fire,
                        size: 12,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      const Text(
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
            children: [
              // Columna 1 - Datos generales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('SKU', widget.producto.sku),
                    _buildInfoRow('Categoría', widget.producto.categoria),
                    _buildInfoRow('Marca', widget.producto.marca),
                    if (widget.producto.stockMinimo != null)
                      _buildInfoRow('Stock Mínimo', widget.producto.stockMinimo.toString()),
                  ],
                ),
              ),
              
              // Columna 2 - Precios
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Precio Compra', widget.producto.getPrecioCompraFormateado()),
                    _buildInfoRow('Precio Venta', widget.producto.getPrecioVentaFormateado()),
                    if (widget.producto.precioOferta != null)
                      _buildInfoRow(
                        widget.producto.liquidacion ? 'Precio Liquidación' : 'Precio Oferta', 
                        widget.producto.getPrecioOfertaFormateado()!,
                        textColor: widget.producto.liquidacion ? Colors.orange : Colors.green,
                      ),
                    if (widget.producto.liquidacion)
                      _buildInfoRow(
                        'Descuento', 
                        widget.producto.getPorcentajeDescuentoOfertaFormateado() ?? '0%',
                        textColor: Colors.orange,
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          // Descripción (si existe)
          if (widget.producto.descripcion != null && widget.producto.descripcion!.isNotEmpty) ...[
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
                color: Colors.white.withOpacity(0.8),
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
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
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
