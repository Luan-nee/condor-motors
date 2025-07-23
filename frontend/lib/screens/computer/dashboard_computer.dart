import 'package:condorsmotors/providers/computer/dash.computer.provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

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
  State<DashboardComputerScreen> createState() =>
      _DashboardComputerScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('sucursalId', sucursalId))
      ..add(StringProperty('nombreSucursal', nombreSucursal));
  }
}

class _DashboardComputerScreenState extends State<DashboardComputerScreen> {
  late DashboardComputerProvider _dashboardProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  Future<void> _initializeProvider() async {
    _dashboardProvider =
        Provider.of<DashboardComputerProvider>(context, listen: false);
    await _dashboardProvider.inicializar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Consumer<DashboardComputerProvider>(
          builder: (context, provider, _) => Text(
            'Dashboard - ${provider.nombreSucursal}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _dashboardProvider.cargarDatos(),
          ),
        ],
      ),
      body: Consumer<DashboardComputerProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.cargarDatos(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildVentasCard(provider),
                const SizedBox(height: 16),
                _buildStockBajoCard(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVentasCard(DashboardComputerProvider provider) {
    // Verificar el tipo de los elementos en ultimasVentas
    final List<Venta> ventas = provider.ultimasVentas.map((item) {
      try {
        // Si el elemento ya es un objeto Venta, devolverlo directamente
        if (item is Venta) {
          return item;
        }
        // Si es un Map, convertirlo a Venta usando fromJson
        else if (item is Map<String, dynamic>) {
          return Venta.fromJson(item);
        }
        // Si no es ninguno de los anteriores, crear un objeto Venta con valores predeterminados
        else {
          return Venta(
            id: 'N/A',
            estado: 'DESCONOCIDO',
            subtotal: 0.0,
            igv: 0.0,
            total: 0.0,
          );
        }
      } catch (e) {
        debugPrint('Error al convertir venta: $e');
        // En caso de error, devolver un objeto Venta con valores predeterminados
        return Venta(
          id: 'N/A',
          estado: 'DESCONOCIDO',
          subtotal: 0.0,
          igv: 0.0,
          total: 0.0,
        );
      }
    }).toList();

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
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
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
            if (ventas.isEmpty)
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
                itemCount: ventas.length,
                itemBuilder: (BuildContext context, int index) {
                  final Venta venta = ventas[index];
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

  Widget _buildStockBajoCard(DashboardComputerProvider provider) {
    final List<ProductoStockBajo> productos = provider.productosStockBajo
        .map(ProductoStockBajo.fromJson)
        .toList();

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
                        color: const Color(0xFFE31E24).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.triangleExclamation,
                        size: 16,
                        color: Color(0xFFE31E24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Stock Bajo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => provider.cargarDatos(),
                  icon: const FaIcon(
                    FontAwesomeIcons.arrowsRotate,
                    size: 14,
                    color: Color(0xFF2196F3),
                  ),
                  label: const Text(
                    'Actualizar',
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!provider.isLoading && productos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Mostrando ${productos.length} productos con stock bajo',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (productos.isEmpty)
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
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: productos.length,
                itemBuilder: (BuildContext context, int index) {
                  final ProductoStockBajo producto = productos[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      producto.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
                              color: const Color(0xFF2196F3).withValues(alpha: 0.1),
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
                        color: const Color(0xFFE31E24).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${producto.stock}',
                        style: const TextStyle(
                          color: Color(0xFFE31E24),
                          fontWeight: FontWeight.bold,
                        ),
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

  String _formatDateTime(DateTime? date) {
    if (date == null) {
      return 'No disponible';
    }
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
