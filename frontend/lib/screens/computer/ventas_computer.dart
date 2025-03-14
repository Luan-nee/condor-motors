import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/ventas.api.dart' as ventas_api;
import '../../api/main.api.dart';
import '../../services/ventas_transfer_service.dart';
import 'widgets/pending_sales_widget.dart';
import 'widgets/form_sales_computer.dart';

class SalesComputerScreen extends StatefulWidget {
  const SalesComputerScreen({super.key});

  @override
  State<SalesComputerScreen> createState() => _SalesComputerScreenState();
}

class _SalesComputerScreenState extends State<SalesComputerScreen> {
  final _apiService = ApiService();
  late final ventas_api.VentasApi _ventasApi;
  bool _isLoading = false;
  List<ventas_api.Venta> _ventas = [];
  
  // Datos de prueba para productos
  final List<Map<String, dynamic>> _productos = [
    {
      'id': 1,
      'codigo': 'CAS001',
      'nombre': 'Casco MT Thunder 3',
      'precio': 299.99,
      'stock': 15,
      'categoria': 'Cascos',
      'imagen': 'assets/images/casco-mt.jpg',
    },
    {
      'id': 2,
      'codigo': 'ACE001',
      'nombre': 'Aceite Motul 5100 4T',
      'precio': 89.99,
      'stock': 25,
      'categoria': 'Lubricantes',
      'imagen': 'assets/images/aceite-motul.jpg',
    },
    {
      'id': 3,
      'codigo': 'FRE001',
      'nombre': 'Kit de Frenos Brembo',
      'precio': 850.00,
      'stock': 8,
      'categoria': 'Frenos',
      'imagen': 'assets/images/frenos-brembo.jpg',
    },
    {
      'id': 4,
      'codigo': 'SUS001',
      'nombre': 'Amortiguador YSS',
      'precio': 599.99,
      'stock': 12,
      'categoria': 'Suspensión',
      'imagen': 'assets/images/amortiguador-yss.jpg',
    },
    {
      'id': 5,
      'codigo': 'LLA001',
      'nombre': 'Llanta Michelin Pilot',
      'precio': 450.00,
      'stock': 20,
      'categoria': 'Llantas',
      'imagen': 'assets/images/llanta-michelin.jpg',
    },
  ];

  // Datos de prueba para clientes
  final List<Map<String, dynamic>> _clientes = [
    {
      'id': 1,
      'nombre': 'Juan Pérez',
      'documento': '12345678',
      'telefono': '987654321',
      'tipo': 'DNI',
      'direccion': 'Av. Principal 123',
    },
    {
      'id': 2,
      'nombre': 'María García',
      'documento': '87654321',
      'telefono': '123456789',
      'tipo': 'DNI',
      'direccion': 'Calle 45 #789',
    },
    {
      'id': 3,
      'nombre': 'Carlos López',
      'documento': '45678912',
      'telefono': '789456123',
      'tipo': 'RUC',
      'direccion': 'Jr. Comercial 456',
    },
  ];

  // Datos de prueba para ventas pendientes
  final List<Map<String, dynamic>> _ventasPendientes = [
    {
      'id': 'V001',
      'cliente': {
        'id': 1,
        'nombre': 'Juan Pérez',
        'documento': '12345678',
        'telefono': '987654321',
      },
      'productos': [
        {
          'id': 1,
          'nombre': 'Casco MT Thunder 3',
          'precio': 299.99,
          'cantidad': 1,
        },
        {
          'id': 2,
          'nombre': 'Aceite Motul 5100 4T',
          'precio': 89.99,
          'cantidad': 2,
        },
      ],
      'total': 479.97,
      'fecha': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
      'estado': 'PENDIENTE',
    },
    {
      'id': 'V002',
      'cliente': {
        'id': 2,
        'nombre': 'María García',
        'documento': '87654321',
        'telefono': '123456789',
      },
      'productos': [
        {
          'id': 3,
          'nombre': 'Kit de Frenos Brembo',
          'precio': 850.00,
          'cantidad': 1,
        },
      ],
      'total': 850.00,
      'fecha': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
      'estado': 'PENDIENTE',
    },
  ];

  // Variables para el procesamiento de ventas pendientes
  Map<String, dynamic>? _ventaSeleccionada;
  String _montoIngresado = '';
  String _nombreCliente = '';
  String _tipoDocumento = 'Boleta';
  bool _procesandoPago = false;
  final FocusNode _montoFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _ventasApi = ventas_api.VentasApi(_apiService);
    _cargarVentas();
  }

  @override
  void dispose() {
    _montoFocusNode.dispose();
    super.dispose();
  }

  // Método para manejar la entrada de teclas
  void _handleKeyPress(String key) {
    setState(() {
      if (key == '00') {
        _montoIngresado += '00';
      } else if (_montoIngresado == '0') {
        _montoIngresado = key;
      } else {
        _montoIngresado += key;
      }
    });
  }

  // Método para limpiar el monto
  void _clearAmount() {
    setState(() {
      if (_montoIngresado.isNotEmpty) {
        _montoIngresado = _montoIngresado.substring(0, _montoIngresado.length - 1);
      }
    });
  }

  // Método para cambiar el tipo de documento
  void _changeDocumentType(String type) {
    setState(() {
      _tipoDocumento = type;
    });
  }

  // Método para cambiar el nombre del cliente
  void _changeCustomerName(String name) {
    setState(() {
      _nombreCliente = name;
    });
  }

  Future<void> _cargarVentas() async {
    setState(() => _isLoading = true);
    try {
      final ventas = await _ventasApi.getVentas();
      if (!mounted) return;
      setState(() {
        _ventas = ventas;
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

  Future<void> _anularVenta(ventas_api.Venta venta) async {
    try {
      await _ventasApi.anularVenta(
        venta.id,
        'Anulado por el usuario',
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venta anulada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      await _cargarVentas();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al anular venta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Método para seleccionar una venta pendiente para procesar
  void _seleccionarVenta(Map<String, dynamic> venta) {
    setState(() {
      _ventaSeleccionada = venta;
      _montoIngresado = '';
      _nombreCliente = venta['cliente']['nombre'];
      _tipoDocumento = 'Boleta'; // Por defecto
    });
  }
  
  // Método para procesar el pago de una venta
  Future<void> _procesarPago() async {
    if (_ventaSeleccionada == null) return;
    
    setState(() => _procesandoPago = true);
    
    try {
      // Mostrar diálogo de procesamiento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ProcessingDialog(documentType: _tipoDocumento),
      );
      
      // Simular procesamiento (en un entorno real, aquí se llamaría a la API)
      await Future.delayed(const Duration(seconds: 2));
      
      // Marcar la venta como procesada
      final ventasTransferService = VentasTransferService();
      await ventasTransferService.marcarVentaComoProcesada(_ventaSeleccionada!['id']);
      
      if (!mounted) return;
      
      // Cerrar diálogo de procesamiento
      Navigator.pop(context);
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venta procesada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Mostrar diálogo de impresión
      await _mostrarDialogoImpresion();
      
      // Limpiar selección
      setState(() {
        _ventaSeleccionada = null;
        _procesandoPago = false;
      });
      
      // Recargar ventas
      await _cargarVentas();
    } catch (e) {
      if (!mounted) return;
      
      // Cerrar diálogo de procesamiento si está abierto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar venta: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() => _procesandoPago = false);
    }
  }
  
  // Método para cancelar el procesamiento de una venta
  void _cancelarProcesamiento() {
    setState(() => _ventaSeleccionada = null);
  }

  Future<void> _mostrarDialogoImpresion() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.print,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Imprimir Comprobante',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Desea imprimir el comprobante de venta?',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _imprimirComprobante();
                  },
                  icon: const FaIcon(FontAwesomeIcons.print),
                  label: const Text('Imprimir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const FaIcon(FontAwesomeIcons.times),
                  label: const Text('Cancelar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31E24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _imprimirComprobante() async {
    // Simular generación de PDF
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Generando comprobante...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    // Simular tiempo de generación
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Cerrar diálogo de carga
    Navigator.pop(context);

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comprobante generado exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.cashRegister,
                size: 20,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Sistema de Ventas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarVentas,
          ),
        ],
      ),
      body: Row(
        children: [
          // Panel izquierdo: Ventas pendientes
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: PendingSalesWidget(
                onSaleSelected: _seleccionarVenta,
                ventasPendientes: _ventasPendientes,
              ),
            ),
          ),
          
          // Panel derecho: Procesamiento de venta o historial
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _ventaSeleccionada != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: _cancelarProcesamiento,
                            ),
                            const Text(
                              'Procesar Venta',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Detalles de la venta
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2D2D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFF4CAF50),
                                    child: FaIcon(
                                      FontAwesomeIcons.user,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _ventaSeleccionada!['cliente']['nombre'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Doc: ${_ventaSeleccionada!['cliente']['documento']}',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE31E24).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'S/ ${_ventaSeleccionada!['total'].toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xFFE31E24),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white24),
                              const SizedBox(height: 16),
                              
                              // Lista de productos
                              ...(_ventaSeleccionada!['productos'] as List<dynamic>).map((producto) {
                                final subtotal = (producto['precio'] as double) * (producto['cantidad'] as int);
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: FaIcon(
                                        FontAwesomeIcons.box,
                                        color: Color(0xFF4CAF50),
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    producto['nombre'] as String,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    'Cantidad: ${producto['cantidad']} x S/ ${(producto['precio'] as double).toStringAsFixed(2)}',
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                  trailing: Text(
                                    'S/ ${subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                              
                              const Divider(color: Colors.white24),
                              
                              // Total
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'TOTAL',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'S/ ${(_ventaSeleccionada!['total'] as double).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Campo de monto con teclado virtual
                        Expanded(
                          child: NumericKeypad(
                            onKeyPressed: _handleKeyPress,
                            onClear: _clearAmount,
                            onSubmit: _procesarPago,
                            currentAmount: _ventaSeleccionada!['total'].toString(),
                            paymentAmount: _montoIngresado,
                            customerName: _nombreCliente,
                            documentType: _tipoDocumento,
                            onCustomerNameChanged: _changeCustomerName,
                            onDocumentTypeChanged: _changeDocumentType,
                            isProcessing: _procesandoPago,
                          ),
                        ),
                      ],
                    )
                  : _isLoading
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
                              color: const Color(0xFF2D2D2D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                collapsedIconColor: Colors.white,
                                iconColor: Colors.white,
                                title: Text(
                                  'Venta #${venta.id}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fecha: ${_formatDateTime(venta.fechaCreacion)}',
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                    Text(
                                      'Estado: ${venta.estado}',
                                      style: TextStyle(
                                        color: venta.estado == ventas_api.VentasApi.estados['COMPLETADA']
                                            ? Colors.green
                                            : venta.estado == ventas_api.VentasApi.estados['ANULADA']
                                                ? Colors.red
                                                : Colors.orange,
                                      ),
                                    ),
                                    Text(
                                      'Total: S/ ${venta.total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Detalles de la Venta',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...venta.detalles.map((detalle) => ListTile(
                                          title: Text(
                                            'Producto #${detalle.productoId}',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                          subtitle: Text(
                                            'Cantidad: ${detalle.cantidad}',
                                            style: TextStyle(color: Colors.grey[400]),
                                          ),
                                          trailing: Text(
                                            'S/ ${detalle.subtotal.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )),
                                        const Divider(color: Colors.white24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Subtotal:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'S/ ${venta.subtotal.toStringAsFixed(2)}',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'IGV:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'S/ ${venta.igv.toStringAsFixed(2)}',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        if (venta.descuentoTotal != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Descuento:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                'S/ ${venta.descuentoTotal!.toStringAsFixed(2)}',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Total:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'S/ ${venta.total.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Color(0xFF4CAF50),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                // TODO: Implementar generación de boleta
                                              },
                                              icon: const Icon(Icons.receipt),
                                              label: const Text('Generar Boleta'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF2196F3),
                                              ),
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                // TODO: Implementar generación de factura
                                              },
                                              icon: const Icon(Icons.description),
                                              label: const Text('Generar Factura'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF9C27B0),
                                              ),
                                            ),
                                            if (venta.estado != ventas_api.VentasApi.estados['ANULADA'])
                                              ElevatedButton.icon(
                                                onPressed: () => _anularVenta(venta),
                                                icon: const Icon(Icons.cancel),
                                                label: const Text('Anular'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFFE31E24),
                                                ),
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
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'No disponible';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
} 