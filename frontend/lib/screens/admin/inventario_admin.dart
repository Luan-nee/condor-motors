import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../main.dart' show api; // API global
import '../../models/paginacion.model.dart';
import '../../models/producto.model.dart';
import '../../models/sucursal.model.dart';
import '../../widgets/paginador.dart';
import 'widgets/slide_sucursal.dart';
import 'widgets/stock_detalle_sucursal.dart';
import 'widgets/stock_detalles_dialog.dart';
import 'widgets/stock_list.dart';

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
  PaginatedResponse<Producto>? _paginatedProductos;
  List<Producto> _productosFiltrados = [];
  bool _isLoadingSucursales = true;
  bool _isLoadingProductos = false;
  String? _errorProductos;
  
  // Parámetros de paginación y filtrado
  String _searchQuery = '';
  int _currentPage = 1;
  int _pageSize = 10;
  String _sortBy = '';
  String _order = 'desc';

  @override
  void initState() {
    super.initState();
    _cargarSucursales();
  }

  Future<void> _cargarSucursales() async {
    setState(() {
      _isLoadingSucursales = true;
    });

    try {
      final sucursales = await api.sucursales.getSucursales();
      setState(() {
        _sucursales = sucursales;
        _isLoadingSucursales = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSucursales = false;
      });
    }
  }

  Future<void> _cargarProductos(String sucursalId) async {
    if (sucursalId.isEmpty) {
      setState(() {
        _paginatedProductos = null;
        _productosFiltrados = [];
      });
      return;
    }

    setState(() {
      _isLoadingProductos = true;
      _errorProductos = null;
    });

    try {
      // Aplicar la búsqueda del servidor sólo si la búsqueda es mayor a 3 caracteres
      final searchQuery = _searchQuery.length >= 3 ? _searchQuery : null;
      
      final paginatedProductos = await api.productos.getProductos(
        sucursalId: sucursalId,
        search: searchQuery,
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: _sortBy.isNotEmpty ? _sortBy : null,
        order: _order,
      );
      
      setState(() {
        _paginatedProductos = paginatedProductos;
        _productosFiltrados = paginatedProductos.items;
        _isLoadingProductos = false;
      });
    } catch (e) {
      setState(() {
        _errorProductos = e.toString();
        _isLoadingProductos = false;
      });
    }
  }

  // Método para cambiar de página
  void _cambiarPagina(int pagina) {
    if (_currentPage != pagina) {
      setState(() {
        _currentPage = pagina;
      });
      _cargarProductos(_selectedSucursalId);
    }
  }

  // Método para cambiar tamaño de página
  void _cambiarTamanioPagina(int tamanio) {
    if (_pageSize != tamanio) {
      setState(() {
        _pageSize = tamanio;
        _currentPage = 1; // Volvemos a la primera página al cambiar el tamaño
      });
      _cargarProductos(_selectedSucursalId);
    }
  }

  // Método para ordenar por un campo
  void _ordenarPor(String campo) {
    setState(() {
      if (_sortBy == campo) {
        // Si ya estamos ordenando por este campo, cambiamos la dirección
        _order = _order == 'asc' ? 'desc' : 'asc';
      } else {
        _sortBy = campo;
        _order = 'desc'; // Por defecto ordenamos descendente
      }
      _currentPage = 1; // Volvemos a la primera página al cambiar el orden
    });
    _cargarProductos(_selectedSucursalId);
  }

  void _onSucursalSeleccionada(Sucursal sucursal) {
    setState(() {
      _selectedSucursalId = sucursal.id;
      _selectedSucursalNombre = sucursal.nombre;
      _selectedSucursal = sucursal;
      _currentPage = 1; // Volver a la primera página al cambiar de sucursal
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
                      
                      // Barra de búsqueda
                      if (_selectedSucursalId.isNotEmpty)
                        SizedBox(
                          width: 300,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar productos...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                              prefixIcon: const Icon(Icons.search, color: Colors.white38),
                              filled: true,
                              fillColor: const Color(0xFF232323),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(),
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                                
                                // Si la búsqueda es mayor a 3 caracteres o está vacía, hacer solicitud al servidor
                                if (value.length >= 3 || value.isEmpty) {
                                  _currentPage = 1; // Reiniciar a la primera página
                                  _cargarProductos(_selectedSucursalId);
                                }
                              });
                            },
                          ),
                        ),
                      
                      const SizedBox(width: 16),
                      
                      // Botón de agregar producto
                      ElevatedButton.icon(
                        onPressed: _selectedSucursalId.isEmpty ? null : () {
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
                          disabledBackgroundColor: const Color(0xFF3D3D3D),
                          disabledForegroundColor: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                  
                  // Resumen del inventario (si hay sucursal seleccionada)
                  if (_selectedSucursalId.isNotEmpty && _productosFiltrados.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    InventarioResumen(
                      productos: _productosFiltrados,
                      sucursalNombre: _selectedSucursalNombre,
                    ),
                  ],
                  
                  // Tabla de productos
                  const SizedBox(height: 16),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: TableProducts(
                            selectedSucursalId: _selectedSucursalId,
                            productos: _productosFiltrados,
                            isLoading: _isLoadingProductos,
                            error: _errorProductos,
                            onRetry: _selectedSucursalId.isNotEmpty
                                ? () => _cargarProductos(_selectedSucursalId)
                                : null,
                            onEditProducto: _editarProducto,
                            onVerDetalles: _verDetallesProducto,
                            onVerStockDetalles: _verStockDetalles,
                            onSort: _ordenarPor,
                            sortBy: _sortBy,
                            sortOrder: _order,
                          ),
                        ),
                        
                        // Paginador
                        if (_paginatedProductos != null && _paginatedProductos!.paginacion.totalPages > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Info de cantidad
                                Text(
                                  'Mostrando ${_productosFiltrados.length} de ${_paginatedProductos!.paginacion.totalItems} productos',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                
                                // Paginador
                                Paginador(
                                  paginacion: _paginatedProductos!.paginacion,
                                  onPageChanged: _cambiarPagina,
                                ),
                                
                                // Selector de tamaño de página
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Mostrar:',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildPageSizeDropdown(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
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

  Widget _buildPageSizeDropdown() {
    final options = [10, 20, 50, 100];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _pageSize,
          items: options.map((size) {
            return DropdownMenuItem<int>(
              value: size,
              child: Text(
                size.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _cambiarTamanioPagina(value);
            }
          },
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white),
          dropdownColor: const Color(0xFF2D2D2D),
        ),
      ),
    );
  }
}
