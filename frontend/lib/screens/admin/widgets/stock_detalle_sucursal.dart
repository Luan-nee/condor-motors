import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/producto.model.dart';
import '../../../models/sucursal.model.dart';
import 'stock_utils.dart';
import 'stock_detalles_dialog.dart';
import '../../../main.dart' show api;

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
      
      // En un escenario real, haríamos una llamada API para obtener el stock por sucursal
      // Aquí simulamos que tenemos la información con un valor predeterminado del producto
      for (final sucursal in sucursales) {
        // En un caso real, obtendrías el stock de cada sucursal con una API
        // stockMap[sucursal.id] = await api.productos.getStockEnSucursal(widget.producto.id, sucursal.id);
        
        // Por ahora, usamos el mismo stock para todas (simulación)
        stockMap[sucursal.id] = widget.producto.stock;
      }
      
      setState(() {
        _sucursales = sucursales;
        _stockPorSucursal = stockMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar sucursales: ${e.toString()}';
        _isLoading = false;
      });
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
      fechaCreacion: widget.producto.fechaCreacion,
    );
    
    // Mostrar el diálogo de detalles de stock para la sucursal seleccionada
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StockDetallesDialog(
          producto: productoSucursal,
          sucursalId: sucursal.id,
          sucursalNombre: sucursal.nombre,
        );
      },
    );
    
    // Si hubo cambios en el stock, recargar las sucursales para actualizar la información
    if (result == true) {
      _cargarSucursales();
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
            const Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.store,
                  size: 16,
                  color: Color(0xFFE31E24),
                ),
                SizedBox(width: 8),
                Text(
                  'Disponibilidad en Sucursales',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Estado de carga
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(
                    color: Color(0xFFE31E24),
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
                    
                    final statusColor = StockUtils.getStockStatusColor(stockEnSucursal, stockMinimo);
                    final statusIcon = StockUtils.getStockStatusIcon(stockEnSucursal, stockMinimo);
                    final statusText = StockUtils.getStockStatusText(stockEnSucursal, stockMinimo);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: const Color(0xFF2D2D2D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
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
                                        const FaIcon(
                                          FontAwesomeIcons.store,
                                          size: 14,
                                          color: Color(0xFFE31E24),
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
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sucursal.direccion ?? 'Sin dirección',
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
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Stock Actual',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      stockEnSucursal.toString(),
                                      style: TextStyle(
                                        color: statusColor,
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
                                    icon: const FaIcon(
                                      FontAwesomeIcons.chartLine,
                                      size: 14,
                                    ),
                                    label: const Text('Gestionar'),
                                    onPressed: () => _verStockDetalle(sucursal),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3E3E3E),
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
  
  Widget _buildProductoInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              FaIcon(
                FontAwesomeIcons.box,
                size: 16,
                color: Color(0xFFE31E24),
              ),
              SizedBox(width: 8),
              Text(
                'Información del Producto',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Datos básicos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem('Nombre', widget.producto.nombre),
                    _buildInfoItem('SKU', widget.producto.sku),
                    _buildInfoItem('Categoría', widget.producto.categoria),
                  ],
                ),
              ),
              // Datos adicionales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem('Marca', widget.producto.marca),
                    _buildInfoItem('Stock Mínimo', '${widget.producto.stockMinimo ?? 0}'),
                    if (widget.producto.descripcion != null && widget.producto.descripcion!.isNotEmpty)
                      _buildInfoItem('Descripción', widget.producto.descripcion!),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
