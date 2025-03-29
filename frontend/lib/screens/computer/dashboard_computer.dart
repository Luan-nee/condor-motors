import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/main.dart' show api;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Definición de la clase Venta para manejar los datos
class Venta {
  final String id;
  final DateTime? fechaCreacion;
  final String estado;
  final double subtotal;
  final double igv;
  final double total;
  final double? descuentoTotal;

  Venta({
    required this.id,
    this.fechaCreacion,
    required this.estado,
    required this.subtotal,
    required this.igv,
    required this.total,
    this.descuentoTotal,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      id: json['id'] ?? '',
      fechaCreacion: json['fecha_creacion'] != null 
          ? DateTime.parse(json['fecha_creacion']) 
          : null,
      estado: json['estado'] ?? 'PENDIENTE',
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      igv: (json['igv'] ?? 0.0).toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
      descuentoTotal: json['descuento_total'] != null 
          ? (json['descuento_total']).toDouble() 
          : null,
    );
  }
}

// Clase para manejar productos con stock bajo
class ProductoStockBajo {
  final String id;
  final String nombre;
  final int stock;
  final int stockMinimo;
  final String? categoria;
  final String? marca;

  ProductoStockBajo({
    required this.id,
    required this.nombre,
    required this.stock,
    required this.stockMinimo,
    this.categoria,
    this.marca,
  });

  factory ProductoStockBajo.fromJson(Map<String, dynamic> json) {
    return ProductoStockBajo(
      id: json['id'].toString(),
      nombre: json['nombre'] ?? 'Producto sin nombre',
      stock: (json['stockActual'] ?? json['stock'] ?? 0) as int,
      stockMinimo: (json['stockMinimo'] ?? 0) as int,
      categoria: json['categoria'] is Map 
          ? json['categoria']['nombre'] 
          : (json['categoria'] as String?),
      marca: json['marca'] is Map 
          ? json['marca']['nombre'] 
          : (json['marca'] as String?),
    );
  }
}

class DashboardComputerScreen extends StatefulWidget {
  final int? sucursalId;
  final String nombreSucursal;

  const DashboardComputerScreen({
    super.key, 
    this.sucursalId,
    this.nombreSucursal = 'Sucursal',
  });

  @override
  State<DashboardComputerScreen> createState() => _DashboardComputerScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(IntProperty('sucursalId', sucursalId))
    ..add(StringProperty('nombreSucursal', nombreSucursal));
  }
}

class _DashboardComputerScreenState extends State<DashboardComputerScreen> {
  late final VentasApi _ventasApi;
  late final StocksApi _stocksApi;
  bool _isLoading = false;
  List<Venta> _ultimasVentas = <Venta>[];
  List<ProductoStockBajo> _productosBajos = <ProductoStockBajo>[];
  bool _mostrandoTodosProductos = false;
  
  @override
  void initState() {
    super.initState();
    _ventasApi = api.ventas;
    _stocksApi = api.stocks;
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      // Obtener el ID de sucursal correcto del widget o usar el ID de la autenticación (7)
      // IMPORTANTE: Usamos el ID 7 según la información del usuario autenticado
      final String sucursalIdString = widget.sucursalId?.toString() ?? '7';
      debugPrint('Cargando datos para sucursal ID: $sucursalIdString');
      
      // Cargar últimas ventas
      final Map<String, dynamic> ventasResponse = await _ventasApi.getVentas(
        sucursalId: sucursalIdString,
      );
      
      if (!mounted) {
        return;
      }
      
      // Convertir los datos de la API a objetos Venta
      final List<Venta> ventasList = <Venta>[];
      if (ventasResponse['data'] != null && ventasResponse['data'] is List) {
        for (var item in ventasResponse['data']) {
          ventasList.add(Venta.fromJson(item));
        }
      }
      
      // Ordenar por fecha y tomar las últimas 5
      ventasList.sort((Venta a, Venta b) => 
        (b.fechaCreacion ?? DateTime.now())
            .compareTo(a.fechaCreacion ?? DateTime.now())
      );
      
      _ultimasVentas = ventasList.take(5).toList();
      
      // Cargar productos con stock bajo usando la API de stocks
      try {
        debugPrint('Obteniendo productos con stock bajo para sucursal ID: $sucursalIdString');
        
        final List stocksResponse = await _stocksApi.getStockBySucursal(
          sucursalId: sucursalIdString,
          stockBajo: true,
        );
        
        if (!mounted) {
          return;
        }
        
        final List<ProductoStockBajo> productosBajosList = <ProductoStockBajo>[];
        for (var item in stocksResponse) {
          productosBajosList.add(ProductoStockBajo.fromJson(item));
        }
              
        _productosBajos = productosBajosList;
        _mostrandoTodosProductos = false;
        debugPrint('Productos con stock bajo cargados: ${_productosBajos.length}');
      } catch (stockError) {
        debugPrint('Error al cargar productos con stock bajo: $stockError');
        // Si hay error, mostrar un mensaje más detallado para depuración
        debugPrint('Detalles del error: $stockError');
        
        // Si hay error, mantener los datos demo
        _productosBajos = <ProductoStockBajo>[
          ProductoStockBajo(
            id: '1',
            nombre: 'Casco MT Thunder',
            stock: 2,
            stockMinimo: 5,
          ),
          ProductoStockBajo(
            id: '2',
            nombre: 'Aceite Motul 5100',
            stock: 3,
            stockMinimo: 10,
          ),
        ];
      }
      
      setState(() {});
    } catch (e) {
      if (!mounted) {
        return;
      }
      // Mostrar más detalles del error para depuración
      debugPrint('Error detallado al cargar datos: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Text(
          'Dashboard - ${widget.nombreSucursal}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Resumen de ventas
                  _buildVentasCard(),
                  const SizedBox(height: 16),
                  
                  // Productos con stock bajo
                  _buildStockBajoCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildVentasCard() {
    return Card(
      color: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.cashRegister,
                    size: 16,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Últimas Ventas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_ultimasVentas.isEmpty)
              Center(
                child: Text(
                  'No hay ventas recientes',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ultimasVentas.length,
                itemBuilder: (BuildContext context, int index) {
                  final Venta venta = _ultimasVentas[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Venta #${venta.id}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      _formatDateTime(venta.fechaCreacion),
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing: Text(
                      'S/ ${venta.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockBajoCard() {
    return Card(
      color: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _mostrandoTodosProductos 
                            ? const Color(0xFF2196F3).withOpacity(0.1) 
                            : const Color(0xFFE31E24).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FaIcon(
                        _mostrandoTodosProductos 
                            ? FontAwesomeIcons.boxOpen 
                            : FontAwesomeIcons.triangleExclamation,
                        size: 16,
                        color: _mostrandoTodosProductos 
                            ? const Color(0xFF2196F3) 
                            : const Color(0xFFE31E24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _mostrandoTodosProductos ? 'Todos los Productos' : 'Stock Bajo',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () async {
                    try {
                      setState(() => _isLoading = true);
                      final String sucursalIdString = widget.sucursalId?.toString() ?? '7';
                      
                      // Si ya estamos mostrando todos los productos, volver a stock bajo
                      final List stocksResponse = await _stocksApi.getStockBySucursal(
                        sucursalId: sucursalIdString,
                        stockBajo: !_mostrandoTodosProductos, // Si estábamos mostrando todos, ahora filtramos para stock bajo
                      );
                      
                      if (!mounted) {
                        return;
                      }
                      
                      final List<ProductoStockBajo> productosList = <ProductoStockBajo>[];
                      for (var item in stocksResponse) {
                        productosList.add(ProductoStockBajo.fromJson(item));
                      }
                                          
                      setState(() {
                        _productosBajos = productosList;
                        _isLoading = false;
                        _mostrandoTodosProductos = !_mostrandoTodosProductos; // Alternar el modo
                      });
                      
                      final bool nuevoEstado = _mostrandoTodosProductos;
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(nuevoEstado
                              ? 'Mostrando todos los productos'
                              : 'Mostrando productos con stock bajo'
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) {
                        return;
                      }
                      setState(() => _isLoading = false);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al actualizar la lista: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: FaIcon(
                    _mostrandoTodosProductos 
                        ? FontAwesomeIcons.filter 
                        : FontAwesomeIcons.arrowsRotate,
                    size: 14,
                    color: const Color(0xFF2196F3),
                  ),
                  label: Text(
                    _mostrandoTodosProductos ? 'Ver Stock Bajo' : 'Actualizar',
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Contador de productos
            if (!_isLoading && _productosBajos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Text(
                      'Mostrando ${_productosBajos.length} productos',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    if (_mostrandoTodosProductos) ...<Widget>[
                      const SizedBox(width: 4),
                      Text(
                        '(${_productosBajos.where((ProductoStockBajo p) => p.stock < p.stockMinimo).length} con stock bajo)',
                        style: const TextStyle(
                          color: Color(0xFFE31E24),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_productosBajos.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay productos con stock bajo',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Todos los productos tienen stock suficiente',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Puedes usar el botón "Actualizar" para verificar nuevamente o\npulsar "Ver todos los productos" en la esquina superior derecha',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: <Widget>[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _productosBajos.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ProductoStockBajo producto = _productosBajos[index];
                      final bool tieneStockBajo = producto.stock < producto.stockMinimo;
                      
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          producto.nombre,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: tieneStockBajo ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Row(
                          children: <Widget>[
                            Text(
                              'Stock mínimo: ${producto.stockMinimo}',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            if (producto.categoria != null) ...<Widget>[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  producto.categoria!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF2196F3),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tieneStockBajo 
                                ? const Color(0xFFE31E24).withOpacity(0.1)
                                : const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${producto.stock}',
                            style: TextStyle(
                              color: tieneStockBajo 
                                  ? const Color(0xFFE31E24)
                                  : const Color(0xFF4CAF50),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) {
      return 'No disponible';
    }
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
