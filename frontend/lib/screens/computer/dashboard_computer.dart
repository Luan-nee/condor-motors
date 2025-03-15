import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/index.dart';
import '../../main.dart' show api;

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
}

class _DashboardComputerScreenState extends State<DashboardComputerScreen> {
  late final VentasApi _ventasApi;
  bool _isLoading = false;
  List<Venta> _ultimasVentas = [];
  List<Map<String, dynamic>> _productosBajos = [];
  List<Map<String, dynamic>> _colaboradoresConectados = [];
  
  @override
  void initState() {
    super.initState();
    _ventasApi = api.ventas;
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      // Cargar últimas ventas
      final ventasResponse = await _ventasApi.getVentas(
        sucursalId: widget.sucursalId?.toString(),
      );
      
      if (!mounted) return;
      
      // Convertir los datos de la API a objetos Venta
      final List<Venta> ventasList = [];
      if (ventasResponse['data'] != null && ventasResponse['data'] is List) {
        for (var item in ventasResponse['data']) {
          ventasList.add(Venta.fromJson(item));
        }
      }
      
      // Ordenar por fecha y tomar las últimas 5
      ventasList.sort((a, b) => 
        (b.fechaCreacion ?? DateTime.now())
            .compareTo(a.fechaCreacion ?? DateTime.now())
      );
      
      _ultimasVentas = ventasList.take(5).toList();
      
      // TODO: Cargar productos con stock bajo
      _productosBajos = [
        {
          'id': 1,
          'nombre': 'Casco MT Thunder',
          'stock': 2,
          'stockMinimo': 5,
        },
        {
          'id': 2,
          'nombre': 'Aceite Motul 5100',
          'stock': 3,
          'stockMinimo': 10,
        },
      ];
      
      // TODO: Cargar colaboradores conectados
      _colaboradoresConectados = [
        {
          'id': 1,
          'nombre': 'Juan Pérez',
          'rol': 'Vendedor',
          'ultimaActividad': DateTime.now().subtract(const Duration(minutes: 5)),
        },
        {
          'id': 2,
          'nombre': 'María García',
          'rol': 'Vendedor',
          'ultimaActividad': DateTime.now().subtract(const Duration(minutes: 15)),
        },
      ];
      
      setState(() {});
    } catch (e) {
      if (!mounted) return;
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
        actions: [
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
                children: [
                  // Resumen de ventas
                  _buildVentasCard(),
                  const SizedBox(height: 16),
                  
                  // Productos con stock bajo
                  _buildStockBajoCard(),
                  const SizedBox(height: 16),
                  
                  // Colaboradores conectados
                  _buildColaboradoresCard(),
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
          children: [
            Row(
              children: [
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
                itemBuilder: (context, index) {
                  final venta = _ultimasVentas[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Venta #${venta.id}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${_formatDateTime(venta.fechaCreacion)}',
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
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE31E24).withOpacity(0.1),
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
            const SizedBox(height: 16),
            if (_productosBajos.isEmpty)
              Center(
                child: Text(
                  'No hay productos con stock bajo',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _productosBajos.length,
                itemBuilder: (context, index) {
                  final producto = _productosBajos[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      producto['nombre'] as String,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Stock mínimo: ${producto['stockMinimo']}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE31E24).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${producto['stock']}',
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

  Widget _buildColaboradoresCard() {
    return Card(
      color: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.users,
                    size: 16,
                    color: Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Colaboradores Conectados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_colaboradoresConectados.isEmpty)
              Center(
                child: Text(
                  'No hay colaboradores conectados',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _colaboradoresConectados.length,
                itemBuilder: (context, index) {
                  final colaborador = _colaboradoresConectados[index];
                  final ultimaActividad = colaborador['ultimaActividad'] as DateTime;
                  final diferencia = DateTime.now().difference(ultimaActividad);
                  final minutos = diferencia.inMinutes;
                  
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF2196F3),
                      child: FaIcon(
                        FontAwesomeIcons.user,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      colaborador['nombre'] as String,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${colaborador['rol']} • Activo hace ${minutos} min',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
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
    if (date == null) return 'No disponible';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
