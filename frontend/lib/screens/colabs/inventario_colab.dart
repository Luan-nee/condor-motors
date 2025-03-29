import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/screens/computer/widgets/ventas_pendientes_utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class InventarioColabScreen extends StatefulWidget {
  const InventarioColabScreen({super.key});

  @override
  State<InventarioColabScreen> createState() => _InventarioColabScreenState();
}

class _InventarioColabScreenState extends State<InventarioColabScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  String? _sucursalId;

  // Datos de ejemplo para productos
  final List<Map<String, dynamic>> _productos = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 1,
      'codigo': 'CAS001',
      'nombre': 'Casco MT Thunder',
      'descripcion': 'Casco integral MT Thunder con sistema de ventilación avanzado',
      'precio': 299.99,
      'precioMayorista': 250.00,
      'stock': 15,
      'stockMinimo': 5,
      'categoria': 'Cascos',
      'marca': 'MT Helmets',
      'estado': 'ACTIVO',
      'imagen': 'assets/images/casco_mt.jpg',
      'ubicacion': 'Estante A-1',
      'ultimoConteo': '2024-03-10',
    },
    <String, dynamic>{
      'id': 2,
      'codigo': 'ACE001',
      'nombre': 'Aceite Motul 5100',
      'descripcion': 'Aceite sintético 4T 15W-50 para motocicletas',
      'precio': 89.99,
      'precioMayorista': 75.00,
      'stock': 3,
      'stockMinimo': 10,
      'categoria': 'Lubricantes',
      'marca': 'Motul',
      'estado': 'BAJO_STOCK',
      'imagen': 'assets/images/aceite_motul.jpg',
      'ubicacion': 'Estante B-2',
      'ultimoConteo': '2024-03-11',
    },
    <String, dynamic>{
      'id': 3,
      'codigo': 'LLA001',
      'nombre': 'Llanta Pirelli Diablo',
      'descripcion': 'Llanta deportiva Pirelli Diablo Rosso III 180/55 ZR17',
      'precio': 450.00,
      'precioMayorista': 380.00,
      'stock': 0,
      'stockMinimo': 4,
      'categoria': 'Llantas',
      'marca': 'Pirelli',
      'estado': 'AGOTADO',
      'imagen': 'assets/images/llanta_pirelli.jpg',
      'ubicacion': 'Estante C-3',
      'ultimoConteo': '2024-03-09',
    },
    <String, dynamic>{
      'id': 4,
      'codigo': 'FRE001',
      'nombre': 'Kit de Frenos Brembo',
      'descripcion': 'Kit completo de frenos Brembo con pastillas y disco',
      'precio': 850.00,
      'precioMayorista': 720.00,
      'stock': 8,
      'stockMinimo': 3,
      'categoria': 'Frenos',
      'marca': 'Brembo',
      'estado': 'ACTIVO',
      'imagen': 'assets/images/frenos_brembo.jpg',
      'ubicacion': 'Estante D-1',
      'ultimoConteo': '2024-03-12',
    },
    <String, dynamic>{
      'id': 5,
      'codigo': 'AMO001',
      'nombre': 'Amortiguador YSS',
      'descripcion': 'Amortiguador trasero YSS ajustable en compresión y rebote',
      'precio': 599.99,
      'precioMayorista': 520.00,
      'stock': 6,
      'stockMinimo': 4,
      'categoria': 'Suspensión',
      'marca': 'YSS',
      'estado': 'ACTIVO',
      'imagen': 'assets/images/amortiguador_yss.jpg',
      'ubicacion': 'Estante E-2',
      'ultimoConteo': '2024-03-10',
    }
  ];

  // Categorías disponibles
  final List<String> _categorias = <String>[
    'Todos',
    'Cascos',
    'Lubricantes',
    'Llantas',
    'Frenos',
    'Suspensión'
  ];

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    try {
      // Obtener el ID de sucursal usando la utilidad
      final int? sucId = await VentasPendientesUtils.obtenerSucursalId();
      if (!mounted) {
        return;
      }
      
      setState(() {
        _sucursalId = sucId?.toString();
      });
      await _cargarProductos();
    } catch (e) {
      debugPrint('Error al inicializar datos: $e');
    }
  }

  Future<void> _cargarProductos() async {
    if (!mounted) {
      return;
    }

    setState(() {
    });
    
    try {
      // Obtener productos usando la API
      final productos = await api.productos.getProductos(
        sucursalId: _sucursalId ?? '1',
        useCache: false,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _productos
          ..clear()
          ..addAll(productos.items.map((producto) => producto.toJson()));
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      
      setState(() {
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar productos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _realizarConteoInventario(Map<String, dynamic> producto) async {
    if (!mounted) {
      return;
    }
    
    try {
      // Usar la API de stocks para actualizar el inventario
      await api.stocks.updateStock(
        _sucursalId ?? '1',
        producto['id'].toString(),
        producto['stock'] as int,
        'incremento',
      );
      
      // Recargar productos después del conteo
      await _cargarProductos();
      
      if (!mounted) {
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conteo de inventario realizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al realizar el conteo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _ajustarInventario(Map<String, dynamic> producto) async {
    if (!mounted) {
      return;
    }
    
    try {
      // Usar la API de stocks para ajustar el inventario
      await api.stocks.registrarMovimientoStock(
        _sucursalId ?? '1',
        producto['id'].toString(),
        producto['stock'] as int,
        'entrada',
        motivo: 'Ajuste de inventario',
      );
      
      // Recargar productos después del ajuste
      await _cargarProductos();
      
      if (!mounted) {
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajuste de inventario realizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al realizar el ajuste: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getProductosFiltrados() {
    if (_searchQuery.isEmpty && _selectedCategory == 'Todos') {
      return _productos;
    }

    return _productos.where((Map<String, dynamic> producto) {
      final bool matchesSearch = 
          producto['codigo'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          producto['nombre'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          producto['marca'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          producto['ubicacion'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      final bool matchesCategory = _selectedCategory == 'Todos' || 
          producto['categoria'] == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'ACTIVO':
        return Colors.green;
      case 'BAJO_STOCK':
        return Colors.orange;
      case 'AGOTADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> productosFiltrados = _getProductosFiltrados();
    
    return Scaffold(
      body: Column(
        children: <Widget>[
          // Header con título
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                const FaIcon(
                  FontAwesomeIcons.boxesStacked,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'INVENTARIO',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'control de stock',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Barra de búsqueda y filtros
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                // Buscador
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por código, nombre o ubicación...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (String value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Filtro de categorías
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: _categorias.map((String categoria) {
                    return DropdownMenuItem<String>(
                      value: categoria,
                      child: Text(categoria),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // Lista de productos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: productosFiltrados.length,
              itemBuilder: (BuildContext context, int index) {
                final Map<String, dynamic> producto = productosFiltrados[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(producto['estado']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FaIcon(
                        producto['estado'] == 'AGOTADO'
                            ? FontAwesomeIcons.xmark
                            : producto['estado'] == 'BAJO_STOCK'
                                ? FontAwesomeIcons.exclamation
                                : FontAwesomeIcons.check,
                        color: _getEstadoColor(producto['estado']),
                        size: 24,
                      ),
                    ),
                    title: Row(
                      children: <Widget>[
                        Text(
                          producto['codigo'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            producto['nombre'],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            producto['ubicacion'],
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Último conteo: ${producto['ultimoConteo']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          'Stock: ${producto['stock']}',
                          style: TextStyle(
                            color: _getEstadoColor(producto['estado']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Mín: ${producto['stockMinimo']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    children: <Widget>[
                      // Detalles del producto
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Detalles del Producto',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(producto['descripcion']),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Categoría: ${producto['categoria']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Marca: ${producto['marca']}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _realizarConteoInventario(producto);
                                  },
                                  icon: const FaIcon(
                                    FontAwesomeIcons.listCheck,
                                    size: 16,
                                  ),
                                  label: const Text('Realizar Conteo'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (productosFiltrados.isNotEmpty) {
            _ajustarInventario(productosFiltrados[0]);
          }
        },
        child: const FaIcon(FontAwesomeIcons.penToSquare),
      ),
    );
  }
}
