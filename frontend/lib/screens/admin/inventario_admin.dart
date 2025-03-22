import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'widgets/stock_list.dart';
import 'widgets/stock_utils.dart';
import 'widgets/slide_sucursal.dart';
import 'widgets/stock_detalles_dialog.dart';
import 'widgets/stock_detalle_sucursal.dart';
import '../../models/producto.model.dart';
import '../../models/sucursal.model.dart';
import '../../main.dart' show api; // API global
import 'widgets/productos_utils.dart';

class InventarioAdminScreen extends StatefulWidget {
  const InventarioAdminScreen({super.key});

  @override
  State<InventarioAdminScreen> createState() => _InventarioAdminScreenState();
}

class _InventarioAdminScreenState extends State<InventarioAdminScreen> {
  // Estado
  String _selectedSucursalId = '';
  String _selectedSucursalNombre = '';
  List<Sucursal> _sucursales = [];
  Sucursal? _selectedSucursal;
  List<Producto>? _productos;
  bool _isLoadingSucursales = true;
  bool _isLoadingProductos = false;
  String? _errorSucursales;
  String? _errorProductos;

  @override
  void initState() {
    super.initState();
    _cargarSucursales();
  }

  Future<void> _cargarSucursales() async {
    setState(() {
      _isLoadingSucursales = true;
      _errorSucursales = null;
    });

    try {
      final sucursales = await api.sucursales.getSucursales();
      setState(() {
        _sucursales = sucursales;
        _isLoadingSucursales = false;
      });
    } catch (e) {
      setState(() {
        _errorSucursales = e.toString();
        _isLoadingSucursales = false;
      });
    }
  }

  Future<void> _cargarProductos(String sucursalId) async {
    if (sucursalId.isEmpty) {
      setState(() {
        _productos = null;
      });
      return;
    }

    setState(() {
      _isLoadingProductos = true;
      _errorProductos = null;
    });

    try {
      final productos = await api.productos.getProductos(sucursalId: sucursalId);
      setState(() {
        _productos = productos;
        _isLoadingProductos = false;
      });
    } catch (e) {
      setState(() {
        _errorProductos = e.toString();
        _isLoadingProductos = false;
      });
    }
  }

  void _onSucursalSeleccionada(Sucursal sucursal) {
    setState(() {
      _selectedSucursalId = sucursal.id;
      _selectedSucursalNombre = sucursal.nombre;
      _selectedSucursal = sucursal;
    });
    _cargarProductos(sucursal.id);
  }

  void _verDetallesProducto(Producto producto) {
    showDialog(
      context: context,
      builder: (context) => StockDetalleSucursalDialog(
        producto: producto,
      ),
    ).then((_) {
      // Recargar productos al cerrar el diálogo para reflejar posibles cambios
      if (_selectedSucursalId.isNotEmpty) {
        _cargarProductos(_selectedSucursalId);
      }
    });
  }

  void _editarProducto(Producto producto) {
    // TODO: Implementar edición de producto
    debugPrint('Editar producto: ${producto.nombre}');
  }
  
  void _verStockDetalles(Producto producto) {
    showDialog(
      context: context,
      builder: (context) => StockDetallesDialog(
        producto: producto,
        sucursalId: _selectedSucursalId,
        sucursalNombre: _selectedSucursalNombre,
      ),
    ).then((_) {
      // Recargar productos al cerrar el diálogo para reflejar cambios
      if (_selectedSucursalId.isNotEmpty) {
        _cargarProductos(_selectedSucursalId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Inventario'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _cargarSucursales();
              if (_selectedSucursalId.isNotEmpty) {
                _cargarProductos(_selectedSucursalId);
              }
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Área principal (75% del ancho)
            Expanded(
              flex: 75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y estadísticas
                  Row(
                    children: [
                      // Título
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedSucursalId.isEmpty
                                  ? 'Inventario General'
                                  : 'Inventario de $_selectedSucursalNombre',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedSucursalId.isEmpty
                                  ? 'Seleccione una sucursal para ver su inventario'
                                  : 'Gestión de stock y productos',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Botón de agregar producto
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implementar agregar producto
                        },
                        icon: const FaIcon(
                          FontAwesomeIcons.plus,
                          size: 14,
                        ),
                        label: const Text('Nuevo Producto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE31E24),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Resumen del inventario (si hay sucursal seleccionada)
                  if (_selectedSucursalId.isNotEmpty && _productos != null) ...[
                    const SizedBox(height: 16),
                    InventarioResumen(
                      productos: _productos!,
                      sucursalNombre: _selectedSucursalNombre,
                    ),
                  ],
                  
                  // Tabla de productos
                  const SizedBox(height: 16),
                  Expanded(
                    child: TableProducts(
                      selectedSucursalId: _selectedSucursalId,
                      productos: _productos,
                      isLoading: _isLoadingProductos,
                      error: _errorProductos,
                      onRetry: _selectedSucursalId.isNotEmpty
                          ? () => _cargarProductos(_selectedSucursalId)
                          : null,
                      onEditProducto: _editarProducto,
                      onVerDetalles: _verDetallesProducto,
                      onVerStockDetalles: _verStockDetalles,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // SlideSucursal a la derecha (25% del ancho)
            Expanded(
              flex: 25,
              child: SlideSucursal(
                sucursales: _sucursales,
                sucursalSeleccionada: _selectedSucursal,
                onSucursalSelected: _onSucursalSeleccionada,
                onRecargarSucursales: _cargarSucursales,
                isLoading: _isLoadingSucursales,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
