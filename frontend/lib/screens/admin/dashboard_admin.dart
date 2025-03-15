import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/index.dart';
import '../../main.dart' show api;

// Definición de la clase Producto para manejar los datos
class Producto {
  final int id;
  final String nombre;
  final double precio;
  final String? descripcion;
  final String? imagen;
  final String? categoria;

  Producto({
    required this.id,
    required this.nombre,
    required this.precio,
    this.descripcion,
    this.imagen,
    this.categoria,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      precio: (json['precio'] ?? 0.0).toDouble(),
      descripcion: json['descripcion'],
      imagen: json['imagen'],
      categoria: json['categoria'],
    );
  }
}

// Definición de la clase Stock para manejar los datos
class Stock {
  final int productoId;
  final int cantidad;

  Stock({
    required this.productoId,
    required this.cantidad,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      productoId: json['producto_id'] ?? 0,
      cantidad: json['cantidad'] ?? 0,
    );
  }
}

// Definición de la clase Sucursal para manejar los datos
class Sucursal {
  final int id;
  final String nombre;
  final String direccion;
  final bool sucursalCentral;
  final bool activo;
  final DateTime? fechaCreacion;

  Sucursal({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.sucursalCentral,
    required this.activo,
    this.fechaCreacion,
  });

  factory Sucursal.fromJson(Map<String, dynamic> json) {
    return Sucursal(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      direccion: json['direccion'] ?? '',
      sucursalCentral: json['sucursal_central'] ?? false,
      activo: json['activo'] ?? true,
      fechaCreacion: json['fecha_creacion'] != null 
          ? DateTime.parse(json['fecha_creacion']) 
          : null,
    );
  }
}

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  late final ProductosApi _productosApi;
  late final SucursalesApi _sucursalesApi;
  List<Producto> _productos = [];
  List<Sucursal> _sucursales = [];
  List<Sucursal> _centrales = [];
  Map<int, int> _existencias = {};
  bool _isLoading = false;
  double _totalVentas = 0;
  double _totalGanancias = 0;
  bool _mostrarCentrales = true;

  @override
  void initState() {
    super.initState();
    _productosApi = api.productos;
    _sucursalesApi = api.sucursales;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // Cargar productos
      final productosResponse = await _productosApi.getProductos();
      final List<Producto> productosList = [];
      for (var item in productosResponse) {
        productosList.add(Producto.fromJson(item));
      }
      
      // Simular datos de ventas (esto debería venir de una API real)
      final ventasData = {
        'total': 15000.0,
        'ganancia': 3500.0
      };
      
      // Simular datos de stock (esto debería venir de una API real)
      final existencias = <int, int>{};
      for (var producto in productosList) {
        existencias[producto.id] = (producto.id % 20); // Simulación de stock
      }
      
      // Cargar sucursales
      final sucursalesResponse = await _sucursalesApi.getSucursales();
      final List<Sucursal> sucursalesList = [];
      for (var item in sucursalesResponse) {
        sucursalesList.add(Sucursal.fromJson(item));
      }
      
      final centrales = sucursalesList.where((s) => s.sucursalCentral).toList();
      final sucursalesNoCentrales = sucursalesList.where((s) => !s.sucursalCentral).toList();
      
      if (!mounted) return;
      setState(() {
        _productos = productosList;
        _existencias = existencias;
        _totalVentas = ventasData['total'] ?? 0.0;
        _totalGanancias = ventasData['ganancia'] ?? 0.0;
        _sucursales = sucursalesNoCentrales;
        _centrales = centrales;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _toggleMostrarCentrales(bool mostrarCentrales) {
    setState(() {
      _mostrarCentrales = mostrarCentrales;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _DashboardContent(
      productosList: _productos,
      totalVentas: _totalVentas,
      totalGanancias: _totalGanancias,
      existencias: _existencias,
      sucursales: _sucursales,
      centrales: _centrales,
      mostrarCentrales: _mostrarCentrales,
      onToggleMostrarCentrales: _toggleMostrarCentrales,
      onRefresh: _loadInitialData,
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final List<Producto> productosList;
  final double totalVentas;
  final double totalGanancias;
  final Map<int, int> existencias;
  final List<Sucursal> sucursales;
  final List<Sucursal> centrales;
  final bool mostrarCentrales;
  final Function(bool) onToggleMostrarCentrales;
  final VoidCallback onRefresh;

  const _DashboardContent({
    required this.productosList,
    required this.totalVentas,
    required this.totalGanancias,
    required this.existencias,
    required this.sucursales,
    required this.centrales,
    required this.mostrarCentrales,
    required this.onToggleMostrarCentrales,
    required this.onRefresh,
  });

  int getExistencias(Producto producto) {
    return existencias[producto.id] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Panel principal (ocupa el 75% del ancho)
        Expanded(
          flex: 75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header con nombre del local
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'INVENTARIO',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      ' / ',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white54,
                      ),
                    ),
                    Text(
                      'Central Principal',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Sección de productos con bajo stock
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF1A1A1A),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Productos con bajo stock',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE31E24),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tabla de productos
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFF2D2D2D),
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Foto',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Producto',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Stock',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Cantidad máxima',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Cantidad mínima',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                          rows: productosList
                              .where((producto) =>
                                  getExistencias(producto) < 10) // Ejemplo de umbral
                              .map(
                                (producto) => DataRow(
                                  cells: [
                                    DataCell(
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2D2D2D),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const FaIcon(
                                          FontAwesomeIcons.motorcycle,
                                          color: Colors.white54,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(
                                      producto.nombre,
                                      style: const TextStyle(color: Colors.white),
                                    )),
                                    DataCell(Text(
                                      getExistencias(producto).toString(),
                                      style: TextStyle(
                                        color: getExistencias(producto) < 5
                                            ? const Color(0xFFE31E24)
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )),
                                    const DataCell(Text(
                                      '50', // Ejemplo de cantidad máxima
                                      style: TextStyle(color: Colors.white),
                                    )),
                                    const DataCell(Text(
                                      '10', // Ejemplo de cantidad mínima
                                      style: TextStyle(color: Colors.white),
                                    )),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Panel lateral derecho (ocupa el 25% del ancho)
        Container(
          width: MediaQuery.of(context).size.width * 0.25,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            border: Border(
              left: BorderSide(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título del panel
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Administrar Locales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const FaIcon(
                            FontAwesomeIcons.arrowsRotate,
                            color: Colors.white70,
                            size: 16,
                          ),
                          onPressed: onRefresh,
                          tooltip: 'Actualizar',
                        ),
                        IconButton(
                          icon: const FaIcon(
                            FontAwesomeIcons.circlePlus,
                            color: Color(0xFFE31E24),
                          ),
                          onPressed: () {
                            // TODO: Implementar agregar local
                          },
                          tooltip: 'Agregar local',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tabs de Centrales y Sucursales
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildTab(mostrarCentrales, 'Centrales', () => onToggleMostrarCentrales(true)),
                    const SizedBox(width: 8),
                    _buildTab(!mostrarCentrales, 'Sucursales', () => onToggleMostrarCentrales(false)),
                  ],
                ),
              ),

              // Lista de locales
              Expanded(
                child: mostrarCentrales
                    ? _buildLocalesList(centrales)
                    : _buildLocalesList(sucursales),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocalesList(List<Sucursal> locales) {
    if (locales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.store,
              color: Colors.white24,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              mostrarCentrales
                  ? 'No hay centrales registradas'
                  : 'No hay sucursales registradas',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: locales.length,
      itemBuilder: (context, index) {
        final local = locales[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.store,
                          color: Color(0xFFE31E24),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            local.nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.penToSquare,
                          color: Colors.white70,
                          size: 14,
                        ),
                        onPressed: () {
                          // TODO: Implementar editar local
                        },
                        tooltip: 'Editar',
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        padding: EdgeInsets.zero,
                        iconSize: 14,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.trash,
                          color: Colors.red,
                          size: 14,
                        ),
                        onPressed: () {
                          // TODO: Implementar eliminar local
                        },
                        tooltip: 'Eliminar',
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        padding: EdgeInsets.zero,
                        iconSize: 14,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                local.direccion.isNotEmpty
                    ? local.direccion
                    : 'Sin dirección registrada',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: local.activo
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      local.activo ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                        color: local.activo ? Colors.green : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (local.fechaCreacion != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Creado: ${_formatDate(local.fechaCreacion!)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildTab(bool isSelected, String text, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? const Color(0xFFE31E24)
                    : Colors.white.withOpacity(0.1),
                width: 2,
              ),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFFE31E24) : Colors.white54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
