import 'package:flutter/material.dart';
import '../../main.dart' show api;

// Definición de la clase Venta para manejar los datos
class Venta {
  final String id;
  final DateTime? fechaCreacion;
  final String estado;
  final double subtotal;
  final double igv;
  final double total;
  final double descuentoTotal;
  final List<DetalleVenta>? detalles;

  Venta({
    required this.id,
    this.fechaCreacion,
    required this.estado,
    required this.subtotal,
    required this.igv,
    required this.total,
    this.descuentoTotal = 0.0,
    this.detalles,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      id: json['id']?.toString() ?? '',
      fechaCreacion: json['fecha_creacion'] != null 
          ? DateTime.parse(json['fecha_creacion']) 
          : null,
      estado: json['estado'] ?? 'PENDIENTE',
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      igv: (json['igv'] ?? 0.0).toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
      descuentoTotal: (json['descuento_total'] ?? 0.0).toDouble(),
      detalles: json['detalles'] != null
          ? (json['detalles'] as List)
              .map((detalle) => DetalleVenta.fromJson(detalle))
              .toList()
          : null,
    );
  }
}

// Clase para los detalles de venta
class DetalleVenta {
  final String productoId;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  DetalleVenta({
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      productoId: json['producto_id']?.toString() ?? '',
      cantidad: json['cantidad'] ?? 0,
      precioUnitario: (json['precio_unitario'] ?? 0.0).toDouble(),
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
    );
  }
}

// Constantes para los estados de venta
class EstadosVenta {
  static const String PENDIENTE = 'PENDIENTE';
  static const String COMPLETADA = 'COMPLETADA';
  static const String ANULADA = 'ANULADA';
}

class VentasAdminScreen extends StatefulWidget {
  const VentasAdminScreen({super.key});

  @override
  State<VentasAdminScreen> createState() => _VentasAdminScreenState();
}

class _VentasAdminScreenState extends State<VentasAdminScreen> {
  bool _isLoading = false;
  List<Venta> _ventas = [];

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final response = await api.ventas.getVentas();
      
      if (!mounted) return;
      
      final List<Venta> ventasList = [];
      if (response['data'] != null && response['data'] is List) {
        for (var item in response['data']) {
          ventasList.add(Venta.fromJson(item));
        }
      }
      
      setState(() {
        _ventas = ventasList;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar ventas: $e'),
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
      appBar: AppBar(
        title: const Text('Ventas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _ventas.length,
              itemBuilder: (context, index) {
                final venta = _ventas[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text('Venta #${venta.id}'),
                    subtitle: Text('Fecha: ${venta.fechaCreacion?.toLocal() ?? 'No disponible'}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total: S/ ${venta.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Subtotal: S/ ${venta.subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
} 